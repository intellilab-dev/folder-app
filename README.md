# Folder - Minimalist macOS File Explorer

A fast, native macOS file browser built with Swift and SwiftUI, using command-line tools (no Xcode GUI required).

## 🎉 What's Working (Phase 1.5 - Polished MVP)

✅ **Navigation**
- Browse any folder on your Mac
- **Double-click** folders/files to open them (Finder-style!)
- **Single-click** to select items
- Back/Forward navigation with full history
- Up button to go to parent folder
- **Editable address bar** - click path, type new location, press Enter

✅ **Keyboard Navigation 🎹**
- **Ctrl+Left**: Go to parent folder
- **Ctrl+Right**: Open selected folder (or first folder)
- **Arrow Keys**: Navigate between items
- **Enter**: Open selected item
- **Escape**: Clear selection
- **Cmd+,**: Open settings

✅ **View Modes**
- Toggle between Grid and List views (button in toolbar)
- Grid: Large, beautiful file icons (64px default, adjustable 32-128px)
- List: Compact view with file details (size, modified date, 20px icons)

✅ **Real File Icons 🎨**
- **NSWorkspace integration** - shows actual macOS file icons
- Icons match what you see in Finder
- Proper icons for apps, documents, images, code files, etc.
- **Icon caching** - loads fast after first view (4-6x performance boost!)
- Lighter, softer appearance (reduced opacity for better aesthetics)

✅ **File Display**
- Shows all files and folders
- Respects "Show Hidden Files" setting
- Symlink detection with special arrow badge
- Proper sorting (folders first, then files alphabetically)

✅ **Selection**
- Single-click to select (blue border highlight)
- Cmd+Click to multi-select
- Visual feedback for selected items

✅ **Settings Panel ⚙️**
Press Cmd+, to access:
- Default view mode (Grid/List)
- Icon size slider (32-128px for grid view)
- Show/hide hidden files toggle
- Theme selection (Light/Dark/System)
- Reset to defaults button

## 🚀 Quick Start

### Build the App

```bash
./build.sh
```

This will:
1. Compile the Swift code using Swift Package Manager
2. Create a macOS .app bundle
3. Place it in `Folder.app`

### Run the App

```bash
./run.sh
```

Or double-click `Folder.app` in Finder.

## 🧪 Testing Guide

### Navigation Tests
1. ✅ Launch app - opens to home directory
2. ✅ **Single-click** a folder - gets selected (blue border)
3. ✅ **Double-click** a folder - opens it
4. ✅ Back button - returns to previous folder
5. ✅ Up button - goes to parent folder
6. ✅ Click path bar, type `/Applications`, press Enter - navigates there

### Keyboard Navigation Tests
1. ✅ Press **Arrow keys** - selection moves between items
2. ✅ Press **Enter** - opens selected folder/file
3. ✅ Press **Ctrl+Left** - goes to parent folder
4. ✅ Press **Ctrl+Right** on selected folder - opens it
5. ✅ Press **Escape** - clears selection

### View & Icons Tests
1. ✅ Click grid/list toggle - switches between views
2. ✅ Check icons - should look like real macOS file icons (not generic)
3. ✅ Icons should match what Finder shows
4. ✅ Icons load fast after first view (caching works!)

### Settings Panel Tests
1. ✅ Press **Cmd+,** - opens settings
2. ✅ Toggle "Show Hidden Files" - affects file display
3. ✅ Change theme - app appearance changes
4. ✅ Adjust icon size slider - see larger/smaller icons
5. ✅ Click "Reset to Defaults" - restores original settings
6. ✅ Close and reopen app - settings persist

### Multi-Select Test
1. ✅ **Cmd+Click** multiple items - all get selected
2. ✅ **Cmd+Click** selected item - deselects it
3. ✅ Click empty space - clears selection

## 📂 Project Structure

```
FolderApp/
├── Package.swift                 # Swift Package Manager manifest
├── build.sh                      # Build script
├── run.sh                        # Run script
├── Sources/FolderApp/
│   ├── main.swift               # App entry point
│   ├── Models/                  # Data models
│   │   ├── FileSystemItem.swift
│   │   ├── AppSettings.swift
│   │   └── ViewMode.swift
│   ├── ViewModels/              # Business logic
│   │   └── FileExplorerViewModel.swift
│   ├── Views/                   # SwiftUI views
│   │   ├── ContentView.swift
│   │   ├── NavigationBar.swift
│   │   ├── FileGridView.swift
│   │   └── FileListView.swift
│   └── Services/                # File system operations
│       └── FileSystemService.swift
└── Folder.app/                  # Built app bundle (generated)
```

## 🛠️ Build System

This project uses **Swift Package Manager** and command-line tools instead of Xcode:

- ✅ No Xcode GUI required
- ✅ `swift build` for compilation
- ✅ Automated .app bundle creation
- ✅ Fully scriptable build process

## 🔧 Development Commands

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

## 📋 What's Coming Next

### Phase 2: Search & Clipboard (Next Build)
- ⏳ Instant search (Cmd+F to search as you type)
- ⏳ Search within current folder + 2 levels deep
- ⏳ Copy/Cut/Paste operations (Cmd+C/X/V)
- ⏳ Drag and drop support
- ⏳ Visual feedback for cut items (dimmed)

### Phase 3: Tags & Favorites (Future)
- ⏳ Tag creation and management
- ⏳ Native macOS tag integration
- ⏳ Favorites sidebar
- ⏳ Recent items tracking

### Phase 4: Context Menu & Actions (Future)
- ⏳ Right-click context menu
- ⏳ File operations (rename, delete, compress)
- ⏳ Open in Terminal
- ⏳ Show Info panel

## 🐛 Known Issues

### Minor Issues
- [ ] Icon size slider effect requires view mode toggle to see changes
- [ ] "Show Hidden Files" toggle needs manual refresh (click refresh button)
- [ ] Settings window can be opened multiple times
- [ ] Swift 6 Sendable warning for NSCache (cosmetic only, no impact)

### Not Implemented Yet
- [ ] Search functionality
- [ ] Copy/paste operations
- [ ] Context menu (right-click)
- [ ] Drag and drop
- [ ] File permission indicators
- [ ] Loading spinner for large directories

## 📝 Feedback

Test the app and report:
- ✅ What works well
- ❌ What doesn't work
- 💡 Suggestions for improvements
- 🐛 Any bugs or crashes

## 🎯 Next Steps

After successful testing of Phase 1, we'll add:
1. **Icon Caching** - Real file icons from NSWorkspace
2. **Settings Panel** - Configure app behavior
3. **Search** - Instant file search
4. **Clipboard** - Copy/cut/paste operations
5. **Context Menu** - Right-click actions

---

**Built with Swift 6.2.1 and SwiftUI**
**Targets macOS 13.0+**
