# Folder - Minimalist macOS File Explorer

A fast, native macOS file browser built with Swift and SwiftUI. A modern alternative to Finder with live file updates, keyboard shortcuts, and a clean dark interface.

## Features

### Navigation
- Double-click folders/files to open them
- Single-click to select items
- **Shift-click** to select a range of files
- **Cmd-click** to select multiple individual files
- Back/Forward navigation with history
- Editable address bar - type paths directly
- Up button to go to parent folder

### Views & Display
- **Grid View**: Large file icons with thumbnails
- **List View**: Compact view with file details
- **Sorting**: Sort by Name, Date, Size, or Type
- Real macOS file icons with caching
- Live file system updates - new files appear instantly
- Show/hide hidden files toggle

### Sidebar
- **Favorites**: Pin folders for quick access
- **Recent Locations**: Track recently visited folders
- **Color Tags**: Organize folders with visual tags
- Drag to reorder items
- Toggle sections on/off in settings

### File Operations
- **Right-click context menu**: Create new folders, rename, delete
- Copy/Cut/Paste with system clipboard
- Drag and drop support
- Move to trash
- Add folders to favorites

### Keyboard Shortcuts
- **Cmd+Shift+N**: Create new folder
- **Cmd+C/X/V**: Copy/Cut/Paste
- **Cmd+F**: Search files
- **Cmd+,**: Open settings
- **Cmd+Sidebar**: Toggle sidebar
- **Arrow Keys**: Navigate between items
- **Enter**: Open selected item
- **Delete**: Move to trash
- **Escape**: Clear selection
- **Ctrl+Left**: Go to parent folder
- **Ctrl+Right**: Open selected folder

## Installation

### Quick Install (Recommended)

1. **Download or clone** this repository
2. **Build the app**:
   ```bash
   ./build.sh
   ```
3. **Install system-wide**:
   ```bash
   cp -R Folder.app /Applications/
   ```
4. **Launch** from Applications folder or Spotlight

### Install to Terminal (Optional)

To launch Folder from the command line:

```bash
./install-to-path.sh
```

Now you can run `folder` from any terminal to launch the app.

### Manual Build

If you prefer to build manually:

```bash
# Build with Swift Package Manager
swift build -c release

# Create app bundle
mkdir -p Folder.app/Contents/MacOS
mkdir -p Folder.app/Contents/Resources
cp .build/release/Folder Folder.app/Contents/MacOS/
cp Resources/AppIcon.icns Folder.app/Contents/Resources/

# Code sign
codesign --force --sign - --entitlements Folder.entitlements --deep Folder.app

# Install
cp -R Folder.app /Applications/
```

## Usage

### Getting Started

1. **Launch** Folder from Applications
2. **Browse** your files by clicking folders
3. **Select files** with single-click, shift-click for ranges, cmd-click for multiple
4. **Right-click** anywhere to create a new folder
5. **Drag folders** to favorites in the sidebar
6. **Sort** files using the toolbar buttons

### Settings

Press **Cmd+,** to open settings:
- Default view mode (Grid/List)
- Icon size for grid view
- Show/hide hidden files
- Toggle sidebar sections (Favorites, Recent, Color Tags)
- Theme selection (Light/Dark/System)

### URL Scheme

Folder supports the `folder://` URL scheme:

```bash
# Open a specific folder
open "folder://open?path=/Users/username/Documents"
```

## Requirements

- macOS 13.0 or later
- Swift 6.2.1 or later (for building)

## Building from Source

### Prerequisites

- Xcode Command Line Tools: `xcode-select --install`
- Swift Package Manager (included with Xcode CLT)

### Build Commands

```bash
# Build release version
./build.sh

# Run the app
./run.sh

# Clean build artifacts
rm -rf .build Folder.app

# Rebuild from scratch
rm -rf .build Folder.app && ./build.sh
```

## Project Structure

```
FolderApp/
├── Package.swift              # Swift Package Manager manifest
├── build.sh                   # Build script
├── Folder.entitlements        # App permissions
├── Sources/FolderApp/
│   ├── main.swift            # App entry point
│   ├── Models/               # Data models
│   ├── ViewModels/           # Business logic
│   ├── Views/                # SwiftUI views
│   └── Services/             # File system & utilities
└── Resources/                # App icon and assets
```

## Troubleshooting

### Permission Prompts

On first launch, macOS may ask for file access permissions. Grant these to allow Folder to browse your files. The app uses security-scoped bookmarks to remember permissions.

### App Won't Open

If macOS blocks the app with "unidentified developer" warning:

```bash
# Remove quarantine attribute
xattr -cr /Applications/Folder.app

# Or add to allowed apps
spctl --add /Applications/Folder.app
```

### Build Errors

If you encounter build errors:

```bash
# Clean and rebuild
rm -rf .build Folder.app
./build.sh
```

## Contributing

This is an open-source project. Feel free to:
- Report bugs via GitHub Issues
- Submit pull requests
- Suggest new features
- Improve documentation

## License

MIT License - See LICENSE file for details

## Credits

Built with Swift and SwiftUI
Designed for macOS 13.0+

---

**Repository**: https://github.com/intellilab-dev/folder-app
