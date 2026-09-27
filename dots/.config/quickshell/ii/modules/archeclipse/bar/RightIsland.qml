import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

// RightIsland: the widget stack with a per-widget enable rail, living in the
// right side pill beside the bar (ArchBarState.rightOpen).
//
// Same lifecycle as upstream: the panel is pinned by the bar (leftLocked /
// rightLocked), closes on Escape, IPC, the close button, or one hover-out
// pressure after the cursor leaves. The rail toggles which cards are shown
// and the choice is persisted in config.json under arch.rightWidgets.
Item {
    id: root

    signal closeRequested()

    property string monitorName: ""
    property int screenHeight: 1080
    readonly property string side: "right"
    readonly property bool locked: ArchTheme.rightPanelLocked

    // Hover tracking on a stable container, lock pins the panel open.
    HoverHandler {
        id: islandHover
        onHoveredChanged: {
            if (islandHover.hovered) {
                leaveTimer.stop();
                ArchBarState.activate(root.side, 0);
            } else {
                root.requestAutoHide();
            }
        }
    }

    function requestAutoHide() {
        if (root.locked || islandHover.hovered)
            return;
        leaveTimer.restart();
    }

    function cancelPendingHide() {
        leaveTimer.stop();
    }

    Timer {
        id: leaveTimer
        interval: ArchTheme.revealOutPressure
        onTriggered: {
            if (!root.locked && !islandHover.hovered && ArchBarState.popupCount === 0)
                root.closeRequested();
        }
    }

    // ---- widget registry: order + enable state, persisted in config.json ----
    readonly property var defaultWidgets: [
        { name: "Calendar", icon: "calendar_month", enabled: true },
        { name: "Tasks", icon: "view_carousel", enabled: true },
        { name: "Notifications", icon: "notifications", enabled: true },
        { name: "Resources", icon: "monitor_heart", enabled: true },
        { name: "Focus", icon: "timer", enabled: false }
    ]

    property var _widgets: null

    readonly property var widgets: {
        if (root._widgets)
            return root._widgets;
        const stored = Config.options?.arch?.rightWidgets;
        if (Array.isArray(stored) && stored.length > 0)
            return stored;
        return root.defaultWidgets;
    }

    readonly property var enabledWidgets: root.widgets.filter(w => w.enabled)

    function persist(list) {
        root._widgets = list;
        Config.setNestedValue("arch.rightWidgets", JSON.stringify(list));
    }

    function toggleWidget(index) {
        const list = root.widgets.slice();
        list[index] = Object.assign({}, list[index], { enabled: !list[index].enabled });
        persist(list);
    }

    // Reorder is resolved on release: the rail is a positioner, so the target
    // slot comes from the drag delta, not the absolute y.
    function moveWidget(from, to) {
        if (to < 0 || to >= root.widgets.length || to === from)
            return;
        const list = root.widgets.slice();
        const [item] = list.splice(from, 1);
        list.splice(to, 0, item);
        persist(list);
    }

    Rectangle {
        anchors.fill: parent
        radius: ArchTheme.radius
        color: ArchTheme.surface
        border.width: 1
        border.color: ArchTheme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: ArchTheme.spacing
        spacing: ArchTheme.spacing

        // ---- card stack ----
        Flickable {
            id: contentScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: contentColumn.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentColumn
                width: contentScroll.width
                spacing: ArchTheme.spacing

                Repeater {
                    model: root.enabledWidgets

                    delegate: Rectangle {
                        id: cardShell
                        required property var modelData
                        width: contentColumn.width
                        height: cardBody.implicitHeight + 16
                        radius: ArchTheme.cardRadius
                        // Upstream cards are frameless (RightPanelCard); a
                        // hairline keeps the stack readable on the pill.
                        color: "transparent"
                        border.width: 1
                        border.color: ArchTheme.border

                        opacity: 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        Component.onCompleted: opacity = 1

                        ColumnLayout {
                            id: cardBody
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            // card header: name + count badge
                            RowLayout {
                                Layout.fillWidth: true
                                visible: cardShell.modelData.name !== "Calendar" && cardShell.modelData.name !== "Focus"

                                MaterialSymbol {
                                    text: cardShell.modelData.icon
                                    iconSize: ArchTheme.fontSize - 1
                                    color: ArchTheme.muted
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: cardShell.modelData.name
                                    color: ArchTheme.muted
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeBadge
                                }
                            }

                            CalendarCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 190
                                visible: cardShell.modelData.name === "Calendar"
                            }
                            WindowCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 210
                                visible: cardShell.modelData.name === "Tasks"
                            }
                            NotificationCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 190
                                visible: cardShell.modelData.name === "Notifications"
                            }
                            ResourceCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150
                                visible: cardShell.modelData.name === "Resources"
                            }
                            TimerCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 90
                                visible: cardShell.modelData.name === "Focus"
                            }
                        }
                    }
                }
                }
            }
        // ---- enable rail (right edge, mirroring the left island) ----
        Item {
            Layout.preferredWidth: 34
            Layout.fillHeight: true

            // Plain Column on purpose: the positioner owns absolute y, so the
            // drag delta is the only thing the reorder maths needs.
            Column {
                id: railList
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4

                Repeater {
                    model: root.widgets

                    delegate: Item {
                        id: railItem
                        required property var modelData
                        required property int index
                        width: 34
                        height: 30
                        // Set on release after a real drag so the trailing
                        // click does not toggle the widget.
                        property bool suppressClick: false
                        property real dragStartY: 0
                        readonly property bool dragging: Math.abs(y - dragStartY) > 0.5

                        MouseArea {
                            id: railMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeVerCursor
                            drag.axis: Drag.YAxis
                            drag.target: railItem
                            drag.minimumY: -railItem.index * 34
                            drag.maximumY: (root.widgets.length - 1 - railItem.index) * 34

                            onPressed: railItem.dragStartY = railItem.y
                            onReleased: {
                                if (railItem.dragging) {
                                    // 30px cell + 4px spacing = 34px pitch.
                                    const to = Math.max(0, Math.min(root.widgets.length - 1, railItem.index + Math.round((railItem.y - railItem.dragStartY) / 34)));
                                    if (to !== railItem.index) {
                                        railItem.suppressClick = true;
                                        root.moveWidget(railItem.index, to);
                                    }
                                    railItem.x = 0;
                                    railItem.y = 0;
                                }
                            }
                            onClicked: {
                                if (railItem.suppressClick) {
                                    railItem.suppressClick = false;
                                    return;
                                }
                                root.toggleWidget(railItem.index);
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: railItem.modelData.enabled ? ArchTheme.surfaceActive : railMouse.containsMouse ? ArchTheme.surfaceHover : "transparent"
                            border.width: 1
                            border.color: railItem.modelData.enabled ? ArchTheme.border : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: railItem.modelData.icon
                            iconSize: ArchTheme.fontSize
                            color: railItem.modelData.enabled ? ArchTheme.accent : ArchTheme.muted
                        }
                    }
                }
            }

            // window actions pinned above the settings button
            IslandWindowActions {
                anchors.bottom: settingsBtn.bottom
                anchors.bottomMargin: ArchTheme.spacing
                width: 34
                side: "right"
                onCloseRequested: root.closeRequested()
            }

            SettingsButton {
                id: settingsBtn
                anchors.bottom: parent.bottom
                width: 34
            }
        }
    }
}
