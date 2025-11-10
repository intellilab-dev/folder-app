//
//  Favorite.swift
//  Folder
//
//  Model for favorite/bookmarked locations
//

import Foundation

struct Favorite: Identifiable, Codable, Equatable {
    let id: UUID
    let path: URL
    let name: String
    let icon: String
    let order: Int

    init(id: UUID = UUID(), path: URL, name: String, icon: String = "folder.fill", order: Int = 0) {
        self.id = id
        self.path = path
        self.name = name
        self.icon = icon
        self.order = order
    }
}

struct ColorTag: Codable, Equatable, Hashable {
    let color: TagColor
    let name: String

    enum TagColor: String, Codable, CaseIterable {
        case red = "#FF3B30"
        case orange = "#FF9500"
        case yellow = "#FFCC00"
        case green = "#34C759"
        case teal = "#009880"
        case blue = "#007AFF"
        case purple = "#AF52DE"
        case pink = "#FF2D55"
        case gray = "#8E8E93"

        var displayName: String {
            switch self {
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
}

@MainActor
class SidebarManager: ObservableObject {
    static let shared = SidebarManager()

    @Published var favorites: [Favorite] = []
    @Published var recentLocations: [URL] = []
    @Published var colorTags: [URL: ColorTag] = [:] // path -> tag mapping

    private let favoritesKey = "favorites"
    private let recentLocationsKey = "recentLocations"
    private let colorTagsKey = "colorTags"
    private let maxRecentLocations = 10

    private init() {
        loadFavorites()
        loadRecentLocations()
        loadColorTags()

        // Add default favorites if empty
        if favorites.isEmpty {
            addDefaultFavorites()
        }
    }

    // MARK: - Favorites

    func addFavorite(_ path: URL, name: String? = nil, icon: String = "folder.fill") {
        let favoriteName = name ?? path.lastPathComponent
        let favorite = Favorite(
            path: path,
            name: favoriteName,
            icon: icon,
            order: favorites.count
        )
        favorites.append(favorite)
        saveFavorites()
    }

    func removeFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }

    func reorderFavorites(from: Int, to: Int) {
        guard from != to,
              from >= 0, from < favorites.count,
              to >= 0, to < favorites.count else { return }

        let item = favorites.remove(at: from)
        favorites.insert(item, at: to)

        // Recreate favorites with updated order values
        favorites = favorites.enumerated().map { index, favorite in
            Favorite(id: favorite.id, path: favorite.path, name: favorite.name, icon: favorite.icon, order: index)
        }

        saveFavorites()
    }

    func updateFavoriteIcon(id: UUID, icon: String) {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else { return }
        let favorite = favorites[index]
        favorites[index] = Favorite(id: favorite.id, path: favorite.path, name: favorite.name, icon: icon, order: favorite.order)
        saveFavorites()
    }

    func isFavorite(_ path: URL) -> Bool {
        return favorites.contains { $0.path == path }
    }

    // MARK: - Recent Locations

    func addRecentLocation(_ path: URL) {
        // Remove if already exists
        recentLocations.removeAll { $0 == path }

        // Add to beginning
        recentLocations.insert(path, at: 0)

        // Limit to max
        if recentLocations.count > maxRecentLocations {
            recentLocations = Array(recentLocations.prefix(maxRecentLocations))
        }

        saveRecentLocations()
    }

    func reorderRecents(from: Int, to: Int) {
        guard from != to,
              from >= 0, from < recentLocations.count,
              to >= 0, to < recentLocations.count else { return }

        let item = recentLocations.remove(at: from)
        recentLocations.insert(item, at: to)

        saveRecentLocations()
    }

    // MARK: - Color Tags

    func setColorTag(for path: URL, tag: ColorTag?) {
        if let tag = tag {
            colorTags[path] = tag
        } else {
            colorTags.removeValue(forKey: path)
        }
        saveColorTags()
    }

    func getColorTag(for path: URL) -> ColorTag? {
        return colorTags[path]
    }

    // MARK: - Persistence

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let decoded = try? JSONDecoder().decode([Favorite].self, from: data) else {
            return
        }
        favorites = decoded
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }

    private func loadRecentLocations() {
        guard let data = UserDefaults.standard.data(forKey: recentLocationsKey),
              let decoded = try? JSONDecoder().decode([URL].self, from: data) else {
            return
        }
        recentLocations = decoded
    }

    private func saveRecentLocations() {
        if let encoded = try? JSONEncoder().encode(recentLocations) {
            UserDefaults.standard.set(encoded, forKey: recentLocationsKey)
        }
    }

    private func loadColorTags() {
        guard let data = UserDefaults.standard.data(forKey: colorTagsKey),
              let decoded = try? JSONDecoder().decode([URL: ColorTag].self, from: data) else {
            return
        }
        colorTags = decoded
    }

    private func saveColorTags() {
        if let encoded = try? JSONEncoder().encode(colorTags) {
            UserDefaults.standard.set(encoded, forKey: colorTagsKey)
        }
    }

    private func addDefaultFavorites() {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser

        // Home
        addFavorite(homeURL, name: "Home", icon: "house.fill")

        // Desktop
        let desktopURL = homeURL.appendingPathComponent("Desktop")
        if fileManager.fileExists(atPath: desktopURL.path) {
            addFavorite(desktopURL, name: "Desktop", icon: "desktopcomputer")
        }

        // Documents
        let documentsURL = homeURL.appendingPathComponent("Documents")
        if fileManager.fileExists(atPath: documentsURL.path) {
            addFavorite(documentsURL, name: "Documents", icon: "doc.fill")
        }

        // Downloads
        let downloadsURL = homeURL.appendingPathComponent("Downloads")
        if fileManager.fileExists(atPath: downloadsURL.path) {
            addFavorite(downloadsURL, name: "Downloads", icon: "arrow.down.circle.fill")
        }
    }
}
