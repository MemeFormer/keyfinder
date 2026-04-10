#!/bin/bash

# Build script for KeyFinder macOS app
set -e

echo "Building KeyFinder..."

# Build modes:
# - universal (default): build both Intel and Apple Silicon and merge with lipo
# - host: build only the host architecture
BUILD_MODE="${BUILD_MODE:-universal}"
USER_SET_ARCHS="${ARCHS+x}"
ARCHS="${ARCHS:-x86_64 arm64}"

if [ "${BUILD_MODE}" = "host" ] && [ -z "${USER_SET_ARCHS}" ]; then
    HOST_ARCH=$(uname -m)
    if [ "${HOST_ARCH}" = "x86_64" ]; then
        ARCHS="x86_64"
    elif [ "${HOST_ARCH}" = "arm64" ]; then
        ARCHS="arm64"
    else
        echo "❌ Unsupported host architecture: ${HOST_ARCH}"
        exit 1
    fi
fi

echo "Build mode: ${BUILD_MODE}"
echo "Architectures: ${ARCHS}"
echo "Swift toolchain: $(swift --version | head -1)"

for ARCH in ${ARCHS}; do
    echo "Building for ${ARCH}..."
    swift build -c release --arch "${ARCH}"
done

mkdir -p .build/universal

if [ "$(echo "${ARCHS}" | wc -w | tr -d ' ')" -eq 1 ]; then
    ONLY_ARCH="${ARCHS}"
    echo "Single-arch build detected (${ONLY_ARCH}); using that binary directly..."
    cp ".build/${ONLY_ARCH}-apple-macosx/release/KeyFinder" .build/universal/KeyFinder
else
    echo "Creating universal binary with lipo..."
    LIPO_INPUTS=""
    for ARCH in ${ARCHS}; do
        LIPO_INPUTS="${LIPO_INPUTS} .build/${ARCH}-apple-macosx/release/KeyFinder"
    done
    # shellcheck disable=SC2086
    lipo -create ${LIPO_INPUTS} -output .build/universal/KeyFinder
fi

# Create app bundle structure
APP_NAME="KeyFinder"
APP_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean and create directories
rm -rf build
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy universal executable
cp .build/universal/KeyFinder "${MACOS_DIR}/"

# Copy app icon if it exists
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/"
    echo "✓ App icon added"
fi

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>KeyFinder</string>
    <key>CFBundleIdentifier</key>
    <string>com.keyfinder.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>KeyFinder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.9</string>
    <key>CFBundleVersion</key>
    <string>9</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.music</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Audio File</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.audio</string>
                <string>public.mp3</string>
                <string>com.microsoft.waveform-audio</string>
                <string>com.apple.m4a-audio</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

echo "App bundle created at: ${APP_DIR}"

# Check for signing identity
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F '"' '{print $2}')

if [ -z "$IDENTITY" ]; then
    echo ""
    echo "⚠️  No Developer ID certificate found."
    echo "Attempting to sign with ad-hoc signature (for local use only)..."
    codesign --force --deep --sign - "${APP_DIR}"
    echo "✅ App signed with ad-hoc signature"
    echo "⚠️  This app will only run on your machine"
else
    echo ""
    echo "Found signing identity: ${IDENTITY}"
    echo "Signing app..."
    codesign --force --deep --sign "${IDENTITY}" --options runtime "${APP_DIR}"
    echo "✅ App signed with Developer ID"
fi

echo ""
echo "🎉 Build complete!"
echo "App location: ${APP_DIR}"

# Create DMG automatically
echo ""
echo "Creating DMG..."
./make-dmg.sh

echo ""
echo "✅ DMG created: KeyFinder-v1.9.dmg"
