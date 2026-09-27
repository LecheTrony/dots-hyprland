import QtQuick
import Quickshell
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Toggles one of the slide-out side panels (left apps / right status).
Item {
    id: root

    required property string iconText
    property bool open: false

    signal toggleRequest()

    width: 22
    height: ArchTheme.barContentHeight

    Rectangle {
        anchors.fill: parent
        radius: ArchTheme.radius
        color: root.open || hoverHandler.hovered ? ArchTheme.surfaceActive : "transparent"
        border.width: root.open ? 1 : 0
        border.color: ArchTheme.border

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.iconText
            iconSize: 14
            color: root.open ? ArchTheme.accent : hoverHandler.hovered ? ArchTheme.fg : ArchTheme.fgDim
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        onTapped: root.toggleRequest()
    }
}
