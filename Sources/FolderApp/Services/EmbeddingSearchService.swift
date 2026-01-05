//
//  EmbeddingSearchService.swift
//  Folder
//
//  Service for hybrid keyword + embedding search
//

import Foundation

/// Service for performing hybrid search combining keyword and semantic matching
@MainActor
class EmbeddingSearchService {
    static let shared = EmbeddingSearchService()

    private init() {}

    private let embeddingService = InfomaniakEmbeddingService.shared

    // MARK: - Hybrid Search

    /// Perform hybrid search combining keyword and embedding similarity
    func hybridSearch(
        query: String,
        in folderPath: URL,
        embeddingIndex: EmbeddingIndex,
        allItems: [FileSystemItem],
        apiToken: String,
        productId: String
    ) async -> [SearchResult] {
        // Generate query embedding
        guard let queryEmbedding = try? await embeddingService.generateEmbedding(
            text: query,
            apiToken: apiToken,
            productId: productId
        ) else {
            // Fall back to keyword-only search if embedding fails
            return keywordOnlySearch(query: query, items: allItems)
        }

        // Perform keyword search
        let keywordResults = performKeywordSearch(query: query, items: allItems)

        // Perform embedding search
        let embeddingResults = performEmbeddingSearch(
            queryEmbedding: queryEmbedding,
            index: embeddingIndex,
            allItems: allItems
        )

        // Merge and rank results
        let mergedResults = mergeResults(
            keyword: keywordResults,
            embedding: embeddingResults
        )

        // Filter by threshold and sort
        let threshold: Float = 0.3
        return mergedResults
            .filter { $0.score > threshold }
            .sorted { $0.score > $1.score }
            .prefix(50)
            .map { $0 }
    }

    // MARK: - Keyword Search

    /// Perform keyword-based search on filenames
    private func performKeywordSearch(
        query: String,
        items: [FileSystemItem]
    ) -> [(FileSystemItem, Float)] {
        var results: [(FileSystemItem, Float)] = []

        for item in items {
            let score = keywordScore(item: item, query: query)
            if score > 0 {
                results.append((item, score))
            }
        }

        return results
    }

    /// Calculate keyword matching score
    private func keywordScore(item: FileSystemItem, query: String) -> Float {
        let queryLower = query.lowercased()
        let nameLower = item.name.lowercased()

        // Exact match
        if nameLower == queryLower {
            return 1.0
        }

        // Starts with
        if nameLower.hasPrefix(queryLower) {
            return 0.8
        }

        // Contains
        if nameLower.contains(queryLower) {
            return 0.5
        }

        // Word boundary match (more sophisticated)
        let words = nameLower.components(separatedBy: CharacterSet.alphanumerics.inverted)
        for word in words {
            if word.hasPrefix(queryLower) {
                return 0.6
            }
        }

        return 0.0
    }

    /// Keyword-only search fallback
    private func keywordOnlySearch(query: String, items: [FileSystemItem]) -> [SearchResult] {
        let keywordResults = performKeywordSearch(query: query, items: items)

        return keywordResults.map { item, score in
            SearchResult(
                item: item,
                score: score,
                matchType: .keywordOnly,
                textSnippet: nil
            )
        }
        .sorted { $0.score > $1.score }
        .prefix(50)
        .map { $0 }
    }

    // MARK: - Embedding Search

    /// Perform embedding-based semantic search
    private func performEmbeddingSearch(
        queryEmbedding: [Float],
        index: EmbeddingIndex,
        allItems: [FileSystemItem]
    ) -> [(EmbeddingRecord, Float, FileSystemItem)] {
        var results: [(EmbeddingRecord, Float, FileSystemItem)] = []

        // Create a lookup map for items by relative path
        let itemsByPath = createItemLookup(items: allItems, folderPath: index.folderPath)

        for record in index.records {
            // Calculate similarity
            let similarity = cosineSimilarity(queryEmbedding, record.embedding)

            // Find corresponding FileSystemItem
            if let item = itemsByPath[record.filePath] {
                results.append((record, similarity, item))
            }
        }

        return results
    }

    /// Create lookup map from relative paths to items
    private func createItemLookup(items: [FileSystemItem], folderPath: String) -> [String: FileSystemItem] {
        var lookup: [String: FileSystemItem] = [:]

        for item in items {
            let relativePath = item.path.path.replacingOccurrences(of: folderPath + "/", with: "")
            lookup[relativePath] = item
        }

        return lookup
    }

    /// Calculate cosine similarity between two vectors
    func cosineSimilarity(_ vec1: [Float], _ vec2: [Float]) -> Float {
        guard vec1.count == vec2.count else { return 0.0 }

        var dotProduct: Float = 0.0
        var magnitude1: Float = 0.0
        var magnitude2: Float = 0.0

        for i in 0..<vec1.count {
            dotProduct += vec1[i] * vec2[i]
            magnitude1 += vec1[i] * vec1[i]
            magnitude2 += vec2[i] * vec2[i]
        }

        magnitude1 = sqrt(magnitude1)
        magnitude2 = sqrt(magnitude2)

        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }

        return dotProduct / (magnitude1 * magnitude2)
    }

    // MARK: - Result Merging

    /// Merge and rank keyword and embedding results
    private func mergeResults(
        keyword: [(FileSystemItem, Float)],
        embedding: [(EmbeddingRecord, Float, FileSystemItem)]
    ) -> [SearchResult] {
        // Create lookup maps
        var keywordScores: [URL: Float] = [:]
        for (item, score) in keyword {
            keywordScores[item.path] = score
        }

        var embeddingScores: [URL: (Float, String)] = [:]
        for (record, score, item) in embedding {
            embeddingScores[item.path] = (score, record.textPreview)
        }

        // Get all unique items
        var allPaths = Set<URL>()
        allPaths.formUnion(keywordScores.keys)
        allPaths.formUnion(embeddingScores.keys)

        // Calculate hybrid scores
        var results: [SearchResult] = []
        let keywordWeight: Float = 0.4
        let embeddingWeight: Float = 0.6

        for path in allPaths {
            let kwScore = keywordScores[path] ?? 0.0
            let embScore = embeddingScores[path]?.0 ?? 0.0

            let hybridScore = (keywordWeight * kwScore) + (embeddingWeight * embScore)

            // Determine match type
            let matchType: SearchResult.MatchType
            if kwScore > 0 && embScore > 0 {
                matchType = .hybrid
            } else if kwScore > 0 {
                matchType = .keywordOnly
            } else {
                matchType = .embeddingOnly
            }

            // Find the item
            if let item = keyword.first(where: { $0.0.path == path })?.0 ??
                          embedding.first(where: { $0.2.path == path })?.2 {
                let snippet = embeddingScores[path]?.1

                results.append(SearchResult(
                    item: item,
                    score: hybridScore,
                    matchType: matchType,
                    textSnippet: snippet
                ))
            }
        }

        return results
    }
}
