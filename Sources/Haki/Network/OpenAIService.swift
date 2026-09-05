import Foundation

public final class OpenAIService {
    public static let shared = OpenAIService()
    
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let modelsEndpoint = URL(string: "https://api.openai.com/v1/models")!
    
    public init(session: URLSession? = nil) {
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 25.0
            config.timeoutIntervalForResource = 30.0
            self.session = URLSession(configuration: config)
        }
    }
    
    /// Verifies the API key validity against OpenAI models endpoint.
    public func validateAPIKey(_ apiKey: String) async throws -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }
        
        var request = URLRequest(url: modelsEndpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let err as URLError where err.code == .timedOut {
            throw TranscriptionError.networkTimeout
        } catch {
            throw TranscriptionError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else if httpResponse.statusCode == 401 {
            let errorMsg = parseErrorMessage(from: data) ?? "Invalid API key"
            throw TranscriptionError.invalidAPIKey(errorMsg)
        } else if httpResponse.statusCode == 429 {
            let errorMsg = parseErrorMessage(from: data) ?? "Rate limit reached or quota exceeded"
            throw TranscriptionError.rateLimitExceeded(errorMsg)
        } else {
            let errorMsg = parseErrorMessage(from: data) ?? "Status code \(httpResponse.statusCode)"
            throw TranscriptionError.apiError(statusCode: httpResponse.statusCode, message: errorMsg)
        }
    }
    
    /// Transcribes audio data using the specified model and prompt.
    public func transcribe(
        audioData: Data,
        apiKey: String,
        model: String = "gpt-4o-transcribe",
        language: String = "ar",
        prompt: String? = nil
    ) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }
        guard !audioData.isEmpty else {
            throw TranscriptionError.emptyAudio
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Model
        body.appendFormField(named: "model", value: model, boundary: boundary)
        
        // Language (omit for auto-detection)
        if !language.isEmpty && language.lowercased() != "auto" {
            body.appendFormField(named: "language", value: language, boundary: boundary)
        }
        
        // Prompt / Context instructions
        if let prompt = prompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body.appendFormField(named: "prompt", value: prompt, boundary: boundary)
        }
        
        // Response format
        body.appendFormField(named: "response_format", value: "json", boundary: boundary)
        
        // Audio File
        body.appendFileData(
            named: "file",
            filename: "dictation.wav",
            mimeType: "audio/wav",
            fileData: audioData,
            boundary: boundary
        )
        
        // Close multipart body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let startTime = CFAbsoluteTimeGetCurrent()
        AppLogger.shared.info("Sending audio transcription request (\(audioData.count) bytes, model: \(model), lang: \(language))...")
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let err as URLError where err.code == .timedOut {
            AppLogger.shared.error("Transcription request timed out")
            throw TranscriptionError.networkTimeout
        } catch {
            AppLogger.shared.error("Transcription network error: \(error.localizedDescription)")
            throw TranscriptionError.networkError(error.localizedDescription)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }
        
        AppLogger.shared.info("Transcription completed in \(String(format: "%.2f", duration))s with HTTP \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                let trimmedResult = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedResult.isEmpty {
                    throw TranscriptionError.silenceDetected
                }
                return trimmedResult
            } catch {
                AppLogger.shared.error("Failed to decode transcription response JSON")
                throw TranscriptionError.invalidResponse
            }
            
        case 401:
            let msg = parseErrorMessage(from: data) ?? "Unauthorized"
            AppLogger.shared.error("OpenAI 401 Unauthorized")
            throw TranscriptionError.invalidAPIKey(msg)
            
        case 429:
            let msg = parseErrorMessage(from: data) ?? "Too Many Requests"
            AppLogger.shared.error("OpenAI 429 Rate Limit / Quota Exceeded")
            throw TranscriptionError.rateLimitExceeded(msg)
            
        default:
            let msg = parseErrorMessage(from: data) ?? "Unknown server error"
            AppLogger.shared.error("OpenAI API error \(httpResponse.statusCode): \(msg)")
            throw TranscriptionError.apiError(statusCode: httpResponse.statusCode, message: msg)
        }
    }
    
    private func parseErrorMessage(from data: Data) -> String? {
        if let envelope = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
            return envelope.error.message
        }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Multipart Form Data Helpers
private extension Data {
    mutating func appendFormField(named name: String, value: String, boundary: String) {
        var field = "--\(boundary)\r\n"
        field += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        field += "\(value)\r\n"
        if let data = field.data(using: .utf8) {
            append(data)
        }
    }
    
    mutating func appendFileData(
        named name: String,
        filename: String,
        mimeType: String,
        fileData: Data,
        boundary: String
    ) {
        var header = "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n\r\n"
        if let headerData = header.data(using: .utf8) {
            append(headerData)
            append(fileData)
            append("\r\n".data(using: .utf8)!)
        }
    }
}
