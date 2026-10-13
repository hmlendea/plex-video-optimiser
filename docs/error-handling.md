# Error Handling

## Error Taxonomy

| Category | Examples | Handling |
|----------|----------|----------|
| **Input Validation** | File not found, not a file | Exit 1 with message |
| **Dependency Missing** | `mkvmerge`, `ffmpeg` not found | Command fails, script continues with empty vars |
| **External Command Failure** | `mkvmerge`, `mkvinfo`, `ffmpeg` non-zero exit | No explicit check; empty output → wrong decisions |
| **User Cancellation** | N at confirmation prompts | Clean exit, no partial output |
| **Output Verification** | Temp file missing after ffmpeg | Script continues, replacement prompt shows missing file |
| **Filesystem** | Disk full, permissions, read-only | OS-level errors propagate |

## Current Handling Patterns

### 1. Input Validation (Explicit)
```bash
if [ ! -f "${FILE_PATH}" ]; then
    echo "Cannot access '${FILE_PATH}': No such file or directory"
    exit 1
end
```

### 2. Command Substitution (Implicit)
```bash
VIDEO_FORMAT=$(getVideoTrackFormat)
# If mkvmerge fails, VIDEO_FORMAT="" → treated as "no conversion needed"
```

### 3. User Confirmation (Explicit)
```bash
read -p "Are you sure? [Y/n] " -n 1 -r
if [[ ${REPLY} =~ ^[Yy]$ ]] || [ -z "${REPLY}" ]; then
    # proceed
else
    exit 0
fi
```

### 4. Output Verification (Partial)
```bash
if [ ! -f "${OUTPUT_TEMP_FILE}" ]; then
    exit  # Silent exit, no error message
fi
```

## Gaps & Risks

| Gap | Risk | Mitigation |
|-----|------|------------|
| No dependency check at startup | Confusing errors mid-run | Add `command -v` checks |
| No `set -e` | Failures silent, wrong state | Add `set -euo pipefail` |
| No ffmpeg exit code check | Corrupt output not detected | Check `$?` after ffmpeg |
| No temp file cleanup on interrupt | Orphaned `.OPTIMISED.mkv` files | Trap signals |
| Empty `VIDEO_FORMAT` = copy | AV1/VP9 not detected → wrong output | Validate mkvmerge output |
| No stderr capture | Errors lost in output | Redirect stderr to log |

## Recommended Improvements

### Add Startup Validation
```bash
for cmd in mkvmerge mkvinfo ffmpeg perl-rename; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command '$cmd' not found"
        exit 1
    fi
done
```

### Add Strict Mode
```bash
set -euo pipefail
```

### Check ffmpeg Exit Code
```bash
ffmpeg -i "${FILE_PATH}" ${FFMPEG_ARGUMENTS} "${OUTPUT_TEMP_FILE}"
if [ $? -ne 0 ]; then
    echo "ERROR: ffmpeg failed"
    rm -f "${OUTPUT_TEMP_FILE}"
    exit 1
fi
```

### Trap Cleanup
```bash
cleanup() {
    rm -f "${OUTPUT_TEMP_FILE}"
    rm -f extractedSubtitleFile.${SESSION_ID}.*
}
trap cleanup EXIT INT TERM
```

### Validate Critical Variables
```bash
if [ -z "${VIDEO_FORMAT}" ]; then
    echo "ERROR: Could not detect video format"
    exit 1
fi
```

## Error Messages

| Situation | Current Message | Improved |
|-----------|-----------------|----------|
| File not found | `Cannot access '...': No such file or directory` | ✅ Clear |
| mkvmerge fails | (silent, empty var) | `ERROR: mkvmerge failed to inspect file` |
| ffmpeg fails | (silent, continues) | `ERROR: ffmpeg exited with code $?` |
| No output file | (silent exit) | `ERROR: Output file not created` |
| User cancels | (clean exit) | ✅ Acceptable |

## Recovery Strategies

| Failure Point | Recovery |
|---------------|----------|
| Before ffmpeg | Re-run script |
| During ffmpeg | Re-run script (original intact) |
| After ffmpeg, before replace | `.OPTIMISED.mkv` exists, manually rename |
| After replace | Original lost — restore from backup |

## Best Practices for Modifications

1. **Always check command exit codes** for external tools
2. **Validate critical variables** before use
3. **Use `set -euo pipefail`** at script top
4. **Trap signals** for temp file cleanup
5. **Provide actionable error messages** with suggested fixes