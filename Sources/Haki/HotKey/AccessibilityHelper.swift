import Foundation
import AppKit
import ApplicationServices

import Combine

public final class AccessibilityHelper: ObservableObject {
    public static let shared = AccessibilityHelper()
    
    @Published public private(set) var isGranted: Bool = false
    private var timer: Timer?
    
    private init() {
        self.isGranted = AXIsProcessTrusted()
        startMonitoring()
    }
    
    public func checkPermission() {
        let granted = AXIsProcessTrusted()
        if granted != self.isGranted {
            DispatchQueue.main.async {
                self.isGranted = granted
            }
        }
    }
    
    public func startMonitoring() {
        checkPermission()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkPermission()
        }
        
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    /// Returns true if Accessibility permission is granted for this application.
    public func isAccessibilityGranted() -> Bool {
        let granted = AXIsProcessTrusted()
        if granted != isGranted {
            DispatchQueue.main.async {
                self.isGranted = granted
            }
        }
        return granted
    }
    
    /// Prompts system dialog requesting Accessibility permission.
    public func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        checkPermission()
        AppLogger.shared.info("Requested accessibility permission. Trusted: \(trusted)")
    }
    
    /// Opens macOS System Settings directly to Accessibility permissions pane.
    public func openSystemAccessibilitySettings() {
        requestAccessibilityPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
