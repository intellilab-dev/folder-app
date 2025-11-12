//
//  WindowManager.swift
//  Folder
//
//  Manages multiple app windows
//

import AppKit

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var windows: [NSWindow] = []

    private init() {
        // Subscribe to window close notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    func addWindow(_ window: NSWindow) {
        // Prevent window from being released when closed
        window.releasedWhenClosed = false
        windows.append(window)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Remove window from array when it closes
        windows.removeAll { $0 == window }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
