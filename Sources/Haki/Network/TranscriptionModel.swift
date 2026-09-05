import Foundation

public enum TranscriptionModel: String, CaseIterable, Identifiable, Codable {
    case gptTranscribe = "gpt-transcribe"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .gptTranscribe:
            return "GPT Transcribe — Recommended"
        case .gpt4oTranscribe:
            return "GPT-4o Transcribe — High Accuracy"
        }
    }
    
    public var modelDescription: String {
        switch self {
        case .gptTranscribe:
            return "OpenAI's latest high-speed speech model designed for fast, accurate general dictation."
        case .gpt4oTranscribe:
            return "OpenAI's flagship audio model offering deep comprehension and dialect preservation for complex speech."
        }
    }
    
    public static let defaultModel: TranscriptionModel = .gptTranscribe
    
    public static func from(rawString: String?) -> TranscriptionModel {
        guard let raw = rawString, let model = TranscriptionModel(rawValue: raw) else {
            return .defaultModel
        }
        return model
    }
}
