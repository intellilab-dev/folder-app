//
//  IconService.swift
//  Folder
//
//  Service for loading and caching file icons
//

import Foundation
import AppKit
import SwiftUI

@MainActor
class IconService: ObservableObject {
    static let shared = IconService()

    // Cache for NSImages (path → NSImage)
    private let imageCache = NSCache<NSString, NSImage>()

    // Cache for SwiftUI Images (path → Image ID)
    @Published private var swiftUICache: [String: String] = [:]

    private init() {
        // Configure cache limits
        imageCache.countLimit = 500  // Max 500 icons in memory
        imageCache.totalCostLimit = 50 * 1024 * 1024  // 50MB max
    }

    /// Get icon for a file or folder
    func icon(for item: FileSystemItem, size: CGFloat = 64) -> NSImage {
        let cacheKey = "\(item.path.path)-\(Int(size))" as NSString

        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // Load icon from NSWorkspace
        let icon = NSWorkspace.shared.icon(forFile: item.path.path)

        // Resize icon to requested size
        let resizedIcon = resizeImage(icon, to: NSSize(width: size, height: size))

        // Cache it
        imageCache.setObject(resizedIcon, forKey: cacheKey)

        return resizedIcon
    }

    /// Get icon as SwiftUI Image
    func swiftUIIcon(for item: FileSystemItem, size: CGFloat = 64) -> Image {
        let nsImage = icon(for: item, size: size)
        return Image(nsImage: nsImage)
    }

    /// Preload icons for an array of items (for performance)
    func preloadIcons(for items: [FileSystemItem], size: CGFloat = 64) {
        Task.detached(priority: .background) {
            for item in items {
                let cacheKey = "\(item.path.path)-\(Int(size))" as NSString

                // Skip if already cached
                if await self.imageCache.object(forKey: cacheKey) != nil {
                    continue
                }

                // Load and cache icon
                await MainActor.run {
                    _ = self.icon(for: item, size: size)
                }
            }
        }
    }

    /// Clear all cached icons
    func clearCache() {
        imageCache.removeAllObjects()
        swiftUICache.removeAll()
    }

    // MARK: - Private Helpers

    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)

        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()

        return newImage
    }
}
