'use strict';

const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const { Worker } = require('worker_threads');
const fs = require('fs');
const { exportCSV, exportRekordbox, exportSerato, exportTraktor, exportEngineDJ, exportVirtualDJ, exportiTunes } = require('./exporter');
const { writeTagsToFile } = require('./tagger');
const { keyToCamelot, keyToShortName } = require('./camelot');

const WORKER_POOL_SIZE = 4;

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 750,
    minWidth: 900,
    minHeight: 600,
    backgroundColor: '#000000',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
    },
  });
  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });

// Open file dialog
ipcMain.handle('open-files', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: 'Add Audio Files',
    properties: ['openFile', 'multiSelections'],
    filters: [
      { name: 'Audio Files', extensions: ['mp3', 'wav', 'flac', 'm4a', 'aiff', 'aif', 'ogg'] },
      { name: 'All Files', extensions: ['*'] },
    ],
  });
  return result.canceled ? [] : result.filePaths;
});

// Analyze files with worker pool
ipcMain.handle('analyze-files', async (event, filePaths) => {
  const workerPath = path.join(__dirname, 'worker.js');
  for (let i = 0; i < filePaths.length; i += WORKER_POOL_SIZE) {
    const batch = filePaths.slice(i, i + WORKER_POOL_SIZE);
    await Promise.all(batch.map(fp => runWorker(workerPath, fp, event)));
  }
  return { done: true };
});

function runWorker(workerPath, filePath, event) {
  return new Promise((resolve) => {
    const worker = new Worker(workerPath, { workerData: { filePath } });
    worker.on('message', (result) => {
      if (result.success) {
        const camelot = keyToCamelot(result.keyName);
        const shortKey = keyToShortName(result.keyName);
        event.sender.send('track-result', {
          filePath: result.filePath,
          key: shortKey,
          camelot,
          bpm: result.bpm ? result.bpm.toFixed(1) : '',
          duration: result.duration,
          waveform: result.waveform,
          artist: result.artist,
          title: result.title,
          albumArtDataUrl: result.albumArtDataUrl,
        });
      } else {
        event.sender.send('track-result', { filePath: result.filePath, error: result.error });
      }
      resolve();
    });
    worker.on('error', (err) => {
      event.sender.send('track-result', { filePath, error: err.message });
      resolve();
    });
  });
}

// Export handlers
async function saveExport(tracks, generator, defaultName, filterName, ext) {
  const { canceled, filePath } = await dialog.showSaveDialog(mainWindow, {
    defaultPath: defaultName,
    filters: [{ name: filterName, extensions: [ext] }],
  });
  if (canceled || !filePath) return { saved: false };
  fs.writeFileSync(filePath, generator(tracks), 'utf8');
  return { saved: true, filePath };
}

ipcMain.handle('export-csv',       (_, t) => saveExport(t, exportCSV,       'keyfinder_export.csv',        'CSV',  'csv'));
ipcMain.handle('export-rekordbox', (_, t) => saveExport(t, exportRekordbox,  'rekordbox_export.xml',        'XML',  'xml'));
ipcMain.handle('export-serato',    (_, t) => saveExport(t, exportSerato,     'serato_export.csv',           'CSV',  'csv'));
ipcMain.handle('export-traktor',   (_, t) => saveExport(t, exportTraktor,    'collection_keyfinder.nml',    'NML',  'nml'));
ipcMain.handle('export-enginedj',  (_, t) => saveExport(t, exportEngineDJ,   'keyfinder_engine_db.json',    'JSON', 'json'));
ipcMain.handle('export-virtualdj', (_, t) => saveExport(t, exportVirtualDJ,  'keyfinder_vdj_database.xml',  'XML',  'xml'));
ipcMain.handle('export-itunes',    (_, t) => saveExport(t, exportiTunes,     'keyfinder_itunes.xml',        'XML',  'xml'));

// Write tags
ipcMain.handle('write-tags', async (_, tracks) => {
  const results = [];
  for (const track of tracks) {
    if (!track.key || !track.bpm) continue;
    try {
      await writeTagsToFile(track.filePath, { key: track.key, bpm: track.bpm, camelot: track.camelot || '' });
      results.push({ filePath: track.filePath, success: true });
    } catch (err) {
      results.push({ filePath: track.filePath, success: false, error: err.message });
    }
  }
  return results;
});
