# KeyFinder VST Plugin

A real-time key and BPM analyzer VST plugin for DAWs, built with JUCE.

## Features

- **Live Analysis**: Analyzes incoming audio in real-time during playback
- **Minimal Black & White UI**: Matches the desktop app aesthetic
- **Professional Algorithms**: Same accuracy as the standalone app
- **DAW Integration**: Works in Ableton, Logic Pro, FL Studio, etc.

## How It Works

The VST plugin acts as a **live analyzer**:
1. Load it on any audio track or master channel in your DAW
2. Play your track
3. Click "ANALYZE" to start capturing audio
4. After 5 seconds, the plugin displays:
   - Musical key (e.g., "Am", "C#")
   - Camelot notation (e.g., "8A", "5B")
   - BPM (beats per minute)

## Building the VST

### Prerequisites

1. **Install JUCE** (v7.0+):
   ```bash
   # Download from https://juce.com/download/
   # Or via homebrew:
   brew install juce
   ```

2. **Set JUCE Path**:
   - Open `KeyFinderVST.jucer` in Projucer
   - Go to File > Global Paths
   - Set "Path to JUCE" to your JUCE installation directory

### Build Steps

1. **Open in Projucer**:
   ```bash
   cd KeyFinderVST
   open KeyFinderVST.jucer
   ```

2. **Configure**:
   - In Projucer, go to the "Exporters" tab
   - Select "Xcode (macOS)"
   - Update JUCE module paths if needed

3. **Export to Xcode**:
   - Click "Save Project and Open in IDE"
   - This will generate Xcode project in `Builds/MacOSX/`

4. **Build in Xcode**:
   ```bash
   cd Builds/MacOSX
   xcodebuild -configuration Release
   ```

5. **Install VST**:
   ```bash
   # Copy to your VST3 folder
   cp -r build/Release/KeyFinderVST.vst3 ~/Library/Audio/Plug-Ins/VST3/

   # Or for AU (Audio Unit):
   cp -r build/Release/KeyFinderVST.component ~/Library/Audio/Plug-Ins/Components/
   ```

## Usage in DAW

### Ableton Live
1. Drop "KeyFinder VST" onto any audio track
2. Play the track
3. Click "ANALYZE" button in the plugin
4. View results after 5 seconds

### Logic Pro
1. Insert as Audio FX on track
2. Play track and click "ANALYZE"
3. Results appear in plugin window

### FL Studio
1. Add to mixer track as effect
2. Enable and click "ANALYZE" during playback

## Architecture

```
Source/
├── PluginProcessor.h/cpp   # Audio processing & analysis logic
├── PluginEditor.h/cpp      # Minimal black & white UI
├── KeyDetector.h/cpp       # Musical key detection
└── BPMDetector.h/cpp       # Tempo detection
```

## Key Detection Accuracy

The VST uses the same enhanced algorithm as the desktop app:
- **16384-point FFT** for high frequency resolution
- **Harmonic weighting** prioritizes bass frequencies (more reliable)
- **Krumhansl-Schmuckler** key profiles for correlation
- **80-4000 Hz** focus range for musical content

## Differences from Desktop App

| Feature | Desktop App | VST Plugin |
|---------|-------------|------------|
| Input | Drop audio files | Live audio from DAW |
| Batch Processing | ✅ Multiple files | ❌ One track at a time |
| Album Art | ✅ Displayed | ❌ Not applicable |
| Use Case | DJ library analysis | In-session analysis |

## Troubleshooting

**Plugin doesn't appear in DAW:**
- Check VST3 folder: `~/Library/Audio/Plug-Ins/VST3/`
- Rescan plugins in your DAW
- Check DAW's plugin blocklist

**No analysis results:**
- Ensure track is playing when you click ANALYZE
- Wait full 5 seconds for collection
- Check that audio is passing through plugin

**Build errors:**
- Verify JUCE path in Projucer
- Update to JUCE 7.0+
- Check Xcode version (14+)

## License

MIT
