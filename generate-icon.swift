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

    // Create gradient background circle
    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let circlePath = NSBezierPath(ovalIn: bounds.insetBy(dx: size * 0.05, dy: size * 0.05))

    // Purple gradient (similar to the icon in the screenshot)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0),  // Light purple
        NSColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0)   // Darker purple
    ])

    gradient?.draw(in: circlePath, angle: -45)

    // Draw folder symbol in white
    if let folderSymbol = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil) {
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .regular)
        let configuredSymbol = folderSymbol.withSymbolConfiguration(symbolConfig)

        // Center the symbol
        let symbolSize = configuredSymbol?.size ?? NSSize(width: size * 0.5, height: size * 0.5)
        let symbolRect = NSRect(
            x: (size - symbolSize.width) / 2,
            y: (size - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )

        // Draw white folder symbol
        NSColor.white.set()
        configuredSymbol?.draw(in: symbolRect)
    }

    image.unlockFocus()

    return image
}

// Run the generator
generateAppIcon()
