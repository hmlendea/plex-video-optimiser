# FFmpeg Argument Functions

## Overview

Functions that construct FFmpeg command-line arguments for video/audio transcoding and subtitle extraction.

---

## `getVideoFfmpegArgs`

```bash
function getVideoFfmpegArgs {
    if [[ "${VIDEO_FORMAT}" == "AV1" ]] \
    || [[ "${VIDEO_FORMAT}" == "VP9" ]]; then
        echo "-map 0:v:0 -c:v:0 h264"
    else
        echo ""
    fi
}
```

**Description**: Generates video track FFmpeg arguments based on detected codec.

**Parameters**: None (uses global `VIDEO_FORMAT`)

**Returns**:
- `"-map 0:v:0 -c:v:0 h264"` — transcode AV1/VP9 to H.264
- `""` — copy for all other codecs

**Usage**:
```bash
VIDEO_FFMPEG_ARGUMENTS=$(getVideoFfmpegArgs)
if [ -n "${VIDEO_FFMPEG_ARGUMENTS}" ]; then
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${VIDEO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="-map 0:v:0 -c:v:0 copy"
fi
```

**Codec Decision Matrix**:
| Detected Codec | Output Codec | Arguments |
|----------------|--------------|-----------|
| AV1 | H.264 | `-map 0:v:0 -c:v:0 h264` |
| VP9 | H.264 | `-map 0:v:0 -c:v:0 h264` |
| AVC (H.264) | AVC | `-map 0:v:0 -c:v:0 copy` |
| HEVC (H.265) | HEVC | `-map 0:v:0 -c:v:0 copy` |
| MPEG-4 | MPEG-4 | `-map 0:v:0 -c:v:0 copy` |
| VC-1 | VC-1 | `-map 0:v:0 -c:v:0 copy` |
| Other | Same | `-map 0:v:0 -c:v:0 copy` |

**Dependencies**: None (pure logic)

---

## `getAudioFfmpegArgs`

```bash
function getAudioFfmpegArgs {
    local FFMPEG_AUDIO_TRACK_ARGS=""
    local OUTPUT_AUDIO_TRACKS_COUNT=0
    local COPIED_AUDIO_TRACK_INDEX=-1
    local MODIFICATIONS_APPLIED=false

    # Phase 1: Find first AAC/MP3 track to copy
    for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
        if isAudioTrackFormatOk "${AUDIO_TRACK_INDEX}"; then
            FFMPEG_AUDIO_TRACK_ARGS="-map 0:a:${AUDIO_TRACK_INDEX} -c:a:0 copy"
            OUTPUT_AUDIO_TRACKS_COUNT=1
            COPIED_AUDIO_TRACK_INDEX=${AUDIO_TRACK_INDEX}
            [[ "${AUDIO_TRACK_INDEX}" != "0" ]] && MODIFICATIONS_APPLIED=true
            break
        fi
    done

    # Phase 2: If no AAC/MP3, convert first non-commentary to AAC
    if [ -z "${FFMPEG_AUDIO_TRACK_ARGS}" ]; then
        for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
            if ! isAudioTrackCommentary "${AUDIO_TRACK_INDEX}"; then
                FFMPEG_AUDIO_TRACK_ARGS="-map 0:a:${AUDIO_TRACK_INDEX} -c:a:0 aac"
                OUTPUT_AUDIO_TRACKS_COUNT=1
                MODIFICATIONS_APPLIED=true
                break
            fi
        done
    fi

    # Phase 3: Add remaining tracks (movies only, unless KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS)
    if (! ${IS_TVSHOW_EPISODE}) || ${KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS}; then
        for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
            [[ "${AUDIO_TRACK_INDEX}" == "${COPIED_AUDIO_TRACK_INDEX}" ]] && continue

            if isAudioTrackDiscardable "${AUDIO_TRACK_INDEX}"; then
                MODIFICATIONS_APPLIED=true
            else
                FFMPEG_AUDIO_TRACK_ARGS="${FFMPEG_AUDIO_TRACK_ARGS} -map 0:a:${AUDIO_TRACK_INDEX} -c:a:${OUTPUT_AUDIO_TRACKS_COUNT} copy"
                OUTPUT_AUDIO_TRACKS_COUNT=$((OUTPUT_AUDIO_TRACKS_COUNT+1))
            fi
        done
    fi

    [ "${OUTPUT_AUDIO_TRACKS_COUNT}" -ne "${AUDIO_TRACKS_COUNT}" ] && MODIFICATIONS_APPLIED=true

    ${MODIFICATIONS_APPLIED} && echo "${FFMPEG_AUDIO_TRACK_ARGS}"
}
```

**Description**: Builds complete audio FFmpeg arguments implementing the track selection policy.

**Parameters**: None (uses globals: `AUDIO_TRACKS_COUNT`, `IS_TVSHOW_EPISODE`, `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS`)

**Returns**: FFmpeg argument string or empty if no modifications needed

**Phases**:

### Phase 1: Copy Preferred Format
- Iterates tracks 0 to N-1
- First AAC or MP3 → `-map 0:a:{idx} -c:a:0 copy`
- Records index in `COPIED_AUDIO_TRACK_INDEX`

### Phase 2: Convert Fallback
- If no AAC/MP3 found
- First non-commentary → `-map 0:a:{idx} -c:a:0 aac`

### Phase 3: Preserve Additional Tracks
- **Movies**: Always preserve non-discardable
- **TV Episodes**: Only if `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true`
- Skips primary track
- Discardable (commentary, AC-3, E-AC-3, MP3, Opus, PCM) → dropped
- Others → `-map 0:a:{idx} -c:a:{out_idx} copy`

**Output Example**:
```
-map 0:a:0 -c:a:0 copy -map 0:a:2 -c:a:1 copy -map 0:a:3 -c:a:2 copy
```

**Dependencies**: `isAudioTrackFormatOk`, `isAudioTrackCommentary`, `isAudioTrackDiscardable`, `getAudioTrackFormat`, `getAudioTrackName`

---

## Subtitle Extraction Arguments

Built inline in main flow (not a separate function):

```bash
SUBTITLES_FFMPEG_ARGUMENTS="${SUBTITLES_FFMPEG_ARGUMENTS} -map 0:s:${SUBTITLE_TRACK_INDEX} -c:s srt extractedSubtitleFile.${SESSION_ID}.${TRACK_LANGUAGE}.srt"
```

**Parameters**:
- `SUBTITLE_TRACK_INDEX` (int): ffmpeg stream index (0-based)
- `SESSION_ID` (string): Unique session identifier
- `TRACK_LANGUAGE` (string): 3-letter language code

**Output**: One `-map`/`-c:s` pair per subtitle track

**Example**:
```
-map 0:s:0 -c:s srt extractedSubtitleFile.abc123.ENG.srt -map 0:s:1 -c:s srt extractedSubtitleFile.abc123.SPA.srt
```

**Codec**: Always `-c:s srt` (convert to SubRip text format)

---

## Container Conversion Handling

```bash
if [ "${FILE_EXTENSION}" != "mkv" ] || [ "${CONTAINER_FORMAT}" != "Matroska" ]; then
    echo "File format needs conversion!"
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS=""
fi
```

**Logic**: If input is not MKV or not Matroska container:
- Sets `IS_OPTIMISABLE=true`
- **Clears** `FFMPEG_ARGUMENTS` (empty string)
- This causes ffmpeg to use default stream mapping (all streams, copy codecs)
- Effectively remuxes to MKV with no transcoding

**Note**: This is a special case — empty `FFMPEG_ARGUMENTS` triggers default ffmpeg behaviour.

---

## Subtitle Removal Arguments

```bash
if [ "${SUBTITLE_TRACKS_COUNT}" -gt 0 ]; then
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map -0:s"
fi
```

**Argument**: `-map -0:s` — negative mapping excludes all subtitle streams from input 0

**Effect**: All subtitle tracks removed from output video file

**Note**: Applied regardless of whether extraction happens — subtitles always removed from optimised video

---

## Complete FFmpeg Command Construction

```bash
# Video
if [ -n "${VIDEO_FFMPEG_ARGUMENTS}" ]; then
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${VIDEO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="-map 0:v:0 -c:v:0 copy"
fi

# Audio
if [ -n "${AUDIO_FFMPEG_ARGUMENTS}" ]; then
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${AUDIO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map 0:a -c:a copy"
fi

# Container conversion (clears args)
if [ "${FILE_EXTENSION}" != "mkv" ] || [ "${CONTAINER_FORMAT}" != "Matroska" ]; then
    FFMPEG_ARGUMENTS=""
fi

# Subtitle removal
if [ "${SUBTITLE_TRACKS_COUNT}" -gt 0 ]; then
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map -0:s"
fi
```

**Execution**:
```bash
ffmpeg -i "${FILE_PATH}" ${FFMPEG_ARGUMENTS} "${OUTPUT_TEMP_FILE}"
```

**Argument Order**: ffmpeg processes `-map` options in order; later maps override earlier for same output stream index.

---

## Invariants

1. **Video always mapped** — either transcoded or copied
2. **Audio always mapped** — at least one track guaranteed
3. **Subtitles always removed from video** — `-map -0:s` when any exist
4. **Container conversion uses defaults** — empty args = remux all streams
5. **Session ID in subtitle extraction** — prevents temp file collisions