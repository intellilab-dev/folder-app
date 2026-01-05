//
//  SearchViewModel.swift
//  Folder
//
//  View model for search functionality
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchQuery: String = ""
    @Published var searchResults: [FileSystemItem] = []
    @Published var isSearching = false
    @Published var isSearchActive = false

    private var searchTask: Task<Void, Never>?
    private let fileSystemService = FileSystemService.shared
    private let embeddingManager = EmbeddingManager.shared
    private let embeddingSearchService = EmbeddingSearchService.shared

    // Debounce timer
    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.15  // 150ms

    // MARK: - Search

    func search(in folder: URL, depth: Int = 2) {
        // Cancel previous search
        searchTask?.cancel()
        debounceTimer?.invalidate()

        guard !searchQuery.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        // Debounce the search
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.searchTask = Task {
                await self.performSearch(in: folder, depth: depth)
            }
        }
    }

    private func performSearch(in folder: URL, depth: Int) async {
        // Check if folder is embedded and has valid credentials
        if embeddingManager.isEmbedded(folder),
           let index = embeddingManager.getEmbeddingIndex(for: folder),
           let apiToken = embeddingManager.apiToken,
           let productId = embeddingManager.productId {

            // Use hybrid search
            let allItems = await getAllItemsRecursively(in: folder, depth: depth)
            let results = await embeddingSearchService.hybridSearch(
                query: searchQuery,
                in: folder,
                embeddingIndex: index,
                allItems: allItems,
                apiToken: apiToken,
                productId: productId
            )
            self.searchResults = results.map { $0.item }.sorted()
        } else {
            // Use existing keyword search
            var results: [FileSystemItem] = []
            await searchRecursively(in: folder, currentDepth: 0, maxDepth: depth, results: &results)
            self.searchResults = results.sorted()
        }

        self.isSearching = false
    }

    /// Get all items recursively for hybrid search
    private func getAllItemsRecursively(in folder: URL, depth: Int) async -> [FileSystemItem] {
        var allItems: [FileSystemItem] = []
        await collectAllItems(in: folder, currentDepth: 0, maxDepth: depth, items: &allItems)
        return allItems
    }

    /// Collect all items recursively
    private func collectAllItems(in folder: URL, currentDepth: Int, maxDepth: Int, items: inout [FileSystemItem]) async {
        // Check if task was cancelled
        if Task.isCancelled {
            return
        }

        // Stop if we've reached max depth
        if currentDepth > maxDepth {
            return
        }

        do {
            let contents = try fileSystemService.contentsOfDirectory(at: folder, showHidden: false)

            for item in contents {
                // Check if task was cancelled
                if Task.isCancelled {
                    return
                }

                items.append(item)

                // Recursively collect from subdirectories
                if item.type == .folder {
                    await collectAllItems(in: item.path, currentDepth: currentDepth + 1, maxDepth: maxDepth, items: &items)
                }
            }
        } catch {
            // Silently handle errors (permission denied, etc.)
        }
    }

    private func searchRecursively(in folder: URL, currentDepth: Int, maxDepth: Int, results: inout [FileSystemItem]) async {
        // Check if task was cancelled
        if Task.isCancelled {
            return
        }

        // Stop if we've reached max depth
        if currentDepth > maxDepth {
            return
        }

        do {
            let contents = try fileSystemService.contentsOfDirectory(at: folder, showHidden: false)

            for item in contents {
                // Check if task was cancelled
                if Task.isCancelled {
                    return
                }

                // Check if filename matches (case-insensitive substring match)
                if item.name.localizedCaseInsensitiveContains(searchQuery) {
                    results.append(item)
                }

                // Recursively search in subdirectories
                if item.type == .folder {
                    await searchRecursively(in: item.path, currentDepth: currentDepth + 1, maxDepth: maxDepth, results: &results)
                }
            }
        } catch {
            // Silently handle errors (permission denied, etc.)
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
        isSearchActive = false
        searchTask?.cancel()
        debounceTimer?.invalidate()
    }

    func activateSearch() {
        isSearchActive = true
    }

    func deactivateSearch() {
        clearSearch()
    }
}
