pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.archeclipse.services
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// ArchEclipse bar. The layer surface spans the full monitor height so the
// side panels can stretch vertically, but only the pills and the edge hot
// zones are part of the mask, so clicks anywhere else fall through.
//
// The main pill is a compact, content-sized pill docked to the bar edge
// (outer corners square, inner corners rounded). When a side panel opens the
// pill is pushed off-center into the remaining free space instead of
// overlapping it.
Scope {
    id: bar

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: PanelWindow {
                id: panelWindow
                screen: barLoader.modelData

                readonly property string monitorName: Hyprland.monitorFor(screen)?.name ?? screen?.name ?? ""
                readonly property int screenHeight: (Hyprland.monitorFor(screen)?.height ?? screen?.height ?? 1080) | 0
                readonly property int barHeight: ArchTheme.barHeight
                readonly property bool atBottom: Config.options.bar.bottom

                anchors {
                    left: true
                    right: true
                    top: !panelWindow.atBottom
                    bottom: panelWindow.atBottom
                }

                // Search grabs the keyboard so typing goes to the island; every
                // other state stays on-demand so launched apps keep focus.
                WlrLayershell.keyboardFocus: panelWindow.state === "search" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
                WlrLayershell.exclusiveZone: Config.options.bar.autoHide.enable ? -1 : panelWindow.barHeight
                WlrLayershell.namespace: "quickshell:archeclipse:bar"
                color: "transparent"
                aboveWindows: true
                implicitHeight: panelWindow.screenHeight

                mask: Region {
                    item: pill
                    Region {
                        item: leftPill.visible ? leftPill : null
                    }
                    Region {
                        item: rightPill.visible ? rightPill : null
                    }
                    Region {
                        item: leftHot
                    }
                    Region {
                        item: rightHot
                    }
                }

                // ---- island state machine ----
                // Shared with every other monitor: several states can be
                // active at once and the pill shows the highest-priority
                // one. `left`/`right` are side overlays, independent of the
                // pill, so both can be open at the same time.
                readonly property string state: ArchBarState.state
                readonly property bool islandOpen: ArchBarState.islandOpen
                readonly property bool anyOpen: ArchBarState.anyOpen

                function activate(next, timeout) {
                    ArchBarState.activate(next, timeout);
                }
                function deactivate(next) {
                    ArchBarState.deactivate(next);
                }
                function toggle(next) {
                    ArchBarState.toggle(next);
                }

                readonly property bool leftLocked: ArchTheme.leftPanelLocked
                readonly property bool rightLocked: ArchTheme.rightPanelLocked

                Item {
                    id: stripRoot
                    anchors.fill: parent

                    // ===================== main pill =====================
                    Item {
                        id: pill
                        // side panels push the pill into the free space;
                        // only the pushes animate (pillX tracks them rigidly).
                        property real leftPush: leftPill.shown ? 8 + leftPill.width + 8 : 0
                        property real rightPush: rightPill.shown ? rightPill.width + 8 + 8 : 0
                        Behavior on leftPush {
                            NumberAnimation {
                                duration: ArchTheme.anim.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: ArchTheme.anim.emphasizedDecel
                            }
                        }
                        Behavior on rightPush {
                            NumberAnimation {
                                duration: ArchTheme.anim.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: ArchTheme.anim.emphasizedDecel
                            }
                        }
                        readonly property real pillX: {
                            const rightStart = rightPush > 0 ? stripRoot.width - 8 - rightPush : stripRoot.width;
                            return leftPush + Math.max(0, (rightStart - leftPush - pill.width) / 2);
                        }

                        x: pillX
                        y: panelWindow.atBottom ? stripRoot.height - height : 0
                        width: Math.max(100, stack.width + 10)
                        height: Math.max(panelWindow.barHeight, stack.height + 10)
                        property bool widthAnimReady: false
                        Component.onCompleted: widthAnimReady = true
                        Behavior on width {
                            enabled: pill.widthAnimReady
                            NumberAnimation {
                                duration: ArchTheme.anim.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: ArchTheme.anim.emphasized
                            }
                        }
                        // Shrink-only glide: while growing, the height tracks
                        // the unfolding content instead of chasing it.
                        Behavior on height {
                            enabled: pill.height > stack.height + 10
                            NumberAnimation {
                                duration: ArchTheme.anim.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: ArchTheme.anim.emphasized
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            topLeftRadius: panelWindow.atBottom ? ArchTheme.radius : 0
                            topRightRadius: panelWindow.atBottom ? ArchTheme.radius : 0
                            bottomLeftRadius: panelWindow.atBottom ? 0 : ArchTheme.radius
                            bottomRightRadius: panelWindow.atBottom ? 0 : ArchTheme.radius
                            color: ArchTheme.surface
                            border.width: 1
                            border.color: ArchTheme.border
                            clip: true
                        }

                        // ---- island stack (one beat, docked to the bar edge) ----
                        Item {
                            id: stack
                            anchors.top: panelWindow.atBottom ? undefined : parent.top
                            anchors.bottom: panelWindow.atBottom ? parent.bottom : undefined
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 5
                            anchors.bottomMargin: 5
                            width: pageLoader.item ? (pageLoader.item.implicitWidth > 0 ? pageLoader.item.implicitWidth : pageLoader.item.width) : 0
                            height: pageLoader.item ? (pageLoader.item.implicitHeight > 0 ? pageLoader.item.implicitHeight : pageLoader.item.height) : 0

                            Loader {
                                id: pageLoader
                                anchors.fill: parent
                                property string current: panelWindow.state
                                sourceComponent: {
                                    switch (pageLoader.current) {
                                    case "control":
                                        return controlComp;
                                    case "search":
                                        return searchComp;
                                    case "weather":
                                        return weatherComp;
                                    case "player":
                                        return playerComp;
                                    case "system":
                                        return systemComp;
                                    default:
                                        return defaultComp;
                                    }
                                }
                                onLoaded: {
                                    if (item && item["monitorName"] !== undefined)
                                        item.monitorName = panelWindow.monitorName;
                                }
                            }

                            Connections {
                                target: pageLoader.item
                                function onToggleControl() {
                                    panelWindow.toggle("control");
                                }
                                function onCloseRequested() {
                                    panelWindow.deactivate(pageLoader.current);
                                }
                                function onStateRequested(target) {
                                    panelWindow.activate(target);
                                }
                            }

                            HoverHandler {
                                id: stackHover
                                enabled: panelWindow.islandOpen
                                onHoveredChanged: {
                                    if (stackHover.hovered)
                                        leaveTimer.stop();
                                    else
                                        leaveTimer.restart();
                                }
                            }
                            Timer {
                                id: leaveTimer
                                interval: ArchTheme.revealOutPressure
                                onTriggered: {
                                    if (!stackHover.hovered && ArchBarState.popupCount === 0)
                                        panelWindow.deactivate(panelWindow.state);
                                }
                            }
                        }
                    }

                    // ===================== left side panel =====================
                    Item {
                        id: leftPill
                        x: 8
                        y: panelWindow.atBottom ? stripRoot.height - height : 0
                        width: ArchTheme.leftPanelWidth
                        height: Math.max(400, panelWindow.screenHeight - 15)
                        property bool shown: false
                        property bool flag: ArchBarState.leftOpen
                        onFlagChanged: leftPill.setShown(leftPill.flag)
                        Component.onCompleted: leftPill.setShown(leftPill.flag)
                        property real openT: 0
                        function setShown(open) {
                            if (open) {
                                leftCloseTimer.stop();
                                leftIsland.cancelPendingHide();
                                leftPill.shown = true;
                                leftPill.openT = 1;
                            } else {
                                if (!leftPill.shown)
                                    return;
                                leftPill.openT = 0;
                                leftCloseTimer.restart();
                            }
                        }
                        Timer {
                            id: leftCloseTimer
                            interval: ArchTheme.anim.normal
                            onTriggered: leftPill.shown = false
                        }
                        IslandExpandClip {
                            expand: leftPill.openT
                            contentHeight: leftPill.height
                            anchors.top: parent.top
                            Rectangle {
                                color: ArchTheme.surface
                                width: parent.width
                                height: leftPill.height
                                topLeftRadius: 0
                                bottomLeftRadius: 0
                                topRightRadius: panelWindow.atBottom ? 0 : ArchTheme.radius
                                bottomRightRadius: panelWindow.atBottom ? 0 : ArchTheme.radius
                                border.width: 1
                                border.color: ArchTheme.border
                                clip: true
                                LeftIsland {
                                    id: leftIsland
                                    anchors.fill: parent
                                    monitorName: panelWindow.monitorName
                                    screenHeight: panelWindow.screenHeight
                                    onCloseRequested: panelWindow.deactivate("left")
                                }
                            }
                        }
                    }

                    // ===================== right side panel =====================
                    Item {
                        id: rightPill
                        x: stripRoot.width - width - 8
                        y: panelWindow.atBottom ? stripRoot.height - height : 0
                        width: ArchTheme.rightPanelWidth
                        height: Math.max(400, panelWindow.screenHeight - 15)
                        property bool shown: false
                        property bool flag: ArchBarState.rightOpen
                        onFlagChanged: rightPill.setShown(rightPill.flag)
                        Component.onCompleted: rightPill.setShown(rightPill.flag)
                        property real openT: 0
                        function setShown(open) {
                            if (open) {
                                rightCloseTimer.stop();
                                rightIsland.cancelPendingHide();
                                rightPill.shown = true;
                                rightPill.openT = 1;
                            } else {
                                if (!rightPill.shown)
                                    return;
                                rightPill.openT = 0;
                                rightCloseTimer.restart();
                            }
                        }
                        Timer {
                            id: rightCloseTimer
                            interval: ArchTheme.anim.normal
                            onTriggered: rightPill.shown = false
                        }
                        IslandExpandClip {
                            expand: rightPill.openT
                            contentHeight: rightPill.height
                            anchors.top: parent.top
                            Rectangle {
                                color: ArchTheme.surface
                                width: parent.width
                                height: rightPill.height
                                topRightRadius: 0
                                bottomRightRadius: 0
                                topLeftRadius: panelWindow.atBottom ? 0 : ArchTheme.radius
                                bottomLeftRadius: panelWindow.atBottom ? 0 : ArchTheme.radius
                                border.width: 1
                                border.color: ArchTheme.border
                                clip: true
                                RightIsland {
                                    id: rightIsland
                                    anchors.fill: parent
                                    monitorName: panelWindow.monitorName
                                    screenHeight: panelWindow.screenHeight
                                    onCloseRequested: panelWindow.deactivate("right")
                                }
                            }
                        }
                    }

                    // ===================== reveal hot zones =====================
                    HotZone {
                        id: leftHot
                        side: "left"
                        size: 5
                        hotZoneEnabled: ArchTheme.leftPanelHotZone
                        panelLock: panelWindow.leftLocked
                    }
                    HotZone {
                        id: rightHot
                        side: "right"
                        size: 5
                        hotZoneEnabled: ArchTheme.rightPanelHotZone
                        panelLock: panelWindow.rightLocked
                    }

                    Connections {
                        target: leftHot
                        function onRevealRequested() {
                            panelWindow.activate("left");
                        }
                    }
                    Connections {
                        target: rightHot
                        function onRevealRequested() {
                            panelWindow.activate("right");
                        }
                    }
                }

                Shortcut {
                    sequence: Qt.Key_Escape
                    enabled: panelWindow.anyOpen
                    onActivated: {
                        // Side panels first: they are overlays, the pill
                        // island stays as it is.
                        if (ArchBarState.leftOpen)
                            panelWindow.deactivate("left");
                        else if (ArchBarState.rightOpen)
                            panelWindow.deactivate("right");
                        else
                            panelWindow.deactivate(panelWindow.state);
                    }
                }

                // Search shortcuts. Only one bar instance is active per
                // monitor and the panel family is exclusive, so registration
                // stays scoped to the loaded family.
                GlobalShortcut {
                    name: "searchToggleRelease"
                    description: "Archeclipse: toggle search island"
                    onPressed: panelWindow.toggle("search")
                }
                GlobalShortcut {
                    name: "searchToggleReleaseInterrupt"
                    description: "Archeclipse: toggle search island (interrupt)"
                    onPressed: panelWindow.toggle("search")
                }
                GlobalShortcut {
                    name: "archToggleLeftPanel"
                    description: "Archeclipse: toggle left side panel"
                    onPressed: panelWindow.toggle("left")
                }
                GlobalShortcut {
                    name: "archToggleRightPanel"
                    description: "Archeclipse: toggle right side panel"
                    onPressed: panelWindow.toggle("right")
                }

                Component {
                    id: defaultComp
                    DefaultBar {}
                }

                Component {
                    id: controlComp
                    ControlIsland {
                        monitorName: panelWindow.monitorName
                    }
                }
                Component {
                    id: searchComp
                    SearchIsland {
                        monitorName: panelWindow.monitorName
                    }
                }
                Component {
                    id: weatherComp
                    WeatherIsland {}
                }
                Component {
                    id: playerComp
                    PlayerIsland {}
                }
                Component {
                    id: systemComp
                    SystemMonitorIsland {}
                }
            }
        }
    }
}
