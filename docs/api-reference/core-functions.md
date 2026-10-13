# Core Functions

## `getVideoTrackFormat`

```bash
function getVideoTrackFormat {
    local VIDEO_TRACK_FORMAT=""

    VIDEO_TRACK_FORMAT=$(mkvmerge -i "${FILE_PATH}" | \
                            grep -E "Track ID [0-9]+: video" | \
                            head -n 1 | tail -n 1 | \
                            awk -F "(" '{print $2}' | awk -F ")" '{print $1}')

    echo "${VIDEO_TRACK_FORMAT}"
}
```

**Description**: Extracts the video codec format from the first video track in the MKV file.

**Parameters**: None (uses global `FILE_PATH`)

**Returns**:
- String: Video codec name (e.g., "AVC", "HEVC", "AV1", "VP9", "MPEG-4", "VC-1")
- Empty string if no video track found

**Dependencies**: `mkvmerge`

**Example Output**:
```
AVC
HEVC
AV1
VP9
```

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

**Description**: Generates FFmpeg arguments for video track processing based on detected codec.

**Parameters**: None (uses global `VIDEO_FORMAT`)

**Returns**:
- `"-map 0:v:0 -c:v:0 h264"` — if video is AV1 or VP9 (transcode to H.264)
- `""` (empty) — for all other codecs (copy directly)

**Logic**:
| Input Codec | Output | Action |
|-------------|--------|--------|
| AV1 | H.264 | Transcode |
| VP9 | H.264 | Transcode |
| AVC (H.264) | AVC | Copy |
| HEVC (H.265) | HEVC | Copy |
| MPEG-4 | MPEG-4 | Copy |
| VC-1 | VC-1 | Copy |
| Any other | Same | Copy |

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

**Description**: Builds complete FFmpeg audio arguments implementing the audio track selection and conversion policy.

**Parameters**: None (uses globals: `AUDIO_TRACKS_COUNT`, `IS_TVSHOW_EPISODE`, `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS`)

**Returns**: FFmpeg argument string or empty if no modifications needed

**Algorithm Phases**:

### Phase 1: Preferred Format Copy
- Scans tracks in order (0 to N-1)
- First track with format AAC or MP3 → copied as output track 0
- Sets `COPIED_AUDIO_TRACK_INDEX` to skip in phase 3

### Phase 2: Fallback Conversion
- If no AAC/MP3 found
- First non-commentary track → converted to AAC as output track 0

### Phase 3: Additional Track Preservation
- **Movies** (`IS_TVSHOW_EPISODE=false`): Always preserve non-discardable tracks
- **TV Episodes** (`IS_TVSHOW_EPISODE=true`): Only if `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true`
- Iterates all tracks, skips primary track
- Discardable tracks (commentary, AC-3, E-AC-3, MP3, Opus, PCM) → dropped
- Others (DTS, TrueHD, FLAC, etc.) → copied with incrementing output index

**Output Format**:
```
-map 0:a:0 -c:a:0 copy -map 0:a:1 -c:a:1 copy -map 0:a:2 -c:a:2 copy
```

**Dependencies**: `isAudioTrackFormatOk`, `isAudioTrackCommentary`, `isAudioTrackDiscardable`, `getAudioTrackFormat`, `getAudioTrackName`