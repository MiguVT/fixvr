#!/usr/bin/env bash
# fixvr: Valve Index blank EDID fix installer
# https://github.com/miguvt/fixvr
set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
RULE_FILE="99-valve-index-reboot.rules"
RULE_DST="/etc/udev/rules.d/$RULE_FILE"
RULE_RAW_URL="https://raw.githubusercontent.com/MiguVT/fixvr/main/src/$RULE_FILE"
AUR_PKG="fixvr"

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✔]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
step()  { echo -e "${CYAN}[→]${NC} $*"; }
die()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
SUDO=""
setup_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    elif command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        die "This script must be run as root or sudo must be available."
    fi
}

# Locate the rule file relative to this script (works when called from anywhere)
# Falls back to downloading from GitHub when run via curl | bash
find_rule_file() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local candidates=(
        "$script_dir/$RULE_FILE"               # running from src/
        "$script_dir/../src/$RULE_FILE"        # running from repo root
        "$(pwd)/src/$RULE_FILE"                # cwd is repo root
        "$(pwd)/$RULE_FILE"                    # cwd is src/
    )

    for f in "${candidates[@]}"; do
        if [[ -f "$f" ]]; then
            echo "$f"
            return 0
        fi
    done

    # Not found locally (e.g. run via curl | bash) — download from GitHub
    warn "Rule file not found locally, downloading from GitHub…"
    local tmp_rule
    tmp_rule="$(mktemp "/tmp/${RULE_FILE}.XXXXXX")"

    if command -v curl &>/dev/null; then
        curl -fsSL "$RULE_RAW_URL" -o "$tmp_rule" || die "Failed to download rule file from GitHub."
    elif command -v wget &>/dev/null; then
        wget -qO "$tmp_rule" "$RULE_RAW_URL" || die "Failed to download rule file from GitHub."
    else
        die "Rule file not found locally and neither curl nor wget is available."
    fi

    echo "$tmp_rule"
}

# ---------------------------------------------------------------------------
# Distro detection
# ---------------------------------------------------------------------------
DISTRO_ID=""
DISTRO_ID_LIKE=""

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_ID_LIKE=""
    fi
}

is_arch_based() {
    [[ "$DISTRO_ID" == "arch"         ]] ||
    [[ "$DISTRO_ID" == "manjaro"      ]] ||
    [[ "$DISTRO_ID" == "endeavouros"  ]] ||
    [[ "$DISTRO_ID" == "garuda"       ]] ||
    [[ "$DISTRO_ID" == "cachyos"      ]] ||
    [[ "$DISTRO_ID" == "artix"        ]] ||
    echo "$DISTRO_ID_LIKE" | grep -qw "arch"
}

# ---------------------------------------------------------------------------
# AUR install (Arch-based)
# ---------------------------------------------------------------------------
install_paru() {
    step "Installing paru (AUR helper)…"
    if ! command -v git &>/dev/null; then
        sudo pacman -S --needed --noconfirm git
    fi
    sudo pacman -S --needed --noconfirm base-devel

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru"
    (cd "$tmp_dir/paru" && makepkg -si --noconfirm)

    info "paru installed successfully."
}

install_aur() {
    step "Arch-based distro detected: installing via AUR…"

    local aur_helper=""

    if command -v paru &>/dev/null; then
        aur_helper="paru"
    elif command -v yay &>/dev/null; then
        aur_helper="yay"
    else
        warn "Neither paru nor yay is installed."
        echo
        echo -e "  ${BOLD}paru${NC} is the recommended AUR helper for this project."
        echo
        read -rp "  Install paru automatically now? [y/N] " yn </dev/tty
        echo
        case "$yn" in
            [Yy]*)
                install_paru
                aur_helper="paru"
                ;;
            *)
                echo "  To install paru manually, run:"
                echo
                echo "    sudo pacman -S --needed base-devel git"
                echo "    git clone https://aur.archlinux.org/paru.git /tmp/paru"
                echo "    cd /tmp/paru && makepkg -si"
                echo
                die "Please install paru or yay and re-run this script."
                ;;
        esac
    fi

    info "Using AUR helper: $aur_helper"
    step "Installing $AUR_PKG…"
    "$aur_helper" -S "$AUR_PKG"

    info "Done! The udev rule was installed via the AUR package."
}

# ---------------------------------------------------------------------------
# Manual install (all other distros)
# ---------------------------------------------------------------------------
install_manual() {
    setup_sudo

    local rule_src
    rule_src="$(find_rule_file)"
    step "Rule file found: $rule_src"

    step "Installing udev rule to $RULE_DST…"
    $SUDO install -m 644 -o root -g root "$rule_src" "$RULE_DST"

    step "Reloading udev rules…"
    $SUDO udevadm control --reload-rules
    $SUDO udevadm trigger --subsystem-match=usb --subsystem-match=hidraw

    info "Done! Reconnect your Valve Index to apply the fix."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo
echo -e "${BOLD}fixvr: Valve Index blank EDID fix installer${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

detect_distro
step "Detected distro: ${BOLD}$DISTRO_ID${NC}${DISTRO_ID_LIKE:+ (like: $DISTRO_ID_LIKE)}"
echo

if is_arch_based; then
    install_aur
else
    install_manual
fi

echo
echo -e "${GREEN}${BOLD}All done.${NC} Your Valve Index blank EDID bug should now be fixed."
echo
