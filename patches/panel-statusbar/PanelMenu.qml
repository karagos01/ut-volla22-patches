/*
 * Copyright (C) 2014-2016 Canonical Ltd.
 * Copyright (C) 2020 UBports Foundation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import Lomiri.Components 1.3
import Lomiri.Gestures 0.1
import "../Components"
import Lomiri.Indicators 0.1
import "Indicators"

Showable {
    id: root
    property alias model: bar.model
    property alias showDragHandle: __showDragHandle
    property alias hideDragHandle: __hideDragHandle
    property alias overFlowWidth: bar.overFlowWidth
    property alias verticalVelocityThreshold: yVelocityCalculator.velocityThreshold
    property int minimizedPanelHeight: units.gu(3)
    property int expandedPanelHeight: units.gu(7)
    property real openedHeight: units.gu(71)
    property bool enableHint: true
    property bool showOnClick: true
    property color panelColor: lightMode ? "#FFFFFF" : "#000000"
    property real menuContentX: 0

    property alias alignment: bar.alignment
    property alias hideRow: bar.hideRow
    property alias rowItemDelegate: bar.rowItemDelegate
    property alias pageDelegate: content.pageDelegate

    property var blurSource : null
    property rect blurRect : Qt.rect(0, 0, 0, 0)
    property bool lightMode : false
    property real barContentRightInset: 0

    // Quick tiles properties for Android-like indicator panel
    property bool showQuickTiles: false
    property real quickTileHeight: units.gu(12)
    property bool hasKeyboard: false
    property string clockText: ""
    property real barContentLeftInset: 0
    readonly property real quickTileSpacing: units.gu(0.6)
    readonly property int quickTileColumns: 4
    readonly property real quickTileCellHeight: units.gu(9)
    readonly property real quickTileCellWidth: units.gu(9.4)
    readonly property bool quickTilesVisible: showQuickTiles && unitProgress > 0

    readonly property real unitProgress: Math.max(0, (height - minimizedPanelHeight) / (openedHeight - minimizedPanelHeight))
    readonly property bool fullyOpened: unitProgress >= 1
    readonly property bool partiallyOpened: unitProgress > 0 && unitProgress < 1.0
    readonly property bool fullyClosed: unitProgress == 0
    readonly property alias expanded: bar.expanded
    readonly property int barWidth: bar.width
    readonly property alias currentMenuIndex: bar.currentItemIndex

    // Exposes the current contentX of the PanelBar's internal ListView. This
    // must be used to offset absolute x values against the ListView, since
    // we commonly add or remove elements and cause the contentX to change.
    readonly property int rowContentX: bar.rowContentX

    // The user tapped the panel and did not move.
    // Note that this does not fire on mouse events, only touch events.
    signal showTapped()

    // TODO: Perhaps we need a animation standard for showing/hiding? Each showable seems to
    // use its own values. Need to ask design about this.
    showAnimation: SequentialAnimation {
        StandardAnimation {
            target: root
            property: "height"
            to: openedHeight
            duration: LomiriAnimation.BriskDuration
            easing.type: Easing.OutCubic
        }
        // set binding in case units.gu changes while menu open, so height correctly adjusted to fit
        ScriptAction { script: root.height = Qt.binding( function(){ return root.openedHeight; } ) }
    }

    hideAnimation: SequentialAnimation {
        StandardAnimation {
            target: root
            property: "height"
            to: minimizedPanelHeight
            duration: LomiriAnimation.BriskDuration
            easing.type: Easing.OutCubic
        }
        // set binding in case units.gu changes while menu closed, so menu adjusts to fit
        ScriptAction { script: root.height = Qt.binding( function(){ return root.minimizedPanelHeight; } ) }
    }

    shown: false
    height: minimizedPanelHeight

    onUnitProgressChanged: d.updateState()

    QtObject {
        id: quickTilesModel

        function identifierAt(row) {
            return root.model ? root.model.data(row, IndicatorsModelRole.Identifier) : "";
        }

        function indicatorPropertiesAt(row) {
            return root.model ? root.model.data(row, IndicatorsModelRole.IndicatorProperties) : ({});
        }

        function isIncluded(row) {
            var ident = identifierAt(row);
            if (ident === "ayatana-indicator-datetime") return false;
            if (ident === "ayatana-indicator-session" && !root.showQuickTiles) return false;
            if (ident === "ayatana-indicator-session") return false;
            if (ident === "ayatana-indicator-keyboard" && !root.hasKeyboard) return false;
            return true;
        }

        function visibleCount() {
            if (!root.model) return 0;
            var c = 0;
            for (var i = 0; i < root.model.count; i++) {
                if (isIncluded(i)) c++;
            }
            return c;
        }

        function visiblePosition(row) {
            if (!root.model) return -1;
            var pos = 0;
            for (var i = 0; i < row; i++) {
                if (isIncluded(i)) pos++;
            }
            return pos;
        }

        function rowFor(row) {
            var pos = visiblePosition(row);
            return Math.floor(pos / root.quickTileColumns);
        }
    }

    function selectQuickTile(modelIndex) {
        bar.setCurrentItemIndex(modelIndex);
    }

    BackgroundBlur {
        x: 0
        y: 0
        width: root.blurRect.width
        height: root.blurRect.height
        visible: root.height > root.minimizedPanelHeight
        sourceItem: root.blurSource
        blurRect: root.blurRect
        occluding: false
    }

    Item {
        anchors {
            left: parent.left
            right: parent.right
            top: bar.bottom
            bottom: parent.bottom
        }
        clip: root.partiallyOpened

        Rectangle {
            color: Qt.rgba(root.panelColor.r,
                           root.panelColor.g,
                           root.panelColor.b,
                           1.0)
            opacity: 0.85
            anchors.fill: parent
        }

        // eater
        MouseArea {
            anchors.fill: content
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: wheel.accepted = true;
            enabled: root.state != "initial"
            visible: content.visible
        }

        Item {
            id: quickTiles
            objectName: "quickTiles"
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: units.gu(3)
            }
            height: quickTilesVisible ? quickTilesColumn.height + units.gu(1) : 0
            visible: quickTilesVisible
            clip: true

            Column {
                id: quickTilesColumn
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.quickTileSpacing

                Repeater {
                    id: quickTileRowRepeater
                    model: {
                        if (!root.quickTilesVisible || !root.model) return 0;
                        var vc = quickTilesModel.visibleCount();
                        return Math.ceil(vc / root.quickTileColumns);
                    }

                    Row {
                        id: tileRow
                        property int rowIndex: index
                        spacing: root.quickTileSpacing
                        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

                        Repeater {
                            id: tileRepeater
                            model: {
                                if (!root.model) return 0;
                                var vc = quickTilesModel.visibleCount();
                                var startPos = tileRow.rowIndex * root.quickTileColumns;
                                var remaining = vc - startPos;
                                return Math.min(root.quickTileColumns, remaining);
                            }

                            Loader {
                                id: tileLoader
                                width: root.quickTileCellWidth
                                height: root.quickTileCellHeight
                                active: quickTilesVisible

                                property int globalVisibleIndex: tileRow.rowIndex * root.quickTileColumns + index
                                property int sourceModelIndex: {
                                    if (!root.model) return -1;
                                    var visIdx = 0;
                                    for (var i = 0; i < root.model.count; i++) {
                                        if (quickTilesModel.isIncluded(i)) {
                                            if (visIdx === globalVisibleIndex) return i;
                                            visIdx++;
                                        }
                                    }
                                    return -1;
                                }

                                sourceComponent: quickTilesVisible ? quickTileDelegate : null

                                property string tileIdentifier: sourceModelIndex >= 0 ? quickTilesModel.identifierAt(sourceModelIndex) : ""
                                property var tileIndicatorProperties: sourceModelIndex >= 0 ? quickTilesModel.indicatorPropertiesAt(sourceModelIndex) : null
                                property bool tileSelected: sourceModelIndex >= 0 && bar.currentItemIndex === sourceModelIndex
                            }
                        }
                    }
                }
            }
        }

        MenuContent {
            id: content
            objectName: "menuContent"

            anchors {
                left: parent.left
                right: parent.right
                top: quickTilesVisible ? quickTiles.bottom : parent.top
            }
            height: openedHeight - bar.height - handle.height - (quickTilesVisible ? quickTiles.height : 0)
            model: root.model
            visible: root.unitProgress > 0
            currentMenuIndex: bar.currentItemIndex
        }
    }

    Handle {
        id: handle
        objectName: "handle"
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(2)
        active: d.activeDragHandle ? true : false
        visible: !root.fullyClosed
    }

    Rectangle {
        anchors.fill: bar
        color: panelColor
        visible: !root.fullyClosed
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Left) {
            bar.selectPreviousItem();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            bar.selectNextItem();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.hide();
            event.accepted = true;
        }
    }

    Rectangle {
        id: panelClockBg
        anchors {
            left: parent.left
            top: bar.top
            bottom: bar.bottom
        }
        width: panelClock.visible ? panelClock.contentWidth + units.gu(5) : 0
        color: panelColor
        visible: panelClock.visible

        Label {
            id: panelClock
            anchors {
                left: parent.left
                leftMargin: units.gu(3)
                verticalCenter: parent.verticalCenter
            }
            text: root.clockText
            fontSize: "medium"
            font.weight: Font.Medium
            color: theme.palette.selected.backgroundText
            visible: root.clockText !== "" && root.showQuickTiles
        }
    }

    PanelBar {
        id: bar
        objectName: "indicatorsBar"

        anchors {
            left: panelClock.visible ? panelClockBg.right : parent.left
            leftMargin: 0
            right: parent.right
        }
        expanded: false
        enableLateralChanges: false
        lateralPosition: -1
        lightMode: root.lightMode
        contentRightInset: root.barContentRightInset
        unitProgress: root.unitProgress

        height: expanded ? expandedPanelHeight : minimizedPanelHeight
        Behavior on height { NumberAnimation { duration: LomiriAnimation.SnapDuration; easing: LomiriAnimation.StandardEasing } }
    }

    ScrollCalculator {
        id: leftScroller
        width: units.gu(5)
        anchors.left: bar.left
        height: bar.height

        forceScrollingPercentage: 0.33
        stopScrollThreshold: units.gu(0.75)
        direction: Qt.RightToLeft
        lateralPosition: -1

        onScroll: bar.addScrollOffset(-scrollAmount);
    }

    ScrollCalculator {
        id: rightScroller
        width: units.gu(5)
        anchors.right: bar.right
        height: bar.height

        forceScrollingPercentage: 0.33
        stopScrollThreshold: units.gu(0.75)
        direction: Qt.LeftToRight
        lateralPosition: -1

        onScroll: bar.addScrollOffset(scrollAmount);
    }

    MouseArea {
        anchors.bottom: parent.bottom
        anchors.left: alignment == Qt.AlignLeft ? parent.left : __showDragHandle.left
        anchors.right: alignment == Qt.AlignRight ? parent.right : __showDragHandle.right
        height: minimizedPanelHeight
        enabled: __showDragHandle.enabled && showOnClick
        onClicked: {
            var barPosition = mapToItem(bar, mouseX, mouseY);
            bar.selectItemAt(barPosition.x)
            root.show()
        }
    }

    DragHandle {
        id: __showDragHandle
        objectName: "showDragHandle"
        anchors.bottom: parent.bottom
        anchors.left: alignment == Qt.AlignLeft ? parent.left : undefined
        anchors.leftMargin: -root.menuContentX
        anchors.right: alignment == Qt.AlignRight ? parent.right : undefined
        width: root.overFlowWidth + root.menuContentX
        height: minimizedPanelHeight
        direction: Direction.Downwards
        enabled: !root.shown && root.available && !hideAnimation.running && !showAnimation.running
        autoCompleteDragThreshold: maxTotalDragDistance / 2
        stretch: true

        onPressedChanged: {
            if (pressed) {
                touchPressTime = new Date().getTime();
            } else {
                var touchReleaseTime = new Date().getTime();
                if (touchReleaseTime - touchPressTime <= 300 && distance < units.gu(1)) {
                    root.showTapped();
                }
            }
        }
        property var touchPressTime

        // using hint regulates minimum to hint displacement, but in fullscreen mode, we need to do it manually.
        overrideStartValue: enableHint ? minimizedPanelHeight : expandedPanelHeight + handle.height
        maxTotalDragDistance: openedHeight - (enableHint ? minimizedPanelHeight : expandedPanelHeight + handle.height)
        hintDisplacement: enableHint ? expandedPanelHeight - minimizedPanelHeight + handle.height : 0
    }

    MouseArea {
        anchors.fill: __hideDragHandle
        enabled: __hideDragHandle.enabled
        onClicked: root.hide()
    }

    DragHandle {
        id: __hideDragHandle
        objectName: "hideDragHandle"
        anchors.fill: handle
        direction: Direction.Upwards
        enabled: root.shown && root.available && !hideAnimation.running && !showAnimation.running
        hintDisplacement: units.gu(3)
        autoCompleteDragThreshold: maxTotalDragDistance / 6
        stretch: true
        maxTotalDragDistance: openedHeight - expandedPanelHeight - handle.height

        onTouchPositionChanged: {
            if (root.state === "locked") {
                d.xDisplacementSinceLock += (touchPosition.x - d.lastHideTouchX)
                d.lastHideTouchX = touchPosition.x;
            }
        }
    }

    PanelVelocityCalculator {
        id: yVelocityCalculator
        velocityThreshold: d.hasCommitted ? 0.1 : 0.3
        trackedValue: d.activeDragHandle ?
                            (Direction.isPositive(d.activeDragHandle.direction) ?
                                    d.activeDragHandle.distance :
                                    -d.activeDragHandle.distance)
                            : 0

        onVelocityAboveThresholdChanged: d.updateState()
    }

    Connections {
        target: showAnimation
        function onRunningChanged() {
            if (showAnimation.running) {
                root.state = "commit";
            }
        }
    }

    Connections {
        target: hideAnimation
        function onRunningChanged() {
            if (hideAnimation.running) {
                root.state = "initial";
            }
        }
    }

    QtObject {
        id: d
        property var activeDragHandle: showDragHandle.dragging ? showDragHandle : hideDragHandle.dragging ? hideDragHandle : null
        property bool hasCommitted: false
        property real lastHideTouchX: 0
        property real xDisplacementSinceLock: 0
        onXDisplacementSinceLockChanged: d.updateState()

        property real rowMappedLateralPosition: {
            if (!d.activeDragHandle) return -1;
            return d.activeDragHandle.mapToItem(bar, d.activeDragHandle.touchPosition.x, 0).x;
        }

        function updateState() {
            if (!showAnimation.running && !hideAnimation.running && d.activeDragHandle) {
                if (unitProgress <= 0) {
                    root.state = "initial";
                // lock indicator if we've been committed and aren't moving too much laterally or too fast up.
                } else if (d.hasCommitted && (Math.abs(d.xDisplacementSinceLock) < units.gu(2) || yVelocityCalculator.velocityAboveThreshold)) {
                    root.state = "locked";
                } else {
                    root.state = "reveal";
                }
            }
        }
    }

    Component {
        id: quickTileDelegate

        Item {
            width: root.quickTileCellWidth
            height: root.quickTileCellHeight

            property string tileIdentifier: parent ? parent.tileIdentifier : ""
            property var tileIndicatorProperties: parent ? parent.tileIndicatorProperties : null
            property bool tileSelected: parent ? parent.tileSelected : false
            property int sourceModelIndex: parent ? parent.sourceModelIndex : -1

            Loader {
                id: qtDelegateLoader
                anchors.fill: parent
                sourceComponent: bar.rowItemDelegate

                property var model: QtObject {
                    property string identifier: tileIdentifier
                    property var indicatorProperties: tileIndicatorProperties
                }
                property int index: sourceModelIndex
                property var indicatorProperties: tileIndicatorProperties

                onLoaded: {
                    if (item) {
                        item.quickTileMode = true;
                        item.expanded = true;
                        item.identifier = tileIdentifier;
                        if (tileIndicatorProperties) {
                            item.busName = tileIndicatorProperties.busName;
                            item.actionsObjectPath = tileIndicatorProperties.actionsObjectPath;
                            item.menuObjectPath = tileIndicatorProperties.menuObjectPath;
                        }
                    }
                }
            }

            Binding {
                target: qtDelegateLoader.item
                property: "selected"
                value: tileSelected
                when: qtDelegateLoader.item !== null
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (sourceModelIndex >= 0) {
                        if (qtDelegateLoader.item && typeof qtDelegateLoader.item.activateQuickTile === "function") {
                            qtDelegateLoader.item.activateQuickTile();
                        }
                        root.selectQuickTile(sourceModelIndex);
                    }
                }
            }
        }
    }

    states: [
        State {
            name: "initial"
            PropertyChanges { target: d; hasCommitted: false; restoreEntryValues: false }
        },
        State {
            name: "reveal"
            StateChangeScript {
                script: {
                    yVelocityCalculator.reset();
                    // initial item selection
                    if (!d.hasCommitted) bar.selectItemAt(d.rowMappedLateralPosition);
                    d.hasCommitted = false;
                }
            }
            PropertyChanges {
                target: bar
                expanded: !root.showQuickTiles
                // changes to lateral touch position effect which indicator is selected
                lateralPosition: d.rowMappedLateralPosition
                // vertical velocity determines if changes in lateral position has an effect
                enableLateralChanges: d.activeDragHandle &&
                                      !yVelocityCalculator.velocityAboveThreshold
            }
            // left scroll bar handling
            PropertyChanges {
                target: leftScroller
                lateralPosition: {
                    if (!d.activeDragHandle) return -1;
                    var mapped = d.activeDragHandle.mapToItem(leftScroller, d.activeDragHandle.touchPosition.x, 0);
                    return mapped.x;
                }
            }
            // right scroll bar handling
            PropertyChanges {
                target: rightScroller
                lateralPosition: {
                    if (!d.activeDragHandle) return -1;
                    var mapped = d.activeDragHandle.mapToItem(rightScroller, d.activeDragHandle.touchPosition.x, 0);
                    return mapped.x;
                }
            }
        },
        State {
            name: "locked"
            StateChangeScript {
                script: {
                    d.xDisplacementSinceLock = 0;
                    d.lastHideTouchX = hideDragHandle.touchPosition.x;
                }
            }
            PropertyChanges { target: bar; expanded: !root.showQuickTiles }
        },
        State {
            name: "commit"
            extend: "locked"
            PropertyChanges { target: root; focus: true }
            PropertyChanges { target: bar; interactive: true }
            PropertyChanges {
                target: d;
                hasCommitted: true
                lastHideTouchX: 0
                xDisplacementSinceLock: 0
                restoreEntryValues: false
            }
        }
    ]
    state: "initial"
}
