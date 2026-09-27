import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

// LeftIsland: the widget stack with a per-widget enable rail, living in the
// left side pill beside the bar (ArchBarState.leftOpen).
//
// Same lifecycle as upstream: pinned by the bar (leftLocked), closed by Escape,
// IPC, the close button, or one hover-out pressure after the cursor leaves.
// The rail toggles which cards are shown; the order and enable state persist
// in config.json under arch.leftWidgets. Tabs mirror the upstream left panel
// (user/apps, keybinds, scripts) minus the booru/chat/manga/donations tabs.
Item {
    id: root

    signal closeRequested()

    property string monitorName: ""
    property int screenHeight: 1080
    readonly property string side: "left"
    readonly property bool locked: ArchTheme.leftPanelLocked

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
        { name: "Profile", icon: "account_circle", enabled: true },
        { name: "Apps", icon: "apps", enabled: true },
        { name: "KeyBinds", icon: "keyboard", enabled: true },
        { name: "Scripts", icon: "terminal", enabled: false },
        { name: "Settings", icon: "settings", enabled: true }
    ]

    property var _widgets: null

    readonly property var widgets: {
        if (root._widgets)
            return root._widgets;
        const stored = Config.options?.arch?.leftWidgets;
        if (!Array.isArray(stored) || stored.length === 0)
            return root.defaultWidgets;
        // Any widget added to defaultWidgets later (Settings) is appended to
        // an older stored list instead of being lost.
        const known = new Set(stored.map((w) => w && w.name));
        const merged = stored.slice();
        for (const fallback of root.defaultWidgets) {
            if (!known.has(fallback.name))
                merged.push(Object.assign({}, fallback));
        }
        return merged;
    }

    readonly property var enabledWidgets: root.widgets.filter(w => w.enabled)

    function persist(list) {
        root._widgets = list;
        Config.setNestedValue("arch.leftWidgets", JSON.stringify(list));
    }

    function toggleWidget(index) {
        const list = root.widgets.slice();
        list[index] = Object.assign({}, list[index], { enabled: !list[index].enabled });
        persist(list);
    }

    property int _focusAttempt: 0

    function focusSettings() {
        root._focusAttempt = 0;
        if (!root.focusWidget("Settings"))
            focusRetry.restart();
    }

    function focusSettingsAttempt() {
        root._focusAttempt += 1;
        if (root.focusWidget("Settings") || root._focusAttempt >= 6)
            return;
        focusRetry.restart();
    }

    // Scrolls the card stack to `name`; used by the bar settings button.
    function focusWidget(name) {
        const index = root.enabledWidgets.findIndex((w) => w.name === name);
        if (index < 0)
            return false;
        const delegate = cardRepeater.itemAt(index);
        if (!delegate)
            return false;
        const target = Math.max(0, Math.min(
            contentScroll.contentHeight - contentScroll.height,
            delegate.y - contentScroll.contentY));
        contentScroll.contentY = target;
        return true;
    }

    function moveWidget(from, to) {
        if (to < 0 || to >= root.widgets.length || to === from)
            return;
        const list = root.widgets.slice();
        const [item] = list.splice(from, 1);
        list.splice(to, 0, item);
        persist(list);
    }

    // ---- app launcher data (upstream UserProfile / launcher tabs) ----
    readonly property var entries: DesktopEntries.applications.values
    readonly property var filteredApps: {
        const list = [];
        for (const e of root.entries) {
            if (!e || e.noDisplay === true || e.hidden === true)
                continue;
            list.push(e);
        }
        return list;
    }

    property list<QtObject> toggles: [
        NetworkToggle {},
        BluetoothToggle {},
        DarkModeToggle {},
        NightLightToggle {},
        PowerProfilesToggle {},
        NotificationToggle {},
        MicToggle {},
        ScreenSnipToggle {}
    ]

    function runScript(command) {
        if (!command)
            return;
        Quickshell.execDetached(["bash", "-lc", command]);
    }

    Component.onCompleted: ArchBarState._leftIslandDiag = () => JSON.stringify({
        widgets: root.enabledWidgets.map((w) => w.name),
        contentHeight: Math.round(contentScroll.contentHeight),
        viewport: Math.round(contentScroll.height),
        contentY: Math.round(contentScroll.contentY),
        settingsVisible: root.enabledWidgets.some((w) => w.name === "Settings")
    })

    Connections {
        target: ArchBarState
        function onSettingsRequested() {
            root.focusSettings();
        }
    }

    Timer {
        id: focusRetry
        interval: 120
        onTriggered: root.focusSettingsAttempt()
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

        // ---- enable rail ----
        Item {
            Layout.preferredWidth: 34
            Layout.fillHeight: true

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

            IslandWindowActions {
                anchors.bottom: settingsBtn.bottom
                anchors.bottomMargin: ArchTheme.spacing
                width: 34
                side: "left"
                onCloseRequested: root.closeRequested()
            }

            SettingsButton {
                id: settingsBtn
                anchors.bottom: parent.bottom
                width: 34
            }
        }

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
                    id: cardRepeater
                    model: root.enabledWidgets

                    delegate: Rectangle {
                        id: cardShell
                        required property var modelData
                        width: contentColumn.width
                        height: cardBody.implicitHeight + 16
                        radius: ArchTheme.cardRadius
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
                            spacing: 6

                            // ---------- profile ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: cardShell.modelData.name === "Profile"

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        radius: 17
                                        color: ArchTheme.surfaceActive
                                        border.width: 1
                                        border.color: ArchTheme.border

                                        Text {
                                            anchors.centerIn: parent
                                            text: (SystemInfo.username || Quickshell.env("USER") || "?").substring(0, 1).toUpperCase()
                                            color: ArchTheme.accent
                                            font.family: ArchTheme.fontFamily
                                            font.pixelSize: ArchTheme.fontSizeLarge
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            Layout.fillWidth: true
                                            text: SystemInfo.username || Quickshell.env("USER") || "user"
                                            elide: Text.ElideRight
                                            color: ArchTheme.fg
                                            font.family: ArchTheme.fontFamily
                                            font.pixelSize: ArchTheme.fontSize
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: (SystemInfo.distroName || "") + " · " + (SystemInfo.desktopEnvironment || "")
                                            elide: Text.ElideRight
                                            color: ArchTheme.muted
                                            font.family: ArchTheme.fontFamily
                                            font.pixelSize: ArchTheme.fontSizeCaption
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: ArchTheme.border
                                }

                                // quick toggles
                                Grid {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: ArchTheme.spacing / 2
                                    rowSpacing: ArchTheme.spacing / 2

                                    Repeater {
                                        model: root.toggles
                                        delegate: Rectangle {
                                            id: toggleTile
                                            required property var modelData
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 30
                                            radius: ArchTheme.chipRadius
                                            color: toggleTile.modelData?.toggled ? ArchTheme.surfaceActive : toggleHover.hovered ? ArchTheme.surfaceHover : "transparent"
                                            border.width: 1
                                            border.color: toggleTile.modelData?.toggled ? ArchTheme.border : "transparent"

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }

                                            Row {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.right: parent.right
                                                anchors.rightMargin: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6

                                                MaterialSymbol {
                                                    width: 14
                                                    text: toggleTile.modelData?.icon ?? ""
                                                    iconSize: ArchTheme.fontSize - 1
                                                    color: toggleTile.modelData?.toggled ? ArchTheme.accent : ArchTheme.muted
                                                }
                                                Text {
                                                    width: parent.width - 20
                                                    text: toggleTile.modelData?.statusText || toggleTile.modelData?.name || ""
                                                    elide: Text.ElideRight
                                                    color: toggleTile.modelData?.available === false ? ArchTheme.muted : ArchTheme.fg
                                                    font.family: ArchTheme.fontFamily
                                                    font.pixelSize: ArchTheme.fontSizeCaption
                                                }
                                            }

                                            HoverHandler {
                                                id: toggleHover
                                            }
                                            TapHandler {
                                                onTapped: {
                                                    if (toggleTile.modelData?.available !== false)
                                                        toggleTile.modelData?.mainAction?.();
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Uptime") + ": " + DateTime.uptime + "   ·   " + Translation.tr("Memory") + ": " + Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                                    color: ArchTheme.muted
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeBadge
                                }
                            }

                            // ---------- apps ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                visible: cardShell.modelData.name === "Apps"

                                Text {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Applications")
                                    color: ArchTheme.muted
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeCaption
                                }

                                Flickable {
                                    id: appFlick
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 260
                                    clip: true
                                    contentWidth: width
                                    contentHeight: appGrid.implicitHeight
                                    boundsBehavior: Flickable.StopAtBounds

                                    Grid {
                                        id: appGrid
                                        width: appFlick.width
                                        columns: 4
                                        columnSpacing: ArchTheme.spacing / 2
                                        rowSpacing: ArchTheme.spacing / 2

                                        Repeater {
                                            model: root.filteredApps
                                            delegate: AppTile {
                                                required property var modelData
                                                entry: modelData
                                                width: (appGrid.width - appGrid.columnSpacing * 3) / 4
                                            }
                                        }
                                    }
                                }
                            }

                            // ---------- keybinds ----------
                            KeyBindsCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 420
                                visible: cardShell.modelData.name === "KeyBinds"
                            }

                            // ---------- settings ----------
                            SettingsCard {
                                Layout.fillWidth: true
                                visible: cardShell.modelData.name === "Settings"
                            }

                            // ---------- scripts ----------
                            ScriptsCard {
                                id: scriptCard
                                Layout.fillWidth: true
                                Layout.preferredHeight: 200
                                visible: cardShell.modelData.name === "Scripts"
                                onRequestRun: command => root.runScript(command)
                                onRequestRemove: index => scriptCard.removeAt(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
