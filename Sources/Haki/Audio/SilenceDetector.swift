import Foundation
import AVFoundation

public struct SilenceDetector {
    /// Silence energy threshold below which audio is considered empty noise or silence.
    public static let defaultSilenceRMSThreshold: Float = 0.006
    public static let minSpeechDuration: TimeInterval = 0.35
    
    /// Calculates Root Mean Square (RMS) energy from audio buffer.
    public static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }

        let channelCount = Int(buffer.format.channelCount)
        var sum: Float = 0.0
        var sampleCount = 0

        if buffer.format.isInterleaved {
            // Channel 0 holds all frames interleaved across every channel.
            let stride = max(channelCount, 1)
            let samples = channelData[0]
            for i in 0..<(frameLength * stride) {
                sum += samples[i] * samples[i]
                sampleCount += 1
            }
        } else {
            for c in 0..<max(channelCount, 1) {
                let samples = channelData[c]
                for i in 0..<frameLength {
                    sum += samples[i] * samples[i]
                    sampleCount += 1
                }
            }
        }
        guard sampleCount > 0 else { return 0.0 }
        return sqrt(sum / Float(sampleCount))
    }
    
    /// Converts an RMS value to a normalized 0.0 ... 1.0 level for UI meters.
    public static func normalizedPower(from rms: Float) -> Float {
        // Clamp to min/max decibel range (-60dB to 0dB)
        let minDb: Float = -60.0
        let db = 20.0 * log10(max(rms, 0.0001))
        if db < minDb { return 0.0 }
        if db >= 0.0 { return 1.0 }
        return (db - minDb) / abs(minDb)
    }
    
    /// Checks whether the recording is too short to contain speech.
    public static func isTooShort(duration: TimeInterval) -> Bool {
        duration < minSpeechDuration
    }
}
