# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Automatic Microphone Preference**: Optional setting (enabled by default) that automatically selects AirPods when they connect, then any USB microphone, falling back to the system default. Toggle in Settings → Audio.

### Fixed
- **"No speech detected" after short recordings**: Audio buffer writes are now fully drained before the recording file is closed, so the tail of a recording is no longer lost.
- **OpenAI 400 "Audio file might be corrupted or unsupported"**: Recordings are now written as a standard 16-bit mono PCM WAV via `AVAudioConverter` instead of the raw (often non-interleaved) device format, which WAV cannot hold.
- **False "No speech detected" on quiet microphones**: Removed the local RMS energy gate; only recordings shorter than 0.35 s are rejected locally and the transcription API judges speech content.
- **Incorrect RMS calculation** for interleaved and multi-channel microphone buffers.

### Changed
- `SilenceDetector.isSilent` replaced by `SilenceDetector.isTooShort` reflecting the relaxed local filtering.

## [0.1.0] - 2026-09-05

### Added
- **Initial native macOS release of Haki / حكي**: Lightweight menu bar application built with Swift, SwiftUI, AppKit, AVFoundation, and Security.framework.
- **Arabic Dictation**: Built specifically for natural Arabic with Syrian and Levantine dialect preservation and code-switched English vocabulary support.
- **OpenAI Audio API Integration**: Direct URLSession multipart implementation without third-party dependencies.
- **Model Selector**: Support for `gpt-transcribe` (recommended default) and `gpt-4o-transcribe` (high accuracy).
- **Global Push-to-Talk**: Customizable system-wide hotkey (`⌥ Option + Space` default) that intercepts key-down/up across any active application.
- **Microphone Selection**: Real-time CoreAudio hardware device routing with support for built-in mics, USB devices, and AirPods.
- **Silence & Zero-Energy Detection**: RMS audio analysis rejecting accidental clicks and silent recordings.
- **Automatic Paste**: Background clipboard paste with keystroke debounce and previous clipboard state restoration.
- **Keychain Security**: Secure API key storage via macOS Keychain with backward-compatible migration.
- **Floating Visual HUD**: Non-activating overlay showing recording, transcribing, and completion states.
- **Original App Branding**: Custom macOS squircle application icon with microphone and Arabic speech waveform motifs.
