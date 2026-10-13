# Security

## Threat Model

plex-video-optimiser is a **local CLI tool** run by the file owner on their own media files. No network access, no privilege escalation, no multi-user context.

## Attack Surface

| Vector | Risk | Mitigation |
|--------|------|------------|
| Input file path | Path traversal? | `basename`/`dirname` used, but `FILE_PATH="$*"` joins all args |
| Temp file names | Collision/prediction | 32-char random SESSION_ID from `/dev/urandom` |
| Command injection | User input in commands | No user input in command substitution (only file paths) |
| ffmpeg/mkvmerge exploits | Malformed media files | Upstream responsibility |
| File overwrite | Accidental data loss | Two confirmations, temp file, explicit replace prompt |

## Security Controls

### 1. Input Validation
```bash
FILE_PATH="$*"
if [ ! -f "${FILE_PATH}" ]; then
    echo "Cannot access '${FILE_PATH}': No such file or directory"
    exit 1
fi
```
- Checks file exists and is regular file
- Does not resolve symlinks (follows them)

### 2. Temp File Isolation
```bash
SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
OUTPUT_TEMP_FILE="${OUTPUT_FILE_PATH_WITHOUT_EXTENSION}.OPTIMISED.mkv"
```
- High-entropy session ID prevents prediction
- Temp file in same directory as input (user-writable)

### 3. No Command Injection
- All command substitutions use controlled variables
- `FILE_PATH` only used in `mkvmerge`, `mkvinfo`, `ffmpeg` as file argument
- No `eval`, no user input in command position

### 4. Confirmation Gates
```bash
read -p "Are you sure you want to optimise...? [Y/n] "
read -p "Do you want to replace the original file? [Y/n] "
```
- Two explicit confirmations before destructive action
- Default "Yes" on Enter (convenience over safety)

### 5. Transactional Write
- Writes to `.OPTIMISED.mkv` temp file
- Only renames over original after second confirmation
- Original preserved until explicit replace

## Vulnerabilities (Known)

| Issue | Severity | Description |
|-------|----------|-------------|
| `FILE_PATH="$*"` joins args | Low | Spaces in path work, but multiple files concatenated |
| No symlink check | Low | Could follow symlink outside intended directory |
| Default "Yes" on Enter | Medium | Accidental Enter confirms destructive action |
| No `set -e` | Low | Failures may continue with wrong state |
| Temp files not cleaned on interrupt | Low | Orphaned files on Ctrl+C |

## Recommendations

1. **Change default to "No"**: `[Y/n]` → `[y/N]`
2. **Add `set -euo pipefail`** at script top
3. **Trap signals** for temp file cleanup
4. **Validate single file argument**: `if [ $# -ne 1 ]; then ...`
5. **Resolve symlinks**: `FILE_PATH=$(realpath "$1")`
6. **Check ffmpeg exit code** explicitly

## Compliance

- **No personal data processed** — only media files
- **No network communication** — fully offline
- **No authentication/authorisation** — local user context
- **GPL v3 licensed** — source available, modifiable