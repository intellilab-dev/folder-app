#!/bin/bash
# Install Folder.app to Applications and register for Shortcuts

set -e

echo "📦 Installing Folder.app..."

# Check if Folder.app exists
if [ ! -d "Folder.app" ]; then
    echo "❌ Folder.app not found. Run ./build.sh first."
    exit 1
fi

# Remove old version if it exists
if [ -d "/Applications/Folder.app" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "/Applications/Folder.app"
fi

# Copy to Applications
echo "📋 Copying to /Applications..."
cp -R "Folder.app" "/Applications/"

# Make sure executable has correct permissions
chmod +x "/Applications/Folder.app/Contents/MacOS/Folder"

# Remove quarantine attributes
echo "🔓 Removing quarantine attributes..."
xattr -cr "/Applications/Folder.app"

# Create /usr/local/bin if it doesn't exist
if [ ! -d "/usr/local/bin" ]; then
    echo "📁 Creating /usr/local/bin..."
    sudo mkdir -p /usr/local/bin
fi

# Create symlink for command-line access
echo "🔗 Creating symlink for PATH access..."
sudo ln -sf "/Applications/Folder.app/Contents/MacOS/Folder" /usr/local/bin/folder

# Refresh Launch Services database to register URL scheme
echo "🔄 Registering URL scheme with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -v -f "/Applications/Folder.app"

# Refresh icon cache
echo "🎨 Refreshing icon cache..."
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "Folder.app is now installed and accessible via:"
echo "  • Spotlight (search 'Folder')"
echo "  • Launchpad"
echo "  • /Applications/Folder.app"
echo "  • Command line: 'folder' (in PATH)"
echo ""
echo "To use in Shortcuts:"
echo "  1. Open Shortcuts app"
echo "  2. Add 'Open URLs' action"
echo "  3. Use: folder://open?path=/your/folder/path"
echo ""
