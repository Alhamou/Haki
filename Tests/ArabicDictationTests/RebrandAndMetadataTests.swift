import XCTest
@testable import ArabicDictation

final class RebrandAndMetadataTests: XCTestCase {
    
    func testInfoPlistRebrandMetadata() throws {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let plistURL = URL(fileURLWithPath: "\(currentDir)/Resources/Info.plist")
        
        guard fileManager.fileExists(atPath: plistURL.path) else {
            XCTFail("Info.plist not found at \(plistURL.path)")
            return
        }
        
        let data = try Data(contentsOf: plistURL)
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            XCTFail("Failed to deserialize Info.plist")
            return
        }
        
        XCTAssertEqual(plist["CFBundleExecutable"] as? String, "Haki", "CFBundleExecutable must be Haki")
        XCTAssertEqual(plist["CFBundleName"] as? String, "Haki", "CFBundleName must be Haki")
        XCTAssertEqual(plist["CFBundleDisplayName"] as? String, "Haki", "CFBundleDisplayName must be Haki")
        XCTAssertEqual(plist["CFBundleIconFile"] as? String, "AppIcon", "CFBundleIconFile must be AppIcon")
        
        let micUsage = plist["NSMicrophoneUsageDescription"] as? String ?? ""
        XCTAssertTrue(micUsage.contains("Haki"), "NSMicrophoneUsageDescription should mention Haki")
    }
    
    func testBuildScriptTargetsHaki() throws {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let scriptURL = URL(fileURLWithPath: "\(currentDir)/scripts/build_app.sh")
        
        guard fileManager.fileExists(atPath: scriptURL.path) else {
            XCTFail("build_app.sh not found at \(scriptURL.path)")
            return
        }
        
        let content = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(content.contains("APP_NAME=\"Haki\""), "build_app.sh must define APP_NAME=\"Haki\"")
        XCTAssertTrue(content.contains("APP_BUNDLE=\"$BUILD_DIR/$APP_NAME.app\""), "build_app.sh must package to $BUILD_DIR/$APP_NAME.app")
        XCTAssertTrue(content.contains("DEST_APPLICATIONS=\"/Applications/$APP_NAME.app\""), "build_app.sh must install to /Applications/$APP_NAME.app")
    }
    
    func testSettingsContinuity() {
        let settings = AppSettings.shared
        // Verify default settings still hold
        XCTAssertEqual(settings.model, .gptTranscribe)
        XCTAssertEqual(settings.language, "ar")
        XCTAssertTrue(settings.pasteAutomatically)
        XCTAssertTrue(settings.promptContext.contains("Syrian") || settings.promptContext.contains("Levantine"))
    }
}
