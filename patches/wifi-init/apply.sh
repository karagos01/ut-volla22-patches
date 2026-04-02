#!/bin/bash
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST="${HOST:-100.113.104.32}"
SSH="sshpass -p 9021 ssh -o StrictHostKeyChecking=no phablet@${HOST}"
SCP="sshpass -p 9021 scp -o StrictHostKeyChecking=no"

echo "==> Remounting RW..."
$SSH 'echo 9021 | sudo -S mount -o remount,rw /'

echo "==> Uploading wifi-init service..."
$SCP "$PATCH_DIR/wifi-init.service" "phablet@${HOST}:/tmp/wifi-init.service"
$SSH 'echo 9021 | sudo -S cp /tmp/wifi-init.service /etc/systemd/system/wifi-init.service'
$SSH 'echo 9021 | sudo -S systemctl daemon-reload'
$SSH 'echo 9021 | sudo -S systemctl enable wifi-init.service'

echo "==> Done. WiFi will auto-initialize on boot."
