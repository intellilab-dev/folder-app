#!/bin/bash
# Refresh macOS icon cache to show app icon in menu bar

echo "🔄 Refreshing macOS icon cache..."

# Kill any running Folder app instances
killall Folder 2>/dev/null || true

# Clear icon cache
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock
killall Finder

echo "✅ Icon cache refreshed!"
echo "⏳ Dock and Finder will restart in a few seconds..."
echo ""
echo "Now rebuild and run the app:"
echo "  ./build.sh && ./run.sh"
