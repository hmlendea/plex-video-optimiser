# Documentation Index

## Repository Summary

**plex-video-optimiser** is a CLI tool written in Bash that optimises video files for direct-stream compatibility with Plex on Raspberry Pi devices. It analyses MKV files, converts incompatible video/audio codecs (AV1/VP9 to H.264, non-AAC/MP3 audio to AAC), removes unwanted subtitle tracks, extracts and normalises subtitle languages, and produces clean MKV output files.

## Root Document Map

- [ARCHITECTURE.md](../ARCHITECTURE.md) — High-level architecture (if present)
- [SECURITY.md](../SECURITY.md) — Security model (if present)
- [ROADMAP.md](../ROADMAP.md) — Project roadmap (if present)
- [PRIVACY.md](../PRIVACY.md) — Privacy policy (if present)
- [LICENSE](../LICENSE) — GNU GPL v3 license

## Documentation Catalogue

### Architecture & Design
- [architecture.md](./architecture.md) — High-level architecture complementing root ARCHITECTURE.md
- [design-decisions.md](./design-decisions.md) — Key architectural/design choices and rationale
- [repository-structure.md](./repository-structure.md) — Source tree layout, module organisation
- [repository-overview.md](./repository-overview.md) — Repository purpose, scope, entry points

### Components
- [components/video-processing.md](./components/video-processing.md) — Video track detection and conversion logic
- [components/audio-processing.md](./components/audio-processing.md) — Audio track selection, conversion, and preservation
- [components/subtitle-processing.md](./components/subtitle-processing.md) — Subtitle extraction, language detection, deduplication
- [components/file-naming.md](./components/file-naming.md) — Output file name sanitisation and TV show episode detection

### Execution Flows
- [flows/main-execution.md](./flows/main-execution.md) — End-to-end optimisation flow from input to output
- [flows/subtitle-extraction.md](./flows/subtitle-extraction.md) — Subtitle extraction and post-processing flow

### Reference
- [api-reference/INDEX.md](./api-reference/INDEX.md) — Function reference index
- [api-reference/core-functions.md](./api-reference/core-functions.md) — Core function documentation
- [api-reference/track-functions.md](./api-reference/track-functions.md) — Track inspection functions
- [api-reference/ffmpeg-functions.md](./api-reference/ffmpeg-functions.md) — FFmpeg argument generation functions

### Operations
- [configuration.md](./configuration.md) — Configuration options and environment variables
- [build-and-deployment.md](./build-and-deployment.md) — Build pipeline, GitHub Actions workflow
- [testing.md](./testing.md) — Test strategy and organisation
- [troubleshooting.md](./troubleshooting.md) — Common issues and solutions

### Cross-Cutting Concerns
- [dependencies.md](./dependencies.md) — External dependencies (mkvtoolnix, ffmpeg, perl-rename, fix-subtitle)
- [error-handling.md](./error-handling.md) — Error taxonomy, handling patterns, recovery
- [logging.md](./logging.md) — Logging approach (stdout/stderr, session IDs)
- [security.md](./security.md) — Security model, threat mitigations
- [invariants.md](./invariants.md) — System-wide invariants and contracts
- [concurrency-and-scheduling.md](./concurrency-and-scheduling.md) — Sequential execution model
- [state-and-persistence.md](./state-and-persistence.md) — Temporary file handling, session management
- [data-model.md](./data-model.md) — Track metadata model, language codes

### Maintenance
- [documentation-maintenance.md](./documentation-maintenance.md) — How to keep docs current
- [change-guide.md](./change-guide.md) — How to modify common areas safely
- [ambiguities-and-open-questions.md](./ambiguities-and-open-questions.md) — Unresolved items, TODOs, known gaps
- [faq.md](./faq.md) — Frequently asked questions
- [quick-start.md](./quick-start.md) — Getting started guide for newcomers

## Navigation Aids

- **Start here** (newcomers): [quick-start.md](./quick-start.md) → [repository-overview.md](./repository-overview.md) → [flows/main-execution.md](./flows/main-execution.md)
- **Deep dive** (component owners): [components/](./components/) → [api-reference/](./api-reference/)
- **Flows** (debuggers): [flows/main-execution.md](./flows/main-execution.md) → [flows/subtitle-extraction.md](./flows/subtitle-extraction.md)

## Maintenance Metadata

- Last reviewed: 2026-10-13
- Owner: repository maintainers
- Coverage status: Comprehensive — all major components, flows, and functions documented