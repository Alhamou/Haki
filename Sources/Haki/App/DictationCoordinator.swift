import Foundation
import AppKit
import AVFoundation
import Combine

public final class DictationCoordinator: ObservableObject {
    public static let shared = DictationCoordinator()
    
    @Published public private(set) var isRecording = false
    @Published public private(set) var isTranscribing = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe AudioRecorder levels to forward to Floating HUD during recording
        AudioRecorder.shared.$currentAudioLevel
            .sink { [weak self] level in
                guard let self = self, self.isRecording else { return }
                FloatingHUDWindowController.shared.show(state: .recording, audioLevel: level)
            }
            .store(in: &cancellables)
    }
    
    public func toggleDictation() {
        if isRecording {
            stopDictation()
        } else {
            startDictation()
        }
    }
    
    public func startDictation() {
        guard !isRecording && !isTranscribing else { return }
        
        let settings = AppSettings.shared
        guard let apiKey = settings.getAPIKey(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLogger.shared.warning("Dictation started without API key.")
            FloatingHUDWindowController.shared.show(state: .error("OpenAI API key is missing."))
            SoundEffects.shared.play(.errorAlert, enabled: settings.playSoundEffects)
            SettingsWindowController.shared.showSettings()
            return
        }
        
        // Check Microphone permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if authStatus == .denied || authStatus == .restricted {
            FloatingHUDWindowController.shared.show(state: .error("Microphone permission denied."))
            SoundEffects.shared.play(.errorAlert, enabled: settings.playSoundEffects)
            return
        } else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startDictation()
                    }
                }
            }
            return
        }
        
        do {
            let selectedDeviceID = AudioDeviceManager.shared.selectedDevice?.id
            try AudioRecorder.shared.startRecording(deviceID: selectedDeviceID)
            self.isRecording = true
            
            SoundEffects.shared.play(.recordingStarted, enabled: settings.playSoundEffects)
            FloatingHUDWindowController.shared.show(state: .recording, audioLevel: 0.0)
            MenuBarManager.shared.updateState(isRecording: true, isTranscribing: false)
        } catch {
            AppLogger.shared.error("Failed to start recording: \(error.localizedDescription)")
            FloatingHUDWindowController.shared.show(state: .error("Could not start recording."))
            SoundEffects.shared.play(.errorAlert, enabled: settings.playSoundEffects)
        }
    }
    
    public func stopDictation() {
        guard isRecording else { return }
        self.isRecording = false
        
        let settings = AppSettings.shared
        SoundEffects.shared.play(.recordingStopped, enabled: settings.playSoundEffects)
        
        FloatingHUDWindowController.shared.show(state: .transcribing)
        MenuBarManager.shared.updateState(isRecording: false, isTranscribing: true)
        self.isTranscribing = true
        
        Task {
            await transcribeAndPaste {
                let recordingResult = try AudioRecorder.shared.stopRecording()
                defer {
                    // Strict privacy requirement: delete temporary recording immediately
                    try? FileManager.default.removeItem(at: recordingResult.fileURL)
                    AppLogger.shared.info("Temporary audio file safely removed.")
                }
                return (try Data(contentsOf: recordingResult.fileURL), "dictation.wav", "audio/wav")
            }
        }
    }
    
    /// Transcribes an audio file recorded elsewhere (e.g. on the iPhone via AirMouse) and pastes the text.
    /// The file is always deleted afterwards.
    public func transcribeFile(at fileURL: URL) {
        guard !isRecording && !isTranscribing else {
            AppLogger.shared.warning("Ignoring incoming audio: a dictation is already in progress.")
            try? FileManager.default.removeItem(at: fileURL)
            return
        }
        
        FloatingHUDWindowController.shared.show(state: .transcribing)
        MenuBarManager.shared.updateState(isRecording: false, isTranscribing: true)
        self.isTranscribing = true
        
        Task {
            await transcribeAndPaste {
                defer {
                    try? FileManager.default.removeItem(at: fileURL)
                    AppLogger.shared.info("Incoming audio file safely removed.")
                }
                let ext = fileURL.pathExtension.lowercased()
                return (try Data(contentsOf: fileURL), "dictation.\(ext)", Self.mimeType(forExtension: ext))
            }
        }
    }
    
    private static func mimeType(forExtension ext: String) -> String {
        switch ext {
        case "m4a", "mp4": return "audio/mp4"
        case "webm": return "audio/webm"
        case "mp3": return "audio/mpeg"
        case "ogg": return "audio/ogg"
        default: return "audio/wav"
        }
    }
    
    /// Loads the audio, sends it to OpenAI and pastes the result. Expects `isTranscribing` to be set already.
    private func transcribeAndPaste(
        _ loadAudio: () throws -> (data: Data, filename: String, mimeType: String)
    ) async {
        let settings = AppSettings.shared
        do {
            let audio = try loadAudio()
            
            guard let apiKey = settings.getAPIKey() else {
                throw TranscriptionError.missingAPIKey
            }
            
            let text = try await OpenAIService.shared.transcribe(
                audioData: audio.data,
                apiKey: apiKey,
                model: settings.model.rawValue,
                language: settings.language,
                prompt: settings.promptContext,
                filename: audio.filename,
                mimeType: audio.mimeType
            )
            
            await MainActor.run {
                self.isTranscribing = false
                MenuBarManager.shared.updateState(isRecording: false, isTranscribing: false)
                SoundEffects.shared.play(.transcriptionSuccess, enabled: settings.playSoundEffects)
                
                if settings.pasteAutomatically {
                    let pasted = PasteManager.shared.pasteText(text)
                    if pasted {
                        FloatingHUDWindowController.shared.show(state: .done)
                    } else {
                        FloatingHUDWindowController.shared.show(state: .error("Text copied! Enable Accessibility in Settings to auto-paste."))
                    }
                } else {
                    PasteManager.shared.pasteText(text, restoreClipboard: false)
                    FloatingHUDWindowController.shared.show(state: .done)
                }
            }
        } catch {
            await MainActor.run {
                self.isTranscribing = false
                MenuBarManager.shared.updateState(isRecording: false, isTranscribing: false)
                SoundEffects.shared.play(.errorAlert, enabled: settings.playSoundEffects)
                
                let errorDesc = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                FloatingHUDWindowController.shared.show(state: .error(errorDesc))
            }
        }
    }
}
