# API Reference Index

## Function Categories

### Core Functions
| Function | Description | File |
|----------|-------------|------|
| `getVideoTrackFormat` | Extract video codec from MKV | [core-functions.md](./core-functions.md) |
| `getVideoFfmpegArgs` | Generate video FFmpeg args | [core-functions.md](./core-functions.md) |
| `getAudioFfmpegArgs` | Generate audio FFmpeg args | [core-functions.md](./core-functions.md) |

### Track Inspection Functions
| Function | Description | File |
|----------|-------------|------|
| `getAudioTrackFormat` | Get audio codec for track index | [track-functions.md](./track-functions.md) |
| `getAudioTrackName` | Get audio track name | [track-functions.md](./track-functions.md) |
| `getSubtitleTrackName` | Get normalised subtitle track name | [track-functions.md](./track-functions.md) |
| `getTrackName` | Get raw track name from mkvinfo | [track-functions.md](./track-functions.md) |
| `getTrackLanguage` | Get language code from mkvinfo | [track-functions.md](./track-functions.md) |
| `getFirstTrackType` | Get first track type (video/audio/subtitle) | [track-functions.md](./track-functions.md) |

### Audio Decision Functions
| Function | Description | File |
|----------|-------------|------|
| `isAudioTrackFormatOk` | Check if track is AAC/MP3 | [track-functions.md](./track-functions.md) |
| `isAudioTrackCommentary` | Check if track is commentary | [track-functions.md](./track-functions.md) |
| `isAudioTrackDiscardable` | Check if track should be dropped | [track-functions.md](./track-functions.md) |

### Subtitle Functions
| Function | Description | File |
|----------|-------------|------|
| `isSubtitleTrackDiscardable` | Check if subtitle should be skipped | [track-functions.md](./track-functions.md) |
| `doesTrackNameMatch` | Pattern match track name | [track-functions.md](./track-functions.md) |
| `getSubtitleLanguage` | Detect 3-letter language code | [track-functions.md](./track-functions.md) |
| `replaceDuplicatedSubtitles` | Deduplicate subtitle files | [track-functions.md](./track-functions.md) |

### FFmpeg Argument Functions
| Function | Description | File |
|----------|-------------|------|
| `getVideoFfmpegArgs` | Video conversion args | [ffmpeg-functions.md](./ffmpeg-functions.md) |
| `getAudioFfmpegArgs` | Audio selection/conversion args | [ffmpeg-functions.md](./ffmpeg-functions.md) |

## Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `FILE_PATH` | string | Input file path (positional arg) |
| `FILE_BASENAME` | string | Basename of input file |
| `FILE_EXTENSION` | string | File extension |
| `FILE_NAME` | string | Filename without extension |
| `FILE_DIRECTORY` | string | Directory containing input file |
| `SESSION_ID` | string | 32-char random for temp files |
| `IS_TVSHOW_EPISODE` | boolean | True if SxxExx detected in filename |
| `IS_OPTIMISABLE` | boolean | True if any conversion needed |
| `CONTAINER_FORMAT` | string | Container format from mkvmerge |
| `VIDEO_FORMAT` | string | Video codec from mkvmerge |
| `AUDIO_TRACKS_COUNT` | int | Number of audio tracks |
| `SUBTITLE_TRACKS_COUNT` | int | Number of subtitle tracks |
| `FFMPEG_ARGUMENTS` | string | Combined FFmpeg arguments |
| `SUBTITLES_FFMPEG_ARGUMENTS` | string | Subtitle extraction FFmpeg args |
| `OUTPUT_FILE_NAME` | string | Sanitised output filename |
| `OUTPUT_FILE_PATH_WITHOUT_EXTENSION` | string | Output path without .mkv |
| `OUTPUT_TEMP_FILE` | string | Temp output path (.OPTIMISED.mkv) |
| `OUTPUT_FILE` | string | Final output path (.mkv) |

## Configuration Constants

| Constant | Default | Description |
|----------|---------|-------------|
| `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS` | `false` | Preserve all audio tracks for TV episodes |
| `KEEP_FORCED_SUBTITLES` | `false` | Keep forced subtitle tracks |
| `KEEP_SDH_SUBTITLES` | `false` | Keep SDH subtitle tracks |

## External Commands

| Command | Purpose |
|---------|---------|
| `mkvmerge` | Container/track inspection |
| `mkvinfo` | Detailed track metadata |
| `ffmpeg` | Transcoding/remuxing/extraction |
| `perl-rename` | Batch rename extracted subtitles |
| `fix-subtitle` | Subtitle post-processing |
| `iconv` | Filename transliteration |
| `du` | File size reporting |