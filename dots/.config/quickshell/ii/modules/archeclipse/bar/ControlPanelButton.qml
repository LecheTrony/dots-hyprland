import QtQuick
import qs.modules.archeclipse.looks

Rectangle {
    id: root

    signal toggleControl()

    width: 32
    height: ArchTheme.barContentHeight
    radius: ArchTheme.radius
    color: mouse.containsMouse ? ArchTheme.surfaceHover : "transparent"

    Text {
        anchors.centerIn: parent
        text: "\uF303"
        color: ArchTheme.fg
        font.family: ArchTheme.iconFamily
        font.pixelSize: ArchTheme.fontSize + 2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleControl()
    }
}