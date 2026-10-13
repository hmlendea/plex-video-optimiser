# Build and Deployment

## Build Process

**No build step required** — this is a single Bash script interpreted at runtime.

## CI/CD Pipeline

### GitHub Actions Workflow: `.github/workflows/bash.yml`

```yaml
name: Bash

on:
  push:
    branches: [ "master" ]
  pull_request:
    branches: [ "master" ]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run shellcheck
      run: shellcheck plex-video-optimiser.sh
```

**Purpose**: Lint the Bash script with shellcheck on every push/PR to master.

**Trigger**: Push to master, PR to master

**Job**: `shellcheck` — runs shellcheck on the main script

**Dependencies**: `shellcheck` (installed on Ubuntu runner)

## Release Process

1. Tag a commit: `git tag v1.x.x`
2. Push tag: `git push origin v1.x.x`
3. GitHub Actions creates release (if configured)
4. Badge in README updates automatically

## Deployment

**No deployment** — users download and run the script directly.

### Installation (User)

```bash
# Download
curl -O https://raw.githubusercontent.com/hmlendea/plex-video-optimiser/master/plex-video-optimiser.sh
chmod +x plex-video-optimiser.sh

# Or clone
git clone https://github.com/hmlendea/plex-video-optimiser.git
cd plex-video-optimiser
chmod +x plex-video-optimiser.sh
```

### Dependencies (Runtime)

| Tool | Package (Ubuntu/Debian) | Package (Arch) | Package (macOS) |
|------|------------------------|----------------|-----------------|
| `mkvmerge`, `mkvinfo` | `mkvtoolnix` | `mkvtoolnix-cli` | `brew install mkvtoolnix` |
| `ffmpeg` | `ffmpeg` | `ffmpeg` | `brew install ffmpeg` |
| `perl-rename` | `rename` | `perl-rename` | `brew install rename` |
| `fix-subtitle` | N/A (external) | N/A | N/A |
| `iconv` | `libc-bin` | `glibc` | Built-in |
| `du` | `coreutils` | `coreutils` | Built-in |

**Note**: `fix-subtitle` is optional — script checks for `/usr/bin/fix-subtitle` before using.

## Versioning

- Semantic versioning: `vMAJOR.MINOR.PATCH`
- Tags: `v1.6.0`, `v1.5.0`, `v1.4.0`
- Latest tag determines "Latest GitHub release" badge

## Environments

| Environment | Purpose |
|-------------|---------|
| Development | Local testing, script modification |
| CI (GitHub Actions) | Linting only |
| Production | User machines (Raspberry Pi, Linux, macOS) |

## Rollback

- Revert to previous tag: `git checkout v1.5.0`
- No database migrations, no stateful services