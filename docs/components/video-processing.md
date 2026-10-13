# Video Processing

## Overview

Video track detection and conversion logic. The script inspects the video format and determines whether transcoding is required.

## Function: `getVideoTrackFormat`

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

### Purpose
Extract the video codec format from the MKV container using `mkvmerge -i`.

### Input
- `FILE_PATH` — path to the MKV file

### Output
- String: video codec name (e.g., "AVC", "HEVC", "AV1", "VP9", etc.)
- Empty string if no video track found

### Example
```bash
getVideoTrackFormat  # → "AVC"
getVideoTrackFormat  # → "AV1"
```

## Function: `getVideoFfmpegArgs`

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

### Purpose
Generate FFmpeg arguments for video conversion.

### Logic
- **AV1 or VP9** → transcode to H.264 (`-c:v:0 h264`)
- **All other codecs** → copy directly (`-map 0:v:0 -c:v:0 copy`, set at higher level)

### Output
- Non-empty string: FFmpeg video arguments
- Empty string: no conversion needed

### Example
```bash
getVideoFfmpegArgs  # → "-map 0:v:0 -c:v:0 h264" (for AV1/VP9)
getVideoFfmpegArgs  # → "" (for AVC/HEVC)
```

## Invariants

1. **Only AV1/VP9 triggers conversion** — all other codecs are copied directly
2. **Conversion target**: H.264 (most compatible with Plex on Raspberry Pi)
3. **No quality enhancement** — purely format conversion for compatibility
4. **Video track index always 0** — assumes first video track