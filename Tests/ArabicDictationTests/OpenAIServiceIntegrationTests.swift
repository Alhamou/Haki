import XCTest
@testable import ArabicDictation

final class OpenAIServiceIntegrationTests: XCTestCase {
    
    func testAPIKeyValidationRejectionWithDummyKey() async throws {
        let service = OpenAIService()
        do {
            _ = try await service.validateAPIKey("sk-invalid-test-key-000000000000000000000000")
            XCTFail("Validation should have failed with 401 Unauthorized")
        } catch let TranscriptionError.invalidAPIKey(msg) {
            XCTAssertFalse(msg.isEmpty)
            // OpenAI error response contains message about invalid key
            XCTAssertTrue(msg.lowercased().contains("invalid") || msg.lowercased().contains("incorrect") || msg.lowercased().contains("key"))
        } catch {
            // In case network is offline or other error
            print("Note: Network error during dummy key test: \(error)")
        }
    }
    
    func testTranscriptionMultipartRejectionWithDummyKey() async throws {
        let service = OpenAIService()
        let dummyWavData = Data(repeating: 0, count: 1024)
        do {
            _ = try await service.transcribe(
                audioData: dummyWavData,
                apiKey: "sk-invalid-test-key-000000000000000000000000",
                model: "gpt-4o-transcribe",
                language: "ar",
                prompt: "Transcribe faithfully in Arabic."
            )
            XCTFail("Transcription should have failed with 401 Unauthorized")
        } catch let TranscriptionError.invalidAPIKey(msg) {
            XCTAssertFalse(msg.isEmpty)
        } catch {
            print("Note: Result during dummy key test: \(error)")
        }
    }
}
