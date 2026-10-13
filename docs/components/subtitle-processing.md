# Subtitle Processing

## Overview

Subtitle extraction, language detection, forced/SDH filtering, and deduplication logic. The script extracts text-based subtitles (SRT, SubStationAlpha), normalises language names, removes duplicates, and optionally post-processes with `fix-subtitle`.

## Functions

### `getSubtitleTrackName`

```bash
function getSubtitleTrackName {
    local TRACK_ID="${1}"
    local LANGUAGE_VARIANTS_PATTERN="[Bb]razil\|[Cc]anada\|[Ee]urope"

    getTrackName "${TRACK_ID}" | \
        sed -e 's/[Bb]rasil\|[Bb]razilian/Brazil/g' \
            -e 's/[Cc]anadi[ae]n/Canada/g' \
            -e 's/[Ll]atin[o]*[Aa]m[eé]rica[n]*[o]*/LatinAmerica/g' \
            -e 's/[Ee]uropean/Europe/g' | \
        sed -e 's/^\('"${LANGUAGE_VARIANTS_PATTERN}"'\)\s\s*\(.*\)/\2 (\1)/g' \
            -e 's/\(.*\)\s\s*\('"${LANGUAGE_VARIANTS_PATTERN}"'\)$/\1 (\2)/g' | \
        sed -e 's/\[Full\]//g' | \
        sed -e 's/^العربية/Arabic/g' \
            -e 's/^中文/Chinese/g' \
            -e 's/^(廣東話\|[Yy]ue)/Cantonese/g' \
            -e 's/^日本語/Japanese/g' \
            -e 's/^한국어/Korean/g' \
            -e 's/^български/Bulgarian/g' \
            -e 's/^Čeština/Czech/g' \
            -e 's/^[Dd]ansk/Danish/g' \
            -e 's/^[Nn]ederlands/Dutch/g' \
            -e 's/^[Ee]esti/Estonian/g' \
            -e 's/^[Ss]uomi/Finnish/g' \
            -e 's/^[Ff]rançais/French/g' \
            -e 's/^[Dd]eutsch/German/g' \
            -e 's/^Ελληνικά/Greek/g' \
            -e 's/^עברית/Hebrew/g' \
            -e 's/^Bahasa Indonesia/Indonesian/g' \
            -e 's/^[Ii]taliano/Italian/g' \
            -e 's/^[Mm]agyar/Hungarian/g' \
            -e 's/^[Ll]atvie[sš]u/Latvian/g' \
            -e 's/^[Ll]ietuvi[uų]/Lithuanian/g' \
            -e 's/^Bahasa Melayu/Malaysian/g' \
            -e 's/^[Nn]orsk/Norwegian/g' \
            -e 's/^[Pp]olski/Polish/g' \
            -e 's/^[Pp]ortuguês/Portuguese/g' \
            -e 's/^[Rr]om[aâ]n[aă]/Romanian/g' \
            -e 's/^Русский/Russian/g' \
            -e 's/^[Ee]spañol/Spanish/g' \
            -e 's/^[Ss]venska/Swedish/g' \
            -e 's/^தமிழ்/Tamil/g' \
            -e 's/^తెలుగు/Telugu/g' \
            -e 's/^ไทย/Thai/g' \
            -e 's/^українська/Ukrainian/g' \
            -e 's/^Tiếng Việt/Vietnamese/g' | \
        sed -e 's/^\s*//g' \
            -e 's/\s*$//g'
}
```

**Purpose**: Extract and normalise subtitle track name from mkvinfo.

**Input**: `TRACK_ID` (mkvmerge track ID, 0-based)

**Output**: Normalised track name (e.g., "English", "Spanish (LatinAmerica)", "Forced", "SDH")

**Normalisation Pipeline**:
1. Region variant standardisation (Brazil, Canada, LatinAmerica, Europe)
2. Move region to parenthetical suffix: "Brazil Portuguese" → "Portuguese (Brazil)"
3. Remove "[Full]" marker
4. Translate native script names to English (Arabic, Chinese, Japanese, Korean, Cyrillic, etc.)
5. Trim whitespace

---

### `getTrackName` (shared)

```bash
function getTrackName {
    local TRACK_ID="${1}"
    local TRACK_ID_MKVINFO=-1
    local MKVINFO_TRACK_BEGIN_LINE=-1
    local MKVINFO_TRACK_END_LINE=-1
    local MKVINFO_TRACK_LINES_COUNT=-1
    local TRACK_NAME=""

    TRACK_ID_MKVINFO=$((TRACK_ID+1))
    MKVINFO_TRACK_BEGIN_LINE=$(mkvinfo "${FILE_PATH}" | grep -n "+ Track number: ${TRACK_ID_MKVINFO}" | awk -F: '{print $1}' | head -n 1)
    MKVINFO_TRACK_END_LINE=$(mkvinfo "${FILE_PATH}" | tail --lines=+"${MKVINFO_TRACK_BEGIN_LINE}" | grep -n "\(| +\||+\)" | head -n 1 | awk -F: '{print $1}')
    MKVINFO_TRACK_END_LINE=$((MKVINFO_TRACK_BEGIN_LINE+MKVINFO_TRACK_END_LINE-2))
    MKVINFO_TRACK_LINES_COUNT=$((MKVINFO_TRACK_END_LINE-MKVINFO_TRACK_BEGIN_LINE+1))

    mkvinfo "${FILE_PATH}" | \
        tail --lines=+"${MKVINFO_TRACK_BEGIN_LINE}" | \
        head -n "${MKVINFO_TRACK_LINES_COUNT}" | \
        grep "+ Name:" | \
        awk -F: '{print $2}' | \
        sed -e 's/^\s*//g' -e 's/\s*$//g'
}
```

**Purpose**: Extract raw track name from mkvinfo output for a given track number.

**Input**: `TRACK_ID` (mkvinfo track number, 1-based internally)

**Output**: Raw track name string

---

### `getTrackLanguage` (shared)

```bash
function getTrackLanguage {
    local TRACK_ID="${1}"
    local TRACK_ID_MKVINFO=-1
    local MKVINFO_TRACK_BEGIN_LINE=-1
    local MKVINFO_TRACK_END_LINE=-1
    local MKVINFO_TRACK_LINES_COUNT=-1
    local TRACK_LANGUAGE=""

    TRACK_ID_MKVINFO=$((TRACK_ID+1))
    MKVINFO_TRACK_BEGIN_LINE=$(mkvinfo "${FILE_PATH}" | grep -n "+ Track number: ${TRACK_ID_MKVINFO}" | awk -F: '{print $1}' | head -n 1)
    MKVINFO_TRACK_END_LINE=$(mkvinfo "${FILE_PATH}" | tail --lines=+"${MKVINFO_TRACK_BEGIN_LINE}" | grep -n "\(| +\||+\)" | head -n 1 | awk -F: '{print $1}')
    MKVINFO_TRACK_END_LINE=$((MKVINFO_TRACK_BEGIN_LINE+MKVINFO_TRACK_END_LINE-2))
    MKVINFO_TRACK_LINES_COUNT=$((MKVINFO_TRACK_END_LINE-MKVINFO_TRACK_BEGIN_LINE+1))
    TRACK_LANGUAGE=$(mkvinfo "${FILE_PATH}" | \
                        tail --lines=+"${MKVINFO_TRACK_BEGIN_LINE}" | \
                        head -n "${MKVINFO_TRACK_LINES_COUNT}" | \
                        grep "+ Language:" | \
                        awk -F: '{print toupper($2)}' | \
                        sed 's/ //g')

    echo "${TRACK_LANGUAGE}"
}
```

**Purpose**: Extract language code from mkvinfo track metadata.

**Input**: `TRACK_ID` (mkvinfo track number)

**Output**: Uppercase 3-letter language code (e.g., "ENG", "SPA", "FRE") or empty

---

### `isSubtitleTrackDiscardable`

```bash
function isSubtitleTrackDiscardable {
    local TRACK_ID="${*}"

    if (! ${KEEP_FORCED_SUBTITLES}); then
        [[ "${TRACK_NAME}" == *"Forced"* ]] && return 0 # True
    fi

    if (! ${KEEP_SDH_SUBTITLES}); then
        [[ "${TRACK_NAME}" == *"SDH"* ]] && return 0 # True
    fi

    return 1 # False
}
```

**Purpose**: Determine if a subtitle track should be excluded from extraction.

**Logic**:
- If `KEEP_FORCED_SUBTITLES=false` (default): discard tracks with "Forced" in name
- If `KEEP_SDH_SUBTITLES=false` (default): discard tracks with "SDH" in name
- Otherwise: keep

**Note**: Uses global `TRACK_NAME` variable set by caller.

---

### `doesTrackNameMatch`

```bash
function doesTrackNameMatch {
    local TRACK_NAME="${1}"
    local MATCH_PATTERN="${2}"
    local MATCHES_COUNT=0

    MATCHES_COUNT=$(echo "${TRACK_NAME}" | grep -c "${MATCH_PATTERN}")

    if [ "${MATCHES_COUNT}" -gt 0 ]; then
        return 0 # True
    else
        return 1 # False
    fi
}
```

**Purpose**: Case-insensitive pattern match against track name.

**Returns**: 0 (match), 1 (no match)

---

### `getSubtitleLanguage`

```bash
function getSubtitleLanguage {
    local TRACK_ID="${*}"
    local TRACK_LANGUAGE=""
    local TRACK_NAME=$(getSubtitleTrackName "${TRACK_ID}")

    doesTrackNameMatch "${TRACK_NAME}" "[Aa]rabic"      && TRACK_LANGUAGE="ARA"
    doesTrackNameMatch "${TRACK_NAME}" "[Bb]ulgarian"   && TRACK_LANGUAGE="BUL"
    doesTrackNameMatch "${TRACK_NAME}" "[Cc]antonese"   && TRACK_LANGUAGE="YUE"
    doesTrackNameMatch "${TRACK_NAME}" "[Cc]hinese"     && TRACK_LANGUAGE="CHI"
    doesTrackNameMatch "${TRACK_NAME}" "[Cc]zech"       && TRACK_LANGUAGE="CZE"
    doesTrackNameMatch "${TRACK_NAME}" "[Dd]anish"      && TRACK_LANGUAGE="DAN"
    doesTrackNameMatch "${TRACK_NAME}" "[Dd]utch"       && TRACK_LANGUAGE="DUT"
    doesTrackNameMatch "${TRACK_NAME}" "[Ee]nglish"     && TRACK_LANGUAGE="ENG"
    doesTrackNameMatch "${TRACK_NAME}" "[Ee]stonian"    && TRACK_LANGUAGE="EST"
    doesTrackNameMatch "${TRACK_NAME}" "[Ff]innish"     && TRACK_LANGUAGE="FIN"
    doesTrackNameMatch "${TRACK_NAME}" "[Ff]rench"      && TRACK_LANGUAGE="FRE"
    doesTrackNameMatch "${TRACK_NAME}" "[Gg]erman"      && TRACK_LANGUAGE="GER"
    doesTrackNameMatch "${TRACK_NAME}" "[Gg]reek"       && TRACK_LANGUAGE="GRE"
    doesTrackNameMatch "${TRACK_NAME}" "[Hh]ebrew"      && TRACK_LANGUAGE="HEB"
    doesTrackNameMatch "${TRACK_NAME}" "[Hh]indi"       && TRACK_LANGUAGE="HIN"
    doesTrackNameMatch "${TRACK_NAME}" "[Hh]ungarian"   && TRACK_LANGUAGE="HUN"
    doesTrackNameMatch "${TRACK_NAME}" "[Ii]ndonesian"  && TRACK_LANGUAGE="IND"
    doesTrackNameMatch "${TRACK_NAME}" "[Ii]talian"     && TRACK_LANGUAGE="ITA"
    doesTrackNameMatch "${TRACK_NAME}" "[Jj]apanese"    && TRACK_LANGUAGE="JAP"
    doesTrackNameMatch "${TRACK_NAME}" "[Kk]orean"      && TRACK_LANGUAGE="KOR"
    doesTrackNameMatch "${TRACK_NAME}" "[Ll]atvian"     && TRACK_LANGUAGE="LAV"
    doesTrackNameMatch "${TRACK_NAME}" "[Ll]ithuanian"  && TRACK_LANGUAGE="LIT"
    doesTrackNameMatch "${TRACK_NAME}" "[Mm]alay"       && TRACK_LANGUAGE="MAY"
    doesTrackNameMatch "${TRACK_NAME}" "[Nn]orwegian"   && TRACK_LANGUAGE="NOR"
    doesTrackNameMatch "${TRACK_NAME}" "[Pp]olish"      && TRACK_LANGUAGE="POL"
    doesTrackNameMatch "${TRACK_NAME}" "[Pp]ortuguese"  && TRACK_LANGUAGE="POR"
    doesTrackNameMatch "${TRACK_NAME}" "[Rr]omanian"    && TRACK_LANGUAGE="RUM"
    doesTrackNameMatch "${TRACK_NAME}" "[Rr]ussian"     && TRACK_LANGUAGE="RUS"
    doesTrackNameMatch "${TRACK_NAME}" "[Ss]lovak"      && TRACK_LANGUAGE="SLO"
    doesTrackNameMatch "${TRACK_NAME}" "[Ss]lovenian"   && TRACK_LANGUAGE="SLV"
    doesTrackNameMatch "${TRACK_NAME}" "[Ss]panish"     && TRACK_LANGUAGE="SPA"
    doesTrackNameMatch "${TRACK_NAME}" "[Ss]wedish"     && TRACK_LANGUAGE="SWE"
    doesTrackNameMatch "${TRACK_NAME}" "[Tt]amil"       && TRACK_LANGUAGE="TAM"
    doesTrackNameMatch "${TRACK_NAME}" "[Tt]elugu"      && TRACK_LANGUAGE="TEL"
    doesTrackNameMatch "${TRACK_NAME}" "[Tt]hai"        && TRACK_LANGUAGE="THA"
    doesTrackNameMatch "${TRACK_NAME}" "[Tt]urkish"     && TRACK_LANGUAGE="TUR"
    doesTrackNameMatch "${TRACK_NAME}" "[Uu]krainian"   && TRACK_LANGUAGE="UKR"
    doesTrackNameMatch "${TRACK_NAME}" "[Vv]ietmanese"  && TRACK_LANGUAGE="VIE"

    [ -z "${TRACK_LANGUAGE}" ] && TRACK_LANGUAGE=$(getTrackLanguage "${TRACK_ID}")

    echo "${TRACK_LANGUAGE}"
}
```

**Purpose**: Determine 3-letter ISO-639-2 language code for a subtitle track.

**Priority**:
1. Match normalised track name against known language patterns (35 languages)
2. Fallback to mkvinfo `Language` field
3. Empty if neither works

**Output**: 3-letter code (e.g., "ENG", "SPA", "CHI") or empty

---

### `replaceDuplicatedSubtitles`

```bash
function replaceDuplicatedSubtitles {
    local SUBTITLE_FILE_NAME="${1}"
    local LANGUAGE_TO_KEEP="${2}"
    local LANGUAGE_TO_REMOVE="${3}"
    local LANGUAGE_NAME="${4}"

    local SUBTITLE_FILE_TO_KEEP="${SUBTITLE_FILE_NAME}.${LANGUAGE_TO_KEEP}.srt"
    local SUBTITLE_FILE_TO_REMOVE="${SUBTITLE_FILE_NAME}.${LANGUAGE_TO_REMOVE}.srt"
    local SUBTITLE_FILE_OUTPUT="${SUBTITLE_FILE_NAME}.${LANGUAGE_NAME}.srt"

    [ ! -f "${SUBTITLE_FILE_TO_KEEP}" ] && return
    [ ! -f "${SUBTITLE_FILE_TO_REMOVE}" ] && return

    if [[ "${SUBTITLE_FILE_OUTPUT}" != "${SUBTITLE_FILE_TO_REMOVE}" ]]; then
        echo "Removing the ${LANGUAGE_TO_REMOVE} subtitle"
        rm "${SUBTITLE_FILE_TO_REMOVE}"
    fi

    if [[ "${SUBTITLE_FILE_OUTPUT}" != "${SUBTITLE_FILE_TO_KEEP}" ]]; then
        echo "Renaming the '${LANGUAGE_TO_KEEP}' subtitle to '${LANGUAGE_NAME}'"
        mv "${SUBTITLE_FILE_TO_KEEP}" "${SUBTITLE_FILE_OUTPUT}"
    fi
}
```

**Purpose**: Deduplicate subtitle files when multiple tracks map to same language.

**Logic**: Keep the first variant, remove others, rename to canonical language code.

**Hardcoded Deduplication Rules** (in main flow):
| Keep | Remove | Output |
|------|--------|--------|
| CHI | CHI2, CHI3, CHI-繁體 | CHI |
| CHI-简体 | CHI-繁體 | CHI |
| FRE | FRE-Canada | FRE |
| FRE-France | FRE, FRE-Canada | FRE |
| POR | POR-Brazil | POR |
| SPA | SPA-LatinAmerica | SPA |
| SPA-España | SPA, SPA-LatinAmerica | SPA |
| SPA-Europe | SPA-LatinAmerica | SPA |
| SPA-Spain | SPA, SPA-LatinAmerica | SPA |

---

## Main Flow Integration

### Subtitle Track Discovery
```bash
SUBTITLE_TRACKS=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" | grep "\(SRT\|SubStationAlpha\)" | awk '{print $3}' | awk -F: '{print $1}')
```
- Only **text-based** subtitles (SRT, SubStationAlpha/SSA/ASS)
- Image-based (PGS, VobSub) ignored

### Extraction (Interactive)
```bash
SUBTITLES_FFMPEG_ARGUMENTS="${SUBTITLES_FFMPEG_ARGUMENTS} -map 0:s:${SUBTITLE_TRACK_INDEX} -c:s srt extractedSubtitleFile.${SESSION_ID}.${TRACK_LANGUAGE}.srt"
```
- Each track → separate `.srt` file
- Named with session ID + language code

### Post-Processing
1. **Deduplication** — `replaceDuplicatedSubtitles` for known variants
2. **fix-subtitle** — if available, runs on each extracted file
3. **Rename** — `perl-rename` strips session prefix: `extractedSubtitleFile.{SESSION}.{LANG}.srt` → `{OUTPUT_NAME}.{LANG}.srt`

---

## Configuration Options

| Option | Default | Effect |
|--------|---------|--------|
| `KEEP_FORCED_SUBTITLES` | `false` | Keep "Forced" subtitle tracks |
| `KEEP_SDH_SUBTITLES` | `false` | Keep "SDH" (Subtitles for Deaf/Hard of Hearing) tracks |

---

## Invariants

1. **Only text subtitles extracted** — PGS/VobSub ignored
2. **Forced/SDH discarded by default** — opt-in via config
3. **Language detection: name-based first, metadata fallback**
4. **Deduplication rules hardcoded** — specific to common release patterns
5. **Output: one .srt per unique language** — canonical naming
6. **Session ID isolates temp files** — safe concurrent runs