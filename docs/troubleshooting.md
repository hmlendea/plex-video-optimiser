# Troubleshooting

## Common Issues

### "Cannot access '...': No such file or directory"
**Cause**: Input file path incorrect or file doesn't exist.
**Fix**: Verify path exists, use absolute path, quote paths with spaces.

### "mkvmerge: command not found" / "mkvinfo: command not found"
**Cause**: mkvtoolnix not installed.
**Fix**: Install mkvtoolnix package (see [build-and-deployment.md](./build-and-deployment.md)).

### "ffmpeg: command not found"
**Cause**: ffmpeg not installed.
**Fix**: Install ffmpeg package.

### "perl-rename: command not found"
**Cause**: perl-rename (prename) not installed.
**Fix**: Install `rename` (Debian/Ubuntu) or `perl-rename` (Arch) package.

### Subtitle extraction fails silently
**Cause**: No text-based subtitles (SRT/SSA) in file, or `ffmpeg` extraction error.
**Fix**: Check `mkvmerge -i` output — only SRT and SubStationAlpha are extracted. PGS/VobSub are skipped.

### Output file not created / empty
**Cause**: ffmpeg failed (codec not supported, disk full, permissions).
**Fix**: Run ffmpeg command manually from script output to see error.

### "No optimisation needed!" but file has AV1/VP9
**Cause**: `mkvmerge -i` didn't detect video track correctly, or video format string doesn't match "AV1"/"VP9" exactly.
**Fix**: Run `mkvmerge -i "file.mkv"` manually and check video format string.

### Audio tracks missing in output
**Cause**: All audio tracks were discardable (commentary, AC-3, E-AC-3, MP3, Opus, PCM) and no preferred format found.
**Fix**: Check `isAudioTrackDiscardable` logic — at least one track should be converted to AAC.

### TV episode loses audio tracks
**Cause**: Default behaviour for TV episodes (`KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false`).
**Fix**: Set `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true` in script.

### Forced/SDH subtitles not extracted
**Cause**: Default config discards them.
**Fix**: Set `KEEP_FORCED_SUBTITLES=true` and/or `KEEP_SDH_SUBTITLES=true` in script.

### Filename sanitisation removes too much
**Cause**: Aggressive regex patterns match legitimate title words.
**Fix**: Review sanitisation pipeline in [file-naming.md](./components/file-naming.md) — known issue with years in titles.

### Duplicate subtitle files not cleaned up
**Cause**: `replaceDuplicatedSubtitles` rules don't match your language variants.
**Fix**: Add custom rules to the hardcoded deduplication section in main flow.

### `fix-subtitle` not running
**Cause**: Binary not at `/usr/bin/fix-subtitle`.
**Fix**: Install fix-subtitle or symlink to `/usr/bin/fix-subtitle`.

### Session ID collision (concurrent runs)
**Cause**: Extremely unlikely (32-char alphanumeric), but possible.
**Fix**: Script uses `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1` — entropy is high.

### Output file larger than input
**Cause**: H.264 conversion from AV1/VP9 with default ffmpeg quality settings.
**Fix**: Consider adding `-crf` or `-b:v` to `getVideoFfmpegArgs` for quality control.

## Debugging Tips

### Enable Verbose Output
Add `set -x` at top of script for trace:
```bash
#!/bin/bash
set -x
```

### Inspect Intermediate Values
Add `echo` statements after key variable assignments:
```bash
echo "DEBUG: VIDEO_FORMAT=$VIDEO_FORMAT"
echo "DEBUG: AUDIO_TRACKS_COUNT=$AUDIO_TRACKS_COUNT"
```

### Run ffmpeg Manually
Copy the "ffmpeg arguments:" output and run:
```bash
ffmpeg -i "input.mkv" [COPIED_ARGS] "output.mkv"
```

### Check Track Detection
```bash
mkvmerge -i "file.mkv"
mkvinfo "file.mkv"
```

### Verify Output
```bash
mkvmerge -i "output.mkv"
ffprobe -show_streams "output.mkv"
```

## Known Limitations

1. **No config file** — must edit script to change options
2. **No CLI flags** — all options hardcoded
3. **No dry-run mode** — always prompts for confirmation
4. **No batch processing** — single file at a time
5. **No progress bar** — ffmpeg output only
6. **Hardcoded deduplication** — only handles specific language variants
7. **Year removal** — strips 19xx/20xx from filenames (may remove legitimate years)
8. **No test suite** — manual verification only
9. **Interactive only** — cannot automate in scripts
10. **Single-threaded** — no parallel processing