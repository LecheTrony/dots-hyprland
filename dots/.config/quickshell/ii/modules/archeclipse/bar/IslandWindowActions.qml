import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.archeclipse.looks

// Shared bottom window-action cluster for the left/right side panels: expand,
// shrink, lock (pins the panel open) and close. The side drives the min/max
// panel width and the lock state.
Column {
    id: root

    property string side: "left"
    readonly property bool isLeft: side === "left"
    readonly property bool locked: isLeft ? ArchTheme.leftPanelLocked : ArchTheme.rightPanelLocked

    signal closeRequested()

    spacing: 4

    Item {
        width: 1
        height: 8
    }

    component ActionRow: Rectangle {
        id: row
        property string glyph: ""
        property string tooltip: ""
        property bool toggle: false
        property bool checked: false
        property color hoverFg: ArchTheme.accent
        // Tracked explicitly: the child handler id is not reliably visible
        // from the component's own bindings in this engine.
        property bool hovered: false
        signal triggered()
        width: parent.width
        height: 28
        radius: ArchTheme.chipRadius
        color: row.hovered ? ArchTheme.surfaceHover : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: ArchTheme.anim.fastEffects
            }
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: ArchTheme.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: row.glyph
            color: row.hovered ? row.hoverFg : (row.checked ? ArchTheme.accent : ArchTheme.fgDim)
            font.family: ArchTheme.fontFamily
            font.pixelSize: 14
        }
        HoverHandler {
            onHoveredChanged: row.hovered = hovered
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.triggered()
        }
    }

    ActionRow {
        glyph: "+"
        tooltip: "Expand"
        onTriggered: {
            if (root.isLeft)
                ArchTheme.leftPanelWidth = Math.min(1500, ArchTheme.leftPanelWidth + 50);
            else
                ArchTheme.rightPanelWidth = Math.min(1500, ArchTheme.rightPanelWidth + 50);
        }
    }
    ActionRow {
        glyph: "−"
        tooltip: "Shrink"
        onTriggered: {
            if (root.isLeft)
                ArchTheme.leftPanelWidth = Math.max(400, ArchTheme.leftPanelWidth - 50);
            else
                ArchTheme.rightPanelWidth = Math.max(250, ArchTheme.rightPanelWidth - 50);
        }
    }
    ActionRow {
        glyph: root.locked ? "󰒥" : "󰒣"
        tooltip: root.locked ? "Unlock" : "Lock"
        checked: root.locked
        onTriggered: {
            if (root.isLeft)
                ArchTheme.leftPanelLocked = !ArchTheme.leftPanelLocked;
            else
                ArchTheme.rightPanelLocked = !ArchTheme.rightPanelLocked;
        }
    }
    ActionRow {
        glyph: "✕"
        tooltip: "Close"
        hoverFg: ArchTheme.danger
        onTriggered: root.closeRequested()
    }
}
