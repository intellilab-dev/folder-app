#!/bin/bash
# Convert Folder.png to .icns format

set -e

echo "🎨 Converting Folder.png to app icon..."

# Check if source icon exists
if [ ! -f "Folder.png" ]; then
    echo "❌ Folder.png not found!"
    exit 1
fi

# Create iconset directory
ICONSET="Resources/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

# Generate all required sizes
echo "📐 Generating icon sizes..."

sips -z 16 16     Folder.png --out "${ICONSET}/icon_16x16.png" > /dev/null
sips -z 32 32     Folder.png --out "${ICONSET}/icon_16x16@2x.png" > /dev/null
sips -z 32 32     Folder.png --out "${ICONSET}/icon_32x32.png" > /dev/null
sips -z 64 64     Folder.png --out "${ICONSET}/icon_32x32@2x.png" > /dev/null
sips -z 128 128   Folder.png --out "${ICONSET}/icon_128x128.png" > /dev/null
sips -z 256 256   Folder.png --out "${ICONSET}/icon_128x128@2x.png" > /dev/null
sips -z 256 256   Folder.png --out "${ICONSET}/icon_256x256.png" > /dev/null
sips -z 512 512   Folder.png --out "${ICONSET}/icon_256x256@2x.png" > /dev/null
sips -z 512 512   Folder.png --out "${ICONSET}/icon_512x512.png" > /dev/null
sips -z 1024 1024 Folder.png --out "${ICONSET}/icon_512x512@2x.png" > /dev/null

echo "✅ All sizes generated"

# Convert to .icns
echo "🔄 Converting to .icns..."
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns

# Clean up
rm -rf "$ICONSET"

echo "✅ Icon conversion complete! Resources/AppIcon.icns created"
