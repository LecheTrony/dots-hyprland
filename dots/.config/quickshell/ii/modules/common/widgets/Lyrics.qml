pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color textColor: "white"
    property color activeColor: "white"
    property color dimColor: Qt.rgba(1, 1, 1, 0.35)
    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorShapeColor: Appearance.colors.colOnPrimaryContainer
    property int textAlignment: Text.AlignLeft
    property real fontScale: 1.0
    property bool animateTransitions: false
    property real lineSpacing: 6

    implicitWidth: 200
    implicitHeight: 200

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LyricsService.status !== "ok" && LyricsService.status !== "plain"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: LyricsService.restartLyrics()
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 12

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 48
                    implicitHeight: 48
                    visible: LyricsService.status === "loading"

                    MaterialLoadingIndicator {
                        anchors.fill: parent
                        loading: LyricsService.status === "loading"
                        colBg: root.indicatorColor
                        colShape: root.indicatorShapeColor
                        implicitSize: 48
                    }
                }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    visible: LyricsService.status !== "loading"
                    text: LyricsService.status === "no_info" ? "music_off" : "lyrics"
                    iconSize: 40
                    color: root.dimColor
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.dimColor
                    text: {
                        if (LyricsService.status === "loading") return Translation.tr("Searching lyrics...")
                        if (LyricsService.status === "no_info") return Translation.tr("No song info")
                        return Translation.tr("No lyrics found")
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: LyricsService.status !== "loading"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.dimColor
                    opacity: 0.7
                    text: Translation.tr("Click to retry")
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LyricsService.status === "plain"

            Flickable {
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: plainColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: plainColumn
                    width: parent.width
                    spacing: root.lineSpacing

                    Repeater {
                        model: LyricsService.lyricsLines
                        delegate: StyledText {
                            required property var modelData
                            width: plainColumn.width
                            horizontalAlignment: root.textAlignment
                            wrapMode: Text.WordWrap
                            text: modelData.text || "♪"
                            font.pixelSize: Appearance.font.pixelSize.small * root.fontScale
                            color: root.textColor
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LyricsService.status === "ok"
            spacing: root.lineSpacing

            Repeater {
                model: 7
                delegate: StyledText {
                    id: lyricSlot
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: root.textAlignment
                    wrapMode: Text.WordWrap
                    text: LyricsService.slots[index] ?? ""
                    readonly property int dist: Math.abs(index - LyricsService.before)
                    font.pixelSize: {
                        if (dist === 0) return Appearance.font.pixelSize.normal * root.fontScale
                        if (dist === 1) return Appearance.font.pixelSize.small * root.fontScale
                        return Appearance.font.pixelSize.smaller * root.fontScale
                    }
                    opacity: {
                        if (dist === 0) return 1.0
                        if (dist === 1) return 0.6
                        if (dist === 2) return 0.35
                        return 0.15
                    }
                    color: dist === 0 ? root.activeColor : root.textColor
                    transform: Translate { id: lineSlide }
                    onTextChanged: {
                        if (root.animateTransitions) slideAnim.restart();
                    }
                    SequentialAnimation {
                        id: slideAnim
                        ScriptAction { script: lineSlide.y = 28 * root.fontScale }
                        NumberAnimation { target: lineSlide; property: "y"; to: 0; duration: 420; easing.type: Easing.OutBack }
                    }
                    Behavior on font.pixelSize {
                        enabled: root.animateTransitions
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}