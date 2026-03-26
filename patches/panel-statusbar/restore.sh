#!/usr/bin/env bash
set -uo pipefail
for f in Panel.qml PanelMenu.qml PanelBar.qml Indicators/IndicatorItem.qml; do
    [ -f "/usr/share/lomiri/Panel/${f}.orig" ] && sudo cp "/usr/share/lomiri/Panel/${f}.orig" "/usr/share/lomiri/Panel/$f"
done
echo "Stock panel restored."
