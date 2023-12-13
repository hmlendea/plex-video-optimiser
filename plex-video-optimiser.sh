#!/bin/bash

FILE_PATH="$*"

if [ ! -f "${FILE_PATH}" ]; then
    echo "Cannot access '${FILE_PATH}': No such file or directory"
    exit 1
fi

# Options
KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false
KEEP_FORCED_SUBTITLES=false
KEEP_SDH_SUBTITLES=false

FILE_BASENAME=$(basename -- "$FILE_PATH")
FILE_EXTENSION="${FILE_BASENAME##*.}"
FILE_NAME="${FILE_BASENAME%.*}"
FILE_DIRECTORY=$(dirname "${FILE_PATH}")

SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

IS_TVSHOW_EPISODE=false
IS_OPTIMISABLE=false
FFMPEG_ARGUMENTS=""

OUTPUT_FILE_NAME=${FILE_NAME}
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/\.mkv$//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(AMIABLE\|BAE\|BLUEBIRD\|BluHD\|BLUTONiUM\|BTN\|cakes\|CasStudio\|CHD\|CRiSC\|CtrlHD\|decibeL\|EbP\|ETRG\|FLUX\|FraMeSToR\|FREEHK\|ggez\|GOLDIES\|HDMaN\|iNTERNAL\|L0L\|LazyStudio\|lightspeed\|MovietaM\|MTeam\|MZABI\|NiXON\|NTb\|pawel2006\|PETFRiFiED\|playBD\|[Pp][Ss][Yy][Cc][Hh][Dd]\|t3nzin\|TENEIGHTY\|TOMMY\|TrollUHD\|ZON3\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\([Dd][Vv][Dd]\|[Pp][Aa][Ll]\|[Ww][Ss]\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(720p\|1080p\|2160[p]*\|4K\|UHD\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(10bit\|BT2020\|Chroma[\ \.]422[\ \.]Edition\|VISIONPLUS\|HDR1000\|HDR\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(AVC\|D[o]*V[i]*\|[Dd][Xx][Vv][Aa]\|HEVC\|[xX]26[45]\([Hh][Ii]10\)*\|[Hh]\.*26[45]\|-AJP69\|[Bb]lu-*[Rr]ay\|VC-1\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(Amazon\|AMZN\|ATVP\|Disney\|DSNP\|Vimeo\|[Ww][Ee][Bb]\(-DL\)*\|WEBRip\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(REPACK\|Remux\|REMUX\|RoSubbed\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(AC3\|AAC2\.0\|Atmos\|[Dd][Dd][Pp]*2\.0\|DTS-MA\|DTS-X\|DTS\|HD[-\ \.]MA\|LPCM\|DD+\|DD[P]*[\.]*[567]\.1\|DTSX\|FLAC[-\ \.][567]\.1\|TrueHD\|[567]\.1\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[-\ \.]*\(Director.s[. ]Cut\|Extended\([. ]Edition\)*\)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | iconv -f utf-8 -t ascii//translit)
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's@\(?\|!\|\\\|/\)@@g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/\./ /g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/\(19\|20\)[0-9][0-9]//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/-/ /g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/(\s*)//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/\s\s*/ /g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/\s*$//g')
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/[Ss]\([0-9][0-9]*\)[Ee]\([0-9][0-9]*\)/S\1E\2/g')
OUTPUT_FILE_PATH_WITHOUT_EXTENSION="${FILE_DIRECTORY}/${OUTPUT_FILE_NAME}"

FILE_NAME_TVSHOW_EPISODE_MATCHES_COUNT=$(echo "${FILE_NAME}" | grep -E "[Ss][0-9]+[Ee][0-9]+" -c)
if [ "${FILE_NAME_TVSHOW_EPISODE_MATCHES_COUNT}" -gt 0 ]; then
    IS_TVSHOW_EPISODE=true
fi

function getVideoTrackFormat {
    local VIDEO_TRACK_FORMAT=""

    VIDEO_TRACK_FORMAT=$(mkvmerge -i "${FILE_PATH}" | \
                            grep -E "Track ID [0-9]+: video" | \
                            head -n 1 | tail -n 1 | \
                            awk -F "(" '{print $2}' | awk -F ")" '{print $1}')

    echo "${VIDEO_TRACK_FORMAT}"
}

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
            -e 's/^Tiếng Việt/Vietnamese/g'
}

function getTrackName {
    local TRACK_ID="${1}"
    local TRACK_ID_MKVINFO=-1
    local MKVINFO_TRACK_BEGIN_LINE=-1
    local MKVINFO_TRACK_END_LINE=-1
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

function getTrackLanguage {
    local TRACK_ID="${1}"
    local TRACK_ID_MKVINFO=-1
    local MKVINFO_TRACK_BEGIN_LINE=-1
    local MKVINFO_TRACK_END_LINE=-1
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

function getFirstTrackType {
    mkvinfo "${FILE_PATH}" | \
        grep "Track type:" | \
        head -n 1 | \
        awk -F':' '{print $2}' | \
        sed -e 's/^\s*//g' -e 's/\s*$//g'
}

echo "Gathering file info for ${FILE_PATH} ..."
CONTAINER_FORMAT=$(mkvmerge -i "${FILE_PATH}" | head -n 1 | awk -F: '{print $3}' | sed 's/ //g')
VIDEO_FORMAT=$(getVideoTrackFormat)
AUDIO_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": audio" -c)

SUBTITLE_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" -c)

echo "Session ID: ${SESSION_ID}"
echo "Input file name: ${FILE_NAME}"
echo "Video format: ${VIDEO_FORMAT}"

for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")

    if [ -n "${AUDIO_TRACK_FORMAT}" ]; then
        AUDIO_TRACK_NAME=$(getAudioTrackName "${AUDIO_TRACK_INDEX}")

        printf "Audio ${AUDIO_TRACK_INDEX}: ${AUDIO_TRACK_FORMAT}"
        [ -n "${AUDIO_TRACK_NAME}" ] && printf " (${AUDIO_TRACK_NAME})"
        printf "\n"
    fi
done

echo "Output file name: ${OUTPUT_FILE_NAME}"

function isAudioTrackFormatOk {
    local AUDIO_TRACK_INDEX="${1}"
    local AUDIO_TRACK_FORMAT=""

    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")

    # AC-3 could cause some problems on some rare devices. It's better to just use AAC instead since it's not going to make a difference anyay
    if [[ "${AUDIO_TRACK_FORMAT}" == "AAC" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "MP3" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}

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

function getVideoFfmpegArgs {
    if [[ "${VIDEO_FORMAT}" == "AV1" ]] \
    || [[ "${VIDEO_FORMAT}" == "VP9" ]]; then
        echo "-map 0:v:0 -c:v:0 h264"
    else
        echo ""
    fi
}

function getAudioFfmpegArgs {
    local FFMPEG_AUDIO_TRACK_ARGS=""
    local OUTPUT_AUDIO_TRACKS_COUNT=0
    local COPIED_AUDIO_TRACK_INDEX=-1
    local MODIFICATIONS_APPLIED=false

    for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
        if isAudioTrackFormatOk "${AUDIO_TRACK_INDEX}"; then
            FFMPEG_AUDIO_TRACK_ARGS="-map 0:a:${AUDIO_TRACK_INDEX} -c:a:0 copy"
            OUTPUT_AUDIO_TRACKS_COUNT=1
            COPIED_AUDIO_TRACK_INDEX=${AUDIO_TRACK_INDEX}
            [[ "${AUDIO_TRACK_INDEX}" != "0" ]] && MODIFICATIONS_APPLIED=true
            break
        fi
    done

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

    if (! ${IS_TVSHOW_EPISODE}) || ${KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS}; then
        for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < AUDIO_TRACKS_COUNT; AUDIO_TRACK_INDEX++)); do
            #if isAudioTrackDiscardable ${AUDIO_TRACK_INDEX} ; then
            #    FFMPEG_AUDIO_TRACK_ARGS="${FFMPEG_AUDIO_TRACK_ARGS} -map -0:a:${AUDIO_TRACK_INDEX}"
            #else
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

#    [[ "${FFMPEG_AUDIO_TRACK_ARGS}" != "-map 0:a:0 -c:a:0 copy" ]] && echo "${FFMPEG_AUDIO_TRACK_ARGS}"
    ${MODIFICATIONS_APPLIED} && echo "${FFMPEG_AUDIO_TRACK_ARGS}"
}

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

function replaceDuplicatedSubtitles {
    local SUBTITLE_FILE_NAME="${1}"
    local LANGUAGE_TO_KEEP="${2}"
    local LANGUAGE_TO_REMOVE="${3}"
    local LANGUAGE_NAME="${4}"

    # TODO: Support other formats also
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

VIDEO_FFMPEG_ARGUMENTS=$(getVideoFfmpegArgs)
AUDIO_FFMPEG_ARGUMENTS=$(getAudioFfmpegArgs)

if [ -n "${VIDEO_FFMPEG_ARGUMENTS}" ]; then
    echo "Video track needs conversion!"
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${VIDEO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="-map 0:v:0 -c:v:0 copy"
fi

if [ -n "${AUDIO_FFMPEG_ARGUMENTS}" ]; then
    echo "Audio track needs conversion!"
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${AUDIO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map 0:a -c:a copy"
fi

if [ "${FILE_EXTENSION}" != "mkv" ] || [ "${CONTAINER_FORMAT}" != "Matroska" ]; then
    echo "File format needs conversion!"
    IS_OPTIMISABLE=true
    #FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map 0:a -c:a copy"
    FFMPEG_ARGUMENTS=""
fi

if [ "${SUBTITLE_TRACKS_COUNT}" -gt 0 ]; then
    echo "Subtitles need removal!"
    IS_OPTIMISABLE=true
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map -0:s"

    SUBTITLE_TRACKS=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" | grep "\(SRT\|SubStationAlpha\)" | awk '{print $3}' | awk -F: '{print $1}')

    if [ -z "${SUBTITLE_TRACKS}" ]; then
        echo "No text subtitles found!"
    else
        echo "Subtitle tracks found:"
        UNKNOWN_LANGUAGE_TRACKS_COUNT=0

        for TRACK_ID in ${SUBTITLE_TRACKS}; do
            TRACK_LANGUAGE=$(getSubtitleLanguage "${TRACK_ID}")
            TRACK_NAME=$(getSubtitleTrackName "${TRACK_ID}")

            isSubtitleTrackDiscardable "${TRACK_ID}" && continue

            if [ -z "${TRACK_LANGUAGE}" ]; then
                TRACK_LANGUAGE="(unknown)"
                UNKNOWN_LANGUAGE_TRACKS_COUNT=$((UNKNOWN_LANGUAGE_TRACKS_COUNT+1))
            fi

            printf "#${TRACK_ID}: ${TRACK_LANGUAGE}"
            [ -n "${TRACK_NAME}" ] && printf " (${TRACK_NAME})"
            printf "\n"
        done

        read -p "Do you want to save the subtitles before removing them? [Y/n] " -n 1 -r
        echo

        if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
            SUBTITLES_FFMPEG_ARGUMENTS=""
            TRACK_LANGUAGES=""

            for TRACK_ID in ${SUBTITLE_TRACKS}; do
                TRACK_LANGUAGE=$(getSubtitleLanguage "${TRACK_ID}")
                TRACK_NAME=$(getSubtitleTrackName "${TRACK_ID}")

                isSubtitleTrackDiscardable "${TRACK_ID}" && continue

                DUPLICATIONS=$(echo "${TRACK_LANGUAGES}" | sed 's/,/\n/g' | grep -c "${TRACK_LANGUAGE}")

                if [ -n "${TRACK_LANGUAGE}" ]; then
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
                fi

                SUBTITLE_TRACK_INDEX=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" | grep "^Track ID ${TRACK_ID}:" -n | awk -F: '{print $1}')
                SUBTITLE_TRACK_INDEX=$((SUBTITLE_TRACK_INDEX-1))

                if [ -z "${TRACK_LANGUAGE}" ]; then
                    if [ ${UNKNOWN_LANGUAGE_TRACKS_COUNT} -gt 1 ]; then
                        echo "Unknown language for subtitle track ${TRACK_ID}"
                        TRACK_LANGUAGE="UNKNOWN_LANGUAGE_TRACK${TRACK_ID}"
                    else
                        TRACK_LANGUAGE="ENG"
                    fi
                fi

                SUBTITLE_FILE_PATH="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.${TRACK_LANGUAGE}.srt"
                if [ -f "${SUBTITLE_FILE_PATH}" ]; then
                    rm "${SUBTITLE_FILE_PATH}"
                fi

                SUBTITLES_FFMPEG_ARGUMENTS="${SUBTITLES_FFMPEG_ARGUMENTS} -map 0:s:${SUBTITLE_TRACK_INDEX} -c:s srt extractedSubtitleFile.${SESSION_ID}.${TRACK_LANGUAGE}.srt"
            done
        fi
    fi
fi

if ${IS_OPTIMISABLE}; then
    OUTPUT_TEMP_FILE="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.OPTIMISED.mkv"
    OUTPUT_FILE="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.mkv"

    if [ -f "${OUTPUT_TEMP_FILE}" ]; then
        rm "${OUTPUT_TEMP_FILE}"
    fi

    du -sh "${FILE_PATH}"
    mkvmerge -i "${FILE_PATH}"

    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${CLEANUP_FFMPEG_ARGUMENTS}"

    if [ -n "${SUBTITLES_FFMPEG_ARGUMENTS}" ]; then
        echo "Extracting the subtitles..."
        ffmpeg -i "${FILE_PATH}" ${SUBTITLES_FFMPEG_ARGUMENTS}
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

        if [ -f "/usr/bin/fix-subtitle" ]; then
            for EXTRACTED_SUBTITLE_FILE in "${TEMP_SUBTITLE_FILE_PREFIX}."*; do
                fix-subtitle --noconfirm "${EXTRACTED_SUBTITLE_FILE}"
            done
        fi

        perl-rename 's/'"${TEMP_SUBTITLE_FILE_PREFIX}"'/'"${OUTPUT_FILE_NAME}"'/g' "${FILE_DIRECTORY}"/*
    fi

    echo "Output file: ${OUTPUT_TEMP_FILE}"
    echo "ffmpeg arguments:"
    echo "${FFMPEG_ARGUMENTS}"

    read -p "Are you sure you want to optimise the video with the mentioned settings? [Y/n] " -n 1 -r
    echo

    FINISHED_OPTIMISING="FALSE"

    if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
        echo "Optimising ${FILE_PATH}..."
        ffmpeg -i "${FILE_PATH}" ${FFMPEG_ARGUMENTS} "${OUTPUT_TEMP_FILE}"

        if [ ! -f "${OUTPUT_TEMP_FILE}" ]; then
            exit
        fi

        echo ">>> DONE!"
        FINISHED_OPTIMISING="TRUE"

        echo "Size before:"
        du -sh "${FILE_PATH}"
        echo "Size after:"
        du -sh "${OUTPUT_TEMP_FILE}"

        mkvmerge -i "${OUTPUT_TEMP_FILE}"
    fi

    if [ "${FINISHED_OPTIMISING}" == "TRUE" ]; then
        read -p "Do you want to replace the original file? [Y/n] " -n 1 -r
        echo

        if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
            rm "${FILE_PATH}"
            mv "${OUTPUT_TEMP_FILE}" "${OUTPUT_FILE}"
        fi
    fi
else
    echo "No optimisation needed!"
fi
