#!/bin/bash
# Creates a distributable DMG with install instructions
set -e

APP_NAME="KeyFinder"
VERSION="1.7"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
STAGING="build/dmg-staging"
BUILD_DIR=".build/arm64-apple-macosx/release"

# Build the app first
swift build -c release

# Create staging folder
rm -rf "${STAGING}"
mkdir -p "${STAGING}"
mkdir -p "${STAGING}/${APP_NAME}.app/Contents/MacOS"
mkdir -p "${STAGING}/${APP_NAME}.app/Contents/Resources"

# Copy the executable
cp "${BUILD_DIR}/${APP_NAME}" "${STAGING}/${APP_NAME}.app/Contents/MacOS/"

# Create Info.plist
cat > "${STAGING}/${APP_NAME}.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>KeyFinder</string>
    <key>CFBundleIdentifier</key>
    <string>com.keyfinder.app</string>
    <key>CFBundleName</key>
    <string>KeyFinder</string>
    <key>CFBundleVersion</key>
    <string>1.7</string>
    <key>CFBundleShortVersionString</key>
    <string>1.7</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Copy app icon if it exists
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${STAGING}/${APP_NAME}.app/Contents/Resources/"
    echo "✓ App icon added"
fi

# Copy Resources if they exist
if [ -d "Sources/KeyFinder/Resources" ]; then
    cp -R "Sources/KeyFinder/Resources/"* "${STAGING}/${APP_NAME}.app/Contents/Resources/" 2>/dev/null || true
fi

# Create install instructions
cat > "${STAGING}/HOW TO INSTALL.txt" << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  KeyFinder v1.7 — Installation Guide
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1
  Drag KeyFinder.app into your Applications folder.

STEP 2 — First Launch (important)
  Because this app is not from the Mac App Store,
  macOS will block it from opening normally.

  DO THIS instead:
  → Right-click (or Control+click) KeyFinder.app
  → Select "Open" from the menu
  → Click "Open" in the popup that appears

  You only need to do this ONCE.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Requires macOS 13.0 or later
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# Create a symlink to /Applications for easy drag-install
ln -s /Applications "${STAGING}/Applications"

# Build the DMG from staging folder
rm -f "${DMG_NAME}"
rm -f "build/${DMG_NAME}"
hdiutil create \
    -volname "${APP_NAME} v${VERSION}" \
    -srcfolder "${STAGING}" \
    -ov -format UDZO \
    "${DMG_NAME}"

# Also copy to build folder
cp "${DMG_NAME}" "build/"

# Clean up staging
rm -rf "${STAGING}"

echo ""
echo "✅ Done: ${DMG_NAME}"
echo "   Size: $(du -sh "${DMG_NAME}" | cut -f1)"
