import QtQuick
import qs.services
import qs.modules.archeclipse.looks

Rectangle {
    id: root

    readonly property real pct: Battery.percentage
    readonly property bool present: Battery.available
    visible: present
    width: visible ? content.width + 8 : 0
    height: ArchTheme.barContentHeight
    radius: ArchTheme.radius
    color: hover.hovered ? ArchTheme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    HoverHandler {
        id: hover
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: ArchTheme.spacing

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const p = root.pct;
                if (Battery.isCharging)
                    return "\uF0E7";
                if (p > 0.9)
                    return "\uF240";
                if (p > 0.7)
                    return "\uF241";
                if (p > 0.5)
                    return "\uF242";
                if (p > 0.25)
                    return "\uF243";
                return "\uF244";
            }
            color: root.pct < 0.15 && !Battery.isCharging ? "#e06c75" : ArchTheme.fg
            font.family: ArchTheme.iconFamily
            font.pixelSize: ArchTheme.barContentHeight - 5
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.pct * 100) + "%"
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }
    }
}