# Audio Processing

## Overview

Audio track selection, conversion, and preservation logic. The script prioritises AAC/MP3 tracks (copy), converts the first non-commentary track to AAC if needed, and optionally preserves original tracks for movies.

## Functions

### `getAudioTrackFormat`

```bash
function getAudioTrackFormat {
    local AUDIO_TRACK_INDEX="${1}"
    local TRACK_ID=-1
    local AUDIO_TRACKS_COUNT=-1
    local AUDIO_TRACK_FORMAT=""

    TRACK_ID=$((AUDIO_TRACK_INDEX+1))
    AUDIO_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | \
                                grep -E "Track ID [0-9]+: audio" | \
                                wc -l)

    if [ "${AUDIO_TRACKS_COUNT}" -ge "${TRACK_ID}" ]; then
        AUDIO_TRACK_FORMAT=$(mkvmerge -i "${FILE_PATH}" | \
                            grep -E "Track ID [0-9]+: audio" | \
                            head -n "${TRACK_ID}" | tail -n 1 | \
                            awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
    fi

    echo "${AUDIO_TRACK_FORMAT}"
}
```

**Purpose**: Get audio codec format for a specific track index (0-based).

**Input**: `AUDIO_TRACK_INDEX` (0-based)

**Output**: Codec string (e.g., "AAC", "AC-3", "DTS", "TrueHD", "FLAC", "Opus", "MP3", "PCM", "E-AC-3")

---

### `getAudioTrackName`

```bash
function getAudioTrackName {
    local AUDIO_TRACK_INDEX="${1}"
    local AUDIO_TRACK_FORMAT=""
    local TRACK_ID=-1
    local AUDIO_TRACK_NAME=""

    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")
    TRACK_ID=${AUDIO_TRACK_INDEX}

    FIRST_TRACK_TYPE=$(getFirstTrackType)

    if [ "${FIRST_TRACK_TYPE}" == "video" ]; then
        TRACK_ID=$((TRACK_ID+1))
    fi

    if [ -n "${AUDIO_TRACK_FORMAT}" ]; then
        AUDIO_TRACK_NAME=$(getTrackName "${TRACK_ID}")
    fi

    echo "${AUDIO_TRACK_NAME}"
}
```

**Purpose**: Get the human-readable name of an audio track.

**Input**: `AUDIO_TRACK_INDEX` (0-based)

**Output**: Track name string (e.g., "English", "Commentary", "Surround 5.1")

---

### `isAudioTrackFormatOk`

```bash
function isAudioTrackFormatOk {
    local AUDIO_TRACK_INDEX="${1}"
    local AUDIO_TRACK_FORMAT=""

    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")

    if [[ "${AUDIO_TRACK_FORMAT}" == "AAC" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "MP3" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}
```

**Purpose**: Check if audio track is already in a preferred format (AAC or MP3).

**Returns**: 0 (true) if AAC/MP3, 1 (false) otherwise.

---

### `isAudioTrackCommentary`

```bash
function isAudioTrackCommentary {
    local AUDIO_TRACK_INDEX=${1}
    local AUDIO_TRACK_NAME=""
    local COMMENTARY_NAME_MATCHES_COUNT=0

    AUDIO_TRACK_NAME=$(getAudioTrackName "${AUDIO_TRACK_INDEX}")
    COMMENTARY_NAME_MATCHES_COUNT=$(echo "${AUDIO_TRACK_NAME}" | grep -c "[Cc]ommentary")

    if [ "${COMMENTARY_NAME_MATCHES_COUNT=}" -ge 1 ]; then
        return 0 # True
    else
        return 1 # False
    fi
}
```

**Purpose**: Detect commentary tracks by name.

**Returns**: 0 (true) if name contains "Commentary" (case-insensitive), 1 (false) otherwise.

---

### `isAudioTrackDiscardable`

```bash
function isAudioTrackDiscardable {
    local AUDIO_TRACK_INDEX="${1}"
    local AUDIO_TRACK_FORMAT=""

    isAudioTrackCommentary "${AUDIO_TRACK_INDEX}" && return 0 # True

    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")

    if [[ "${AUDIO_TRACK_FORMAT}" == "AC-3" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "AC-3 Dolby Surround EX" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "E-AC-3" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "MP3" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "Opus" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "PCM" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}
```

**Purpose**: Determine if an audio track should be dropped (not copied to output).

**Logic**:
- Commentary tracks → discard
- AC-3, AC-3 Dolby Surround EX, E-AC-3, MP3, Opus, PCM → discard
- All others (DTS, TrueHD, FLAC, DTS-X, DTS-MA, etc.) → keep

---

### `getAudioFfmpegArgs`

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

**Purpose**: Build complete FFmpeg audio arguments.

**Algorithm**:
1. **Prefer existing AAC/MP3** — copy first one found as track 0
2. **Fallback: convert first non-commentary** to AAC as track 0
3. **Preserve additional tracks** (movies only by default):
   - Skip commentary tracks
   - Skip discardable formats (AC-3, E-AC-3, MP3, Opus, PCM)
   - Copy remaining tracks (DTS, TrueHD, FLAC, etc.)

**Output**: FFmpeg argument string or empty if no modifications needed.

---

## Decision Matrix

| Track Format | Is Preferred? | Is Discardable? | Action |
|--------------|---------------|-----------------|--------|
| AAC | ✅ | ❌ | Copy as primary |
| MP3 | ✅ | ✅ | Copy as primary, but discardable if not primary |
| AC-3 | ❌ | ✅ | Discard |
| E-AC-3 | ❌ | ✅ | Discard |
| Opus | ❌ | ✅ | Discard |
| PCM | ❌ | ✅ | Discard |
| DTS | ❌ | ❌ | Preserve (copy) |
| TrueHD | ❌ | ❌ | Preserve (copy) |
| FLAC | ❌ | ❌ | Preserve (copy) |
| DTS-X | ❌ | ❌ | Preserve (copy) |
| DTS-MA | ❌ | ❌ | Preserve (copy) |
| Commentary (any) | ❌ | ✅ | Discard |

---

## TV Show vs Movie Behaviour

| Scenario | `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false` (default) | `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true` |
|----------|----------------------------------------------------------|-----------------------------------------------|
| **TV Episode** | Only primary track kept (AAC/MP3 copy or converted) | All non-discardable tracks preserved |
| **Movie** | All non-discardable tracks preserved | All non-discardable tracks preserved |

---

## Invariants

1. **At least one audio track always in output** — primary track guaranteed
2. **Primary track always AAC or MP3** — either copied or converted
3. **Commentary tracks never preserved**
4. **Discardable formats never preserved as additional tracks**
5. **Track order preserved** — additional tracks maintain original relative order