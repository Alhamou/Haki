import Foundation
import AppKit
import ApplicationServices

public final class AccessibilityHelper {
    public static let shared = AccessibilityHelper()
    
    private init() {}
    
    /// Returns true if Accessibility permission is granted for this application.
    public func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Prompts system dialog requesting Accessibility permission.
    public func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        AppLogger.shared.info("Requested accessibility permission. Trusted: \(trusted)")
    }
    
    /// Opens macOS System Settings directly to Accessibility permissions pane.
    public func openSystemAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
