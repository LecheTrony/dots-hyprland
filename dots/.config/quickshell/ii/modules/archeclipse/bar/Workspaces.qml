import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.archeclipse.looks

// Thin workspace strip: 10 bars + a slimmer special slot in the middle.
// Empty slots are greyed, occupied are lit, the focused one uses the accent.
// Hovering (or a workspace change) temporarily expands the strip to reveal
// each slot's biggest-window app icon, then collapses after peekDuration.
Item {
    id: root

    property int count: 10
    property real barHeight: 4
    property real iconSize: 16
    property real btnSpacing: 4
    property real hitHeight: 6
    property real expandedHeight: 32
    property int peekDuration: 2000
    property real specialRatio: 0.55

    property bool expanded: false
    property bool hoverPeek: false
    property bool _ready: false
    readonly property bool showIcons: root.expanded || root.hoverPeek

    implicitHeight: showIcons ? expandedHeight : hitHeight
    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Timer {
        id: readyTimer
        interval: 400
        onTriggered: root._ready = true
    }
    Component.onCompleted: readyTimer.start()

    function requestExpand() {
        if (!root._ready)
            return;
        root.expanded = true;
        peekTimer.restart();
    }

    HoverHandler {
        id: stripHover
        onHoveredChanged: {
            if (stripHover.hovered) {
                if (root._ready)
                    root.hoverPeek = true;
            } else {
                root.hoverPeek = false;
            }
        }
    }

    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    onFocusedIdChanged: root.requestExpand()
    Timer {
        id: peekTimer
        interval: root.peekDuration
        onTriggered: root.expanded = false
    }

    readonly property var wsData: {
        Hyprland.toplevels.values;
        Hyprland.workspaces.values;
        const out = [];
        for (let i = 1; i <= root.count; i++) {
            const tops = Hyprland.toplevels.values.filter(t => (t.workspace?.id ?? -1) === i);
            out.push({
                id: i,
                occupied: tops.length > 0,
                icon: tops.length > 0 ? root.iconGlyphFor(tops[0].lastIpcObject?.class ?? tops[0].class ?? "") : ""
            });
        }
        return out;
    }

    function iconGlyphFor(cls) {
        const c = (cls || "").toLowerCase();
        if (c.includes("firefox") || c.includes("zen") || c.includes("chromium") || c.includes("brave"))
            return "\uF356";
        if (c.includes("code") || c.includes("cursor") || c.includes("vim") || c.includes("neovim"))
            return "\uF109";
        if (c.includes("discord") || c.includes("telegram") || c.includes("whatsapp") || c.includes("slack") || c.includes("vesktop"))
            return "\uF3FE";
        if (c.includes("spotify") || c.includes("vlc") || c.includes("strawberry") || c.includes("audacious"))
            return "\uF001";
        if (c.includes("kitty") || c.includes("alacritty") || c.includes("foot") || c.includes("wezterm") || c.includes("konsole") || c.includes("ghostty"))
            return "\uF41A";
        if (c.includes("file") || c.includes("nautilus") || c.includes("dolphin") || c.includes("thunar"))
            return "\uF290";
        if (c.includes("obsidian") || c.includes("libreoffice") || c.includes("notion"))
            return "\uF319";
        if (c.includes("gimp") || c.includes("blender") || c.includes("inkscape") || c.includes("obs"))
            return "\uF54B";
        return "\uF7D0";
    }

    // new-client blink: 3 blinks on unfocused workspaces
    property var _counts: ({})
    property bool _countsInit: false
    property var blinking: ({})
    property bool blinkPhase: true
    readonly property var clientCounts: {
        Hyprland.toplevels.values;
        const m = {};
        for (let i = 1; i <= root.count; i++)
            m[i] = 0;
        for (const t of Hyprland.toplevels.values) {
            const id = t.workspace?.id ?? -1;
            if (id >= 1 && id <= root.count)
                m[id]++;
        }
        return m;
    }
    onClientCountsChanged: {
        const cur = root.clientCounts;
        if (!root._countsInit) {
            root._counts = Object.assign({}, cur);
            root._countsInit = true;
            return;
        }
        const prev = root._counts;
        const nb = Object.assign({}, root.blinking);
        let touch = false;
        for (let i = 1; i <= root.count; i++) {
            const o = prev[i] ?? 0, n = cur[i] ?? 0;
            if (n > o && i !== root.focusedId) {
                nb[i] = 6;
                touch = true;
                root.requestExpand();
            } else if (i === root.focusedId && nb[i] !== undefined) {
                delete nb[i];
                touch = true;
            }
        }
        root._counts = Object.assign({}, cur);
        if (touch)
            root.blinking = nb;
    }
    Timer {
        id: blinkTimer
        interval: 220
        repeat: true
        running: Object.keys(root.blinking).length > 0
        onTriggered: {
            root.blinkPhase = !root.blinkPhase;
            const nb = {};
            for (const k in root.blinking) {
                const r = root.blinking[k] - 1;
                if (r > 0)
                    nb[k] = r;
            }
            root.blinking = nb;
        }
    }

    readonly property var specialTops: {
        Hyprland.toplevels.values;
        Hyprland.workspaces.values;
        return Hyprland.toplevels.values.filter(t => ((t.workspace?.name ?? "") + "").startsWith("special"));
    }
    readonly property var specialWs: {
        Hyprland.workspaces.values;
        const found = Hyprland.workspaces.values.find(w => ((w.name ?? "") + "").startsWith("special"));
        return found ?? null;
    }
    readonly property bool specialOccupied: root.specialTops.length > 0
    readonly property bool specialActive: root.specialWs?.active ?? false
    readonly property bool specialFocusedHere: ((Hyprland.focusedWorkspace?.name ?? "") + "").startsWith("special")
    readonly property bool specialHasFocus: ((Hyprland.activeToplevel?.workspace?.name ?? "") + "").startsWith("special")
    readonly property bool specialOpen: root.specialActive || root.specialFocusedHere || root.specialHasFocus
    onSpecialOpenChanged: {
        if (root.specialOpen)
            root.requestExpand();
    }

    Component {
        id: wsSlot
        Item {
            id: slot
            property int wsId: modelData
            readonly property bool focused: root.focusedId === wsId
            readonly property bool occupied: root.wsData[wsId - 1]?.occupied ?? false
            readonly property bool alerting: root.blinking[wsId] !== undefined
            readonly property string iconText: root.wsData[wsId - 1]?.icon ?? ""

            width: strip.normalW
            height: strip.height

            Column {
                anchors.centerIn: parent
                spacing: 2

                Item {
                    width: slot.width
                    height: root.showIcons ? root.iconSize + 2 : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: slot.iconText
                        color: slot.alerting ? ArchTheme.accent : (slot.focused || slot.occupied) ? ArchTheme.fg : ArchTheme.muted
                        opacity: root.showIcons ? (slot.alerting ? (root.blinkPhase ? 1.0 : 0.15) : ((slot.focused || slot.occupied) ? 1.0 : 0.35)) : 0
                        font.family: ArchTheme.iconFamily
                        font.pixelSize: root.iconSize

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }

                Rectangle {
                    id: bar
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: slot.width
                    height: root.barHeight
                    radius: root.barHeight / 2
                    color: slot.alerting ? ArchTheme.accent : slot.focused ? ArchTheme.accent : slot.occupied ? ArchTheme.fg : ArchTheme.muted
                    opacity: slot.alerting ? (root.blinkPhase ? 1.0 : 0.15) : (slot.focused || slot.occupied) ? 1.0 : 0.35

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({workspace=${slot.wsId}})`)
                onWheel: wheel => {
                    if (wheel.angleDelta.y < 0)
                        Hyprland.dispatch(`hl.dsp.focus({workspace="r+1"})`);
                    else if (wheel.angleDelta.y > 0)
                        Hyprland.dispatch(`hl.dsp.focus({workspace="r-1"})`);
                }
            }
        }
    }

    Row {
        id: strip
        anchors.fill: parent
        spacing: root.btnSpacing
        readonly property real normalW: Math.max(0, (strip.width - root.btnSpacing * root.count) / (root.count + root.specialRatio))
        readonly property real specialW: strip.normalW * root.specialRatio

        Repeater {
            model: [1, 2, 3, 4, 5]
            delegate: wsSlot
        }

        // special workspace slot: middle, narrower, standout
        Item {
            id: specialSlot
            width: strip.specialW
            height: strip.height

            Column {
                anchors.centerIn: parent
                spacing: 2

                Item {
                    width: specialSlot.width
                    height: root.showIcons ? root.iconSize + 2 : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.specialOccupied ? root.iconGlyphFor(root.specialTops[0].lastIpcObject?.class ?? root.specialTops[0].class ?? "") : "\uF069"
                        color: ArchTheme.accent
                        opacity: root.showIcons ? (root.specialOpen ? 1.0 : root.specialOccupied ? 0.9 : 0.55) : 0
                        font.family: ArchTheme.iconFamily
                        font.pixelSize: root.iconSize

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: specialSlot.width
                    height: root.barHeight + 1
                    radius: (root.barHeight + 1) / 2
                    color: ArchTheme.accent
                    opacity: root.specialOpen ? 1.0 : root.specialOccupied ? 0.8 : 0.45
                    border.color: ArchTheme.accent
                    border.width: root.specialOpen ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("hl.dsp.workspace.toggle_special()")
            }
        }

        Repeater {
            model: [6, 7, 8, 9, 10]
            delegate: wsSlot
        }
    }
}