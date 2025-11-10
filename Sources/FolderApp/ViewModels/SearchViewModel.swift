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
        var results: [FileSystemItem] = []

        // Recursive search with depth limit
        await searchRecursively(in: folder, currentDepth: 0, maxDepth: depth, results: &results)

        // Update results on main thread
        self.searchResults = results.sorted()
        self.isSearching = false
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
