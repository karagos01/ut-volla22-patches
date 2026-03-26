#!/usr/bin/env bash
# Ubuntu Touch patchset installer — Volla Phone 22 / UT 24.04
set -uo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*" >&2; }

# Auto-discover patches
PATCHES=()
DESCS=()
for d in "$BASE"/patches/*/apply.sh; do
    [ -f "$d" ] || continue
    name="$(basename "$(dirname "$d")")"
    desc=""
    [ -f "$(dirname "$d")/README.md" ] && desc="$(head -1 "$(dirname "$d")/README.md" | sed 's/^# //')"
    PATCHES+=("$name")
    DESCS+=("$desc")
done

ensure_rw() {
    if ! touch /usr/share/.rw-test 2>/dev/null; then
        info "Remounting root read-write..."
        sudo mount -o remount,rw /
    fi
    rm -f /usr/share/.rw-test 2>/dev/null
}

apply_patch() {
    local name="$1"
    local script="$BASE/patches/$name/apply.sh"
    info "Applying: $name"
    if bash "$script" 2>&1; then
        ok "$name"
    else
        err "$name failed"
    fi
}

list_patches() {
    echo
    for i in "${!PATCHES[@]}"; do
        printf "  ${CYAN}%2d)${NC} %-25s %s\n" "$((i+1))" "${PATCHES[$i]}" "${DESCS[$i]}"
    done
    echo
}

case "${1:-}" in
    --all)
        ensure_rw
        for p in "${PATCHES[@]}"; do apply_patch "$p"; done
        info "Restart lightdm to apply UI changes: sudo systemctl restart lightdm.service"
        ;;
    --list)
        list_patches
        ;;
    --help|-h)
        echo "Usage: $0 [--all | --list | PATCH_NAME ...]"
        ;;
    "")
        echo
        echo -e "${CYAN}  Volla Phone 22 — UT 24.04 Patches${NC}"
        echo
        echo "  1) Install all patches"
        echo "  2) Choose patches"
        echo "  3) List patches"
        echo "  4) Exit"
        echo
        read -p "  Choice [1-4]: " choice
        case "$choice" in
            1)
                ensure_rw
                for p in "${PATCHES[@]}"; do apply_patch "$p"; done
                info "Restart lightdm: sudo systemctl restart lightdm.service"
                ;;
            2)
                list_patches
                read -p "  Numbers (space-separated): " -a nums
                ensure_rw
                for n in "${nums[@]}"; do
                    idx=$((n-1))
                    [ "$idx" -ge 0 ] && [ "$idx" -lt "${#PATCHES[@]}" ] && apply_patch "${PATCHES[$idx]}"
                done
                ;;
            3) list_patches ;;
            4) exit 0 ;;
        esac
        ;;
    *)
        ensure_rw
        for p in "$@"; do apply_patch "$p"; done
        ;;
esac
