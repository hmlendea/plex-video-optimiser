# Repository Structure

## Source Tree

```
plex-video-optimiser/
├── .github/
│   └── workflows/
│       └── bash.yml              # Shellcheck CI workflow
├── docs/                         # Documentation (generated)
│   ├── INDEX.md                  # Master index
│   ├── architecture.md           # High-level architecture
│   ├── repository-overview.md    # This file's parent overview
│   ├── repository-structure.md   # This file
│   ├── components/               # Per-component deep dives
│   │   ├── video-processing.md
│   │   ├── audio-processing.md
│   │   ├── subtitle-processing.md
│   │   └── file-naming.md
│   ├── flows/                    # End-to-end execution flows
│   │   ├── main-execution.md
│   │   └── subtitle-extraction.md
│   ├── api-reference/            # Function reference
│   │   ├── INDEX.md
│   │   ├── core-functions.md
│   │   ├── track-functions.md
│   │   └── ffmpeg-functions.md
│   └── ... (other cross-cutting docs)
├── LICENSE                       # GNU GPL v3
├── README.md                     # Project homepage
└── plex-video-optimiser.sh       # Main script (single file, ~550 lines)
```

## Script Internal Structure

`plex-video-optimiser.sh` is organised as follows:

| Line Range | Section | Description |
|------------|---------|-------------|
| 1-10 | Shebang & Input Validation | `#!/bin/bash`, file existence check |
| 11-30 | Configuration & Metadata | Hardcoded options, path parsing, session ID |
| 31-65 | File Naming & TV Detection | Sanitisation pipeline, SxxExx detection |
| 67-200 | Track Inspection Functions | `getVideoTrackFormat`, `getAudioTrackFormat`, `getAudioTrackName`, `getSubtitleTrackName`, `getTrackName`, `getTrackLanguage`, `getFirstTrackType` |
| 202-210 | Video FFmpeg Args | `getVideoFfmpegArgs` — AV1/VP9 → H.264 |
| 212-270 | Audio FFmpeg Args | `getAudioFfmpegArgs` — track selection, conversion |
| 272-310 | Subtitle Helpers | `isSubtitleTrackDiscardable`, `doesTrackNameMatch`, `getSubtitleLanguage`, `replaceDuplicatedSubtitles` |
| 312-380 | Main Analysis | Container/video/audio detection, track enumeration |
| 382-450 | FFmpeg Construction | Combine video/audio/subtitle args, handle container conversion |
| 452-520 | Subtitle Extraction | Interactive extraction, language deduplication, post-processing |
| 522-570 | Optimisation Execution | User confirmation, ffmpeg run, size comparison, replacement prompt |

## Module Organisation

**No modules** — single file with function definitions followed by main execution. Functions are grouped by concern:

1. **Track inspection** (7 functions) — query mkvmerge/mkvinfo
2. **Video processing** (1 function) — codec conversion decision
3. **Audio processing** (4 functions) — format check, commentary detection, discard logic, arg generation
4. **Subtitle processing** (5 functions) — discard logic, name matching, language detection, deduplication
5. **Main flow** — inline, not function-wrapped

## Configuration Location

Hardcoded at script top (lines 13-15):
```bash
KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false
KEEP_FORCED_SUBTITLES=false
KEEP_SDH_SUBTITLES=false
```

No external config file, no CLI flags, no environment variable support.

## Build Artifacts

None — interpreted Bash script. CI only runs shellcheck.

## Test Files

None present in repository. No test directory, no test framework.