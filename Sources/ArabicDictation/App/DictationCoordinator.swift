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
            do {
                let recordingResult = try AudioRecorder.shared.stopRecording()
                defer {
                    // Strict privacy requirement: delete temporary recording immediately
                    try? FileManager.default.removeItem(at: recordingResult.fileURL)
                    AppLogger.shared.info("Temporary audio file safely removed.")
                }
                
                guard let apiKey = settings.getAPIKey() else {
                    throw TranscriptionError.missingAPIKey
                }
                
                let audioData = try Data(contentsOf: recordingResult.fileURL)
                
                let text = try await OpenAIService.shared.transcribe(
                    audioData: audioData,
                    apiKey: apiKey,
                    model: settings.model,
                    language: settings.language,
                    prompt: settings.promptContext
                )
                
                await MainActor.run {
                    self.isTranscribing = false
                    MenuBarManager.shared.updateState(isRecording: false, isTranscribing: false)
                    FloatingHUDWindowController.shared.show(state: .done)
                    SoundEffects.shared.play(.transcriptionSuccess, enabled: settings.playSoundEffects)
                    
                    if settings.pasteAutomatically {
                        let pasted = PasteManager.shared.pasteText(text)
                        if !pasted && !AccessibilityHelper.shared.isAccessibilityGranted() {
                            FloatingHUDWindowController.shared.show(state: .error("Accessibility permission required to paste text."))
                        }
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
}
