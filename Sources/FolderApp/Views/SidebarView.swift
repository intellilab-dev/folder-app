//
//  SidebarView.swift
//  Folder
//
//  Sidebar with favorites and recent locations
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var sidebarManager: SidebarManager
    @ObservedObject var fileExplorerViewModel: FileExplorerViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showAllRecent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Favorites Section
            if settingsManager.settings.showFavoritesSection {
                SidebarSection(title: "Favorites") {
                ForEach(sidebarManager.favorites) { favorite in
                    SidebarFavoriteItem(
                        favorite: favorite,
                        isSelected: fileExplorerViewModel.currentPath == favorite.path,
                        sidebarManager: sidebarManager
                    ) {
                        fileExplorerViewModel.navigate(to: favorite.path)
                    }
                    .onDrag {
                        NSItemProvider(object: favorite.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: FavoriteDropDelegate(
                        favorite: favorite,
                        favorites: sidebarManager.favorites,
                        sidebarManager: sidebarManager
                    ))
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDropToFavorites(providers: providers)
            }

                Divider()
                    .padding(.vertical, 8)
            }

            // Recent Locations Section
            if settingsManager.settings.showRecentSection {
                SidebarSection(title: "Recent") {
                let displayedRecent = showAllRecent ? sidebarManager.recentLocations : Array(sidebarManager.recentLocations.prefix(5))

                ForEach(displayedRecent, id: \.self) { location in
                    SidebarItem(
                        icon: "clock.fill",
                        title: location.lastPathComponent,
                        subtitle: location.deletingLastPathComponent().path,
                        isSelected: fileExplorerViewModel.currentPath == location
                    ) {
                        fileExplorerViewModel.navigate(to: location)
                    }
                    .onDrag {
                        NSItemProvider(object: location.path as NSString)
                    }
                    .onDrop(of: [.text], delegate: RecentDropDelegate(
                        location: location,
                        recents: displayedRecent,
                        sidebarManager: sidebarManager
                    ))
                }

                if sidebarManager.recentLocations.count > 5 {
                    Button(action: { showAllRecent.toggle() }) {
                        HStack {
                            Text(showAllRecent ? "Show Less" : "Show More (\(sidebarManager.recentLocations.count - 5))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: showAllRecent ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }

                Divider()
                    .padding(.vertical, 8)
            }

            // Color Tags Section
            if settingsManager.settings.showColorTagsSection {
                SidebarSection(title: "Color Tags") {
                let taggedPaths = Array(sidebarManager.colorTags.keys).sorted { $0.path < $1.path }

                ForEach(taggedPaths, id: \.self) { path in
                    if let colorTag = sidebarManager.getColorTag(for: path) {
                        SidebarColorTagItem(
                            path: path,
                            colorTag: colorTag,
                            isSelected: fileExplorerViewModel.currentPath == path,
                            sidebarManager: sidebarManager
                        ) {
                            fileExplorerViewModel.navigate(to: path)
                        }
                    }
                }
            }
            }

            Spacer()
        }
        .padding(.top, 52)
        .frame(width: 200)
        .background(Color.folderSidebar)
    }

    private func handleDropToFavorites(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: NSURL.self) { object, error in
                guard let url = object as? URL, error == nil else { return }

                Task { @MainActor in
                    sidebarManager.addFavorite(url, name: url.lastPathComponent, icon: "folder.fill")
                }
            }
        }
        return true
    }
}

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            content
        }
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .folderAccent : .secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .primary : .primary)
                        .lineLimit(1)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.folderAccent.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Favorite Item with Color Tag

struct SidebarFavoriteItem: View {
    let favorite: Favorite
    let isSelected: Bool
    @ObservedObject var sidebarManager: SidebarManager
    let action: () -> Void

    var colorTag: ColorTag? {
        sidebarManager.getColorTag(for: favorite.path)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: favorite.icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .folderAccent : .secondary)
                        .frame(width: 16)

                    // macOS-style color tag dot
                    if let colorTag = colorTag {
                        Circle()
                            .fill(Color(hex: colorTag.color.rawValue))
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .stroke(Color.folderSidebar, lineWidth: 0.5)
                            )
                            .offset(x: -3, y: -3)
                    }
                }

                Text(favorite.name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .primary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.folderAccent.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .contextMenu {
            Menu("Change Icon") {
                ForEach(Array(iconOptions.enumerated()), id: \.offset) { index, iconOption in
                    Button(action: {
                        sidebarManager.updateFavoriteIcon(id: favorite.id, icon: iconOption.icon)
                    }) {
                        HStack {
                            Image(systemName: iconOption.icon)
                            Text(iconOption.name)
                        }
                    }
                }
            }

            Divider()

            Menu("Apply Color Tag") {
                ForEach(ColorTag.TagColor.allCases, id: \.self) { color in
                    Button(action: {
                        sidebarManager.setColorTag(for: favorite.path, tag: ColorTag(color: color, name: color.rawValue))
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: color.rawValue))
                                .frame(width: 10, height: 10)
                            Text(colorName(for: color))
                        }
                    }
                }

                Divider()

                if colorTag != nil {
                    Button("Remove Color Tag") {
                        sidebarManager.setColorTag(for: favorite.path, tag: nil)
                    }
                }
            }

            Divider()

            Button("Remove from Favorites", role: .destructive) {
                sidebarManager.removeFavorite(id: favorite.id)
            }
        }
    }

    private let iconOptions: [(name: String, icon: String)] = [
        ("Folder", "folder.fill"),
        ("Home", "house.fill"),
        ("Desktop", "desktopcomputer"),
        ("Documents", "doc.fill"),
        ("Downloads", "arrow.down.circle.fill"),
        ("Pictures", "photo.fill"),
        ("Music", "music.note"),
        ("Movies", "film.fill"),
        ("Star", "star.fill"),
        ("Heart", "heart.fill"),
        ("Bookmark", "bookmark.fill"),
        ("Tag", "tag.fill")
    ]

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

// MARK: - Color Tag Item

struct SidebarColorTagItem: View {
    let path: URL
    let colorTag: ColorTag
    let isSelected: Bool
    @ObservedObject var sidebarManager: SidebarManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .folderAccent : .secondary)
                        .frame(width: 16)

                    // macOS-style color tag dot
                    Circle()
                        .fill(Color(hex: colorTag.color.rawValue))
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.folderSidebar, lineWidth: 0.5)
                        )
                        .offset(x: -3, y: -3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(path.lastPathComponent)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .primary : .primary)
                        .lineLimit(1)

                    Text(path.deletingLastPathComponent().path)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.folderAccent.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") {
                action()
            }

            Divider()

            Menu("Apply Color Tag") {
                ForEach(ColorTag.TagColor.allCases, id: \.self) { color in
                    Button(action: {
                        sidebarManager.setColorTag(for: path, tag: ColorTag(color: color, name: color.rawValue))
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: color.rawValue))
                                .frame(width: 10, height: 10)
                            Text(colorName(for: color))
                        }
                    }
                }

                Divider()

                Button("Remove Color Tag") {
                    sidebarManager.setColorTag(for: path, tag: nil)
                }
            }
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

// MARK: - Drop Delegate for Reordering

struct FavoriteDropDelegate: DropDelegate {
    let favorite: Favorite
    let favorites: [Favorite]
    let sidebarManager: SidebarManager

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedID = info.itemProviders(for: [.text]).first else { return }

        _ = draggedID.loadObject(ofClass: NSString.self) { object, error in
            guard let idString = object as? String,
                  let draggedUUID = UUID(uuidString: idString),
                  let fromIndex = favorites.firstIndex(where: { $0.id == draggedUUID }),
                  let toIndex = favorites.firstIndex(where: { $0.id == favorite.id }),
                  fromIndex != toIndex else { return }

            Task { @MainActor in
                sidebarManager.reorderFavorites(from: fromIndex, to: toIndex)
            }
        }
    }
}

struct RecentDropDelegate: DropDelegate {
    let location: URL
    let recents: [URL]
    let sidebarManager: SidebarManager

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedPath = info.itemProviders(for: [.text]).first else { return }

        _ = draggedPath.loadObject(ofClass: NSString.self) { [sidebarManager] object, error in
            guard let pathString = object as? String else { return }

            Task { @MainActor in
                guard let fromIndex = sidebarManager.recentLocations.firstIndex(where: { $0.path == pathString }),
                      let toIndex = sidebarManager.recentLocations.firstIndex(where: { $0 == location }),
                      fromIndex != toIndex else { return }

                sidebarManager.reorderRecents(from: fromIndex, to: toIndex)
            }
        }
    }
}
