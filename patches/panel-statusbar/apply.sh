#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

for f in Panel.qml PanelMenu.qml PanelBar.qml Indicators/IndicatorItem.qml; do
    [ ! -f "/usr/share/lomiri/Panel/${f}.orig" ] && sudo cp "/usr/share/lomiri/Panel/$f" "/usr/share/lomiri/Panel/${f}.orig"
done

sudo install -m 0644 "$DIR/Panel.qml" /usr/share/lomiri/Panel/Panel.qml
sudo install -m 0644 "$DIR/PanelMenu.qml" /usr/share/lomiri/Panel/PanelMenu.qml
sudo install -m 0644 "$DIR/PanelBar.qml" /usr/share/lomiri/Panel/PanelBar.qml
sudo install -m 0644 "$DIR/IndicatorItem.qml" /usr/share/lomiri/Panel/Indicators/IndicatorItem.qml

echo "Panel statusbar applied."
