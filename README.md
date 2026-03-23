<div align="center">

# 🛡️ Linux Security Toolkit

**Production-grade security stack for Debian/Ubuntu systems**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu%20%7C%20ZorinOS-blue)](https://ubuntu.com)
[![Shell](https://img.shields.io/badge/shell-bash-green)](https://www.gnu.org/software/bash/)
[![Go Tools](https://img.shields.io/badge/go--tools-14-00ADD8?logo=go)](install-go-tools.sh)

</div>

---

## Why This Exists

Most Linux systems ship with **zero active security monitoring**. This toolkit turns a default desktop/server install into a hardened, self-auditing system — without requiring deep security knowledge to set up.

**One command replaces hours of manual configuration.**

---

## What's Included

| Script | Purpose |
|--------|---------|
| [`sysguard-installer.sh`](sysguard-installer.sh) | Full security stack — antivirus, IDS, firewall, audit daemons, custom CLI |
| [`install-go-tools.sh`](install-go-tools.sh) | 14 Go-based recon & offensive security tools |
| [`secmon`](secmon) | Live terminal dashboard for all security services |

---

## sysguard-installer.sh

6-phase installer. Each phase is optional — skip what you don't need.

### Phases

```
Phase 1 — Modern CLI Tools      eza, bat, ripgrep, dust, duf, procs, fzf, starship, zoxide
Phase 2 — Security Hardening    ClamAV, Fail2Ban, AuditD, UFW, RKHunter, Lynis, AIDE, USBGuard
Phase 3 — Network Tools         DNSCrypt-proxy, nmap, netstat, whois, traceroute
Phase 4 — Monitoring            btop, vnstat, smartmontools, logwatch, sysstat
Phase 5 — Automation Scripts    sysguard, syshealth, sysnotify, secaudit, sysclean
Phase 6 — SysGuard Ecosystem    Integrates everything, sets up systemd timers
```

### What you get after install

- **Real-time antivirus** scanning every file access (ClamAV daemon)
- **Brute-force protection** — auto-bans IPs after failed login attempts (Fail2Ban)
- **File integrity monitoring** — detects any unauthorized file change (AIDE, daily)
- **Rootkit scanning** every week (RKHunter)
- **Full system security audit** every night (Lynis)
- **Encrypted DNS** — all DNS queries encrypted via Cloudflare DoH (DNSCrypt)
- **Firewall** with sane defaults (UFW)
- **Kernel audit log** — every syscall, file access, user action logged (AuditD)
- **Automated log reports** delivered daily (Logwatch)
- **Custom notification system** — alerts you when something needs attention (SysNotify, every 30min)

### Install

```bash
git clone https://github.com/Evil-Null/linux-security-toolkit
cd linux-security-toolkit
bash sysguard-installer.sh
```

---

## install-go-tools.sh

Installs Go (if missing) then builds 14 tools from source.

| Tool | Category | What it does |
|------|----------|-------------|
| [`nuclei`](https://github.com/projectdiscovery/nuclei) | Scanner | Template-based CVE/vulnerability scanner |
| [`httpx`](https://github.com/projectdiscovery/httpx) | Recon | Fast HTTP probing & fingerprinting |
| [`katana`](https://github.com/projectdiscovery/katana) | Crawler | Next-gen web crawler |
| [`subfinder`](https://github.com/projectdiscovery/subfinder) | Recon | Passive subdomain enumeration |
| [`naabu`](https://github.com/projectdiscovery/naabu) | Scanner | High-speed port scanner |
| [`dnsx`](https://github.com/projectdiscovery/dnsx) | DNS | DNS toolkit — resolve, brute, validate |
| [`amass`](https://github.com/owasp-amass/amass) | Recon | OWASP attack surface mapping |
| [`dalfox`](https://github.com/hahwul/dalfox) | Scanner | XSS vulnerability scanner |
| [`hakrawler`](https://github.com/hakluke/hakrawler) | Crawler | Fast web crawler for hackers |
| [`subzy`](https://github.com/LukaSikic/subzy) | Scanner | Subdomain takeover detector |
| [`gau`](https://github.com/lc/gau) | Recon | Historical URL fetcher (Wayback + Common Crawl) |
| [`ffuf`](https://github.com/ffuf/ffuf) | Fuzzer | Fast web fuzzer |
| [`unfurl`](https://github.com/tomnomnom/unfurl) | Utility | Pull data out of URLs |
| [`assetfinder`](https://github.com/tomnomnom/assetfinder) | Recon | Find domains and subdomains |

All tools build from source — no pre-compiled binaries, no supply chain risk.

### Install

```bash
bash install-go-tools.sh
```

Tools land in `~/go/bin/` and are immediately available in PATH.

---

## secmon — Live Security Dashboard

Real-time terminal UI for all security services.

```
┌─ Services ──────────┐ ┌─ Timers ──────────────┐ ┌─ Fail2Ban ──┐
│ 🛡️  ClamAV  running  │ │ AIDE         6h 12m   │ │ sshd    0   │
│ 🚫 Fail2Ban running  │ │ Lynis        6h 21m   │ │ nginx   2   │
│ 👁️  AuditD  running  │ │ RKHunter     5 days   │ └─────────────┘
│ 🔒 DNSCrypt running  │ │ SecAudit     6 days   │
└─────────────────────┘ └───────────────────────┘
┌─ Last 16 log entries (security services, 24h) ──────────────────┐
│ ClamAV: Database up-to-date (version: 27949)                    │
│ AuditD: Rotating log files                                      │
└─────────────────────────────────────────────────────────────────┘
```

Refreshes every 5 seconds. Warnings highlighted in yellow.

### Install

```bash
cp secmon ~/.local/bin/secmon
chmod +x ~/.local/bin/secmon
secmon
```

Requires: `pip install rich` (or `pipx install rich`)

---

## Requirements

- Debian / Ubuntu / ZorinOS / Pop!_OS / Linux Mint
- `sudo` access
- Internet connection

---

## License

MIT — use freely, modify freely.
