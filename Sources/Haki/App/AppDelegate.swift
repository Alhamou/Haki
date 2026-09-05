import Foundation
import AppKit
import AVFoundation

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.info("Haki launching...")
        
        // Ensure menu-bar-only accessory mode (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup Menu Bar Item
        MenuBarManager.shared.setupMenuBar()
        
        // Request / verify Microphone permission
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                AppLogger.shared.info("Microphone authorization response: \(granted)")
            }
        }
        
        // Check Accessibility permission & setup Push-to-Talk
        if AccessibilityHelper.shared.isAccessibilityGranted() {
            setupPushToTalk()
        } else {
            AppLogger.shared.warning("Accessibility permission is required for global shortcut and auto-paste.")
            // Periodically check if permission was granted in System Settings
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                if AccessibilityHelper.shared.isAccessibilityGranted() {
                    timer.invalidate()
                    self?.setupPushToTalk()
                    MenuBarManager.shared.updateState(isRecording: false, isTranscribing: false)
                }
            }
        }
        
        // Prompt for API key if missing
        if !AppSettings.shared.hasAPIKey {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                SettingsWindowController.shared.showSettings()
            }
        }
    }
    
    private func setupPushToTalk() {
        let hotkey = PushToTalkManager.shared
        hotkey.onStartRecording = {
            DictationCoordinator.shared.startDictation()
        }
        hotkey.onStopRecording = {
            DictationCoordinator.shared.stopDictation()
        }
        hotkey.start()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        PushToTalkManager.shared.stop()
        AudioRecorder.shared.cancelRecording()
        AppLogger.shared.info("Haki terminated.")
    }
}
