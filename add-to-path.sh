#!/bin/bash
# Add Folder to PATH - Run this manually if needed

echo "🔗 Adding Folder to PATH..."
echo ""
echo "Run this command to add 'folder' to your PATH:"
echo ""
echo "sudo ln -sf /Applications/Folder.app/Contents/MacOS/Folder /usr/local/bin/folder"
echo ""
echo "After running, you can use 'folder' from any terminal!"
echo ""
echo "Press Enter to run it now (requires password), or Ctrl+C to cancel..."
read

sudo ln -sf /Applications/Folder.app/Contents/MacOS/Folder /usr/local/bin/folder

if [ -f "/usr/local/bin/folder" ]; then
    echo "✅ Success! Try: folder"
else
    echo "❌ Failed to create symlink"
fi
