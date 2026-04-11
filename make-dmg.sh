#!/bin/bash
# Creates a distributable DMG with install instructions
set -e

APP_NAME="KeyFinder"
VERSION="1.9"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
STAGING="build/dmg-staging"
PREBUILT_APP="build/${APP_NAME}.app"

# Skip build - use already-built app from build-app.sh
if [ ! -d "${PREBUILT_APP}" ]; then
    echo "❌ Error: No built app found at ${PREBUILT_APP}"
    echo "   Run build-app.sh first"
    exit 1
fi

echo "Using pre-built app: ${PREBUILT_APP}"

# Create staging folder
rm -rf "${STAGING}"
mkdir -p "${STAGING}"

# Copy the pre-built app
cp -R "${PREBUILT_APP}" "${STAGING}/"

# Create install instructions
cat > "${STAGING}/HOW TO INSTALL.txt" << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  KeyFinder v1.9 — Installation Guide
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
  Requires macOS 12.0 or later
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
