#!/bin/bash
# Run script for Folder app

APP_NAME="Folder.app"

# Check if app exists
if [ ! -d "$APP_NAME" ]; then
    echo "❌ App not found. Building first..."
    ./build.sh
fi

# Run the app
echo "🚀 Launching Folder app..."
open "$APP_NAME"
