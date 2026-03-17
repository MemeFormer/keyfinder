#!/bin/bash

set -e

echo "🎛️  KeyFinder VST Build & Install Script"
echo "========================================"
echo ""

# Check if JUCE is installed
JUCE_DIR=""
if [ -d "$HOME/JUCE" ]; then
    JUCE_DIR="$HOME/JUCE"
elif [ -d "/Applications/JUCE" ]; then
    JUCE_DIR="/Applications/JUCE"
fi

if [ -z "$JUCE_DIR" ]; then
    echo "❌ JUCE not found!"
    echo ""
    echo "To build the VST, you need to install JUCE first:"
    echo ""
    echo "Option 1 - Download manually:"
    echo "  1. Go to https://juce.com/download/"
    echo "  2. Download JUCE"
    echo "  3. Unzip to ~/JUCE or /Applications/JUCE"
    echo ""
    echo "Option 2 - Quick install (requires git):"
    echo "  cd ~"
    echo "  git clone https://github.com/juce-framework/JUCE.git"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Found JUCE at: $JUCE_DIR"
echo ""

# Find Projucer
PROJUCER=""
if [ -f "$JUCE_DIR/Projucer.app/Contents/MacOS/Projucer" ]; then
    PROJUCER="$JUCE_DIR/Projucer.app/Contents/MacOS/Projucer"
elif [ -f "$JUCE_DIR/extras/Projucer/Builds/MacOSX/build/Debug/Projucer.app/Contents/MacOS/Projucer" ]; then
    PROJUCER="$JUCE_DIR/extras/Projucer/Builds/MacOSX/build/Debug/Projucer.app/Contents/MacOS/Projucer"
fi

if [ -z "$PROJUCER" ]; then
    echo "⚠️  Projucer not found, building it..."
    cd "$JUCE_DIR/extras/Projucer/Builds/MacOSX"
    xcodebuild -configuration Release
    PROJUCER="$JUCE_DIR/extras/Projucer/Builds/MacOSX/build/Release/Projucer.app/Contents/MacOS/Projucer"
fi

echo "✅ Using Projucer at: $PROJUCER"
echo ""

# Update JUCE paths in .jucer file
echo "📝 Updating JUCE module paths..."
cd "$(dirname "$0")/KeyFinderVST"

# Generate Xcode project
echo "🔨 Generating Xcode project..."
"$PROJUCER" --resave KeyFinderVST.jucer

# Build VST3
echo "🏗️  Building VST3 plugin..."
cd Builds/MacOSX
xcodebuild -configuration Release

# Install VST3
echo "📦 Installing VST3..."
VST3_DIR="$HOME/Library/Audio/Plug-Ins/VST3"
mkdir -p "$VST3_DIR"

if [ -d "build/Release/KeyFinderVST.vst3" ]; then
    cp -R "build/Release/KeyFinderVST.vst3" "$VST3_DIR/"
    echo "✅ VST3 installed to: $VST3_DIR/KeyFinderVST.vst3"
else
    echo "❌ VST3 build not found!"
    exit 1
fi

# Build and install AU (Audio Unit)
echo "🏗️  Building AU plugin..."
xcodebuild -configuration Release

AU_DIR="$HOME/Library/Audio/Plug-Ins/Components"
mkdir -p "$AU_DIR"

if [ -d "build/Release/KeyFinderVST.component" ]; then
    cp -R "build/Release/KeyFinderVST.component" "$AU_DIR/"
    echo "✅ AU installed to: $AU_DIR/KeyFinderVST.component"
fi

echo ""
echo "🎉 VST/AU Build & Install Complete!"
echo ""
echo "Installed plugins:"
echo "  • VST3: $VST3_DIR/KeyFinderVST.vst3"
echo "  • AU:   $AU_DIR/KeyFinderVST.component"
echo ""
echo "Next steps:"
echo "  1. Open your DAW (Ableton, Logic, etc.)"
echo "  2. Rescan plugins"
echo "  3. Load 'KeyFinder VST' on a track"
echo "  4. Play audio and click ANALYZE"
echo ""
