# Logging

## Overview

plex-video-optimiser uses **stdout/stderr for all output** — no dedicated logging framework, no log files, no structured logging.

## Output Streams

| Stream | Content |
|--------|---------|
| **stdout** | Progress messages, track info, prompts, summaries |
| **stderr** | External command errors (mkvmerge, ffmpeg, etc.) |

## Log Levels (Implicit)

| Level | Usage |
|-------|-------|
| **INFO** | `echo "Gathering file info..."`, `echo "Video track needs conversion!"` |
| **WARN** | None explicitly |
| **ERROR** | `echo "Cannot access..."` (then exit) |
| **DEBUG** | None (add `set -x` for trace) |

## Structured Fields

**None** — output is human-readable free text.

## Correlation

**Session ID** provides run correlation:
```bash
SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo "Session ID: ${SESSION_ID}"
```
- 32-character alphanumeric
- Used in temp file names: `extractedSubtitleFile.{SESSION_ID}.{LANG}.srt`
- Printed at start for manual correlation

## Sinks/Destinations

| Destination | Configuration |
|-------------|---------------|
| Console (stdout/stderr) | Only destination |
| Files | None |
| Syslog | None |
| External service | None |

## Redaction/Masking

**None** — file paths, names, and track info printed in full.

## Retention

**None** — no log files created. Output only in terminal scrollback.

## Sampling

**Not applicable** — no high-volume logging.

## Performance Considerations

- **Synchronous output** — each `echo` blocks
- **No async logging** — minimal overhead (few dozen lines per run)
- **External command output** — ffmpeg/mkvmerge output goes to stderr directly

## Error Logging

- External command stderr passes through
- Script errors: single-line messages to stdout
- No stack traces (Bash limitation)
- No context enrichment

## Audit Logging

**None** — no security-relevant event logging.

## Configuration

**No logging configuration** — all output hardcoded.

## Runtime Level Changes

**Not supported** — no log level control.

## Recommendations for Enhancement

1. **Add `--verbose`/`-v` flag** for debug output
2. **Add `--quiet`/`-q` flag** for minimal output
3. **Add `--log-file` option** for file output
4. **Structured JSON output** for machine parsing
5. **Timestamp each line** for timing analysis