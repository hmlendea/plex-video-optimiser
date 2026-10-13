# Main Execution Flow

## Overview

End-to-end flow from script invocation to final output file. The script executes linearly with two interactive confirmation points.

## Flow Diagram

```
START
  │
  ▼
Validate input file exists
  │
  ▼
Parse metadata (path, name, extension, directory)
  │
  ▼
Generate SESSION_ID (32-char random)
  │
  ▼
Sanitise output filename (strip tags, normalise)
  │
  ▼
Detect TV show episode (SxxExx pattern)
  │
  ▼
Gather file info (mkvmerge -i)
  │
  ├── Container format
  ├── Video format
  ├── Audio track count
  └── Subtitle track count
  │
  ▼
Enumerate audio tracks
  │
  ├── For each: format, name
  └── Display to user
  │
  ▼
Determine optimisation needs
  │
  ├── Video: AV1/VP9 → needs H.264 conversion
  ├── Audio: needs conversion/selection?
  ├── Container: non-MKV or non-Matroska?
  └── Subtitles: any text tracks to remove?
  │
  ▼
IS_OPTIMISABLE = any of above true
  │
  ▼
IF !IS_OPTIMISABLE:
  │   Print "No optimisation needed!"
  │   EXIT 0
  ▼
ELSE:
  │
  ▼
Build FFmpeg arguments
  │
  ├── Video args (getVideoFfmpegArgs)
  ├── Audio args (getAudioFfmpegArgs)
  ├── Subtitle removal (-map -0:s)
  └── Container conversion (if needed)
  │
  ▼
Display summary (input size, mkvmerge -i, output path, ffmpeg args)
  │
  ▼
PROMPT 1: "Are you sure you want to optimise? [Y/n]"
  │
  ├── N/no → EXIT
  └── Y/yes/Enter → continue
  │
  ▼
Run ffmpeg with constructed arguments
  │
  ├── Output to .OPTIMISED.mkv temp file
  └── Wait for completion
  │
  ▼
Verify output file exists
  │
  ▼
Display size comparison (before/after)
  │
  ▼
Display output mkvmerge -i
  │
  ▼
PROMPT 2: "Do you want to replace the original file? [Y/n]"
  │
  ├── N/no → keep .OPTIMISED.mkv, EXIT
  └── Y/yes/Enter → continue
  │
  ▼
Delete original file
  │
  ▼
Rename .OPTIMISED.mkv → .mkv
  │
  ▼
END
```

## Detailed Steps

### 1. Input Validation (Lines 1-10)
```bash
FILE_PATH="$*"
if [ ! -f "${FILE_PATH}" ]; then
    echo "Cannot access '${FILE_PATH}': No such file or directory"
    exit 1
fi
```
- Accepts full path as positional arguments (joined with spaces)
- Exits with code 1 if file not found

### 2. Metadata Extraction (Lines 11-30)
```bash
FILE_BASENAME=$(basename -- "$FILE_PATH")
FILE_EXTENSION="${FILE_BASENAME##*.}"
FILE_NAME="${FILE_BASENAME%.*}"
FILE_DIRECTORY=$(dirname "${FILE_PATH}")
SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
```
- Splits path into components
- Generates unique session ID for temp file isolation

### 3. File Name Sanitisation (Lines 31-65)
See [file-naming.md](./components/file-naming.md) for full pipeline.

### 4. TV Episode Detection (Lines 67-70)
```bash
FILE_NAME_TVSHOW_EPISODE_MATCHES_COUNT=$(echo "${FILE_NAME}" | grep -E "[Ss][0-9]+[Ee][0-9]+" -c)
if [ "${FILE_NAME_TVSHOW_EPISODE_MATCHES_COUNT}" -gt 0 ]; then
    IS_TVSHOW_EPISODE=true
fi
```

### 5. File Info Gathering (Lines 72-95)
```bash
CONTAINER_FORMAT=$(mkvmerge -i "${FILE_PATH}" | head -n 1 | awk -F: '{print $3}' | sed 's/ //g')
VIDEO_FORMAT=$(getVideoTrackFormat)
AUDIO_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": audio" -c)
SUBTITLE_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" -c)
```
- Uses `mkvmerge -i` for container/track summary
- Calls `getVideoTrackFormat` for video codec

### 6. Audio Track Enumeration (Lines 97-107)
```bash
for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")
    if [ -n "${AUDIO_TRACK_FORMAT}" ]; then
        AUDIO_TRACK_NAME=$(getAudioTrackName "${AUDIO_TRACK_INDEX}")
        printf "Audio ${AUDIO_TRACK_INDEX}: ${AUDIO_TRACK_FORMAT}"
        [ -n "${AUDIO_TRACK_NAME}" ] && printf " (${AUDIO_TRACK_NAME})"
        printf "\n"
    fi
done
```

### 7. Optimisation Decision (Lines 312-380)
```bash
VIDEO_FFMPEG_ARGUMENTS=$(getVideoFfmpegArgs)
AUDIO_FFMPEG_ARGUMENTS=$(getAudioFfmpegArgs)

if [ -n "${VIDEO_FFMPEG_ARGUMENTS}" ]; then
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${VIDEO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="-map 0:v:0 -c:v:0 copy"
fi

if [ -n "${AUDIO_FFMPEG_ARGUMENTS}" ]; then
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${AUDIO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map 0:a -c:a copy"
fi

if [ "${FILE_EXTENSION}" != "mkv" ] || [ "${CONTAINER_FORMAT}" != "Matroska" ]; then
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS=""
fi

if [ "${SUBTITLE_TRACKS_COUNT}" -gt 0 ]; then
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map -0:s"
    # ... subtitle extraction setup
fi
```

### 8. Early Exit (Lines 382-384)
```bash
if ! ${IS_OPTIMISABLE}; then
    echo "No optimisation needed!"
    exit 0
fi
```

### 9. FFmpeg Execution (Lines 452-520)
```bash
OUTPUT_TEMP_FILE="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.OPTIMISED.mkv"
OUTPUT_FILE="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.mkv"

# ... subtitle extraction if requested ...

echo "Output file: ${OUTPUT_TEMP_FILE}"
echo "ffmpeg arguments:"
echo "${FFMPEG_ARGUMENTS}"

read -p "Are you sure you want to optimise the video with the mentioned settings? [Y/n] " -n 1 -r
echo

if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
    echo "Optimising ${FILE_PATH}..."
    ffmpeg -i "${FILE_PATH}" ${FFMPEG_ARGUMENTS} "${OUTPUT_TEMP_FILE}"
    # ... size comparison, mkvmerge -i output ...

    read -p "Do you want to replace the original file? [Y/n] " -n 1 -r
    echo

    if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
        rm "${FILE_PATH}"
        mv "${OUTPUT_TEMP_FILE}" "${OUTPUT_FILE}"
    fi
fi
```

## Error Handling

| Failure Point | Behaviour |
|---------------|-----------|
| Input file missing | Exit 1 with error message |
| mkvmerge/mkvinfo fails | Command substitution fails, likely empty variables → may produce incorrect args |
| ffmpeg fails | Non-zero exit, temp file may not exist → script continues but replacement prompt shows missing file |
| User cancels at prompt 1 | Clean exit, no temp file created |
| User cancels at prompt 2 | .OPTIMISED.mkv left in place, original preserved |

## Invariants

1. **Original file untouched until explicit confirmation**
2. **Temp file uses unique SESSION_ID** — no collision risk
3. **Two confirmation gates** — optimise, then replace
4. **Size comparison shown** — user can verify compression
5. **mkvmerge -i shown for output** — verify track structure