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

FILE_PATH_WITHOUT_EXTENSION="${FILE_PATH%.*}"
FILE_BASENAME=$(basename -- "$FILE_PATH")
FILE_EXTENSION="${FILE_BASENAME##*.}"
FILE_NAME="${FILE_BASENAME%.*}"
FILE_DIRECTORY=$(dirname "${FILE_PATH}")

SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

IS_TVSHOW_EPISODE=false
IS_OPTIMISABLE=false
FFMPEG_ARGUMENTS=""

OUTPUT_FILE_NAME=${FILE_NAME}
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\.mkv$//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(AMIABLE\|BAE\|BluHD\|BLUTONiUM\|BTN\|cakes\|CasStudio\|CHD\|CRiSC\|CtrlHD\|decibeL\|EbP\|ETRG\|FLUX\|FraMeSToR\|FREEHK\|ggez\|GOLDIES\|iNTERNAL\|TENEIGHTY\|TrollUHD\|playBD\|LazyStudio\|MovietaM\|NTb\|[Pp][Ss][Yy][Cc][Hh][Dd]\|HDMaN\|BLUEBIRD\|TrollUHD\|MTeam\|MZABI\|ZON3\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(720p\|1080p\|2160[p]*\|4K\|UHD\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(10bit\|BT2020\|Chroma[\ \.]422[\ \.]Edition\|VISIONPLUS\|HDR1000\|HDR\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(AVC\|DV\|[Dd][Xx][Vv][Aa]\|HEVC\|[xX]26[45]\|[Hh]\.*26[45]\|-AJP69\|[Bb]lu-*[Rr]ay\|VC-1\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(Amazon\|AMZN\|ATVP\|Disney\|Vimeo\|[Ww][Ee][Bb]\(-DL\)*\|WEBRip\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(Extended Edition\|Extended\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(REPACK\|Remux\|REMUX\|RoSubbed\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(AC3\|AAC2\.0\|Atmos\|DTS-MA\|DTS-X\|DTS\|HD[-\ \.]MA\|LPCM\|DD+\|DD[P]*[\.]*[567]\.1\|DTSX\|FLAC[-\ \.][567]\.1\|TrueHD\|[567]\.1\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(Director.s[. ]Cut\|Extended[. ]Edition\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | iconv -f utf-8 -t ascii//translit)
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's@\(?\|!\|\\\|/\)@@g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\./ /g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/(*\(19\|20\)[0-9][0-9])*$//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/-/ /g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\ +/ /g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\ +$//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[Ss]\([0-9][0-9]*\)[Ee]\([0-9][0-9]*\)$/S\1E\2/g')
OUTPUT_FILE_PATH_WITHOUT_EXTENSION="${FILE_DIRECTORY}/${OUTPUT_FILE_NAME}"

if [ $(echo "${FILE_NAME}" | grep -E "[Ss][0-9]+[Ee][0-9]+" -c) -gt 0 ]; then
    IS_TVSHOW_EPISODE=true
fi

function getVideoTrackFormat {
    echo $( mkvmerge -i "${FILE_PATH}" | \
            grep -E "Track ID [0-9]+: video" | \
            head -n 1 | tail -n 1 | \
            awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
}

function getAudioTrackFormat {
    AUDIO_TRACK_INDEX="${1}"
    TRACK_ID=$((AUDIO_TRACK_INDEX+1))
    AUDIO_TRACKS_COUNT=$(   mkvmerge -i "${FILE_PATH}" | \
                            grep -E "Track ID [0-9]+: audio" | \
                            wc -l)

    if [ ${AUDIO_TRACKS_COUNT} -ge ${TRACK_ID} ]; then
        echo $( mkvmerge -i "${FILE_PATH}" | \
                grep -E "Track ID [0-9]+: audio" | \
                head -n ${TRACK_ID} | tail -n 1 | \
                awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
    fi
}

function getAudioTrackName {
    AUDIO_TRACK_INDEX=${1}
    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat ${AUDIO_TRACK_INDEX})
    TRACK_ID=$((AUDIO_TRACK_INDEX+1))

    if [ -n "${AUDIO_TRACK_FORMAT}" ]; then
        echo $(getTrackName ${TRACK_ID})
    fi
}

function getTrackName {
    TRACK_ID="${1}"
    TRACK_ID_MKVINFO=$((TRACK_ID+1))

    MKVINFO_TRACK_BEGIN_LINE=$(mkvinfo "${FILE_PATH}" | grep -n "+ Track number: ${TRACK_ID_MKVINFO}" | awk -F: '{print $1}' | head -n 1)
    MKVINFO_TRACK_END_LINE=$(mkvinfo "${FILE_PATH}" | tail --lines=+${MKVINFO_TRACK_BEGIN_LINE} | grep -n "\(| +\||+\)" | head -n 1 | awk -F: '{print $1}')
    MKVINFO_TRACK_END_LINE=$((MKVINFO_TRACK_BEGIN_LINE+MKVINFO_TRACK_END_LINE-2))
    MKVINFO_TRACK_LINES_COUNT=$((MKVINFO_TRACK_END_LINE-MKVINFO_TRACK_BEGIN_LINE+1))

    TRACK_LANGUAGE=$(   mkvinfo "${FILE_PATH}" | \
                        tail --lines=+${MKVINFO_TRACK_BEGIN_LINE} | \
                        head -n ${MKVINFO_TRACK_LINES_COUNT} | \
                        grep "+ Name:" | \
                        awk -F: '{print $2}' | \
                        sed 's/^ *//g')

    echo ${TRACK_LANGUAGE}
}

function getTrackLanguage {
    TRACK_ID=${1}
    TRACK_ID_MKVINFO=$((TRACK_ID+1))

    MKVINFO_TRACK_BEGIN_LINE=$(mkvinfo "${FILE_PATH}" | grep -n "+ Track number: ${TRACK_ID_MKVINFO}" | awk -F: '{print $1}' | head -n 1)
    MKVINFO_TRACK_END_LINE=$(mkvinfo "${FILE_PATH}" | tail --lines=+${MKVINFO_TRACK_BEGIN_LINE} | grep -n "\(| +\||+\)" | head -n 1 | awk -F: '{print $1}')
    MKVINFO_TRACK_END_LINE=$((MKVINFO_TRACK_BEGIN_LINE+MKVINFO_TRACK_END_LINE-2))
    MKVINFO_TRACK_LINES_COUNT=$((MKVINFO_TRACK_END_LINE-MKVINFO_TRACK_BEGIN_LINE+1))

    TRACK_LANGUAGE=$(mkvinfo "${FILE_PATH}" | tail --lines=+${MKVINFO_TRACK_BEGIN_LINE} | head -n ${MKVINFO_TRACK_LINES_COUNT} | grep "+ Language:" | awk -F: '{print toupper($2)}' | sed 's/ //g')

    echo ${TRACK_LANGUAGE}
}

function printAudioTrackInfo {
    AUDIO_TRACK_INDEX=${1}
    AUDIO_FORMAT=$(getAudioTrackFormat ${AUDIO_TRACK_INDEX})

    if [ -n "${AUDIO_FORMAT}" ]; then
        AUDIO_NAME=$(getAudioTrackName ${AUDIO_TRACK_INDEX})
        printf "Audio ${AUDIO_TRACK_INDEX}: Format=${AUDIO_FORMAT}" >&2

        [ -n "${AUDIO_NAME}" ] && printf ", Name=\"${AUDIO_NAME}\"" >&2
        printf "\n" >&2
    fi
}

echo "Gathering file info for ${FILE_PATH} ..."
CONTAINER_FORMAT=$(mkvmerge -i "${FILE_PATH}" | head -n 1 | awk -F: '{print $3}' | sed 's/ //g')
VIDEO_FORMAT=$(getVideoTrackFormat)
AUDIO_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": audio" -c)

SUBTITLE_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" -c)

echo "Session ID: ${SESSION_ID}"
echo "Input file name: ${FILE_NAME}"
echo "Video format: ${VIDEO_FORMAT}"

for ((AUDIO_TRACK_INDEX = 0; AUDIO_TRACK_INDEX < ${AUDIO_TRACKS_COUNT}; AUDIO_TRACK_INDEX++)); do
    printAudioTrackInfo ${AUDIO_TRACK_INDEX}
done

echo "Output file name: ${OUTPUT_FILE_NAME}"

function isAudioTrackFormatOk {
    AUDIO_TRACK_INDEX=${1}
    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat ${AUDIO_TRACK_INDEX})

    # AC-3 could cause some problems on some rare devices. It's better to just use AAC instead since it's not going to make a difference anyay
    if [[ "${AUDIO_TRACK_FORMAT}" == "AAC" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "MP3" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function isAudioTrackCommentary {
    AUDIO_TRACK_INDEX=${1}
    AUDIO_TRACK_NAME=$(getAudioTrackName ${AUDIO_TRACK_INDEX})

    if [ $(echo "${AUDIO_TRACK_NAME}" | grep -c "[Cc]ommentary") -ge 1 ]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function isAudioTrackDiscardable {
    AUDIO_TRACK_INDEX="${1}"

    $(isAudioTrackCommentary "${AUDIO_TRACK_INDEX}") && return 0 # True

    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat "${AUDIO_TRACK_INDEX}")

    if [[ "${AUDIO_TRACK_FORMAT}" == "AC-3" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "AC-3 Dolby Surround EX" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "E-AC-3" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "MP3" ]] \
    || [[ "${AUDIO_TRACK_FORMAT}" == "Opus" ]]; then
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

    for ((AUDIO_TRACK_INDEX=0; AUDIO_TRACK_INDEX<${AUDIO_TRACKS_COUNT}; AUDIO_TRACK_INDEX++)); do
        if isAudioTrackFormatOk ${AUDIO_TRACK_INDEX}; then
            FFMPEG_AUDIO_TRACK_ARGS="-map 0:a:${AUDIO_TRACK_INDEX} -c:a:0 copy"
            OUTPUT_AUDIO_TRACKS_COUNT=1
            COPIED_AUDIO_TRACK_INDEX=${AUDIO_TRACK_INDEX}
            [[ "${AUDIO_TRACK_INDEX}" != "0" ]] && MODIFICATIONS_APPLIED=true
            break
        fi
    done

    if [ -z "${FFMPEG_AUDIO_TRACK_ARGS}" ]; then
        for ((AUDIO_TRACK_INDEX=0; AUDIO_TRACK_INDEX<${AUDIO_TRACKS_COUNT}; AUDIO_TRACK_INDEX++)); do
            if ! isAudioTrackCommentary ${AUDIO_TRACK_INDEX}; then
                FFMPEG_AUDIO_TRACK_ARGS="-map 0:a:${AUDIO_TRACK_INDEX} -c:a:0 aac"
                OUTPUT_AUDIO_TRACKS_COUNT=1
                MODIFICATIONS_APPLIED=true
                break
            fi
        done
    fi

    if ${IS_TVSHOW_EPISODE} && ${KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS}; then
        for ((AUDIO_TRACK_INDEX=0; AUDIO_TRACK_INDEX<${AUDIO_TRACKS_COUNT}; AUDIO_TRACK_INDEX++)); do
            #if isAudioTrackDiscardable ${AUDIO_TRACK_INDEX} ; then
            #    FFMPEG_AUDIO_TRACK_ARGS="${FFMPEG_AUDIO_TRACK_ARGS} -map -0:a:${AUDIO_TRACK_INDEX}"
            #else
            [[ "${AUDIO_TRACK_INDEX}" == "${COPIED_AUDIO_TRACK_INDEX}" ]] && continue

            if isAudioTrackDiscardable ${AUDIO_TRACK_INDEX}; then
                MODIFICATIONS_APPLIED=true
            else
                FFMPEG_AUDIO_TRACK_ARGS="${FFMPEG_AUDIO_TRACK_ARGS} -map 0:a:${AUDIO_TRACK_INDEX} -c:a:${OUTPUT_AUDIO_TRACKS_COUNT} copy"
                OUTPUT_AUDIO_TRACKS_COUNT=$((OUTPUT_AUDIO_TRACKS_COUNT+1))
            fi
        done
    fi

    [ ${OUTPUT_AUDIO_TRACKS_COUNT} -ne ${AUDIO_TRACKS_COUNT} ] && MODIFICATIONS_APPLIED=true

#    [[ "${FFMPEG_AUDIO_TRACK_ARGS}" != "-map 0:a:0 -c:a:0 copy" ]] && echo "${FFMPEG_AUDIO_TRACK_ARGS}"
    ${MODIFICATIONS_APPLIED} && echo "${FFMPEG_AUDIO_TRACK_ARGS}"
}

function isSubtitleTrackDiscardable {
    local TRACK_ID="${@}"

    if (! ${KEEP_FORCED_SUBTITLES}); then
        [[ "${TRACK_NAME}" == *"Forced"* ]] && return 0 # True
    fi

    if (! ${KEEP_SDH_SUBTITLES}); then
        [[ "${TRACK_NAME}" == *"SDH"* ]] && return 0 # True
    fi

    return 1 # False
}

function getSubtitleLanguage {
    local TRACK_ID="${@}"
    local TRACK_LANGUAGE="$(getTrackLanguage ${TRACK_ID})"
    local TRACK_NAME=$(getTrackName "${TRACK_ID}")

#    if [ -z "${TRACK_LANGUAGE}" ]; then
        [ $(echo "${TRACK_NAME}" | grep -c "中文\|[Cc]hinese") -ge 1 ] && TRACK_LANGUAGE="CHI"
        [ $(echo "${TRACK_NAME}" | grep -c "廣東話\|[Cc]antonese\|[Yy]ue") -ge 1 ] && TRACK_LANGUAGE="YUE"

        [ $(echo "${TRACK_NAME}" | grep -c "[Aa]rabic") -ge 1 ] && TRACK_LANGUAGE="ARA"
        [ $(echo "${TRACK_NAME}" | grep -c "[Bb]ulgarian") -ge 1 ] && TRACK_LANGUAGE="BUL"
        [ $(echo "${TRACK_NAME}" | grep -c "[Cc]zech") -ge 1 ] && TRACK_LANGUAGE="CZE"
        [ $(echo "${TRACK_NAME}" | grep -c "[Dd]anish") -ge 1 ] && TRACK_LANGUAGE="DAN"
        [ $(echo "${TRACK_NAME}" | grep -c "[Dd]eutsch\|[Gg]erman") -ge 1 ] && TRACK_LANGUAGE="GER"
        [ $(echo "${TRACK_NAME}" | grep -c "[Dd]utch") -ge 1 ] && TRACK_LANGUAGE="DUT"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ee]nglish") -ge 1 ] && TRACK_LANGUAGE="ENG"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ee]spañol\|[Ss]panish") -ge 1 ] && TRACK_LANGUAGE="SPA"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ee]stonian") -ge 1 ] && TRACK_LANGUAGE="EST"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ff]innish") -ge 1 ] && TRACK_LANGUAGE="FIN"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ff]rançais\|[Ff]rench") -ge 1 ] && TRACK_LANGUAGE="FRE"
        [ $(echo "${TRACK_NAME}" | grep -c "[Gg]reek") -ge 1 ] && TRACK_LANGUAGE="GRE"
        [ $(echo "${TRACK_NAME}" | grep -c "[Hh]ebrew") -ge 1 ] && TRACK_LANGUAGE="HEB"
        [ $(echo "${TRACK_NAME}" | grep -c "[Hh]indi") -ge 1 ] && TRACK_LANGUAGE="HIN"
        [ $(echo "${TRACK_NAME}" | grep -c "[Hh]ungarian") -ge 1 ] && TRACK_LANGUAGE="HUN"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ii]ndonesian") -ge 1 ] && TRACK_LANGUAGE="IND"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ii]taliano\|[Ii]talian") -ge 1 ] && TRACK_LANGUAGE="ITA"
        [ $(echo "${TRACK_NAME}" | grep -c "[Jj]apanese") -ge 1 ] && TRACK_LANGUAGE="JAP"
        [ $(echo "${TRACK_NAME}" | grep -c "[Kk]orean") -ge 1 ] && TRACK_LANGUAGE="KOR"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ll]atvian") -ge 1 ] && TRACK_LANGUAGE="LAV"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ll]ithuanian") -ge 1 ] && TRACK_LANGUAGE="LIT"
        [ $(echo "${TRACK_NAME}" | grep -c "[Mm]alay") -ge 1 ] && TRACK_LANGUAGE="MAY"
        [ $(echo "${TRACK_NAME}" | grep -c "[Nn]orwegian") -ge 1 ] && TRACK_LANGUAGE="NOR"
        [ $(echo "${TRACK_NAME}" | grep -c "[Pp]olish") -ge 1 ] && TRACK_LANGUAGE="POL"
        [ $(echo "${TRACK_NAME}" | grep -c "[Pp]ortuguês\|[Pp]ortuguese") -ge 1 ] && TRACK_LANGUAGE="POR"
        [ $(echo "${TRACK_NAME}" | grep -c "[Rr]omână\|[Rr]omanian") -ge 1 ] && TRACK_LANGUAGE="RUM"
        [ $(echo "${TRACK_NAME}" | grep -c "[Rr]ussian") -ge 1 ] && TRACK_LANGUAGE="RUS"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ss]lovak") -ge 1 ] && TRACK_LANGUAGE="SLO"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ss]lovenian") -ge 1 ] && TRACK_LANGUAGE="SLV"
        [ $(echo "${TRACK_NAME}" | grep -c "[Ss]wedish") -ge 1 ] && TRACK_LANGUAGE="SWE"
        [ $(echo "${TRACK_NAME}" | grep -c "[Tt]amil") -ge 1 ] && TRACK_LANGUAGE="TAM"
        [ $(echo "${TRACK_NAME}" | grep -c "[Tt]elugu") -ge 1 ] && TRACK_LANGUAGE="TEL"
        [ $(echo "${TRACK_NAME}" | grep -c "[Tt]hai") -ge 1 ] && TRACK_LANGUAGE="THA"
        [ $(echo "${TRACK_NAME}" | grep -c "[Tt]urkish") -ge 1 ] && TRACK_LANGUAGE="TUR"
        [ $(echo "${TRACK_NAME}" | grep -c "[Uu]krainian") -ge 1 ] && TRACK_LANGUAGE="UKR"
        [ $(echo "${TRACK_NAME}" | grep -c "[Vv]ietmanese") -ge 1 ] && TRACK_LANGUAGE="VIE"
#    fi

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

if [ ${SUBTITLE_TRACKS_COUNT} -gt 0 ]; then
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
            TRACK_NAME=$(getTrackName "${TRACK_ID}")

            $(isSubtitleTrackDiscardable "${TRACK_ID}") && continue

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
                TRACK_LANGUAGE="$(getSubtitleLanguage ${TRACK_ID})"
                TRACK_NAME=$(getTrackName "${TRACK_ID}")

                $(isSubtitleTrackDiscardable "${TRACK_ID}") && continue

                DUPLICATIONS=$(echo "${TRACK_LANGUAGES}" | sed 's/,/\n/g' | grep -c "${TRACK_LANGUAGE}")

                if [ -n "${TRACK_LANGUAGE}" ]; then
                    if [ "${DUPLICATIONS}" -ge 1 ]; then
                        if [ -n "${TRACK_NAME}" ]; then
                            TRACK_LANGUAGE_NAME=$(echo "${TRACK_NAME}" | sed \
                                -e 's/\s//g' -e 's/[()]//g' \
                                -e 's/\([Cc]hinese\|[Ff]rench\|[Pp]ortuguese\|[Ss]panish\)//g' \
                                -e 's/[Bb]razilian/Brazil/g' \
                                -e 's/[Cc]anadian/Canada/g' \
                                -e 's/[Ee]uropean/Europe/g')

                            TRACK_LANGUAGE="${TRACK_LANGUAGE}-${TRACK_LANGUAGE_NAME}"
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

    if [ ! -z "${SUBTITLES_FFMPEG_ARGUMENTS}" ]; then
        echo "Extracting the subtitles..."
        ffmpeg -i "${FILE_PATH}" ${SUBTITLES_FFMPEG_ARGUMENTS}

        # Chinese - Simplified
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "CHI" "CHI2" "CHI"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "CHI" "CHI3" "CHI"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "CHI" "CHI-繁體" "CHI"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "CHI-简体" "CHI-繁體" "CHI"

        # French - France
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "FRE" "FRE-Canada" "FRE"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "FRE-France" "FRE" "FRE"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "FRE-France" "FRE-Canada" "FRE"

        # Portuguese - Portugal
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "POR" "POR-Brasil" "POR"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "POR" "POR-Brazil" "POR"

        # Spanish - Spain
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA" "SPA-LatinAmerica" "SPA"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA" "SPA-Latinoamérica" "SPA"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA-España" "SPA" "SPA"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA-España" "SPA-Latinoamérica" "SPA"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA-Europe" "SPA-LatinAmerica" "SPA"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA-Spain" "SPA" "SPA"
        replaceDuplicatedSubtitles "extractedSubtitleFile.${SESSION_ID}" "SPA-Spain" "SPA-LatinAmerica" "SPA"

        if [ -f "/usr/bin/fix-subtitle" ]; then
            for EXTRACTED_SUBTITLE_FILE in "extractedSubtitleFile.${SESSION_ID}."*; do
                fix-subtitle --noconfirm "${EXTRACTED_SUBTITLE_FILE}"
            done
        fi

        perl-rename 's/extractedSubtitleFile\.'"${SESSION_ID}"'/'"${OUTPUT_FILE_NAME}"'/g' "${FILE_DIRECTORY}"/*
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
