import QtQuick
import QtQuick.Controls
import qs.services
import qs.modules.archeclipse.looks

Rectangle {
    id: root

    property string monitorName: ""
    width: content.width
    height: ArchTheme.barContentHeight
    radius: ArchTheme.radius
    color: hover.hovered || sliderRevealed ? ArchTheme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    readonly property var screenMonitor: Brightness.monitors.find(m => m.screen?.name === root.monitorName) ?? Brightness.monitors[0]
    readonly property real level: screenMonitor?.multipliedBrightness ?? 0
    readonly property string glyph: {
        const b = root.level;
        if (b > 0.75)
            return "\uF00E0";
        if (b > 0.5)
            return "\uF00DF";
        return "\uF00DE";
    }

    property bool sliderRevealed: false
    property bool keepOpen: false
    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: {
            if (!root.keepOpen)
                root.sliderRevealed = false;
        }
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: ArchTheme.spacing

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: ArchTheme.fg
            font.family: ArchTheme.iconFamily
            font.pixelSize: ArchTheme.barContentHeight - 4
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.level * 100) + "%"
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }

        Slider {
            id: slider
            visible: root.sliderRevealed
            width: 90
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            from: 0
            to: 1
            stepSize: 0.01
            Component.onCompleted: slider.value = root.level
            onMoved: screenMonitor?.setBrightness(slider.value)
            Binding {
                target: slider
                property: "value"
                value: root.level
                when: !slider.pressed
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: {
            root.sliderRevealed = !root.sliderRevealed;
            if (root.sliderRevealed)
                hideTimer.restart();
        }
        onWheel: wheel => {
            if (!screenMonitor)
                return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            screenMonitor.setBrightness(Math.max(0, Math.min(1, screenMonitor.multipliedBrightness + step)));
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hover.hovered) {
                root.keepOpen = true;
                hideTimer.stop();
            } else {
                root.keepOpen = false;
                hideTimer.restart();
            }
        }
    }
}