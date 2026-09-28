# Tag Writing

KeyFinder now includes Traktor-focused ID3 tag writing for MP3 files.

## Defaults
- ID3 v2.3 writes by default (v2.4 model support included).
- COMM comment template: `[KeyCamelot] [BPM] BPM`
- Additional writes to `TKEY` and `TXXX:MIXEDINKEY`

## Safety
- Dry-run preview before write.
- Atomic replacement (`temp -> replaceItemAt`) to avoid corruption.
- Preserves existing non-target frames (e.g. Artist/Album/Title, artwork) while updating mapped targets.
- Backup store in `~/.config/keyfinder/keyfinder_tag_backup.json`.
- Batch undo supported by batch UUID.

## Template Tokens
`[KeyCamelot]`, `[KeyOpen]`, `[KeyTraditional]`, `[BPM]`, `[Energy]`, `[Title]`, `[Artist]`, `[Album]`, `[Year]`, `[Filename]`, `[Filepath]`, `[TrackNumber]`, `[Custom:<descriptor>]`.

Escaping: `\[` and `\]`.

## Modes
- `overwrite`
- `append`
- `prepend`
- `onlyIfEmpty`

## CLI flags
- `--write-tags`
- `--dry-run`
- `--template`
- `--field`
- `--mode`
- `--backup-path`

## UI policy profiles
- Conservative (Key only): write only missing key fields
- Overwrite Key + BPM: replace existing key/bpm with analyzed values
- Dual-Key Traktor: keep Traktor key column, write KeyFinder key to comment/TXXX
- Title Prefix Sort: prepend `[Key]-[BPM]-[Title]` style data for playlist sorting

Each mapping row exposes: target frame, template, and mode (`overwrite`, `append`, `prepend`, `onlyIfEmpty`).
