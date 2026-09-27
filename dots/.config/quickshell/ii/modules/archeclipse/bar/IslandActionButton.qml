import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Compact icon + label action used in the quick-settings island footer.
Item {
    id: root

    required property string iconText
    property string label: ""
    property bool highlighted: false

    signal clicked()

    Layout.fillWidth: true
    height: 30

    Rectangle {
        anchors.fill: parent
        radius: ArchTheme.radius
        color: root.highlighted || hoverHandler.hovered ? ArchTheme.surfaceActive : ArchTheme.surface
        border.width: 1
        border.color: hoverHandler.hovered ? ArchTheme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Row {
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconText
                iconSize: 13
                color: hoverHandler.hovered ? ArchTheme.accent : ArchTheme.muted
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.label !== ""
                text: root.label
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize - 1
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
