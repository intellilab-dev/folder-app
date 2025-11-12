//
//  NavigationBar.swift
//  Folder
//
//  Address bar and navigation controls
//

import SwiftUI
import AppKit

// Custom button style that removes ALL macOS styling
struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct NavigationBar: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var editingPath: String = ""
    @State private var isEditingPath = false
    @FocusState private var isPathFieldFocused: Bool
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Sidebar toggle button
            Button(action: {
                settingsManager.settings.showSidebar.toggle()
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(NoButtonStyle())
            .focusable(false)
            .help(settingsManager.settings.showSidebar ? "Hide Sidebar" : "Show Sidebar")

            Divider()
                .frame(height: 20)

            // Back button
            Button(action: { viewModel.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.canGoBack)

            // Forward button
            Button(action: { viewModel.navigateForward() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.canGoForward)

            // Up/Parent button
            Button(action: { viewModel.navigateToParent() }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.borderless)

            Divider()
                .frame(height: 20)

            // Address bar / Search bar
            HStack {
                // Search icon - clickable to activate search
                Button(action: {
                    if !searchViewModel.isSearchActive {
                        searchViewModel.activateSearch()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(searchViewModel.isSearchActive ? Color.folderAccent : .secondary)
                }
                .buttonStyle(.borderless)
                .help("Search (Cmd+F)")

                if searchViewModel.isSearchActive {
                    // Search mode
                    TextField("Search in current folder...", text: $searchViewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isSearchFieldFocused)
                        .onChange(of: searchViewModel.searchQuery) { _ in
                            searchViewModel.search(in: viewModel.currentPath)
                        }
                        .onExitCommand {
                            // Escape to exit search
                            searchViewModel.deactivateSearch()
                        }

                    if searchViewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    if !searchViewModel.searchQuery.isEmpty {
                        Button(action: { searchViewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else if isEditingPath {
                    // Path editing mode
                    TextField("Path", text: $editingPath)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isPathFieldFocused)
                        .onSubmit {
                            navigateToPath()
                        }
                        .onExitCommand {
                            // Cancel editing on Escape key
                            editingPath = viewModel.currentPath.path
                            isEditingPath = false
                            isPathFieldFocused = false
                        }
                } else {
                    // Normal address bar display
                    Text(viewModel.currentPath.path)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startEditing()
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.folderSidebar)
            .cornerRadius(6)
            .onChange(of: isEditingPath) { newValue in
                if newValue {
                    // Focus the text field when entering edit mode
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                        isPathFieldFocused = true
                    }
                }
            }
            .onChange(of: searchViewModel.isSearchActive) { isActive in
                if isActive {
                    // Focus search field when activating search
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                        isSearchFieldFocused = true
                    }
                }
            }

            Divider()
                .frame(height: 20)

            // View mode toggle (shows target state, not current state)
            Button(action: { viewModel.toggleViewMode() }) {
                Image(systemName: viewModel.viewMode.mode == .iconGrid ? "list.bullet" : "square.grid.2x2")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .help("Toggle view mode")

            // Refresh button
            Button(action: { viewModel.refresh() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .frame(height: 44)
        .onChange(of: viewModel.currentPath) { newPath in
            // Reset editing state when path changes externally
            if isEditingPath {
                isEditingPath = false
                isPathFieldFocused = false
            }
            editingPath = newPath.path
        }
    }

    private func startEditing() {
        editingPath = viewModel.currentPath.path
        isEditingPath = true
        // Clear selection to prevent conflicts with Enter key
        viewModel.clearSelection()
    }

    private func navigateToPath() {
        // Trim whitespace
        let trimmedPath = editingPath.trimmingCharacters(in: .whitespacesAndNewlines)

        // Exit editing mode first
        isEditingPath = false
        isPathFieldFocused = false

        // Don't navigate if empty or unchanged
        guard !trimmedPath.isEmpty, trimmedPath != viewModel.currentPath.path else {
            return
        }

        // Resolve URL
        guard let url = FileSystemService.shared.resolveURL(from: trimmedPath) else {
            // Invalid path - show error or just reset
            editingPath = viewModel.currentPath.path
            return
        }

        // Navigate to the resolved URL
        viewModel.navigate(to: url)
    }
}
