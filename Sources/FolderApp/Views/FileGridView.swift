//
//  FileGridView.swift
//  Folder
//
//  Grid view for files and folders
//

import SwiftUI
import AppKit

struct FileGridView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @StateObject private var clipboardManager = ClipboardManager.shared
    let showDimmed: Bool

    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var lastClickedItem: UUID?
    @State private var lastClickTime: Date?
    @FocusState private var renamingFocusedID: UUID?

    private let spacing: CGFloat = 16
    private let clickPauseInterval: TimeInterval = 0.5 // Time window for click-pause-click
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: CGFloat(viewModel.viewMode.iconSize + 40)), spacing: spacing)]
    }

    var body: some View {
        VStack(spacing: 0) {
            SortingToolbar(viewModel: viewModel)

            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(viewModel.items) { item in
                        FileGridItemWithRename(
                            item: item,
                            isSelected: viewModel.isSelected(item),
                            isRenaming: viewModel.renamingItem == item.id,
                            clipboardManager: clipboardManager,
                            isDimmed: showDimmed,
                            viewModel: viewModel,
                            onSingleClick: { handleSingleClick(item) },
                            onDoubleClick: { handleDoubleClick(item) },
                            renamingFocusedID: $renamingFocusedID
                        )
                        .onDrag {
                            NSItemProvider(object: item.path as NSURL)
                        }
                        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                            handleDrop(providers: providers, destination: item)
                        }
                        .contextMenu {
                            FileContextMenu(item: item, viewModel: viewModel, clipboardManager: clipboardManager)
                        }
                    }
                }
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss rename mode when clicking empty space
                    renamingFocusedID = nil
                    viewModel.commitRename()
                }
                .contextMenu {
                    Button("New Folder") {
                        viewModel.createNewFolder(named: "Untitled Folder", autoRename: true)
                    }

                    Divider()

                    Button("Paste") {
                        Task {
                            do {
                                _ = try await clipboardManager.paste(to: viewModel.currentPath)
                                viewModel.refresh()
                            } catch {
                                print("Paste failed: \(error)")
                            }
                        }
                    }
                    .disabled(!clipboardManager.hasClipboardContent())
                }
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button("New Folder") {
                    viewModel.createNewFolder(named: "Untitled Folder", autoRename: true)
                }

                Divider()

                Button("Paste") {
                    Task {
                        do {
                            _ = try await clipboardManager.paste(to: viewModel.currentPath)
                            viewModel.refresh()
                        } catch {
                            print("Paste failed: \(error)")
                        }
                    }
                }
                .disabled(!clipboardManager.hasClipboardContent())
            }
        }
    }

    private func handleSingleClick(_ item: FileSystemItem) {
        let modifierFlags = NSEvent.modifierFlags
        let now = Date()

        // Check for Finder-style click-pause-click rename pattern
        if !modifierFlags.contains(.shift) && !modifierFlags.contains(.command),
           lastClickedItem == item.id,
           let lastTime = lastClickTime,
           now.timeIntervalSince(lastTime) >= clickPauseInterval && now.timeIntervalSince(lastTime) <= 2.0,
           viewModel.isSelected(item) {
            // Second click on same item after pause - enter rename mode
            viewModel.startRenaming(item)
            renamingFocusedID = item.id
            lastClickedItem = nil
            lastClickTime = nil
            return
        }

        // Dismiss any active rename mode when clicking a different item
        if viewModel.renamingItem != nil && viewModel.renamingItem != item.id {
            renamingFocusedID = nil
            viewModel.commitRename()
        }

        // Handle selection
        if modifierFlags.contains(.shift) {
            // Shift+Click: range selection
            if let lastSelected = viewModel.lastSelectedItem,
               let lastItem = viewModel.items.first(where: { $0.id == lastSelected }) {
                viewModel.selectRange(from: lastItem, to: item)
            } else {
                viewModel.toggleSelection(for: item)
            }
        } else if modifierFlags.contains(.command) {
            // Cmd+Click: toggle selection (add/remove from selection)
            viewModel.toggleSelection(for: item)
        } else {
            // Regular click: select only this item
            viewModel.clearSelection()
            viewModel.toggleSelection(for: item)
        }

        // Track click for rename detection
        lastClickedItem = item.id
        lastClickTime = now
    }

    private func handleDoubleClick(_ item: FileSystemItem) {
        // Double click: open item
        viewModel.openItem(item)
    }

    private func handleDrop(providers: [NSItemProvider], destination: FileSystemItem) -> Bool {
        // Only allow drops on folders
        guard destination.type == .folder else { return false }

        for provider in providers {
            _ = provider.loadObject(ofClass: NSURL.self) { [weak viewModel] object, error in
                guard let url = object as? URL, error == nil else {
                    if let error = error {
                        print("Failed to load dropped item: \(error.localizedDescription)")
                    }
                    return
                }

                let destinationURL = destination.path.appendingPathComponent(url.lastPathComponent)

                // Don't move if source and destination are the same
                guard url != destinationURL else { return }

                // Check if destination already exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at destination")
                    return
                }

                do {
                    try FileManager.default.moveItem(at: url, to: destinationURL)
                    print("Moved \(url.lastPathComponent) to \(destination.name)")

                    Task { @MainActor in
                        viewModel?.refresh()
                    }
                } catch {
                    print("Failed to move item: \(error.localizedDescription)")
                }
            }
        }

        return true
    }

}

// MARK: - File Grid Item with Rename Support

struct FileGridItemWithRename: View {
    let item: FileSystemItem
    let isSelected: Bool
    let isRenaming: Bool
    let clipboardManager: ClipboardManager
    let isDimmed: Bool
    @ObservedObject var viewModel: FileExplorerViewModel
    let onSingleClick: () -> Void
    let onDoubleClick: () -> Void
    @FocusState.Binding var renamingFocusedID: UUID?
    @StateObject private var iconService = IconService.shared

    var body: some View {
        if isRenaming {
            // Rename mode
            VStack(spacing: 8) {
                iconService.swiftUIIcon(for: item, size: CGFloat(viewModel.viewMode.iconSize))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: CGFloat(viewModel.viewMode.iconSize), height: CGFloat(viewModel.viewMode.iconSize))
                    .opacity(isDimmed && clipboardManager.clipboardItems.contains(where: { $0.id == item.id }) ? 0.5 : 1.0)

                TextField("", text: $viewModel.renameText, onCommit: {
                    viewModel.commitRename()
                })
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .frame(width: CGFloat(viewModel.viewMode.iconSize + 40))
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
                .focused($renamingFocusedID, equals: item.id)
                .onExitCommand {
                    viewModel.cancelRename()
                    renamingFocusedID = nil
                }
                .onAppear {
                    renamingFocusedID = item.id
                }
            }
            .padding(8)
            .background(isSelected ? Color.folderAccent.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.folderAccent, lineWidth: isSelected ? 2 : 0)
            )
        } else {
            // Normal display mode
            FileGridItem(item: item, isSelected: isSelected, clipboardManager: clipboardManager, isDimmed: isDimmed)
                .onTapGesture(count: 2) {
                    onDoubleClick()
                }
                .onTapGesture {
                    onSingleClick()
                }
        }
    }
}

struct FileGridItem: View {
    let item: FileSystemItem
    let isSelected: Bool
    @ObservedObject var clipboardManager: ClipboardManager
    let isDimmed: Bool
    @StateObject private var iconService = IconService.shared
    @StateObject private var sidebarManager = SidebarManager.shared
    @StateObject private var thumbnailService = ThumbnailService.shared
    @State private var thumbnail: NSImage?

    private var isCut: Bool {
        clipboardManager.clipboardAction == .cut &&
        clipboardManager.clipboardItems.contains(where: { $0.path == item.path })
    }

    private var colorTag: ColorTag? {
        sidebarManager.getColorTag(for: item.path)
    }

    private var opacity: Double {
        if isDimmed {
            return 0.3
        } else if isCut {
            return 0.5
        } else {
            return 1.0
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Icon or Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let thumbnail = thumbnail {
                    // Show thumbnail preview
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    // Show regular icon
                    iconService.swiftUIIcon(for: item, size: 64)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                }

                // Symlink badge
                if item.isSymlink {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 16))
                        .foregroundColor(.folderAccent)
                        .padding(2)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .clipShape(Circle())
                }

                // Color tag badge
                if let colorTag = colorTag {
                    Circle()
                        .fill(Color(hex: colorTag.color.rawValue))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5)
                        )
                        .offset(x: 4, y: -4)
                }
            }

            // Name
            Text(item.name)
                .font(.system(size: 12))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
                .truncationMode(.middle)
        }
        .padding(8)
        .background(isSelected ? Color.folderAccent.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.folderAccent : Color.clear, lineWidth: 2)
        )
        .opacity(opacity)
        .task {
            // Load thumbnail for images and PDFs
            if thumbnailService.supportsThumbnail(for: item.path.path) {
                thumbnail = await thumbnailService.getThumbnail(for: item.path.path, size: CGSize(width: 128, height: 128))
            }
        }
    }
}

// MARK: - File Context Menu

struct FileContextMenu: View {
    let item: FileSystemItem
    @ObservedObject var viewModel: FileExplorerViewModel
    @ObservedObject var clipboardManager: ClipboardManager
    @StateObject private var sidebarManager = SidebarManager.shared
    @State private var showingRenameAlert = false
    @State private var newName = ""

    var body: some View {
        Button("Open") {
            viewModel.openItem(item)
        }

        Divider()

        Button("Copy") {
            clipboardManager.copy(items: [item])
        }

        Button("Cut") {
            clipboardManager.cut(items: [item])
        }

        Divider()

        Button("Move to Trash") {
            moveToTrash()
        }

        Button("Rename...") {
            newName = item.name
            showingRenameAlert = true
        }

        Divider()

        Button("Add to Favorites") {
            sidebarManager.addFavorite(item.path, name: item.name, icon: item.type == .folder ? "folder.fill" : "doc.fill")
        }

        Menu("Apply Color Tag") {
            ForEach(ColorTag.TagColor.allCases, id: \.self) { color in
                Button(action: {
                    sidebarManager.setColorTag(for: item.path, tag: ColorTag(color: color, name: color.rawValue))
                }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: color.rawValue))
                            .frame(width: 12, height: 12)
                        Text(colorName(for: color))
                    }
                }
            }

            Divider()

            Button("Remove Color Tag") {
                sidebarManager.setColorTag(for: item.path, tag: nil)
            }
        }
        .background(
            EmptyView()
                .alert("Rename", isPresented: $showingRenameAlert) {
                    TextField("New Name", text: $newName)
                    Button("Rename") {
                        if !newName.isEmpty {
                            viewModel.renameItem(item, to: newName)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
        )
    }

    private func moveToTrash() {
        do {
            try FileManager.default.trashItem(at: item.path, resultingItemURL: nil)
            viewModel.refresh()
        } catch {
            print("Failed to move to trash: \(error.localizedDescription)")
        }
    }

    private func colorName(for color: ColorTag.TagColor) -> String {
        switch color {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .teal: return "Teal"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .gray: return "Gray"
        }
    }
}
