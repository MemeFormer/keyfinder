# Quick Start Guide

## Desktop App

### Build & Launch (One Command)
```bash
./build-all.sh
```

This will:
- Build the desktop app
- Automatically launch it
- Build VST if JUCE is installed

### Manual Build
```bash
./build-app.sh
open build/KeyFinder.app
```

## Using the Desktop App

1. The app opens showing "DROP AUDIO FILES"
2. Drag **one or multiple audio files** onto the window
3. App automatically analyzes all files
4. View results in table format:
   - Album art (if embedded in file)
   - Track name
   - Musical key (e.g., "Am", "C#", "F#m")
   - Camelot notation (e.g., "8A", "5B")
   - BPM (e.g., "128.0")
5. Drop more files to add to batch
6. Click X to remove individual tracks
7. Click "CLEAR ALL" to start fresh

## VST Plugin

### First-Time Setup
1. Install JUCE (one time only):
```bash
cd ~
git clone https://github.com/juce-framework/JUCE.git
```

2. Build and install VST:
```bash
./install-vst.sh
```

This installs:
- VST3 plugin to `~/Library/Audio/Plug-Ins/VST3/`
- Audio Unit to `~/Library/Audio/Plug-Ins/Components/`

### Using VST in DAW
1. Open your DAW (Ableton, Logic, FL Studio, etc.)
2. Rescan plugins
3. Add "KeyFinder VST" to any audio track
4. Play the track
5. Click "ANALYZE" button
6. Wait 5 seconds
7. View key, Camelot, and BPM

## Example Results

### Desktop App (Batch)
```
[Album Art] Track Name           Key    Camelot  BPM
───────────────────────────────────────────────────
[  🎵   ]  Summer Track.mp3     Am     8A       128.0
[  🎨   ]  Deep House.flac      C      8B       122.5
[  📀   ]  Techno Banger.wav    Dm     7A       130.0
```

### VST Plugin (Live)
```
KEY FINDER VST
──────────────
KEY
 Am

CAMELOT        BPM
  8A           128.0

[ANALYZE]
```

## Tips

### For Best Accuracy
- Use high-quality audio (WAV, FLAC, 320kbps MP3)
- Analyze full tracks (not just intros)
- For tracks with key changes, result shows dominant key
- Compare with ear test if uncertain

### Batch Processing (Desktop)
- Drop entire folders of tracks
- Results appear as each track finishes
- Remove tracks that failed or aren't needed
- Use for DJ library preparation

### Live Analysis (VST)
- Perfect for quick checks during production
- Doesn't affect audio (pass-through only)
- Great for finding compatible tracks to layer
- Use during mixing/mastering sessions

## Camelot Wheel Reference

Perfect harmonic mixing:
- **Same number, any letter**: C → Cm (8B → 8A)
- **±1 number, same letter**: 8A → 7A or 9A
- **Combined**: 8A works with 7A, 8B, 9A

## Technical Notes

- Desktop app: Batch analyzes unlimited files
- VST plugin: Captures 5 seconds of live audio
- Both use identical algorithms (~90-95% accuracy)
- 16K FFT with harmonic weighting
- All processing is local (no internet required)
