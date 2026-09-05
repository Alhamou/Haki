# Arabic Dictation for macOS 🎙️🇸🇾

A native, ultra-lightweight macOS menu bar application for Arabic voice dictation powered by OpenAI's Audio Transcription API (`gpt-4o-transcribe`, `language: ar`).

Built from scratch using **Swift**, **SwiftUI**, **AppKit**, **AVFoundation**, and **Security.framework**.

Zero local AI models, zero Python, zero Node.js runtime, zero Electron, zero large dependencies.

---

## Features

- **Push-to-Talk Global Hotkey (`⌥ Option + Space`)**: Press and hold to speak Arabic, release to automatically transcribe and paste at your cursor in any active application.
- **Arabic & Syrian Dialect Preservation**: Configured specifically for Arabic with custom context prompting preserving Syrian/Levantine dialects, proper nouns, regional places, and code-switched English words (e.g. *GitHub*, *TakeCar*).
- **Menu Bar Resident (`LSUIElement`)**: Unobtrusive status bar app with dynamic state icons (Idle, Recording, Transcribing), device switcher, and one-click dictation toggle.
- **Dynamic Microphone Selection**: Seamlessly switches between built-in mics, USB headsets, and AirPods with automatic reconnection handling via CoreAudio HAL.
- **Live Input Level & Silence Rejection**: Real-time VU metering with automatic silence and zero-energy detection, preventing unnecessary or accidental API calls.
- **Safe Clipboard Auto-Paste**: Restores previous clipboard contents after pasting, preserving your clipboard history without stealing focus from your active app.
- **Secure Keychain Storage**: OpenAI API key is stored exclusively in macOS Keychain (`Security.framework`). Never stored in `UserDefaults`, plists, source files, or git.
- **Zero Audio Footprint / Complete Privacy**: Audio is recorded to temporary scratch files and strictly deleted immediately after transcription completes or fails. No local audio history is ever saved.
- **Floating Visual HUD**: A subtle, non-activating floating pill indicator showing live recording status, transcribing progress, and completion checks.

---

## Target Platform & Requirements

- **OS**: macOS 13.0 (Ventura) or newer (tested on macOS 14 & macOS 26 Apple Silicon).
- **Architecture**: Apple Silicon (arm64) native.
- **OpenAI API Key**: With access to OpenAI Audio Transcriptions (`gpt-4o-transcribe` / `whisper-1`).

---

## Required Permissions

1. **Microphone (`NSMicrophoneUsageDescription`)**:
   - Required by AVFoundation to capture audio when push-to-talk is engaged.
   - You will be prompted on first launch or you can enable it in **System Settings → Privacy & Security → Microphone**.
2. **Accessibility**:
   - Required for:
     1. Global Push-to-Talk shortcut interception (`CGEventTap`) across any active application.
     2. Simulating the `⌘ + V` keystroke to paste the transcribed Arabic text at your active cursor.
   - Enable in **System Settings → Privacy & Security → Accessibility** for `ArabicDictation`.
3. **Input Monitoring**:
   - *Not required separately.* Trusted Accessibility permission enables `CGEventTap` globally.

---

## Build & Installation

### Option 1: Automated Build Script (Recommended)

Run the included build script from the repository root:

```bash
chmod +x scripts/build_app.sh
./scripts/build_app.sh
```

This compiles a release binary, codesigns it with entitlements, packages it to:
- `build/ArabicDictation.app`
- and installs it to `/Applications/ArabicDictation.app` (if not already existing).

### Option 2: Swift Package Manager (CLI)

```bash
# Build binary
swift build -c release

# Run all unit and integration tests
swift test
```

---

## Usage Guide

1. **Launch App**: Open `/Applications/ArabicDictation.app` or `build/ArabicDictation.app`.
2. **Enter API Key**:
   - Click the 🎙️ icon in the macOS menu bar and select **Settings…**.
   - Under the **Transcription** tab, paste your OpenAI API key and click **Save** (and optionally **Test API Key** to verify connection).
3. **Check Microphone**:
   - In **Settings → Audio**, verify your desired microphone is selected.
   - Click **Test Microphone** to test the live VU input-level meter.
4. **Dictate**:
   - Focus any app (TextEdit, Notes, WhatsApp, Slack, Cursor, Terminal, Browser, etc.).
   - Press and **hold** `⌥ Option + Space`.
   - Speak your Arabic sentence.
   - **Release** `⌥ Option + Space`.
   - The app sends the audio to OpenAI and pastes the transcribed Arabic text directly at your cursor!

---

## Dialect & Arabic Test Sentences

The app is tuned to faithfully transcribe standard and colloquial Arabic:

1. `مرحبا، هذا اختبار لتحويل الصوت إلى كتابة باللغة العربية.`
2. `اليوم بدي روح عالمزة وبعدين مرق ع ساحة الأمويين.`
3. `خلينا نجرب إذا البرنامج بيفهم اللهجة السورية بشكل منيح.`
4. `بدي افتح GitHub وبعدين شغل مشروع TakeCar.`

---

## Privacy Notice

> Audio is recorded only while you hold down the Push-to-Talk shortcut (or click Start Dictation).
> Audio files are saved as temporary WAV files and are strictly deleted immediately upon transcription completion or failure.
> Your API key is encrypted and stored in your macOS Keychain.

---

## License

MIT License.
