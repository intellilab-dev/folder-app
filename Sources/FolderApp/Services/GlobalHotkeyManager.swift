//
//  GlobalHotkeyManager.swift
//  Folder
//
//  Manages global keyboard shortcuts using Carbon APIs
//

import AppKit
import Carbon

@MainActor
class GlobalHotkeyManager: ObservableObject {
    static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    @Published var isHotkeyEnabled = false

    private init() {}

    func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        // Unregister existing hotkey first
        unregisterHotkey()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            // Get the hotkey ID
            var hotkeyID = EventHotKeyID()
            GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)

            // Activate the app
            Task { @MainActor in
                NSApp.activate(ignoringOtherApps: true)

                // Show the main window if hidden
                if let window = NSApp.windows.first(where: { $0.title == "Folder" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }

            return noErr
        }, 1, &eventType, nil, &eventHandler)

        // Register the hotkey
        let hotkeyID = EventHotKeyID(signature: OSType(0x464F4C44), id: 1) // 'FOLD'
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if status == noErr {
            isHotkeyEnabled = true
        }
    }

    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        isHotkeyEnabled = false
    }
}

// Helper extension for key code mapping
extension GlobalHotkeyManager {
    static func keyCodeFromString(_ key: String) -> UInt32? {
        let mapping: [String: UInt32] = [
            "space": 49,
            "return": 36,
            "tab": 48,
            "delete": 51,
            "escape": 53,
            "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96,
            "f6": 97, "f7": 98, "f8": 100, "f9": 101, "f10": 109,
            "f11": 103, "f12": 111,
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3,
            "g": 5, "h": 4, "i": 34, "j": 38, "k": 40, "l": 37,
            "m": 46, "n": 45, "o": 31, "p": 35, "q": 12, "r": 15,
            "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7,
            "y": 16, "z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
            "6": 22, "7": 26, "8": 28, "9": 25
        ]
        return mapping[key.lowercased()]
    }

    static func carbonModifiersFromAppKit(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0

        if modifiers.contains(.command) {
            carbonMods |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbonMods |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonMods |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            carbonMods |= UInt32(shiftKey)
        }

        return carbonMods
    }
}
