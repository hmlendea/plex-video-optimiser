# Security Policy

This document describes the security policy for plex-video-optimiser, a local command-line tool for video file optimisation. The tool operates entirely on the user's filesystem with no network connectivity, telemetry, or external services.

## 📑 Table of Contents

- [Supported Versions](#-supported-versions)
- [Reporting a Vulnerability](#-reporting-a-vulnerability)
- [Scope](#-scope)
- [Disclosure Policy](#-disclosure-policy)

## 🛡️ Supported Versions

Use this table to indicate which project versions currently receive security maintenance.

| Version | Distribution Channel | Supported |
|---------|--------------------|-----------|
| Latest version | GitHub Releases | ✅ |
| Latest version | Source code (main branch) | ✅ |
| Preceding versions | Any distribution channel | ❌ |

## 🚨 Reporting a Vulnerability

Please do not disclose suspected vulnerabilities publicly before maintainers have had an opportunity to validate and remediate them.

To report a vulnerability:
- [GitHub Security Advisories](https://github.com/horatiu/plex-video-optimiser/security/advisories)
- Contact the maintainers directly

## 📌 Scope

The subsequent report categories are in scope for this repository:
- Arbitrary code execution via crafted input files
- Path traversal or directory escape during file processing
- Command injection via filename or metadata manipulation
- Denial of service via resource exhaustion (disk, memory, CPU)
- Information disclosure through error messages or logs

The subsequent categories are out of scope unless explicitly stated to the contrary:
- Vulnerabilities in external dependencies (mkvtoolnix, ffmpeg, perl-rename, fix-subtitle, iconv)
- Issues requiring network access (the tool has no network functionality)
- Social engineering or physical access attacks
- Vulnerabilities in the host operating system or filesystem

## 📢 Disclosure Policy

This project follows coordinated disclosure:
1. Vulnerabilities are investigated privately.
2. A remediation plan is prepared and validated.
3. Public disclosure is published after a fix, mitigation, or agreed risk decision is available.
4. Credit is attributed in accordance with reporter preference and project policy.