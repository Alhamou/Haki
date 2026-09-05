import XCTest
import AVFoundation
@testable import ArabicDictation

final class SilenceDetectionTests: XCTestCase {
    
    func testSilenceDetectionWithSynthesizedBuffers() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
            XCTFail("Could not create audio format")
            return
        }
        
        let frameCount: AVAudioFrameCount = 1600
        guard let silentBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            XCTFail("Could not create PCM buffer")
            return
        }
        silentBuffer.frameLength = frameCount
        
        // Zero-fill the silent buffer
        if let channelData = silentBuffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                channelData[i] = 0.0
            }
        }
        
        let silentRMS = SilenceDetector.calculateRMS(buffer: silentBuffer)
        XCTAssertEqual(silentRMS, 0.0, accuracy: 0.0001)
        
        // Test normalized power for zero amplitude
        let powerZero = SilenceDetector.normalizedPower(from: silentRMS)
        XCTAssertEqual(powerZero, 0.0, accuracy: 0.01)
        
        // Create a voiced buffer with sine wave
        guard let voicedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            XCTFail("Could not create PCM buffer")
            return
        }
        voicedBuffer.frameLength = frameCount
        if let channelData = voicedBuffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                // 440 Hz tone at 0.5 amplitude
                channelData[i] = 0.5 * sin(2.0 * .pi * 440.0 * Float(i) / 16000.0)
            }
        }
        
        let voicedRMS = SilenceDetector.calculateRMS(buffer: voicedBuffer)
        XCTAssertGreaterThan(voicedRMS, 0.3)
        
        let powerVoiced = SilenceDetector.normalizedPower(from: voicedRMS)
        XCTAssertGreaterThan(powerVoiced, 0.5)
    }
    
    func testIsSilentThresholdLogic() {
        // Duration too short (< 0.35s)
        XCTAssertTrue(SilenceDetector.isSilent(duration: 0.2, averageRMS: 0.1, maxRMS: 0.2))
        
        // Energy too low
        XCTAssertTrue(SilenceDetector.isSilent(duration: 2.0, averageRMS: 0.001, maxRMS: 0.002))
        
        // Valid speech
        XCTAssertFalse(SilenceDetector.isSilent(duration: 2.0, averageRMS: 0.05, maxRMS: 0.15))
    }
}
