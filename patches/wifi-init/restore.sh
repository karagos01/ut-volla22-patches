#!/bin/bash
set -euo pipefail

HOST="${HOST:-100.113.104.32}"
SSH="sshpass -p 9021 ssh -o StrictHostKeyChecking=no phablet@${HOST}"

echo "==> Remounting RW..."
$SSH 'echo 9021 | sudo -S mount -o remount,rw /'

echo "==> Removing wifi-init service..."
$SSH 'echo 9021 | sudo -S systemctl disable wifi-init.service 2>/dev/null || true'
$SSH 'echo 9021 | sudo -S rm -f /etc/systemd/system/wifi-init.service'
$SSH 'echo 9021 | sudo -S systemctl daemon-reload'

echo "==> Done. WiFi auto-init removed."
