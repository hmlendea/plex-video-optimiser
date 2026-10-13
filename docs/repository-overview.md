# Repository Overview

## Purpose

This repository contains **plex-video-optimiser**, a command-line tool that prepares video files for optimal direct-stream playback on Plex Media Server running on Raspberry Pi hardware.

## Scope

### In Scope
- Single Bash script (`plex-video-optimiser.sh`) — the entire application
- GitHub Actions workflow for shellcheck linting (`.github/workflows/bash.yml`)
- Documentation under `docs/`
- Standard repository files (README.md, LICENSE)

### Out of Scope
- No GUI, no daemon, no server component
- No configuration file (options are hardcoded constants)
- No plugin system or extensibility
- No support for non-MKV input (will convert but with limitations)

## Entry Points

### Primary
```bash
./plex-video-optimiser.sh "/path/to/video.mkv"
```
- Single positional argument: input file path
- Interactive prompts for confirmation
- Exit codes: 0 (success), 1 (file not found), other (ffmpeg/mkvtoolnix failures)

### Secondary (Environment Variables)
The script reads no environment variables. Configuration options are hardcoded at the top:
```bash
KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false
KEEP_FORCED_SUBTITLES=false
KEEP_SDH_SUBTITLES=false
```

## Target Environment

- **Runtime**: Bash 4+, Linux/macOS
- **Required tools**: `mkvmerge`, `mkvinfo` (mkvtoolnix), `ffmpeg`, `perl-rename` (optional), `fix-subtitle` (optional), `iconv`, `du`
- **Target playback**: Plex on Raspberry Pi (direct stream, no transcoding)

## Repository Structure

```
plex-video-optimiser/
├── .github/
│   └── workflows/
│       └── bash.yml          # Shellcheck CI
├── docs/                     # Generated documentation
│   ├── INDEX.md
│   ├── architecture.md
│   ├── repository-overview.md
│   ├── repository-structure.md
│   ├── components/
│   ├── flows/
│   ├── api-reference/
│   └── ...
├── LICENSE                   # GNU GPL v3
├── README.md                 # Project description, badges
└── plex-video-optimiser.sh   # Main script (≈550 lines)
```

## Version History

- **v1.6.0** (latest tag) — README badge fix
- **v1.5.0** — File naming improvements
- **v1.4.0** — File naming, subtitle improvements
- Earlier: iterative subtitle language support, provider name stripping

## License

GNU General Public License v3.0 — see [LICENSE](../LICENSE)