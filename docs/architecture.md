# Architecture

## Overview

plex-video-optimiser is a single-file Bash script (`plex-video-optimiser.sh`) that implements a linear, sequential pipeline for video file optimisation. There is no modular decomposition into separate files — all logic resides in one script with function definitions at the top and main execution flow at the bottom.

## High-Level Pipeline

```
Input File
    │
    ▼
File Validation & Metadata Extraction
    │
    ▼
Track Analysis (Video, Audio, Subtitles)
    │
    ▼
Decision Engine (what needs conversion)
    │
    ▼
FFmpeg Argument Construction
    │
    ▼
User Confirmation
    │
    ▼
Optimisation Execution (ffmpeg)
    │
    ▼
Subtitle Extraction & Post-Processing (optional)
    │
    ▼
Output Verification & Replacement Prompt
    │
    ▼
Final Output
```

## Component Responsibilities

| Component | Location | Responsibility |
|-----------|----------|----------------|
| File validation | Lines 1-10 | Verify input file exists |
| Metadata extraction | Lines 11-30 | Parse filename, extension, directory, session ID |
| File naming | Lines 31-65 | Sanitise output filename, detect TV show episodes |
| Track inspection | Lines 67-200 | Query mkvmerge/mkvinfo for track formats, names, languages |
| Video processing | Lines 202-210 | Detect AV1/VP9, generate H.264 conversion args |
| Audio processing | Lines 212-270 | Select preferred tracks, convert to AAC, preserve originals |
| Subtitle processing | Lines 272-380 | Language detection, forced/SDH filtering, deduplication |
| FFmpeg orchestration | Lines 382-450 | Combine args, handle container conversion, execute |
| User interaction | Lines 452-520 | Confirmations, progress display, replacement prompt |

## Data Flow

### Input Data
- **File path** (positional argument)
- **Environment**: `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS`, `KEEP_FORCED_SUBTITLES`, `KEEP_SDH_SUBTITLES` (hardcoded defaults)

### Intermediate State
- `FILE_PATH`, `FILE_NAME`, `FILE_EXTENSION`, `FILE_DIRECTORY`
- `SESSION_ID` (32-char random for temp file isolation)
- `IS_TVSHOW_EPISODE` (boolean from SxxExx pattern)
- `CONTAINER_FORMAT` (from mkvmerge)
- `VIDEO_FORMAT` (from mkvmerge)
- `AUDIO_TRACKS_COUNT`, `SUBTITLE_TRACKS_COUNT`
- Per-track: format, name, language
- `IS_OPTIMISABLE` (boolean flag)
- `FFMPEG_ARGUMENTS` (constructed string)
- `SUBTITLES_FFMPEG_ARGUMENTS` (for extraction)

### Output Data
- Optimised MKV file (`{name}.OPTIMISED.mkv` → `{name}.mkv`)
- Extracted subtitle files (`{name}.{LANG}.srt`)
- Console output (progress, decisions, sizes)

## External Dependencies

| Tool | Purpose | Invocation |
|------|---------|------------|
| `mkvmerge` | Container/track inspection | `mkvmerge -i "$FILE_PATH"` |
| `mkvinfo` | Detailed track metadata | `mkvinfo "$FILE_PATH"` |
| `ffmpeg` | Transcoding/remuxing | `ffmpeg -i "$FILE_PATH" $ARGS "$OUTPUT"` |
| `perl-rename` | Batch rename extracted subtitles | `perl-rename 's/.../.../g' "$DIR"/*` |
| `fix-subtitle` | Subtitle post-processing | `fix-subtitle --noconfirm "$FILE"` |
| `iconv` | Filename transliteration | `iconv -f utf-8 -t ascii//translit` |
| `du` | File size reporting | `du -sh "$FILE"` |

## Execution Model

- **Single-threaded, synchronous** — no background jobs, no parallelism
- **Interactive** — requires user confirmation at two points
- **Transactional** — writes to temp file, only replaces original on explicit confirmation
- **Idempotent-ish** — re-running on already-optimised file reports "No optimisation needed"

## Key Invariants

1. **Original file never modified until explicit user confirmation**
2. **Temp files use unique SESSION_ID to avoid collisions**
3. **Only text-based subtitles (SRT, SubStationAlpha) are extracted**
4. **Video conversion only for AV1/VP9 → H.264; everything else copied**
5. **Audio preference order: AAC/MP3 (copy) → first non-commentary (convert to AAC) → preserve originals for movies**
6. **TV show episodes: by default only keep first compatible audio track unless `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true`**