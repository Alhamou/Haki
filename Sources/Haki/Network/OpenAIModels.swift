import Foundation

public struct TranscriptionResponse: Codable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

public struct OpenAIErrorEnvelope: Codable {
    public let error: OpenAIErrorDetail
}

public struct OpenAIErrorDetail: Codable {
    public let message: String
    public let type: String?
    public let param: String?
    public let code: String?
}

public enum TranscriptionError: LocalizedError, Equatable {
    public static func == (lhs: TranscriptionError, rhs: TranscriptionError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey): return true
        case (.invalidAPIKey(let a), .invalidAPIKey(let b)): return a == b
        case (.rateLimitExceeded(let a), .rateLimitExceeded(let b)): return a == b
        case (.apiError(let c1, let m1), .apiError(let c2, let m2)): return c1 == c2 && m1 == m2
        case (.networkTimeout, .networkTimeout): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.emptyAudio, .emptyAudio): return true
        case (.silenceDetected, .silenceDetected): return true
        case (.networkError, .networkError): return true
        default: return false
        }
    }

    case missingAPIKey
    case invalidAPIKey(String)
    case rateLimitExceeded(String)
    case apiError(statusCode: Int, message: String)
    case networkTimeout
    case networkError(String)
    case invalidResponse
    case emptyAudio
    case silenceDetected
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Please add your key in Settings."
        case .invalidAPIKey(let msg):
            return "OpenAI rejected the API key: \(msg)"
        case .rateLimitExceeded(let msg):
            return "OpenAI rate limit or quota exceeded: \(msg)"
        case .apiError(let code, let msg):
            return "OpenAI API error (\(code)): \(msg)"
        case .networkTimeout:
            return "Transcription request timed out. Please check your internet connection."
        case .networkError(let msg):
            return "Network connection error: \(msg)"
        case .invalidResponse:
            return "Received an invalid or malformed response from OpenAI."
        case .emptyAudio:
            return "No microphone input detected."
        case .silenceDetected:
            return "No speech detected."
        }
    }
}
