# Folder

Fast, keyboard-driven file browser for macOS. Native Swift/SwiftUI.

## Install

```bash
git clone https://github.com/intellilab-dev/folder-app.git
cd folder-app && ./install.sh
```

**Requires:** macOS 13+, Xcode Command Line Tools

## Features

- Keyboard navigation (arrows, shortcuts)
- External drive support with one-click eject
- Grid/List views with sorting
- Drag & drop everywhere
- Shortcuts.app integration: `folder://open?path=/path`

## Shortcuts

| Key | Action |
|-----|--------|
| Cmd+F | Search |
| Cmd+Shift+N | New folder |
| Cmd+C/X/V | Copy/Cut/Paste |
| Space | Quick Look |
| Enter | Open |
| Delete | Trash |

## Troubleshooting

**Won't open?** `xattr -cr /Applications/Folder.app`

## License

Open Source, Non-Commercial. See [LICENSE](LICENSE).

---

<details>
<summary>Development</summary>

### Building

```bash
./build.sh          # Build Folder.app
./install.sh        # Build + install + add to PATH
```

### Project Structure

```
Sources/FolderApp/
├── main.swift       # App entry
├── Models/          # Data structures
├── ViewModels/      # Business logic
├── Views/           # SwiftUI interface
└── Services/        # File system, icons, clipboard
```

### Contributing

- Report bugs via GitHub Issues
- Submit pull requests
- Request features

</details>
