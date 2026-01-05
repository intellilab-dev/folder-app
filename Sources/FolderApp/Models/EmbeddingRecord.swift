//
//  EmbeddingRecord.swift
//  Folder
//
//  Data models for embedding-based search
//

import Foundation

/// Represents a single file's embedding data
struct EmbeddingRecord: Codable, Identifiable {
    let id: UUID
    let filePath: String              // Relative to folder root
    let embedding: [Float]            // 384 dimensions (mini_lm_l12_v2 model)
    let textPreview: String           // First 200 chars for display
    let timestamp: Date               // When embedding was created
    let fileModifiedDate: Date        // File's modification date (for staleness detection)

    init(
        id: UUID = UUID(),
        filePath: String,
        embedding: [Float],
        textPreview: String,
        timestamp: Date = Date(),
        fileModifiedDate: Date
    ) {
        self.id = id
        self.filePath = filePath
        self.embedding = embedding
        self.textPreview = textPreview
        self.timestamp = timestamp
        self.fileModifiedDate = fileModifiedDate
    }
}

/// Index containing all embeddings for a folder
struct EmbeddingIndex: Codable {
    var folderPath: String
    var records: [EmbeddingRecord]
    var lastUpdated: Date

    init(folderPath: String, records: [EmbeddingRecord] = [], lastUpdated: Date = Date()) {
        self.folderPath = folderPath
        self.records = records
        self.lastUpdated = lastUpdated
    }
}

/// Search result with relevance scoring
struct SearchResult: Identifiable {
    let id: UUID
    let item: FileSystemItem
    let score: Float
    let matchType: MatchType
    let textSnippet: String?

    enum MatchType {
        case keywordOnly
        case embeddingOnly
        case hybrid
    }

    init(
        id: UUID = UUID(),
        item: FileSystemItem,
        score: Float,
        matchType: MatchType,
        textSnippet: String? = nil
    ) {
        self.id = id
        self.item = item
        self.score = score
        self.matchType = matchType
        self.textSnippet = textSnippet
    }
}

/// Progress tracking for embedding generation
struct ProcessingProgress {
    var current: Int
    var total: Int
    var currentFile: String
    var successCount: Int
    var errors: [(filename: String, error: String)]

    init(
        current: Int = 0,
        total: Int = 0,
        currentFile: String = "",
        successCount: Int = 0,
        errors: [(filename: String, error: String)] = []
    ) {
        self.current = current
        self.total = total
        self.currentFile = currentFile
        self.successCount = successCount
        self.errors = errors
    }

    var isComplete: Bool {
        return current >= total && total > 0
    }

    var progressPercentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(current) / Double(total) * 100.0
    }
}
