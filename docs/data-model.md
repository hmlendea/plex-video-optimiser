# Data Model

## Domain Entities

### Video File
| Property | Type | Source |
|----------|------|--------|
| `path` | string | Input argument |
| `basename` | string | `basename` |
| `extension` | string | Basename parsing |
| `name` | string | Basename without extension |
| `directory` | string | `dirname` |
| `container_format` | string | `mkvmerge -i` line 1 |
| `video_format` | string | `mkvmerge -i` video track |
| `is_tvshow_episode` | boolean | SxxExx regex on name |
| `session_id` | string | `/dev/urandom` 32-char |

### Video Track
| Property | Type | Source |
|----------|------|--------|
| `index` | int | Always 0 (first video track) |
| `codec` | string | `mkvmerge -i` (AVC, HEVC, AV1, VP9, etc.) |
| `needs_conversion` | boolean | `codec ∈ {AV1, VP9}` |
| `target_codec` | string | H.264 if conversion needed |

### Audio Track
| Property | Type | Source |
|----------|------|--------|
| `index` | int | 0-based (mkvmerge order) |
| `codec` | string | `mkvmerge -i` (AAC, AC-3, DTS, TrueHD, FLAC, Opus, MP3, PCM, E-AC-3) |
| `name` | string | `mkvinfo` track name |
| `is_commentary` | boolean | Name contains "Commentary" |
| `is_preferred_format` | boolean | `codec ∈ {AAC, MP3}` |
| `is_discardable` | boolean | Commentary or `codec ∈ {AC-3, E-AC-3, MP3, Opus, PCM}` |
| `output_action` | enum | `copy_primary`, `convert_to_aac_primary`, `copy_additional`, `drop` |

### Subtitle Track
| Property | Type | Source |
|----------|------|--------|
| `track_id` | int | mkvmerge track ID (0-based) |
| `codec` | string | `mkvmerge -i` (SRT, SubStationAlpha, PGS, VobSub) |
| `is_text_based` | boolean | `codec ∈ {SRT, SubStationAlpha}` |
| `name` | string | `mkvinfo` track name (normalised) |
| `language_code` | string | 3-letter ISO-639-2 (from name or mkvinfo) |
| `is_forced` | boolean | Name contains "Forced" |
| `is_sdh` | boolean | Name contains "SDH" |
| `is_discardable` | boolean | `(is_forced ∧ ¬KEEP_FORCED) ∨ (is_sdh ∧ ¬KEEP_SDH)` |
| `extracted` | boolean | User confirmed extraction ∧ text-based ∧ ¬discardable |

## Language Codes (Supported)

| Code | Language | Detection |
|------|----------|-----------|
| ARA | Arabic | Name match |
| BUL | Bulgarian | Name match |
| YUE | Cantonese | Name match |
| CHI | Chinese | Name match |
| CZE | Czech | Name match |
| DAN | Danish | Name match |
| DUT | Dutch | Name match |
| ENG | English | Name match |
| EST | Estonian | Name match |
| FIN | Finnish | Name match |
| FRE | French | Name match |
| GER | German | Name match |
| GRE | Greek | Name match |
| HEB | Hebrew | Name match |
| HIN | Hindi | Name match |
| HUN | Hungarian | Name match |
| IND | Indonesian | Name match |
| ITA | Italian | Name match |
| JAP | Japanese | Name match |
| KOR | Korean | Name match |
| LAV | Latvian | Name match |
| LIT | Lithuanian | Name match |
| MAY | Malay | Name match |
| NOR | Norwegian | Name match |
| POL | Polish | Name match |
| POR | Portuguese | Name match |
| RUM | Romanian | Name match |
| RUS | Russian | Name match |
| SLO | Slovak | Name match |
| SLV | Slovenian | Name match |
| SPA | Spanish | Name match |
| SWE | Swedish | Name match |
| TAM | Tamil | Name match |
| TEL | Telugu | Name match |
| THA | Thai | Name match |
| TUR | Turkish | Name match |
| UKR | Ukrainian | Name match |
| VIE | Vietnamese | Name match |

## Relationships

```
VideoFile
    ├── 1 VideoTrack
    ├── N AudioTracks
    └── N SubtitleTracks
```

## State Transitions

### Video Track
```
Detected → [AV1/VP9] → Transcode to H.264
Detected → [Other] → Copy
```

### Audio Track
```
Detected
    ├── [Preferred (AAC/MP3)] → Copy as Primary
    ├── [Non-commentary, No Preferred] → Convert to AAC as Primary
    ├── [Commentary] → Drop
    ├── [Discardable Format] → Drop (if not Primary)
    └── [Preservable Format] → Copy as Additional (Movies/TV with flag)
```

### Subtitle Track
```
Detected
    ├── [Not Text-Based] → Ignore
    ├── [Forced ∧ ¬KEEP_FORCED] → Discard
    ├── [SDH ∧ ¬KEEP_SDH] → Discard
    └── [Keep] → Extract to SRT → Deduplicate → Post-process → Rename
```

## FFmpeg Argument Model

### Video Args
```
-map 0:v:0 -c:v:0 {h264|copy}
```

### Audio Args (Multi-track)
```
-map 0:a:{in_idx} -c:a:{out_idx} {copy|aac}
```

### Subtitle Removal
```
-map -0:s
```

### Subtitle Extraction
```
-map 0:s:{idx} -c:s srt extractedSubtitleFile.{SESSION}.{LANG}.srt
```

## Output File Model

### Optimised Video
- **Path**: `{directory}/{sanitised_name}.mkv`
- **Container**: Matroska
- **Video**: H.264 (if AV1/VP9) or original
- **Audio**: ≥1 track (AAC/MP3 primary + preservable additional)
- **Subtitles**: None (removed)

### Extracted Subtitles
- **Path**: `{directory}/{sanitised_name}.{LANG}.srt`
- **Format**: SubRip (SRT)
- **One per unique language** (after deduplication)