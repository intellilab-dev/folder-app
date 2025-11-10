//
//  FileSystemService.swift
//  Folder
//
//  Service for interacting with the file system
//

import Foundation
import AppKit

@MainActor
class FileSystemService: ObservableObject {
    static let shared = FileSystemService()

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Directory Reading

    /// Read contents of a directory and return FileSystemItems
    func contentsOfDirectory(at url: URL, showHidden: Bool = false) throws -> [FileSystemItem] {
        var items: [FileSystemItem] = []

        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .creationDateKey,
                .isHiddenKey
            ],
            options: []
        )

        for itemURL in contents {
            // Skip hidden files if not showing them
            if !showHidden {
                let resourceValues = try? itemURL.resourceValues(forKeys: [.isHiddenKey])
                if resourceValues?.isHidden == true || itemURL.lastPathComponent.hasPrefix(".") {
                    continue
                }
            }

            // Create FileSystemItem
            if let item = try? FileSystemItem(from: itemURL) {
                items.append(item)
            }
        }

        return items.sorted()
    }

    // MARK: - Navigation Helpers

    /// Check if a path exists and is accessible
    func pathExists(_ url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    /// Get parent directory of a URL
    func parentDirectory(of url: URL) -> URL? {
        let parent = url.deletingLastPathComponent()
        return parent.path != url.path ? parent : nil
    }

    /// Get home directory
    func homeDirectory() -> URL {
        return fileManager.homeDirectoryForCurrentUser
    }

    // MARK: - File Operations

    /// Move item to trash
    func moveToTrash(_ url: URL) throws {
        var trashedURL: NSURL?
        try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)
    }

    /// Copy item to destination
    func copyItem(at source: URL, to destination: URL) throws {
        try fileManager.copyItem(at: source, to: destination)
    }

    /// Move item to destination
    func moveItem(at source: URL, to destination: URL) throws {
        try fileManager.moveItem(at: source, to: destination)
    }

    /// Rename item
    func renameItem(at url: URL, to newName: String) throws {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try fileManager.moveItem(at: url, to: newURL)
    }

    /// Create new folder
    func createFolder(at url: URL, named name: String) throws {
        let folderURL = url.appendingPathComponent(name)
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
    }

    // MARK: - Path Validation

    /// Validate and resolve a path string to URL
    func resolveURL(from pathString: String) -> URL? {
        // Expand tilde
        let expandedPath = NSString(string: pathString).expandingTildeInPath

        // Create URL
        let url = URL(fileURLWithPath: expandedPath)

        // Check if exists
        guard pathExists(url) else {
            return nil
        }

        return url
    }

    // MARK: - Folder Size Calculation

    /// Calculate total size of a folder recursively
    func calculateFolderSize(at url: URL) async throws -> Int64 {
        var totalSize: Int64 = 0

        // Get directory enumerator
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            // Check for cancellation
            if Task.isCancelled {
                throw CancellationError()
            }

            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])

            // Only add file sizes (not directories themselves)
            if resourceValues.isDirectory == false {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }

        return totalSize
    }
}

