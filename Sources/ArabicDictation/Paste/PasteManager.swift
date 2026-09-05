import Foundation
import AppKit
import ApplicationServices

public final class PasteManager {
    public static let shared = PasteManager()
    
    private init() {}
    
    /// Pastes text at the current cursor position in the active application.
    @discardableResult
    public func pasteText(_ text: String, restoreClipboard: Bool = true) -> Bool {
        guard !text.isEmpty else { return false }
        
        let pasteboard = NSPasteboard.general
        
        // 1. Save previous clipboard state
        var previousItems: [[NSPasteboard.PasteboardType: Data]] = []
        if restoreClipboard, let items = pasteboard.pasteboardItems {
            for item in items {
                var dict: [NSPasteboard.PasteboardType: Data] = [:]
                for type in item.types {
                    if let data = item.data(forType: type) {
                        dict[type] = data
                    }
                }
                if !dict.isEmpty {
                    previousItems.append(dict)
                }
            }
        }
        
        // 2. Set new transcribed text
        pasteboard.clearContents()
        let setSuccess = pasteboard.setString(text, forType: .string)
        guard setSuccess else {
            AppLogger.shared.error("Failed to set transcribed text into clipboard.")
            return false
        }
        
        // If accessibility is not granted, macOS blocks synthetic keystrokes.
        // Keep the transcribed text on the clipboard so the user can manually paste it!
        guard AccessibilityHelper.shared.isAccessibilityGranted() else {
            AppLogger.shared.warning("Accessibility permission missing; transcribed text copied to clipboard, but auto-paste Cmd+V is blocked by macOS.")
            return false
        }
        
        // 3. Synthesize Command + V keystroke
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 0x09 // Virtual key code for 'V'
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            AppLogger.shared.error("Failed to create CGEvent for paste.")
            return false
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        usleep(25000) // 25ms delay so the key down is properly registered before key up
        keyUp.post(tap: .cghidEventTap)
        
        AppLogger.shared.info("Synthesized Cmd+V event to paste Arabic text.")
        
        // 4. Restore original clipboard content after application has processed the paste
        if restoreClipboard && !previousItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                pasteboard.clearContents()
                for itemDict in previousItems {
                    let item = NSPasteboardItem()
                    for (type, data) in itemDict {
                        item.setData(data, forType: type)
                    }
                    pasteboard.writeObjects([item])
                }
                AppLogger.shared.info("Restored previous clipboard contents.")
            }
        }
        
        return true
    }
}
