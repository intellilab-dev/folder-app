#!/bin/bash
# Install Folder app to PATH for easy command-line access

set -e

APP_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Folder.app"
SYMLINK_PATH="/usr/local/bin/folder"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Folder.app not found. Please run ./build.sh first."
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
if [ ! -d "/usr/local/bin" ]; then
    echo "📁 Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
fi

# Remove existing symlink if it exists
if [ -L "$SYMLINK_PATH" ]; then
    echo "🗑️  Removing existing symlink..."
    sudo rm "$SYMLINK_PATH"
fi

# Create symlink
echo "🔗 Creating symlink: $SYMLINK_PATH -> $APP_PATH"
sudo ln -s "$APP_PATH/Contents/MacOS/Folder" "$SYMLINK_PATH"

# Make sure it's executable
sudo chmod +x "$SYMLINK_PATH"

echo "✅ Success! You can now run 'folder' from anywhere in the terminal."
echo ""
echo "Usage:"
echo "  folder                    # Launch Folder app"
echo "  folder /path/to/folder   # Open specific folder (future feature)"
echo ""
echo "To uninstall: sudo rm $SYMLINK_PATH"
