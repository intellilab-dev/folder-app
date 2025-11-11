#!/bin/bash
# Add padding to icon for proper macOS sizing

set -e

echo "🎨 Adding padding to icon..."

# Backup original
cp Folder.png Folder-original.png

# Scale down to 85% and add transparent padding
# macOS icons need about 7.5% padding on each side
sips -z 850 850 Folder.png --out Folder-scaled.png > /dev/null

# Create 1024x1024 canvas with padding
convert Folder-scaled.png -gravity center -background none -extent 1024x1024 Folder-padded.png

# Replace original
mv Folder-padded.png Folder.png
rm Folder-scaled.png

echo "✅ Icon padding added (1024x1024 with padding)"
