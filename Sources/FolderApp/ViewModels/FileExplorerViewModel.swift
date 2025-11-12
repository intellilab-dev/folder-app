//
//  FileExplorerViewModel.swift
//  Folder
//
//  Main view model for file exploration and navigation
//

import Foundation
import Combine
import AppKit

@MainActor
class FileExplorerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPath: URL
    @Published var items: [FileSystemItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var viewMode: ViewMode = .default
    @Published var selectedItems: Set<UUID> = []
    @Published var lastSelectedItem: UUID? // Track last selected item for range selection
    @Published var folderSizes: [URL: Int64] = [:] // Cache folder sizes

    // Navigation history
    @Published var canGoBack = false
    @Published var canGoForward = false

    private var navigationHistory: [URL] = []
    private var currentHistoryIndex = -1

    // Services
    private let fileSystemService = FileSystemService.shared
    private let settingsManager = SettingsManager.shared
    private let fileWatcher = FileSystemWatcher()

    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(initialPath: URL? = nil) {
        // Start at home directory or last opened folder
        if let path = initialPath ?? settingsManager.settings.lastOpenedFolder {
            self.currentPath = path
        } else {
            self.currentPath = fileSystemService.homeDirectory()
        }

        // Subscribe to file system changes
        setupFileWatcher()

        // Load initial contents
        Task {
            await loadContents()
        }
    }

    // MARK: - File System Watching

    private func setupFileWatcher() {
        fileWatcher.$didDetectChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] didChange in
                guard let self = self, didChange else { return }

                // Auto-refresh when changes detected
                print("Auto-refreshing due to file system changes")
                Task {
                    await self.loadContents()
                }

                // Reset the flag
                self.fileWatcher.resetChangeFlag()
            }
            .store(in: &cancellables)
    }

    // MARK: - Directory Loading

    func loadContents() async {
        isLoading = true
        errorMessage = nil

        do {
            let showHidden = settingsManager.settings.showHiddenFiles
            let contents = try fileSystemService.contentsOfDirectory(at: currentPath, showHidden: showHidden)

            // Sort based on current view mode
            self.items = sortItems(contents)
            self.isLoading = false

            // Save as last opened folder
            settingsManager.settings.lastOpenedFolder = currentPath

            // Select first item by default
            if !items.isEmpty {
                selectedItems.insert(items[0].id)
            }

            // Calculate folder sizes in background
            Task.detached(priority: .background) { [weak self] in
                await self?.calculateFolderSizes(for: contents.filter { $0.type == .folder })
            }

            // Start watching the current directory for changes
            fileWatcher.startWatching(url: currentPath)
        } catch {
            self.errorMessage = "Failed to load directory: \(error.localizedDescription)"
            self.items = []
            self.isLoading = false

            // Stop watching on error
            fileWatcher.stopWatching()
        }
    }

    private func calculateFolderSizes(for folders: [FileSystemItem]) async {
        for folder in folders {
            // Skip if already calculated
            if folderSizes[folder.path] != nil {
                continue
            }

            do {
                let size = try await fileSystemService.calculateFolderSize(at: folder.path)
                await MainActor.run {
                    self.folderSizes[folder.path] = size
                }
            } catch {
                // Silently fail for inaccessible folders
            }
        }
    }

    // MARK: - Navigation

    func navigate(to url: URL) {
        guard fileSystemService.pathExists(url) else {
            errorMessage = "Path does not exist: \(url.path)"
            return
        }

        // Add to history
        if currentHistoryIndex < navigationHistory.count - 1 {
            // Remove forward history when navigating to new location
            navigationHistory.removeSubrange((currentHistoryIndex + 1)...)
        }

        navigationHistory.append(currentPath)
        currentHistoryIndex = navigationHistory.count - 1

        // Update navigation state
        updateNavigationState()

        // Navigate
        currentPath = url
        selectedItems.removeAll()

        Task {
            await loadContents()
        }
    }

    func navigateToParent() {
        guard let parent = fileSystemService.parentDirectory(of: currentPath) else {
            return
        }
        navigate(to: parent)
    }

    func navigateBack() {
        guard canGoBack, currentHistoryIndex > 0 else { return }

        currentHistoryIndex -= 1
        currentPath = navigationHistory[currentHistoryIndex]
        selectedItems.removeAll()

        Task {
            await loadContents()
        }

        updateNavigationState()
    }

    func navigateForward() {
        guard canGoForward, currentHistoryIndex < navigationHistory.count - 1 else { return }

        currentHistoryIndex += 1
        currentPath = navigationHistory[currentHistoryIndex]
        selectedItems.removeAll()

        Task {
            await loadContents()
        }

        updateNavigationState()
    }

    private func updateNavigationState() {
        canGoBack = currentHistoryIndex > 0
        canGoForward = currentHistoryIndex < navigationHistory.count - 1
    }

    // MARK: - Item Selection

    func toggleSelection(for item: FileSystemItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        lastSelectedItem = item.id
    }

    func selectAll() {
        selectedItems = Set(items.map { $0.id })
    }

    func clearSelection() {
        selectedItems.removeAll()
    }

    func isSelected(_ item: FileSystemItem) -> Bool {
        return selectedItems.contains(item.id)
    }

    func selectRange(from startItem: FileSystemItem, to endItem: FileSystemItem) {
        guard let startIndex = items.firstIndex(where: { $0.id == startItem.id }),
              let endIndex = items.firstIndex(where: { $0.id == endItem.id }) else {
            return
        }

        let range = startIndex <= endIndex ? startIndex...endIndex : endIndex...startIndex
        for index in range {
            selectedItems.insert(items[index].id)
        }
        lastSelectedItem = endItem.id
    }

    // MARK: - Item Actions

    func openItem(_ item: FileSystemItem) {
        if item.type == .folder {
            navigate(to: item.path)
        } else {
            // Open file with default application
            NSWorkspace.shared.open(item.path)
        }
    }

    // MARK: - View Mode

    func toggleViewMode() {
        viewMode.mode = viewMode.mode == .iconGrid ? .list : .iconGrid
    }

    func setViewMode(_ mode: ViewMode.DisplayMode) {
        viewMode.mode = mode
    }

    func setSortOption(_ sortBy: ViewMode.SortOption) {
        viewMode.sortBy = sortBy
        items = sortItems(items)
    }

    func toggleSortOrder() {
        viewMode.sortOrder = viewMode.sortOrder == .ascending ? .descending : .ascending
        items = sortItems(items)
    }

    // MARK: - Sorting

    private func sortItems(_ items: [FileSystemItem]) -> [FileSystemItem] {
        var sorted = items

        // Sort by selected option
        switch viewMode.sortBy {
        case .name:
            sorted.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateModified:
            sorted.sort { $0.modifiedAt < $1.modifiedAt }
        case .size:
            sorted.sort { $0.size < $1.size }
        case .type:
            sorted.sort { $0.type.rawValue < $1.type.rawValue }
        }

        // Apply sort order
        if viewMode.sortOrder == .descending {
            sorted.reverse()
        }

        return sorted
    }

    // MARK: - Refresh

    func refresh() {
        Task {
            await loadContents()
        }
    }

    // MARK: - Keyboard Navigation

    func selectNextItem() {
        guard !items.isEmpty else { return }

        if let firstSelected = selectedItems.first,
           let currentIndex = items.firstIndex(where: { $0.id == firstSelected }) {
            let nextIndex = min(currentIndex + 1, items.count - 1)
            clearSelection()
            selectedItems.insert(items[nextIndex].id)
        } else {
            // No selection, select first item
            selectedItems.insert(items[0].id)
        }
    }

    func selectPreviousItem() {
        guard !items.isEmpty else { return }

        if let firstSelected = selectedItems.first,
           let currentIndex = items.firstIndex(where: { $0.id == firstSelected }) {
            let prevIndex = max(currentIndex - 1, 0)
            clearSelection()
            selectedItems.insert(items[prevIndex].id)
        } else {
            // No selection, select first item
            selectedItems.insert(items[0].id)
        }
    }

    func selectItemBelow(columnsPerRow: Int) {
        guard !items.isEmpty else { return }

        if let firstSelected = selectedItems.first,
           let currentIndex = items.firstIndex(where: { $0.id == firstSelected }) {
            let nextIndex = min(currentIndex + columnsPerRow, items.count - 1)
            clearSelection()
            selectedItems.insert(items[nextIndex].id)
        } else {
            // No selection, select first item
            selectedItems.insert(items[0].id)
        }
    }

    func selectItemAbove(columnsPerRow: Int) {
        guard !items.isEmpty else { return }

        if let firstSelected = selectedItems.first,
           let currentIndex = items.firstIndex(where: { $0.id == firstSelected }) {
            let prevIndex = max(currentIndex - columnsPerRow, 0)
            clearSelection()
            selectedItems.insert(items[prevIndex].id)
        } else {
            // No selection, select first item
            selectedItems.insert(items[0].id)
        }
    }

    func openSelectedItem() {
        guard let firstSelected = selectedItems.first,
              let item = items.first(where: { $0.id == firstSelected }) else {
            return
        }
        openItem(item)
    }

    func navigateIntoSelectedFolder() {
        guard let firstSelected = selectedItems.first,
              let item = items.first(where: { $0.id == firstSelected }) else {
            // No selection, navigate into first folder
            if let firstFolder = items.first(where: { $0.type == .folder }) {
                navigate(to: firstFolder.path)
            }
            return
        }

        if item.type == .folder {
            navigate(to: item.path)
        }
    }

    // MARK: - File Operations

    func createNewFolder(named name: String) {
        do {
            try fileSystemService.createFolder(at: currentPath, named: name)
            refresh()
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }

    func renameItem(_ item: FileSystemItem, to newName: String) {
        let newPath = item.path.deletingLastPathComponent().appendingPathComponent(newName)

        do {
            try FileManager.default.moveItem(at: item.path, to: newPath)
            refresh()
        } catch {
            errorMessage = "Failed to rename item: \(error.localizedDescription)"
        }
    }

    func deleteSelectedItems() {
        let selectedItemsList = items.filter { selectedItems.contains($0.id) }

        for item in selectedItemsList {
            do {
                try FileManager.default.trashItem(at: item.path, resultingItemURL: nil)
            } catch {
                errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
        }

        selectedItems.removeAll()
        refresh()
    }

    // MARK: - Deinitialization

    deinit {
        fileWatcher.stopWatching()
    }
}
