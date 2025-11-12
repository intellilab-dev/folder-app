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

    // Store window controllers instead of windows for proper lifecycle management
    private var windowControllers: [NSWindowController] = []

    private init() {
        // Subscribe to window close notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    func addWindowController(_ controller: NSWindowController) {
        // Window controllers properly manage their windows' lifecycle
        // No need to set releasedWhenClosed manually
        windowControllers.append(controller)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Remove window controller when its window closes
        windowControllers.removeAll { $0.window == window }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
