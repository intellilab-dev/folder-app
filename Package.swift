// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FolderApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Folder",
            targets: ["FolderApp"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed later
        // e.g., Sparkle for auto-updates
    ],
    targets: [
        .executableTarget(
            name: "FolderApp",
            dependencies: [],
            path: "Sources/FolderApp",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
