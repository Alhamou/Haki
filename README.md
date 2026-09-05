# ArabicDictation

A native, ultra-lightweight macOS menu bar application for Arabic voice dictation powered by the OpenAI Audio Transcription API.

Focus any text field in any macOS application, hold a global hotkey, speak in Arabic, and release—your speech is transcribed and pasted instantly at your current cursor position.

Zero local AI models. Zero Python. Zero Node.js runtime. Zero Electron. Zero heavy dependencies.

---

## Features

- **Push-to-Talk Global Hotkey (`⌥ Option + Space`)**: Press and hold to speak Arabic, release to automatically transcribe and paste at your cursor in any active application.
- **Selectable OpenAI Transcription Models**:
  - **`gpt-transcribe`** (*Default & Recommended*): Fast, cost-efficient, low-latency transcription optimized for daily voice typing.
  - **`gpt-4o-transcribe`** (*High Accuracy*): Flagship audio transcription model for complex phrases, dialects, and technical terminology.
- **Arabic & Syrian / Levantine Dialect Preservation**: Tuned specifically for Arabic (`language: ar`) with context prompting that preserves Syrian/Levantine colloquialisms, regional proper nouns, and technical English terms (e.g., *GitHub*, *API*, *Docker*).
- **Menu Bar Resident (`LSUIElement`)**: Unobtrusive status bar presence with real-time state icons (Idle, Recording, Transcribing), device selector, and one-click dictation toggle.
- **Dynamic Microphone Selection**: Seamlessly switches between built-in microphones, USB audio interfaces, and AirPods with automatic reconnection handling via CoreAudio HAL.
- **Live Input Level & Silence Rejection**: Real-time VU metering with automatic silence and zero-energy detection, preventing empty or accidental API requests.
- **Safe Clipboard Auto-Paste**: Preserves your existing clipboard contents by saving and restoring them after paste injection, without stealing focus from your active application.
- **Secure Keychain Storage**: Your OpenAI API key is stored exclusively in the macOS Keychain (`Security.framework`). Never written to `UserDefaults`, plists, source files, or git.
- **Zero Audio Footprint**: Audio is captured to temporary scratch files and deleted immediately upon completion or failure. No local audio history is ever retained.
- **Floating Visual HUD**: A subtle, non-activating floating indicator displaying live recording status, transcribing progress, and completion states.

---

## Supported Models

| Model Identifier | Display Name | Recommended Use Case |
| :--- | :--- | :--- |
| `gpt-transcribe` | **GPT Transcribe** *(Default & Recommended)* | Fast, low-latency, cost-effective daily voice typing. |
| `gpt-4o-transcribe` | **GPT-4o Transcribe** *(High Accuracy)* | Maximum transcription accuracy for complex vocabulary and mixed dialects. |

The transcription model can be switched at any time from **Settings → Transcription**.

---

## Requirements

- **Operating System**: macOS 13.0 (Ventura) or newer (macOS 14 Sonoma, macOS 15 Sequoia, and newer supported).
- **Hardware Architecture**: Apple Silicon (arm64 native: M1, M2, M3, M4) or Intel (x86_64).
- **OpenAI Account**: An active OpenAI API key with access to Audio Transcription endpoints.
- **Permissions**:
  - **Microphone**: Required to capture your voice while holding push-to-talk.
  - **Accessibility**: Required for global hotkey interception (`CGEventTap`) and simulating `⌘ + V` paste injection.

---

## Build from Source

### Prerequisites
- macOS with Xcode Command Line Tools installed (`xcode-select --install`).
- Swift 6.0 or newer (`swift --version`).

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/ArabicDictation.git
cd ArabicDictation
```

### 2. Build via Swift Package Manager
```bash
# Build debug binary
swift build

# Run test suite
swift test

# Build release binary
swift build -c release
```

### 3. Package as Native `.app` Bundle
Use the automated build and packaging script:
```bash
chmod +x scripts/build_app.sh
./scripts/build_app.sh
```

This script will:
1. Compile the release binary (`swift build -c release`).
2. Construct the macOS app bundle structure (`build/ArabicDictation.app`).
3. Compile and link `AppIcon.icns` and `Info.plist`.
4. Sign the bundle with your local Apple Development certificate or ad-hoc signature.
5. Install or update the application in `/Applications/ArabicDictation.app`.

---

## Step-by-Step Usage Guide

1. **Launch the App**: Open `ArabicDictation.app` from `/Applications` or your `build/` folder. A microphone icon (🎙️) will appear in your menu bar.
2. **Grant Permissions**:
   - When prompted, grant **Microphone** access.
   - Open **System Settings → Privacy & Security → Accessibility** and ensure **ArabicDictation** is enabled.
3. **Open Settings**: Click the menu bar icon (🎙️) and select **Settings…** (or press `⌘ ,`).
4. **Paste OpenAI API Key**: Under the **Transcription** tab, enter your OpenAI API key (`sk-...`) and click **Save**. Click **Test API Key** to verify connectivity.
5. **Select Model**: Choose your preferred transcription model (default: `GPT Transcribe — Recommended`).
6. **Select Microphone**: Under the **Audio** tab, choose your desired input device (e.g. Built-in Microphone, USB headset, or AirPods) and test the live input level meter.
7. **Focus Any Text Field**: Click into any text field or editor (TextEdit, Notes, Slack, WhatsApp, Cursor, Terminal, Browser, Word, etc.).
8. **Dictate**:
   - Press and **hold** `⌥ Option + Space`.
   - Speak your Arabic sentence or phrase.
   - **Release** `⌥ Option + Space`.
   - The audio is sent to OpenAI and the transcribed Arabic text is automatically typed at your active cursor!

---

## Detailed Permissions Explanation

### 1. Microphone (`NSMicrophoneUsageDescription`)
- **Why is it needed?** AVFoundation requires explicit user consent to capture input from your selected audio hardware.
- **When is audio captured?** Only during the exact duration you hold down the push-to-talk hotkey (or click "Start Dictation"). Audio recording stops the instant you release the hotkey.

### 2. Accessibility (`AXIsProcessTrusted`)
- **Why is it needed?**
  1. **Global Push-to-Talk (`CGEventTap`)**: macOS security requires Accessibility privileges to listen for the global `⌥ Option + Space` key combination across third-party background applications.
  2. **Automatic Text Insertion (`CGEvent`)**: To insert transcribed text at your current cursor position without stealing window focus, the app simulates a native `⌘ + V` (Command+V) keystroke.
- **Input Monitoring**: *Not required separately*. Trusted Accessibility permission grants the necessary tap privileges for global hotkey handling.

---

## Privacy Guarantee

- **Zero Tracking & Telemetry**: No analytics, diagnostics, crash reporters, or third-party SDKs are embedded.
- **No Local Audio Retained**: Audio is recorded directly to temporary scratch files (`NSTemporaryDirectory()`) and deleted immediately after transcription completes or errors out.
- **Keychain Security**: Your OpenAI API key is encrypted and stored in your local macOS Keychain (`kSecClassGenericPassword`). It is never stored in plaintext, `UserDefaults`, configuration files, or logs.
- **Direct API Communication**: Audio payloads are transmitted directly from your Mac to `https://api.openai.com/v1/audio/transcriptions` over TLS. No intermediary servers or proxies are involved.

---

## Development & Testing

### Running Tests
ArabicDictation includes a comprehensive unit test suite covering model selection, fallback logic, settings persistence, multipart payload generation, paste timings, and silence detection:

```bash
swift test
```

### Project Structure
```
ArabicDictation/
├── Package.swift               # SPM project manifest
├── Resources/
│   ├── AppIcon.icns            # 1024x1024 macOS app icon
│   └── Info.plist              # Bundle metadata (LSUIElement, permissions)
├── Sources/ArabicDictation/
│   ├── App/                    # App lifecycle, AppDelegate, StatusItemController
│   ├── Audio/                  # AudioRecorder, AudioDeviceManager (CoreAudio HAL)
│   ├── Hotkey/                 # GlobalHotkeyManager (CGEventTap)
│   ├── HUD/                    # FloatingHUDController, HUDView
│   ├── Paste/                  # PasteManager (CGEvent, clipboard restoration)
│   ├── Services/               # OpenAIService, KeychainHelper
│   ├── Settings/               # AppSettings, SettingsView, TranscriptionModel
│   └── UI/                     # Menu bar & status presentation
├── Tests/ArabicDictationTests/ # Unit & integration test suites
├── scripts/
│   ├── build_app.sh            # Packaging & codesigning script
│   ├── generate_icon.swift     # CoreGraphics 1024x1024 master icon generator
│   └── make_icons.sh           # iconutil pipeline script
├── CONTRIBUTING.md             # Contribution guidelines
├── SECURITY.md                 # Vulnerability reporting & security policy
├── CHANGELOG.md                # Version history & release notes
└── LICENSE                     # MIT License
```

---

## Contributing & Security

- Contributions are welcome! Please review [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on code style, branch structure, and pull requests.
- For security concerns or responsible disclosure, please refer to [SECURITY.md](SECURITY.md).

---

## License

This project is licensed under the [MIT License](LICENSE).
