# Concurrency and Scheduling

## Execution Model

**Strictly single-threaded, synchronous, sequential** — no concurrency, no parallelism, no background jobs.

## Flow Control

```
Main Script (PID 1)
    │
    ├── mkvmerge (blocking)
    ├── mkvinfo (blocking, multiple calls)
    ├── ffmpeg (blocking, main optimisation)
    ├── ffmpeg (blocking, subtitle extraction)
    ├── fix-subtitle (blocking, per file)
    └── perl-rename (blocking)
```

Each external command runs to completion before the next starts.

## No Async Patterns

| Pattern | Used? |
|---------|-------|
| Background jobs (`&`) | No |
| `wait` | No |
| Coprocesses | No |
| Named pipes | No |
| Signal handlers | No (except implicit SIGINT) |
| `trap` | No |

## Resource Contention

| Resource | Contention Risk | Mitigation |
|----------|-----------------|------------|
| Input file | Read-only, multiple tools | Sequential reads |
| Output directory | Temp files + final output | Unique SESSION_ID |
| `/dev/urandom` | Session ID generation | Single read at start |
| CPU | ffmpeg encoding | Single ffmpeg at a time |
| Disk I/O | Sequential | No parallel I/O |

## Scheduling

**No scheduler** — runs immediately when invoked. No cron, no daemon, no queue.

## Interrupt Handling

- **SIGINT (Ctrl+C)**: Terminates current command, script exits
- **No cleanup trap** — temp files (`.OPTIMISED.mkv`, `extractedSubtitleFile.*`) may remain
- **No resume capability** — must restart from beginning

## Scalability

| Dimension | Limit |
|-----------|-------|
| Concurrent runs | Unlimited (different files, different SESSION_ID) |
| File size | Limited by disk space, ffmpeg limits |
| Batch processing | Not supported (manual per-file) |

## Recommendations for Enhancement

1. **Add `trap` for cleanup** on EXIT/INT/TERM
2. **Add `--batch` mode** for directory processing
3. **Add `--dry-run`** to show actions without executing
4. **Parallel ffmpeg** for independent files (external tool like GNU parallel)