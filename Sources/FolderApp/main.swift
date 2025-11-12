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
    var window: NSWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()

        // Register for URL events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Create the main window
        let contentView = ContentView()
            .environmentObject(SettingsManager.shared)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window?.titlebarAppearsTransparent = true
        window?.appearance = NSAppearance(named: .darkAqua)
        window?.center()
        window?.title = "Folder"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = NSColor.folderSidebar
        window?.makeKeyAndOrderFront(nil)
        window?.setFrameAutosaveName("MainWindow")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        // Handle URL: folder://open?path=/path/to/folder
        if url.scheme == "folder" {
            handleFolderURL(url)
        }
    }

    private func handleFolderURL(_ url: URL) {
        // Make sure window is visible
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)

        // Parse URL and open folder
        if url.host == "open", let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let pathItem = components.queryItems?.first(where: { $0.name == "path" }),
               let folderPath = pathItem.value {
                // Open the specified folder
                print("Opening folder from URL: \(folderPath)")
                // TODO: Navigate to the folder path in FileExplorerViewModel
            }
        }
    }

    @MainActor @objc func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(SettingsManager.shared)

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 700),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )

            settingsWindow?.center()
            settingsWindow?.title = "Settings"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.level = .floating
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
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
