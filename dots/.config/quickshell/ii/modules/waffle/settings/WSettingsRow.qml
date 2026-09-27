pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Single settings row: optional icon tile, label + description on the left and
// a slotted control on the right. Ported from the iNiR reference with the
// settings-search registration stripped (the search registry does not exist in
// this config); the row is still clickable for switch-style rows.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string description: ""
    property alias control: controlLoader.sourceComponent
    property bool clickable: false
    property bool showChevron: false

    readonly property color rowHover: Looks.settings.tileHover
    readonly property color rowPressed: Looks.settings.tilePressed
    readonly property color rowTile: Looks.settings.tile

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(Looks.dp(52), contentRow.implicitHeight + Looks.dp(20))

    function flash() {
        highlightAnim.restart();
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.leftMargin: Looks.dp(2)
        anchors.rightMargin: Looks.dp(2)
        radius: Looks.settings.radiusLarge
        color: {
            if (root.clickable && mouseArea.pressed)
                return root.rowPressed
            if (mouseArea.containsMouse)
                return root.rowHover
            return "transparent"
        }
        scale: root.clickable && mouseArea.pressed ? 0.985 : 1.0

        Behavior on color {
            ColorAnimation { duration: 70 }
        }
        Behavior on scale {
            NumberAnimation { duration: 40; easing.type: Easing.OutQuad }
        }
    }

    Rectangle {
        id: highlightOverlay
        anchors.fill: parent
        radius: Looks.settings.radiusLarge
        color: Looks.colors.accent
        opacity: 0
    }

    SequentialAnimation {
        id: highlightAnim
        NumberAnimation { target: highlightOverlay; property: "opacity"; to: 0.18; duration: 200; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 600 }
        NumberAnimation { target: highlightOverlay; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InCubic }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.clickable) root.clicked()
    }

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            leftMargin: Looks.dp(12)
            rightMargin: Looks.dp(12)
        }
        spacing: Looks.dp(10)

        Rectangle {
            visible: root.icon !== ""
            implicitWidth: Looks.dp(30)
            implicitHeight: Looks.dp(30)
            radius: Looks.settings.radiusLarge
            color: mouseArea.containsMouse ? Looks.colors.selection : root.rowTile
            border.width: 1
            border.color: mouseArea.containsMouse ? Looks.colors.accent : Looks.settings.stroke
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            FluentIcon {
                anchors.centerIn: parent
                icon: root.icon
                implicitSize: Looks.dp(16)
                color: mouseArea.containsMouse ? Looks.colors.accent : Looks.colors.subfg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Looks.dp(2)

            WText {
                Layout.fillWidth: true
                text: root.label
                font.pixelSize: Looks.font.pixelSize.normal
                elide: Text.ElideRight
            }

            WText {
                visible: root.description !== ""
                Layout.fillWidth: true
                text: root.description
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
                lineHeight: 1.2
            }
        }

        Loader {
            id: controlLoader
            Layout.alignment: Qt.AlignVCenter
        }

        FluentIcon {
            visible: root.showChevron
            icon: "chevron-right"
            implicitSize: Looks.dp(14)
            color: Looks.colors.subfg
            opacity: 0.7
        }
    }
}
