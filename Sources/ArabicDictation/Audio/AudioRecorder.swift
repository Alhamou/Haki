import Foundation
import AVFoundation
import CoreAudio
import Combine

public struct RecordingResult {
    public let fileURL: URL
    public let duration: TimeInterval
    public let averageRMS: Float
    public let peakRMS: Float
}

public final class AudioRecorder: ObservableObject {
    public static let shared = AudioRecorder()
    
    @Published public private(set) var isRecording = false
    @Published public private(set) var isTestingMicrophone = false
    @Published public private(set) var currentAudioLevel: Float = 0.0
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var tempFileURL: URL?
    
    private var startTime: CFAbsoluteTime = 0
    private var totalRMSAccumulator: Float = 0
    private var rmsCount: Int = 0
    private var peakRMSValue: Float = 0
    
    private let queue = DispatchQueue(label: "com.arabicdictation.audiorecorder", qos: .userInitiated)
    
    public init() {}
    
    // MARK: - Live Metering for Settings Test
    public func startMicrophoneTest(deviceID: AudioDeviceID? = nil) throws {
        stopMicrophoneTest()
        isTestingMicrophone = true
        try setupAndStartEngine(deviceID: deviceID, recordToFile: false)
    }
    
    public func stopMicrophoneTest() {
        guard isTestingMicrophone else { return }
        tearDownEngine()
        isTestingMicrophone = false
        DispatchQueue.main.async {
            self.currentAudioLevel = 0.0
        }
    }
    
    // MARK: - Actual Dictation Recording
    public func startRecording(deviceID: AudioDeviceID? = nil) throws {
        // Stop any test mode first
        if isTestingMicrophone {
            stopMicrophoneTest()
        }
        
        guard !isRecording else { return }
        
        // Reset statistics
        startTime = CFAbsoluteTimeGetCurrent()
        totalRMSAccumulator = 0.0
        rmsCount = 0
        peakRMSValue = 0.0
        
        try setupAndStartEngine(deviceID: deviceID, recordToFile: true)
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
        AppLogger.shared.info("Audio recording started.")
    }
    
    public func stopRecording() throws -> RecordingResult {
        guard isRecording else {
            throw TranscriptionError.emptyAudio
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        tearDownEngine()
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.currentAudioLevel = 0.0
        }
        
        guard let url = tempFileURL else {
            throw TranscriptionError.emptyAudio
        }
        
        let avgRMS = rmsCount > 0 ? (totalRMSAccumulator / Float(rmsCount)) : 0.0
        let peakRMS = peakRMSValue
        
        AppLogger.shared.info("Recording stopped. Duration: \(String(format: "%.2f", duration))s, Avg RMS: \(String(format: "%.4f", avgRMS)), Peak: \(String(format: "%.4f", peakRMS))")
        
        // Check for silent audio or zero-energy input
        if SilenceDetector.isSilent(duration: duration, averageRMS: avgRMS, maxRMS: peakRMS) {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
            if duration < SilenceDetector.minSpeechDuration {
                AppLogger.shared.warning("Recording was too short (\(String(format: "%.2f", duration))s)")
                throw TranscriptionError.emptyAudio
            } else {
                AppLogger.shared.warning("Silent audio detected (Avg RMS: \(avgRMS))")
                throw TranscriptionError.silenceDetected
            }
        }
        
        return RecordingResult(
            fileURL: url,
            duration: duration,
            averageRMS: avgRMS,
            peakRMS: peakRMS
        )
    }
    
    public func cancelRecording() {
        tearDownEngine()
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
        }
        DispatchQueue.main.async {
            self.isRecording = false
            self.isTestingMicrophone = false
            self.currentAudioLevel = 0.0
        }
        AppLogger.shared.info("Audio recording cancelled.")
    }
    
    // MARK: - Engine Setup & Tear Down
    private func setupAndStartEngine(deviceID: AudioDeviceID?, recordToFile: Bool) throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        
        // If deviceID specified, override AUAudioUnit
        if let devID = deviceID, devID != 0 {
            do {
                try inputNode.auAudioUnit.setDeviceID(devID)
                AppLogger.shared.info("Applied input device ID \(devID) to audio unit")
            } catch {
                AppLogger.shared.warning("Could not set device ID \(devID): \(error.localizedDescription)")
            }
        }
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.channelCount > 0 else {
            AppLogger.shared.error("Input format has 0 channels. Device might be disconnected.")
            throw TranscriptionError.emptyAudio
        }
        
        if recordToFile {
            let tempDir = FileManager.default.temporaryDirectory
            let uniqueURL = tempDir.appendingPathComponent("dictation_\(UUID().uuidString).wav")
            self.tempFileURL = uniqueURL
            
            // Standard WAV format settings matching hardware input format
            self.audioFile = try AVAudioFile(
                forWriting: uniqueURL,
                settings: inputFormat.settings,
                commonFormat: inputFormat.commonFormat,
                interleaved: inputFormat.isInterleaved
            )
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let rms = SilenceDetector.calculateRMS(buffer: buffer)
            let level = SilenceDetector.normalizedPower(from: rms)
            
            DispatchQueue.main.async {
                self.currentAudioLevel = level
            }
            
            if recordToFile {
                self.queue.async {
                    self.totalRMSAccumulator += rms
                    self.rmsCount += 1
                    if rms > self.peakRMSValue {
                        self.peakRMSValue = rms
                    }
                    
                    do {
                        try self.audioFile?.write(from: buffer)
                    } catch {
                        AppLogger.shared.error("Error writing audio buffer: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        engine.prepare()
        try engine.start()
        self.audioEngine = engine
    }
    
    private func tearDownEngine() {
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            self.audioEngine = nil
        }
        self.audioFile = nil
    }
}
