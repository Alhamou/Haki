import Foundation
import AppKit
import CoreGraphics
import Combine

public final class PushToTalkManager {
    public static let shared = PushToTalkManager()
    
    public var onStartRecording: (() -> Void)?
    public var onStopRecording: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isListening = false
    private var isKeyDownActive = false
    private var cancellables = Set<AnyCancellable>()
    
    private var targetKeyCode: Int64 = 49
    private var targetModifiers: NSEvent.ModifierFlags = .option
    
    public init() {
        updateShortcut()
        
        AccessibilityHelper.shared.$isGranted
            .removeDuplicates()
            .sink { [weak self] granted in
                guard let self = self else { return }
                if granted && !self.isListening {
                    self.start()
                }
            }
            .store(in: &cancellables)
    }
    
    public func updateShortcut() {
        let current = AppSettings.shared.shortcut
        self.targetKeyCode = Int64(current.keyCode)
        self.targetModifiers = current.modifiers
        AppLogger.shared.info("Push-to-Talk shortcut updated to: \(current.displayString)")
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        guard !isListening else { return }
        updateShortcut()
        
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
        AppLogger.shared.info("Global Push-to-Talk (\(AppSettings.shared.shortcut.displayString)) event tap registered successfully.")
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
        let modifierMatches = checkModifiersMatch(flags: flags, target: targetModifiers)
        
        switch type {
        case .keyDown:
            if keyCode == targetKeyCode && modifierMatches {
                let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                if !isRepeat && !isKeyDownActive {
                    isKeyDownActive = true
                    AppLogger.shared.info("Push-to-Talk triggered: \(keyCode) keyDown")
                    DispatchQueue.main.async { [weak self] in
                        self?.onStartRecording?()
                    }
                }
                // Suppress key so it isn't typed into the active app
                return nil
            }
            
        case .keyUp:
            if keyCode == targetKeyCode && isKeyDownActive {
                isKeyDownActive = false
                AppLogger.shared.info("Push-to-Talk released: \(keyCode) keyUp")
                DispatchQueue.main.async { [weak self] in
                    self?.onStopRecording?()
                }
                return nil
            }
            
        case .flagsChanged:
            // If user releases required modifiers while key is down, stop recording
            if isKeyDownActive && !modifierMatches {
                isKeyDownActive = false
                AppLogger.shared.info("Push-to-Talk released: modifier key released")
                DispatchQueue.main.async { [weak self] in
                    self?.onStopRecording?()
                }
            }
            
        default:
            break
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func checkModifiersMatch(flags: CGEventFlags, target: NSEvent.ModifierFlags) -> Bool {
        let isOption = flags.contains(.maskAlternate)
        let isControl = flags.contains(.maskControl)
        let isCommand = flags.contains(.maskCommand)
        let isShift = flags.contains(.maskShift)
        
        let wantOption = target.contains(.option)
        let wantControl = target.contains(.control)
        let wantCommand = target.contains(.command)
        let wantShift = target.contains(.shift)
        
        return (isOption == wantOption) &&
               (isControl == wantControl) &&
               (isCommand == wantCommand) &&
               (isShift == wantShift)
    }
}
