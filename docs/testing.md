# Testing

## Current State

**No automated tests exist** in the repository.

- No test directory
- No test framework
- No unit tests, integration tests, or end-to-end tests
- CI only runs shellcheck (static analysis)

## Manual Testing Approach

Users/testers manually verify by:

1. **Running on sample files** with various codecs/containers
2. **Checking output** with `mkvmerge -i` and `ffprobe`
3. **Verifying Plex direct-stream** on Raspberry Pi
4. **Comparing file sizes** before/after

## Test Scenarios Needed

### Video Codec Tests
| Input Codec | Expected Output | Verification |
|-------------|-----------------|--------------|
| AV1 | H.264 | `ffprobe -show_streams` shows h264 |
| VP9 | H.264 | `ffprobe -show_streams` shows h264 |
| AVC (H.264) | AVC (copy) | Same codec, smaller size? |
| HEVC (H.265) | HEVC (copy) | Same codec |
| MPEG-4 | MPEG-4 (copy) | Same codec |
| VC-1 | VC-1 (copy) | Same codec |

### Audio Track Tests
| Input Tracks | Expected Output | Verification |
|--------------|-----------------|--------------|
| AAC (track 0) | AAC copied as track 0 | `mkvmerge -i` shows AAC at track 0 |
| MP3 (track 1), DTS (track 0) | MP3 copied as track 0 | MP3 at track 0 |
| DTS (track 0), TrueHD (track 1) | DTS→AAC track 0, TrueHD track 1 | AAC + TrueHD |
| Commentary (track 0), AAC (track 1) | AAC copied as track 0 | Commentary dropped |
| AC-3 only | AC-3→AAC track 0 | AAC output |

### TV vs Movie Audio Tests
| Input | `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS` | Expected |
|-------|------------------------------------------|----------|
| TV episode, 2 audio tracks | false | Only primary track |
| TV episode, 2 audio tracks | true | Both non-discardable tracks |
| Movie, 2 audio tracks | false | Both non-discardable tracks |

### Subtitle Tests
| Input Subtitles | Config | Expected Extraction |
|-----------------|--------|---------------------|
| ENG (SRT), SPA (SSA) | defaults | ENG.srt, SPA.srt |
| ENG (Forced), ENG (Full) | defaults | ENG (Full) only |
| ENG (SDH), ENG (Full) | defaults | ENG (Full) only |
| ENG (Forced) | KEEP_FORCED_SUBTITLES=true | ENG (Forced) extracted |
| PGS (image) | any | Not extracted |

### Container Tests
| Input Container | Expected | Verification |
|-----------------|----------|--------------|
| MP4 (H.264/AAC) | MKV (H.264/AAC) | `mkvmerge -i` shows Matroska |
| AVI (MPEG-4/MP3) | MKV (MPEG-4/MP3) | Matroska container |
| MKV (already) | MKV (optimised) | Matroska |

### Filename Sanitisation Tests
| Input Filename | Expected Output |
|----------------|-----------------|
| `Show.S01E02.1080p.WEB-DL.x264-GROUP.mkv` | `Show S01E02.mkv` |
| `Movie.2023.4K.UHD.HEVC.TrueHD.Atmos-GROUP.mkv` | `Movie.mkv` |
| `Series.S02E05.720p.BluRay.DTS-HD.MA.5.1-GROUP.mkv` | `Series S02E05.mkv` |

## Recommended Test Framework

If tests are added, consider:

1. **Bats** (Bash Automated Testing System) — native Bash testing
2. **ShellSpec** — BDD-style for shell scripts
3. **shunit2** — xUnit-style for shell

### Example Bats Structure
```
tests/
├── test_video_processing.bats
├── test_audio_processing.bats
├── test_subtitle_processing.bats
├── test_file_naming.bats
├── test_integration.bats
└── fixtures/
    ├── video_av1.mkv
    ├── video_vp9.mkv
    ├── audio_aac_dts.mkv
    ├── subs_srt_ssa.mkv
    └── container_mp4.mp4
```

## Test Data Requirements

- Sample MKV files with known track configurations
- Small test files (< 10MB each) for CI
- Coverage of all codec combinations
- Files with various subtitle types (SRT, SSA, PGS, VobSub)

## CI Integration

Add to `.github/workflows/bash.yml`:
```yaml
- name: Run tests
  run: bats tests/
```

## Coverage Goals

| Area | Target |
|------|--------|
| Video processing | 100% (2 codecs → transcode, rest → copy) |
| Audio processing | 100% (all format combinations) |
| Subtitle processing | 100% (extraction, dedup, language detection) |
| File naming | 100% (all sanitisation rules) |
| Main flow | 100% (optimisable vs non-optimisable paths) |