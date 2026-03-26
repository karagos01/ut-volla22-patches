#!/usr/bin/env bash
# Bootstrap for fresh UT install — remount R/W, install git, clone and run patchset
set -uo pipefail

REPO="https://github.com/karagos01/ut-volla22-patches"
BASE="/home/phablet/.local/share/ut-patches"

echo "Ubuntu Touch patchset bootstrap — Volla Phone 22"

# Remount R/W
if ! touch /usr/share/.rw-test 2>/dev/null; then
    echo "Remounting root read-write..."
    sudo mount -o remount,rw /
fi
rm -f /usr/share/.rw-test 2>/dev/null

# Install git if missing
if ! command -v git &>/dev/null; then
    echo "Installing git..."
    sudo apt-get update -qq && sudo apt-get install -y git
fi

# Clone or update
if [ -d "$BASE/.git" ]; then
    git -C "$BASE" pull --ff-only 2>/dev/null || { rm -rf "$BASE"; git clone --depth 1 "$REPO" "$BASE"; }
else
    git clone --depth 1 "$REPO" "$BASE"
fi

exec bash "$BASE/install.sh"
