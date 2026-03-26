#!/usr/bin/env bash
set -uo pipefail
[ -f /usr/share/lomiri/Greeter/Greeter.qml.orig ] && sudo cp /usr/share/lomiri/Greeter/Greeter.qml.orig /usr/share/lomiri/Greeter/Greeter.qml
sudo rm -rf /usr/lib/aarch64-linux-gnu/lomiri/qml/FpWake
echo "Fingerprint wake restored to stock."
