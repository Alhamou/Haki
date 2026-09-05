import Foundation
import os.log

public final class AppLogger {
    public static let shared = AppLogger()
    
    private let osLogger = os.Logger(subsystem: "com.alhamou.haki", category: "General")
    private let lock = NSLock()
    private var logs: [String] = []
    private let maxLogCount = 200
    
    private init() {}
    
    public func info(_ message: String) {
        osLogger.info("\(message, privacy: .public)")
        appendLog("[INFO] \(message)")
    }
    
    public func debug(_ message: String) {
        osLogger.debug("\(message, privacy: .public)")
        appendLog("[DEBUG] \(message)")
    }
    
    public func warning(_ message: String) {
        osLogger.warning("\(message, privacy: .public)")
        appendLog("[WARN] \(message)")
    }
    
    public func error(_ message: String) {
        osLogger.error("\(message, privacy: .public)")
        appendLog("[ERROR] \(message)")
    }
    
    private func appendLog(_ entry: String) {
        lock.lock()
        defer { lock.unlock() }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        logs.append("\(timestamp) \(entry)")
        if logs.count > maxLogCount {
            logs.removeFirst(logs.count - maxLogCount)
        }
    }
    
    public func getRecentLogs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return logs
    }
    
    public func clearLogs() {
        lock.lock()
        defer { lock.unlock() }
        logs.removeAll()
    }
}
