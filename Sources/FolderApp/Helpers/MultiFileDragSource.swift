//
//  MultiFileDragSource.swift
//  Folder
//
//  NSViewRepresentable wrapper that enables multi-file drag via AppKit's native drag API
//

import SwiftUI
import AppKit

/// A transparent NSView that intercepts mouse drags and initiates a multi-file drag session
class DraggableView: NSView, NSDraggingSource {
    var fileURLs: [URL] = []
    var dragEnabled = false
    private var dragStartPoint: NSPoint?
    private var isDragging = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Make the view layer-backed for better performance
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func mouseDown(with event: NSEvent) {
        if dragEnabled && !fileURLs.isEmpty {
            dragStartPoint = convert(event.locationInWindow, from: nil)
            isDragging = false
        } else {
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragEnabled, !fileURLs.isEmpty, !isDragging else {
            super.mouseDragged(with: event)
            return
        }

        guard let startPoint = dragStartPoint else { return }
        let currentPoint = convert(event.locationInWindow, from: nil)
        let distance = hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y)

        // Only start drag after moving a minimum distance
        guard distance > 5 else { return }

        isDragging = true

        // Create dragging items for all files
        var draggingItems: [NSDraggingItem] = []
        for (index, url) in fileURLs.enumerated() {
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 32, height: 32)
            // Offset each icon slightly so they stack visually
            let offsetX = CGFloat(index) * 4
            let offsetY = CGFloat(index) * 4
            item.setDraggingFrame(NSRect(x: startPoint.x + offsetX, y: startPoint.y - 32 + offsetY, width: 32, height: 32), contents: icon)
            draggingItems.append(item)
        }

        // Start the drag session
        beginDraggingSession(with: draggingItems, event: event, source: self)
        dragStartPoint = nil
    }

    override func mouseUp(with event: NSEvent) {
        dragStartPoint = nil
        isDragging = false
        super.mouseUp(with: event)
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return context == .outsideApplication ? .copy : .move
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        isDragging = false
        dragStartPoint = nil
    }
}

/// NSViewRepresentable that wraps the DraggableView
struct MultiFileDragView: NSViewRepresentable {
    let fileURLs: [URL]
    let isEnabled: Bool

    func makeNSView(context: Context) -> DraggableView {
        let view = DraggableView(frame: .zero)
        view.fileURLs = fileURLs
        view.dragEnabled = isEnabled
        return view
    }

    func updateNSView(_ nsView: DraggableView, context: Context) {
        nsView.fileURLs = fileURLs
        nsView.dragEnabled = isEnabled
    }
}

// Extension for easy use - returns the drag view directly
extension View {
    @ViewBuilder
    func multiFileDrag(urls: [URL], enabled: Bool = true) -> some View {
        ZStack {
            self
            MultiFileDragView(fileURLs: urls, isEnabled: enabled)
        }
    }
}
