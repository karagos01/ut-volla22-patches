#!/usr/bin/env bash
# Fingerprint wake+unlock — single touch to wake and unlock
# Volla Phone 22 / UT 24.04
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

# Backup
[ -f /usr/share/lomiri/Greeter/Greeter.qml ] && [ ! -f /usr/share/lomiri/Greeter/Greeter.qml.orig ] && \
    sudo cp /usr/share/lomiri/Greeter/Greeter.qml /usr/share/lomiri/Greeter/Greeter.qml.orig

# Install FpWake QML plugin
sudo mkdir -p /usr/lib/aarch64-linux-gnu/lomiri/qml/FpWake
sudo install -m 0644 "$DIR/FpWake/libfpwake-plugin.so" /usr/lib/aarch64-linux-gnu/lomiri/qml/FpWake/
sudo install -m 0644 "$DIR/FpWake/qmldir" /usr/lib/aarch64-linux-gnu/lomiri/qml/FpWake/

# Install patched Greeter
sudo install -m 0644 "$DIR/Greeter.qml" /usr/share/lomiri/Greeter/Greeter.qml

# Enable fingerprint identification
UID_NUM=$(id -u phablet 2>/dev/null || echo 32011)
sudo gdbus call --system --dest org.freedesktop.Accounts \
    --object-path "/org/freedesktop/Accounts/User${UID_NUM}" \
    --method org.freedesktop.DBus.Properties.Set \
    com.lomiri.AccountsService.SecurityPrivacy EnableFingerprintIdentification '<true>' >/dev/null 2>&1 || true

echo "Fingerprint wake+unlock installed."
echo "Enroll fingerprint: QT_QPA_PLATFORM=minimal qmlscene $DIR/enroll.qml"
