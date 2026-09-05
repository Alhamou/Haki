import Foundation
import AVFoundation

public struct SilenceDetector {
    /// Silence energy threshold below which audio is considered empty noise or silence.
    public static let defaultSilenceRMSThreshold: Float = 0.006
    public static let minSpeechDuration: TimeInterval = 0.35
    
    /// Calculates Root Mean Square (RMS) energy from audio buffer.
    public static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        return sqrt(sum / Float(frameLength))
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
    
    /// Checks whether the recorded audio is silent or too short to contain speech.
    public static func isSilent(
        duration: TimeInterval,
        averageRMS: Float,
        maxRMS: Float,
        threshold: Float = defaultSilenceRMSThreshold
    ) -> Bool {
        if duration < minSpeechDuration {
            return true
        }
        if averageRMS < threshold && maxRMS < (threshold * 1.8) {
            return true
        }
        return false
    }
}
