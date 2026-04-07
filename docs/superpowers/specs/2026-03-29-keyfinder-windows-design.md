# KeyFinder Windows — Design Spec

**Date:** 2026-03-29
**Status:** Approved
**Goal:** Separate Windows build of KeyFinder as an Electron app for near-immediate release.

---

## Context

The existing KeyFinder v1.7 is a macOS-only SwiftUI app. The codebase uses AVFoundation, Accelerate, and AppKit — none of which are available on Windows. A Windows port requires a full rewrite. The chosen approach is Electron + essentia.js, which gives a release-quality Windows installer with the least implementation effort.

---

## Architecture

A new, standalone project directory: `keyfinder-windows/` (sibling to the macOS project root).

### Process Model

```
┌─────────────────────────────────────────────┐
│  Renderer Process (Chromium)                │
│  index.html + app.js + styles.css           │
│  — Track table, drop zone, UI state         │
└────────────────┬────────────────────────────┘
                 │ contextBridge IPC
┌────────────────▼────────────────────────────┐
│  Main Process (Node.js)                     │
│  main.js + preload.js                       │
│  — Window management, file dialogs,         │
│    export saves, tag writing                │
└────────────────┬────────────────────────────┘
                 │ Worker thread
┌────────────────▼────────────────────────────┐
│  Analysis Worker (worker.js)                │
│  — essentia.js WASM                         │
│  — Key detection, BPM, chroma               │
│  — One worker per file (parallel pool)      │
└─────────────────────────────────────────────┘
```

### File Structure

```
keyfinder-windows/
├── main.js              # Electron main — BrowserWindow, IPC handlers, file dialogs
├── preload.js           # contextBridge: exposes safe IPC API to renderer
├── worker.js            # Worker thread — loads essentia.js, analyzes one file
├── exporter.js          # Export logic: CSV, Rekordbox XML, Serato, Traktor, Engine DJ, Virtual DJ, iTunes XML
├── tagger.js            # Tag writing via node-taglib-sharp
├── renderer/
│   ├── index.html       # App shell — toolbar, drop zone, track table
│   ├── app.js           # UI logic — track state, column rendering, drag-drop
│   └── styles.css       # Black & white, monospace (matches Mac app aesthetic)
├── package.json
└── build/               # electron-builder output (.exe NSIS installer)
```

---

## Components

### main.js
- Creates `BrowserWindow` with `nodeIntegration: false`, `contextIsolation: true`
- `ipcMain` handlers:
  - `analyze-files` — receives file paths, spawns Worker threads (pool of 4)
  - `export-*` — opens save dialog, calls exporter, writes file
  - `write-tags` — calls tagger for selected files
  - `open-files` — opens file picker dialog, returns paths to renderer

### preload.js
- Exposes `window.keyfinder` API via `contextBridge`:
  - `openFiles()`, `analyzeFiles(paths)`, `exportCSV(tracks)`, `exportRekordbox(tracks)`, etc.
  - `onAnalysisProgress(cb)`, `onTrackResult(cb)` — event listeners for analysis updates

### worker.js
- Receives a file path via `workerData`
- Decodes audio using `@ffmpeg.wasm` or Node's `fs` + `essentia.js` Web Audio decoding path
- Runs essentia.js `KeyExtractor` (HPCP-based, same Krumhansl-Schmuckler profiles as Mac app)
- Runs essentia.js `RhythmExtractor2013` for BPM
- Generates a downsampled waveform array (500 points) for the mini waveform column
- Posts result back: `{ key, camelotNotation, bpm, duration, waveformData, error? }`

### renderer/app.js
- Tracks array in memory: `[{ id, fileName, filePath, albumArt, key, camelot, bpm, duration, waveform, status }]`
- Drop zone: listens for `dragover` / `drop`, filters to audio extensions, calls `window.keyfinder.analyzeFiles()`
- Track table: renders columns — ART | TRACK | KEY | CAMELOT | BPM | DUR | WAVEFORM
- Progress: per-row spinner while analyzing, green checkmark on completion, red error badge on failure
- Toolbar: Add Files button, Export menu, Clear All, search/filter input

### exporter.js
All 6 export formats from the Mac app, ported 1:1:
- CSV
- Rekordbox XML
- Serato CSV
- Traktor NML
- Engine DJ JSON
- Virtual DJ XML
- iTunes XML

### tagger.js
- Uses `node-taglib-sharp` to write key and BPM to ID3 (MP3), Vorbis comment (FLAC), or iTunes atom (M4A)
- Writes: `TKEY` (ID3 key), `TBPM` (ID3 BPM), comment field with Camelot notation

---

## UI Design

Matches the Mac app exactly:
- Black background (`#000`), white text (`#fff`)
- Monospace font (`Consolas`, `Courier New`, fallback `monospace`)
- Column order: ART | TRACK | KEY | CAMELOT | BPM | DUR | WAVEFORM
- Drop zone: dashed border, centered "Drop audio files here" text
- Toolbar: flat buttons, no gradients
- Row hover: subtle `#111` highlight

Waveform column: 80×24px canvas drawn from the 500-point array returned by the worker.

---

## Key npm Dependencies

| Package | Purpose |
|---|---|
| `electron` | App shell + cross-platform packaging |
| `essentia.js` | WASM audio analysis (key, BPM, chroma) |
| `music-metadata` | Read audio tags (title, artist, duration, album art) |
| `node-taglib-sharp` | Write key/BPM back to audio file tags |
| `electron-builder` | Build Windows NSIS `.exe` installer |

Audio decoding for essentia.js: use `ffmpeg-static` + `fluent-ffmpeg` to decode any audio format to raw PCM float32, which essentia.js consumes.

---

## Data Flow

```
User drops files
     ↓
renderer/app.js collects file paths
     ↓
window.keyfinder.analyzeFiles(paths) → IPC → main.js
     ↓
main.js spawns Worker per file (pool of 4 concurrent)
     ↓
worker.js: ffmpeg decode → PCM → essentia.js → result
     ↓
IPC progress event → renderer updates row
     ↓
All done → export / tag write available
```

---

## Export Flow

```
User clicks Export → toolbar menu
     ↓
window.keyfinder.exportXxx(tracks) → IPC → main.js
     ↓
main.js opens save dialog (dialog.showSaveDialog)
     ↓
exporter.js generates file content
     ↓
fs.writeFileSync to chosen path
```

---

## Error Handling

- Per-track errors shown inline in the table row (red status badge + tooltip with message)
- Unsupported formats: caught at file-drop time, filtered out with user notification
- ffmpeg decode failure: worker posts `{ error: "Could not decode file" }`
- essentia.js failure: worker catches and posts error
- No retry UI in v1 (can add in v2)

---

## Build & Release

```bash
cd keyfinder-windows
npm install
npm run build        # electron-builder → dist/KeyFinder-Setup-1.7.exe
```

`electron-builder` config in `package.json`:
- Target: NSIS (Windows installer)
- App ID: `com.keyfinder.app`
- Version: `1.7`
- Icon: same icon as Mac app (converted to `.ico`)

---

## Out of Scope (v1)

- Analysis result caching
- DJ presets / BPM filter bar
- Smart DJ harmonic mix generator
- Duplicate detection panel
- Camelot wheel view
- Beat grid / cue points views
- Audio preview player
- Key change timeline

---

## Success Criteria

- Drop audio files → key + BPM + waveform appear for each track
- All 6 export formats produce valid files matching Mac app output
- Tag writing works for MP3, FLAC, M4A
- `npm run build` produces a runnable Windows `.exe` installer
- UI matches Mac app's black & white monospace aesthetic
