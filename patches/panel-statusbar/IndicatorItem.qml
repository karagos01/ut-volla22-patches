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
    property real iconHeight: quickTileMode ? units.gu(2.5) : units.gu(2)

    readonly property real quickTileWidth: units.gu(9.4)

    readonly property color quickTileIconColor: {
        if (quickTileMode && selected) return "#FFFFFF";
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
        color: root.selected ? theme.palette.normal.activity : Qt.rgba(theme.palette.normal.backgroundText.r,
                                                                        theme.palette.normal.backgroundText.g,
                                                                        theme.palette.normal.backgroundText.b,
                                                                        0.15)

        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Item {
        id: mainItems
        anchors.centerIn: quickTileMode ? tileCircle : parent

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

                    model: d.useFallbackIcon ? [ d.fallbackIconForIdentifier(root.identifier) ] : (d.hideMinimisedFallback ? [] : root.icons)

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
                when: !quickTileMode && !expanded && (!icons || icons.length === 0) && leftLabel == "" && rightLabel == "" && (root.identifier === "ayatana-indicator-network" || root.identifier === "ayatana-indicator-transfer")
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
        property bool hideMinimisedFallback: false
        property var shouldIndicatorBeShown: undefined

        function fallbackIconForIdentifier(ident) {
            if (ident === "ayatana-indicator-messages") return "image://theme/messages";
            if (ident === "ayatana-indicator-network") return "image://theme/nm-signal-100";
            if (ident === "ayatana-indicator-transfer") return "image://theme/transfer-progress";
            if (ident === "ayatana-indicator-bluetooth") return "image://theme/bluetooth-active";
            if (ident === "ayatana-indicator-power") return "image://theme/battery-full-charged";
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
