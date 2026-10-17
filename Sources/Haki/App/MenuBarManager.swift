import Foundation
import AppKit

public final class MenuBarManager: NSObject, NSMenuDelegate {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var dictationMenuItem: NSMenuItem?
    private var statusHeaderItem: NSMenuItem?
    private var microphoneSubmenu: NSMenu?
    
    private var isRecording = false
    private var isTranscribing = false
    
    private override init() {
        super.init()
    }
    
    public func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item
        
        if let button = item.button {
            button.imagePosition = .imageLeading
            button.toolTip = "Haki — حكي (\(AppSettings.shared.shortcut.displayString))"
        }
        
        updateIcon()
        
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        
        rebuildMenu(menu)
    }
    
    public func updateShortcutDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let button = self.statusItem?.button {
                button.toolTip = "Haki — حكي (\(AppSettings.shared.shortcut.displayString))"
            }
            if let menu = self.statusItem?.menu {
                self.rebuildMenu(menu)
            }
        }
    }
    
    public func updateState(isRecording: Bool, isTranscribing: Bool) {
        self.isRecording = isRecording
        self.isTranscribing = isTranscribing
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateIcon()
            if let menu = self.statusItem?.menu {
                self.rebuildMenu(menu)
            }
        }
    }
    
    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        if isRecording {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .bold)
            if let image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "Recording")?.withSymbolConfiguration(config) {
                image.isTemplate = false
                button.image = tintImage(image, with: .systemRed)
            }
            button.title = " تسجيل..."
        } else if isTranscribing {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            if let image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Transcribing")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
            button.title = " معالجة..."
        } else {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            if let image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Haki")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
            button.title = " حكي"
        }
    }
    
    private func tintImage(_ image: NSImage, with color: NSColor) -> NSImage {
        let tinted = image.copy() as! NSImage
        tinted.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: tinted.size)
        imageRect.fill(using: .sourceAtop)
        tinted.unlockFocus()
        return tinted
    }
    
    public func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // Status header
        let statusTitle: String
        if isRecording {
            statusTitle = "● Recording Arabic Speech..."
        } else if isTranscribing {
            statusTitle = "⏳ Transcribing via OpenAI..."
        } else {
            statusTitle = "Haki — حكي (\(AppSettings.shared.shortcut.displayString))"
        }
        let header = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        
        menu.addItem(NSMenuItem.separator())
        
        // Dictation Toggle
        let toggleTitle = isRecording ? "Stop Dictation" : "Start Dictation (\(AppSettings.shared.shortcut.displayString))"
        let dictationItem = NSMenuItem(title: toggleTitle, action: #selector(toggleDictationClicked), keyEquivalent: "")
        dictationItem.target = self
        menu.addItem(dictationItem)
        self.dictationMenuItem = dictationItem
        
        // Microphones Submenu
        let micItem = NSMenuItem(title: "Microphone", action: nil, keyEquivalent: "")
        let micMenu = NSMenu(title: "Microphone")
        
        let devices = AudioDeviceManager.shared.availableDevices
        let selectedUID = AudioDeviceManager.shared.selectedDevice?.uid
        
        if devices.isEmpty {
            let noMicItem = NSMenuItem(title: "No input devices found", action: nil, keyEquivalent: "")
            noMicItem.isEnabled = false
            micMenu.addItem(noMicItem)
        } else {
            for device in devices {
                let devItem = NSMenuItem(
                    title: device.name + (device.isDefault ? " (Default)" : ""),
                    action: #selector(deviceSelected(_:)),
                    keyEquivalent: ""
                )
                devItem.target = self
                devItem.representedObject = device.uid
                devItem.state = (device.uid == selectedUID) ? .on : .off
                micMenu.addItem(devItem)
            }
        }
        
        micItem.submenu = micMenu
        menu.addItem(micItem)
        
        // Model Submenu
        let currentModel = AppSettings.shared.model
        let modelItem = NSMenuItem(title: "Model: \(currentModel.displayName)", action: nil, keyEquivalent: "")
        let modelMenu = NSMenu(title: "Transcription Model")
        for model in TranscriptionModel.allCases {
            let mItem = NSMenuItem(
                title: model.displayName,
                action: #selector(modelSelected(_:)),
                keyEquivalent: ""
            )
            mItem.target = self
            mItem.representedObject = model.rawValue
            mItem.state = (model == currentModel) ? .on : .off
            modelMenu.addItem(mItem)
        }
        modelItem.submenu = modelMenu
        menu.addItem(modelItem)
        
        // Language Submenu
        let currentLang = TranscriptionLanguage(rawValue: AppSettings.shared.language) ?? .arabic
        let langItem = NSMenuItem(title: "Language: \(currentLang.displayName)", action: nil, keyEquivalent: "")
        let langMenu = NSMenu(title: "Transcription Language")
        for lang in TranscriptionLanguage.allCases {
            let lItem = NSMenuItem(
                title: lang.displayName,
                action: #selector(languageSelected(_:)),
                keyEquivalent: ""
            )
            lItem.target = self
            lItem.representedObject = lang.rawValue
            lItem.state = (lang.rawValue == AppSettings.shared.language) ? .on : .off
            langMenu.addItem(lItem)
        }
        langItem.submenu = langMenu
        menu.addItem(langItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Accessibility Warning if needed
        if !AccessibilityHelper.shared.isAccessibilityGranted() {
            let permItem = NSMenuItem(
                title: "⚠️ Grant Accessibility Permission...",
                action: #selector(openPermissionsClicked),
                keyEquivalent: ""
            )
            permItem.target = self
            menu.addItem(permItem)
            
            let restartItem = NSMenuItem(
                title: "🔄 Restart Haki to Apply Permission",
                action: #selector(restartAppClicked),
                keyEquivalent: ""
            )
            restartItem.target = self
            menu.addItem(restartItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Haki", action: #selector(quitAppClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - NSMenuDelegate
    public func menuNeedsUpdate(_ menu: NSMenu) {
        AudioDeviceManager.shared.refreshDevices()
        rebuildMenu(menu)
    }
    
    // MARK: - Actions
    @objc private func toggleDictationClicked() {
        DictationCoordinator.shared.toggleDictation()
    }
    
    @objc private func deviceSelected(_ sender: NSMenuItem) {
        if let uid = sender.representedObject as? String {
            AudioDeviceManager.shared.selectDevice(uid: uid)
        }
    }
    
    @objc private func modelSelected(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String,
           let model = TranscriptionModel(rawValue: raw) {
            AppSettings.shared.model = model
        }
    }
    
    @objc private func languageSelected(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String {
            AppSettings.shared.language = raw
        }
    }
    
    @objc private func openSettingsClicked() {
        SettingsWindowController.shared.showSettings()
    }
    
    @objc private func openPermissionsClicked() {
        AccessibilityHelper.shared.openSystemAccessibilitySettings()
    }
    
    @objc private func restartAppClicked() {
        AccessibilityHelper.shared.relaunchApp()
    }
    
    @objc private func quitAppClicked() {
        NSApp.terminate(nil)
    }
}
