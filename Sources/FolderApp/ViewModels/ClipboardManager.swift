//
//  ClipboardManager.swift
//  Folder
//
//  Manager for clipboard operations (copy/cut/paste)
//

import Foundation
import AppKit

@MainActor
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var clipboardItems: [FileSystemItem] = []
    @Published var clipboardAction: ClipboardAction = .copy

    enum ClipboardAction {
        case copy
        case cut
    }

    private let fileSystemService = FileSystemService.shared
    private let pasteboard = NSPasteboard.general

    private init() {}

    // MARK: - Copy

    func copy(items: [FileSystemItem]) {
        clipboardItems = items
        clipboardAction = .copy

        // Write URLs to system pasteboard
        let urls = items.map { $0.path as NSURL }
        pasteboard.clearContents()
        pasteboard.writeObjects(urls)
    }

    // MARK: - Cut

    func cut(items: [FileSystemItem]) {
        clipboardItems = items
        clipboardAction = .cut

        // Write URLs to system pasteboard
        let urls = items.map { $0.path as NSURL }
        pasteboard.clearContents()
        pasteboard.writeObjects(urls)
    }

    // MARK: - Paste

    func paste(to destination: URL) async throws -> PasteResult {
        // Read URLs from pasteboard
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            throw ClipboardError.nothingToPaste
        }

        var succeeded: [URL] = []
        var failed: [(URL, Error)] = []
        var conflicts: [URL] = []

        for sourceURL in urls {
            let fileName = sourceURL.lastPathComponent
            let destinationURL = destination.appendingPathComponent(fileName)

            // Check if destination already exists
            if fileSystemService.pathExists(destinationURL) {
                conflicts.append(sourceURL)
                continue
            }

            do {
                if clipboardAction == .cut {
                    // Move file
                    try fileSystemService.moveItem(at: sourceURL, to: destinationURL)
                } else {
                    // Copy file
                    try fileSystemService.copyItem(at: sourceURL, to: destinationURL)
                }
                succeeded.append(destinationURL)
            } catch {
                failed.append((sourceURL, error))
            }
        }

        // Clear clipboard if cut operation completed
        if clipboardAction == .cut && succeeded.count == urls.count {
            clearClipboard()
        }

        return PasteResult(succeeded: succeeded, failed: failed, conflicts: conflicts)
    }

    // MARK: - Paste with conflict resolution

    func pasteWithResolution(to destination: URL, conflictResolution: ConflictResolution) async throws -> PasteResult {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            throw ClipboardError.nothingToPaste
        }

        var succeeded: [URL] = []
        var failed: [(URL, Error)] = []

        for sourceURL in urls {
            let fileName = sourceURL.lastPathComponent
            var destinationURL = destination.appendingPathComponent(fileName)

            // Handle conflicts
            if fileSystemService.pathExists(destinationURL) {
                switch conflictResolution {
                case .skip:
                    continue
                case .replace:
                    // Delete existing file first
                    try? fileSystemService.moveToTrash(destinationURL)
                case .keepBoth:
                    // Append " copy" to filename
                    destinationURL = generateUniqueURL(for: destinationURL)
                }
            }

            do {
                if clipboardAction == .cut {
                    try fileSystemService.moveItem(at: sourceURL, to: destinationURL)
                } else {
                    try fileSystemService.copyItem(at: sourceURL, to: destinationURL)
                }
                succeeded.append(destinationURL)
            } catch {
                failed.append((sourceURL, error))
            }
        }

        // Clear clipboard if cut operation completed
        if clipboardAction == .cut && failed.isEmpty {
            clearClipboard()
        }

        return PasteResult(succeeded: succeeded, failed: failed, conflicts: [])
    }

    // MARK: - Helpers

    func hasClipboardContent() -> Bool {
        return !clipboardItems.isEmpty
    }

    func clearClipboard() {
        clipboardItems = []
        pasteboard.clearContents()
    }

    private func generateUniqueURL(for url: URL) -> URL {
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var newURL = url

        while fileSystemService.pathExists(newURL) {
            let newFilename: String
            if ext.isEmpty {
                newFilename = "\(filename) copy \(counter)"
            } else {
                newFilename = "\(filename) copy \(counter).\(ext)"
            }
            newURL = directory.appendingPathComponent(newFilename)
            counter += 1
        }

        return newURL
    }
}

// MARK: - Supporting Types

struct PasteResult {
    let succeeded: [URL]
    let failed: [(URL, Error)]
    let conflicts: [URL]

    var hasConflicts: Bool {
        return !conflicts.isEmpty
    }

    var allSucceeded: Bool {
        return failed.isEmpty && conflicts.isEmpty
    }
}

enum ConflictResolution {
    case replace
    case keepBoth
    case skip
}

enum ClipboardError: Error, LocalizedError {
    case nothingToPaste
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .nothingToPaste:
            return "Nothing to paste"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}
