# Invariants

## System-Wide Invariants

### File Safety
1. **Original file never modified without explicit user confirmation** — two prompts required
2. **Temp files use unique SESSION_ID** — prevents collision on concurrent runs
3. **Output written to temp file first** — atomic rename on confirmation

### Video Processing
4. **Only AV1 and VP9 trigger video transcoding** — all other codecs copied
5. **Video transcoding target is always H.264** — no other output codec
6. **Video track index always 0** — assumes single video track

### Audio Processing
7. **At least one audio track in output** — primary track guaranteed
8. **Primary audio track always AAC or MP3** — copied or converted
9. **Commentary tracks never preserved** — dropped in all cases
10. **Discardable formats never preserved as additional tracks** — AC-3, E-AC-3, MP3, Opus, PCM dropped
11. **TV episodes: only primary track by default** — unless `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true`

### Subtitle Processing
12. **Only text subtitles (SRT, SubStationAlpha) extracted** — PGS/VobSub ignored
13. **Forced/SDH subtitles discarded by default** — opt-in via config
14. **Language detection: name-based first, metadata fallback** — 35 languages supported
15. **Deduplication rules hardcoded** — specific to common release patterns
16. **Output: one .srt per unique language** — canonical 3-letter codes

### Container Processing
17. **Non-MKV or non-Matroska input → remux to MKV** — all streams copied
18. **Subtitles always removed from video output** — `-map -0:s` when any exist

### Filename Sanitisation
19. **Output always .mkv extension** — forced regardless of input
20. **Output in same directory as input** — preserves location
21. **TV episode pattern normalised to SxxExx** — uppercase S, E
22. **Release metadata stripped** — groups, quality, codecs, sources removed

### Execution Model
23. **Single-threaded, synchronous** — no parallelism
24. **Interactive** — requires user confirmation at two points
25. **Idempotent-ish** — re-running on optimised file reports "No optimisation needed"

## Contracts

### Between Track Inspection and Decision Logic
- `getVideoTrackFormat` returns exact mkvmerge codec string
- `getAudioTrackFormat` returns exact mkvmerge codec string
- `getSubtitleLanguage` returns 3-letter code or empty

### Between Decision Logic and FFmpeg Construction
- `getVideoFfmpegArgs` returns empty or valid `-map -c:v` args
- `getAudioFfmpegArgs` returns empty or valid `-map -c:a` args
- Empty = "no modifications needed" → copy all

### Between Main Flow and User
- All decisions displayed before first confirmation
- Size comparison shown after optimisation
- Output track structure shown via `mkvmerge -i`

## Assumptions

| Assumption | Risk if Violated |
|------------|------------------|
| Single video track | Multi-video files: only first processed |
| mkvmerge/mkvinfo output format stable | Version changes break parsing |
| ffmpeg supports H.264 encoding | Missing encoder → conversion fails |
| perl-rename available | Subtitle rename fails |
| /dev/urandom readable | Session ID generation fails |
| User has write permission in input dir | Temp file creation fails |
| No concurrent runs on same file | SESSION_ID collision (extremely unlikely) |