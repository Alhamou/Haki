import SwiftUI

public enum HUDState: Equatable {
    case idle
    case recording
    case transcribing
    case done
    case error(String)
}

public struct FloatingHUDView: View {
    let state: HUDState
    let audioLevel: Float
    
    public init(state: HUDState, audioLevel: Float = 0.0) {
        self.state = state
        self.audioLevel = audioLevel
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            switch state {
            case .idle:
                EmptyView()
                
            case .recording:
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .scaleEffect(1.0 + CGFloat(audioLevel) * 0.5)
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)
                    
                    Text("Recording…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // Simple live audio level bars
                    HStack(spacing: 2) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.red.opacity(0.85))
                                .frame(width: 3, height: max(4, CGFloat(audioLevel) * 16.0 * CGFloat(index + 1) / 4.0))
                                .animation(.easeOut(duration: 0.08), value: audioLevel)
                        }
                    }
                }
                
            case .transcribing:
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                        .frame(width: 14, height: 14)
                    
                    Text("Transcribing…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                
            case .done:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                    
                    Text("Done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                
            case .error(let msg):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text(msg)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}
