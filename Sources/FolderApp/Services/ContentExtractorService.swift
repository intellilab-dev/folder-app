//
//  ContentExtractorService.swift
//  Folder
//
//  Service for extracting text content from files
//

import Foundation
import PDFKit

/// Service for extracting text from various file types
@MainActor
class ContentExtractorService {
    static let shared = ContentExtractorService()

    private init() {}

    /// Maximum characters to extract (API limit consideration)
    private let maxCharacters = 8000

    /// Extract text from a file
    /// - Parameter url: File URL
    /// - Returns: Extracted text, or nil if extraction failed
    func extractText(from url: URL) async -> String? {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "pdf":
            return await extractFromPDF(url)
        case "md", "txt", "markdown":
            return extractFromText(url)
        default:
            return nil
        }
    }

    /// Extract text from PDF using PDFKit
    private func extractFromPDF(_ url: URL) async -> String? {
        return await Task.detached {
            guard let document = PDFDocument(url: url) else {
                return nil
            }

            var text = ""
            let pageCount = document.pageCount

            // Extract text from each page
            for pageIndex in 0..<pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                guard let pageText = page.string else { continue }

                text += pageText
                text += "\n\n"  // Separate pages

                // Stop if we've exceeded max characters
                if text.count > self.maxCharacters {
                    break
                }
            }

            // Truncate if needed
            if text.count > self.maxCharacters {
                text = String(text.prefix(self.maxCharacters))
            }

            // Clean up extra whitespace
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            return text.isEmpty ? nil : text
        }.value
    }

    /// Extract text from plain text/markdown files
    private func extractFromText(_ url: URL) -> String? {
        do {
            var text = try String(contentsOf: url, encoding: .utf8)

            // Truncate if needed
            if text.count > maxCharacters {
                text = String(text.prefix(maxCharacters))
            }

            // Clean up extra whitespace
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            return text.isEmpty ? nil : text
        } catch {
            // Try with other encodings if UTF-8 fails
            if let text = try? String(contentsOf: url, encoding: .isoLatin1) {
                let truncated = text.count > maxCharacters ? String(text.prefix(maxCharacters)) : text
                return truncated.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return nil
        }
    }

    /// Create a preview snippet from extracted text
    /// - Parameter text: Full extracted text
    /// - Returns: First 200 characters for preview
    func createPreview(from text: String) -> String {
        let previewLength = 200
        if text.count <= previewLength {
            return text
        }

        let preview = String(text.prefix(previewLength))
        return preview + "..."
    }
}
