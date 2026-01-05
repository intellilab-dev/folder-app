//
//  EmbeddingManager.swift
//  Folder
//
//  Manager for coordinating embedding generation and storage
//

import Foundation
import CryptoKit

/// Manager for embedding-based search functionality
@MainActor
class EmbeddingManager: ObservableObject {
    static let shared = EmbeddingManager()

    // MARK: - Published Properties

    @Published var embeddedFolders: Set<URL> = []
    @Published var isProcessing = false
    @Published var processingProgress: ProcessingProgress?

    // MARK: - Services

    private let contentExtractor = ContentExtractorService.shared
    private let embeddingService = InfomaniakEmbeddingService.shared
    private let fileSystemService = FileSystemService.shared

    // MARK: - Storage

    private let embeddingStoragePath: URL
    private let indicesPath: URL
    private var embeddingIndexes: [URL: EmbeddingIndex] = [:]

    // MARK: - UserDefaults Keys

    private let embeddedFoldersKey = "com.folder.embeddedFolders"

    // MARK: - Initialization

    private init() {
        // Setup storage directories
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.embeddingStoragePath = appSupport.appendingPathComponent("FolderApp/embeddings")
        self.indicesPath = embeddingStoragePath.appendingPathComponent("indices")

        // Create directories if needed
        try? FileManager.default.createDirectory(at: indicesPath, withIntermediateDirectories: true)

        // Load embedded folders from UserDefaults
        loadEmbeddedFolders()
    }

    // MARK: - API Credentials

    /// Get API token from .env file
    var apiToken: String? {
        loadFromEnv("INFOMANIAK_API_TOKEN")
    }

    /// Get product ID from .env file
    var productId: String? {
        loadFromEnv("INFOMANIAK_PRODUCT_ID")
    }

    /// Check if API credentials are valid
    var hasValidCredentials: Bool {
        return apiToken != nil && productId != nil
    }

    // MARK: - Public Methods

    /// Check if a folder is embedded
    func isEmbedded(_ folderPath: URL) -> Bool {
        return embeddedFolders.contains(folderPath)
    }

    /// Enable embedding for a folder
    func enableEmbedding(for folderPath: URL) async throws {
        guard hasValidCredentials else {
            throw EmbeddingError.invalidCredentials
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            try await processFolder(folderPath)
            embeddedFolders.insert(folderPath)
            saveEmbeddedFolders()
        } catch {
            // Remove from embedded folders if processing failed
            embeddedFolders.remove(folderPath)
            throw error
        }
    }

    /// Disable embedding for a folder
    func disableEmbedding(for folderPath: URL) {
        // Remove from set
        embeddedFolders.remove(folderPath)
        saveEmbeddedFolders()

        // Delete index file
        let indexPath = getIndexPath(for: folderPath)
        try? FileManager.default.removeItem(at: indexPath)

        // Remove from cache
        embeddingIndexes.removeValue(forKey: folderPath)
    }

    /// Get embedding index for a folder
    func getEmbeddingIndex(for folderPath: URL) -> EmbeddingIndex? {
        // Check cache first
        if let cached = embeddingIndexes[folderPath] {
            return cached
        }

        // Load from disk
        if let loaded = loadIndex(for: folderPath) {
            embeddingIndexes[folderPath] = loaded
            return loaded
        }

        return nil
    }

    /// Get all embeddable files in a folder recursively
    func getEmbeddableFiles(in folderPath: URL) -> [FileSystemItem] {
        var embeddableFiles: [FileSystemItem] = []
        collectEmbeddableFiles(in: folderPath, results: &embeddableFiles)
        return embeddableFiles
    }

    // MARK: - Private Methods

    /// Process a folder and generate embeddings
    private func processFolder(_ folderPath: URL) async throws {
        // Find all embeddable files
        let files = getEmbeddableFiles(in: folderPath)

        guard !files.isEmpty else {
            throw NSError(domain: "EmbeddingManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No embeddable files found in folder"
            ])
        }

        // Initialize progress
        processingProgress = ProcessingProgress(
            current: 0,
            total: files.count,
            currentFile: "",
            successCount: 0,
            errors: []
        )

        var records: [EmbeddingRecord] = []

        // Process each file
        for (index, file) in files.enumerated() {
            // Update progress
            processingProgress?.current = index
            processingProgress?.currentFile = file.name

            do {
                // Extract text
                guard let text = await contentExtractor.extractText(from: file.path) else {
                    processingProgress?.errors.append((file.name, "Could not extract text"))
                    continue
                }

                // Skip empty text
                guard !text.isEmpty else {
                    processingProgress?.errors.append((file.name, "No text content"))
                    continue
                }

                // Generate embedding
                let embedding = try await embeddingService.generateEmbeddingWithRetry(
                    text: text,
                    apiToken: apiToken!,
                    productId: productId!
                )

                // Create preview
                let preview = contentExtractor.createPreview(from: text)

                // Create record with relative path
                let relativePath = file.path.path.replacingOccurrences(of: folderPath.path + "/", with: "")
                let record = EmbeddingRecord(
                    filePath: relativePath,
                    embedding: embedding,
                    textPreview: preview,
                    fileModifiedDate: file.modifiedAt
                )

                records.append(record)
                processingProgress?.successCount += 1

            } catch {
                processingProgress?.errors.append((file.name, error.localizedDescription))
            }
        }

        // Mark processing as complete
        processingProgress?.current = files.count

        // Save index
        let index = EmbeddingIndex(
            folderPath: folderPath.path,
            records: records
        )
        saveIndex(index, for: folderPath)
        embeddingIndexes[folderPath] = index
    }

    /// Recursively collect embeddable files
    private func collectEmbeddableFiles(in folderPath: URL, results: inout [FileSystemItem]) {
        do {
            let contents = try fileSystemService.contentsOfDirectory(at: folderPath, showHidden: false)

            for item in contents {
                if item.type == .folder {
                    // Recurse into subdirectories
                    collectEmbeddableFiles(in: item.path, results: &results)
                } else if item.isEmbeddable {
                    results.append(item)
                }
            }
        } catch {
            // Silently skip directories we can't access
        }
    }

    // MARK: - Storage Methods

    /// Get index file path for a folder
    private func getIndexPath(for folderPath: URL) -> URL {
        let hash = folderHash(for: folderPath)
        return indicesPath.appendingPathComponent("\(hash).json")
    }

    /// Generate hash for folder path
    private func folderHash(for url: URL) -> String {
        let data = url.path.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Save embedding index to disk
    private func saveIndex(_ index: EmbeddingIndex, for folder: URL) {
        let indexPath = getIndexPath(for: folder)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(index)
            try data.write(to: indexPath)
        } catch {
            print("Failed to save embedding index: \(error)")
        }
    }

    /// Load embedding index from disk
    private func loadIndex(for folder: URL) -> EmbeddingIndex? {
        let indexPath = getIndexPath(for: folder)

        guard FileManager.default.fileExists(atPath: indexPath.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: indexPath)
            let decoder = JSONDecoder()
            return try decoder.decode(EmbeddingIndex.self, from: data)
        } catch {
            print("Failed to load embedding index: \(error)")
            return nil
        }
    }

    /// Save embedded folders to UserDefaults
    private func saveEmbeddedFolders() {
        let paths = embeddedFolders.map { $0.path }
        UserDefaults.standard.set(paths, forKey: embeddedFoldersKey)
    }

    /// Load embedded folders from UserDefaults
    private func loadEmbeddedFolders() {
        if let paths = UserDefaults.standard.array(forKey: embeddedFoldersKey) as? [String] {
            embeddedFolders = Set(paths.map { URL(fileURLWithPath: $0) })
        }
    }

    // MARK: - .env File Parsing

    /// Load value from .env file
    private func loadFromEnv(_ key: String) -> String? {
        // Try project root first
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if let value = loadFromEnvFile(at: projectRoot.appendingPathComponent(".env"), key: key) {
            return value
        }

        // Try home directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        if let value = loadFromEnvFile(at: homeDir.appendingPathComponent(".env"), key: key) {
            return value
        }

        // Try app directory
        let appDir = URL(fileURLWithPath: "/Users/mattia/Documents/Home/folder")
        if let value = loadFromEnvFile(at: appDir.appendingPathComponent(".env"), key: key) {
            return value
        }

        return nil
    }

    /// Load value from specific .env file
    private func loadFromEnvFile(at url: URL, key: String) -> String? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else {
                continue
            }

            // Parse key=value
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else {
                continue
            }

            let lineKey = parts[0].trimmingCharacters(in: .whitespaces)
            if lineKey == key {
                let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
                return value
            }
        }

        return nil
    }
}
