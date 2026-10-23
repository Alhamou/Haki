import Foundation

/// Accepts audio recorded on another device (the AirMouse iPhone page) and hands it to dictation.
///
/// The sender writes the file into `inboxURL` and opens `haki://transcribe?file=<name>`.
/// Only plain file names inside the inbox are accepted, so the URL can't point Haki at other files.
public enum RemoteAudioInbox {
    public static let inboxURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Caches/Haki/Inbox", isDirectory: true)
    
    static let allowedExtensions: Set<String> = ["m4a", "mp4", "webm", "wav", "mp3", "ogg"]
    static let maxFileSize = 25 * 1024 * 1024  // OpenAI transcription upload limit
    
    public static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "haki", url.host?.lowercased() == "transcribe" else {
            AppLogger.shared.warning("Ignoring unsupported URL: \(url.absoluteString)")
            return
        }
        guard let fileURL = resolveFile(from: url) else {
            AppLogger.shared.warning("Rejected incoming audio URL: \(url.absoluteString)")
            return
        }
        AppLogger.shared.info("Received remote audio: \(fileURL.lastPathComponent)")
        DictationCoordinator.shared.transcribeFile(at: fileURL)
    }
    
    /// The inbox file named by `?file=`, or nil if the name is unsafe, missing, or too large.
    static func resolveFile(from url: URL) -> URL? {
        let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "file" })?.value ?? ""
        guard !name.isEmpty, !name.hasPrefix("."), !name.contains("/"), !name.contains("\\") else { return nil }
        
        let fileURL = inboxURL.appendingPathComponent(name, isDirectory: false)
        guard allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { return nil }
        guard fileURL.resolvingSymlinksInPath().deletingLastPathComponent().path
                == inboxURL.resolvingSymlinksInPath().path else { return nil }
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              attributes[.type] as? FileAttributeType == .typeRegular,
              let size = attributes[.size] as? Int, size > 0 else { return nil }
        guard size <= maxFileSize else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        return fileURL
    }
}
