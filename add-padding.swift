#!/usr/bin/swift

import AppKit
import Foundation

// Add padding to icon
func addPadding() {
    guard let originalImage = NSImage(contentsOfFile: "Folder.png") else {
        print("❌ Failed to load Folder.png")
        exit(1)
    }

    let originalSize = originalImage.size
    print("📐 Original size: \(Int(originalSize.width))x\(Int(originalSize.height))")

    // Create padded version at 1024x1024
    let targetSize: CGFloat = 1024
    let padding: CGFloat = 0.088 // 8.8% padding on each side (90% content)
    let contentSize = targetSize * (1 - padding * 2)

    let paddedImage = NSImage(size: NSSize(width: targetSize, height: targetSize))
    paddedImage.lockFocus()

    // Draw transparent background
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: targetSize, height: targetSize).fill()

    // Draw scaled content in center
    let drawRect = NSRect(
        x: (targetSize - contentSize) / 2,
        y: (targetSize - contentSize) / 2,
        width: contentSize,
        height: contentSize
    )

    originalImage.draw(
        in: drawRect,
        from: NSRect(origin: .zero, size: originalImage.size),
        operation: .sourceOver,
        fraction: 1.0
    )

    paddedImage.unlockFocus()

    // Save as PNG
    if let tiffData = paddedImage.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {

        // Backup original
        try? FileManager.default.copyItem(atPath: "Folder.png", toPath: "Folder-original.png")

        // Save new version
        try? pngData.write(to: URL(fileURLWithPath: "Folder.png"))

        print("✅ Icon padding added - 1024x1024 with 8.8% padding")
        print("   Content scaled to: \(Int(contentSize))x\(Int(contentSize))")
    } else {
        print("❌ Failed to save padded icon")
        exit(1)
    }
}

addPadding()
