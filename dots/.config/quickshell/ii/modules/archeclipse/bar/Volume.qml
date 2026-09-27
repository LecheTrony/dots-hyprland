import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
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

    readonly property var sink: Audio.sink
    readonly property real value: sink?.audio?.volume ?? 0

    // Browse the per-screen monitor so the brightness slider follows the
    // right screen (Volume.qml hosts it for the reveal slider row).
    readonly property var screenMonitor: Brightness.monitors.find(m => m.screen?.name === root.monitorName) ?? Brightness.monitors[0]
    readonly property real brightness: screenMonitor?.multipliedBrightness ?? 0
    readonly property string brightnessIcon: {
        const b = screenMonitor?.multipliedBrightness ?? 0;
        if (b <= 0)
            return "brightness_empty";
        if (b <= 0.5)
            return "brightness_low";
        if (b <= 0.75)
            return "brightness_medium";
        return "brightness_high";
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

    function volumeIcon() {
        const v = root.value;
        const muted = sink?.audio?.muted ?? false;
        if (muted || v <= 0.01)
            return ArchTheme.iconFamily === "" ? "" : "\uF6A8"; // volume muted glyph
        return v > 0.65 ? "\uF6A9" : v > 0.25 ? "\uF6AA" : "\uF6AB";
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: ArchTheme.spacing

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: labelRow.implicitWidth
            height: labelRow.implicitHeight

            Row {
                id: labelRow
                spacing: ArchTheme.spacing

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volumeIcon()
                    color: sink?.audio?.muted ? ArchTheme.muted : ArchTheme.fg
                    font.family: ArchTheme.iconFamily
                    font.pixelSize: ArchTheme.barContentHeight - 5
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.value * 100) + "%"
                    color: ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        Audio.toggleMute();
                    } else {
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
                onWheel: wheel => {
                    if (!root.sink?.audio)
                        return;
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    root.sink.audio.volume = Math.max(0, Math.min(1, root.value + step));
                }
            }
        }

        Slider {
            id: slider
            visible: root.sliderRevealed
            width: 90
            anchors.verticalCenter: parent.verticalCenter
            height: 16
            from: 0
            to: 1
            stepSize: 0.01
            Component.onCompleted: slider.value = root.value
            onMoved: if (root.sink?.audio)
                root.sink.audio.volume = slider.value
            Binding {
                target: slider
                property: "value"
                value: root.value
                when: !slider.pressed
            }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hover.hovered) {
                root.keepOpen = true;
                root.sliderRevealed = true;
                hideTimer.stop();
            } else {
                root.keepOpen = false;
                hideTimer.restart();
            }
        }
    }
}