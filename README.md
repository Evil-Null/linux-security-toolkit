# Linux Security Toolkit

Personal security ecosystem for Debian/Ubuntu systems.

## Contents

| File | Description |
|------|-------------|
| `sysguard-installer.sh` | Full system security stack installer (ClamAV, Fail2Ban, AuditD, RKHunter, Lynis, AIDE, custom scripts) |
| `install-go-tools.sh` | Go-based recon/offensive tools installer (ProjectDiscovery suite + more) |

---

## sysguard-installer.sh

Installs and configures a full server-grade security stack:

- **ClamAV** — real-time antivirus
- **Fail2Ban** — brute-force protection
- **AuditD** — kernel-level audit daemon
- **RKHunter** — rootkit scanner (weekly cron)
- **Lynis** — system security audit (nightly)
- **AIDE** — file integrity checker (daily)
- **Logwatch** — daily log reports
- **DNSCrypt-proxy** — encrypted DNS
- **UFW** — firewall
- Custom scripts: `sysguard`, `syshealth`, `sysnotify`, `secaudit`, `sysclean`

```bash
bash sysguard-installer.sh
```

---

## install-go-tools.sh

Installs Go (if not present) then builds and installs:

| Tool | Purpose |
|------|---------|
| `nuclei` | Template-based vulnerability scanner |
| `httpx` | Fast HTTP probing |
| `katana` | Web crawler |
| `subfinder` | Subdomain enumeration |
| `naabu` | Port scanner |
| `dnsx` | DNS toolkit |
| `amass` | Attack surface mapping |
| `dalfox` | XSS scanner |
| `hakrawler` | Web crawler |
| `subzy` | Subdomain takeover checker |
| `gau` | URL fetcher (Wayback/Common Crawl) |
| `ffuf` | Web fuzzer |
| `unfurl` | URL parser |
| `assetfinder` | Asset discovery |

```bash
bash install-go-tools.sh
```

Tools are installed to `~/go/bin/`.

---

## Requirements

- Debian / Ubuntu (or derivatives: ZorinOS, Pop!_OS, Linux Mint...)
- `sudo` access (for sysguard-installer.sh)
- Internet connection
