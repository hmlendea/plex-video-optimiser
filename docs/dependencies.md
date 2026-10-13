# Dependencies

## External Dependencies

### Required (Script fails without)

| Tool | Package | Version Tested | Purpose |
|------|---------|----------------|---------|
| `bash` | bash | 4.4+ | Script interpreter |
| `mkvmerge` | mkvtoolnix | 50+ | Container/track inspection |
| `mkvinfo` | mkvtoolnix | 50+ | Detailed track metadata |
| `ffmpeg` | ffmpeg | 4.4+ | Transcoding, remuxing, extraction |
| `perl-rename` | rename / perl-rename | 1.9+ | Batch rename extracted subtitles |
| `iconv` | libc-bin / glibc | 2.31+ | Filename transliteration |
| `du` | coreutils | 8.30+ | File size reporting |
| `grep` | grep | 3.4+ | Pattern matching |
| `sed` | sed | 4.7+ | Text transformation |
| `awk` | gawk | 5.0+ | Field extraction |
| `cat`, `tr`, `fold`, `head`, `tail`, `wc` | coreutils | Standard | Text processing |

### Optional (Graceful degradation)

| Tool | Package | Purpose | Fallback |
|------|---------|---------|----------|
| `fix-subtitle` | External | Subtitle post-processing | Skipped if not at `/usr/bin/fix-subtitle` |

## Dependency Graph

```
plex-video-optimiser.sh
    │
    ├── mkvmerge ──► Container format, track list, codec detection
    │
    ├── mkvinfo ──► Track names, languages (detailed)
    │
    ├── ffmpeg ──► Transcoding (AV1/VP9→H.264, audio→AAC)
    │              Remuxing (container conversion)
    │              Subtitle extraction (→SRT)
    │
    ├── perl-rename ──► Rename temp subtitle files
    │
    ├── fix-subtitle (optional) ──► Subtitle cleanup
    │
    ├── iconv ──► Filename Unicode→ASCII
    │
    └── du ──► Size reporting
```

## Version Compatibility

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| bash | 4.0 | Arrays, `[[ ]]`, `=~` regex |
| mkvtoolnix | 40.0 | `mkvmerge -i` output format stable |
| ffmpeg | 4.0 | H.264 encoder, SRT subtitle encoder |
| perl-rename | 1.0 | Basic regex rename |
| coreutils | 8.0 | Standard utilities |

## Installation Commands

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install mkvtoolnix ffmpeg rename coreutils
```

### Arch Linux
```bash
sudo pacman -S mkvtoolnix-cli ffmpeg perl-rename coreutils
```

### Fedora
```bash
sudo dnf install mkvtoolnix ffmpeg prename coreutils
```

### macOS (Homebrew)
```bash
brew install mkvtoolnix ffmpeg rename
```

### Raspberry Pi OS
```bash
sudo apt update
sudo apt install mkvtoolnix ffmpeg rename coreutils
```

## Runtime Detection

The script does **not** check for dependencies at startup. Failures manifest as:
- `command not found` errors during execution
- Empty variable assignments from failed command substitutions
- Incorrect FFmpeg arguments leading to ffmpeg errors

## Known Version Issues

| Tool | Issue | Workaround |
|------|-------|------------|
| `mkvmerge` < 40 | Different `-i` output format | Upgrade mkvtoolnix |
| `ffmpeg` < 4 | No H.264 encoder by default | Upgrade ffmpeg |
| `perl-rename` vs `rename` | Different packages on different distros | Script uses `perl-rename` command |

## Internal Dependencies (Script Functions)

```
Main Flow
    │
    ├── getVideoTrackFormat ──► mkvmerge
    │
    ├── getAudioTrackFormat ──► mkvmerge
    │
    ├── getAudioTrackName ──► getAudioTrackFormat, getFirstTrackType, getTrackName
    │
    ├── getSubtitleTrackName ──► getTrackName
    │
    ├── getTrackName ──► mkvinfo
    │
    ├── getTrackLanguage ──► mkvinfo
    │
    ├── getFirstTrackType ──► mkvinfo
    │
    ├── getVideoFfmpegArgs ──► (uses VIDEO_FORMAT)
    │
    ├── getAudioFfmpegArgs ──► isAudioTrackFormatOk, isAudioTrackCommentary, isAudioTrackDiscardable
    │       │
    │       ├── isAudioTrackFormatOk ──► getAudioTrackFormat
    │       ├── isAudioTrackCommentary ──► getAudioTrackName
    │       └── isAudioTrackDiscardable ──► isAudioTrackCommentary, getAudioTrackFormat
    │
    ├── isSubtitleTrackDiscardable ──► (uses TRACK_NAME, KEEP_FORCED_SUBTITLES, KEEP_SDH_SUBTITLES)
    │
    ├── doesTrackNameMatch ──► grep
    │
    ├── getSubtitleLanguage ──► getSubtitleTrackName, doesTrackNameMatch, getTrackLanguage
    │
    └── replaceDuplicatedSubtitles ──► rm, mv
```

## License Compatibility

All dependencies are GPL-compatible:
- mkvtoolnix: GPL v2+
- ffmpeg: GPL v2+/v3 (depending on build)
- perl-rename: GPL v1+/Artistic
- coreutils: GPL v3+
- fix-subtitle: Unknown (optional)