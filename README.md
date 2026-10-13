[![Donate](https://img.shields.io/badge/-%E2%99%A5%20Donate-%23ff69b4)](https://hmlendea.go.ro/fund.html) [![Build Status](https://github.com/hmlendea/plex-video-optimiser/actions/workflows/bash.yml/badge.svg)](https://github.com/hmlendea/plex-video-optimiser/actions/workflows/bash.yml)
[![Latest Release](https://img.shields.io/github/v/release/hmlendea/plex-video-optimiser)](https://github.com/hmlendea/plex-video-optimiser/releases/latest)
[![License](https://img.shields.io/github/license/hmlendea/plex-video-optimiser)](https://github.com/hmlendea/plex-video-optimiser/blob/master/LICENSE)

# plex-video-optimiser

A CLI tool to optimise video files for use on Plex on a Raspberry Pi. The output should be as direct-stream-compatible with as many devices as possible.

## 📑 Table of Contents

- [Capabilities](#-capabilities)
- [Use Cases](#-use-cases)
- [Usage](#-usage)
- [Command Reference](#-command-reference)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Architecture](#-architecture)
- [Contributing](#-contributing)
- [Security](#-security)
- [License](#-license)

## ✨ Capabilities

- Converts AV1 and VP9 video codecs to H.264 for broad device compatibility
- Selects and converts audio tracks to AAC while preserving original high-quality tracks
- Extracts and processes subtitles with language detection and deduplication
- Sanitises filenames for Plex compatibility (removes release groups, quality tags, codec info)
- Detects TV show episodes and applies TV-specific processing rules
- Converts containers to Matroska (MKV) format
- Interactive confirmations before processing and before replacing original files

## 🎯 Use Cases

- **Plex on Raspberry Pi:** Optimise video files for direct-stream playback on resource-constrained devices
- **Codec compatibility:** Convert modern codecs (AV1, VP9) to widely-supported H.264
- **Audio normalisation:** Ensure audio tracks use compatible codecs (AAC) while preserving quality originals
- **Subtitle management:** Extract, deduplicate, and normalise subtitle tracks
- **Library organisation:** Sanitise filenames for consistent Plex library presentation

## 🚀 Usage

```bash
./plex-video-optimiser.sh "/path/to/video/file.mkv"
```

The script will:
1. Analyse the input file (video, audio, subtitle tracks)
2. Determine what conversions are needed
3. Display the planned FFmpeg arguments
4. Prompt for confirmation before processing
5. Process the file and display size comparison
6. Prompt to replace the original file

## ⌨️ Command Reference

| Command | Description |
|---------|-------------|
| `./plex-video-optimiser.sh <file>` | Optimise a single video file |
| `KEEP_ORIGINAL_AUDIO_TRACKS_FOR_TVSHOWS=true ./plex-video-optimiser.sh <file>` | Preserve all original audio tracks for TV episodes |
| `KEEP_FORCED_SUBTITLES=true ./plex-video-optimiser.sh <file>` | Keep forced subtitle tracks |
| `KEEP_SDH_SUBTITLES=true ./plex-video-optimiser.sh <file>` | Keep SDH (Subtitles for the Deaf and Hard of Hearing) tracks |

## ⚠️ Known Limitations

- Single-threaded sequential processing; no parallel execution
- Requires manual confirmation at two stages (not suitable for fully automated batch processing)
- Hardcoded release group and quality tag lists for filename sanitisation
- Subtitle language detection relies on track names; falls back to MKV metadata
- No configuration file; options controlled via environment variables only
- Temporary files created in the same directory as the input file
- No progress indicator during FFmpeg execution

## 🖥️ System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS | Linux (any modern distribution) | Linux (Ubuntu 20.04+, Debian 11+, Arch, Fedora) |
| Shell | Bash 4.0+ | Bash 5.0+ |
| mkvtoolnix | mkvmerge, mkvinfo | Latest stable |
| ffmpeg | 4.0+ with libx264, libfdk_aac | Latest stable |
| perl-rename | Any version | Latest |
| fix-subtitle | Optional | Latest (for subtitle post-processing) |
| iconv | Standard (glibc) | Standard |
| coreutils | Standard (GNU) | Standard |

## 📦 Installation

[![Obtain it from GitHub](https://raw.githubusercontent.com/hmlendea/readme-assets/master/badges/stores/github.png)](https://github.com/hmlendea/plex-video-optimiser/releases)

### From Source

```bash
git clone https://github.com/hmlendea/plex-video-optimiser.git
cd plex-video-optimiser
chmod +x plex-video-optimiser.sh
```

### Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install mkvtoolnix ffmpeg rename fix-subtitle
```

**Arch Linux:**
```bash
sudo pacman -S mkvtoolnix-cli ffmpeg perl-rename fix-subtitle
```

**Fedora:**
```bash
sudo dnf install mkvtoolnix ffmpeg perl-File-Rename fix-subtitle
```

**macOS (Homebrew):**
```bash
brew install mkvtoolnix ffmpeg rename fix-subtitle
```

## 🏗️ Architecture

See [architecture documentation](ARCHITECTURE.md) for system context, component responsibilities, data flow, and operational characteristics.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## 📜 Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code.

## 💝 Project Engagement

- [Report issues](https://github.com/hmlendea/plex-video-optimiser/issues)
- [Request features](https://github.com/hmlendea/plex-video-optimiser/issues/new?template=feature_request.md)
- [Security vulnerabilities](SECURITY.md)

## 📄 License

GNU General Public License v3.0 or later. See [LICENSE](LICENSE) for details.
