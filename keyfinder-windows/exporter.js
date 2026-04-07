'use strict';

function escapeXML(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function isoNow() {
  return new Date().toISOString();
}

function exportCSV(tracks) {
  let csv = 'Filename,Key,Camelot,BPM,File Path\n';
  for (const t of tracks) {
    if (!t.key) continue;
    const filename = (t.fileName || '').replace(/,/g, ';');
    const path = (t.filePath || '').replace(/,/g, ';');
    csv += `${filename},${t.key || ''},${t.camelot || ''},${t.bpm || ''},${path}\n`;
  }
  return csv;
}

function exportRekordbox(tracks) {
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
  xml += '<DJ_PLAYLISTS Version="1.0.0">\n  <COLLECTION>\n';
  for (const t of tracks) {
    if (!t.key || !t.bpm) continue;
    const loc = 'file://localhost/' + (t.filePath || '').replace(/\\/g, '/');
    xml += `    <TRACK TrackID="${escapeXML(t.id)}" Name="${escapeXML(t.fileName)}" `;
    xml += `Artist="${escapeXML(t.artist || '')}" AverageBpm="${escapeXML(t.bpm)}" `;
    xml += `Location="${escapeXML(loc)}" Tonality="${escapeXML(t.key)}"/>\n`;
  }
  xml += '  </COLLECTION>\n</DJ_PLAYLISTS>\n';
  return xml;
}

function exportSerato(tracks) {
  let csv = 'File Path,Key,BPM,Camelot\n';
  for (const t of tracks) {
    if (!t.key || !t.bpm) continue;
    csv += `"${t.filePath}","${t.key}","${t.bpm}","${t.camelot || ''}"\n`;
  }
  return csv;
}

function exportTraktor(tracks) {
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n<NML VERSION="19">\n  <COLLECTION>\n';
  for (const t of tracks) {
    if (!t.key || !t.bpm) continue;
    const bpm = parseFloat(t.bpm) || 120;
    const dur = Math.round((t.duration || 0) * 1000);
    xml += `    <ENTRY Title="${escapeXML(t.title || t.fileName)}" Artist="${escapeXML(t.artist || '')}">\n`;
    xml += `      <LOCATION File="${escapeXML(t.fileName)}" Dir="${escapeXML((t.filePath || '').replace(/\\/g, '/'))}"/>\n`;
    xml += `      <INFO BPM="${bpm.toFixed(2)}" DUR="${dur}"/>\n`;
    xml += `      <TEMPO Bpm="${bpm.toFixed(2)}" Type="0"/>\n`;
    xml += `    </ENTRY>\n`;
  }
  xml += '  </COLLECTION>\n</NML>\n';
  return xml;
}

function exportEngineDJ(tracks) {
  const arr = [];
  for (const t of tracks) {
    if (!t.key || !t.bpm) continue;
    arr.push({
      path: t.filePath,
      filename: t.fileName,
      title: t.title || t.fileName,
      artist: t.artist || '',
      genre: t.genre || '',
      year: t.year || '',
      bpm: parseFloat(t.bpm) || 0,
      key: t.key,
      camelot: t.camelot || '',
      duration: t.duration || 0,
    });
  }
  return JSON.stringify({ version: '1.0', exportDate: isoNow(), trackCount: arr.length, tracks: arr }, null, 2);
}

function exportVirtualDJ(tracks) {
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n<VDJ DatabaseVersion="8.0">\n  <Songs>\n';
  for (const t of tracks) {
    if (!t.key || !t.bpm) continue;
    const dur = Math.round((t.duration || 0) * 1000);
    xml += `    <Song Id="${escapeXML(t.id)}">\n`;
    xml += `      <FilePath>${escapeXML(t.filePath)}</FilePath>\n`;
    xml += `      <Title>${escapeXML(t.title || t.fileName)}</Title>\n`;
    xml += `      <Artist>${escapeXML(t.artist || '')}</Artist>\n`;
    xml += `      <Length>${dur}</Length>\n`;
    xml += `      <Bpm>${escapeXML(t.bpm)}</Bpm>\n`;
    xml += `      <Tonality>${escapeXML(t.key)}</Tonality>\n`;
    xml += `    </Song>\n`;
  }
  xml += '  </Songs>\n</VDJ>\n';
  return xml;
}

function exportiTunes(tracks) {
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
  xml += '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n';
  xml += '<plist version="1.0">\n<dict>\n';
  xml += `  <key>Date</key><date>${isoNow()}</date>\n`;
  xml += '  <key>Tracks</key>\n  <dict>\n';
  for (const t of tracks) {
    if (!t.key || !t.bpm) continue;
    const trackId = Math.abs(hashCode(t.filePath || t.id));
    const durMs = Math.round((t.duration || 0) * 1000);
    xml += `    <key>${trackId}</key>\n    <dict>\n`;
    xml += `      <key>Track ID</key><integer>${trackId}</integer>\n`;
    xml += `      <key>Name</key><string>${escapeXML(t.title || t.fileName)}</string>\n`;
    xml += `      <key>Artist</key><string>${escapeXML(t.artist || '')}</string>\n`;
    xml += `      <key>Total Time</key><integer>${durMs}</integer>\n`;
    xml += `      <key>BPM</key><integer>${Math.round(parseFloat(t.bpm) || 0)}</integer>\n`;
    xml += `      <key>Comments</key><string>Key: ${escapeXML(t.key)} | Camelot: ${escapeXML(t.camelot || '')}</string>\n`;
    xml += `    </dict>\n`;
  }
  xml += '  </dict>\n</dict>\n</plist>\n';
  return xml;
}

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0;
  }
  return hash;
}

module.exports = { exportCSV, exportRekordbox, exportSerato, exportTraktor, exportEngineDJ, exportVirtualDJ, exportiTunes };
