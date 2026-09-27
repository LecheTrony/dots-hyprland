import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// System resources card: CPU / RAM / swap with sparkline history and host
// details, on the ii ResourceUsage + SystemInfo services.
Item {
    id: root

    readonly property var host: Quickshell.env("HOSTNAME") ?? "localhost"

    // Sparkline as a normalised polyline (0..1), drawn by the delegate.
    function history(points) {
        if (!points || points.length < 2)
            return [];
        const max = Math.max(...points, 0.0001);
        return points.map(p => Math.max(0, Math.min(1, p / max)));
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        ColumnLayout {
            spacing: 6

            MetricRow {
                label: "cpu"
                value: ResourceUsage.cpuUsage
                total: 1
                detail: "CPU"
                tone: ArchTheme.accent
                points: ResourceUsage.cpuUsageHistory
            }

            MetricRow {
                label: "memory"
                value: ResourceUsage.memoryUsedPercentage
                total: 1
                detail: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed) + " / " + ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
                tone: ArchTheme.color6
                points: ResourceUsage.memoryUsageHistory
            }

            MetricRow {
                label: "swap"
                value: ResourceUsage.swapUsedPercentage
                total: 1
                detail: ResourceUsage.kbToGbString(ResourceUsage.swapUsed) + " / " + ResourceUsage.kbToGbString(ResourceUsage.swapTotal)
                tone: ArchTheme.color4
                points: ResourceUsage.swapUsageHistory
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 1

            Rectangle {
                anchors.fill: parent
                color: ArchTheme.border
            }
        }

        Text {
            Layout.fillWidth: true
            text: SystemInfo.username + " \u00b7 " + SystemInfo.distroName
            color: ArchTheme.fgDim
            elide: Text.ElideRight
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSizeCaption
        }

        component MetricRow: ColumnLayout {
            id: metric
            property string label: ""
            property real value: 0
            property real total: 0
            property string detail: ""
            property color tone: ArchTheme.accent
            property var points: []

            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: metric.label
                    iconSize: ArchTheme.fontSize
                    color: metric.tone
                }
                Text {
                    Layout.fillWidth: true
                    text: metric.detail
                    color: ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                }
                Text {
                    text: Math.round(metric.value * 100) + "%"
                    color: metric.tone
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                }
            }

            // bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 1.5
                color: ArchTheme.border

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, metric.total > 0 ? metric.value / metric.total : metric.value))
                    height: parent.height
                    radius: 1.5
                    color: metric.tone

                    Behavior on width {
                        NumberAnimation {
                            duration: ArchTheme.anim.fastEffects
                        }
                    }
                }
            }

            // sparkline
            Canvas {
                id: chart
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                visible: metric.points && metric.points.length > 1
                // The service mutates its history arrays in place, so the
                // sparkline is repainted on a slow tick instead of a binding.
                onWidthChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const pts = root.history(metric.points);
                    if (pts.length < 2)
                        return;
                    ctx.strokeStyle = metric.tone;
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    for (let i = 0; i < pts.length; i++) {
                        const x = (i / (pts.length - 1)) * width;
                        const y = height - pts[i] * height;
                        if (i === 0)
                            ctx.moveTo(x, y);
                        else
                            ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }

                Timer {
                    interval: 700
                    running: chart.visible
                    repeat: true
                    onTriggered: chart.requestPaint()
                }
            }
        }
    }
}
