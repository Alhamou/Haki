import SwiftUI
import AppKit
import AVFoundation

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var deviceManager = AudioDeviceManager.shared
    @ObservedObject var audioRecorder = AudioRecorder.shared
    
    @State private var apiKeyInput: String = ""
    @State private var isTestingAPIKey = false
    @State private var apiTestStatus: String?
    @State private var apiTestSuccess: Bool?
    @State private var selectedTab: SettingsTab = .transcription
    @State private var isRecordingShortcut = false
    @State private var localKeyMonitor: Any?
    
    public init() {}
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case transcription = "Transcription"
        case audio = "Audio"
        case keyboard = "Keyboard"
        case behavior = "Behavior"
        case advanced = "Advanced"
        
        public var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .transcription: return "text.badge.checkmark"
            case .audio: return "mic.fill"
            case .keyboard: return "keyboard"
            case .behavior: return "gearshape.2"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Tab Selector
            HStack(spacing: 16) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                        if tab != .audio && audioRecorder.isTestingMicrophone {
                            audioRecorder.stopMicrophoneTest()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .transcription:
                        transcriptionSection
                    case .audio:
                        audioSection
                    case .keyboard:
                        keyboardSection
                    case .behavior:
                        behaviorSection
                    case .advanced:
                        advancedSection
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Privacy & Brand Footer
            HStack {
                Image(systemName: "mic.badge.waveform")
                    .foregroundColor(.accentColor)
                Text("Haki • احكي، وحكي بيكتبها")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.secondary)
                Text("Audio is sent to OpenAI only on dictation. Zero local audio kept.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 440)
        .onAppear {
            if let existing = settings.getAPIKey() {
                apiKeyInput = existing
            }
        }
    }
    
    // MARK: - Transcription Tab
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenAI API Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("OpenAI API Key (Stored securely in macOS Keychain):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    SecureField("sk-...", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        let ok = settings.saveAPIKey(apiKeyInput)
                        if ok {
                            apiTestStatus = "Key saved to Keychain."
                            apiTestSuccess = true
                        }
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    if settings.hasAPIKey {
                        Button("Remove API Key") {
                            _ = settings.removeAPIKey()
                            apiKeyInput = ""
                            apiTestStatus = "Key removed from Keychain."
                            apiTestSuccess = nil
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                Button(action: testAPIKey) {
                    HStack(spacing: 6) {
                        if isTestingAPIKey {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        }
                        Text("Test API Key")
                    }
                }
                .disabled(isTestingAPIKey || apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                if let status = apiTestStatus {
                    HStack(spacing: 4) {
                        Image(systemName: apiTestSuccess == true ? "checkmark.circle.fill" : (apiTestSuccess == false ? "xmark.octagon.fill" : "info.circle"))
                            .foregroundColor(apiTestSuccess == true ? .green : (apiTestSuccess == false ? .red : .blue))
                        Text(status)
                            .font(.caption)
                            .foregroundColor(apiTestSuccess == true ? .green : (apiTestSuccess == false ? .red : .primary))
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
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
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("Language:")
                        .foregroundColor(.secondary)
                    HStack {
                        Text("Arabic (ar)")
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Tab
    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Microphone Input")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Microphone:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Live Input Level:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 14)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .yellow, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(audioRecorder.currentAudioLevel)), height: 14)
                            .animation(.easeOut(duration: 0.08), value: audioRecorder.currentAudioLevel)
                    }
                }
                .frame(height: 14)
            }
            
            HStack {
                Button(audioRecorder.isTestingMicrophone ? "Stop Microphone Test" : "Test Microphone") {
                    if audioRecorder.isTestingMicrophone {
                        audioRecorder.stopMicrophoneTest()
                    } else {
                        do {
                            try audioRecorder.startMicrophoneTest(deviceID: deviceManager.selectedDevice?.id)
                        } catch {
                            AppLogger.shared.error("Failed to start mic test: \(error.localizedDescription)")
                        }
                    }
                }
                
                if audioRecorder.isTestingMicrophone {
                    Text("Speak now to verify input level...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Keyboard Tab
    private var keyboardSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Global Push-to-Talk Shortcut")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Hold the shortcut while speaking, then release to transcribe and paste:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: {
                        if isRecordingShortcut {
                            stopRecordingShortcut()
                        } else {
                            startRecordingShortcut()
                        }
                    }) {
                        HStack(spacing: 6) {
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
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isRecordingShortcut ? Color.orange.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isRecordingShortcut ? Color.orange : Color.gray.opacity(0.3), lineWidth: isRecordingShortcut ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if settings.shortcut != .defaultShortcut {
                        Button("Reset to Default") {
                            stopRecordingShortcut()
                            settings.resetShortcutToDefault()
                        }
                        .font(.caption)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
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
                        PresetButton(title: "⌘ ⇧ Space", active: settings.shortcut.displayString == "⇧ Shift + ⌘ Command + Space") {
                            stopRecordingShortcut()
                            settings.setShortcut(keyCode: 49, modifiers: [.command, .shift])
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessibility Permission")
                    .font(.headline)
                
                HStack {
                    if AccessibilityHelper.shared.isAccessibilityGranted() {
                        Label("Accessibility permission is granted.", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Accessibility permission required for global hotkey and auto-paste.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Button("Open System Settings to Grant Permission") {
                                AccessibilityHelper.shared.openSystemAccessibilitySettings()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Behavior Tab
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Application Behavior")
                .font(.headline)
            
            Toggle("Paste automatically at cursor position", isOn: $settings.pasteAutomatically)
            Toggle("Play sound when recording starts/stops", isOn: $settings.playSoundEffects)
            
            Toggle("Launch at Login", isOn: Binding(
                get: { settings.launchAtLogin },
                set: { settings.setLaunchAtLogin(enabled: $0) }
            ))
        }
    }
    
    // MARK: - Advanced Tab
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Arabic Transcription Context & Instructions")
                .font(.headline)
            
            Text("Optional prompt context sent with the OpenAI transcription request to preserve dialects and vocabulary:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $settings.promptContext)
                .font(.system(.body))
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            
            Divider()
            
            Toggle("Show Debug Logs in Diagnostics", isOn: $settings.showDebugLogs)
            
            if settings.showDebugLogs {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Recent Diagnostic Logs:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Clear") {
                            AppLogger.shared.clearLogs()
                        }
                        .font(.caption)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(AppLogger.shared.getRecentLogs(), id: \.self) { log in
                                Text(log)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 100)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                }
            }
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
                        self.apiTestStatus = "API Key is valid!"
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
    
    // MARK: - Shortcut Recording
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

// MARK: - PresetButton UI Component
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
                .background(active ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12))
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

// MARK: - KeyCap UI Component
private struct KeyCapView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
    }
}
