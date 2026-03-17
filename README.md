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

## License

MIT
