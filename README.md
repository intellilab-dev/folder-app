# Folder - A Better Finder for macOS

**Hey MacBook enthusiast!** Tired of Finder's clunky interface? Folder is your fast, keyboard-driven file browser that actually gets out of your way.

Built with Swift and SwiftUI. Native macOS performance. Zero bloat.

## Why Folder?

- **Keyboard-first navigation** - Arrow keys, shortcuts, instant search
- **Live file updates** - Watch files appear/change in real-time
- **External drive support** - Access USB drives and SD cards from sidebar
- **Clean, focused interface** - One window, dark mode, zero distractions
- **Shortcuts.app integration** - Automate file operations via URL scheme

## Core Features

### 🚀 **Lightning-Fast Navigation**
- **Double-click** to open folders/files
- **Arrow keys** to move between items
- **Back/Forward** navigation with full history
- **Type paths** directly in the address bar
- **Search everywhere** - Cmd+F searches recursively, with drag & drop support

### 📁 **External Drive Support** (NEW)
- **USB drives** appear automatically in sidebar
- **SD cards** and external volumes detected on mount
- **Eject safely** with one click
- No more digging through /Volumes

### 👀 **Dual View Modes**
- **Grid View** - Large icons with file thumbnails
- **List View** - Compact rows with metadata
- **Sort by** Name, Date, Size, or Type
- Real macOS icons with smart caching

### ⭐ **Smart Sidebar**
- **Favorites** - Pin your most-used folders
- **Recent Locations** - Quick access to browsing history
- **External Devices** - USB drives, SD cards at your fingertips
- **Color Tags** - Organize with visual labels
- Drag to reorder everything

### ⚡ **File Operations**
- **Right-click** for context menu (new folder, rename, delete)
- **Copy/Cut/Paste** with system clipboard integration
- **Drag and drop** between Folder, Finder, and other apps
- **Move to trash** safely (Cmd+Delete)
- **Quick Look** preview with spacebar

### ⌨️ **Keyboard Shortcuts**
```
Cmd+F         → Search files (with drag & drop)
Cmd+Shift+N   → Create new folder
Cmd+C/X/V     → Copy/Cut/Paste
Cmd+,         → Settings
Cmd+[/]       → Navigate Back/Forward
Enter         → Open selected item
Delete        → Move to trash
Escape        → Clear selection
Space         → Quick Look preview
```

## Installation

### Quick Install (2 minutes)

```bash
# 1. Clone the repo
git clone https://github.com/intellilab-dev/folder-app.git
cd folder-app

# 2. Build the app
./build.sh

# 3. Install to Applications
cp -R Folder.app /Applications/

# 4. Launch from Spotlight or Dock
open /Applications/Folder.app
```

### Add to Terminal (Optional)

Want to launch Folder from anywhere in your terminal?

```bash
./add-to-path.sh
```

Now type `folder` in any terminal window to launch the app.

### Shortcuts.app Integration

Folder supports URL schemes for automation:

```bash
# Open a specific folder
open "folder://open?path=/Users/$(whoami)/Documents"
```

Perfect for Shortcuts.app workflows!

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Swift 5.9+** (for building from source)

## What's Different from Finder?

| Feature | Finder | Folder |
|---------|--------|--------|
| Keyboard navigation | Limited | Full arrow key support |
| Search results | No drag & drop | Drag & drop enabled |
| External drives | Hidden in sidebar | Auto-detected, one-click eject |
| Window management | Multiple windows | Single focused window |
| Performance | Slow with large folders | Cached icons, instant updates |
| Customization | Limited | Grid size, themes, hide/show sections |

## Settings

Press **Cmd+,** to customize:
- Default view mode (Grid or List)
- Icon size (40-200px)
- Show/hide hidden files
- Toggle sidebar sections
- Theme (Light/Dark/System)

## Troubleshooting

**App won't open?** Remove quarantine:
```bash
xattr -cr /Applications/Folder.app
```

**Build errors?** Clean and rebuild:
```bash
rm -rf .build Folder.app && ./build.sh
```

**Permissions prompts?** Grant file access on first launch. Folder uses security-scoped bookmarks to remember your choices.

## Project Structure

```
FolderApp/
├── Sources/FolderApp/
│   ├── main.swift           # App entry point
│   ├── Models/              # Data structures
│   ├── ViewModels/          # Business logic
│   ├── Views/               # SwiftUI interface
│   └── Services/            # File system, icons, clipboard
├── Package.swift            # Swift Package Manager config
├── build.sh                 # Build script
└── Folder.entitlements      # Permissions
```

## Contributing

Open-source and ready for contributions:
- Report bugs via GitHub Issues
- Submit pull requests
- Request features
- Improve docs

## License

MIT License - Do whatever you want with it.

---

**Built for MacBook enthusiasts who value speed, simplicity, and keyboard shortcuts.**

Repository: https://github.com/intellilab-dev/folder-app
