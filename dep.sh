#!/usr/bin/env bash
# =============================================================================
# dep.sh — Dependency checker & installer
# Supports: Ubuntu/Debian (apt), Fedora/RHEL (dnf), Arch Linux (pacman)
# =============================================================================

set -euo pipefail

# ── Colour codes ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
err()     { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { err "$*"; exit 1; }
section() { echo -e "\n${BOLD}$*${RESET}"; }

# ── Dependency table ──────────────────────────────────────────────────────────
# Format: "binary|apt_pkg|dnf_pkg|pacman_pkg|display_name|url"
DEPS=(
    "bash|bash|bash|bash|Bash|https://www.gnu.org/software/bash/"
    "gcc|gcc|gcc|gcc|GCC|https://gcc.gnu.org/"
    "make|make|make|make|Make|https://www.gnu.org/software/make/"
    "numactl|numactl|numactl|numactl|numactl|https://github.com/numactl/numactl"
    "bc|bc|bc|bc|bc|https://www.gnu.org/software/bc/"
    "awk|gawk|gawk|gawk|awk (gawk)|https://www.gnu.org/software/gawk/"
    "gnuplot|gnuplot|gnuplot|gnuplot|gnuplot|https://www.gnuplot.info/"
    "convert|imagemagick|ImageMagick|imagemagick|ImageMagick|https://imagemagick.org"
)

# ── Detect package manager ────────────────────────────────────────────────────
detect_pm() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# ── Install a single package ──────────────────────────────────────────────────
install_pkg() {
    local pm="$1" pkg="$2" name="$3"
    info "Installing ${name} (${pkg}) via ${pm}…"
    case "$pm" in
        apt)
            sudo apt-get install -y "$pkg"
            ;;
        dnf)
            sudo dnf install -y "$pkg"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$pkg"
            ;;
    esac
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    section "=== Dependency Checker ==="

    local pm
    pm="$(detect_pm)"

    if [[ "$pm" == "unknown" ]]; then
        die "No supported package manager found (apt / dnf / pacman)."
    fi

    info "Detected package manager: ${BOLD}${pm}${RESET}"

    # Refresh package index once if we will need to install anything
    # (deferred until we know at least one package is missing)
    local index_refreshed=false
    local missing=()
    local found=()

    # ── Check phase ───────────────────────────────────────────────────────────
    section "── Checking dependencies ──"
    for entry in "${DEPS[@]}"; do
        IFS='|' read -r binary apt_pkg dnf_pkg pacman_pkg name url <<< "$entry"

        if command -v "$binary" &>/dev/null; then
            ok "${name} $(command -v "$binary")"
            found+=("$name")
        else
            warn "${name} not found  →  ${url}"
            missing+=("$entry")
        fi
    done

    # ── Install phase ─────────────────────────────────────────────────────────
    if [[ ${#missing[@]} -eq 0 ]]; then
        section "── Result ──"
        ok "All dependencies are already satisfied. Nothing to install."
        exit 0
    fi

    section "── Installing missing dependencies (${#missing[@]}) ──"

    # Refresh index once
    if [[ "$index_refreshed" == false ]]; then
        info "Refreshing package index…"
        case "$pm" in
            apt)     sudo apt-get update -y ;;
            dnf)     sudo dnf check-update -y || true ;;   # returns 100 when updates exist
            pacman)  sudo pacman -Sy ;;
        esac
        index_refreshed=true
    fi

    local failed=()
    for entry in "${missing[@]}"; do
        IFS='|' read -r binary apt_pkg dnf_pkg pacman_pkg name url <<< "$entry"

        # Pick the right package name for this PM
        local pkg
        case "$pm" in
            apt)    pkg="$apt_pkg"    ;;
            dnf)    pkg="$dnf_pkg"    ;;
            pacman) pkg="$pacman_pkg" ;;
        esac

        if install_pkg "$pm" "$pkg" "$name"; then
            # Verify the binary is now reachable
            if command -v "$binary" &>/dev/null; then
                ok "${name} installed successfully."
            else
                warn "${name} package installed but binary '${binary}' not found in PATH."
                failed+=("$name")
            fi
        else
            err "Failed to install ${name} (package: ${pkg})."
            failed+=("$name")
        fi
    done

    # ── Summary ───────────────────────────────────────────────────────────────
    section "── Summary ──"
    echo -e "  Already present : ${GREEN}${#found[@]}${RESET}"
    local installed=$(( ${#missing[@]} - ${#failed[@]} ))
    echo -e "  Newly installed : ${GREEN}${installed}${RESET}"
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo -e "  Failed          : ${RED}${#failed[@]}${RESET}  (${failed[*]})"
        exit 1
    else
        ok "All dependencies satisfied."
    fi
}

main "$@"