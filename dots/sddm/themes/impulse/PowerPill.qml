import QtQuick 2.15

Rectangle {
    id: pill
    property string text: ""
    property color accent: "#66C2FF"
    signal clicked()

    width: pillLabel.implicitWidth + 34
    height: 36
    radius: 18
    color: pillMouse.pressed ? Qt.rgba(accent.r, accent.g, accent.b, 0.28)
                             : Qt.rgba(1, 1, 1, 0.055)
    border.width: 1
    border.color: pillMouse.pressed ? accent : Qt.rgba(1, 1, 1, 0.14)

    Text {
        id: pillLabel
        anchors.centerIn: parent
        color: pillMouse.pressed ? "#FFFFFF" : Qt.rgba(0.93, 0.95, 1.0, 0.78)
        font.family: "monospace"
        font.pixelSize: 12
        font.letterSpacing: 1
        text: pill.text
    }
    MouseArea {
        id: pillMouse
        anchors.fill: parent
        onClicked: pill.clicked()
    }
}