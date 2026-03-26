#!/usr/bin/env bash
# Restore original unlock speed
set -uo pipefail

for f in /etc/pam.d/lightdm /etc/pam.d/common-auth /etc/pam.d/common-session /usr/share/lomiri/Greeter/GreeterView.qml; do
    [ -f "${f}.orig" ] && sudo cp "${f}.orig" "$f"
done

echo "Original unlock restored."
