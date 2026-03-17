#!/bin/bash
# KeyFinder Distribution Script
# Builds, signs, notarizes, and packages for web distribution
# Requires: Apple Developer ID cert + notarytool credentials
set -e

APP_NAME="KeyFinder"
VERSION="1.5"
BUNDLE_ID="com.keyfinder.app"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

# ─── Step 1: Build ──────────────────────────────────────────────────────────
echo "▶ Building..."
./build-app.sh

# ─── Step 2: Verify signing identity ────────────────────────────────────────
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F '"' '{print $2}')
if [ -z "$IDENTITY" ]; then
    echo "❌ No Developer ID Application certificate found."
    echo "   Get one at: https://developer.apple.com/account/resources/certificates"
    exit 1
fi
echo "✓ Signing identity: ${IDENTITY}"

# ─── Step 3: Sign with hardened runtime (required for notarization) ─────────
echo "▶ Signing with hardened runtime..."
codesign --force --deep \
    --sign "${IDENTITY}" \
    --options runtime \
    --entitlements entitlements.plist \
    "build/${APP_NAME}.app"
echo "✓ Signed"

# ─── Step 4: Create DMG ─────────────────────────────────────────────────────
echo "▶ Creating DMG..."
rm -f "build/${DMG_NAME}"
hdiutil create \
    -volname "${APP_NAME} ${VERSION}" \
    -srcfolder "build/${APP_NAME}.app" \
    -ov -format UDZO \
    "build/${DMG_NAME}"

# Sign the DMG too
codesign --force --sign "${IDENTITY}" "build/${DMG_NAME}"
echo "✓ DMG created and signed: build/${DMG_NAME}"

# ─── Step 5: Notarize ───────────────────────────────────────────────────────
echo ""
echo "▶ Submitting for notarization..."
echo "  (This takes 1-5 minutes)"
echo ""
echo "You'll need your Apple ID and an App-Specific Password."
echo "Generate one at: https://appleid.apple.com → App-Specific Passwords"
echo ""

read -p "Apple ID (email): " APPLE_ID
read -sp "App-Specific Password: " APP_PASSWORD
echo ""
read -p "Team ID (from developer.apple.com/account): " TEAM_ID

xcrun notarytool submit "build/${DMG_NAME}" \
    --apple-id "${APPLE_ID}" \
    --password "${APP_PASSWORD}" \
    --team-id "${TEAM_ID}" \
    --wait

# ─── Step 6: Staple notarization ticket to DMG ──────────────────────────────
echo "▶ Stapling notarization ticket..."
xcrun stapler staple "build/${DMG_NAME}"
echo "✓ Stapled"

# ─── Step 7: Verify ─────────────────────────────────────────────────────────
echo "▶ Verifying..."
spctl --assess --type open --context context:primary-signature "build/${DMG_NAME}" && echo "✓ Gatekeeper approved"

echo ""
echo "🎉 Distribution build ready!"
echo "   File: build/${DMG_NAME}"
echo "   Size: $(du -sh "build/${DMG_NAME}" | cut -f1)"
echo ""
echo "Upload this DMG to your website."
