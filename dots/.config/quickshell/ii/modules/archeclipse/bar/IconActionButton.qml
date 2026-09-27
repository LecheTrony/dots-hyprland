import QtQuick
import Quickshell
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Small square icon-only action (upstream AppButton shape): optional
// tooltip, `active` state for toggles, hover/press feedback.
Item {
    id: root

    required property string icon
    property string tooltip: ""
    property bool active: false
    // `enabled` is already an Item property, so interaction is gated with this.
    property bool actionEnabled: true
    enabled: root.actionEnabled

    signal clicked()

    implicitWidth: 22
    implicitHeight: 22
    opacity: root.actionEnabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.active ? ArchTheme.surfaceActive : tapHandler.pressed ? ArchTheme.surface : "transparent"
        border.width: 1
        border.color: root.active ? ArchTheme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.icon
        iconSize: ArchTheme.fontSize
        color: !root.actionEnabled ? ArchTheme.muted : root.active ? ArchTheme.accent : hoverHandler.hovered ? ArchTheme.accent : ArchTheme.muted
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.actionEnabled
    }

    TapHandler {
        id: tapHandler
        enabled: root.actionEnabled
        onTapped: root.clicked()
    }

    // Tooltip: plain bubble above the button, no external dependency.
    Item {
        id: tip
        visible: root.tooltip !== "" && hoverHandler.hovered
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        z: 50
        width: tipText.implicitWidth + 10
        height: tipText.implicitHeight + 6

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: ArchTheme.surfaceActive
            border.width: 1
            border.color: ArchTheme.border
        }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.tooltip
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize - 2
        }
    }
}
