import Foundation
import IOKit.hid
import AppKit

/// Manages reading touch data from a Magic Mouse and sends a middle click
/// when the touch occurs near the center of the surface.
class MagicMouseTouchManager {
    private var manager: IOHIDManager
    private var touching = false
    private var middleActive = false

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        // Match Apple mice
        let match: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x05AC,
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterInputValueCallback(manager, inputCallback, context)
    }

    /// Starts listening for HID events.
    func start() {
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    /// Stops listening for HID events.
    func stop() {
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func handle(value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let page = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        // Track whether a finger is touching the surface
        if page == kHIDPage_Digitizer && usage == kHIDUsage_Dig_Touch {
            touching = IOHIDValueGetIntegerValue(value) != 0
            if !touching { middleActive = false }
        }

        // Read X coordinate of the touch and fire middle click
        if touching && page == kHIDPage_Digitizer && usage == kHIDUsage_Dig_X {
            let x = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypePhysical)
            print("Touch X: \(x)")

            // Simple middle click area check (normalized ~0-4096)
            if x > 1500 && x < 2500 {
                if !middleActive {
                    triggerMiddleClick()
                    middleActive = true
                }
            } else {
                middleActive = false
            }
        }
    }

    private func triggerMiddleClick() {
        let loc = NSEvent.mouseLocation
        if let down = CGEvent(mouseEventSource: nil, mouseType: .otherMouseDown, mouseCursorPosition: loc, mouseButton: .center),
           let up = CGEvent(mouseEventSource: nil, mouseType: .otherMouseUp, mouseCursorPosition: loc, mouseButton: .center) {
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
}

private func inputCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, value: IOHIDValue) {
    let manager = Unmanaged<MagicMouseTouchManager>.fromOpaque(context!).takeUnretainedValue()
    manager.handle(value: value)
}
