# Contributing to plex-video-optimiser

This document covers the guidelines and processes for contributing to this project, including how to report issues, suggest enhancements, submit code changes, and follow project standards.

## 📑 Table of Contents

- [How to Contribute](#-how-to-contribute)
  - [Reporting Issues](#reporting-issues)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Code Contributions](#code-contributions)
    - [Prerequisites](#prerequisites)
    - [Development Setup](#development-setup)
    - [Making Changes](#making-changes)
    - [Pull Request Guidelines](#pull-request-guidelines)
  - [Code Style](#code-style)
  - [Testing](#testing)
  - [Documentation](#documentation)
- [Code of Conduct](#-code-of-conduct)
- [Security](#-security)
- [License](#-license)
- [Recognition](#-recognition)
- [Getting Help](#-getting-help)

## 🤝 How to Contribute

### Reporting Issues

- Search existing issues first.
- Use the issue templates if available.
- Provide clear reproduction steps.
- Include environment details (OS, Bash version, mkvtoolnix version, ffmpeg version).

### Suggesting Enhancements

- Check the roadmap and existing discussions.
- Explain the use case and expected behavior.
- Consider implementation complexity.

### Code Contributions

#### Prerequisites

- Bash 4.0 or later
- mkvtoolnix (mkvmerge, mkvinfo)
- ffmpeg
- perl-rename (File::Rename)
- fix-subtitle (optional, for subtitle post-processing)
- iconv (usually provided by glibc)
- coreutils (du, basename, dirname, etc.)

#### Development Setup

```bash
# Clone the repository
git clone https://github.com/horatiu/plex-video-optimiser.git
cd plex-video-optimiser

# No installation required; the script runs directly
# Ensure all dependencies are installed on your system
# On Ubuntu/Debian:
sudo apt-get install mkvtoolnix ffmpeg rename fix-subtitle

# On macOS (Homebrew):
brew install mkvtoolnix ffmpeg file-rename fix-subtitle

# On Arch Linux:
sudo pacman -S mkvtoolnix-cli ffmpeg perl-rename fix-subtitle
```

#### Making Changes

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes to `plex-video-optimiser.sh`.
4. Run shellcheck: `shellcheck plex-video-optimiser.sh`
5. Test manually with sample media files.
6. Commit with clear and descriptive messages.
7. Push to your fork.
8. Open a Pull Request.

#### Pull Request Guidelines

- Target the `master` branch.
- Keep PRs focused and atomic.
- Update documentation if applicable.
- Ensure the CI checks pass (shellcheck workflow).

### Code Style

Follow the project's coding standards:
- Run `shellcheck plex-video-optimiser.sh` before committing.
- Use 4-space indentation.
- Use descriptive variable and function names.
- Keep functions focused and small.
- Comment complex logic.

### Testing

No automated test suite exists. Manual testing is required:

```bash
# Test with a sample file
./plex-video-optimiser.sh /path/to/sample.mkv

# Verify output
mkvmerge -i output.mkv
```

Recommended test scenarios:
- Optimising an AV1 file to H.264
- Processing a file with multiple audio tracks
- Extracting and deduplicating subtitles
- Running the script on an already-optimised file (should report "No optimisation needed")

### Documentation

- Update relevant docs in `docs/` for changes.
- Follow the existing documentation style.
- Update `README.md` if usage changes.

## 📋 Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## 🔒 Security

Report security vulnerabilities per the [Security Policy](SECURITY.md).

## 📄 License

By contributing, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).

## 🙏 Recognition

Contributors are recognized in the [GitHub contributors list](https://github.com/horatiu/plex-video-optimiser/graphs/contributors).

## ❓ Getting Help

- Open a [GitHub Issue](https://github.com/horatiu/plex-video-optimiser/issues) for bugs or questions.
- Check existing discussions and documentation first.