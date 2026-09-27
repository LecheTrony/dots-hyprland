import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Connectivity card: Wi-Fi toggle, scan, per-network connect list with inline
// password prompt, plus the Bluetooth device list (upstream ConnectivitySection
// on the ii Network / BluetoothStatus services).
Item {
    id: root

    width: parent ? parent.width : 0
    implicitHeight: card.implicitHeight + 20

    // Network list is only materialised when the user asks for it.
    property bool networksOpen: false
    property var passwordTarget: null
    property string passwordText: ""

    readonly property var networks: Network.friendlyWifiNetworks
    readonly property var btDevices: {
        const connected = BluetoothStatus.connectedDevices ?? [];
        const paired = BluetoothStatus.pairedButNotConnectedDevices ?? [];
        return connected.concat(paired);
    }

    function signalIcon(strength) {
        if (strength >= 80)
            return "signal_wifi_4";
        if (strength >= 55)
            return "signal_wifi_3";
        if (strength >= 30)
            return "signal_wifi_2";
        return "signal_wifi_1";
    }

    function connect(ap) {
        if (!ap)
            return;
        if (ap.active) {
            Network.disconnectWifiNetwork();
            return;
        }
        if (ap.isSecure) {
            root.passwordTarget = ap;
            root.passwordText = "";
            return;
        }
        Network.connectToWifiNetwork(ap);
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: body.implicitHeight + 20
        radius: ArchTheme.cardRadius
        color: ArchTheme.surface

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 10
            spacing: ArchTheme.spacing

            // ================= wifi =================
            RowLayout {
                Layout.fillWidth: true
                spacing: ArchTheme.spacing

                MaterialSymbol {
                    text: !Network.wifiEnabled ? "wifi_off" : Network.networkName ? signalIcon(Network.networkStrength) : "wifi"
                    iconSize: 16
                    color: Network.wifiEnabled ? ArchTheme.accent : ArchTheme.fgDim
                }

                Text {
                    Layout.fillWidth: true
                    text: Network.networkName ? Network.networkName : (Network.wifiEnabled ? Translation.tr("Disconnected") : Translation.tr("Wi-Fi off"))
                    elide: Text.ElideRight
                    color: Network.wifiEnabled ? ArchTheme.fg : ArchTheme.fgDim
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                }

                IconActionButton {
                    icon: Network.wifiScanning ? "progress_activity" : "refresh"
                    tooltip: Translation.tr("Rescan")
                    active: Network.wifiScanning
                    actionEnabled: Network.wifiEnabled
                    onClicked: Network.rescanWifi()
                }

                IconActionButton {
                    icon: "network_wifi"
                    tooltip: Translation.tr("Networks")
                    active: root.networksOpen
                    actionEnabled: Network.wifiEnabled
                    onClicked: {
                        root.networksOpen = !root.networksOpen;
                        root.passwordTarget = null;
                    }
                }

                IconActionButton {
                    icon: "wifi"
                    tooltip: Network.wifiEnabled ? Translation.tr("Disable Wi-Fi") : Translation.tr("Enable Wi-Fi")
                    active: Network.wifiEnabled
                    onClicked: Network.toggleWifi()
                }
            }

            // ---- network list ----
            Flickable {
                id: netFlick
                Layout.fillWidth: true
                Layout.preferredHeight: root.networksOpen && root.networks.length > 0 ? Math.min(124, root.networks.length * 28 - 4) : 0
                visible: Layout.preferredHeight > 0
                clip: true
                contentWidth: width
                contentHeight: netColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: ArchTheme.anim.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: ArchTheme.anim.emphasizedDecel
                    }
                }

                Column {
                    id: netColumn
                    width: netFlick.width
                    spacing: 2

                    Repeater {
                        model: root.networks
                        delegate: Item {
                            id: netRow
                            required property var modelData
                            readonly property var ap: netRow.modelData
                            width: netFlick.width
                            height: 26

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: netRow.ap.active ? ArchTheme.surfaceHover : netTap.containsMouse ? ArchTheme.surface : "transparent"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 8

                                MaterialSymbol {
                                    text: netRow.ap.isSecure ? "lock" : "lock_open"
                                    iconSize: ArchTheme.fontSize - 3
                                    color: ArchTheme.muted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: netRow.ap.ssid ?? ""
                                    elide: Text.ElideRight
                                    color: netRow.ap.active ? ArchTheme.accent : ArchTheme.fg
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSize - 1
                                }

                                MaterialSymbol {
                                    text: signalIcon(netRow.ap.strength ?? 0)
                                    iconSize: ArchTheme.fontSize - 2
                                    color: netRow.ap.active ? ArchTheme.accent : ArchTheme.muted
                                }

                                MaterialSymbol {
                                    visible: netRow.ap.active
                                    text: "logout"
                                    iconSize: ArchTheme.fontSize - 2
                                    color: ArchTheme.muted
                                }
                            }

                            MouseArea {
                                id: netTap
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.connect(netRow.ap)
                            }
                        }
                    }
                }
            }

            // ---- inline password prompt for secured networks ----
            RowLayout {
                Layout.fillWidth: true
                visible: root.passwordTarget !== null
                spacing: 6

                TextField {
                    id: pwField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Password")
                    echoMode: TextInput.Password
                    text: root.passwordText
                    onTextChanged: root.passwordText = text
                    color: ArchTheme.fg
                    placeholderTextColor: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize - 1
                    background: Rectangle {
                        radius: 4
                        color: ArchTheme.surfaceHover
                        border.width: 1
                        border.color: pwField.activeFocus ? ArchTheme.accent : ArchTheme.border
                    }
                    Keys.onReturnPressed: root.submitPassword()
                    Keys.onEscapePressed: root.passwordTarget = null
                }

                IconActionButton {
                    icon: "check"
                    tooltip: Translation.tr("Connect")
                    onClicked: root.submitPassword()
                }

                IconActionButton {
                    icon: "close"
                    tooltip: Translation.tr("Cancel")
                    onClicked: root.passwordTarget = null
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: ArchTheme.border
            }

            // ================= bluetooth =================
            RowLayout {
                Layout.fillWidth: true
                spacing: ArchTheme.spacing

                MaterialSymbol {
                    text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    iconSize: 16
                    color: BluetoothStatus.enabled ? ArchTheme.accent : ArchTheme.fgDim
                }

                Text {
                    Layout.fillWidth: true
                    text: BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Bluetooth")
                    elide: Text.ElideRight
                    color: BluetoothStatus.enabled ? ArchTheme.fg : ArchTheme.fgDim
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                }

                IconActionButton {
                    icon: "bluetooth"
                    tooltip: BluetoothStatus.enabled ? Translation.tr("Disable Bluetooth") : Translation.tr("Enable Bluetooth")
                    active: BluetoothStatus.enabled
                    actionEnabled: BluetoothStatus.available
                    onClicked: {
                        if (BluetoothStatus.available)
                            if (Bluetooth.defaultAdapter)
                                Bluetooth.defaultAdapter.enabled = !BluetoothStatus.enabled;
                    }
                }
            }

            // ---- bluetooth devices ----
            Column {
                Layout.fillWidth: true
                spacing: 2
                visible: root.btDevices.length > 0

                Repeater {
                    model: root.btDevices
                    delegate: Item {
                        id: btRow
                        required property var modelData
                        readonly property var device: btRow.modelData
                        width: parent.width
                        height: 24

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: btTap.containsMouse ? ArchTheme.surfaceHover : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 8

                            MaterialSymbol {
                                text: btRow.device.connected ? "bluetooth_connected" : "bluetooth"
                                iconSize: ArchTheme.fontSize - 2
                                color: btRow.device.connected ? ArchTheme.accent : ArchTheme.muted
                            }

                            Text {
                                Layout.fillWidth: true
                                text: btRow.device.name ?? btRow.device.address ?? ""
                                elide: Text.ElideRight
                                color: ArchTheme.fg
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSize - 1
                            }

                            Text {
                                text: btRow.device.batteryPercentage ? btRow.device.batteryPercentage + "%" : ""
                                color: ArchTheme.muted
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSizeCaption
                            }

                            MaterialSymbol {
                                text: "link"
                                iconSize: ArchTheme.fontSize - 3
                                color: btRow.device.connected ? ArchTheme.accent : "transparent"
                            }
                        }

                        MouseArea {
                            id: btTap
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (btRow.device.connected)
                                    btRow.device.disconnect();
                                else
                                    btRow.device.connect();
                            }
                        }
                    }
                }
            }
        }
    }

    function submitPassword() {
        if (root.passwordTarget === null)
            return;
        Network.changePassword(root.passwordTarget, root.passwordText);
        root.passwordTarget = null;
        root.passwordText = "";
    }
}
