import SwiftUI
import AppKit
import AVFoundation

// MARK: - Navigation Sections
public enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case transcription = "Transcription"
    case audio = "Audio"
    case shortcut = "Shortcut"
    case advanced = "Advanced"
    
    public var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .transcription: return "text.badge.checkmark"
        case .audio: return "mic.fill"
        case .shortcut: return "command"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

// MARK: - Main Settings View
public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var deviceManager = AudioDeviceManager.shared
    @ObservedObject var audioRecorder = AudioRecorder.shared
    
    @State private var selectedSection: SettingsSection
    
    public init(initialSection: SettingsSection = .general) {
        _selectedSection = State(initialValue: initialSection)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // MARK: - Left Sidebar Navigation
                sidebarView
                    .frame(width: 190)
                
                Divider()
                
                // MARK: - Detail Content Area
                VStack(spacing: 0) {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 20) {
                            switch selectedSection {
                            case .general:
                                GeneralSettingsSection(settings: settings)
                            case .transcription:
                                TranscriptionSettingsSection(settings: settings)
                            case .audio:
                                AudioSettingsSection(deviceManager: deviceManager, audioRecorder: audioRecorder)
                            case .shortcut:
                                ShortcutSettingsSection(settings: settings)
                            case .advanced:
                                AdvancedSettingsSection(settings: settings)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            
            Divider()
            
            // MARK: - Subtle Footer
            settingsFooter
        }
        .frame(minWidth: 620, minHeight: 500)
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // App Branding at Top of Sidebar
            HStack(spacing: 8) {
                Image(systemName: "mic.badge.waveform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Haki Settings")
                        .font(.system(size: 13, weight: .bold))
                    Text("احكي، وحكي بيكتبها")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            
            // Section Buttons
            ForEach(SettingsSection.allCases) { section in
                SidebarItemRow(
                    section: section,
                    isSelected: selectedSection == section
                ) {
                    if selectedSection == .audio && section != .audio && audioRecorder.isTestingMicrophone {
                        audioRecorder.stopMicrophoneTest()
                    }
                    selectedSection = section
                }
            }
            
            Spacer()
            
            // Version Info at Sidebar Bottom
            VStack(alignment: .leading, spacing: 2) {
                Text("Haki for Mac")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Version 1.0.0")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Footer View
    private var settingsFooter: some View {
        HStack {
            Text("Haki / حكي")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text("•")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Audio is sent to OpenAI only during transcription.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sidebar Item Row Component
private struct SidebarItemRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.iconName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? .primary : .secondary))
                    .frame(width: 20, alignment: .center)
                
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.12) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(Text(section.rawValue))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - 1. General Settings Section
private struct GeneralSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "General",
                subtitle: "Basic application preferences and system integration."
            )
            
            SettingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Launch Haki at login", isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { settings.setLaunchAtLogin(enabled: $0) }
                    ))
                    .toggleStyle(.switch)
                    
                    Divider()
                    
                    Toggle("Play sound when recording starts and stops", isOn: $settings.playSoundEffects)
                        .toggleStyle(.switch)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Paste transcribed text automatically", isOn: $settings.pasteAutomatically)
                            .toggleStyle(.switch)
                        Text("When enabled, transcribed text is automatically pasted at your active cursor upon completion.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Show floating status HUD", isOn: $settings.showFloatingHUD)
                            .toggleStyle(.switch)
                        Text("Displays a sleek visual indicator at the bottom of your screen during speech and transcription.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - 2. Transcription Settings Section
private struct TranscriptionSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    @State private var apiKeyInput: String = ""
    @State private var isTestingAPIKey = false
    @State private var apiTestStatus: String?
    @State private var apiTestSuccess: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Transcription",
                subtitle: "Configure your OpenAI speech model and dialect instructions."
            )
            
            // OpenAI API Key Card
            SettingsCard(title: "OpenAI API") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter your OpenAI API key. Stored securely in macOS Keychain:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        SecureField("sk-...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(Text("OpenAI API Key"))
                        
                        Button("Save Key") {
                            let ok = settings.saveAPIKey(apiKeyInput)
                            if ok {
                                apiTestStatus = "Key saved to Keychain."
                                apiTestSuccess = true
                            }
                        }
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: testAPIKey) {
                            HStack(spacing: 6) {
                                if isTestingAPIKey {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .frame(width: 12, height: 12)
                                }
                                Text("Test Connection")
                            }
                        }
                        .disabled(isTestingAPIKey || apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        if settings.hasAPIKey {
                            Button("Remove Key") {
                                _ = settings.removeAPIKey()
                                apiKeyInput = ""
                                apiTestStatus = "Key removed from Keychain."
                                apiTestSuccess = nil
                            }
                            .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                    
                    if let status = apiTestStatus {
                        HStack(spacing: 6) {
                            Image(systemName: apiTestSuccess == true ? "checkmark.circle.fill" : (apiTestSuccess == false ? "exclamationmark.triangle.fill" : "info.circle"))
                                .foregroundColor(apiTestSuccess == true ? .green : (apiTestSuccess == false ? .red : .accentColor))
                            Text(status)
                                .font(.caption)
                                .foregroundColor(apiTestSuccess == true ? .green : (apiTestSuccess == false ? .red : .primary))
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .onAppear {
                if let existing = settings.getAPIKey() {
                    apiKeyInput = existing
                }
            }
            
            // Model & Language Card
            SettingsCard(title: "Model & Language") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transcription Model:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.model) {
                            ForEach(TranscriptionModel.allCases) { modelOption in
                                Text(modelOption.displayName).tag(modelOption)
                            }
                        }
                        .labelsHidden()
                        
                        Text(settings.model.modelDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Language:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.language) {
                            ForEach(TranscriptionLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let selected = TranscriptionLanguage(rawValue: settings.language) {
                            Text(selected.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // Custom Instructions Card
            SettingsCard(title: "Custom Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional instructions sent with dictation to preserve dialect vocabulary, names, and mixed terms:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $settings.promptContext)
                        .font(.system(.body))
                        .frame(height: 75)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack {
                        Spacer()
                        Button("Reset Instructions to Default") {
                            settings.promptContext = AppSettings.defaultPromptContext
                        }
                        .font(.caption)
                    }
                }
            }
            
            // Privacy Note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.secondary)
                Text("Audio is sent to OpenAI only when you finish dictation. No local audio is permanently saved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    private func testAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        
        isTestingAPIKey = true
        apiTestStatus = "Testing connection to OpenAI..."
        apiTestSuccess = nil
        
        Task {
            do {
                let valid = try await OpenAIService.shared.validateAPIKey(key)
                await MainActor.run {
                    self.isTestingAPIKey = false
                    if valid {
                        self.apiTestStatus = "API Key is valid and active!"
                        self.apiTestSuccess = true
                        _ = settings.saveAPIKey(key)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isTestingAPIKey = false
                    self.apiTestStatus = error.localizedDescription
                    self.apiTestSuccess = false
                }
            }
        }
    }
}

// MARK: - 3. Audio Settings Section
private struct AudioSettingsSection: View {
    @ObservedObject var deviceManager: AudioDeviceManager
    @ObservedObject var audioRecorder: AudioRecorder
    
    @State private var hasDetectedSound = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Audio",
                subtitle: "Select your input microphone and verify live audio levels."
            )
            
            SettingsCard {
                VStack(alignment: .leading, spacing: 18) {
                    // Microphone Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Microphone")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if deviceManager.availableDevices.isEmpty {
                            Picker("", selection: .constant("")) {
                                Text("Default System Microphone").tag("")
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Picker("", selection: Binding(
                                get: { deviceManager.selectedDevice?.uid ?? "" },
                                set: { newUID in deviceManager.selectDevice(uid: newUID) }
                            )) {
                                ForEach(deviceManager.availableDevices) { device in
                                    Text(device.name + (device.isDefault ? " (Default)" : ""))
                                        .tag(device.uid)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Toggle(isOn: Binding(
                            get: { deviceManager.autoSelectPreferred },
                            set: { newValue in
                                deviceManager.autoSelectPreferred = newValue
                                deviceManager.refreshDevices()
                            }
                        )) {
                            Text("Prefer AirPods when connected, then USB microphones")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .toggleStyle(.switch)
                    }
                    
                    // Live Input Level Meter
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Input Level")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            if audioRecorder.isTestingMicrophone {
                                if hasDetectedSound {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Sound detected")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text("Listening...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.18))
                                    .frame(height: 14)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint, .yellow],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(0, min(geo.size.width, geo.size.width * CGFloat(audioRecorder.currentAudioLevel))),
                                        height: 14
                                    )
                                    .animation(.easeOut(duration: 0.08), value: audioRecorder.currentAudioLevel)
                            }
                        }
                        .frame(height: 14)
                        
                        Text(helperText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Test Microphone Action Button
                    HStack {
                        Button(action: toggleMicrophoneTest) {
                            HStack(spacing: 6) {
                                Image(systemName: audioRecorder.isTestingMicrophone ? "stop.fill" : "play.fill")
                                Text(audioRecorder.isTestingMicrophone ? "Stop Microphone Test" : "Test Microphone")
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .onChange(of: audioRecorder.currentAudioLevel) { level in
            if audioRecorder.isTestingMicrophone && level > 0.05 {
                hasDetectedSound = true
            }
        }
    }
    
    private var helperText: String {
        if !audioRecorder.isTestingMicrophone {
            return "Click 'Test Microphone' to verify your input device and check responsiveness."
        } else if hasDetectedSound {
            return "Microphone is picking up speech properly."
        } else {
            return "Speak clearly into your microphone to verify level meter activity…"
        }
    }
    
    private func toggleMicrophoneTest() {
        if audioRecorder.isTestingMicrophone {
            audioRecorder.stopMicrophoneTest()
            hasDetectedSound = false
        } else {
            hasDetectedSound = false
            do {
                try audioRecorder.startMicrophoneTest(deviceID: deviceManager.selectedDevice?.id)
            } catch {
                AppLogger.shared.error("Failed to start mic test: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 4. Shortcut Settings Section
private struct ShortcutSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    @State private var isRecordingShortcut = false
    @State private var localKeyMonitor: Any?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Shortcut",
                subtitle: "Set up your global push-to-talk dictation hotkey."
            )
            
            // Push to talk visual card
            SettingsCard(title: "Push-to-Talk Hotkey") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Hold the shortcut to record, and release it to transcribe and paste:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Shortcut Keycaps Display & Change Action
                    HStack(spacing: 12) {
                        Button(action: {
                            if isRecordingShortcut {
                                stopRecordingShortcut()
                            } else {
                                startRecordingShortcut()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isRecordingShortcut {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Press shortcut keys now… (Esc to cancel)")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 13, weight: .medium))
                                } else {
                                    ForEach(settings.shortcut.keyParts, id: \.self) { part in
                                        KeyCapView(text: part)
                                    }
                                    
                                    Image(systemName: "pencil")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 13))
                                        .padding(.leading, 4)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isRecordingShortcut ? Color.orange.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isRecordingShortcut ? Color.orange : Color.gray.opacity(0.3), lineWidth: isRecordingShortcut ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Change global shortcut"))
                        
                        if settings.shortcut != .defaultShortcut {
                            Button("Reset to Default") {
                                stopRecordingShortcut()
                                settings.resetShortcutToDefault()
                            }
                            .font(.caption)
                        }
                    }
                    
                    // Behavior explanation flow
                    HStack(spacing: 24) {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            Text("While held:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Recording")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            Text("On release:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Transcribe & paste")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Divider()
                    
                    // Quick Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Presets:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            PresetButton(title: "⌥ Option + Space", active: settings.shortcut.displayString == "⌥ Option + Space") {
                                stopRecordingShortcut()
                                settings.setShortcut(keyCode: 49, modifiers: .option)
                            }
                            PresetButton(title: "⌃ Control + Space", active: settings.shortcut.displayString == "⌃ Control + Space") {
                                stopRecordingShortcut()
                                settings.setShortcut(keyCode: 49, modifiers: .control)
                            }
                            PresetButton(title: "⌥ Option + D", active: settings.shortcut.displayString == "⌥ Option + D") {
                                stopRecordingShortcut()
                                settings.setShortcut(keyCode: 2, modifiers: .option)
                            }
                            PresetButton(title: "⇧ ⌘ Space", active: settings.shortcut.displayString == "⇧ Shift + ⌘ Command + Space") {
                                stopRecordingShortcut()
                                settings.setShortcut(keyCode: 49, modifiers: [.command, .shift])
                            }
                        }
                    }
                }
            }
            
            // Accessibility Permission Card
            SettingsCard(title: "System Permission") {
                VStack(alignment: .leading, spacing: 8) {
                    if AccessibilityHelper.shared.isAccessibilityGranted() {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Accessibility permission is granted.")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Accessibility permission is required for global push-to-talk and auto-paste.")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            
                            Button("Open System Settings to Grant Permission") {
                                AccessibilityHelper.shared.openSystemAccessibilitySettings()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func startRecordingShortcut() {
        stopRecordingShortcut()
        isRecordingShortcut = true
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Cancel on Escape without modifiers
            if event.keyCode == 53 && event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
                stopRecordingShortcut()
                return nil
            }
            
            let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if !flags.isEmpty || (event.keyCode >= 120 && event.keyCode <= 122) || (event.keyCode >= 96 && event.keyCode <= 111) {
                settings.setShortcut(keyCode: event.keyCode, modifiers: flags)
                stopRecordingShortcut()
                return nil
            }
            return event
        }
    }
    
    private func stopRecordingShortcut() {
        isRecordingShortcut = false
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }
}

// MARK: - 5. Advanced Settings Section
private struct AdvancedSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    @State private var showingResetAlert = false
    @State private var copyFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Advanced",
                subtitle: "Diagnostic logging, speech sensitivity thresholds, and reset options."
            )
            
            // Diagnostic Logging Card
            SettingsCard(title: "Diagnostic Logging") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Debug Logging", isOn: $settings.showDebugLogs)
                        .toggleStyle(.switch)
                    Text("Records detailed runtime logs including audio RMS energy, API requests, and latencies.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if settings.showDebugLogs {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Recent Diagnostic Logs:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(copyFeedback ? "Copied!" : "Copy Logs") {
                                    let allLogs = AppLogger.shared.getRecentLogs().joined(separator: "\n")
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(allLogs, forType: .string)
                                    copyFeedback = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        copyFeedback = false
                                    }
                                }
                                .font(.caption)
                                
                                Button("Clear") {
                                    AppLogger.shared.clearLogs()
                                }
                                .font(.caption)
                            }
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 3) {
                                    let logs = AppLogger.shared.getRecentLogs()
                                    if logs.isEmpty {
                                        Text("No log entries recorded yet.")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .padding(6)
                                    } else {
                                        ForEach(logs, id: \.self) { log in
                                            Text(log)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(8)
                            }
                            .frame(height: 110)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Silence Detection Sensitivity Card
            SettingsCard(title: "Speech Detection") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Silence Detection Energy Threshold:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("0.006 RMS")
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Minimum Speech Duration:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("0.35 s")
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    
                    Text("Audio with energy below threshold or shorter than 0.35s is discarded before reaching OpenAI.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            
            // Reset to Defaults Card
            SettingsCard(title: "Restore Defaults") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reset shortcuts, behavior options, and custom dialect prompt to factory defaults:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Restore Default Settings…") {
                        showingResetAlert = true
                    }
                }
            }
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Restore Default Settings?"),
                    message: Text("This will reset all application preferences, shortcuts, and transcription instructions to defaults. Your OpenAI API key in Keychain will remain safe."),
                    primaryButton: .destructive(Text("Restore Defaults")) {
                        settings.resetToDefaults()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// MARK: - Reusable UI Components

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 2)
    }
}

private struct SettingsCard<Content: View>: View {
    var title: String? = nil
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct PresetButton: View {
    let title: String
    let active: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: active ? .semibold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(active ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(active ? Color.accentColor : Color.clear, lineWidth: 1)
                )
                .foregroundColor(active ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct KeyCapView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)
    }
}
