# Subtitle Extraction Flow

## Overview

Optional interactive flow that extracts text-based subtitle tracks before optimisation, deduplicates by language, post-processes with `fix-subtitle`, and renames to clean output names.

## Flow Diagram

```
Subtitle tracks detected (SUBTITLE_TRACKS_COUNT > 0)
  │
  ▼
Filter to text-based only (SRT, SubStationAlpha)
  │
  ▼
IF no text subtitles:
  │   Print "No text subtitles found!"
  │   Continue without extraction
  ▼
ELSE:
  │
  ▼
Display found tracks with language/name
  │
  ▼
PROMPT: "Do you want to save the subtitles before removing them? [Y/n]"
  │
  ├── N/no → Skip extraction, subtitles removed from output
  └── Y/yes/Enter → Continue
  │
  ▼
For each non-discarded track:
  │
  ├── Get language code (getSubtitleLanguage)
  ├── Handle duplicates (append -2, -3 or variant name)
  ├── Build ffmpeg extraction args
  │       -map 0:s:{index} -c:s srt extractedSubtitleFile.{SESSION}.{LANG}.srt
  └── Track language list for deduplication
  │
  ▼
Run ffmpeg extraction
  │
  ▼
Deduplication (replaceDuplicatedSubtitles)
  │
  ├── Chinese: CHI, CHI2, CHI3, CHI-繁體, CHI-简体 → CHI
  ├── French: FRE, FRE-Canada, FRE-France → FRE
  ├── Portuguese: POR, POR-Brazil → POR
  └── Spanish: SPA, SPA-LatinAmerica, SPA-España, SPA-Europe, SPA-Spain → SPA
  │
  ▼
Post-process with fix-subtitle (if available)
  │
  ▼
Rename: extractedSubtitleFile.{SESSION}.{LANG}.srt → {OUTPUT_NAME}.{LANG}.srt
  │
  ▼
Continue to main optimisation
```

## Detailed Steps

### 1. Subtitle Track Discovery (Lines 330-335)
```bash
SUBTITLE_TRACKS=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" | grep "\(SRT\|SubStationAlpha\)" | awk '{print $3}' | awk -F: '{print $1}')
```
- `mkvmerge -i` output parsed for subtitle tracks
- Only **SRT** and **SubStationAlpha** (SSA/ASS) — text-based
- Image-based (PGS, VobSub, HDMV PGS) excluded

### 2. Track Enumeration & Display (Lines 337-360)
```bash
for TRACK_ID in ${SUBTITLE_TRACKS}; do
    TRACK_LANGUAGE=$(getSubtitleLanguage "${TRACK_ID}")
    TRACK_NAME=$(getSubtitleTrackName "${TRACK_ID}")

    isSubtitleTrackDiscardable "${TRACK_ID}" && continue

    # ... display with language and name ...
done
```
- `getSubtitleLanguage` — name-based detection + mkvinfo fallback
- `getSubtitleTrackName` — normalised name (see [subtitle-processing.md](../components/subtitle-processing.md))
- `isSubtitleTrackDiscardable` — filters Forced/SDH based on config

### 3. User Confirmation (Lines 362-365)
```bash
read -p "Do you want to save the subtitles before removing them? [Y/n] " -n 1 -r
echo
if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
    # extraction proceeds
fi
```

### 4. Extraction Argument Construction (Lines 367-410)
```bash
for TRACK_ID in ${SUBTITLE_TRACKS}; do
    TRACK_LANGUAGE=$(getSubtitleLanguage "${TRACK_ID}")
    TRACK_NAME=$(getSubtitleTrackName "${TRACK_ID}")

    isSubtitleTrackDiscardable "${TRACK_ID}" && continue

    # Duplicate handling
    DUPLICATIONS=$(echo "${TRACK_LANGUAGES}" | sed 's/,/\n/g' | grep -c "${TRACK_LANGUAGE}")
    if [ "${DUPLICATIONS}" -ge 1 ]; then
        if [ -n "${TRACK_NAME}" ]; then
            TRACK_LANGUAGE_NAME=$(echo "${TRACK_NAME}" | sed \
                -e 's/\s//g' \
                -e 's/[()]//g' \
                -e 's/\([Cc]hinese\|[Ff]rench\|[Pp]ortuguese\|[Ss]panish\)//g')
            TRACK_LANGUAGE="${TRACK_LANGUAGE}-${TRACK_LANGUAGE_NAME}$((DUPLICATIONS+1))"
        else
            TRACK_LANGUAGE="${TRACK_LANGUAGE}$((DUPLICATIONS+1))"
        fi
    fi
    TRACK_LANGUAGES="${TRACK_LANGUAGES}${TRACK_LANGUAGE},"

    # Map mkvmerge track ID to ffmpeg stream index
    SUBTITLE_TRACK_INDEX=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" | grep "^Track ID ${TRACK_ID}:" -n | awk -F: '{print $1}')
    SUBTITLE_TRACK_INDEX=$((SUBTITLE_TRACK_INDEX-1))

    # Unknown language fallback
    if [ -z "${TRACK_LANGUAGE}" ]; then
        if [ ${UNKNOWN_LANGUAGE_TRACKS_COUNT} -gt 1 ]; then
            TRACK_LANGUAGE="UNKNOWN_LANGUAGE_TRACK${TRACK_ID}"
        else
            TRACK_LANGUAGE="ENG"
        fi
    fi

    # Clean up any existing file
    SUBTITLE_FILE_PATH="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.${TRACK_LANGUAGE}.srt"
    [ -f "${SUBTITLE_FILE_PATH}" ] && rm "${SUBTITLE_FILE_PATH}"

    # Build ffmpeg arg
    SUBTITLES_FFMPEG_ARGUMENTS="${SUBTITLES_FFMPEG_ARGUMENTS} -map 0:s:${SUBTITLE_TRACK_INDEX} -c:s srt extractedSubtitleFile.${SESSION_ID}.${TRACK_LANGUAGE}.srt"
done
```

### 5. Extraction Execution (Lines 412-415)
```bash
echo "Extracting the subtitles..."
ffmpeg -i "${FILE_PATH}" ${SUBTITLES_FFMPEG_ARGUMENTS}
```

### 6. Deduplication (Lines 417-435)
```bash
TEMP_SUBTITLE_FILE_PREFIX="extractedSubtitleFile.${SESSION_ID}"

# Chinese - Simplified
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "CHI" "CHI2" "CHI"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "CHI" "CHI3" "CHI"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "CHI" "CHI-繁體" "CHI"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "CHI-简体" "CHI-繁體" "CHI"

# French - France
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "FRE" "FRE-Canada" "FRE"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "FRE-France" "FRE" "FRE"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "FRE-France" "FRE-Canada" "FRE"

# Portuguese - Portugal
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "POR" "POR-Brazil" "POR"

# Spanish - Spain
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "SPA" "SPA-LatinAmerica" "SPA"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "SPA-España" "SPA" "SPA"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "SPA-Europe" "SPA-LatinAmerica" "SPA"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "SPA-Spain" "SPA" "SPA"
replaceDuplicatedSubtitles "${TEMP_SUBTITLE_FILE_PREFIX}" "SPA-Spain" "SPA-LatinAmerica" "SPA"
```

### 7. fix-subtitle Post-Processing (Lines 437-442)
```bash
if [ -f "/usr/bin/fix-subtitle" ]; then
    for EXTRACTED_SUBTITLE_FILE in "${TEMP_SUBTITLE_FILE_PREFIX}."*; do
        fix-subtitle --noconfirm "${EXTRACTED_SUBTITLE_FILE}"
    done
fi
```
- Runs if `fix-subtitle` binary exists at `/usr/bin/fix-subtitle`
- Processes each extracted file with `--noconfirm` flag

### 8. Final Rename (Lines 444-445)
```bash
perl-rename 's/'"${TEMP_SUBTITLE_FILE_PREFIX}"'/'"${OUTPUT_FILE_NAME}"'/g' "${FILE_DIRECTORY}"/*
```
- Strips session prefix: `extractedSubtitleFile.{SESSION}.{LANG}.srt` → `{OUTPUT_NAME}.{LANG}.srt`
- Requires `perl-rename` (prename) installed

## Language Detection Priority

1. **Track name pattern matching** (35 languages) — `getSubtitleLanguage` checks normalised name
2. **mkvinfo Language field** — fallback if name match fails
3. **Default to ENG** — single unknown track defaults to English
4. **Unique naming** — multiple unknown tracks get `UNKNOWN_LANGUAGE_TRACK{ID}`

## Duplicate Handling

| Scenario | First Track | Second Track | Result |
|----------|-------------|--------------|--------|
| Same language, no variant | ENG | ENG | ENG, ENG-2 |
| Same language, variant in name | ENG | ENG (Director's Commentary) | ENG, ENG-DirectorsCommentary2 |
| Chinese variants | CHI | CHI2 | CHI (kept), CHI2 removed |
| Chinese Simplified/Traditional | CHI-简体 | CHI-繁體 | CHI (kept) |

## Configuration Impact

| Option | Default | Effect on Extraction |
|--------|---------|---------------------|
| `KEEP_FORCED_SUBTITLES` | `false` | Forced tracks skipped entirely |
| `KEEP_SDH_SUBTITLES` | `false` | SDH tracks skipped entirely |

## Dependencies

| Tool | Required? | Purpose |
|------|-----------|---------|
| `ffmpeg` | Yes | Subtitle extraction to SRT |
| `perl-rename` | Yes | Batch rename temp files |
| `fix-subtitle` | No | Optional post-processing |

## Invariants

1. **Only text subtitles extracted** — PGS/VobSub never extracted
2. **Forced/SDH excluded by default** — config opt-in only
3. **Session ID in temp names** — prevents collision on concurrent runs
4. **Deduplication rules hardcoded** — specific to common release patterns
5. **Output: one .srt per unique language** — canonical 3-letter codes
6. **Extraction happens BEFORE main optimisation** — subtitles removed from video output