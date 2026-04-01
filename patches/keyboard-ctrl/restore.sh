#!/bin/bash
set -euo pipefail

HOST="${HOST:-100.113.104.32}"
SSH="sshpass -p 9021 ssh -o StrictHostKeyChecking=no phablet@${HOST}"

KEYS_DIR="/usr/share/maliit/plugins/lomiri-keyboard/keys"
CONTAINER="/usr/share/maliit/plugins/lomiri-keyboard/KeyboardContainer.qml"
EN_DIR="/usr/lib/lomiri-keyboard/plugins/en"
CS_DIR="/usr/lib/lomiri-keyboard/plugins/cs"

echo "==> Remounting RW..."
$SSH 'echo 9021 | sudo -S mount -o remount,rw /'

echo "==> Restoring originals..."
$SSH "echo 9021 | sudo -S mv ${KEYS_DIR}/CharKey.qml.orig ${KEYS_DIR}/CharKey.qml 2>/dev/null || true"
$SSH "echo 9021 | sudo -S mv ${KEYS_DIR}/qmldir.orig ${KEYS_DIR}/qmldir 2>/dev/null || true"
$SSH "echo 9021 | sudo -S mv ${CONTAINER}.orig ${CONTAINER} 2>/dev/null || true"
$SSH "echo 9021 | sudo -S mv ${EN_DIR}/Keyboard_en.qml.orig ${EN_DIR}/Keyboard_en.qml 2>/dev/null || true"
$SSH "echo 9021 | sudo -S mv ${CS_DIR}/Keyboard_cs.qml.orig ${CS_DIR}/Keyboard_cs.qml 2>/dev/null || true"
$SSH "echo 9021 | sudo -S rm -f ${KEYS_DIR}/CtrlKey.qml"

echo "==> Restarting maliit-server..."
$SSH 'systemctl --user restart maliit-server.service'

echo "==> Done. Keyboard restored to original."
