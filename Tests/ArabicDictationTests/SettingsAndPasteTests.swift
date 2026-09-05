import XCTest
import AppKit
@testable import ArabicDictation

final class SettingsAndPasteTests: XCTestCase {
    
    func testAppSettingsDefaults() {
        let settings = AppSettings.shared
        XCTAssertEqual(settings.model, .gptTranscribe)
        XCTAssertEqual(settings.language, "ar")
        XCTAssertTrue(settings.promptContext.contains("Syrian and Levantine dialect"))
        XCTAssertTrue(settings.pasteAutomatically)
        XCTAssertTrue(settings.playSoundEffects)
    }
    
    func testPasteManagerClipboardPreservation() {
        let pasteboard = NSPasteboard.general
        let originalContent = "Original_Clipboard_Content_\(UUID().uuidString)"
        pasteboard.clearContents()
        pasteboard.setString(originalContent, forType: .string)
        
        let arabicText = "مرحبا، هذا اختبار للنسخ"
        let success = PasteManager.shared.pasteText(arabicText, restoreClipboard: true, checkAccessibility: false)
        XCTAssertTrue(success)
        
        // Immediate pasteboard should be the arabicText
        XCTAssertEqual(pasteboard.string(forType: .string), arabicText)
        
        // After delay, should be restored to originalContent
        let expectation = expectation(description: "Restore clipboard")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let restored = pasteboard.string(forType: .string)
            XCTAssertEqual(restored, originalContent)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
