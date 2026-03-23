#!/usr/bin/env bash
# Linux Security Toolkit — Installer
# https://github.com/Evil-Null/linux-security-toolkit

set -e

VERSION="v1.0.0"
BASE_URL="https://github.com/Evil-Null/linux-security-toolkit/releases/download/${VERSION}"
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${BOLD}${CYAN}🛡️  Linux Security Toolkit ${VERSION}${NC}\n"

# Check OS
if ! grep -qi "debian\|ubuntu\|zorin\|mint\|pop" /etc/os-release 2>/dev/null; then
    echo -e "${RED}✗ Supported on Debian/Ubuntu-based systems only${NC}"
    exit 1
fi

# Menu
echo "What would you like to install?"
echo ""
echo "  1) sysguard  — full security stack (ClamAV, Fail2Ban, AuditD, RKHunter, Lynis...)"
echo "  2) go-tools  — recon toolkit (nuclei, httpx, subfinder, amass, ffuf...)"
echo "  3) both"
echo ""
read -rp "Choice [1/2/3]: " CHOICE

install_binary() {
    local name="$1"
    local url="${BASE_URL}/${name}"
    local tmp="/tmp/${name}"

    echo -e "\n${CYAN}→ Downloading ${name}...${NC}"
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$tmp"
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$tmp"
    else
        echo -e "${RED}✗ curl or wget required${NC}"; exit 1
    fi
    chmod +x "$tmp"
    echo -e "${GREEN}✓ Downloaded${NC}"
    echo -e "${CYAN}→ Running ${name}...${NC}\n"
    "$tmp"
    rm -f "$tmp"
}

case "$CHOICE" in
    1) install_binary "sysguard-installer" ;;
    2) install_binary "install-go-tools" ;;
    3) install_binary "sysguard-installer"; install_binary "install-go-tools" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo -e "\n${GREEN}${BOLD}✓ Done${NC}\n"
