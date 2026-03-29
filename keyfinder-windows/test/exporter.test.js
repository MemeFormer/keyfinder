const { exportCSV, exportRekordbox, exportSerato, exportTraktor, exportEngineDJ, exportVirtualDJ, exportiTunes } = require('../exporter');

const TRACKS = [
  {
    id: 'abc-123',
    fileName: 'test track.mp3',
    filePath: 'C:\\Music\\test track.mp3',
    key: 'Am',
    camelot: '8A',
    bpm: '128.0',
    duration: 240.5,
    artist: 'Test Artist',
    title: 'Test Title',
    genre: 'Techno',
    year: '2024',
  }
];

test('exportCSV contains header and track data', () => {
  const csv = exportCSV(TRACKS);
  expect(csv).toContain('Filename,Key,Camelot,BPM');
  expect(csv).toContain('test track.mp3');
  expect(csv).toContain('Am');
  expect(csv).toContain('8A');
  expect(csv).toContain('128.0');
});

test('exportRekordbox produces valid XML with track', () => {
  const xml = exportRekordbox(TRACKS);
  expect(xml).toContain('<?xml');
  expect(xml).toContain('DJ_PLAYLISTS');
  expect(xml).toContain('Tonality="Am"');
  expect(xml).toContain('AverageBpm="128.0"');
});

test('exportSerato contains file path and key', () => {
  const csv = exportSerato(TRACKS);
  expect(csv).toContain('File Path');
  expect(csv).toContain('Am');
  expect(csv).toContain('8A');
});

test('exportTraktor produces NML XML', () => {
  const xml = exportTraktor(TRACKS);
  expect(xml).toContain('NML');
  expect(xml).toContain('COLLECTION');
});

test('exportEngineDJ produces valid JSON', () => {
  const json = exportEngineDJ(TRACKS);
  const parsed = JSON.parse(json);
  expect(parsed.tracks).toHaveLength(1);
  expect(parsed.tracks[0].key).toBe('Am');
  expect(parsed.tracks[0].bpm).toBe(128.0);
});

test('exportVirtualDJ produces XML with song', () => {
  const xml = exportVirtualDJ(TRACKS);
  expect(xml).toContain('VDJ');
  expect(xml).toContain('Tonality');
  expect(xml).toContain('Am');
});

test('exportiTunes produces plist XML', () => {
  const xml = exportiTunes(TRACKS);
  expect(xml).toContain('plist');
  expect(xml).toContain('Am');
});

test('exportCSV escapes commas in filenames', () => {
  const tracks = [{ ...TRACKS[0], fileName: 'track,with,commas.mp3' }];
  const csv = exportCSV(tracks);
  expect(csv).toContain('track;with;commas.mp3');
});
