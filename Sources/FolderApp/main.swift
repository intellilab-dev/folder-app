//
//  main.swift
//  Folder
//
//  App entry point for command-line executable
//

import AppKit
import SwiftUI

// Create app delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: NSWindowController?
    var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()

        // Register for URL events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Create the main window using window controller
        let contentView = ContentView()
            .environmentObject(SettingsManager.shared)

        mainWindowController = SwiftUIWindowController(
            rootView: contentView,
            title: "Folder",
            size: NSSize(width: 1000, height: 700)
        )

        mainWindowController?.window?.setFrameAutosaveName("MainWindow")
        mainWindowController?.showWindow(nil)

        // Add to WindowManager for proper lifecycle management
        WindowManager.shared.addWindowController(mainWindowController!)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Allow multiple windows to be open
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        // Handle URL: folder://open?path=/path/to/folder
        if url.scheme == "folder" {
            Task { @MainActor in
                handleFolderURL(url)
            }
        }
    }

    @MainActor private func handleFolderURL(_ url: URL) {
        // Parse URL: folder://open?path=/path/to/folder
        if url.host == "open", let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let pathItem = components.queryItems?.first(where: { $0.name == "path" }),
               let folderPath = pathItem.value {
                let folderURL = URL(fileURLWithPath: folderPath)

                print("Opening folder from URL: \(folderPath)")

                // Always open in NEW window when launched via URL scheme (Shortcuts.app)
                let contentView = ContentView(initialPath: folderURL)
                    .environmentObject(SettingsManager.shared)

                let windowController = SwiftUIWindowController(
                    rootView: contentView,
                    title: "Folder - \(folderURL.lastPathComponent)",
                    size: NSSize(width: 1000, height: 700)
                )

                windowController.window?.setFrameAutosaveName("URLWindow-\(UUID().uuidString)")
                windowController.showWindow(nil)

                WindowManager.shared.addWindowController(windowController)

                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @MainActor @objc func showSettings() {
        if settingsWindowController == nil {
            let settingsView = SettingsView()
                .environmentObject(SettingsManager.shared)

            settingsWindowController = SwiftUIWindowController(
                rootView: settingsView,
                title: "Settings",
                size: NSSize(width: 550, height: 700),
                styleMask: [.titled, .closable]
            )

            settingsWindowController?.window?.level = .floating
        }

        settingsWindowController?.showWindow(nil)
    }

    private func setupMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Folder", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenu = NSMenu(title: "File")
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu

        fileMenu.addItem(withTitle: "New Folder", action: nil, keyEquivalent: "n")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        mainMenu.addItem(fileMenuItem)

        // Edit menu
        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
