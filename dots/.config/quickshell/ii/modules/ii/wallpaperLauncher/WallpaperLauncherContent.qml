import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

FocusScope {
    id: root

    readonly property var entries: Wallpapers.folderModel
    readonly property string currentWallpaperPath: Config.options.background.wallpaperPath
    readonly property int currentIndex: carousel.currentIndex
    readonly property int count: carousel.count
    readonly property string selectedPath: carousel.selectedPath
    readonly property real padding: 18
    readonly property bool loading: Wallpapers.thumbnailGenerationRunning

    implicitWidth: Math.max(carousel.itemWidth * 3 + padding * 2,
        carousel.implicitWidth + padding * 2)
    implicitHeight: padding * 2 + titleRow.implicitHeight
        + listArea.implicitHeight + bottomRow.implicitHeight
        + Appearance.sizes.hyprlandGapsOut * 2
    focus: true

    function moveSelection(delta: int): void {
        carousel.moveSelection(delta)
    }

    function activateCurrent(): void {
        carousel.activateCurrent()
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            root.forceActiveFocus()
            carousel.syncCurrentIndex()
            Wallpapers.generateThumbnail("large")
        })
    }

    Connections {
        target: GlobalStates

        function onWallpaperLauncherOpenChanged(): void {
            if (!GlobalStates.wallpaperLauncherOpen) return
            Qt.callLater(() => {
                root.forceActiveFocus()
                carousel.syncCurrentIndex()
                Wallpapers.generateThumbnail("large")
            })
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperLauncherOpen = false
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            carousel.moveSelection(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            carousel.moveSelection(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            carousel.activateCurrent()
            event.accepted = true
        } else if (event.key === Qt.Key_Slash) {
            searchField.forceActiveFocus()
            event.accepted = true
        } else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier)) {
            searchField.text += event.text
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            event.accepted = true
        }
    }

    Timer {
        id: gridOpenTimer
        interval: 80
        repeat: false
        onTriggered: GlobalStates.wallpaperSelectorOpen = true
    }

    StyledRectangularShadow {
        target: panel
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 10

            RowLayout {
                id: titleRow
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Wallpaper launcher")
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                }

                StyledText {
                    text: carousel.count > 0
                        ? "%1 / %2".arg(root.currentIndex + 1).arg(root.count)
                        : "0 / 0"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.family: Appearance.font.family.monospace
                }

                StyledText {
                    visible: root.loading
                    text: Translation.tr("Processing...")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSecondary
                }
            }

            Item {
                id: listArea
                Layout.fillWidth: true
                implicitHeight: carousel.implicitHeight

                WallpaperLauncherList {
                    id: carousel
                    anchors.centerIn: parent
                    width: Math.min(parent.width, implicitWidth)
                    height: implicitHeight
                    folderModel: root.entries
                    currentWallpaperPath: root.currentWallpaperPath
                    onApplyRequested: path => {
                        if (path && path.length > 0) {
                            Wallpapers.select(path, Appearance.m3colors.darkmode)
                            GlobalStates.wallpaperLauncherOpen = false
                        }
                    }
                    onDirectoryRequested: path => {
                        Wallpapers.setDirectory(path)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: !root.loading && carousel.count === 0
                    spacing: 6
                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "image_not_supported"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Translation.tr("No wallpapers found")
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            RowLayout {
                id: bottomRow
                Layout.fillWidth: true
                spacing: 6

                IconToolbarButton {
                    implicitWidth: Appearance.sizes.baseBarHeight
                    implicitHeight: Appearance.sizes.baseBarHeight
                    text: "grid_view"
                    onClicked: {
                        Config.setNestedValue("wallpaperSelector.style", "grid")
                        GlobalStates.wallpaperLauncherOpen = false
                        gridOpenTimer.restart()
                    }
                    StyledToolTip { text: Translation.tr("Switch to grid view") }
                }

                IconToolbarButton {
                    implicitWidth: Appearance.sizes.baseBarHeight
                    implicitHeight: Appearance.sizes.baseBarHeight
                    toggled: Wallpapers.showVideos
                    onClicked: Wallpapers.showVideos = !Wallpapers.showVideos
                    text: "movie"
                    StyledToolTip { text: Translation.tr("Show video / live wallpapers (mp4, webm, mkv, avi, mov)") }
                }

                IconToolbarButton {
                    implicitWidth: Appearance.sizes.baseBarHeight
                    implicitHeight: Appearance.sizes.baseBarHeight
                    text: "chevron_left"
                    enabled: carousel.count > 1
                    onClicked: {
                        carousel.moveSelection(-1)
                        root.forceActiveFocus()
                    }
                    StyledToolTip { text: Translation.tr("Previous wallpaper") }
                }

                ToolbarTextField {
                    id: searchField
                    Layout.fillWidth: true
                    implicitHeight: Appearance.sizes.baseBarHeight
                    leftPadding: 38
                    placeholderText: Translation.tr("Search wallpapers")
                    text: Wallpapers.searchQuery
                    onTextChanged: Wallpapers.searchQuery = text
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                            carousel.moveSelection(1)
                            root.forceActiveFocus()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                            carousel.moveSelection(-1)
                            root.forceActiveFocus()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            carousel.activateCurrent()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            if (Wallpapers.searchQuery.length > 0)
                                Wallpapers.searchQuery = ""
                            else {
                                searchField.focus = false
                                root.forceActiveFocus()
                            }
                            event.accepted = true
                        }
                    }

                    MaterialSymbol {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                }

                IconToolbarButton {
                    implicitWidth: Appearance.sizes.baseBarHeight
                    implicitHeight: Appearance.sizes.baseBarHeight
                    text: "chevron_right"
                    enabled: carousel.count > 1
                    onClicked: {
                        carousel.moveSelection(1)
                        root.forceActiveFocus()
                    }
                    StyledToolTip { text: Translation.tr("Next wallpaper") }
                }

                IconToolbarButton {
                    implicitWidth: Appearance.sizes.baseBarHeight
                    implicitHeight: Appearance.sizes.baseBarHeight
                    text: "check"
                    enabled: carousel.count > 0
                    onClicked: {
                        carousel.activateCurrent()
                        root.forceActiveFocus()
                    }
                    StyledToolTip { text: Translation.tr("Apply wallpaper") }
                }

                IconToolbarButton {
                    implicitWidth: Appearance.sizes.baseBarHeight
                    implicitHeight: Appearance.sizes.baseBarHeight
                    text: "close"
                    onClicked: GlobalStates.wallpaperLauncherOpen = false
                    StyledToolTip { text: Translation.tr("Close wallpaper selector") }
                }
            }
        }
    }
}