/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQml 2.15
import Lomiri.Components 1.3
import Lomiri.Settings.Components 0.1
import QMenuModel 1.0
import FpWake 0.1

IndicatorDelegate {
    id: root

    property string identifier
    property alias title: indicatorName.text
    property alias leftLabel: leftLabelItem.text
    property alias rightLabel: rightLabelItem.text
    property var icons: undefined
    property bool expanded: false
    property bool selected: false
    property bool quickTileMode: false
    property real forcedQuickTileWidth: 0
    property var tileActiveOverride: undefined
    property real iconHeight: quickTileMode ? units.gu(2.5) : units.gu(2)

    readonly property real quickTileWidth: units.gu(9.4)

    readonly property bool tileActive: {
        if (identifier.indexOf("sound") !== -1) {
            if (icons && icons.length > 0 && typeof icons[0] === "string") return icons[0].indexOf("muted") === -1;
            return true;
        }
        if (identifier.indexOf("display") !== -1) return tileActiveOverride !== undefined ? tileActiveOverride : false;
        if (identifier.indexOf("power") !== -1) return tileActiveOverride !== undefined ? tileActiveOverride : false;
        if (identifier.indexOf("location") !== -1) {
            if (icons && icons.length > 0 && typeof icons[0] === "string") return icons[0].indexOf("disabled") === -1;
            return false;
        }
        return icons !== undefined && icons.length > 0;
    }
    readonly property color quickTileIconColor: {
        if (quickTileMode && tileActive) return "#FFFFFF";
        if (quickTileMode) return theme.palette.normal.backgroundText;
        return root.color;
    }

    readonly property color color: {
        if (!expanded && !quickTileMode) return theme.palette.normal.backgroundText;
        if (!selected && !quickTileMode) return theme.palette.disabled.backgroundText;
        return theme.palette.normal.backgroundText;
    }

    implicitWidth: quickTileMode ? quickTileWidth : mainItems.width

    clip: quickTileMode


    function activateQuickTile() {
        if (identifier.indexOf("display") !== -1) {
            FpWake.setRotationLock(!tileActive);
            tileActiveOverride = !tileActive;
            return;
        }
        if (identifier.indexOf("power") !== -1) {
            FpWake.toggleFlashlight();
            tileActiveOverride = !tileActive;
            return;
        }
        if (identifier.indexOf("location") !== -1) {
            FpWake.toggleLocation();
            return;
        }
        if (identifier.indexOf("sound") !== -1) {
            FpWake.setMute(false);
            return;
        }
        if (secondaryAction.valid) {
            secondaryAction.activate();
        }
    }

    // Prevent ListView from removing us from the view while expanding.
    // If we're the PanelBar's initial item, our removal will make it lose
    // track of us and cause its positioning to go wrong.
    ListView.delayRemove: stateTransition.running

    MouseArea {
        readonly property int stepUp: 1
        readonly property int stepDown: -1

        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        enabled: !quickTileMode
        onClicked: {
            if ((!expanded || selected) && secondaryAction.valid) {
                secondaryAction.activate();
            }
        }
        onWheel: {
            if ((!expanded || selected) && scrollAction.valid) {
                scrollAction.activate(wheel.angleDelta.y > 0 ? stepUp : stepDown);
            }
        }
    }

    Rectangle {
        id: tileCircle
        visible: quickTileMode
        width: units.gu(5)
        height: units.gu(5)
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: units.gu(0.5)
        color: root.tileActive ? theme.palette.normal.activity : Qt.rgba(theme.palette.normal.backgroundText.r,
                                                                        theme.palette.normal.backgroundText.g,
                                                                        theme.palette.normal.backgroundText.b,
                                                                        0.15)

        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Item {
        id: batteryIndicator
        visible: root.identifier.indexOf("power") !== -1 && !root.expanded && !root.quickTileMode
        width: units.gu(2.5)
        height: units.gu(1.2)
        anchors.centerIn: parent

        property real batteryLevel: {
            // Try rightLabel first
            var pct = parseInt(root.rightLabel);
            if (!isNaN(pct) && pct >= 0 && pct <= 100) return pct;
            // Parse from icon name (e.g. "battery-070-panel" -> 70)
            if (root.icons && root.icons.length > 0) {
                var match = root.icons[0].match(/battery-(\d{3})/);
                if (match) return parseInt(match[1]);
            }
            return 50;
        }

        Rectangle {
            id: batteryBody
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - units.dp(3)
            height: parent.height
            radius: units.dp(2)
            color: "transparent"
            border.color: theme.palette.normal.backgroundText
            border.width: units.dp(1)

            Rectangle {
                id: batteryFill
                anchors.left: parent.left
                anchors.leftMargin: units.dp(1.5)
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height - units.dp(3)
                width: Math.max(0, (parent.width - units.dp(3)) * batteryIndicator.batteryLevel / 100)
                radius: units.dp(1)
                color: batteryIndicator.batteryLevel > 20 ? "#4CAF50" :
                       batteryIndicator.batteryLevel > 10 ? "#FF9800" : "#F44336"
            }

            Label {
                anchors.centerIn: parent
                text: batteryIndicator.batteryLevel + "%"
                fontSize: "xx-small"
                font.weight: Font.DemiBold
                color: theme.palette.normal.backgroundText
            }
        }

        Rectangle {
            id: batteryNub
            anchors.left: batteryBody.right
            anchors.verticalCenter: parent.verticalCenter
            width: units.dp(3)
            height: units.dp(4)
            radius: units.dp(1)
            color: theme.palette.normal.backgroundText
        }
    }

    Item {
        id: mainItems
        anchors.centerIn: quickTileMode ? tileCircle : parent
        visible: !(root.identifier.indexOf("power") !== -1 && !root.expanded && !root.quickTileMode)

        width: quickTileMode ? tileCircle.width : (leftLabelItem.width + iconsItem.width + rightLabelItem.width)
        implicitHeight: units.gu(2)

        Label {
            id: leftLabelItem
            objectName: "leftLabel"

            anchors {
                left: mainItems.left
                verticalCenter: parent.verticalCenter
            }
            width: quickTileMode ? 0 : (contentWidth > 0 ? contentWidth + units.gu(1) : 0)
            horizontalAlignment: Text.AlignHCenter
            visible: !quickTileMode

            opacity: 1.0
            font.family: "Ubuntu"
            fontSize: "medium"
            font.weight: Font.Light
            color: root.quickTileIconColor
            Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration; easing: LomiriAnimation.StandardEasing } }
        }

        Item {
            id: iconsItem
            objectName: "icons"

            width: quickTileMode ? tileCircle.width : (iconRow.width > 0 ? iconRow.width + units.gu(1) : 0)
            anchors {
                left: quickTileMode ? undefined : leftLabelItem.right
                horizontalCenter: quickTileMode ? parent.horizontalCenter : undefined
                verticalCenter: parent.verticalCenter
            }

            Row {
                id: iconRow
                anchors.centerIn: iconsItem
                spacing: units.gu(1)

                Repeater {
                    id: iconRepeater
                    objectName: "iconRepeater"

                    model: d.useFallbackIcon ? [ d.fallbackIconForIdentifier(root.identifier) ] : d.quickTileIconOverride !== "" ? [ d.quickTileIconOverride ] : (d.hideMinimisedFallback ? [] : root.icons)

                    Icon {
                        id: itemImage
                        objectName: "icon"+index
                        height: iconHeight
                        // FIXME Workaround for bug https://bugs.launchpad.net/lomiri/+source/lomiri-ui-toolkit/+bug/1421293
                        width: implicitWidth > 0 && implicitHeight > 0 ? (implicitWidth / implicitHeight * height) : implicitWidth;
                        source: modelData
                        color: root.quickTileIconColor
                        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration; easing: LomiriAnimation.StandardEasing } }

                        // Workaround indicators getting stretched/squished when (un)plugging external/virtual monitor
                        onHeightChanged: {
                            source = ""
                            source = modelData
                        }
                    }
                }
            }
        }

        Label {
            id: rightLabelItem
            objectName: "rightLabel"

            anchors {
                left: iconsItem.right
                verticalCenter: parent.verticalCenter
            }
            width: quickTileMode ? 0 : (contentWidth > 0 ? contentWidth + units.gu(1) : 0)
            horizontalAlignment: Text.AlignHCenter
            visible: !quickTileMode

            opacity: 1.0
            font.family: "Ubuntu"
            fontSize: "medium"
            font.weight: Font.Light
            color: root.quickTileIconColor
            Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration; easing: LomiriAnimation.StandardEasing } }
        }
    }

    Label {
        id: indicatorName
        objectName: "indicatorName"

        anchors.top: quickTileMode ? tileCircle.bottom : mainItems.bottom
        anchors.topMargin: units.gu(0.5)
        anchors.horizontalCenter: parent.horizontalCenter
        width: quickTileMode ? parent.width : (contentWidth > 0 ? contentWidth + units.gu(1) : 0)

        text: identifier
        fontSize: "x-small"
        font.weight: Font.Light
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        opacity: quickTileMode ? 1 : 0
        color: root.quickTileIconColor
        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration; easing: LomiriAnimation.StandardEasing } }
    }

    MouseArea {
        id: quickTileTapArea
        anchors.fill: parent
        visible: quickTileMode
        enabled: quickTileMode
        onClicked: {
            root.activateQuickTile();
        }
    }

    StateGroup {
        objectName: "indicatorItemState"

        states: [
            State {
                name: "minimised"
                when: !quickTileMode && !expanded && ((icons && icons.length > 0) || leftLabel !== "" || rightLabel !== "")
                PropertyChanges { target: indicatorName; opacity: 0 }
            },

            State {
                name: "minimised_fallback_hidden"
                when: !quickTileMode && !expanded && (!icons || icons.length === 0) && leftLabel == "" && rightLabel == "" && (root.identifier === "ayatana-indicator-network" || root.identifier === "ayatana-indicator-transfer" || root.identifier === "ayatana-indicator-messages")
                PropertyChanges { target: indicatorName; opacity: 0 }
                PropertyChanges { target: d; useFallbackIcon: true; hideMinimisedFallback: false }
            },

            State {
                name: "minimised_fallback"
                when: !quickTileMode && !expanded && (!icons || icons.length === 0) && leftLabel == "" && rightLabel == ""
                PropertyChanges { target: indicatorName; opacity: 0 }
                PropertyChanges { target: d; useFallbackIcon: true }
            },

            State {
                name: "expanded"
                PropertyChanges { target: indicatorName; visible: true; opacity: 1 }
                PropertyChanges { target: mainItems; anchors.verticalCenterOffset: -units.gu(1) }
            },

            State {
                name: "quicktile"
                when: quickTileMode
                PropertyChanges { target: indicatorName; visible: true; opacity: 1 }
                PropertyChanges { target: mainItems; anchors.verticalCenterOffset: 0 }
                PropertyChanges { target: root; width: quickTileWidth }
                PropertyChanges { target: d; useFallbackIcon: (!root.icons || root.icons.length === 0) && root.leftLabel === "" && root.rightLabel === "" }
            },

            State {
                name: "expanded_icon"
                extend: "expanded"
                when: !quickTileMode && expanded && (icons && icons.length > 0)
                AnchorChanges { target: iconsItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                AnchorChanges { target: leftLabelItem; anchors.left: undefined; anchors.right: iconsItem.left }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: rightLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(iconsItem.width, indicatorName.width)) }
            },

            State {
                name: "expanded_fallback"
                extend: "expanded"
                when: !quickTileMode && expanded && (!icons || icons.length === 0) && leftLabel == "" && rightLabel == ""
                PropertyChanges { target: d; useFallbackIcon: true }
                AnchorChanges { target: iconsItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                AnchorChanges { target: leftLabelItem; anchors.left: undefined; anchors.right: iconsItem.left }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: rightLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(iconsItem.width, indicatorName.width)) }
            },

            State {
                name: "expanded_rightLabel"
                extend: "expanded"
                when: !quickTileMode && expanded && (!icons || icons.length === 0) && rightLabel !== ""
                AnchorChanges { target: rightLabelItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                PropertyChanges { target: iconsItem; opacity: 0 }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(rightLabelItem.width, indicatorName.width)) }
            },

            State {
                name: "expanded_leftLabel"
                extend: "expanded"
                when: !quickTileMode && expanded && (!icons || icons.length === 0) && leftLabel !== ""
                AnchorChanges { target: leftLabelItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                PropertyChanges { target: iconsItem; opacity: 0 }
                PropertyChanges { target: rightLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(leftLabelItem.width, indicatorName.width)) }
            }
        ]

        transitions: [
            Transition {
                id: stateTransition
                PropertyAction { target: d; property: "useFallbackIcon" }
                AnchorAnimation {
                    targets: [ mainItems, iconsItem, leftLabelItem, rightLabelItem ]
                    duration: LomiriAnimation.SnapDuration; easing: LomiriAnimation.StandardEasing
                }
                PropertyAnimation {
                    targets: [ root, mainItems, iconsItem, leftLabelItem, rightLabelItem, indicatorName ]
                    properties: "width, opacity, anchors.verticalCenterOffset";
                    duration: LomiriAnimation.SnapDuration; easing: LomiriAnimation.StandardEasing
                }
            }
        ]
    }

    rootActionState.onUpdated: {
        if (rootActionState == undefined) {
            title = "";
            leftLabel = "";
            rightLabel = "";
            icons = undefined;
            return;
        }

        title = rootActionState.title ? rootActionState.title : rootActionState.accessibleName;
        leftLabel = rootActionState.leftLabel ? rootActionState.leftLabel : "";
        rightLabel = rootActionState.rightLabel ? rootActionState.rightLabel : "";
        icons = rootActionState.icons;
    }

    QtObject {
        id: d

        property bool useFallbackIcon: false
        property bool hideMinimisedFallback: root.identifier.indexOf("network") !== -1
        property bool rotationLocked: false
        property bool flashlightOn: false
        property string quickTileIconOverride: {
            if (!root.quickTileMode) return "";
            if (root.identifier.indexOf("power") !== -1) return root.tileActive ? "image://theme/torch-on" : "image://theme/torch-off";
            if (root.identifier.indexOf("display") !== -1) return root.tileActive ? "image://theme/orientation-lock" : "image://theme/view-rotate";
            return "";
        }
        property var shouldIndicatorBeShown: undefined

        function fallbackIconForIdentifier(ident) {
            if (ident === "ayatana-indicator-messages") return "image://theme/messages";
            if (ident === "ayatana-indicator-network") return "image://theme/nm-signal-100";
            if (ident === "ayatana-indicator-transfer") return "image://theme/transfer-progress";
            if (ident === "ayatana-indicator-bluetooth") return "image://theme/bluetooth-active";
            if (ident === "ayatana-indicator-power") return root.quickTileMode ? "image://theme/torch-on" : "image://theme/battery-full-charged";
            if (ident === "ayatana-indicator-sound") return "image://theme/audio-volume-medium";
            if (ident === "ayatana-indicator-location") return "image://theme/location";
            if (ident === "ayatana-indicator-rotation-lock") return "image://theme/orientation-lock";
            if (ident === "ayatana-indicator-keyboard") return "image://theme/input-keyboard-symbolic";
            if (ident === "ayatana-indicator-session") return "image://theme/system-devices-panel";
            if (ident === "ayatana-indicator-datetime") return "image://theme/clock";
            return "image://theme/settings";
        }

        onShouldIndicatorBeShownChanged: {
            if (shouldIndicatorBeShown !== undefined) {
                submenuAction.changeState(shouldIndicatorBeShown);
            }
        }
    }

    AyatanaMenuAction {
        id: secondaryAction
        model: menuModel
        index: 0
        name: rootActionState.secondaryAction
    }

    AyatanaMenuAction {
        id: scrollAction
        model: menuModel
        index: 0
        name: rootActionState.scrollAction
    }

    AyatanaMenuAction {
        id: submenuAction
        model: menuModel
        index: 0
        name: rootActionState.submenuAction
    }

    Binding {
        target: d
        property: "shouldIndicatorBeShown"
        restoreMode: Binding.RestoreBinding
        when: submenuAction.valid
        value: root.selected && root.expanded
    }
}
