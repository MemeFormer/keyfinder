#!/bin/bash

set -e

echo "📦 Creating DMG for KeyFinder..."

# Build the app first
./build-app.sh

APP_NAME="KeyFinder"
VERSION="1.5"
DMG_NAME="${APP_NAME}_v${VERSION}.dmg"
VOLUME_NAME="${APP_NAME}"

# Create temporary DMG folder
mkdir -p dmg_temp
cp -R build/KeyFinder.app dmg_temp/

# Create Applications symlink
ln -s /Applications dmg_temp/Applications

# Create DMG
hdiutil create -volname "${VOLUME_NAME}" -srcfolder dmg_temp -ov -format UDZO "${DMG_NAME}"

# Clean up
rm -rf dmg_temp

echo "✅ DMG created: ${DMG_NAME}"
echo "📤 Share this file with your friend!"
echo ""
echo "File size:"
ls -lh "${DMG_NAME}"
