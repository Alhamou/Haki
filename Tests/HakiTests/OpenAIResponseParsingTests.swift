import XCTest
@testable import Haki

final class OpenAIResponseParsingTests: XCTestCase {
    
    func testSuccessfulTranscriptionDecoding() throws {
        let json = """
        {
            "text": "مرحبا، هذا اختبار لتحويل الصوت إلى كتابة باللغة العربية."
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        XCTAssertEqual(response.text, "مرحبا، هذا اختبار لتحويل الصوت إلى كتابة باللغة العربية.")
    }
    
    func testOpenAIErrorEnvelopeDecoding() throws {
        let json = """
        {
            "error": {
                "message": "Incorrect API key provided: sk-invalid. You can find your API key at https://platform.openai.com/account/api-keys.",
                "type": "invalid_request_error",
                "param": null,
                "code": "invalid_api_key"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data)
        XCTAssertTrue(envelope.error.message.contains("Incorrect API key"))
        XCTAssertEqual(envelope.error.code, "invalid_api_key")
        XCTAssertEqual(envelope.error.type, "invalid_request_error")
    }
    
    func testTranscriptionErrorDescriptions() {
        let missingKey = TranscriptionError.missingAPIKey
        XCTAssertEqual(missingKey.errorDescription, "OpenAI API key is missing. Please add your key in Settings.")
        
        let invalidKey = TranscriptionError.invalidAPIKey("Unauthorized")
        XCTAssertTrue(invalidKey.errorDescription!.contains("OpenAI rejected the API key"))
        
        let rateLimit = TranscriptionError.rateLimitExceeded("Quota exceeded")
        XCTAssertTrue(rateLimit.errorDescription!.contains("OpenAI rate limit or quota exceeded"))
        
        let silence = TranscriptionError.silenceDetected
        XCTAssertEqual(silence.errorDescription, "No speech detected.")
        
        let empty = TranscriptionError.emptyAudio
        XCTAssertEqual(empty.errorDescription, "No microphone input detected.")
    }
}
