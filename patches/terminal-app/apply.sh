#!/bin/bash
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST="${HOST:-100.113.104.32}"
SSH="sshpass -p 9021 ssh -o StrictHostKeyChecking=no phablet@${HOST}"
SCP="sshpass -p 9021 scp -o StrictHostKeyChecking=no"

CLICK="terminal.ubports_2.0.6_arm64.click"

echo "==> Uploading terminal click package..."
$SCP "$PATCH_DIR/$CLICK" "phablet@${HOST}:/tmp/$CLICK"

echo "==> Installing..."
$SSH "echo 9021 | sudo -S click install --user=phablet /tmp/$CLICK"

echo "==> Done. Terminal app installed with Termux keyboard bar."
