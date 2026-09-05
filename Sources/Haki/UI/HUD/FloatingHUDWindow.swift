import Foundation
import AppKit
import SwiftUI

public final class FloatingHUDWindowController {
    public static let shared = FloatingHUDWindowController()
    
    private var window: NSPanel?
    private var dismissTimer: Timer?
    
    private init() {
        createWindow()
    }
    
    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 48),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        
        self.window = panel
    }
    
    public func show(state: HUDState, audioLevel: Float = 0.0) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismissTimer?.invalidate()
            self.dismissTimer = nil
            
            if state == .idle {
                self.hide()
                return
            }
            
            guard let window = self.window else { return }
            
            let contentView = FloatingHUDView(state: state, audioLevel: audioLevel)
            let hostingView = NSHostingView(rootView: contentView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 260, height: 50)
            window.contentView = hostingView
            
            // Position at bottom center of the active display
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowWidth: CGFloat = 260
                let windowHeight: CGFloat = 50
                let x = screenRect.origin.x + (screenRect.width - windowWidth) / 2.0
                let y = screenRect.origin.y + 70 // 70px above bottom
                window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
            }
            
            window.alphaValue = 1.0
            window.orderFront(nil)
            
            // Auto dismiss for finished states
            if case .done = state {
                self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
                    self?.hideAnimated()
                }
            } else if case .error = state {
                self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
                    self?.hideAnimated()
                }
            }
        }
    }
    
    public func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.dismissTimer?.invalidate()
            self?.dismissTimer = nil
            self?.window?.orderOut(nil)
        }
    }
    
    public func hideAnimated() {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.orderOut(nil)
                window.alphaValue = 1.0
            })
        }
    }
}
