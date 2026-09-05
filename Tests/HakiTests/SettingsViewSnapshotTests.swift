import XCTest
import SwiftUI
import AppKit
@testable import Haki

final class SettingsViewSnapshotTests: XCTestCase {
    
    @MainActor
    func testRenderSettingsScreenshots() throws {
        let sections: [SettingsSection] = [.general, .transcription, .audio, .shortcut, .advanced]
        let appearances: [(String, NSAppearance.Name)] = [
            ("dark", .darkAqua),
            ("light", .aqua)
        ]
        
        let outputDir = URL(fileURLWithPath: "/Users/alhamou/.gemini/antigravity-ide/brain/94a02f43-788a-4640-8e00-8175f1f75c50")
        
        for (appearanceName, appearance) in appearances {
            for section in sections {
                let view = SettingsView(initialSection: section)
                let hostingView = NSHostingView(rootView: view)
                hostingView.frame = NSRect(x: 0, y: 0, width: 660, height: 560)
                hostingView.appearance = NSAppearance(named: appearance)
                
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 660, height: 560),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.appearance = NSAppearance(named: appearance)
                window.contentView = hostingView
                hostingView.layoutSubtreeIfNeeded()
                
                guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
                    continue
                }
                hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
                
                if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    let fileURL = outputDir.appendingPathComponent("settings_\(section.rawValue.lowercased())_\(appearanceName).png")
                    try pngData.write(to: fileURL)
                    
                    if section == .transcription && appearanceName == "dark" {
                        let resourcesURL = URL(fileURLWithPath: "/Users/alhamou/Developer/Haki/Resources/screenshot.png")
                        try pngData.write(to: resourcesURL)
                    }
                }
            }
        }
    }
}
