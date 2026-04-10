# Traktor Setup Quick Guide

1. Analyze tracks in KeyFinder.
2. Open **Export > Write Tags to Files**.
3. Review generated dry-run report (`keyfinder_tag_write_result.txt`).
4. Confirm tags were written.
5. In Traktor, refresh/re-import tracks so cached values update.
6. Verify `Comment` / `Key` columns and optional custom fields.

Recommended mapping:
- `COMM` = `[KeyCamelot] [BPM] BPM`
- `TKEY` = `[KeyTraditional]`
- `TXXX:MIXEDINKEY` = `[KeyCamelot]`
