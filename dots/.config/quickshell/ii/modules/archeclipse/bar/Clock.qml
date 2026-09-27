import QtQuick
import qs.services
import qs.modules.archeclipse.looks

// Clock cell: time, expanding to the full date on hover (upstream parity).
// Click cycles between 24h and 12h formats.
Rectangle {
    id: root

    property string hoverColor: ArchTheme.surfaceHover

    width: row.implicitWidth + 8
    height: ArchTheme.barContentHeight
    radius: ArchTheme.radius
    color: hover.hovered ? root.hoverColor : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: ArchTheme.anim.fastEffects
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale().toString(DateTime.clock.date, ArchTheme.dateFormat)
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }

        Item {
            id: dateClip
            anchors.verticalCenter: parent.verticalCenter
            width: hover.hovered ? dateText.implicitWidth : 0
            height: dateText.implicitHeight
            clip: true
            visible: width > 0

            Behavior on width {
                NumberAnimation {
                    duration: ArchTheme.anim.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: ArchTheme.anim.standardDecel
                }
            }

            Text {
                id: dateText
                anchors.verticalCenter: parent.verticalCenter
                text: DateTime.longDate
                color: ArchTheme.muted
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ArchTheme.cycleDateFormat()
    }
}
