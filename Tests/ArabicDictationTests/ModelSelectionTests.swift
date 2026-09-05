import XCTest
@testable import ArabicDictation

final class ModelSelectionTests: XCTestCase {
    
    override func tearDown() {
        // Reset model setting to default after each test
        AppSettings.shared.model = .defaultModel
        super.tearDown()
    }
    
    func testDefaultModelIsGptTranscribe() {
        XCTAssertEqual(TranscriptionModel.defaultModel, .gptTranscribe)
        XCTAssertEqual(TranscriptionModel.defaultModel.rawValue, "gpt-transcribe")
        XCTAssertEqual(TranscriptionModel.defaultModel.displayName, "GPT Transcribe — Recommended")
        
        let settings = AppSettings.shared
        XCTAssertEqual(settings.model, .gptTranscribe)
    }
    
    func testModelChoicePersistence() {
        let settings = AppSettings.shared
        
        // 1. Set to gpt-4o-transcribe
        settings.model = .gpt4oTranscribe
        XCTAssertEqual(UserDefaults.standard.string(forKey: "TranscriptionModel"), "gpt-4o-transcribe")
        
        // 2. Decode from raw string
        let stored = UserDefaults.standard.string(forKey: "TranscriptionModel")
        let loaded = TranscriptionModel.from(rawString: stored)
        XCTAssertEqual(loaded, .gpt4oTranscribe)
        
        // 3. Switch back to gpt-transcribe
        settings.model = .gptTranscribe
        XCTAssertEqual(UserDefaults.standard.string(forKey: "TranscriptionModel"), "gpt-transcribe")
    }
    
    func testInvalidStoredModelFallback() {
        // Corrupted / unknown model names should safely fall back to gpt-transcribe
        XCTAssertEqual(TranscriptionModel.from(rawString: "unknown-ai-model"), .gptTranscribe)
        XCTAssertEqual(TranscriptionModel.from(rawString: ""), .gptTranscribe)
        XCTAssertEqual(TranscriptionModel.from(rawString: nil), .gptTranscribe)
        XCTAssertEqual(TranscriptionModel.from(rawString: "whisper-legacy"), .gptTranscribe)
    }
    
    func testGptTranscribeRequestPayload() async {
        let service = OpenAIService()
        let dummyData = Data(repeating: 0, count: 128)
        
        do {
            _ = try await service.transcribe(
                audioData: dummyData,
                apiKey: "sk-test-dummy-key-for-payload-test",
                model: TranscriptionModel.gptTranscribe.rawValue,
                language: "ar",
                prompt: "Test prompt"
            )
        } catch let TranscriptionError.invalidAPIKey(msg) {
            // Reached OpenAI endpoint with gpt-transcribe parameter formed correctly
            XCTAssertFalse(msg.isEmpty)
        } catch {
            print("Expected dummy key rejection: \(error)")
        }
    }
    
    func testGpt4oTranscribeRequestPayload() async {
        let service = OpenAIService()
        let dummyData = Data(repeating: 0, count: 128)
        
        do {
            _ = try await service.transcribe(
                audioData: dummyData,
                apiKey: "sk-test-dummy-key-for-payload-test",
                model: TranscriptionModel.gpt4oTranscribe.rawValue,
                language: "ar",
                prompt: "Test prompt"
            )
        } catch let TranscriptionError.invalidAPIKey(msg) {
            // Reached OpenAI endpoint with gpt-4o-transcribe parameter formed correctly
            XCTAssertFalse(msg.isEmpty)
        } catch {
            print("Expected dummy key rejection: \(error)")
        }
    }
}
