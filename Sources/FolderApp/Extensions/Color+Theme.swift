//
//  Color+Theme.swift
//  Folder
//
//  Custom theme colors
//

import SwiftUI
import AppKit

extension Color {
    static let folderAccent = Color(hex: "#009880")

    // Adaptive colors for light/dark mode
    static var folderBase: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 40/255, green: 44/255, blue: 52/255, alpha: 1)  // Dark mode
                : NSColor(red: 1, green: 1, blue: 1, alpha: 1)                  // Light mode (white)
        })
    }

    static var folderSidebar: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 30/255, green: 33/255, blue: 39/255, alpha: 1)   // Dark mode
                : NSColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1) // Light mode (light gray)
        })
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension NSColor {
    static let folderAccent = NSColor(red: 0x00 / 255.0, green: 0x98 / 255.0, blue: 0x80 / 255.0, alpha: 1.0)
    static let folderSidebar = NSColor(red: 30/255, green: 33/255, blue: 39/255, alpha: 1.0)
}
