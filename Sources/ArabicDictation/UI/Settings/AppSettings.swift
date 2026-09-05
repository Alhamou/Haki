import Foundation
import AppKit
import ServiceManagement
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    // MARK: - Transcription Settings
    @Published public var model: TranscriptionModel {
        didSet { UserDefaults.standard.set(model.rawValue, forKey: "TranscriptionModel") }
    }
    
    @Published public var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "TranscriptionLanguage") }
    }
    
    @Published public var promptContext: String {
        didSet { UserDefaults.standard.set(promptContext, forKey: "TranscriptionPrompt") }
    }
    
    // MARK: - Behavior Settings
    @Published public var pasteAutomatically: Bool {
        didSet { UserDefaults.standard.set(pasteAutomatically, forKey: "PasteAutomatically") }
    }
    
    @Published public var playSoundEffects: Bool {
        didSet { UserDefaults.standard.set(playSoundEffects, forKey: "PlaySoundEffects") }
    }
    
    @Published public var showDebugLogs: Bool {
        didSet { UserDefaults.standard.set(showDebugLogs, forKey: "ShowDebugLogs") }
    }
    
    // MARK: - Shortcut Settings
    @Published public var shortcut: ShortcutConfig {
        didSet {
            if let data = try? JSONEncoder().encode(shortcut) {
                UserDefaults.standard.set(data, forKey: "CustomShortcutConfig")
            }
        }
    }
    
    // MARK: - Launch at Login
    @Published public var launchAtLogin: Bool = false
    
    // MARK: - Keychain API Key State
    @Published public var hasAPIKey: Bool = false
    
    private init() {
        // Default values: gpt-transcribe is the recommended default
        self.model = TranscriptionModel.from(rawString: UserDefaults.standard.string(forKey: "TranscriptionModel"))
        self.language = UserDefaults.standard.string(forKey: "TranscriptionLanguage") ?? "ar"
        self.promptContext = UserDefaults.standard.string(forKey: "TranscriptionPrompt") ?? "Transcribe faithfully in Arabic. Preserve Syrian and Levantine dialect, names, places, numbers, and mixed Arabic-English words. Do not rewrite the meaning."
        
        if UserDefaults.standard.object(forKey: "PasteAutomatically") != nil {
            self.pasteAutomatically = UserDefaults.standard.bool(forKey: "PasteAutomatically")
        } else {
            self.pasteAutomatically = true
        }
        
        if UserDefaults.standard.object(forKey: "PlaySoundEffects") != nil {
            self.playSoundEffects = UserDefaults.standard.bool(forKey: "PlaySoundEffects")
        } else {
            self.playSoundEffects = true
        }
        
        self.showDebugLogs = UserDefaults.standard.bool(forKey: "ShowDebugLogs")
        
        if let data = UserDefaults.standard.data(forKey: "CustomShortcutConfig"),
           let decoded = try? JSONDecoder().decode(ShortcutConfig.self, from: data) {
            self.shortcut = decoded
        } else {
            self.shortcut = .defaultShortcut
        }
        
        // Refresh Keychain state
        self.refreshAPIKeyState()
        
        // Check Launch at Login status
        checkLaunchAtLoginStatus()
    }
    
    public func refreshAPIKeyState() {
        if let key = KeychainHelper.shared.read(), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.hasAPIKey = true
        } else {
            self.hasAPIKey = false
        }
    }
    
    public func saveAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let success = KeychainHelper.shared.save(apiKey: trimmed)
        if success {
            refreshAPIKeyState()
        }
        return success
    }
    
    public func removeAPIKey() -> Bool {
        let success = KeychainHelper.shared.delete()
        refreshAPIKeyState()
        return success
    }
    
    public func getAPIKey() -> String? {
        return KeychainHelper.shared.read()
    }
    
    // MARK: - Modern Launch at Login (SMAppService)
    public func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    public func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                self.launchAtLogin = enabled
                AppLogger.shared.info("Launch at login set to \(enabled)")
            } catch {
                AppLogger.shared.error("Failed to update launch at login: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Shortcut Management
    public func setShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.shortcut = ShortcutConfig(keyCode: keyCode, modifiers: modifiers)
        PushToTalkManager.shared.updateShortcut()
        MenuBarManager.shared.updateShortcutDisplay()
    }
    
    public func resetShortcutToDefault() {
        self.shortcut = .defaultShortcut
        PushToTalkManager.shared.updateShortcut()
        MenuBarManager.shared.updateShortcutDisplay()
    }
}
