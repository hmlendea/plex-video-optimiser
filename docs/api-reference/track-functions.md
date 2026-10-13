# Track Inspection Functions

## `getAudioTrackFormat`

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

**Description**: Extracts the audio codec format for a specific track index.

**Parameters**:
- `AUDIO_TRACK_INDEX` (int, 0-based): Track index (0 = first audio track)

**Returns**:
- String: Audio codec name (e.g., "AAC", "AC-3", "DTS", "TrueHD", "FLAC", "Opus", "MP3", "PCM", "E-AC-3")
- Empty string if track index out of range

**Dependencies**: `mkvmerge`

**Example**:
```bash
getAudioTrackFormat 0  # → "AAC"
getAudioTrackFormat 1  # → "DTS-HD MA"
```

---

## `getAudioTrackName`

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

**Description**: Extracts the human-readable name of an audio track.

**Parameters**:
- `AUDIO_TRACK_INDEX` (int, 0-based): Track index

**Returns**:
- String: Track name (e.g., "English", "Commentary", "Surround 5.1")
- Empty string if no format found

**Logic**:
1. Get audio format for track index
2. Determine first track type (video/audio/subtitle)
3. If first track is video, increment track ID (audio tracks are 1-indexed after video)
4. Extract name from mkvinfo

**Dependencies**: `getAudioTrackFormat`, `getFirstTrackType`, `getTrackName`

---

## `getSubtitleTrackName`

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

**Description**: Extracts and normalises the subtitle track name.

**Parameters**:
- `TRACK_ID` (int, 0-based): mkvmerge track ID

**Returns**:
- String: Normalised track name (e.g., "English", "Spanish (LatinAmerica)", "Forced", "SDH")

**Normalisation Pipeline**:
1. Region variant standardisation (Brazil, Canada, LatinAmerica, Europe)
2. Region moved to parenthetical suffix
3. "[Full]" marker removed
4. Native script names translated to English (35 languages)
5. Whitespace trimmed

**Dependencies**: `getTrackName`

---

## `getTrackName`

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

**Description**: Extracts the raw track name from mkvinfo output for a given track number.

**Parameters**:
- `TRACK_ID` (int, 1-based): mkvinfo track number

**Returns**:
- String: Raw track name

**Algorithm**:
1. Increment track ID (mkvinfo numbering offset)
2. Find begin line of track block in mkvinfo output
3. Find end line (next track block marker)
4. Extract "+ Name:" line from the block
5. Trim whitespace

**Dependencies**: `mkvinfo`

---

## `getTrackLanguage`

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

**Description**: Extracts the language code from mkvinfo track metadata.

**Parameters**:
- `TRACK_ID` (int, 1-based): mkvinfo track number

**Returns**:
- String: Uppercase 3-letter language code (e.g., "ENG", "SPA", "FRE")
- Empty string if no language field found

**Dependencies**: `mkvinfo`

---

## `getFirstTrackType`

```bash
function getFirstTrackType {
    mkvinfo "${FILE_PATH}" | \
        grep "Track type:" | \
        head -n 1 | \
        awk -F':' '{print $2}' | \
        sed -e 's/^\s*//g' -e 's/\s*$//g'
}
```

**Description**: Determines the type of the first track in the file (video, audio, or subtitle).

**Parameters**: None (uses global `FILE_PATH`)

**Returns**:
- String: Track type ("video", "audio", "subtitle")

**Dependencies**: `mkvinfo`

---

## `isAudioTrackFormatOk`

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

**Description**: Checks if an audio track is already in a preferred format.

**Parameters**:
- `AUDIO_TRACK_INDEX` (int, 0-based): Track index

**Returns**:
- 0 (true): AAC or MP3
- 1 (false): any other format

**Dependencies**: `getAudioTrackFormat`

---

## `isAudioTrackCommentary`

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

**Description**: Detects commentary tracks by name.

**Parameters**:
- `AUDIO_TRACK_INDEX` (int, 0-based): Track index

**Returns**:
- 0 (true): Name contains "Commentary" (case-insensitive)
- 1 (false): No match

**Dependencies**: `getAudioTrackName`

---

## `isAudioTrackDiscardable`

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

**Description**: Determines if an audio track should be dropped from the output.

**Parameters**:
- `AUDIO_TRACK_INDEX` (int, 0-based): Track index

**Returns**:
- 0 (true): Commentary, AC-3, AC-3 Dolby Surround EX, E-AC-3, MP3, Opus, PCM
- 1 (false): All other formats (DTS, TrueHD, FLAC, DTS-X, DTS-MA, etc.)

**Dependencies**: `isAudioTrackCommentary`, `getAudioTrackFormat`

---

## `isSubtitleTrackDiscardable`

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

**Description**: Determines if a subtitle track should be skipped during extraction.

**Parameters**:
- `TRACK_ID` (int, 0-based): Track ID (accepts variable args)

**Returns**:
- 0 (true): Forced or SDH track (when not kept)
- 1 (false): Regular subtitle track

**Dependencies**: Global `KEEP_FORCED_SUBTITLES`, `KEEP_SDH_SUBTITLES`, `TRACK_NAME`

**Note**: Relies on caller setting global `TRACK_NAME` before calling.

---

## `doesTrackNameMatch`

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

**Description**: Case-insensitive pattern match against a track name.

**Parameters**:
- `TRACK_NAME` (string): Track name to match
- `MATCH_PATTERN` (string): grep-compatible regex pattern

**Returns**:
- 0 (true): Pattern found
- 1 (false): No match

**Dependencies**: None

---

## `getSubtitleLanguage`

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

**Description**: Determines the 3-letter ISO-639-2 language code for a subtitle track.

**Parameters**:
- `TRACK_ID` (int, 0-based): Track ID

**Returns**:
- String: 3-letter language code (e.g., "ENG", "SPA", "CHI")
- Empty string if neither name match nor mkvinfo language found

**Detection Priority**:
1. Track name pattern matching (35 languages)
2. mkvinfo `Language` field fallback
3. Empty if both fail

**Dependencies**: `getSubtitleTrackName`, `doesTrackNameMatch`, `getTrackLanguage`

---

## `replaceDuplicatedSubtitles`

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

**Description**: Deduplicates subtitle files when multiple tracks map to the same language.

**Parameters**:
- `SUBTITLE_FILE_NAME` (string): Base filename (without language suffix)
- `LANGUAGE_TO_KEEP` (string): Language code to keep
- `LANGUAGE_TO_REMOVE` (string): Language code to remove
- `LANGUAGE_NAME` (string): Canonical output language code

**Returns**: None (side effects: rm/mv)

**Logic**:
1. If keep file doesn't exist → return (no action)
2. If remove file doesn't exist → return (no action)
3. If output differs from remove file → delete remove file
4. If output differs from keep file → rename keep file to output

**Dependencies**: None (uses shell `rm`/`mv`)

**Hardcoded Deduplication Rules** (see [subtitle-extraction.md](../flows/subtitle-extraction.md)):
- Chinese: CHI, CHI2, CHI3, CHI-繁體, CHI-简体 → CHI
- French: FRE, FRE-Canada, FRE-France → FRE
- Portuguese: POR, POR-Brazil → POR
- Spanish: SPA, SPA-LatinAmerica, SPA-España, SPA-Europe, SPA-Spain → SPA