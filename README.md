<div align="center">

# 🛡️ Linux Security Toolkit

**Production-grade security stack for Debian/Ubuntu systems**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu%20%7C%20ZorinOS-blue)](https://ubuntu.com)
[![Release](https://img.shields.io/github/v/release/Evil-Null/linux-security-toolkit)](https://github.com/Evil-Null/linux-security-toolkit/releases)

</div>

---

## Overview

A hardened, self-auditing security ecosystem for Linux desktops and servers.
Turns a default install into an actively monitored, protected system — in one command.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Evil-Null/linux-security-toolkit/master/install.sh | bash
```

Or download manually from [Releases](https://github.com/Evil-Null/linux-security-toolkit/releases).

---

## Components

### `sysguard` — Security Stack Installer

6-phase setup covering:

- **Antivirus** — real-time file scanning
- **Intrusion prevention** — auto-blocks brute-force attempts
- **File integrity monitoring** — detects unauthorized changes
- **Kernel audit logging** — full system activity trail
- **Encrypted DNS** — all queries encrypted, no leaks
- **Firewall** — strict default-deny ruleset
- **Automated scanning** — scheduled rootkit and vulnerability checks
- **System health scripts** — `sysguard`, `syshealth`, `sysnotify`, `secaudit`, `sysclean`

### `go-tools` — Recon & Offensive Toolkit

14 compiled tools for penetration testing and attack surface mapping.
Covers: scanning, fuzzing, subdomain enumeration, crawling, XSS detection, DNS analysis.

### `secmon` — Live Security Dashboard

Real-time terminal UI showing service status, scheduled job timers, and security events.

```bash
# Download and run
curl -fsSL https://github.com/Evil-Null/linux-security-toolkit/releases/latest/download/secmon -o secmon
chmod +x secmon && ./secmon
```

---

## Requirements

- Debian / Ubuntu / ZorinOS / Pop!_OS / Linux Mint
- `sudo` access
- x86_64 architecture

---

## License

MIT
