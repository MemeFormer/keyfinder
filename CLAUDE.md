# KeyFinder - Project Requirements & Preferences

## Build Process

- **Always build with `./build-app.sh`** - This script automatically:
  1. Builds for Intel + Apple Silicon
  2. Creates universal binary
  3. Packages as .app
  4. Signs with ad-hoc signature
  5. **Auto-creates DMG** in project folder

- **DMG naming**: Always `KeyFinder-v1.7.dmg` (version 1.7)

## UI/UX Requirements

### Column Layout (in order)
```
ART | TRACK | KEY | CAMELOT | BPM | DUR | WAVEFORM
```

- **KEY**: Musical key (C, Cm, G, Am, etc.)
- **CAMELOT**: Camelot notation (8B, 9B, 11A, etc.)
- **BPM**: Tempo (124.0, 128.0, etc.)
- **DUR**: Duration in mm:ss format (6:54)
- **WAVEFORM**: Mini waveform visualization

### Remove These Columns
- Energy
- Confidence/Conf
- Categories

### UI Guidelines
- Minimal black & white theme
- Monospace fonts
- Clean drop zone for file import

## Features Implemented (v1.7)

### Core Analysis
- Key detection (Krumhansl-Schmuckler algorithm)
- BPM detection
- Camelot notation
- Beatgrid/phase detection
- 16K FFT with harmonic weighting

### Export Formats
- CSV
- Rekordbox XML
- Serato CSV
- Traktor NML
- Engine DJ (JSON)
- Virtual DJ (XML)
- iTunes XML
- Direct tag writing to audio files

### Performance
- Apple Silicon optimization
- Parallel batch processing
- Analysis caching (file hash based)
- Streaming for large files

### Error Handling
- Detailed error categorization
- Retry failed tracks
- Skip/ignore failed tracks
- Analysis log view

## What NOT To Do

- Don't add cloud sync
- Don't add Mac App Store specific code
- Don't add Meta/Facebook pixel (web tracking - not relevant for desktop app)
- Don't show wrong data in columns - always match KEY→KEY, CAMELOT→CAMELOT, BPM→BPM
- Don't include Energy or Confidence columns

## Cache Locations

If issues with old cached data:
- `~/Library/Caches/KeyFinder`
- `~/Library/Application Support/KeyFinder`

Delete these if columns show wrong data after updates.
