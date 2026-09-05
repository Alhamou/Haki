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

public enum TranscriptionLanguage: String, CaseIterable, Identifiable, Codable {
    case arabic = "ar"
    case english = "en"
    case german = "de"
    case french = "fr"
    case auto = "auto"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .arabic:
            return "Arabic (العربية)"
        case .english:
            return "English"
        case .german:
            return "German (Deutsch)"
        case .french:
            return "French (Français)"
        case .auto:
            return "Auto-Detect Language"
        }
    }
    
    public var description: String {
        switch self {
        case .arabic:
            return "Optimized for Syrian, Levantine, and standard Arabic speech."
        case .english:
            return "Transcribe spoken English with high accuracy."
        case .german:
            return "Transcribe standard and regional German speech."
        case .french:
            return "Transcribe standard French speech."
        case .auto:
            return "Automatically detects spoken language before transcribing."
        }
    }
    
    public static let defaultLanguage: TranscriptionLanguage = .arabic
}

