#!/bin/bash
set -euo pipefail

HOST="${HOST:-100.113.104.32}"
SSH="sshpass -p 9021 ssh -o StrictHostKeyChecking=no phablet@${HOST}"

echo "==> Removing patched terminal..."
$SSH "echo 9021 | sudo -S click unregister --user=phablet terminal.ubports 2.0.6 2>/dev/null || true"

echo "==> Reinstall from OpenStore if needed."
echo "==> Done."
