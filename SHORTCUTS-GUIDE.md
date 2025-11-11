# Using Folder.app with macOS Shortcuts

Folder.app now supports the `folder://` URL scheme, making it easy to integrate with macOS Shortcuts and automation workflows.

## Quick Start

### 1. Install the App
```bash
./build.sh
./install-app.sh
```

The app will be installed to `/Applications/Folder.app` and registered with the system.

### 2. Create a Shortcut

#### Method 1: Open URL Action
1. Open **Shortcuts** app
2. Create a new shortcut
3. Add **"Open URLs"** action
4. Enter: `folder://open?path=/Users/yourusername/Documents`
5. Run the shortcut!

#### Method 2: App Action (Future)
1. Open **Shortcuts** app
2. Search for "Folder" in the Apps section
3. Add Folder-specific actions (coming soon with App Intents)

## URL Scheme Format

### Open a Specific Folder
```
folder://open?path=/path/to/folder
```

**Examples:**
- Open Documents: `folder://open?path=/Users/mattia/Documents`
- Open Downloads: `folder://open?path=/Users/mattia/Downloads`
- Open Desktop: `folder://open?path=/Users/mattia/Desktop`
- Open Applications: `folder://open?path=/Applications`

### URL Encoding
For paths with spaces, use URL encoding:
```
folder://open?path=/Users/mattia/My%20Documents
```

## Example Shortcuts

### Quick Folder Access
Create shortcuts for frequently accessed folders:

**"Open Projects"**
```
Open URLs: folder://open?path=/Users/mattia/Projects
```

**"Open Downloads"**
```
Open URLs: folder://open?path=/Users/mattia/Downloads
```

### Context Menu Integration
1. Create a shortcut that opens Folder with the current file's parent directory
2. Add it to Finder's Quick Actions
3. Right-click any file → Quick Actions → Open in Folder

### Workflow Example
Combine with other actions:

```
1. Ask for Input (Text) → "Which folder?"
2. If Downloads
   → Open URLs: folder://open?path=/Users/mattia/Downloads
3. If Documents
   → Open URLs: folder://open?path=/Users/mattia/Documents
4. Otherwise
   → Open URLs: folder://open?path=/Users/mattia
```

## Advanced Usage

### Launch from Terminal
```bash
open "folder://open?path=$HOME/Documents"
```

### Launch from Script
```bash
#!/bin/bash
PROJECT_DIR="/Users/mattia/Projects/MyApp"
open "folder://open?path=${PROJECT_DIR}"
```

### Launch from AppleScript
```applescript
tell application "System Events"
    open location "folder://open?path=/Users/mattia/Documents"
end tell
```

## Troubleshooting

### "Folder" doesn't appear in Shortcuts
1. Make sure the app is in `/Applications/`
2. Run: `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -v -f /Applications/Folder.app`
3. Restart Shortcuts app

### URL doesn't open
1. Verify the path exists: `ls "/path/to/folder"`
2. Check URL encoding for special characters
3. Make sure the path is absolute (starts with `/`)

### Icon not showing
1. Restart Dock: `killall Dock`
2. Restart Finder: `killall Finder`

## Future Enhancements

Planned features for Shortcuts integration:
- **App Intents**: Native shortcut actions (no URL needed)
- **Quick Actions**: Right-click integration in Finder
- **Focus Filters**: Open specific folders based on Focus mode
- **Automation Triggers**: Time-based folder opening

## Testing the Installation

Test if the URL scheme is registered:
```bash
# This should open Folder.app to your home directory
open "folder://open?path=$HOME"
```

If Folder.app opens and navigates to your home folder, the integration is working! 🎉

---

**Note**: The `folder://` URL scheme is registered system-wide after installation. You can use it from:
- Shortcuts app
- Terminal (`open` command)
- AppleScript
- Any app that can open URLs
- Web browsers (for development/testing)
