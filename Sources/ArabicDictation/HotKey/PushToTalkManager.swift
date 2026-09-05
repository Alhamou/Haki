import Foundation
import AppKit
import CoreGraphics

public final class PushToTalkManager {
    public static let shared = PushToTalkManager()
    
    public var onStartRecording: (() -> Void)?
    public var onStopRecording: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isListening = false
    private var isKeyDownActive = false
    
    // Virtual key code 49 is Space Bar
    private let targetKeyCode: Int64 = 49
    
    public init() {}
    
    deinit {
        stop()
    }
    
    public func start() {
        guard !isListening else { return }
        
        guard AccessibilityHelper.shared.isAccessibilityGranted() else {
            AppLogger.shared.warning("Accessibility permission not granted; global shortcut cannot be registered yet.")
            return
        }
        
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                     (1 << CGEventType.keyUp.rawValue) |
                                     (1 << CGEventType.flagsChanged.rawValue)
        
        let observer = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                let manager = Unmanaged<PushToTalkManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observer
        ) else {
            AppLogger.shared.error("Failed to create CGEventTap for Push-to-Talk.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        isListening = true
        AppLogger.shared.info("Global Push-to-Talk (Option + Space) event tap registered successfully.")
    }
    
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                self.runLoopSource = nil
            }
            self.eventTap = nil
        }
        isListening = false
        isKeyDownActive = false
    }
    
    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // macOS can disable event taps if an app takes too long; re-enable immediately
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                AppLogger.shared.warning("Event tap re-enabled after system timeout.")
            }
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let isOptionPressed = flags.contains(.maskAlternate)
        let hasNoOtherModifiers = !flags.contains(.maskCommand) && !flags.contains(.maskControl)
        
        switch type {
        case .keyDown:
            if keyCode == targetKeyCode && isOptionPressed && hasNoOtherModifiers {
                let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                if !isRepeat && !isKeyDownActive {
                    isKeyDownActive = true
                    AppLogger.shared.info("Push-to-Talk triggered: Option+Space keyDown")
                    DispatchQueue.main.async { [weak self] in
                        self?.onStartRecording?()
                    }
                }
                // Suppress the space key so it isn't typed into the active app
                return nil
            }
            
        case .keyUp:
            if keyCode == targetKeyCode && isKeyDownActive {
                isKeyDownActive = false
                AppLogger.shared.info("Push-to-Talk released: Option+Space keyUp")
                DispatchQueue.main.async { [weak self] in
                    self?.onStopRecording?()
                }
                return nil
            }
            
        case .flagsChanged:
            // If user releases the Option key while recording, stop recording
            if isKeyDownActive && !isOptionPressed {
                isKeyDownActive = false
                AppLogger.shared.info("Push-to-Talk released: Option key released")
                DispatchQueue.main.async { [weak self] in
                    self?.onStopRecording?()
                }
            }
            
        default:
            break
        }
        
        return Unmanaged.passRetained(event)
    }
}
