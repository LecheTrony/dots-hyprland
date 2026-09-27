import QtQuick
import QtQuick.Layouts
import qs.services
import Quickshell
import qs.modules.common
import qs.modules.archeclipse.looks

// System monitor island: CPU / RAM / GPU / swap / uptime rows with the same
// hue coding as the bar cells, plus the hostname line.
Item {
    id: root

    signal closeRequested()

    width: 300
    height: content.implicitHeight

    Column {
        id: content
        width: parent.width
        spacing: ArchTheme.spacing

        Text {
            text: Quickshell.env("HOSTNAME") ?? "localhost"
            color: ArchTheme.accent
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }

        component MeterRow: Column {
            id: meter
            property string label: ""
            property real frac: 0
            property string tip: ""
            property color color: "transparent"
            spacing: 3
            width: parent ? parent.width : 0

            RowLayout {
                width: parent.width
                Text {
                    text: meter.label
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: meter.tip
                    color: ArchTheme.fgDim
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                }
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.12)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, meter.frac))
                    height: parent.height
                    radius: parent.radius
                    color: meter.color
                    Behavior on width {
                        NumberAnimation {
                            duration: ArchTheme.anim.normal
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        MeterRow {
            label: Translation.tr("CPU")
            frac: ResourceUsage.cpuUsage
            tip: Math.round(ResourceUsage.cpuUsage * 100) + "%"
            color: ArchTheme.cpuColor
        }
        MeterRow {
            label: Translation.tr("Memory")
            frac: ResourceUsage.memoryUsedPercentage
            tip: Math.round(ResourceUsage.memoryUsed) + " / " + Math.round(ResourceUsage.memoryTotal) + " MB"
            color: ArchTheme.ramColor
        }
        MeterRow {
            label: Translation.tr("Swap")
            frac: ResourceUsage.swapUsedPercentage
            tip: Math.round(ResourceUsage.swapUsed) + " / " + Math.round(ResourceUsage.swapTotal) + " MB"
            color: ArchTheme.accent
        }
        MeterRow {
            label: Translation.tr("GPU")
            frac: ResourceUsage.gpuUsage ?? 0
            visible: (ResourceUsage.gpuUsage ?? -1) >= 0
            tip: Math.round((ResourceUsage.gpuUsage ?? 0) * 100) + "%"
            color: ArchTheme.gpuColor
        }

        Rectangle {
            width: parent.width
            height: 1
            color: ArchTheme.border
        }

        Text {
            text: Translation.tr("Uptime %1").arg(DateTime.uptime)
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSizeSmall
        }
    }
}
