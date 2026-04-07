'use strict';

const TagLib = require('node-taglib-sharp');

/**
 * Write key and BPM tags to an audio file.
 * Uses node-taglib-sharp for cross-format tag writing.
 * Writes to the comment field for maximum format compatibility.
 */
async function writeTagsToFile(filePath, { key, bpm, camelot }) {
  let file;
  try {
    file = TagLib.File.createFromPath(filePath);
    if (!file || !file.isWritable) {
      throw new Error('File is not writable or not supported: ' + filePath);
    }

    const tag = file.tag;
    if (!tag) throw new Error('No tag found in file: ' + filePath);

    tag.comment = `Key: ${key} | Camelot: ${camelot} | BPM: ${bpm}`;

    file.save();
    return { success: true };
  } finally {
    if (file) file.dispose();
  }
}

module.exports = { writeTagsToFile };
