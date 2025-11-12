//
//  FileListView.swift
//  Folder
//
//  List view for files and folders
//

import SwiftUI
import AppKit

struct FileListView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @StateObject private var clipboardManager = ClipboardManager.shared
    let showDimmed: Bool

    var body: some View {
        VStack(spacing: 0) {
            SortingToolbar(viewModel: viewModel)

            List(viewModel.items) { item in
            FileListRow(item: item, isSelected: viewModel.isSelected(item), clipboardManager: clipboardManager, fileExplorerViewModel: viewModel, isDimmed: showDimmed)
                .onTapGesture(count: 2) {
                    handleDoubleClick(item)
                }
                .onTapGesture {
                    handleSingleClick(item)
                }
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
        .listStyle(.plain)
        }
    }

    private func handleSingleClick(_ item: FileSystemItem) {
        // Single click: select item
        let modifierFlags = NSEvent.modifierFlags
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

struct FileListRow: View {
    let item: FileSystemItem
    let isSelected: Bool
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var fileExplorerViewModel: FileExplorerViewModel
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
        HStack(spacing: 12) {
            // Icon or Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let thumbnail = thumbnail {
                    // Show thumbnail preview
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                } else {
                    // Show regular icon
                    iconService.swiftUIIcon(for: item, size: 20)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }

                // Symlink badge
                if item.isSymlink {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 8))
                        .foregroundColor(.folderAccent)
                }

                // Color tag badge
                if let colorTag = colorTag {
                    Circle()
                        .fill(Color(hex: colorTag.color.rawValue))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1)
                        )
                        .offset(x: 2, y: -2)
                }
            }

            // Name
            Text(item.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Modified date
            Text(item.modifiedAt, style: .date)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)

            // Size
            if item.type == .file {
                Text(formatFileSize(item.size))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)
            } else if item.type == .folder {
                // Show folder size if calculated
                if let folderSize = fileExplorerViewModel.folderSizes[item.path] {
                    Text(formatFileSize(folderSize))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                } else {
                    Text("...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
            } else {
                Text("--")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.folderAccent.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .opacity(opacity)
        .task {
            // Load thumbnail for images and PDFs
            if thumbnailService.supportsThumbnail(for: item.path.path) {
                thumbnail = await thumbnailService.getThumbnail(for: item.path.path, size: CGSize(width: 40, height: 40))
            }
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
