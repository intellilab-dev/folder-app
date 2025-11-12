//
//  ContentView.swift
//  Folder
//
//  Main container view
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel: FileExplorerViewModel
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var sidebarManager = SidebarManager.shared
    @EnvironmentObject var settingsManager: SettingsManager

    init(initialPath: URL? = nil) {
        _viewModel = StateObject(wrappedValue: FileExplorerViewModel(initialPath: initialPath))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            if settingsManager.settings.showSidebar {
                SidebarView(sidebarManager: sidebarManager, fileExplorerViewModel: viewModel)
                Divider()
            }

            // Main content area
            mainContentArea
        }
        .background(Color.folderBase)
        .preferredColorScheme(colorScheme)
        .onAppear {
            setupKeyboardHandling()
        }
        .onChange(of: viewModel.currentPath) { newPath in
            // Add to recent locations when navigating
            sidebarManager.addRecentLocation(newPath)
        }
    }

    private var colorScheme: ColorScheme? {
        switch settingsManager.settings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Use system default
        }
    }

    private var mainContentArea: some View {
        VStack(spacing: 0) {
            // Navigation Bar with integrated search
            NavigationBar(viewModel: viewModel, searchViewModel: searchViewModel)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Main Content Area
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.headline)
                    Button("Try Again") {
                        viewModel.refresh()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchViewModel.isSearchActive {
                // Search mode active
                if searchViewModel.searchQuery.isEmpty {
                    // Empty search query: show normal view
                    Group {
                        if viewModel.viewMode.mode == .iconGrid {
                            FileGridView(viewModel: viewModel, searchViewModel: searchViewModel, showDimmed: false)
                        } else {
                            FileListView(viewModel: viewModel, searchViewModel: searchViewModel, showDimmed: false)
                        }
                    }
                } else if searchViewModel.searchResults.isEmpty && !searchViewModel.isSearching {
                    // No results: show all items dimmed
                    Group {
                        if viewModel.viewMode.mode == .iconGrid {
                            FileGridView(viewModel: viewModel, searchViewModel: searchViewModel, showDimmed: true)
                        } else {
                            FileListView(viewModel: viewModel, searchViewModel: searchViewModel, showDimmed: true)
                        }
                    }
                } else {
                    // Show search results
                    Group {
                        if viewModel.viewMode.mode == .iconGrid {
                            SearchResultsGridView(searchViewModel: searchViewModel, fileExplorerViewModel: viewModel)
                        } else {
                            SearchResultsListView(searchViewModel: searchViewModel, fileExplorerViewModel: viewModel)
                        }
                    }
                }
            } else {
                // Normal File Grid or List View
                Group {
                    if viewModel.viewMode.mode == .iconGrid {
                        FileGridView(viewModel: viewModel, searchViewModel: searchViewModel, showDimmed: false)
                    } else {
                        FileListView(viewModel: viewModel, searchViewModel: searchViewModel, showDimmed: false)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func setupKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return handleKeyEvent(event) ? nil : event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Don't intercept events when a text field is being edited (except for Cmd shortcuts)
        let isTextField = NSApp.keyWindow?.firstResponder is NSTextView ||
                         NSApp.keyWindow?.firstResponder is NSTextField

        let modifiers = event.modifierFlags
        let isCommandPressed = modifiers.contains(.command)
        let isControlPressed = modifiers.contains(.control)
        let isOptionPressed = modifiers.contains(.option)

        // Get keyboard settings
        let shortcuts = settingsManager.settings.keyboardShortcuts

        // Handle Cmd shortcuts even when text field is active
        if isCommandPressed && !isControlPressed {
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "f":
                // Cmd+F: Activate search (if enabled)
                if shortcuts.searchEnabled {
                    searchViewModel.activateSearch()
                    return true
                }
                return false

            case "c":
                // Cmd+C: Copy selected items (only when not in text field)
                if !isTextField {
                    copySelectedItems()
                    return true
                }
                return false

            case "x":
                // Cmd+X: Cut selected items (only when not in text field)
                if !isTextField {
                    cutSelectedItems()
                    return true
                }
                return false

            case "v":
                // Cmd+V: Paste items (only when not in text field)
                if !isTextField {
                    pasteItems()
                    return true
                }
                return false

            case "n":
                // Cmd+Shift+N: New folder (only when not in text field)
                if !isTextField && modifiers.contains(.shift) {
                    showNewFolderPrompt()
                    return true
                }
                return false

            case "t":
                // Cmd+T: Open selected folder in new window (only when not in text field)
                if !isTextField {
                    openSelectedFolderInNewWindow()
                    return true
                }
                return false

            default:
                return false
            }
        }

        // Don't intercept other keys when text field is active
        if isTextField {
            return false
        }

        // Handle Delete key (only when not in text field)
        if event.keyCode == 51 { // Delete key
            viewModel.deleteSelectedItems()
            return true
        }

        // Check if navigation modifier is pressed (for folder navigation)
        let navigationModifierPressed = shortcuts.navigationEnabled && (
            (shortcuts.navigationModifier == .control && isControlPressed) ||
            (shortcuts.navigationModifier == .command && isCommandPressed) ||
            (shortcuts.navigationModifier == .option && isOptionPressed)
        )

        switch event.keyCode {
        // Arrow keys
        case 126: // Up arrow
            if navigationModifierPressed {
                // Navigation modifier + Up: currently not used
                return false
            } else if shortcuts.arrowKeysEnabled && !isControlPressed && !isCommandPressed && !isOptionPressed {
                // Plain arrow keys: navigate between files (if enabled)
                if viewModel.viewMode.mode == .iconGrid {
                    // Grid view: navigate to item above
                    let columnsPerRow = calculateGridColumns()
                    viewModel.selectItemAbove(columnsPerRow: columnsPerRow)
                } else {
                    viewModel.selectPreviousItem()
                }
                return true
            }
            return false

        case 125: // Down arrow
            if navigationModifierPressed {
                // Navigation modifier + Down: currently not used
                return false
            } else if shortcuts.arrowKeysEnabled && !isControlPressed && !isCommandPressed && !isOptionPressed {
                // Plain arrow keys: navigate between files (if enabled)
                if viewModel.viewMode.mode == .iconGrid {
                    let columnsPerRow = calculateGridColumns()
                    viewModel.selectItemBelow(columnsPerRow: columnsPerRow)
                } else {
                    viewModel.selectNextItem()
                }
                return true
            }
            return false

        case 123: // Left arrow
            if navigationModifierPressed {
                // Navigation modifier + Left: Navigate to parent folder
                viewModel.navigateToParent()
                return true
            } else if shortcuts.arrowKeysEnabled && !isControlPressed && !isCommandPressed && !isOptionPressed {
                viewModel.selectPreviousItem()
                return true
            }
            return false

        case 124: // Right arrow
            if navigationModifierPressed {
                // Navigation modifier + Right: Navigate into selected folder
                viewModel.navigateIntoSelectedFolder()
                return true
            } else if shortcuts.arrowKeysEnabled && !isControlPressed && !isCommandPressed && !isOptionPressed {
                viewModel.selectNextItem()
                return true
            }
            return false

        case 36: // Enter/Return
            viewModel.openSelectedItem()
            return true

        case 53: // Escape
            viewModel.clearSelection()
            return true

        case 49: // Space bar - Quick Look
            showQuickLook()
            return true

        default:
            return false
        }
    }

    // MARK: - Grid Navigation Helper

    private func calculateGridColumns() -> Int {
        // Calculate columns to match LazyVGrid's adaptive layout
        guard let window = NSApp.keyWindow else { return 4 }

        let windowWidth = window.frame.width
        let sidebarWidth: CGFloat = settingsManager.settings.showSidebar ? 200 : 0 // Approximate sidebar width
        let dividerWidth: CGFloat = settingsManager.settings.showSidebar ? 1 : 0

        // Available width for grid content
        let availableWidth = windowWidth - sidebarWidth - dividerWidth

        // Grid uses .padding() which is default 16px on each side
        let horizontalPadding: CGFloat = 16 * 2
        let contentWidth = availableWidth - horizontalPadding

        // Grid item sizing: minimum = iconSize + 40, spacing = 16
        let iconSize = CGFloat(viewModel.viewMode.iconSize)
        let itemMinWidth = iconSize + 40
        let spacing: CGFloat = 16

        // Calculate how many items fit: (contentWidth + spacing) / (itemMinWidth + spacing)
        // We add spacing to contentWidth because the last item doesn't have trailing spacing
        let columns = max(1, Int((contentWidth + spacing) / (itemMinWidth + spacing)))

        return columns
    }

    // MARK: - Clipboard Operations

    private func copySelectedItems() {
        let selectedItemsList = viewModel.items.filter { viewModel.selectedItems.contains($0.id) }
        guard !selectedItemsList.isEmpty else { return }
        clipboardManager.copy(items: selectedItemsList)
    }

    private func cutSelectedItems() {
        let selectedItemsList = viewModel.items.filter { viewModel.selectedItems.contains($0.id) }
        guard !selectedItemsList.isEmpty else { return }
        clipboardManager.cut(items: selectedItemsList)
    }

    private func pasteItems() {
        Task {
            do {
                let result = try await clipboardManager.paste(to: viewModel.currentPath)

                if result.hasConflicts {
                    // Show conflict resolution dialog (simplified for now - just skip conflicts)
                    let finalResult = try await clipboardManager.pasteWithResolution(
                        to: viewModel.currentPath,
                        conflictResolution: .skip
                    )
                    print("Pasted \(finalResult.succeeded.count) items, skipped \(result.conflicts.count) conflicts")
                } else {
                    print("Pasted \(result.succeeded.count) items successfully")
                }

                // Refresh the view to show pasted items
                viewModel.refresh()
            } catch {
                print("Paste failed: \(error.localizedDescription)")
            }
        }
    }

    private func openSelectedFolderInNewWindow() {
        guard let firstSelected = viewModel.selectedItems.first,
              let item = viewModel.items.first(where: { $0.id == firstSelected }),
              item.type == .folder else {
            return
        }
        viewModel.openItem(item, openInNewWindow: true)
    }

    // MARK: - File Operations

    private func showQuickLook() {
        guard !viewModel.selectedItems.isEmpty else { return }

        // Find the index of the first selected item
        guard let firstSelectedId = viewModel.selectedItems.first,
              let startIndex = viewModel.items.firstIndex(where: { $0.id == firstSelectedId }) else {
            return
        }

        // Pass all items so user can navigate with arrow keys
        QuickLookManager.shared.showPreview(for: viewModel.items, startingAt: startIndex)
    }

    private func showNewFolderPrompt() {
        let alert = NSAlert()
        alert.messageText = "New Folder"
        alert.informativeText = "Enter a name for the new folder:"
        alert.alertStyle = .informational

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "Untitled Folder"
        alert.accessoryView = textField

        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let folderName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !folderName.isEmpty {
                viewModel.createNewFolder(named: folderName)
            }
        }
    }
}

// MARK: - Search Results Views

struct SearchResultsGridView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var fileExplorerViewModel: FileExplorerViewModel
    @StateObject private var clipboardManager = ClipboardManager.shared

    private let spacing: CGFloat = 16
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: CGFloat(fileExplorerViewModel.viewMode.iconSize + 40)), spacing: spacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(searchViewModel.searchResults) { item in
                    FileGridItem(item: item, isSelected: false, clipboardManager: clipboardManager, isDimmed: false)
                        .onTapGesture(count: 2) {
                            fileExplorerViewModel.openItem(item)
                            searchViewModel.deactivateSearch()
                        }
                }
            }
            .padding()
        }
    }
}

struct SearchResultsListView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var fileExplorerViewModel: FileExplorerViewModel
    @StateObject private var clipboardManager = ClipboardManager.shared

    var body: some View {
        List(searchViewModel.searchResults) { item in
            FileListRow(item: item, isSelected: false, clipboardManager: clipboardManager, fileExplorerViewModel: fileExplorerViewModel, isDimmed: false)
                .onTapGesture(count: 2) {
                    fileExplorerViewModel.openItem(item)
                    searchViewModel.deactivateSearch()
                }
        }
        .listStyle(.plain)
    }
}
