import AppKit
import AudioToolbox

public enum SoundType {
    case recordingStarted
    case recordingStopped
    case transcriptionSuccess
    case errorAlert
}

public final class SoundEffects {
    public static let shared = SoundEffects()
    
    private init() {}
    
    public func play(_ type: SoundType, enabled: Bool = true) {
        guard enabled else { return }
        DispatchQueue.main.async {
            switch type {
            case .recordingStarted:
                NSSound(named: "Tink")?.play()
            case .recordingStopped:
                NSSound(named: "Pop")?.play()
            case .transcriptionSuccess:
                NSSound(named: "Glass")?.play()
            case .errorAlert:
                NSSound(named: "Basso")?.play()
            }
        }
    }
}
