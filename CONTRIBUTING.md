# Contributing to Haki

Thank you for your interest in improving Haki! We welcome community contributions that preserve our commitment to a lightweight, fast, and native macOS application.

---

## Contribution Workflow

1. **Fork the Repository**: Fork the project on GitHub to your personal account.
2. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make Your Changes**: Keep modifications focused, clean, and well-structured.
4. **Run Automated Tests**:
   Ensure all unit and integration tests pass before submitting your PR:
   ```bash
   swift test
   ```
5. **Open a Pull Request**: Submit your pull request against the `main` branch with a clear description of your changes.

---

## Core Guidelines

- **Zero Heavy AI Dependencies**: Do not introduce local speech models, Python runtimes, Node.js environments, Electron, PyTorch, or large third-party packages.
- **No Secrets**: Never commit API keys, personal access tokens, or private credentials.
- **Preserve Native macOS Experience**: All UI should adhere to native macOS and Apple Human Interface Guidelines (Swift, SwiftUI, AppKit).
- **Security & Privacy First**: Audio files must never be persisted, and credentials must remain securely stored in Keychain.
