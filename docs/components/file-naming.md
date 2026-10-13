# File Naming

## Overview

Output file name sanitisation and TV show episode detection. The script transforms the input filename into a clean, Plex-friendly name by stripping release group tags, quality indicators, codec info, source tags, audio tags, and edition markers.

## Sanitisation Pipeline

The `OUTPUT_FILE_NAME` is derived from `FILE_NAME` through a series of `sed` transformations:

### 1. Remove Extension
```bash
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | sed 's/\.mkv$//g')
```

### 2. Remove Release Group Tags
```bash
sed 's/[-\ \.]*\(AMIABLE\|BAE\|BLUEBIRD\|BluHD\|BLUTONiUM\|BTN\|cakes\|CasStudio\|CHD\|CRiSC\|CtrlHD\|decibeL\|EbP\|ETRG\|FLUX\|FraMeSToR\|FREEHK\|ggez\|GOLDIES\|HDMaN\|iNTERNAL\|L0L\|LazyStudio\|lightspeed\|MovietaM\|MTeam\|MZABI\|NiXON\|NTb\|pawel2006\|PETFRiFiED\|playBD\|[Pp][Ss][Yy][Cc][Hh][Dd]\|t3nzin\|TENEIGHTY\|TOMMY\|TrollUHD\|ZON3\)//g'
```
Removes ~50 known release group names (case-insensitive for some).

### 3. Remove Video Standard Tags
```bash
sed 's/[-\ \.]*\([Dd][Vv][Dd]\|[Pp][Aa][Ll]\|[Ww][Ss]\)//g'
```
Removes: DVD, PAL, WS (widescreen)

### 4. Remove Resolution/Quality Tags
```bash
sed 's/[-\ \.]*\(720p\|1080p\|2160[p]*\|4K\|UHD\)//g'
```
Removes: 720p, 1080p, 2160p, 4K, UHD

### 5. Remove HDR/Color/Encoding Tags
```bash
sed 's/[-\ \.]*\(10bit\|BT2020\|Chroma[\ \.]422[\ \.]Edition\|VISIONPLUS\|HDR1000\|HDR\)//g'
```
Removes: 10bit, BT2020, Chroma 422 Edition, VISIONPLUS, HDR1000, HDR

### 6. Remove Video Codec Tags
```bash
sed 's/[-\ \.]*\(AVC\|D[o]*V[i]*\|[Dd][Xx][Vv][Aa]\|HEVC\|[xX]26[45]\([Hh][Ii]10\)*\|[Hh]\.*26[45]\|-AJP69\|[Bb]lu-*[Rr]ay\|VC-1\)//g'
```
Removes: AVC, DoVi/DVI, DVxA, HEVC, x264/x265/Hi10P, H.264/H.265, -AJP69, BluRay/Blu-Ray, VC-1

### 7. Remove Source Tags
```bash
sed 's/[-\ \.]*\(Amazon\|AMZN\|ATVP\|Disney\|DSNP\|Vimeo\|[Ww][Ee][Bb]\(-DL\)*\|WEBRip\)//g'
```
Removes: Amazon/AMZN, ATVP, Disney/DSNP, Vimeo, WEB/WEB-DL, WEBRip

### 8. Remove Release Version Tags
```bash
sed 's/[-\ \.]*\(REPACK\|Remux\|REMUX\|RoSubbed\)//g'
```
Removes: REPACK, Remux, REMUX, RoSubbed

### 9. Remove Audio Codec Tags
```bash
sed 's/[-\ \.]*\(AC3\|AAC2\.0\|Atmos\|[Dd][Dd][Pp]*2\.0\|DTS-MA\|DTS-X\|DTS\|HD[-\ \.]MA\|LPCM\|DD+\|DD[P]*[\.]*[567]\.1\|DTSX\|FLAC[-\ \.][567]\.1\|TrueHD\|[567]\.1\)//g'
```
Removes: AC3, AAC2.0, Atmos, DD/DDP2.0, DTS-MA, DTS-X, DTS, HD-MA/HD.MA, LPCM, DD+/DD/DDP5.1/6.1/7.1, DTSX, FLAC 5.1/6.1/7.1, TrueHD, 5.1/6.1/7.1

### 10. Remove Edition Tags
```bash
sed 's/[-\ \.]*\(Director.s[. ]Cut\|Extended\([. ]Edition\)*\)//g'
```
Removes: Director's Cut, Director.Cut, Extended, Extended Edition

### 11. Transliterate to ASCII
```bash
OUTPUT_FILE_NAME=$(echo "${OUTPUT_FILE_NAME}" | iconv -f utf-8 -t ascii//translit)
```
Converts Unicode to closest ASCII representation.

### 12. Remove Special Characters
```bash
sed 's@\(?\|!\|\\\|/\)@@g'
```
Removes: ?, !, \, /

### 13. Normalise Separators
```bash
sed 's/\./ /g'           # dots → spaces
sed 's/\(19\|20\)[0-9][0-9]//g'  # remove years (19xx, 20xx)
sed 's/-/ /g'           # hyphens → spaces
sed 's/(\s*)//g'        # remove parentheses and contents
sed 's/\s\s*/ /g'       # collapse multiple spaces
sed 's/\s*$//g'         # trim trailing spaces
```

### 14. Normalise TV Episode Pattern
```bash
sed 's/[Ss]\([0-9][0-9]*\)[Ee]\([0-9][0-9]*\)/S\1E\2/g'
```
Standardises season/episode to `SxxExx` format (uppercase S, E).

## TV Show Episode Detection

```bash
FILE_NAME_TVSHOW_EPISODE_MATCHES_COUNT=$(echo "${FILE_NAME}" | grep -E "[Ss][0-9]+[Ee][0-9]+" -c)
if [ "${FILE_NAME_TVSHOW_EPISODE_MATCHES_COUNT}" -gt 0 ]; then
    IS_TVSHOW_EPISODE=true
fi
```

**Logic**: If original filename contains `SxxExx` pattern (case-insensitive), sets `IS_TVSHOW_EPISODE=true`.

**Effect on Audio Processing**: When `IS_TVSHOW_EPISODE=true` and `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=false` (default), only the primary audio track is kept. Additional tracks are discarded.

## Output Path Construction

```bash
OUTPUT_FILE_PATH_WITHOUT_EXTENSION="${FILE_DIRECTORY}/${OUTPUT_FILE_NAME}"
```

Final optimised file: `${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.mkv`
Temp file during processing: `${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.OPTIMISED.mkv`

## Example Transformations

| Input | Output |
|-------|--------|
| `Show.S01E02.1080p.WEB-DL.x264-GROUP.mkv` | `Show S01E02.mkv` |
| `Movie.2023.4K.UHD.HEVC.TrueHD.Atmos-GROUP.mkv` | `Movie.mkv` |
| `Series.S02E05.720p.BluRay.DTS-HD.MA.5.1-GROUP.mkv` | `Series S02E05.mkv` |
| `Film.Director's.Cut.1080p.Remux.AVC.DTS-HD.MA.7.1-GROUP.mkv` | `Film.mkv` |

## Invariants

1. **Always produces .mkv output** — extension forced to `.mkv`
2. **Preserves directory** — output in same folder as input
3. **TV episode pattern normalised** — `S01E02` format enforced
4. **Release metadata stripped** — groups, quality, codecs, sources removed
5. **Years removed** — 19xx/20xx patterns stripped (may remove legitimate years in titles)
6. **Unicode transliterated** — non-ASCII converted to ASCII approximations