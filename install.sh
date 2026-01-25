#!/bin/bash
# Folder - One-line installer
# Builds, installs to /Applications, and adds to PATH

set -e

echo "=== Folder Installer ==="
echo ""

# Check for Swift/Xcode
if ! command -v swift &> /dev/null; then
    echo "Error: Swift not found. Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Build the app
echo "Building..."
./build.sh

# Install to /Applications
echo ""
echo "Installing to /Applications..."
rm -rf /Applications/Folder.app
cp -R Folder.app /Applications/

# Clear quarantine attributes
xattr -cr /Applications/Folder.app 2>/dev/null || true

# Add to PATH
echo "Adding 'folder' command to PATH..."
sudo mkdir -p /usr/local/bin
sudo ln -sf /Applications/Folder.app/Contents/MacOS/Folder /usr/local/bin/folder

echo ""
echo "Done! Launch with:"
echo "  folder              - from terminal"
echo "  Cmd+Space -> Folder - from Spotlight"
