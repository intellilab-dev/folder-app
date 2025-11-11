import Foundation
import AppKit
import Quartz

/// Manager for Quick Look preview functionality
@MainActor
class QuickLookManager: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookManager()

    private var previewItems: [URL] = []
    private var currentIndex: Int = 0

    private override init() {
        super.init()
    }

    /// Toggle Quick Look preview panel
    func togglePreview(for items: [FileSystemItem], selectedIndex: Int = 0) {
        guard !items.isEmpty else { return }

        // Convert FileSystemItem to URLs
        self.previewItems = items.map { $0.path }
        self.currentIndex = min(selectedIndex, items.count - 1)

        if let panel = QLPreviewPanel.shared() {
            if panel.isVisible {
                panel.orderOut(nil)
            } else {
                panel.dataSource = self
                panel.delegate = self
                panel.currentPreviewItemIndex = currentIndex
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }

    /// Show Quick Look preview for a specific item
    func showPreview(for item: FileSystemItem) {
        togglePreview(for: [item], selectedIndex: 0)
    }

    /// Show Quick Look preview for multiple items
    func showPreview(for items: [FileSystemItem], startingAt index: Int) {
        togglePreview(for: items, selectedIndex: index)
    }

    /// Close Quick Look preview panel
    func closePreview() {
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.orderOut(nil)
        }
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return previewItems.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard index >= 0 && index < previewItems.count else {
            return nil
        }
        return previewItems[index] as QLPreviewItem
    }

    // MARK: - QLPreviewPanelDelegate

    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        // Handle keyboard events in preview panel
        if event.type == .keyDown {
            switch event.keyCode {
            case 53: // Escape key
                panel.orderOut(nil)
                return true
            case 123, 124: // Left/Right arrow keys
                // Let Quick Look handle navigation between items
                return false
            case 125, 126: // Up/Down arrow keys
                // Let Quick Look handle these too
                return false
            default:
                break
            }
        }
        return false
    }

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        return true
    }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = self
        panel.delegate = self
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = nil
        panel.delegate = nil
    }

    func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: QLPreviewItem!) -> NSRect {
        // Return the frame where the preview should zoom from
        // For now, return center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            return NSRect(
                x: screenFrame.midX - 50,
                y: screenFrame.midY - 50,
                width: 100,
                height: 100
            )
        }
        return .zero
    }

    func previewPanel(_ panel: QLPreviewPanel!, transitionImageFor item: QLPreviewItem!, contentRect: UnsafeMutablePointer<NSRect>!) -> Any! {
        // Provide a transition image if available
        if let url = item as? URL {
            return NSImage(contentsOf: url)
        }
        return nil
    }
}
