'use strict';

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('keyfinder', {
  openFiles: () => ipcRenderer.invoke('open-files'),
  analyzeFiles: (filePaths) => ipcRenderer.invoke('analyze-files', filePaths),
  onTrackResult: (cb) => ipcRenderer.on('track-result', (_e, data) => cb(data)),
  exportCSV:       (tracks) => ipcRenderer.invoke('export-csv',       tracks),
  exportRekordbox: (tracks) => ipcRenderer.invoke('export-rekordbox', tracks),
  exportSerato:    (tracks) => ipcRenderer.invoke('export-serato',    tracks),
  exportTraktor:   (tracks) => ipcRenderer.invoke('export-traktor',   tracks),
  exportEngineDJ:  (tracks) => ipcRenderer.invoke('export-enginedj',  tracks),
  exportVirtualDJ: (tracks) => ipcRenderer.invoke('export-virtualdj', tracks),
  exportiTunes:    (tracks) => ipcRenderer.invoke('export-itunes',    tracks),
  writeTags:       (tracks) => ipcRenderer.invoke('write-tags',       tracks),
});
