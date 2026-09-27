import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Volume card of the control island: Output/Input switch, device picker and
// the live per-application streams for that direction, each with its own
// slider and mute toggle (upstream VolumeSection, on the ii Audio service).
Item {
    id: root

    width: parent ? parent.width : 0
    implicitHeight: card.implicitHeight

    property bool isSink: true
    // Popup-style device list, opened by the swap button.
    property bool deviceListOpen: false

    readonly property var defaultDevice: root.isSink ? Audio.sink : Audio.source
    readonly property var devices: root.isSink ? Audio.outputDevices : Audio.inputDevices
    readonly property var streams: root.isSink ? Audio.outputAppNodes : Audio.inputAppNodes
    readonly property real deviceCount: root.devices.length

    function deviceLabel(node) {
        if (!node)
            return Translation.tr("No device");
        return Audio.friendlyDeviceName(node);
    }

    function streamTitle(node) {
        try {
            return Audio.appNodeDisplayName(node) || node.description || node.name;
        } catch (e) {
            return node ? node.name : "";
        }
    }

    function streamIcon(node) {
        try {
            const icon = node.iconName;
            if (icon)
                return Quickshell.iconPath(icon, true);
        } catch (e) {}
        return "";
    }

    function setVolume(node, value) {
        if (!node || !node.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(Audio.hardMaxValue, value));
    }

    function toggleMute(node) {
        if (!node || !node.audio)
            return;
        node.audio.mute = !node.audio.mute;
    }

    function pickDevice(node) {
        if (!node)
            return;
        if (root.isSink)
            Audio.setDefaultSink(node);
        else
            Audio.setDefaultSource(node);
        root.deviceListOpen = false;
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: body.implicitHeight + 20
        radius: ArchTheme.radius
        color: ArchTheme.surfaceHover
        border.width: 1
        border.color: ArchTheme.border
    }

    ColumnLayout {
        id: body
        anchors.fill: card
        anchors.margins: 10
        spacing: 8

        // ---- header: direction switch + current device ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Output / Input segmented switch
            Rectangle {
                Layout.preferredHeight: 22
                implicitWidth: segRow.implicitWidth + 8
                radius: 4
                color: ArchTheme.surface
                border.width: 1
                border.color: ArchTheme.border

                Row {
                    id: segRow
                    anchors.centerIn: parent
                    spacing: 2

                    component SegButton: Rectangle {
                        id: segBtn
                        required property string label
                        required property bool selected
                        signal picked()
                        width: segLabel.implicitWidth + 12
                        height: 18
                        radius: 3
                        color: segBtn.selected ? ArchTheme.accent : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Text {
                            id: segLabel
                            anchors.centerIn: parent
                            text: segBtn.label
                            color: segBtn.selected ? ArchTheme.bg : ArchTheme.muted
                            font.family: ArchTheme.fontFamily
                            font.pixelSize: ArchTheme.fontSize - 2
                        }

                        TapHandler {
                            onTapped: segBtn.picked()
                        }
                    }

                    SegButton {
                        label: Translation.tr("Out")
                        selected: root.isSink
                        onPicked: {
                            root.isSink = true;
                            root.deviceListOpen = false;
                        }
                    }
                    SegButton {
                        label: Translation.tr("In")
                        selected: !root.isSink
                        onPicked: {
                            root.isSink = false;
                            root.deviceListOpen = false;
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.deviceLabel(root.defaultDevice)
                elide: Text.ElideRight
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }

            IconActionButton {
                icon: (root.defaultDevice?.audio?.mute ?? false) ? "volume_off" : (root.isSink ? "volume_up" : "mic")
                tooltip: Translation.tr("Mute")
                active: root.defaultDevice?.audio?.mute ?? false
                onClicked: root.toggleMute(root.defaultDevice)
            }

            IconActionButton {
                icon: "swap_vert"
                tooltip: Translation.tr("Select device")
                active: root.deviceListOpen
                enabled: root.deviceCount > 0
                onClicked: root.deviceListOpen = !root.deviceListOpen
            }
        }

        // ---- device list: in-flow so it is never clipped ----
        Rectangle {
            id: deviceList
            Layout.fillWidth: true
            Layout.preferredHeight: root.deviceListOpen && root.deviceCount > 0 ? Math.min(132, root.deviceCount * 26 + 6) : 0
            visible: Layout.preferredHeight > 0
            clip: true
            radius: 6
            color: ArchTheme.surface
            border.width: 1
            border.color: ArchTheme.border

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: ArchTheme.anim.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: ArchTheme.anim.emphasizedDecel
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 2

                Repeater {
                    model: root.devices
                    delegate: Rectangle {
                        id: deviceRow
                        required property var modelData
                        readonly property bool current: deviceRow.modelData === root.defaultDevice
                        width: deviceList.width - 6
                        height: 24
                        radius: 4
                        color: deviceRow.current ? ArchTheme.surfaceHover : deviceTap.containsMouse ? ArchTheme.surface : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            spacing: 6

                            MaterialSymbol {
                                text: root.isSink ? "speaker" : "mic"
                                iconSize: ArchTheme.fontSize - 2
                                color: deviceRow.current ? ArchTheme.accent : ArchTheme.muted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                width: parent.width - 22
                                text: root.deviceLabel(deviceRow.modelData)
                                elide: Text.ElideRight
                                color: deviceRow.current ? ArchTheme.accent : ArchTheme.fg
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSize - 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: deviceTap
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pickDevice(deviceRow.modelData)
                        }
                    }
                }
            }
        }

        // ---- master slider ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.defaultDevice !== null && root.defaultDevice !== undefined

            MaterialSymbol {
                text: (root.defaultDevice?.audio?.mute ?? false) ? "volume_off" : "volume_down"
                iconSize: ArchTheme.fontSize - 2
                color: ArchTheme.muted
            }

            Slider {
                id: masterSlider
                Layout.fillWidth: true
                from: 0
                to: Audio.hardMaxValue
                stepSize: 0.01
                live: true
                value: root.defaultDevice?.audio?.volume ?? 0
                onMoved: root.setVolume(root.defaultDevice, value)

                background: Rectangle {
                    x: masterSlider.leftPadding
                    y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                    width: masterSlider.availableWidth
                    height: 4
                    radius: 2
                    color: ArchTheme.border
                }
                handle: Rectangle {
                    x: masterSlider.leftPadding + masterSlider.visualPosition * (masterSlider.availableWidth - width)
                    y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: masterSlider.pressed ? ArchTheme.accent : ArchTheme.fg
                }
            }

            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Math.round((root.defaultDevice?.audio?.volume ?? 0) * 100) + "%"
                color: ArchTheme.muted
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize - 2
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: ArchTheme.border
            visible: root.streams.length > 0
        }

        // ---- per-application streams ----
        Flickable {
            id: streamFlick
            Layout.fillWidth: true
            Layout.preferredHeight: root.streams.length > 0 ? Math.min(122, root.streams.length * 30 - 4) : 0
            visible: root.streams.length > 0
            clip: true
            contentWidth: width
            contentHeight: streamColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: streamColumn
                width: streamFlick.width
                spacing: 2

                Repeater {
                    model: root.streams
                    delegate: Item {
                        id: streamRow
                        required property var modelData
                        width: streamFlick.width
                        height: 28
                        readonly property var streamAudio: streamRow.modelData.audio ?? null
                        readonly property bool muted: streamRow.streamAudio ? (streamRow.streamAudio.mute ?? false) : false

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            IconImage {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                source: root.streamIcon(streamRow.modelData)
                                asynchronous: true
                                mipmap: true
                            }

                            Text {
                                Layout.preferredWidth: 92
                                text: root.streamTitle(streamRow.modelData)
                                elide: Text.ElideRight
                                color: ArchTheme.fg
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSize - 1
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: Audio.hardMaxValue
                                stepSize: 0.01
                                live: true
                                value: streamRow.streamAudio ? (streamRow.streamAudio.volume ?? 0) : 0
                                onMoved: root.setVolume(streamRow.modelData, value)

                                background: Rectangle {
                                    x: parent.leftPadding
                                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                    width: parent.availableWidth
                                    height: 3
                                    radius: 1.5
                                    color: ArchTheme.border
                                }
                                handle: Rectangle {
                                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: parent.pressed ? ArchTheme.accent : ArchTheme.fg
                                }
                            }

                            IconActionButton {
                                icon: streamRow.muted ? "volume_off" : "volume_up"
                                tooltip: Translation.tr("Mute")
                                active: streamRow.muted
                                onClicked: root.toggleMute(streamRow.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
