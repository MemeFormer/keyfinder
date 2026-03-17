#!/bin/bash

set -e

echo "🚀 Building KeyFinder (Desktop + VST)"
echo "====================================="
echo ""

# Build desktop app
echo "📱 Building Desktop App..."
./build-app.sh

# Open desktop app
echo "🎯 Launching Desktop App..."
open build/KeyFinder.app

# Try to build VST if JUCE is available
if [ -d "$HOME/JUCE" ] || [ -d "/Applications/JUCE" ]; then
    echo ""
    echo "🎛️  Building VST Plugin..."
    ./install-vst.sh
else
    echo ""
    echo "⚠️  Skipping VST build (JUCE not installed)"
    echo "To install VST support:"
    echo "  1. Install JUCE: git clone https://github.com/juce-framework/JUCE.git ~/JUCE"
    echo "  2. Run: ./install-vst.sh"
fi

echo ""
echo "✅ Build complete!"
