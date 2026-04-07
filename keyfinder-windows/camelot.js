'use strict';

const CAMELOT = {
  'C Major':    { camelot: '8B',  short: 'C'   },
  'C# Major':   { camelot: '3B',  short: 'C#'  },
  'D Major':    { camelot: '10B', short: 'D'   },
  'D# Major':   { camelot: '5B',  short: 'D#'  },
  'E Major':    { camelot: '12B', short: 'E'   },
  'F Major':    { camelot: '7B',  short: 'F'   },
  'F# Major':   { camelot: '2B',  short: 'F#'  },
  'G Major':    { camelot: '9B',  short: 'G'   },
  'G# Major':   { camelot: '4B',  short: 'G#'  },
  'A Major':    { camelot: '11B', short: 'A'   },
  'A# Major':   { camelot: '6B',  short: 'A#'  },
  'B Major':    { camelot: '1B',  short: 'B'   },
  'C Minor':    { camelot: '5A',  short: 'Cm'  },
  'C# Minor':   { camelot: '12A', short: 'C#m' },
  'D Minor':    { camelot: '7A',  short: 'Dm'  },
  'D# Minor':   { camelot: '2A',  short: 'D#m' },
  'E Minor':    { camelot: '9A',  short: 'Em'  },
  'F Minor':    { camelot: '4A',  short: 'Fm'  },
  'F# Minor':   { camelot: '11A', short: 'F#m' },
  'G Minor':    { camelot: '6A',  short: 'Gm'  },
  'G# Minor':   { camelot: '1A',  short: 'G#m' },
  'A Minor':    { camelot: '8A',  short: 'Am'  },
  'A# Minor':   { camelot: '3A',  short: 'A#m' },
  'B Minor':    { camelot: '10A', short: 'Bm'  },
};

function keyToCamelot(keyName) {
  return CAMELOT[keyName]?.camelot ?? '';
}

function keyToShortName(keyName) {
  return CAMELOT[keyName]?.short ?? '';
}

module.exports = { keyToCamelot, keyToShortName, CAMELOT };
