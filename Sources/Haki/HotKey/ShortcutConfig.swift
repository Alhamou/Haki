import Foundation
import AppKit

public struct ShortcutConfig: Equatable, Codable {
    public var keyCode: UInt16
    public var modifiersRaw: UInt
    
    public init(keyCode: UInt16 = 49, modifiers: NSEvent.ModifierFlags = .option) {
        self.keyCode = keyCode
        self.modifiersRaw = modifiers.intersection([.command, .option, .control, .shift]).rawValue
    }
    
    public var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiersRaw)
    }
    
    public var keyParts: [String] {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃ Control") }
        if modifiers.contains(.option) { parts.append("⌥ Option") }
        if modifiers.contains(.shift) { parts.append("⇧ Shift") }
        if modifiers.contains(.command) { parts.append("⌘ Command") }
        parts.append(ShortcutHelper.keyName(for: keyCode))
        return parts
    }
    
    public var displayString: String {
        return keyParts.joined(separator: " + ")
    }
    
    public static let defaultShortcut = ShortcutConfig(keyCode: 49, modifiers: .option)
}

import Carbon

public enum ShortcutHelper {
    public static func keyName(for keyCode: UInt16) -> String {
        switch keyCode {
        // Special & Whitespace Keys
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 53: return "Escape"
        case 10: return "§"
        
        // Navigation & Editing
        case 115: return "Home"
        case 119: return "End"
        case 116: return "Page Up"
        case 121: return "Page Down"
        case 117: return "Forward Delete"
        case 114: return "Help"
        
        // Arrow Keys
        case 123: return "Left Arrow"
        case 124: return "Right Arrow"
        case 125: return "Down Arrow"
        case 126: return "Up Arrow"
        
        // Function Keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 105: return "F13"
        case 107: return "F14"
        case 113: return "F15"
        case 106: return "F16"
        case 64: return "F17"
        case 79: return "F18"
        case 80: return "F19"
        case 90: return "F20"
        
        // Keypad Keys
        case 65: return "Keypad ."
        case 67: return "Keypad *"
        case 69: return "Keypad +"
        case 71: return "Keypad Clear"
        case 75: return "Keypad /"
        case 76: return "Keypad Enter"
        case 78: return "Keypad -"
        case 81: return "Keypad ="
        case 82: return "Keypad 0"
        case 83: return "Keypad 1"
        case 84: return "Keypad 2"
        case 85: return "Keypad 3"
        case 86: return "Keypad 4"
        case 87: return "Keypad 5"
        case 88: return "Keypad 6"
        case 89: return "Keypad 7"
        case 91: return "Keypad 8"
        case 92: return "Keypad 9"
        
        // Letters
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        
        // Numbers
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        
        // Punctuation & Symbols
        case 27: return "-"
        case 24: return "="
        case 33: return "["
        case 30: return "]"
        case 42: return "\\"
        case 41: return ";"
        case 39: return "'"
        case 43: return ","
        case 47: return "."
        case 44: return "/"
        case 50: return "`"
            
        default:
            if let translated = translateKeyCodeUsingKeyboardLayout(keyCode: keyCode) {
                return translated
            }
            return "Key \(keyCode)"
        }
    }
    
    private static func translateKeyCodeUsingKeyboardLayout(keyCode: UInt16) -> String? {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let layoutDataRef = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let layoutData = unsafeBitCast(layoutDataRef, to: CFData.self)
        guard let keyLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>?.self) else {
            return nil
        }
        
        var keysDown: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var realLength: Int = 0
        
        let status = UCKeyTranslate(
            keyLayout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &keysDown,
            chars.count,
            &realLength,
            &chars
        )
        
        if status == noErr && realLength > 0 {
            let str = String(utf16CodeUnits: chars, count: realLength).trimmingCharacters(in: .whitespacesAndNewlines)
            if !str.isEmpty {
                return str.uppercased()
            }
        }
        return nil
    }
}
