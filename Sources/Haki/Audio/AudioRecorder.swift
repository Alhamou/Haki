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
    private var writeFormat: AVAudioFormat?
    private var converter: AVAudioConverter?
    
    private var startTime: CFAbsoluteTime = 0
    private var totalRMSAccumulator: Float = 0
    private var rmsCount: Int = 0
    private var peakRMSValue: Float = 0
    
    private let queue = DispatchQueue(label: "com.alhamou.haki.audiorecorder", qos: .userInitiated)
    
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
        
        if duration < SilenceDetector.minSpeechDuration || rmsCount == 0 {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
            AppLogger.shared.warning("Recording was too short or contained no audio frames (\(String(format: "%.2f", duration))s, buffers: \(rmsCount))")
            throw TranscriptionError.emptyAudio
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        if fileSize <= 4096 {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
            AppLogger.shared.warning("Recorded file has no audio payload (\(fileSize) bytes).")
            throw TranscriptionError.emptyAudio
        }

        // Low RMS alone is not decisive (mic gain varies); let the transcription
        // API judge actual speech content instead of discarding audio locally.
        if avgRMS < SilenceDetector.defaultSilenceRMSThreshold {
            AppLogger.shared.warning("Low audio energy (Avg RMS: \(avgRMS), Peak: \(peakRMS)); sending anyway")
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
        // If an explicit device ID is requested and differs from system default, align it via CoreAudio
        if let devID = deviceID, devID != 0 {
            let currentDefault = AudioDeviceManager.shared.getDefaultInputDeviceID()
            if devID != currentDefault {
                AudioDeviceManager.shared.setDefaultInputDevice(deviceID: devID)
            }
        }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
            AppLogger.shared.error("Input format invalid (\(inputFormat.channelCount) ch, \(inputFormat.sampleRate) Hz). Device might be disconnected.")
            throw TranscriptionError.emptyAudio
        }

        if recordToFile {
            let tempDir = FileManager.default.temporaryDirectory
            let uniqueURL = tempDir.appendingPathComponent("dictation_\(UUID().uuidString).wav")
            self.tempFileURL = uniqueURL

            // OpenAI rejects raw device formats; write a standard 16-bit mono WAV.
            // WAV also cannot hold non-interleaved data, so downmix to 1 channel.
            guard let monoFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: inputFormat.sampleRate,
                channels: 1,
                interleaved: true
            ) else {
                throw TranscriptionError.emptyAudio
            }
            let wavSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: inputFormat.sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
            self.audioFile = try AVAudioFile(forWriting: uniqueURL, settings: wavSettings)
            self.writeFormat = monoFormat
            self.converter = AVAudioConverter(from: inputFormat, to: monoFormat)
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
                        if let converted = self.convertedBuffer(from: buffer) {
                            try self.audioFile?.write(from: converted)
                        }
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
    
    /// Converts a raw device buffer to the mono float format backing the WAV file.
    private func convertedBuffer(from buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let converter = converter, let writeFormat = writeFormat else { return buffer }
        let ratio = writeFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio)) + 32
        guard let out = AVAudioPCMBuffer(pcmFormat: writeFormat, frameCapacity: capacity) else {
            return nil
        }
        var fed = false
        var conversionError: NSError?
        let status = converter.convert(to: out, error: &conversionError) { _, outStatus in
            if fed {
                outStatus.pointee = .noDataNow
                return nil
            }
            fed = true
            outStatus.pointee = .haveData
            return buffer
        }
        if let conversionError = conversionError {
            AppLogger.shared.error("Audio conversion failed: \(conversionError.localizedDescription)")
            return nil
        }
        return status == .error ? nil : out
    }

    private func tearDownEngine() {
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            self.audioEngine = nil
        }
        // Wait for pending buffer writes on the serial queue before dropping
        // the file handle, otherwise the tail of the recording is lost.
        queue.sync {}
        self.audioFile = nil
        self.converter = nil
        self.writeFormat = nil
    }
}
