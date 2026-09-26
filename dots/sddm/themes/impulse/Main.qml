import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#080B10"

    TextConstants { id: textConstants }

    // ---- theme (from theme.conf) ----
    readonly property color accent: config.Accent ? config.Accent : "#66C2FF"
    readonly property real surfaceOpacity: config.SurfaceOpacity ? parseFloat(config.SurfaceOpacity) : 0.80
    readonly property real vignette: config.Vignette ? parseFloat(config.Vignette) : 0.48
    readonly property int cardRadius: config.Radius ? parseInt(config.Radius) : 22
    readonly property int cardWidth: config.CardWidth ? parseInt(config.CardWidth) : 440
    readonly property string backgroundSource: config.Background ? config.Background : "background-blur.jpg"

    // ---- state ----
    property int selectedUser: -1
    property int currentSession: 0
    property bool busy: false

    // ---- auth ----
    function doLogin() {
        if (busy)
            return
        busy = true
        statusText.text = ""
        sddm.login(userInput.text.trim(), passInput.text, currentSession)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            busy = false
            statusText.text = textConstants.loginFailed
            statusText.color = "#FF5C5C"
            passInput.text = ""
            passInput.focus = true
        }
        function onLoginSucceeded() {
            busy = false
            statusText.text = textConstants.loginSucceeded
            statusText.color = "#7CFF9A"
        }
    }

    Component.onCompleted: {
        if (userModel && userModel.count > 0 && userModel.get(0) && userModel.get(0).name)
            userInput.text = userModel.get(0).name
        if (sessionModel && sessionModel.hasOwnProperty("lastIndex"))
            currentSession = sessionModel.lastIndex
        else
            currentSession = 0
    }

    // ============================ BACKGROUND ============================

    // pre-blurred art (boxblur at build time): no runtime shader needed
    Image {
        id: bgImg
        anchors.fill: parent
        source: backgroundSource
        fillMode: Image.PreserveAspectCrop
        cache: true
        smooth: true
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, vignette)
    }

    // top impulse glow
    Rectangle {
        id: topGlow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(120, root.height * 0.13)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.accent; }
            GradientStop { position: 1.0; color: "transparent"; }
        }
        opacity: 0.24
    }
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: root.accent
        opacity: 0.95
    }

    // ============================ CLOCK ============================
    Column {
        id: clockCol
        anchors.top: parent.top
        anchors.topMargin: Math.max(56, root.height * 0.10)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        opacity: 0
        Text {
            id: clockTime
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#F4F7FB"
            font.family: "monospace"
            font.pixelSize: Math.max(64, Math.min(120, root.height * 0.11))
            font.weight: Font.ExtraBold
            font.letterSpacing: 2
            text: "00:00"
        }
        Text {
            id: clockDate
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(0.96, 0.97, 1.0, 0.62)
            font.family: "monospace"
            font.pixelSize: 16
            font.letterSpacing: 4
            font.capitalization: Font.AllUppercase
            text: ""
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85)
            font.family: "monospace"
            font.pixelSize: 13
            font.letterSpacing: 2
            text: textConstants.welcomeText.arg(sddm.hostName)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            clockTime.text = Qt.formatTime(d, "HH:mm")
            clockDate.text = Qt.formatDate(d, "dddd d MMMM")
        }
    }

    // ============================ LOGIN CARD ============================
    Item {
        id: cardAnchor
        anchors.centerIn: parent
        width: cardWidth
        height: Math.max(360, root.height * 0.52)
        opacity: 0
    }

    Rectangle {
        id: accentRing
        anchors.centerIn: cardAnchor
        width: cardAnchor.width
        height: cardAnchor.height
        radius: cardRadius + 14
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.05)
        border.width: 1
        border.color: root.accent
        opacity: 0.18
    }

    Timer {
        id: pulseTimer
        interval: 2400
        running: true
        repeat: true
        onTriggered: pulseAnim.restart()
    }
    PropertyAnimation {
        id: pulseAnim
        target: accentRing
        property: "opacity"
        from: 0.32
        to: 0.10
        duration: 1700
        easing.type: Easing.InOutQuad
    }

    Rectangle {
        id: card
        anchors.centerIn: cardAnchor
        width: cardAnchor.width
        height: cardAnchor.height
        radius: cardRadius
        color: Qt.rgba(0.047, 0.059, 0.078, surfaceOpacity)
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 16

            // ---- user identity ----
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
                Rectangle {
                    id: avatar
                    width: 52
                    height: 52
                    radius: 26
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
                    clip: true
                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 48
                        sourceSize.height: 48
                        source: ""
                        visible: false
                        onStatusChanged: if (status === Image.Ready) visible = true
                    }
                    Text {
                        id: avatarInitial
                        anchors.centerIn: parent
                        color: root.accent
                        font.pixelSize: 22
                        font.bold: true
                        text: userInput.text.length ? userInput.text.charAt(0).toUpperCase() : "?"
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Math.max(180, card.width * 0.42)
                    Layout.preferredHeight: 40
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: 1
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7)
                    }
                    TextInput {
                        id: userInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#EEF2F8"
                        font.pixelSize: 19
                        font.bold: true
                        clip: true
                        Keys.onReturnPressed: passInput.focus = true
                        Keys.onEnterPressed: passInput.focus = true
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(0.93, 0.95, 1.0, 0.35)
                        font.pixelSize: 19
                        font.bold: true
                        text: textConstants.userName
                        visible: userInput.text.length === 0
                    }
                }
            }

            // ---- users ----
            Flow {
                id: userFlow
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8
                visible: userModel && userModel.count > 1
                Repeater {
                    model: userModel
                    delegate: Rectangle {
                        readonly property bool active: userInput.text === name
                        width: chipText.implicitWidth + 26
                        height: 30
                        radius: 15
                        color: active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)
                                     : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: active ? root.accent : Qt.rgba(1, 1, 1, 0.12)
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            color: active ? "#FFFFFF" : Qt.rgba(0.93, 0.95, 1.0, 0.75)
                            font.pixelSize: 13
                            font.bold: active
                            text: name
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                userInput.text = name
                                root.selectedUser = index
                                avatarImg.source = icon && icon.toString() ? icon : ""
                                passInput.focus = true
                            }
                        }
                    }
                }
            }

            // ---- session ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    color: Qt.rgba(0.93, 0.95, 1.0, 0.55)
                    font.family: "monospace"
                    font.pixelSize: 12
                    font.letterSpacing: 1
                    text: textConstants.session
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: sessionModel
                        delegate: Rectangle {
                            readonly property bool active: index === root.currentSession
                            width: sText.implicitWidth + 20
                            height: 26
                            radius: 8
                            color: active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                                         : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85)
                                                 : Qt.rgba(1, 1, 1, 0.10)
                            Text {
                                id: sText
                                anchors.centerIn: parent
                                color: active ? "#FFFFFF" : Qt.rgba(0.93, 0.95, 1.0, 0.6)
                                font.pixelSize: 12
                                font.bold: active
                                text: name
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.currentSession = index
                            }
                        }
                    }
                }
            }

            // ---- password ----
            Rectangle {
                id: passBox
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.055)
                border.width: (passInput.focus || passInput.length > 0) ? 1 : 0
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.9)
                TextInput {
                    id: passInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#F2F5FA"
                    font.pixelSize: 17
                    font.family: "monospace"
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData
                    clip: true
                    focus: true
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(0.93, 0.95, 1.0, 0.32)
                    font.pixelSize: 17
                    font.family: "monospace"
                    text: textConstants.password
                    visible: passInput.length === 0 && !passInput.focus
                }
            }

            // ---- status + login ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    id: statusText
                    Layout.fillWidth: true
                    color: "transparent"
                    font.pixelSize: 13
                    font.family: "monospace"
                    elide: Text.ElideRight
                    text: ""
                }
                Rectangle {
                    id: loginBtn
                    Layout.preferredWidth: 128
                    Layout.preferredHeight: 44
                    radius: 22
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.accent }
                        GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.72) }
                    }
                    property bool pressed: false
                    scale: pressed ? 0.96 : 1.0
                    Text {
                        anchors.centerIn: parent
                        color: "#081018"
                        font.pixelSize: 15
                        font.bold: true
                        text: textConstants.login
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: loginBtn.pressed = true
                        onReleased: loginBtn.pressed = false
                        onClicked: root.doLogin()
                    }
                }
                Text {
                    id: spinner
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: root.busy
                    color: root.accent
                    font.pixelSize: 15
                    font.family: "monospace"
                    text: "…"
                    RotationAnimator {
                        target: spinner
                        from: 0
                        to: 360
                        duration: 900
                        running: root.busy
                        loops: Animation.Infinite
                    }
                }
            }
        }
    }

    // ============================ POWER ============================
    Row {
        id: powerRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(28, root.height * 0.045)
        spacing: 10

        PowerPill {
            accent: root.accent
            text: textConstants.suspend
            onClicked: sddm.suspend()
        }
        PowerPill {
            accent: root.accent
            text: textConstants.reboot
            onClicked: sddm.reboot()
        }
        PowerPill {
            accent: root.accent
            text: textConstants.shutdown
            onClicked: sddm.powerOff()
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        color: Qt.rgba(1, 1, 1, 0.28)
        font.pixelSize: 11
        font.family: "monospace"
        text: "ILLOGICAL-IMPULSE"
    }

    // ============================ FADE IN ============================
    NumberAnimation {
        running: true
        target: cardAnchor
        property: "opacity"
        from: 0
        to: 1
        duration: 650
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        running: true
        target: clockCol
        property: "opacity"
        from: 0
        to: 1
        duration: 850
        easing.type: Easing.OutCubic
    }
}