'use strict';

let tracks = [];
let searchQuery = '';

const dropZone     = document.getElementById('drop-zone');
const tableWrapper = document.getElementById('table-wrapper');
const tbody        = document.getElementById('track-tbody');
const btnAddFiles  = document.getElementById('btn-add-files');
const btnExport    = document.getElementById('btn-export');
const btnClear     = document.getElementById('btn-clear');
const exportDrop   = document.getElementById('export-dropdown');
const searchInput  = document.getElementById('search-input');
const trackCount   = document.getElementById('track-count');
const statusText   = document.getElementById('status-text');

function formatDuration(seconds) {
  if (!seconds) return '--:--';
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

function generateId() {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

function setStatus(msg) { statusText.textContent = msg; }

function filteredTracks() {
  if (!searchQuery) return tracks;
  const q = searchQuery.toLowerCase();
  return tracks.filter(t =>
    (t.fileName || '').toLowerCase().includes(q) ||
    (t.key || '').toLowerCase().includes(q) ||
    (t.camelot || '').toLowerCase().includes(q) ||
    (t.artist || '').toLowerCase().includes(q) ||
    (t.title || '').toLowerCase().includes(q)
  );
}

function renderTable() {
  const visible = filteredTracks();
  const hasTracks = tracks.length > 0;
  dropZone.classList.toggle('hidden', hasTracks);
  tableWrapper.classList.toggle('hidden', !hasTracks);

  const analyzedCount = tracks.filter(t => t.key).length;
  btnExport.disabled = analyzedCount === 0;
  btnClear.disabled = !hasTracks;
  trackCount.textContent = hasTracks ? `${analyzedCount}/${tracks.length}` : '';

  tbody.innerHTML = '';
  for (const t of visible) {
    const tr = document.createElement('tr');

    // ART
    const tdArt = document.createElement('td');
    tdArt.className = 'col-art';
    if (t.albumArtDataUrl) {
      const img = document.createElement('img');
      img.src = t.albumArtDataUrl;
      img.className = 'track-art';
      tdArt.appendChild(img);
    } else {
      const ph = document.createElement('div');
      ph.className = 'art-placeholder';
      ph.textContent = '♪';
      tdArt.appendChild(ph);
    }
    tr.appendChild(tdArt);

    // TRACK
    const tdTrack = document.createElement('td');
    tdTrack.className = 'col-track';
    const nameEl = document.createElement('div');
    nameEl.className = 'track-name';
    nameEl.textContent = t.title || t.fileName;
    tdTrack.appendChild(nameEl);
    if (t.artist) {
      const artistEl = document.createElement('div');
      artistEl.className = 'track-artist';
      artistEl.textContent = t.artist;
      tdTrack.appendChild(artistEl);
    }
    tr.appendChild(tdTrack);

    // KEY
    const tdKey = document.createElement('td');
    tdKey.className = 'col-key cell-key';
    if (t.status === 'analyzing') {
      tdKey.innerHTML = '<span class="status-analyzing">···</span>';
    } else if (t.error) {
      tdKey.innerHTML = `<span class="status-error" title="${t.error}">ERR</span>`;
    } else {
      tdKey.textContent = t.key || '';
    }
    tr.appendChild(tdKey);

    // CAMELOT
    const tdCamelot = document.createElement('td');
    tdCamelot.className = 'col-camelot cell-camelot';
    tdCamelot.textContent = t.status === 'done' ? (t.camelot || '') : '';
    tr.appendChild(tdCamelot);

    // BPM
    const tdBpm = document.createElement('td');
    tdBpm.className = 'col-bpm';
    tdBpm.textContent = t.status === 'done' ? (t.bpm || '') : '';
    tr.appendChild(tdBpm);

    // DUR
    const tdDur = document.createElement('td');
    tdDur.className = 'col-dur cell-dur';
    tdDur.textContent = t.duration ? formatDuration(t.duration) : '';
    tr.appendChild(tdDur);

    // WAVEFORM
    const tdWave = document.createElement('td');
    tdWave.className = 'col-waveform';
    if (t.waveform && t.waveform.length > 0) {
      const canvas = document.createElement('canvas');
      canvas.width = 84;
      canvas.height = 24;
      canvas.className = 'waveform';
      drawWaveform(canvas, t.waveform);
      tdWave.appendChild(canvas);
    }
    tr.appendChild(tdWave);

    tbody.appendChild(tr);
  }
}

function drawWaveform(canvas, waveform) {
  const ctx = canvas.getContext('2d');
  const w = canvas.width;
  const h = canvas.height;
  ctx.clearRect(0, 0, w, h);
  ctx.fillStyle = '#555';
  const barW = w / waveform.length;
  for (let i = 0; i < waveform.length; i++) {
    const barH = Math.max(1, waveform[i] * h);
    ctx.fillRect(i * barW, (h - barH) / 2, Math.max(1, barW - 0.5), barH);
  }
}

async function addFiles(filePaths) {
  const audioExts = new Set(['mp3', 'wav', 'flac', 'm4a', 'aiff', 'aif', 'ogg']);
  const existingPaths = new Set(tracks.map(t => t.filePath));
  const newPaths = filePaths.filter(fp => {
    const ext = fp.split('.').pop().toLowerCase();
    return audioExts.has(ext) && !existingPaths.has(fp);
  });
  if (newPaths.length === 0) return;

  for (const fp of newPaths) {
    const fileName = fp.replace(/\\/g, '/').split('/').pop();
    tracks.push({ id: generateId(), filePath: fp, fileName, status: 'analyzing' });
  }

  renderTable();
  setStatus(`Analyzing ${newPaths.length} file(s)...`);
  await window.keyfinder.analyzeFiles(newPaths);
}

btnAddFiles.addEventListener('click', async () => {
  const filePaths = await window.keyfinder.openFiles();
  if (filePaths.length > 0) await addFiles(filePaths);
});

btnClear.addEventListener('click', () => {
  tracks = [];
  renderTable();
  setStatus('READY');
});

document.addEventListener('dragover', (e) => { e.preventDefault(); dropZone.classList.add('drag-over'); });
document.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
document.addEventListener('drop', async (e) => {
  e.preventDefault();
  dropZone.classList.remove('drag-over');
  const filePaths = Array.from(e.dataTransfer.files).map(f => f.path);
  if (filePaths.length > 0) await addFiles(filePaths);
});

window.keyfinder.onTrackResult((result) => {
  const track = tracks.find(t => t.filePath === result.filePath);
  if (!track) return;
  if (result.error) {
    track.status = 'error';
    track.error = result.error;
  } else {
    track.status = 'done';
    track.key = result.key;
    track.camelot = result.camelot;
    track.bpm = result.bpm;
    track.duration = result.duration;
    track.waveform = result.waveform;
    track.artist = result.artist;
    track.title = result.title;
    track.albumArtDataUrl = result.albumArtDataUrl;
  }
  const done = tracks.filter(t => t.status !== 'analyzing').length;
  setStatus(done < tracks.length ? `Analyzing... ${done}/${tracks.length}` : `Done — ${tracks.filter(t => t.key).length} analyzed`);
  renderTable();
});

searchInput.addEventListener('input', (e) => {
  searchQuery = e.target.value.trim();
  renderTable();
});

btnExport.addEventListener('click', (e) => {
  e.stopPropagation();
  exportDrop.classList.toggle('hidden');
});

document.addEventListener('click', () => exportDrop.classList.add('hidden'));

exportDrop.addEventListener('click', async (e) => {
  const btn = e.target.closest('[data-export]');
  if (!btn) return;
  exportDrop.classList.add('hidden');
  const exportable = tracks.filter(t => t.key);
  if (exportable.length === 0) return;
  const type = btn.dataset.export;

  if (type === 'tags') {
    setStatus('Writing tags...');
    const results = await window.keyfinder.writeTags(exportable);
    const ok = results.filter(r => r.success).length;
    setStatus(`Tags written to ${ok}/${results.length} files`);
    return;
  }

  const exportFns = {
    csv:       window.keyfinder.exportCSV,
    rekordbox: window.keyfinder.exportRekordbox,
    serato:    window.keyfinder.exportSerato,
    traktor:   window.keyfinder.exportTraktor,
    enginedj:  window.keyfinder.exportEngineDJ,
    virtualdj: window.keyfinder.exportVirtualDJ,
    itunes:    window.keyfinder.exportiTunes,
  };

  const fn = exportFns[type];
  if (!fn) return;
  const result = await fn(exportable);
  if (result && result.saved) setStatus(`Exported to ${result.filePath}`);
});

renderTable();
setStatus('READY');
