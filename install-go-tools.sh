#!/usr/bin/env bash
# ============================================================
#  Go Security Tools Installer
#  ProjectDiscovery + offensive recon toolkit
#  Debian/Ubuntu-based systems
# ============================================================
set -euo pipefail

G='\033[0;32m' C='\033[0;36m' Y='\033[1;33m' N='\033[0m' B='\033[1m'

ok()   { echo -e "  ${G}✓${N} $1"; }
info() { echo -e "  ${C}→${N} $1"; }
warn() { echo -e "  ${Y}⚠${N} $1"; }

echo -e "\n${B}${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${B}${C}   🔧  Go Security Tools Installer${N}"
echo -e "${B}${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"

# ── 1. Check Go ──────────────────────────────────────────────
if ! command -v go &>/dev/null; then
    warn "Go not found. Installing latest Go..."

    GO_VERSION="1.22.5"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"

    wget -q --show-progress "https://go.dev/dl/${GO_TAR}" -O /tmp/${GO_TAR}
    mkdir -p ~/.local
    tar -C ~/.local -xzf /tmp/${GO_TAR}
    rm /tmp/${GO_TAR}

    export PATH="$PATH:$HOME/.local/go/bin:$HOME/go/bin"

    if ! grep -q 'go/bin' ~/.bashrc; then
        echo '' >> ~/.bashrc
        echo '# Go' >> ~/.bashrc
        echo 'export PATH=$PATH:~/.local/go/bin:~/go/bin' >> ~/.bashrc
    fi

    ok "Go ${GO_VERSION} installed → ~/.local/go/"
else
    ok "Go already installed: $(go version)"
fi

export PATH="$PATH:$HOME/.local/go/bin:$HOME/go/bin"

# ── 2. Install Tools ─────────────────────────────────────────
TOOLS=(
    "nuclei|github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "httpx|github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "katana|github.com/projectdiscovery/katana/cmd/katana@latest"
    "subfinder|github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "naabu|github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "dnsx|github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "amass|github.com/owasp-amass/amass/v4/...@master"
    "dalfox|github.com/hahwul/dalfox/v2@latest"
    "hakrawler|github.com/hakluke/hakrawler@latest"
    "subzy|github.com/LukaSikic/subzy@latest"
    "gau|github.com/lc/gau/v2/cmd/gau@latest"
    "ffuf|github.com/ffuf/ffuf/v2@latest"
    "unfurl|github.com/tomnomnom/unfurl@latest"
    "assetfinder|github.com/tomnomnom/assetfinder@latest"
)

echo -e "\n${B}Installing ${#TOOLS[@]} tools into ~/go/bin/ ...${N}\n"

FAILED=()
for entry in "${TOOLS[@]}"; do
    name="${entry%%|*}"
    pkg="${entry##*|}"
    info "Installing ${name}..."
    if go install "${pkg}" 2>/dev/null; then
        ok "${name}"
    else
        FAILED+=("$name")
        echo -e "  \033[0;31m✗\033[0m ${name} — failed"
    fi
done

# ── 3. Summary ───────────────────────────────────────────────
echo -e "\n${B}${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"

TOTAL=$((${#TOOLS[@]} - ${#FAILED[@]}))
echo -e "  ${G}✓ ${TOTAL}/${#TOOLS[@]} tools installed${N}"

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "  \033[0;31m✗ Failed: ${FAILED[*]}\033[0m"
fi

echo -e "\n  Tools location: ${B}~/go/bin/${N}"
echo -e "  Run: ${C}ls ~/go/bin/${N}"

if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo -e "\n  ${Y}⚠  Reload shell: source ~/.bashrc${N}"
fi

echo ""
