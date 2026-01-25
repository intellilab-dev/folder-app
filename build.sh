#!/bin/bash
# Build script for Folder app

set -e  # Exit on error

echo "🔨 Building Folder app..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build
rm -rf Folder.app

# Build with Swift Package Manager
echo "📦 Compiling Swift code..."
swift build -c release

# Create .app bundle structure
echo "📱 Creating .app bundle..."
APP_NAME="Folder"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Copy the executable
echo "📋 Copying executable..."
cp ".build/release/Folder" "${MACOS}/${APP_NAME}"

# Create Info.plist
echo "📄 Creating Info.plist..."
cat > "${CONTENTS}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Folder</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.folder.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Folder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.folder.app</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>folder</string>
            </array>
        </dict>
    </array>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Folder needs access to browse files on your Desktop.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>Folder needs access to browse your documents.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>Folder needs access to browse your downloads.</string>
</dict>
</plist>
EOF

# Copy app icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    echo "🎨 Copying app icon..."
    cp "Resources/AppIcon.icns" "${RESOURCES}/"
fi

# Make executable
chmod +x "${MACOS}/${APP_NAME}"

# Code sign with entitlements
echo "🔒 Code signing with entitlements..."
codesign --force --sign - --entitlements Folder.entitlements --deep "${APP_BUNDLE}"

echo "✅ Build complete! App bundle created at: ${APP_BUNDLE}"
echo ""
echo "To install system-wide:"
echo "  ./install.sh"
echo ""
echo "Or open it manually:"
echo "  open ${APP_BUNDLE}"
