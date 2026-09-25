pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    property bool opened: false
    property var seedManga: null
    property var seedChapter: null
    property int seedPage: -1

    function open(manga: var, chapter: var, page: int): void {
        root.seedManga = manga
        root.seedChapter = chapter
        root.seedPage = page
        root.opened = true
    }

    function close(): void {
        root.opened = false
        root.closed()
    }

    signal closed()

    Loader {
        active: root.opened
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                WlrLayershell.namespace: "quickshell:mangaFullscreen"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.layer: WlrLayer.Overlay
                exclusionMode: ExclusionMode.Ignore

                Rectangle {
                    id: surface
                    anchors.fill: parent
                    color: Appearance.colors.colLayer0
                    focus: true

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Left) {
                            mangaReader.navigatePage("next")
                            event.accepted = true
                        } else if (event.key === Qt.Key_Right) {
                            mangaReader.navigatePage("prev")
                            event.accepted = true
                        }
                    }

                    MangaView {
                        id: mangaReader
                        anchors.fill: parent
                        anchors.margins: 12
                        immersive: true
                        bigMode: true
                        seedManga: root.seedManga
                        seedChapter: root.seedChapter
                        seedPage: root.seedPage
                    }

                    RippleButtonWithIcon {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        implicitWidth: 42
                        implicitHeight: 42
                        buttonRadius: 21
                        materialIcon: "close"
                        mainText: ""
                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.25)
                        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                        onClicked: root.close()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        height: 26
                        radius: 13
                        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.30)
                        width: hintText.implicitWidth + 28

                        StyledText {
                            id: hintText
                            anchors.centerIn: parent
                            text: "← avanzar · retroceder → · ESC salir"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }
            }
        }
    }
}