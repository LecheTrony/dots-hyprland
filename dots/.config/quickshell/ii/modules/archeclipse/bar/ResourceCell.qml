import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.archeclipse.looks

// CPU / RAM / GPU horizontal bars, stacked (upstream ResourceMonitor). Bars
// stretch with the widget width; hovering pulses the system monitor island.
Item {
    id: root

    signal stateRequested(string state)

    width: 70
    implicitWidth: 70
    Layout.preferredWidth: 70
    height: ArchTheme.barContentHeight
    implicitHeight: ArchTheme.barContentHeight

    readonly property real cpuFrac: ResourceUsage.cpuUsage
    readonly property real ramFrac: ResourceUsage.memoryUsedPercentage
    readonly property real gpuFrac: ResourceUsage.gpuUsage ?? -1

    // (18px content - 2 * 3px spacing) / 3 = 4px per bar
    readonly property int barHeight: 4

    Timer {
        id: dwellTimer
        interval: ArchTheme.revealInPressure
        repeat: false
        onTriggered: root.stateRequested("system")
    }

    HoverHandler {
        id: rootHover
        onHoveredChanged: {
            if (rootHover.hovered) {
                if (ArchTheme.revealInPressure <= 0)
                    root.stateRequested("system");
                else
                    dwellTimer.restart();
            } else {
                dwellTimer.stop();
            }
        }
    }

    Column {
        id: stack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: [
                {
                    frac: root.cpuFrac,
                    color: ArchTheme.cpuColor,
                    tip: "CPU " + Math.round(root.cpuFrac * 100) + "%"
                },
                {
                    frac: root.ramFrac,
                    color: ArchTheme.ramColor,
                    tip: "RAM " + Math.round(root.ramFrac * 100) + "%"
                },
                {
                    frac: root.gpuFrac,
                    color: ArchTheme.gpuColor,
                    tip: "GPU " + (root.gpuFrac >= 0 ? Math.round(root.gpuFrac * 100) + "%" : "N/A")
                }
            ]

            Item {
                id: barItem
                required property var modelData
                // -1 = no data -> hide the bar
                readonly property real frac: modelData.frac
                visible: frac >= 0

                width: stack.width
                height: root.barHeight

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.15)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, barItem.frac))
                        height: parent.height
                        radius: parent.radius
                        color: barItem.modelData.color
                        Behavior on width {
                            NumberAnimation {
                                duration: ArchTheme.anim.fastEffects
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}
