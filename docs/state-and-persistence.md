# State and Persistence

## State Management

**No persistent state** — script is stateless between runs. All state is in-memory during execution.

## In-Memory State (During Run)

| Variable | Scope | Persistence |
|----------|-------|-------------|
| `FILE_PATH` | Global | Input only |
| `FILE_NAME`, `FILE_EXTENSION`, `FILE_DIRECTORY` | Global | Derived from input |
| `SESSION_ID` | Global | Generated at start |
| `IS_TVSHOW_EPISODE` | Global | Derived from filename |
| `IS_OPTIMISABLE` | Global | Computed |
| `CONTAINER_FORMAT`, `VIDEO_FORMAT` | Global | From mkvmerge |
| `AUDIO_TRACKS_COUNT`, `SUBTITLE_TRACKS_COUNT` | Global | From mkvmerge |
| `FFMPEG_ARGUMENTS` | Global | Built incrementally |
| `SUBTITLES_FFMPEG_ARGUMENTS` | Global | Built for extraction |
| `OUTPUT_FILE_NAME` | Global | Sanitised |
| `OUTPUT_FILE_PATH_WITHOUT_EXTENSION` | Global | Derived |
| `OUTPUT_TEMP_FILE`, `OUTPUT_FILE` | Global | Derived |
| `TRACK_NAME` | Global (temp) | Set by caller for `isSubtitleTrackDiscardable` |
| `TRACK_LANGUAGES` | Global (temp) | Built during subtitle extraction |

## Temporary Files

### Main Optimisation
- **Path**: `${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.OPTIMISED.mkv`
- **Lifecycle**: Created by ffmpeg → verified → renamed to final on confirmation
- **Cleanup**: Not automatic on interrupt

### Subtitle Extraction
- **Pattern**: `extractedSubtitleFile.{SESSION_ID}.{LANG}.srt`
- **Location**: Current working directory (not input directory!)
- **Lifecycle**: Created by ffmpeg → deduplicated → fix-subtitle → renamed by perl-rename
- **Final names**: `{OUTPUT_FILE_NAME}.{LANG}.srt` in input directory
- **Cleanup**: Temp files removed by deduplication/rename

## Persistence Across Runs

**None** — each run is independent. No cache, no database, no config file.

## Migration

**Not applicable** — no persistent state to migrate.

## Backup/Recovery

- **Original file**: Preserved until explicit replace confirmation
- **Temp optimised file**: Remains if user declines replace
- **Extracted subtitles**: Final `.srt` files remain in input directory
- **No automatic backup** — user responsible for backups

## Concurrency Safety

- **SESSION_ID** (32-char random) isolates temp files
- **Same file, concurrent runs**: Different SESSION_ID → different temp files → safe
- **Same file, sequential runs**: Second run sees optimised file → "No optimisation needed"

## Disk Space

- **Peak usage**: Input + temp output + extracted subtitles
- **Typical**: 1.5x input size during optimisation
- **No quota enforcement** — fails with disk full error