# Quick Start: Using Folder App in Shortcuts

## ✅ The Working Method: Use URL Scheme

Since Folder.app is built with Swift Package Manager (not Xcode), it won't appear in the Shortcuts "Open App" picker. Instead, use the **URL scheme** which works perfectly!

### Create a Shortcut to Open Folder

1. Open **Shortcuts** app
2. Click **+** to create a new shortcut
3. Search for **"Open URLs"** and add it
4. Type or paste: `folder://open?path=/Users/YOUR_USERNAME/Documents`
5. Name your shortcut (e.g., "Open Documents")
6. Done! ✅

### Examples

**Open Downloads Folder:**
```
folder://open?path=/Users/YOUR_USERNAME/Downloads
```

**Open Desktop:**
```
folder://open?path=/Users/YOUR_USERNAME/Desktop
```

**Open Applications:**
```
folder://open?path=/Applications
```

**Open Any Custom Path:**
```
folder://open?path=/path/to/your/folder
```

### Pro Tip: Quick Access Shortcuts

Create multiple shortcuts for frequently accessed folders:

1. **"My Documents"** → `folder://open?path=/Users/YOUR_USERNAME/Documents`
2. **"My Downloads"** → `folder://open?path=/Users/YOUR_USERNAME/Downloads`
3. **"My Projects"** → `folder://open?path=/Users/YOUR_USERNAME/Projects`
4. **"Desktop"** → `folder://open?path=/Users/YOUR_USERNAME/Desktop`

Add these to your menu bar or assign keyboard shortcuts!

---

## Why doesn't it appear in "Open App"?

Apps built with Swift Package Manager (SPM) without Xcode don't have all the metadata that Shortcuts expects for the "Open App" action. The URL scheme method is actually **more powerful** because:

- ✅ You can specify which folder to open
- ✅ Works from anywhere (Terminal, browsers, other apps)
- ✅ Can be triggered programmatically
- ✅ Supports automation workflows

The "Open App" action would just launch the app, but the URL scheme lets you **open specific folders** directly!

---

## Test It Now

Run this in Terminal:
```bash
open "folder://open?path=$HOME"
```

This should open Folder.app at your home directory! 🎉
