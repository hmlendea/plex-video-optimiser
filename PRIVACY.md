# Privacy and Personal Data

plex-video-optimiser is a local command-line tool for optimising video files for Plex direct-stream playback. It runs entirely on the user's machine, processes only media files explicitly provided as input, and has no network connectivity, telemetry, or external data transmission.

**Information reviewed:** 2026-10-13

## 📑 Table of Contents

- [What This Document Covers](#-what-this-document-covers)
- [Self-Hosted Deployments](#-self-hosted-deployments)
- [Data We Handle](#-data-we-handle)
- [Processing and Use](#-processing-and-use)
- [Storage, Retention, and Deletion](#-storage-retention-and-deletion)
- [External Processing and Integrations](#-external-processing-and-integrations)
- [Data Protection and Security](#-data-protection-and-security)
- [Document Changes](#-document-changes)
- [Contact](#-contact)

## 🔎 What This Document Covers

This document describes how plex-video-optimiser at https://github.com/horatiu/plex-video-optimiser handles personal data. It covers the application behaviour and verified integrations described below. Where the software is self-hosted, the instance operator may have separate responsibilities described below.

## 🏠 Self-Hosted Deployments

plex-video-optimiser is designed exclusively for self-hosted, local execution. The user downloads and runs the script on their own machine. The project maintainers do not operate any service, collect any data, or receive any information from user executions.

The instance operator (the user running the script) has full control over:
- Configuration (via editing the script's constants)
- Local storage (input files, output files, temporary files)
- Logs (stdout/stderr output visible only to the operator)
- Backups (entirely operator-managed)
- Access controls (file system permissions)
- Retention and deletion (operator decides when to remove files)

No data is sent from a self-hosted instance to project maintainers or any external service. There is no telemetry, no update checks, no crash reports, no email, no authentication, no reverse proxy, no object storage, and no monitoring integrations built into the script.

## 📥 Data We Handle

### Data Provided to the Application

The application accepts one input: a path to a media file (video container such as MKV, MP4, AVI, etc.) provided as a command-line argument. The file may contain video, audio, and subtitle tracks. No personal data beyond the media content itself is requested or required.

### Data Generated or Collected by the Application

The application generates the following during execution:
- Temporary optimised video file (`.OPTIMISED.mkv`) in the same directory as the input
- Extracted subtitle files (`.srt`) in the same directory as the input (only if user confirms extraction)
- Standard output and standard error streams containing progress information, file sizes, and track listings

No personal data, identifiers, usage analytics, crash reports, or telemetry are generated or collected automatically.

### Data Received from Integrations

No personal data is received from integrations or third parties. The script invokes local command-line tools (mkvmerge, mkvinfo, ffmpeg, perl-rename, fix-subtitle, iconv) as subprocesses. These tools process the input file locally and return results via stdout/stderr. No data leaves the machine.

## 🧭 Processing and Use

The application processes the data described above for these verified functions:
- Video track inspection and optional transcoding (AV1/VP9 → H.264) — media file content
- Audio track selection, conversion, and preservation — media file content
- Subtitle extraction, language detection, deduplication, and post-processing — media file content
- Filename sanitisation for Plex compatibility — input filename only
- Container remuxing to MKV (if not already MKV) — media file content

## 🗄️ Storage, Retention, and Deletion

All data remains on the operator's local filesystem:
- **Input file**: Unmodified unless the operator explicitly confirms replacement after optimisation
- **Temporary optimised file**: Created as `.OPTIMISED.mkv` in the input file's directory; renamed to final name only after explicit operator confirmation; remains if operator declines replacement
- **Extracted subtitles**: Created as `.srt` files in the input file's directory; retained indefinitely unless manually deleted by operator
- **Temporary subtitle extraction files**: Created in the current working directory with pattern `extractedSubtitleFile.{SESSION_ID}.{LANG}.srt`; cleaned up during deduplication and rename process
- **Session ID**: 32-character random string from `/dev/urandom` used only for temporary file isolation; not persisted
- **Logs**: stdout/stderr only; not written to persistent log files by the script

The instance operator controls all storage, deletion, and backups. The project does not control or access any local data.

## 🔗 External Processing and Integrations

The application has no built-in external data transfer. It invokes the following local command-line tools as subprocesses:

| Service or integration | Purpose | Data involved | Configuration or documentation |
|-----------------------|---------|---------------|--------------------------------|
| mkvmerge (mkvtoolnix) | Container inspection, remuxing | Media file content | https://mkvtoolnix.download/ |
| mkvinfo (mkvtoolnix) | Track metadata inspection | Media file content | https://mkvtoolnix.download/ |
| ffmpeg | Video/audio transcoding, subtitle extraction | Media file content | https://ffmpeg.org/ |
| perl-rename | Subtitle filename normalisation | Subtitle filenames only | https://metacpan.org/pod/File::Rename |
| fix-subtitle (optional) | Subtitle timing/format correction | Subtitle content | https://github.com/horatiu/fix-subtitle |
| iconv | Character encoding conversion | Subtitle content | System package (glibc) |

All tools run locally. No data is transmitted to their upstream projects or any external destination.

## 🛡️ Data Protection and Security

The script implements the following technical safeguards:
- **No network access**: The script contains no network calls, HTTP requests, or socket operations
- **Input validation**: Verifies input file exists and is a regular file before processing
- **Temp file isolation**: Uses a 32-character random session ID from `/dev/urandom` to prevent temp file collisions
- **Transactional writes**: Writes output to a temporary file; only replaces original after explicit operator confirmation
- **No privilege escalation**: Runs with the operator's user permissions; no sudo, setuid, or capability requirements
- **No secrets handling**: Does not read, write, or process credentials, tokens, keys, or passwords

For self-hosted deployments, the operator is responsible for:
- Keeping dependencies (mkvtoolnix, ffmpeg, etc.) updated
- Managing file system permissions on media directories
- Securing the execution environment
- Backing up media files before processing
- Reviewing script modifications before execution

The project does not promise absolute security. Media files may contain metadata (e.g., GPS coordinates in video, device identifiers in audio) that the script preserves or transcodes but does not inspect or strip.

## 🔄 Document Changes

Update this document when application data flows, storage, integrations, or deployment responsibilities change. The current version is published at https://github.com/horatiu/plex-video-optimiser/blob/master/PRIVACY.md.

## 📬 Contact

For questions about application data handling, contact the project maintainers via GitHub Issues at https://github.com/horatiu/plex-video-optimiser/issues. For a self-hosted instance, the instance operator is the sole data controller; the project maintainers have no access to operator data. Include the script version (git commit or release tag) and a description of the data flow in question; do not send passwords, access tokens, or other secrets.