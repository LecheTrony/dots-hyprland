import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Bar content, upstream layout: weather + resource bars on the left, the
// center pill holds bandwidth | control | clock, and the right side starts
// with the media pill followed by battery/brightness/volume/tray. The
// workspace strip sits at the very bottom of the pill.
Column {
    id: root

    signal toggleControl()
    signal stateRequested(string state)
    signal closeRequested()

    property string monitorName: ""

    spacing: 4
    width: implicitWidth

    Item {
        id: topRow
        // Both side zones count as wide as the wider one, so the centered
        // pill always keeps Theme.spacing clearance from either side.
        readonly property real leftMinWidth: weatherCell.implicitWidth + ArchTheme.spacing + resourceCell.implicitWidth
        readonly property real rightMinWidth: utilities.implicitWidth
        readonly property real sideWidth: Math.max(leftMinWidth, rightMinWidth)
        implicitWidth: 2 * sideWidth + centerPill.width + ArchTheme.spacing * 2
        width: implicitWidth
        height: ArchTheme.barContentHeight

        // ---- center pill: bandwidth | control | clock ----
        Rectangle {
            id: centerPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: centerRow.implicitWidth + 20
            height: ArchTheme.barContentHeight
            radius: ArchTheme.radius
            color: ArchTheme.surfaceActive

            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: ArchTheme.spacing
                height: parent.height
                // Equal-width side cells keep the control button dead-center
                // even when bandwidth and clock widths differ.
                readonly property real sideCellWidth: Math.max(bandwidthCell.implicitWidth, clockItem.width)

                Item {
                    width: centerRow.sideCellWidth
                    height: parent.height
                    BandwidthCell {
                        id: bandwidthCell
                        anchors.centerIn: parent
                    }
                }

                ControlPanelButton {
                    id: centerButton
                    anchors.verticalCenter: parent.verticalCenter
                    onToggleControl: root.toggleControl()
                }

                Item {
                    width: centerRow.sideCellWidth
                    height: parent.height
                    Clock {
                        id: clockItem
                        anchors.centerIn: parent
                        hoverColor: "transparent"
                    }
                }
            }
        }

        // ---- left zone: resource bars + weather ----
        Item {
            id: leftZone
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: topRow.sideWidth
            height: parent.height

            RowLayout {
                anchors.fill: parent
                spacing: ArchTheme.spacing

                ResourceCell {
                    id: resourceCell
                    Layout.fillWidth: true
                    onStateRequested: state => root.stateRequested(state)
                }
                WeatherCell {
                    id: weatherCell
                    Layout.fillWidth: true
                    onStateRequested: state => root.stateRequested(state)
                }
            }
        }

        // ---- right zone: media pill, battery, brightness, volume, tray ----
        Item {
            id: rightZone
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: topRow.sideWidth
            height: parent.height

            Row {
                id: utilities
                spacing: ArchTheme.spacing
                height: parent.height
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                PlayerPill {
                    id: playerPill
                    anchors.verticalCenter: parent.verticalCenter
                    onStateRequested: state => root.stateRequested(state)
                }
                Battery {
                    anchors.verticalCenter: parent.verticalCenter
                }
                Brightness {
                    monitorName: root.monitorName
                    anchors.verticalCenter: parent.verticalCenter
                }
                Volume {
                    monitorName: root.monitorName
                    anchors.verticalCenter: parent.verticalCenter
                }
                Tray {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ---- workspace strip: full width of the bar content ----
    Workspaces {
        id: bottomStrip
        width: topRow.implicitWidth
    }
}
