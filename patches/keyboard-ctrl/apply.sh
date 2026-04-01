#!/bin/bash
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST="${HOST:-100.113.104.32}"
SSH="sshpass -p 9021 ssh -o StrictHostKeyChecking=no phablet@${HOST}"
SCP="sshpass -p 9021 scp -o StrictHostKeyChecking=no"

KEYS_DIR="/usr/share/maliit/plugins/lomiri-keyboard/keys"
CONTAINER="/usr/share/maliit/plugins/lomiri-keyboard/KeyboardContainer.qml"
EN_DIR="/usr/lib/lomiri-keyboard/plugins/en"
CS_DIR="/usr/lib/lomiri-keyboard/plugins/cs"

echo "==> Remounting RW..."
$SSH 'echo 9021 | sudo -S mount -o remount,rw /'

echo "==> Backing up originals..."
$SSH "echo 9021 | sudo -S cp ${KEYS_DIR}/CharKey.qml ${KEYS_DIR}/CharKey.qml.orig 2>/dev/null || true"
$SSH "echo 9021 | sudo -S cp ${KEYS_DIR}/qmldir ${KEYS_DIR}/qmldir.orig 2>/dev/null || true"
$SSH "echo 9021 | sudo -S cp ${CONTAINER} ${CONTAINER}.orig 2>/dev/null || true"
$SSH "echo 9021 | sudo -S cp ${EN_DIR}/Keyboard_en.qml ${EN_DIR}/Keyboard_en.qml.orig 2>/dev/null || true"
$SSH "echo 9021 | sudo -S cp ${CS_DIR}/Keyboard_cs.qml ${CS_DIR}/Keyboard_cs.qml.orig 2>/dev/null || true"

echo "==> Uploading patched files..."
$SCP "$PATCH_DIR/CtrlKey.qml" "phablet@${HOST}:/tmp/CtrlKey.qml"
$SCP "$PATCH_DIR/CharKey.qml" "phablet@${HOST}:/tmp/CharKey.qml"
$SCP "$PATCH_DIR/qmldir" "phablet@${HOST}:/tmp/keys_qmldir"
$SCP "$PATCH_DIR/KeyboardContainer.qml" "phablet@${HOST}:/tmp/KeyboardContainer.qml"
$SCP "$PATCH_DIR/Keyboard_en.qml" "phablet@${HOST}:/tmp/Keyboard_en.qml"
$SCP "$PATCH_DIR/Keyboard_cs.qml" "phablet@${HOST}:/tmp/Keyboard_cs.qml"

$SSH "echo 9021 | sudo -S cp /tmp/CtrlKey.qml ${KEYS_DIR}/CtrlKey.qml"
$SSH "echo 9021 | sudo -S cp /tmp/CharKey.qml ${KEYS_DIR}/CharKey.qml"
$SSH "echo 9021 | sudo -S cp /tmp/keys_qmldir ${KEYS_DIR}/qmldir"
$SSH "echo 9021 | sudo -S cp /tmp/KeyboardContainer.qml ${CONTAINER}"
$SSH "echo 9021 | sudo -S cp /tmp/Keyboard_en.qml ${EN_DIR}/Keyboard_en.qml"
$SSH "echo 9021 | sudo -S cp /tmp/Keyboard_cs.qml ${CS_DIR}/Keyboard_cs.qml"

echo "==> Restarting maliit-server..."
$SSH 'systemctl --user restart maliit-server.service'

echo "==> Done. Ctrl key added to keyboard."
