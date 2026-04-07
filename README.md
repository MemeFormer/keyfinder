# Key Finder

A professional macOS app and VST plugin for detecting musical key, Camelot notation, and BPM from audio files.

## Features

### Desktop App
- **Batch Processing**: Analyze multiple files at once
- **Album Art Display**: Shows embedded artwork from audio files
- **Enhanced Accuracy**: 16K FFT with harmonic weighting (~90-95% accuracy)
- **Camelot Wheel**: Perfect for harmonic mixing
- **Professional Algorithms**: Krumhansl-Schmuckler key detection
- **Minimal Black & White UI**: Clean, distraction-free interface
- **Multiple Formats**: MP3, WAV, M4A, FLAC, AIFF

### VST Plugin (JUCE)
- **Live Analysis**: Real-time key/BPM detection in your DAW
- **Same Accuracy**: Uses identical algorithms as desktop app
- **Works Everywhere**: Ableton, Logic, FL Studio, etc.
- **Pass-Through**: Doesn't affect audio, only analyzes

## Build Instructions

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building the App

1. Open Terminal and navigate to the project directory
2. Build and run using Swift Package Manager:
```bash
swift build
swift run
```

### Creating an Xcode Project (Optional)

 To open in Xcode for easier development:
```bash
open Package.swift
```

Or generate an Xcode project:
```bash
swift package generate-xcodeproj
open KeyFinder.xcodeproj
```

## Usage

 ### Desktop App
1. Launch the app
2. Drag and drop **one or multiple audio files** onto the window
3. App automatically analyzes all files in sequence
4. View results in table format:
     - Album art (if embedded)
     - Track name
     - Musical key
     - Camelot notation
     - BPM
5. Drop more files to add to the batch
6. Click "CLEAR ALL" to start fresh

### VST Plugin
1. Build the VST (see `KeyFinderVST/README.md`)
2. Load in your DAW on any audio track
3. Play the track
4. Click "ANALYZE" to capture 5 seconds of audio
5. View results directly in plugin window

## Technical Details

### Key Detection
Uses enhanced Krumhansl-Schmuckler key-finding algorithm:
- **16,384-point FFT** for high frequency resolution (2x typical)
- **Harmonic weighting**: Bass frequencies (80-200 Hz) weighted 2.5x
- Correlates pitch class profile with major/minor key templates
- Returns best matching key from all 24 possibilities
- **~90-95% accuracy** on clear tracks (see ACCURACY.md)

### BPM Detection
Implements onset-based tempo detection:
- Calculates spectral flux for onset detection
- Applies autocorrelation to find periodicity
- Detects tempo peaks in 60-180 BPM range

### Supported Formats
- MP3
- WAV
- M4A
- FLAC
- AIFF/AIF                          

## Architecture

### Desktop App
```
KeyFinder/
├── AudioAnalysis/
│   ├── KeyDetector.swift          # Enhanced key detection (16K FFT)
│   ├── BPMDetector.swift          # BPM detection algorithm
│   ├── AudioProcessor.swift       # Audio file processing
│   └── AlbumArtExtractor.swift    # Metadata extraction
├── Models/
│   ├── AudioAnalysisModel.swift   # Batch processing logic
│   └── TrackAnalysis.swift        # Track data model
├── Views/
│   └── BatchContentView.swift     # Table view with album art
└── KeyFinderApp.swift             # App entry point
```

### VST Plugin
```
KeyFinderVST/
├── Source/
│   ├── PluginProcessor.h/cpp      # Audio processing & buffering
│   ├── PluginEditor.h/cpp         # Minimal black & white UI
│   ├── KeyDetector.h/cpp          # C++ port of key detection
│   └── BPMDetector.h/cpp          # C++ port of BPM detection
└── KeyFinderVST.jucer             # JUCE project file
```

## Troubleshooting: OCLP & Unsupported macOS Hardware

If you are running macOS via OpenCore Legacy Patcher (OCLP) or using older, unsupported Apple hardware, you may encounter specific build and execution blocks.

**1. App Store blocks Xcode download**
OCLP spoofs macOS version numbers, which can cause the Mac App Store to block the full Xcode download. Since `xcode-select --install` does not provide the full toolchain required for `swift build`, you can bypass the App Store entirely by installing the standalone Swift toolchain via Homebrew:
```bash
brew install swift
```

**2. Application displays a prohibitory "Strikethrough" icon**
If the app builds successfully but displays a strikethrough icon in Finder ("application is not supported on this Mac"), this is a LaunchServices OS/Hardware block, **not** a Gatekeeper/Quarantine issue. Standard workarounds like `Right-Click -> Open` or removing quarantine flags will not work.

This occurs because the app's `Info.plist` requires a minimum macOS version of `13.0`, which triggers strict hardware checks on patched older machines. 

**To resolve this manually:**
1. Open the built `KeyFinder-v1.9.dmg` file.
2. **Important:** Drag `KeyFinder.app` out of the `.dmg` and into your `/Applications` folder (or Desktop). *Do not try to edit it inside the `.dmg` or you will get a "read-only file system" error.*
3. Right-click the extracted `KeyFinder.app` and select **Show Package Contents**.
4. Navigate to `Contents/Info.plist` and open it in a text editor.
5. Locate the minimum system version key:
```xml
<key>LSMinimumSystemVersion</key>
<string>13.0</string>
```
6. Change `13.0` to `12.0` and save the file.
7. The strikethrough icon should disappear (you may need to relaunch Finder or move the app to refresh the icon cache), and the app will now launch successfully.

## License

MIT
