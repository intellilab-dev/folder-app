//
//  ViewMode.swift
//  Folder
//
//  View mode preferences (grid vs list, sorting)
//

import Foundation

struct ViewMode: Identifiable, Codable {
    let id: UUID
    var mode: DisplayMode
    var iconSize: Int  // pixels, default 64
    var sortBy: SortOption
    var sortOrder: SortOrder

    enum DisplayMode: String, Codable {
        case iconGrid
        case list
    }

    enum SortOption: String, Codable {
        case name
        case dateModified
        case size
        case type
    }

    enum SortOrder: String, Codable {
        case ascending
        case descending
    }

    // Default view mode
    static let `default` = ViewMode(
        id: UUID(),
        mode: .iconGrid,
        iconSize: 64,
        sortBy: .dateModified,
        sortOrder: .descending
    )
}
