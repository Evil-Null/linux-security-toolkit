#!/usr/bin/env bash
# ============================================================
#  SysGuard Installer v1.0
#  ერთიანი სისტემური ეკოსისტემის ინსტალერი
#  Debian/Ubuntu სისტემებისთვის
# ============================================================
set -euo pipefail

# --- ფერები ---
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' B='\033[1m' D='\033[2m' N='\033[0m'
BG_G='\033[42m' BG_R='\033[41m' BG_C='\033[46m'

# --- სტატუსის ტრეკერი ---
declare -a INSTALLED=()
declare -a FAILED=()
declare -a SKIPPED=()

# --- ფუნქციები ---
banner() {
    echo -e "\n${B}${C}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║                                                  ║"
    echo "║     🛡️  SysGuard Installer v1.0                  ║"
    echo "║     ერთიანი სისტემური ეკოსისტემა                ║"
    echo "║                                                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${N}\n"
}

phase_header() {
    local num="$1" name="$2"
    echo -e "\n${B}${BG_C} ფაზა ${num} ${N} ${B}${C}${name}${N}"
    echo -e "${C}$(printf '━%.0s' {1..50})${N}\n"
}

ok()   { echo -e "  ${G}✓${N} $1"; }
fail() { echo -e "  ${R}✗${N} $1"; }
warn() { echo -e "  ${Y}⚠${N} $1"; }
info() { echo -e "  ${C}→${N} $1"; }

track_ok()   { INSTALLED+=("$1"); ok "$1"; }
track_fail() { FAILED+=("$1"); fail "$1"; }

ask_continue() {
    local phase_name="$1"
    echo ""
    read -rp "$(echo -e "${B}${phase_name}${N} — გააგრძელოთ? [Y/n]: ")" yn
    case "$yn" in
        [Nn]*) SKIPPED+=("$phase_name"); return 1 ;;
        *) return 0 ;;
    esac
}

progress() {
    local current="$1" total="$2" label="$3"
    local pct=$((current * 100 / total))
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    printf "\r  ${D}[${G}%s${D}%s${N}${D}]${N} %3d%% %s" \
        "$(printf '█%.0s' $(seq 1 $filled 2>/dev/null) 2>/dev/null)" \
        "$(printf '░%.0s' $(seq 1 $empty 2>/dev/null) 2>/dev/null)" \
        "$pct" "$label"
}

install_apt() {
    local pkg="$1"
    if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
        ok "$pkg (უკვე დაყენებული)"
        INSTALLED+=("$pkg")
        return 0
    fi
    info "${pkg} ინსტალაცია..."
    if sudo apt install -y "$pkg" >/dev/null 2>&1; then
        track_ok "$pkg"
    else
        track_fail "$pkg"
    fi
}

install_github_deb() {
    local name="$1" url="$2"
    if command -v "$name" &>/dev/null; then
        ok "$name (უკვე დაყენებული)"
        INSTALLED+=("$name")
        return 0
    fi
    info "${name} ინსტალაცია GitHub-იდან..."
    local tmp="/tmp/${name}.deb"
    if wget -q "$url" -O "$tmp" 2>/dev/null && sudo dpkg -i "$tmp" >/dev/null 2>&1; then
        rm -f "$tmp"
        track_ok "$name"
    else
        rm -f "$tmp"
        track_fail "$name"
    fi
}

install_github_bin() {
    local name="$1" url="$2" dest="${3:-/usr/local/bin/$1}"
    if command -v "$name" &>/dev/null; then
        ok "$name (უკვე დაყენებული)"
        INSTALLED+=("$name")
        return 0
    fi
    info "${name} ინსტალაცია GitHub-იდან..."
    local tmp="/tmp/${name}_download"
    mkdir -p "$tmp"
    if wget -q "$url" -O "${tmp}/archive.tar.gz" 2>/dev/null; then
        tar -xzf "${tmp}/archive.tar.gz" -C "$tmp" 2>/dev/null
        local bin
        bin=$(find "$tmp" -name "$name" -type f | head -1)
        if [ -n "$bin" ]; then
            sudo cp "$bin" "$dest"
            sudo chmod 755 "$dest"
            rm -rf "$tmp"
            track_ok "$name"
            return 0
        fi
    fi
    rm -rf "$tmp"
    track_fail "$name"
}

write_script() {
    local path="$1"
    shift
    sudo tee "$path" > /dev/null << 'INNEREOF'
PLACEHOLDER
INNEREOF
    sudo chmod 755 "$path"
}

# ============================================================
#  ფაზა 1: Modern CLI Tools
# ============================================================
phase1_cli_tools() {
    phase_header "1/6" "თანამედროვე CLI Tools"

    local ARCH
    ARCH=$(dpkg --print-architecture)

    # --- APT packages ---
    info "APT პაკეტების ინსტალაცია..."
    sudo apt update -qq 2>/dev/null

    local apt_pkgs=(eza bat ripgrep fd-find fzf duf git-delta zoxide)
    local i=0
    for pkg in "${apt_pkgs[@]}"; do
        ((i++))
        install_apt "$pkg"
    done

    # --- dust (GitHub) ---
    if ! command -v dust &>/dev/null; then
        info "dust ინსტალაცია GitHub-იდან..."
        local DUST_VER
        DUST_VER=$(wget -qO- "https://api.github.com/repos/bootandy/dust/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/' || echo "1.1.1")
        install_github_deb "dust" "https://github.com/bootandy/dust/releases/download/v${DUST_VER}/du-dust_${DUST_VER}-1_${ARCH}.deb"
    else
        ok "dust (უკვე დაყენებული)"
        INSTALLED+=("dust")
    fi

    # --- procs (GitHub) ---
    if ! command -v procs &>/dev/null; then
        info "procs ინსტალაცია GitHub-იდან..."
        local PROCS_VER
        PROCS_VER=$(wget -qO- "https://api.github.com/repos/dalance/procs/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/' || echo "0.14.8")
        local tmp="/tmp/procs_dl"
        mkdir -p "$tmp"
        if wget -q "https://github.com/dalance/procs/releases/download/v${PROCS_VER}/procs-v${PROCS_VER}-x86_64-linux.zip" -O "${tmp}/procs.zip" 2>/dev/null; then
            cd "$tmp" && unzip -q procs.zip 2>/dev/null && cd ->/dev/null
            sudo cp "${tmp}/procs" /usr/local/bin/procs
            sudo chmod 755 /usr/local/bin/procs
            rm -rf "$tmp"
            track_ok "procs"
        else
            rm -rf "$tmp"
            track_fail "procs"
        fi
    else
        ok "procs (უკვე დაყენებული)"
        INSTALLED+=("procs")
    fi

    # --- lazygit (GitHub) ---
    if ! command -v lazygit &>/dev/null; then
        info "lazygit ინსტალაცია GitHub-იდან..."
        local LG_VER
        LG_VER=$(wget -qO- "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/' || echo "0.44.1")
        install_github_bin "lazygit" "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
    else
        ok "lazygit (უკვე დაყენებული)"
        INSTALLED+=("lazygit")
    fi

    # --- Starship ---
    if ! command -v starship &>/dev/null; then
        info "starship ინსტალაცია..."
        if wget -q "https://starship.rs/install.sh" -O /tmp/starship-install.sh 2>/dev/null; then
            sudo sh /tmp/starship-install.sh -y >/dev/null 2>&1 && track_ok "starship" || track_fail "starship"
            rm -f /tmp/starship-install.sh
        else
            track_fail "starship"
        fi
    else
        ok "starship (უკვე დაყენებული)"
        INSTALLED+=("starship")
    fi

    # --- Starship config ---
    if [ ! -f ~/.config/starship.toml ]; then
        mkdir -p ~/.config
        cat > ~/.config/starship.toml << 'TOML'
format = """
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$docker_context\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[character]
success_symbol = "[❯](green)"
error_symbol = "[❯](red)"

[python]
format = '[${symbol}${pyenv_prefix}(${version})]($style) '
symbol = " "

[nodejs]
format = "[$symbol($version)]($style) "
symbol = " "
TOML
        ok "starship.toml შეიქმნა"
    else
        ok "starship.toml (უკვე არსებობს)"
    fi

    # --- Bashrc aliases ---
    if ! grep -q "SysGuard CLI tools\|თანამედროვე CLI tools" ~/.bashrc 2>/dev/null; then
        cat >> ~/.bashrc << 'BASHRC'

# ============================================================
# SysGuard CLI tools
# ============================================================

# eza (ls ალტერნატივა)
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias l='eza --icons --group-directories-first'

# bat (cat ალტერნატივა)
alias cat='batcat --paging=never'
alias catp='batcat'

# ripgrep
alias rg='rg --smart-case'

# dust (du ალტერნატივა)
alias du='dust'

# duf (df ალტერნატივა)
alias df='duf'

# procs (ps ალტერნატივა)
alias pss='procs'

# Starship prompt
eval "$(starship init bash)"

# Zoxide (smart cd)
eval "$(zoxide init bash)"

# fzf
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
BASHRC
        ok "~/.bashrc aliases დაემატა"
    else
        ok "~/.bashrc aliases (უკვე არსებობს)"
    fi

    # --- Git delta ---
    if ! git config --global core.pager | grep -q delta 2>/dev/null; then
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.light true
        git config --global delta.line-numbers true
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
        ok "git-delta კონფიგურაცია"
    else
        ok "git-delta (უკვე კონფიგურირებული)"
    fi
}

# ============================================================
#  ფაზა 2: Security Hardening
# ============================================================
phase2_security() {
    phase_header "2/6" "უსაფრთხოების გამაგრება"

    install_apt "rkhunter"
    install_apt "lynis"
    install_apt "apparmor-profiles-extra"
    install_apt "auditd"
    install_apt "fail2ban"

    # --- rkhunter config ---
    if [ -f /etc/rkhunter.conf ]; then
        sudo sed -i 's|^WEB_CMD="/bin/false"|WEB_CMD=""|' /etc/rkhunter.conf 2>/dev/null || true
        sudo sed -i 's/^UPDATE_MIRRORS=0/UPDATE_MIRRORS=1/' /etc/rkhunter.conf 2>/dev/null || true
        sudo sed -i 's/^MIRRORS_MODE=1/MIRRORS_MODE=0/' /etc/rkhunter.conf 2>/dev/null || true
        ok "rkhunter.conf კონფიგურაცია"
    fi

    # --- rkhunter false positives ---
    if [ ! -f /etc/rkhunter.conf.local ]; then
        sudo tee /etc/rkhunter.conf.local > /dev/null << 'RKHCONF'
ALLOWHIDDENDIR=/etc/.java
ALLOWHIDDENFILE=/etc/.resolv.conf.systemd-resolved.bak
ALLOWHIDDENFILE=/etc/.updated
SCRIPTWHITELIST=/usr/bin/egrep
SCRIPTWHITELIST=/usr/bin/fgrep
SCRIPTWHITELIST=/usr/bin/which
SCRIPTWHITELIST=/usr/bin/lwp-request
PKGMGR=DPKG
ALLOW_SSH_ROOT_USER=unset
RKHCONF
        ok "rkhunter.conf.local შეიქმნა"
    else
        ok "rkhunter.conf.local (უკვე არსებობს)"
    fi

    # --- rkhunter timer ---
    if [ ! -f /etc/systemd/system/rkhunter.timer ]; then
        sudo tee /etc/systemd/system/rkhunter.service > /dev/null << 'EOF'
[Unit]
Description=rkhunter rootkit scan
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/rkhunter --check --skip-keypress --report-warnings-only
Nice=19
EOF
        sudo tee /etc/systemd/system/rkhunter.timer > /dev/null << 'EOF'
[Unit]
Description=Weekly rkhunter scan

[Timer]
OnCalendar=Sun *-*-* 04:00:00
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now rkhunter.timer 2>/dev/null
        ok "rkhunter.timer (კვირა 04:00)"
    else
        ok "rkhunter.timer (უკვე არსებობს)"
    fi

    # --- auditd rules ---
    if [ -f /etc/audit/rules.d/hardening.rules ]; then
        if ! grep -q "sudo_usage" /etc/audit/rules.d/hardening.rules 2>/dev/null; then
            # Add rules before -e 2 line
            sudo sed -i '/-e 2/i \
-w /etc/resolv.conf -p wa -k network\
-w /etc/ufw/ -p wa -k firewall\
-w /usr/bin/sudo -p x -k sudo_usage\
-w /usr/bin/su -p x -k su_usage\
-w /usr/bin/passwd -p x -k passwd_change\
-w /usr/sbin/useradd -p x -k user_mgmt\
-w /usr/sbin/userdel -p x -k user_mgmt\
-w /usr/sbin/usermod -p x -k user_mgmt' /etc/audit/rules.d/hardening.rules 2>/dev/null
            ok "auditd: 8 ახალი წესი დაემატა (რებუთის შემდეგ გააქტიურდება)"
        else
            ok "auditd წესები (უკვე არსებობს)"
        fi
    else
        warn "auditd hardening.rules ფაილი ვერ მოიძებნა"
    fi

    # --- fail2ban: disable sshd if SSH not running ---
    if ! systemctl is-active --quiet sshd 2>/dev/null && ! systemctl is-active --quiet ssh 2>/dev/null; then
        if [ -f /etc/fail2ban/jail.local ]; then
            if grep -q "enabled = true" /etc/fail2ban/jail.local 2>/dev/null; then
                sudo sed -i '/\[sshd\]/,/^\[/{s/enabled = true/enabled = false/}' /etc/fail2ban/jail.local 2>/dev/null || true
                sudo systemctl restart fail2ban 2>/dev/null || true
                ok "fail2ban: sshd jail გამორთულია (SSH არ მუშაობს)"
            fi
        fi
    else
        ok "fail2ban: SSH აქტიურია, sshd jail დარჩა"
    fi
}

# ============================================================
#  ფაზა 3: Network Tools
# ============================================================
phase3_network() {
    phase_header "3/6" "ქსელის ინსტრუმენტები"

    install_apt "nethogs"
    install_apt "iftop"
    install_apt "vnstat"

    # --- vnstat service ---
    sudo systemctl enable --now vnstat 2>/dev/null || true
    ok "vnstat სერვისი ჩართულია"

    # --- bandwhich (GitHub) ---
    if ! command -v bandwhich &>/dev/null; then
        info "bandwhich ინსტალაცია GitHub-იდან..."
        local BW_VER
        BW_VER=$(wget -qO- "https://api.github.com/repos/imsnif/bandwhich/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/' || echo "0.22.2")
        install_github_bin "bandwhich" "https://github.com/imsnif/bandwhich/releases/download/v${BW_VER}/bandwhich-v${BW_VER}-x86_64-unknown-linux-musl.tar.gz"
    else
        ok "bandwhich (უკვე დაყენებული)"
        INSTALLED+=("bandwhich")
    fi

    # --- dnscheck script ---
    if [ ! -f /usr/local/bin/dnscheck ]; then
        sudo tee /usr/local/bin/dnscheck > /dev/null << 'DNSSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

C='\033[0;36m' G='\033[0;32m' R='\033[0;31m'
Y='\033[1;33m' B='\033[1m' N='\033[0m'

echo -e "${B}${C}╔══════════════════════════════════╗${N}"
echo -e "${B}${C}║     DNS Security Check           ║${N}"
echo -e "${B}${C}╚══════════════════════════════════╝${N}"

echo -e "\n${B}DNS სერვერები:${N}"
resolvectl status 2>/dev/null | grep "DNS Servers" | head -3 || \
    cat /etc/resolv.conf | grep nameserver

echo -e "\n${B}DNScrypt-proxy:${N}"
if systemctl is-active --quiet dnscrypt-proxy 2>/dev/null; then
    echo -e "  ${G}✓${N} აქტიური"
    grep "server_names" /etc/dnscrypt-proxy/dnscrypt-proxy.toml 2>/dev/null | head -1
else
    echo -e "  ${R}✗${N} გამორთული"
fi

echo -e "\n${B}DNSSEC ვალიდაცია:${N}"
DNSSEC=$(dig +dnssec cloudflare.com A +short 2>/dev/null | wc -l)
if [ "$DNSSEC" -gt 1 ]; then
    echo -e "  ${G}✓${N} DNSSEC მუშაობს"
else
    echo -e "  ${Y}⚠${N} DNSSEC შესაძლოა არ მუშაობს"
fi

echo -e "\n${B}DNS სიჩქარე:${N}"
for domain in google.com github.com cloudflare.com; do
    TIME=$(dig "$domain" +noall +stats 2>/dev/null | grep "Query time" | awk '{print $4}')
    echo -e "  $domain: ${B}${TIME:-?}ms${N}"
done

echo -e "\n${B}DNS Leak ტესტი:${N}"
RESOLVER=$(dig +short whoami.cloudflare CH TXT @1.1.1.1 2>/dev/null | tr -d '"')
echo -e "  თქვენი DNS resolver IP: ${B}${RESOLVER:-unknown}${N}"
echo ""
DNSSCRIPT
        sudo chmod 755 /usr/local/bin/dnscheck
        track_ok "dnscheck"
    else
        ok "dnscheck (უკვე არსებობს)"
        INSTALLED+=("dnscheck")
    fi
}

# ============================================================
#  ფაზა 4: Monitoring
# ============================================================
phase4_monitoring() {
    phase_header "4/6" "მონიტორინგი"

    # --- logwatch ---
    install_apt "logwatch"

    if [ ! -f /etc/logwatch/conf/logwatch.conf ]; then
        sudo mkdir -p /etc/logwatch/conf /var/log/logwatch
        sudo tee /etc/logwatch/conf/logwatch.conf > /dev/null << 'EOF'
Output = file
Filename = /var/log/logwatch/daily-report.log
Format = text
Range = yesterday
Detail = Med
Service = All
Service = "-zz-network"
MailTo = root
MailFrom = Logwatch
EOF
        ok "logwatch.conf შეიქმნა"
    else
        ok "logwatch.conf (უკვე არსებობს)"
    fi

    # --- logwatch timer ---
    if [ ! -f /etc/systemd/system/logwatch.timer ]; then
        sudo tee /etc/systemd/system/logwatch.service > /dev/null << 'EOF'
[Unit]
Description=Logwatch daily report
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/logwatch
Nice=19
EOF
        sudo tee /etc/systemd/system/logwatch.timer > /dev/null << 'EOF'
[Unit]
Description=Daily logwatch report

[Timer]
OnCalendar=*-*-* 06:30:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now logwatch.timer 2>/dev/null
        ok "logwatch.timer (ყოველდღე 06:30)"
    else
        ok "logwatch.timer (უკვე არსებობს)"
    fi

    # --- sysstat ---
    install_apt "sysstat"

    if [ -f /etc/default/sysstat ]; then
        sudo sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat 2>/dev/null || true
        ok "sysstat ჩართულია"
    fi

    if [ -f /etc/sysstat/sysstat ]; then
        sudo sed -i 's/HISTORY=7/HISTORY=28/' /etc/sysstat/sysstat 2>/dev/null || true
        ok "sysstat HISTORY=28"
    fi

    sudo systemctl restart sysstat 2>/dev/null || true
}

# ============================================================
#  ფაზა 5: Automation Scripts
# ============================================================
phase5_automation() {
    phase_header "5/6" "ავტომატიზაციის სკრიპტები"

    # --- syshealth ---
    if [ ! -f /usr/local/bin/syshealth ]; then
        sudo tee /usr/local/bin/syshealth > /dev/null << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' B='\033[1m' D='\033[2m' N='\033[0m'

header() { echo -e "\n${B}${C}━━━ $1 ━━━${N}"; }
ok()     { echo -e "  ${G}✓${N} $1"; }
warn()   { echo -e "  ${Y}⚠${N} $1"; }
crit()   { echo -e "  ${R}✗${N} $1"; }

echo -e "${B}${C}"
echo "╔══════════════════════════════════════════╗"
echo "║         SysHealth Dashboard              ║"
echo "║         $(date '+%Y-%m-%d %H:%M:%S')            ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${N}"

header "სისტემა"
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
echo -e "  Uptime: ${B}$UPTIME${N}"
echo -e "  Load:   ${B}$LOAD${N} ($(nproc) cores)"

header "CPU"
CPU_USAGE=$(LC_NUMERIC=C top -bn1 | grep 'Cpu(s)' | awk '{printf "%d", $2}')
if [ "$CPU_USAGE" -lt 60 ]; then ok "CPU: ${CPU_USAGE}%"
elif [ "$CPU_USAGE" -lt 85 ]; then warn "CPU: ${CPU_USAGE}%"
else crit "CPU: ${CPU_USAGE}%"; fi

header "მეხსიერება"
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
if [ "$MEM_PCT" -lt 70 ]; then ok "RAM: ${MEM_USED}/${MEM_TOTAL}MB (${MEM_PCT}%)"
elif [ "$MEM_PCT" -lt 90 ]; then warn "RAM: ${MEM_USED}/${MEM_TOTAL}MB (${MEM_PCT}%)"
else crit "RAM: ${MEM_USED}/${MEM_TOTAL}MB (${MEM_PCT}%)"; fi

SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
if [ "$SWAP_USED" -gt 500 ]; then warn "Swap: ${SWAP_USED}MB used"
else ok "Swap: ${SWAP_USED}MB used"; fi

header "დისკი"
DISK_PCT=$(df / | awk 'NR==2 {gsub(/%/,""); print $5}')
DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
if [ "$DISK_PCT" -lt 70 ]; then ok "Root: ${DISK_PCT}% used (${DISK_AVAIL} free)"
elif [ "$DISK_PCT" -lt 90 ]; then warn "Root: ${DISK_PCT}% used (${DISK_AVAIL} free)"
else crit "Root: ${DISK_PCT}% used (${DISK_AVAIL} free)"; fi

header "უსაფრთხოება"
if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    ok "UFW: აქტიური"
else
    crit "UFW: გამორთული!"
fi

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    JAILS=$(sudo fail2ban-client status 2>/dev/null | grep "Number of jail" | awk -F: '{print $2}' | tr -d ' ')
    ok "fail2ban: აქტიური (${JAILS:-0} jails)"
else
    warn "fail2ban: გამორთული"
fi

if systemctl is-active --quiet clamav-daemon 2>/dev/null; then
    ok "ClamAV: აქტიური"
else
    warn "ClamAV: გამორთული"
fi

AA_ENFORCED=$(sudo aa-status 2>/dev/null | grep "profiles are in enforce" | awk '{print $1}')
if [ -n "$AA_ENFORCED" ] && [ "$AA_ENFORCED" -gt 0 ]; then
    ok "AppArmor: ${AA_ENFORCED} profiles enforced"
else
    warn "AppArmor: არ არის აქტიური"
fi

header "ქსელი"
OPEN_PORTS=$(ss -tlnp 2>/dev/null | grep -v '127.0.0' | grep -v '::1' | grep -c LISTEN || echo 0)
if [ "$OPEN_PORTS" -gt 5 ]; then warn "ღია პორტები (არა-localhost): $OPEN_PORTS"
else ok "ღია პორტები (არა-localhost): $OPEN_PORTS"; fi

if dig +short +time=2 google.com >/dev/null 2>&1; then
    ok "DNS: მუშაობს"
else
    crit "DNS: პრობლემა!"
fi

header "განახლებები"
if command -v /usr/lib/update-notifier/apt-check &>/dev/null; then
    UPDATES=$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d';' -f1)
    SEC_UPDATES=$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d';' -f2)
    if [ "$SEC_UPDATES" -gt 0 ]; then crit "უსაფრთხოების განახლებები: $SEC_UPDATES"
    elif [ "$UPDATES" -gt 0 ]; then warn "ხელმისაწვდომი განახლებები: $UPDATES"
    else ok "სისტემა განახლებულია"; fi
else
    ok "apt-check არ არის (manual check: sudo apt update)"
fi

if command -v docker &>/dev/null; then
    header "Docker"
    CONTAINERS=$(docker ps -q 2>/dev/null | wc -l || echo 0)
    IMAGES=$(docker images -q 2>/dev/null | wc -l || echo 0)
    echo -e "  Containers running: ${B}$CONTAINERS${N}, Images: ${B}$IMAGES${N}"
fi

echo -e "\n${D}─── Generated by SysHealth $(date '+%H:%M:%S') ───${N}\n"
SCRIPT
        sudo chmod 755 /usr/local/bin/syshealth
        track_ok "syshealth"
    else
        ok "syshealth (უკვე არსებობს)"
        INSTALLED+=("syshealth")
    fi

    # --- sysclean ---
    if [ ! -f /usr/local/bin/sysclean ]; then
        sudo tee /usr/local/bin/sysclean > /dev/null << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' B='\033[1m' N='\033[0m'

echo -e "${B}🧹 SysClean — სისტემის გაწმენდა${N}\n"

echo -e "${B}APT cache:${N}"
BEFORE=$(du -sm /var/cache/apt/archives/ 2>/dev/null | awk '{print $1}')
sudo apt-get clean -y 2>/dev/null
sudo apt-get autoremove -y 2>/dev/null
AFTER=$(du -sm /var/cache/apt/archives/ 2>/dev/null | awk '{print $1}')
DIFF=$((BEFORE - AFTER))
echo -e "  ${G}✓${N} გათავისუფლდა: ${DIFF}MB"

echo -e "${B}Systemd Journal:${N}"
JBEFORE=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[MG]' | head -1 || echo "?")
sudo journalctl --vacuum-time=3d --vacuum-size=100M 2>/dev/null || true
JAFTER=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[MG]' | head -1 || echo "?")
echo -e "  ${G}✓${N} Journal: ${JBEFORE} → ${JAFTER}"

echo -e "${B}Temp ფაილები:${N}"
TBEFORE=$(du -sm /tmp/ 2>/dev/null | awk '{print $1}')
find /tmp -type f -atime +7 -delete 2>/dev/null || true
TAFTER=$(du -sm /tmp/ 2>/dev/null | awk '{print $1}')
echo -e "  ${G}✓${N} /tmp: $((TBEFORE - TAFTER))MB გათავისუფლდა"

echo -e "${B}User cache:${N}"
USER_HOME="${HOME:-/home/$(logname 2>/dev/null || echo $SUDO_USER)}"
CBEFORE=$(du -sm "${USER_HOME}/.cache/" 2>/dev/null | awk '{print $1}' || echo 0)
find "${USER_HOME}/.cache/" -type f -atime +30 -delete 2>/dev/null || true
CAFTER=$(du -sm "${USER_HOME}/.cache/" 2>/dev/null | awk '{print $1}' || echo 0)
echo -e "  ${G}✓${N} ~/.cache: $((CBEFORE - CAFTER))MB გათავისუფლდა"

echo -e "${B}Trash:${N}"
TRASH_SIZE=$(du -sm "${USER_HOME}/.local/share/Trash/" 2>/dev/null | awk '{print $1}' || echo 0)
if [ "$TRASH_SIZE" -gt 100 ]; then
    echo -e "  ${Y}⚠${N} Trash: ${TRASH_SIZE}MB — გასაწმენდია: rm -rf ~/.local/share/Trash/*"
else
    echo -e "  ${G}✓${N} Trash: ${TRASH_SIZE}MB"
fi

if command -v docker &>/dev/null; then
    echo -e "${B}Docker:${N}"
    DANGLING=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    if [ "$DANGLING" -gt 0 ]; then
        docker image prune -f 2>/dev/null || true
        echo -e "  ${G}✓${N} წაშლილია $DANGLING dangling image"
    else
        echo -e "  ${G}✓${N} სუფთაა"
    fi
fi

if command -v snap &>/dev/null; then
    echo -e "${B}Snap:${N}"
    SNAP_OLD=$(snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | wc -l)
    if [ "$SNAP_OLD" -gt 0 ]; then
        snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read snapname revision; do
            sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
        done
        echo -e "  ${G}✓${N} წაშლილია $SNAP_OLD ძველი snap revision"
    else
        echo -e "  ${G}✓${N} სუფთაა"
    fi
fi

echo -e "\n${B}${G}გაწმენდა დასრულდა!${N}\n"
SCRIPT
        sudo chmod 755 /usr/local/bin/sysclean
        track_ok "sysclean"
    else
        ok "sysclean (უკვე არსებობს)"
        INSTALLED+=("sysclean")
    fi

    # --- secaudit ---
    if [ ! -f /usr/local/bin/secaudit ]; then
        sudo tee /usr/local/bin/secaudit > /dev/null << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/secaudit-$(date +%Y%m%d).log"

{
echo "============================================================"
echo "SecAudit Report — $(date)"
echo "============================================================"

echo -e "\n=== 1. Firewall Status ==="
sudo ufw status verbose 2>/dev/null || echo "UFW not available"

echo -e "\n=== 2. fail2ban ==="
sudo fail2ban-client status 2>/dev/null || echo "fail2ban not running"

echo -e "\n=== 3. Last Failed Logins ==="
sudo lastb 2>/dev/null | head -10 || echo "None"

echo -e "\n=== 4. New SUID Files (last 7 days) ==="
sudo find /usr /bin /sbin -perm -4000 -mtime -7 -type f 2>/dev/null | head -20 || echo "None"

echo -e "\n=== 5. Listening Ports (non-localhost) ==="
ss -tlnp | grep -v '127.0.0' | grep -v '::1' || echo "None"

echo -e "\n=== 6. Recent sudo Actions ==="
sudo journalctl _COMM=sudo --since "1 week ago" --no-pager 2>/dev/null | tail -15

echo -e "\n=== 7. AppArmor ==="
sudo aa-status 2>/dev/null | head -10

echo -e "\n=== 8. Lynis Score ==="
LYNIS_LOG="/var/log/lynis.log"
if [ -f "$LYNIS_LOG" ]; then
    grep "Hardening index" "$LYNIS_LOG" | tail -1
else
    echo "Lynis log not found"
fi

echo -e "\n=== 9. AIDE Integrity ==="
sudo journalctl -u dailyaidecheck --since "1 week ago" --no-pager 2>/dev/null | tail -5

echo -e "\n============================================================"
echo "SecAudit Complete — $(date)"
echo "============================================================"
} | sudo tee "$LOG"

echo ""
echo "რეპორტი შენახულია: $LOG"
SCRIPT
        sudo chmod 755 /usr/local/bin/secaudit
        track_ok "secaudit"
    else
        ok "secaudit (უკვე არსებობს)"
        INSTALLED+=("secaudit")
    fi

    # --- secaudit timer ---
    if [ ! -f /etc/systemd/system/secaudit.timer ]; then
        sudo tee /etc/systemd/system/secaudit.service > /dev/null << 'EOF'
[Unit]
Description=Weekly security audit

[Service]
Type=oneshot
ExecStart=/usr/local/bin/secaudit
EOF
        sudo tee /etc/systemd/system/secaudit.timer > /dev/null << 'EOF'
[Unit]
Description=Weekly security audit

[Timer]
OnCalendar=Mon *-*-* 05:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now secaudit.timer 2>/dev/null
        ok "secaudit.timer (ორშაბათი 05:00)"
    else
        ok "secaudit.timer (უკვე არსებობს)"
    fi

    # --- sysclean timer ---
    if [ ! -f /etc/systemd/system/sysclean.timer ]; then
        sudo tee /etc/systemd/system/sysclean.service > /dev/null << 'EOF'
[Unit]
Description=Monthly system cleanup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sysclean
EOF
        sudo tee /etc/systemd/system/sysclean.timer > /dev/null << 'EOF'
[Unit]
Description=Monthly system cleanup

[Timer]
OnCalendar=*-*-01 04:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now sysclean.timer 2>/dev/null
        ok "sysclean.timer (თვის 1 რიცხვი 04:00)"
    else
        ok "sysclean.timer (უკვე არსებობს)"
    fi
}

# ============================================================
#  ფაზა 6: SysGuard Ecosystem
# ============================================================
phase6_ecosystem() {
    phase_header "6/6" "SysGuard ეკოსისტემა"

    # --- sysguard ---
    if [ ! -f /usr/local/bin/sysguard ]; then
        sudo tee /usr/local/bin/sysguard > /dev/null << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
C='\033[0;36m' G='\033[0;32m' R='\033[0;31m'
Y='\033[1;33m' B='\033[1m' D='\033[2m' N='\033[0m'

show_help() {
    echo -e "${B}${C}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║     🛡️  SysGuard v${VERSION}                     ║"
    echo "║     ერთიანი სისტემური ეკოსისტემა            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${N}"
    echo -e "${B}გამოყენება:${N} sysguard <ბრძანება>"
    echo ""
    echo -e "  ${G}status${N}    — სისტემის ჯანმრთელობის დეშბორდი"
    echo -e "  ${G}security${N}  — უსაფრთხოების აუდიტი"
    echo -e "  ${G}clean${N}     — სისტემის გაწმენდა"
    echo -e "  ${G}dns${N}       — DNS უსაფრთხოების ტესტი"
    echo -e "  ${G}ports${N}     — ღია პორტების სკანირება"
    echo -e "  ${G}traffic${N}   — ცოცხალი ტრაფიკის მონიტორი"
    echo -e "  ${G}updates${N}   — განახლებების შემოწმება"
    echo -e "  ${G}logs${N}      — ბოლო ლოგების მიმოხილვა"
    echo -e "  ${G}lynis${N}     — Lynis უსაფრთხოების სკანი"
    echo -e "  ${G}full${N}      — სრული სისტემის აუდიტი (ყველაფერი ერთად)"
    echo ""
}

cmd_ports() {
    echo -e "\n${B}${C}━━━ ღია პორტები ━━━${N}\n"
    echo -e "${B}არა-localhost:${N}"
    ss -tlnp 2>/dev/null | grep -v '127.0.0' | grep -v '::1' | grep LISTEN || echo "  არცერთი"
    echo ""
    echo -e "${B}ყველა listening:${N}"
    ss -tlnp 2>/dev/null | grep LISTEN
}

cmd_traffic() {
    echo -e "\n${B}${C}━━━ ტრაფიკის მონიტორი ━━━${N}\n"
    echo "  1) nethogs  — ტრაფიკი პროცესებით"
    echo "  2) iftop    — ტრაფიკი კავშირებით"
    echo "  3) vnstat   — ტრაფიკის ისტორია"
    echo ""
    read -rp "არჩევანი [1-3]: " choice
    case "$choice" in
        1) sudo nethogs ;;
        2) sudo iftop ;;
        3) vnstat ;;
        *) echo "არასწორი არჩევანი" ;;
    esac
}

cmd_updates() {
    echo -e "\n${B}${C}━━━ განახლებები ━━━${N}\n"
    echo -e "${D}შემოწმება...${N}"
    sudo apt update -qq 2>/dev/null
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
    if [ "$UPGRADABLE" -gt 0 ]; then
        echo -e "${Y}⚠ ${UPGRADABLE} განახლება ხელმისაწვდომია:${N}"
        apt list --upgradable 2>/dev/null | grep upgradable
        echo ""
        read -rp "დააყენოთ? [y/N]: " yn
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            sudo apt upgrade -y
        fi
    else
        echo -e "${G}✓ სისტემა განახლებულია${N}"
    fi
}

cmd_logs() {
    echo -e "\n${B}${C}━━━ ბოლო ლოგები ━━━${N}\n"
    echo -e "${B}--- გაფრთხილებები (ბოლო 20) ---${N}"
    sudo journalctl --no-pager -n 20 --priority=warning 2>/dev/null
    echo ""
    echo -e "${B}--- sudo ისტორია (ბოლო 10) ---${N}"
    sudo journalctl _COMM=sudo --no-pager -n 10 2>/dev/null
}

cmd_full() {
    echo -e "${B}${C}╔══════════════════════════════════════════════╗${N}"
    echo -e "${B}${C}║     სრული სისტემის აუდიტი                   ║${N}"
    echo -e "${B}${C}╚══════════════════════════════════════════════╝${N}"
    echo ""
    syshealth
    echo -e "\n${D}────────────────────────────────────────${N}\n"
    dnscheck
    echo -e "\n${D}────────────────────────────────────────${N}\n"
    cmd_ports
    echo -e "\n${D}────────────────────────────────────────${N}\n"
    cmd_updates
}

case "${1:-help}" in
    status)    syshealth ;;
    security)  sudo secaudit ;;
    clean)     sudo sysclean ;;
    dns)       dnscheck ;;
    ports)     cmd_ports ;;
    traffic)   cmd_traffic ;;
    updates)   cmd_updates ;;
    logs)      cmd_logs ;;
    lynis)     sudo lynis audit system --quick ;;
    full)      cmd_full ;;
    help|*)    show_help ;;
esac
SCRIPT
        sudo chmod 755 /usr/local/bin/sysguard
        track_ok "sysguard"
    else
        ok "sysguard (უკვე არსებობს)"
        INSTALLED+=("sysguard")
    fi

    # --- sysnotify ---
    if [ ! -f /usr/local/bin/sysnotify ]; then
        sudo tee /usr/local/bin/sysnotify > /dev/null << 'SCRIPT'
#!/usr/bin/env bash
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
REAL_UID=$(id -u "$REAL_USER")
DISPLAY="${DISPLAY:-:0}"
DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${REAL_UID}/bus}"
export DISPLAY DBUS_SESSION_BUS_ADDRESS

notify() {
    local urgency="$1" title="$2" body="$3"
    sudo -u "$REAL_USER" \
        DISPLAY="$DISPLAY" \
        DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        notify-send --urgency="$urgency" --icon=dialog-warning "$title" "$body" 2>/dev/null || true
}

ALERTS=0

DISK_PCT=$(df / | awk 'NR==2 {gsub(/%/,""); print $5}')
if [ "$DISK_PCT" -gt 90 ]; then
    notify critical "დისკი თითქმის სავსეა!" "Root: ${DISK_PCT}% — გაწმინდეთ: sysguard clean"
    ((ALERTS++))
elif [ "$DISK_PCT" -gt 80 ]; then
    notify normal "დისკის გაფრთხილება" "Root: ${DISK_PCT}% გამოყენებული"
    ((ALERTS++))
fi

if command -v /usr/lib/update-notifier/apt-check &>/dev/null; then
    SEC=$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d';' -f2)
    if [ "$SEC" -gt 0 ]; then
        notify critical "უსაფრთხოების განახლებები!" "${SEC} კრიტიკული განახლება ელოდება"
        ((ALERTS++))
    fi
fi

if ! sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    notify critical "ფაირვოლი გამორთულია!" "UFW არ არის აქტიური"
    ((ALERTS++))
fi

MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
if [ "$MEM_PCT" -gt 90 ]; then
    notify critical "მეხსიერება!" "RAM: ${MEM_PCT}% გამოყენებული (${MEM_USED}/${MEM_TOTAL}MB)"
    ((ALERTS++))
fi

if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
    notify normal "fail2ban გამორთულია" "fail2ban სერვისი არ მუშაობს"
    ((ALERTS++))
fi

if [ "$ALERTS" -eq 0 ]; then
    logger -t sysnotify "შემოწმება დასრულდა — პრობლემა არ აღმოჩენილა"
else
    logger -t sysnotify "შემოწმება დასრულდა — ${ALERTS} გაფრთხილება"
fi
SCRIPT
        sudo chmod 755 /usr/local/bin/sysnotify
        track_ok "sysnotify"
    else
        ok "sysnotify (უკვე არსებობს)"
        INSTALLED+=("sysnotify")
    fi

    # --- sysnotify timer ---
    if [ ! -f /etc/systemd/system/sysnotify.timer ]; then
        sudo tee /etc/systemd/system/sysnotify.service > /dev/null << 'EOF'
[Unit]
Description=SysNotify — system notification check

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sysnotify
EOF
        sudo tee /etc/systemd/system/sysnotify.timer > /dev/null << 'EOF'
[Unit]
Description=SysNotify — check every 30 min

[Timer]
OnBootSec=5min
OnUnitActiveSec=30min

[Install]
WantedBy=timers.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now sysnotify.timer 2>/dev/null
        ok "sysnotify.timer (ყოველ 30 წუთში)"
    else
        ok "sysnotify.timer (უკვე არსებობს)"
    fi
}

# ============================================================
#  შეჯამება
# ============================================================
show_summary() {
    echo -e "\n\n${B}${C}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║             ინსტალაციის შეჯამება                ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${N}\n"

    if [ ${#INSTALLED[@]} -gt 0 ]; then
        echo -e "${B}${G}დაინსტალირდა (${#INSTALLED[@]}):${N}"
        for item in "${INSTALLED[@]}"; do
            echo -e "  ${G}✓${N} $item"
        done
    fi

    if [ ${#FAILED[@]} -gt 0 ]; then
        echo -e "\n${B}${R}ვერ დაინსტალირდა (${#FAILED[@]}):${N}"
        for item in "${FAILED[@]}"; do
            echo -e "  ${R}✗${N} $item"
        done
    fi

    if [ ${#SKIPPED[@]} -gt 0 ]; then
        echo -e "\n${B}${Y}გამოტოვებული (${#SKIPPED[@]}):${N}"
        for item in "${SKIPPED[@]}"; do
            echo -e "  ${Y}⚠${N} $item"
        done
    fi

    echo -e "\n${B}${C}━━━ რა გამოიყენოთ ━━━${N}\n"
    echo -e "  ${G}sysguard${N}          — მთავარი ბრძანება (help მენიუ)"
    echo -e "  ${G}sysguard status${N}   — სისტემის სტატუსი"
    echo -e "  ${G}sysguard full${N}     — სრული აუდიტი"
    echo -e "  ${G}sudo sysclean${N}     — სისტემის გაწმენდა"
    echo ""
    echo -e "  ${D}ახალი alias-ების გასააქტიურებლად: source ~/.bashrc${N}"
    echo -e "\n${D}─── SysGuard Installer ───${N}\n"
}

# ============================================================
#  Main
# ============================================================
banner

echo -e "${D}სისტემა: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)${N}"
echo -e "${D}Kernel:  $(uname -r)${N}"
echo -e "${D}Arch:    $(dpkg --print-architecture)${N}\n"

echo -e "${Y}ინსტალერი მოითხოვს sudo წვდომას.${N}"
sudo -v || { echo "sudo წვდომა საჭიროა!"; exit 1; }

if ask_continue "ფაზა 1: Modern CLI Tools"; then
    phase1_cli_tools
fi

if ask_continue "ფაზა 2: უსაფრთხოების გამაგრება"; then
    phase2_security
fi

if ask_continue "ფაზა 3: ქსელის ინსტრუმენტები"; then
    phase3_network
fi

if ask_continue "ფაზა 4: მონიტორინგი"; then
    phase4_monitoring
fi

if ask_continue "ფაზა 5: ავტომატიზაციის სკრიპტები"; then
    phase5_automation
fi

if ask_continue "ფაზა 6: SysGuard ეკოსისტემა"; then
    phase6_ecosystem
fi

show_summary
