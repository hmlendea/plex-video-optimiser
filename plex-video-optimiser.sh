#!/bin/bash

FILE_PATH="$*"
FILE_PATH_WITHOUT_EXTENSION="${FILE_PATH%.*}"
FILE_BASENAME=$(basename -- "$FILE_PATH")
FILE_EXTENSION="${FILE_BASENAME##*.}"
FILE_NAME="${FILE_BASENAME%.*}"
FILE_DIRECTORY=$(dirname "${FILE_PATH}")

SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

IS_TVSHOW_EPISODE="FALSE"
IS_OPTIMISABLE="FALSE"
FFMPEG_ARGUMENTS=""

OUTPUT_FILE_NAME=${FILE_NAME}
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\.mkv$//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(BAE\|BluHD\|BLUTONiUM\|cakes\|CasStudio\|CHD\|decibeL\|EbP\|ETRG\|FREEHK\|GOLDIES\|TrollUHD\|FraMeSToR\|playBD\|LazyStudio\|MovietaM\|NTb\|[Pp][Ss][Yy][Cc][Hh][Dd]\|HDMaN\|BLUEBIRD\|TrollUHD\|MTeam\|MZABI\|ZON3\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(720p\|1080p\|2160p\|4K\|UHD\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(10bit\|BT2020\|Chroma[\ \.]422[\ \.]Edition\|VISIONPLUS\|HDR1000\|HDR\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(AVC\|[Dd][Xx][Vv][Aa]\|HEVC\|x26[45]\|[Hh]\.*26[45]\|-AJP69\|[Bb]lu-*[Rr]ay\|VC-1\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(Amazon\|AMZN\|Disney\|Vimeo\|[Ww][Ee][Bb]\(-DL\)*\|WEBRip\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(REPACK\|Remux\|REMUX\|RoSubbed\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(AC3\|AAC2\.0\|Atmos\|DTS-MA\|DTS\|HD[-\ \.]MA\|LPCM\|DD+\|DD[P]*[567]\.1\|DTSX\|FLAC[-\ \.][567]\.1\|TrueHD\|[567]\.1\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/[-\ \.]*\(Director.s[. ]Cut\|Extended[. ]Edition\)//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | iconv -f utf-8 -t ascii//translit)
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's@\(?\|!\|\\\|/\)@@g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\./ /g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/(*\(19\|20\)[0-9][0-9])*$//g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/-/ /g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\ +/ /g')
OUTPUT_FILE_NAME=$(echo ${OUTPUT_FILE_NAME} | sed 's/\ +$//g')
OUTPUT_FILE_PATH_WITHOUT_EXTENSION="${FILE_DIRECTORY}/${OUTPUT_FILE_NAME}"

if [ $(echo "${FILE_NAME}" | grep -E "[Ss][0-9]+[Ee][0-9]+" -c) -gt 0 ]; then
    IS_TVSHOW_EPISODE="TRUE"
fi

function getVideoTrackFormat {
    echo $( mkvmerge -i "${FILE_PATH}" | \
            grep -E "Track ID [0-9]+: video" | \
            head -n 1 | tail -n 1 | \
            awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
}

function getAudioTrackFormat {
    TRACK_NR=${1}
    AUDIO_TRACKS_COUNT=$(   mkvmerge -i "${FILE_PATH}" | \
                            grep -E "Track ID [0-9]+: audio" | \
                            wc -l)

    if [ ${AUDIO_TRACKS_COUNT} -ge ${TRACK_NR} ]; then
        echo $( mkvmerge -i "${FILE_PATH}" | \
                grep -E "Track ID [0-9]+: audio" | \
                head -n ${TRACK_NR} | tail -n 1 | \
                awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
    fi
}

function getAudioTrackName {
    AUDIO_TRACK_ID=${1}
    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat ${AUDIO_TRACK_ID})

    if [ -n "${AUDIO_TRACK_FORMAT}" ]; then
        echo $(getTrackName ${AUDIO_TRACK_ID})
    fi
}

function getTrackName {
    TRACK_ID=${1}
    TRACK_ID_MKVINFO=$((TRACK_ID+1))

    MKVINFO_TRACK_BEGIN_LINE=$(mkvinfo "${FILE_PATH}" | grep -n "+ Track number: ${TRACK_ID_MKVINFO}" | awk -F: '{print $1}')
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

    MKVINFO_TRACK_BEGIN_LINE=$(mkvinfo "${FILE_PATH}" | grep -n "+ Track number: ${TRACK_ID_MKVINFO}" | awk -F: '{print $1}')
    MKVINFO_TRACK_END_LINE=$(mkvinfo "${FILE_PATH}" | tail --lines=+${MKVINFO_TRACK_BEGIN_LINE} | grep -n "\(| +\||+\)" | head -n 1 | awk -F: '{print $1}')
    MKVINFO_TRACK_END_LINE=$((MKVINFO_TRACK_BEGIN_LINE+MKVINFO_TRACK_END_LINE-2))
    MKVINFO_TRACK_LINES_COUNT=$((MKVINFO_TRACK_END_LINE-MKVINFO_TRACK_BEGIN_LINE+1))

    TRACK_LANGUAGE=$(mkvinfo "${FILE_PATH}" | tail --lines=+${MKVINFO_TRACK_BEGIN_LINE} | head -n ${MKVINFO_TRACK_LINES_COUNT} | grep "+ Language:" | awk -F: '{print toupper($2)}' | sed 's/ //g')

    echo ${TRACK_LANGUAGE}
}

function printAudioTrackInfo {
    AUDIO_TRACK_ID=${1}
    AUDIO_FORMAT=$(getAudioTrackFormat ${AUDIO_TRACK_ID})

    if [ -n "${AUDIO_FORMAT}" ]; then
        AUDIO_NAME=$(getAudioTrackName ${AUDIO_TRACK_ID})
        printf "Audio ${AUDIO_TRACK_ID}: Format=${AUDIO_FORMAT}" >&2

        [ -n "${AUDIO_NAME}" ] && printf ", Name=\"${AUDIO_NAME}\"" >&2
        printf "\n" >&2
    fi
}

echo "Gathering file info for ${FILE_PATH} ..."
CONTAINER_FORMAT=$(mkvmerge -i "${FILE_PATH}" | head -n 1 | awk -F: '{print $3}' | sed 's/ //g')
VIDEO_FORMAT=$(getVideoTrackFormat)
AUDIO_NAME_1=$(getAudioTrackName 1)
AUDIO_NAME_2=$(getAudioTrackName 2)
AUDIO_NAME_3=$(getAudioTrackName 3)
AUDIO_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": audio" -c)
SUBTITLE_TRACKS_COUNT=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" -c)

echo "Input file name: ${FILE_NAME}"
echo "Video format: ${VIDEO_FORMAT}"
printAudioTrackInfo 1
printAudioTrackInfo 2
printAudioTrackInfo 3
echo "Output file name: ${OUTPUT_FILE_NAME}"

function isAudioFormatAcceptable {
    AUDIO_FORMAT_TO_CHECK="$*"

    if [[ "${AUDIO_FORMAT_TO_CHECK}" == "AAC" ]] ||
       [[ "${AUDIO_FORMAT_TO_CHECK}" == "MP3" ]] ||
       [[ "${AUDIO_FORMAT_TO_CHECK}" == "AC-3" ]] ||
       [[ "${AUDIO_FORMAT_TO_CHECK}" == "Opus" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function isAudioTrackFormatOk {
    AUDIO_TRACK_ID=${1}
    AUDIO_TRACK_FORMAT=$(getAudioTrackFormat ${AUDIO_TRACK_ID})

    if [[ "${AUDIO_TRACK_FORMAT}" == "AAC" ]] ||
       [[ "${AUDIO_TRACK_FORMAT}" == "MP3" ]] ||
       [[ "${AUDIO_TRACK_FORMAT}" == "AC-3" ]] ||
       [[ "${AUDIO_TRACK_FORMAT}" == "Opus" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function isAudioTrackCommentary {
    AUDIO_TRACK_ID=${1}
    AUDIO_TRACK_NAME=$(getAudioTrackName ${AUDIO_TRACK_ID})

    if [[ "${AUDIO_TRACK_NAME}" == "Commentary" ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function getVideoFfmpegArgs {
    if [[ "${VIDEO_FORMAT}" == "VP9" ]]; then
        echo "-map 0:v:0 -c:v:0 mpeg4"
    else
        echo ""
    fi
}

function getAudioFfmpegArgs {
    AUDIO_FORMAT_1=$(getAudioTrackFormat 1)
    AUDIO_FORMAT_2=$(getAudioTrackFormat 2)
    AUDIO_FORMAT_3=$(getAudioTrackFormat 3)

    if [ ${AUDIO_TRACKS_COUNT} == 1 ]; then
        if ! isAudioTrackFormatOk 1; then
            echo "-map 0:a:0 -c:a:0 aac -map 0:a:0 -c:a:1 copy"
        fi
    elif [ ${AUDIO_TRACKS_COUNT} == 2 ]; then
        if isAudioTrackFormatOk 1 && isAudioTrackFormatOk 2; then
            if isAudioTrackCommentary 1 ; then
                echo "-map 0:a:1 -c:a:0 copy -map -0:a:1"
            elif isAudioTrackCommentary 2; then
                echo "-map 0:a:0 -c:a:0 copy -map -0:a:1"
            fi
        elif isAudioTrackFormatOk 1 && ! isAudioTrackFormatOk 2; then
            if isAudioTrackCommentary 1 ; then
                echo "-map 0:a:1 -c:a:0 aac -map 0:a:1 -c:a:1 copy"
            elif isAudioTrackCommentary 2; then
                echo "-map 0:a:0 -c:a:0 copy -map -0:a:1"
            fi
        elif ! isAudioTrackFormatOk 1 && isAudioTrackFormatOk 2; then
            if isAudioTrackCommentary 1 ; then
                echo "-map 0:a:1 -c:a:0 copy -map -0:a:1"
            elif isAudioTrackCommentary 2; then
                echo "-map 0:a:0 -c:a:0 aac -map 0:a:0 -c:a:1 copy -map -0:a:1"
            else
                echo "-map 0:a:1 -c:a:0 copy -map 0:a:0 -c:a:1 copy"
            fi
        elif ! isAudioTrackFormatOk 1 && ! isAudioTrackFormatOk 2; then
            if isAudioTrackCommentary 1 ; then
                echo "-map 0:a:1 -c:a:0 aac -map 0:a:1 -c:a:1 copy -map -0:a:1"
            elif isAudioTrackCommentary 2; then
                echo "-map 0:a:0 -c:a:0 aac -map 0:a:0 -c:a:1 copy -map -0:a:1"
            else
                echo "-map 0:a:0 -c:a:0 aac -map 0:a:0 -c:a:1 copy -map -0:a:1"
            fi
        fi
    else
        if isAudioFormatAcceptable ${AUDIO_FORMAT_1} ; then
            echo ""
        elif isAudioFormatAcceptable ${AUDIO_FORMAT_2} && [ ! -z "${AUDIO_FORMAT_3}" ]; then
            echo "-map 0:a:1 -c:a:0 copy -map 0:a:2 -c:a:1 copy -map 0:a:0 -c:a:2 copy"
        elif isAudioFormatAcceptable ${AUDIO_FORMAT_3} ; then
            echo "-map 0:a:2 -c:a:0 copy -map 0:a:1 -c:a:1 copy -map 0:a:0 -c:a:2 copy"
        else
            echo "-map 0:a:0 -c:a:0 aac -map 0:a:0 -c:a:1 copy"
        fi
    fi
}

VIDEO_FFMPEG_ARGUMENTS=$(getVideoFfmpegArgs)
AUDIO_FFMPEG_ARGUMENTS=$(getAudioFfmpegArgs)

if [ -n "${VIDEO_FFMPEG_ARGUMENTS}" ]; then
    echo "Video track needs conversion!"
    IS_OPTIMISABLE="TRUE"
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${VIDEO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="-map 0:v:0 -c:v:0 copy"
fi

if [ -n "${AUDIO_FFMPEG_ARGUMENTS}" ]; then
    echo "Audio track needs conversion!"
    IS_OPTIMISABLE="TRUE"
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} ${AUDIO_FFMPEG_ARGUMENTS}"
else
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map 0:a -c:a copy"
fi

if [ "${FILE_EXTENSION}" != "mkv" ] || [ "${CONTAINER_FORMAT}" != "Matroska" ]; then echo "File format needs conversion!"
    IS_OPTIMISABLE="TRUE" FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map 0:a -c:a copy"
fi

if [ ${SUBTITLE_TRACKS_COUNT} -gt 0 ]; then
    echo "Subtitles need removal!"
    IS_OPTIMISABLE="TRUE"
    FFMPEG_ARGUMENTS="${FFMPEG_ARGUMENTS} -map -0:s"

    SUBTITLE_TRACKS=$(mkvmerge -i "${FILE_PATH}" | grep ": subtitles (" | grep "\(SRT\|SubStationAlpha\)" | awk '{print $3}' | awk -F: '{print $1}')

    if [ -z "${SUBTITLE_TRACKS}" ]; then
        echo "No text subtitles found!"
    else
        echo "Subtitle tracks found:"
        UNKNOWN_LANGUAGE_TRACKS_COUNT=0

        for TRACK_ID in ${SUBTITLE_TRACKS}; do
            TRACK_LANGUAGE="$(getTrackLanguage ${TRACK_ID})"
            if [ -z "${TRACK_LANGUAGE}" ]; then
                TRACK_LANGUAGE="(unknown)"
                UNKNOWN_LANGUAGE_TRACKS_COUNT=$((UNKNOWN_LANGUAGE_TRACKS_COUNT+1))
            fi

            echo "#${TRACK_ID}: ${TRACK_LANGUAGE}"
        done

        read -p "Do you want to save the subtitles before removing them? [Y/n] " -n 1 -r
        echo

        if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
            SUBTITLES_FFMPEG_ARGUMENTS=""
            TRACK_LANGUAGES=""

            for TRACK_ID in ${SUBTITLE_TRACKS}; do
                TRACK_LANGUAGE="$(getTrackLanguage ${TRACK_ID})"

                DUPLICATIONS=$(echo "${TRACK_LANGUAGES}" | grep "${TRACK_LANGUAGE}," -c)
                if [ ! -z "${TRACK_LANGUAGE}" ]; then
                    TRACK_LANGUAGES="${TRACK_LANGUAGES}${TRACK_LANGUAGE},"
                    if [ ${DUPLICATIONS} -ge 1 ]; then
                        TRACK_LANGUAGE=${TRACK_LANGUAGE}$((DUPLICATIONS+1))
                    fi
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

if [ "${IS_OPTIMISABLE}" == "TRUE" ]; then
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
        read -p "Do you want to replace the original file? [y/N] " -n 1 -r
        echo

        if [[ ${REPLY} =~ ^[Yy]$ ]]; then
            rm "${FILE_PATH}"
            mv "${OUTPUT_TEMP_FILE}" "${OUTPUT_FILE}"
        fi
    fi
else
    echo "No optimisation needed!"
fi
