# Configuration

## Overview

plex-video-optimiser uses hardcoded configuration constants at the top of the script. There is no external configuration file, no CLI flags, and no environment variable support.

## Configuration Constants

```bash
# Options
KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false
KEEP_FORCED_SUBTITLES=false
KEEP_SDH_SUBTITLES=false
```

### `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS`

| Value | Behaviour |
|-------|-----------|
| `false` (default) | TV episodes: only primary audio track kept (AAC/MP3 copy or converted to AAC) |
| `true` | TV episodes: all non-discardable audio tracks preserved (same as movies) |

**Effect**: Controls Phase 3 of `getAudioFfmpegArgs` — whether additional audio tracks are preserved for TV show episodes.

### `KEEP_FORCED_SUBTITLES`

| Value | Behaviour |
|-------|-----------|
| `false` (default) | Subtitle tracks with "Forced" in name are discarded during extraction |
| `true` | Forced subtitle tracks are extracted and preserved |

**Effect**: Controls `isSubtitleTrackDiscardable` — whether forced tracks are skipped.

### `KEEP_SDH_SUBTITLES`

| Value | Behaviour |
|-------|-----------|
| `false` (default) | Subtitle tracks with "SDH" in name are discarded during extraction |
| `true` | SDH (Subtitles for Deaf/Hard of Hearing) tracks are extracted and preserved |

**Effect**: Controls `isSubtitleTrackDiscardable` — whether SDH tracks are skipped.

## Modification

To change configuration, edit the script directly at lines 13-15:

```bash
# Options
KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true
KEEP_FORCED_SUBTITLES=true
KEEP_SDH_SUBTITLES=true
```

## Design Rationale

- **Simplicity**: Single-file script with no config parsing overhead
- **Predictability**: Behaviour is explicit in source code
- **Version control**: Configuration changes tracked with code changes
- **No runtime surprises**: No environment-specific behaviour

## Future Considerations

Potential improvements (not implemented):
- CLI flags (`--keep-forced-subs`, `--keep-sdh`, `--keep-all-audio`)
- Config file (`~/.config/plex-video-optimiser.conf`)
- Environment variable overrides (`PVO_KEEP_FORCED_SUBTITLES=1`)