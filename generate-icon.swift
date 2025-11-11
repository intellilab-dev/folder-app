#!/usr/bin/swift

import AppKit
import Foundation

// Generate app icon from SF Symbol
func generateAppIcon() {
    let iconSizes: [(size: Int, scale: Int)] = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2)
    ]

    // Create iconset directory
    let iconsetPath = "Resources/AppIcon.iconset"
    try? FileManager.default.removeItem(atPath: iconsetPath)
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    // Generate each icon size
    for (size, scale) in iconSizes {
        let actualSize = size * scale
        let image = createFolderIcon(size: CGFloat(actualSize))

        let filename: String
        if scale == 1 {
            filename = "icon_\(size)x\(size).png"
        } else {
            filename = "icon_\(size)x\(size)@\(scale)x.png"
        }

        let filePath = "\(iconsetPath)/\(filename)"

        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: filePath))
            print("Generated: \(filename)")
        }
    }

    print("\n✅ Icon set generated at: \(iconsetPath)")
    print("Converting to .icns...")

    // Convert to .icns using iconutil
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    task.arguments = ["-c", "icns", iconsetPath, "-o", "Resources/AppIcon.icns"]

    do {
        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            print("✅ AppIcon.icns created successfully!")

            // Clean up iconset
            try? FileManager.default.removeItem(atPath: iconsetPath)
            print("🧹 Cleaned up temporary files")
        } else {
            print("❌ Failed to convert to .icns")
        }
    } catch {
        print("❌ Error: \(error)")
    }
}

func createFolderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Dark blue-gray background (matching the design)
    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let backgroundColor = NSColor(red: 0.25, green: 0.29, blue: 0.33, alpha: 1.0)
    backgroundColor.setFill()
    NSBezierPath(rect: bounds).fill()

    // Draw layered/stacked icon in white
    let centerX = size / 2
    let centerY = size / 2
    let layerWidth = size * 0.5
    let layerHeight = size * 0.12
    let layerSpacing = size * 0.08

    NSColor.white.setFill()

    // Draw 3 stacked layers (bottom to top)
    for i in 0..<3 {
        let yOffset = centerY - (layerHeight / 2) + CGFloat(i - 1) * layerSpacing

        // Create rounded rectangle for each layer
        let layerRect = NSRect(
            x: centerX - layerWidth / 2,
            y: yOffset,
            width: layerWidth,
            height: layerHeight
        )

        let cornerRadius = layerHeight * 0.3
        let layerPath = NSBezierPath(roundedRect: layerRect, xRadius: cornerRadius, yRadius: cornerRadius)
        layerPath.fill()
    }

    image.unlockFocus()

    return image
}

// Run the generator
generateAppIcon()
