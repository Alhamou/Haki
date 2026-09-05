# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

---

## Reporting a Vulnerability

We take the security of Haki and user privacy seriously.

- **Do NOT report vulnerabilities or leaked credentials publicly** via GitHub issues, discussions, or pull requests.
- **Use GitHub Private Vulnerability Reporting**: If enabled on this repository, please submit a report through the **Security** tab -> **Report a vulnerability**.
- Provide a detailed summary of the vulnerability, steps to reproduce, and potential impact.

---

## Security Architecture & Best Practices

- **Keychain Storage**: OpenAI API keys are stored exclusively in the macOS Keychain (`Security.framework`) and are never written to `UserDefaults`, plists, source code, or application logs.
- **Zero Audio Retention**: Audio recordings are treated as ephemeral scratch data and deleted immediately upon transcription completion or failure.
- **Log Scrubbing**: Diagnostic logs deliberately scrub sensitive strings, keys, audio buffers, and private text.
