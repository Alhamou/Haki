import XCTest
import AppKit
@testable import Haki

final class ShortcutTests: XCTestCase {
    
    func testDefaultShortcut() {
        let config = ShortcutConfig.defaultShortcut
        XCTAssertEqual(config.keyCode, 49)
        XCTAssertTrue(config.modifiers.contains(.option))
        XCTAssertEqual(config.displayString, "⌥ Option + Space")
    }
    
    func testCustomShortcutEncodingAndDisplay() throws {
        let custom = ShortcutConfig(keyCode: 2, modifiers: [.control, .option]) // D key
        XCTAssertEqual(custom.displayString, "⌃ Control + ⌥ Option + D")
        
        let data = try JSONEncoder().encode(custom)
        let decoded = try JSONDecoder().decode(ShortcutConfig.self, from: data)
        XCTAssertEqual(decoded, custom)
        XCTAssertEqual(decoded.keyCode, 2)
        XCTAssertTrue(decoded.modifiers.contains(.control))
        XCTAssertTrue(decoded.modifiers.contains(.option))
    }
    
    func testKeyNames() {
        XCTAssertEqual(ShortcutHelper.keyName(for: 49), "Space")
        XCTAssertEqual(ShortcutHelper.keyName(for: 36), "Return")
        XCTAssertEqual(ShortcutHelper.keyName(for: 0), "A")
        XCTAssertEqual(ShortcutHelper.keyName(for: 122), "F1")
        XCTAssertEqual(ShortcutHelper.keyName(for: 10), "§")
        XCTAssertEqual(ShortcutHelper.keyName(for: 123), "Left Arrow")
        XCTAssertEqual(ShortcutHelper.keyName(for: 126), "Up Arrow")
        XCTAssertEqual(ShortcutHelper.keyName(for: 76), "Keypad Enter")
    }
}
