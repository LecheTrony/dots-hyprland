pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Sidebar entry for the waffle settings window. Ported from the iNiR
// reference: rounded tile with the Win11 selection pill on the leading edge.
Button {
    id: root

    property string navIcon: ""
    property bool selected: false
    property bool expanded: true

    implicitHeight: Looks.dp(44)
    implicitWidth: expanded ? Looks.dp(210) : Looks.dp(48)

    background: Rectangle {
        radius: Looks.settings.radiusLarge
        color: {
            if (root.selected)
                return Looks.colors.selection
            if (root.down)
                return Looks.settings.tilePressed
            if (root.hovered)
                return Looks.settings.tileHover
            return "transparent"
        }
        scale: root.down ? 0.96 : 1.0

        Rectangle {
            visible: root.selected
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: Looks.dp(3.5)
            height: root.down ? Looks.dp(8) : Looks.dp(20)
            radius: Looks.dp(2)
            color: Looks.colors.accent

            Behavior on height {
                NumberAnimation { duration: 90; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.easeInOut }
            }
        }

        Behavior on color {
            ColorAnimation { duration: 70 }
        }
        Behavior on scale {
            NumberAnimation { duration: 40; easing.type: Easing.OutQuad }
        }
    }

    contentItem: RowLayout {
        spacing: root.expanded ? Looks.dp(12) : 0

        Rectangle {
            implicitWidth: Looks.dp(28)
            implicitHeight: Looks.dp(28)
            radius: Looks.settings.radiusLarge
            Layout.leftMargin: root.expanded ? Looks.dp(12) : 0
            Layout.fillWidth: !root.expanded
            Layout.alignment: root.expanded ? Qt.AlignVCenter : Qt.AlignCenter

            color: root.selected
                ? Looks.colors.accent
                : (root.hovered ? Looks.colors.selection : Looks.settings.tile)

            Behavior on color {
                ColorAnimation { duration: 70 }
            }

            FluentIcon {
                anchors.centerIn: parent
                icon: root.navIcon
                implicitSize: Looks.dp(16)
                color: root.selected
                    ? Looks.colors.accentFg
                    : (root.hovered ? Looks.colors.accent : Looks.colors.fg)
            }
        }

        WText {
            visible: root.expanded
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: Looks.font.pixelSize.large
            font.weight: root.selected ? Looks.font.weight.strong : Looks.font.weight.regular
            color: Looks.colors.fg
            opacity: root.selected ? 1 : (root.hovered ? 0.95 : 0.78)
            elide: Text.ElideRight
        }
    }

    WToolTip {
        visible: !root.expanded && root.hovered
        text: root.text
    }
}
