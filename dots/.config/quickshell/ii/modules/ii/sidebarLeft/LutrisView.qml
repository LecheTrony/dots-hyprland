import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string searchQuery: ""
    property bool loading: true
    property string errorMessage: ""
    property var games: []
    property var filteredGames: []

    property string launchingSlug: ""
    property string launchingName: ""
    property bool launching: root.launchingSlug.length > 0

    readonly property color colText: Appearance.colors.colOnLayer0
    readonly property color colTextSecondary: Appearance.colors.colSubtext
    readonly property color colSurface: Appearance.colors.colLayer1
    readonly property color colSurfaceHover: Appearance.colors.colLayer1Hover
    readonly property color colBorder: Appearance.colors.colOutlineVariant
    readonly property color colPrimary: Appearance.colors.colPrimary
    readonly property color colPrimaryHover: Appearance.colors.colPrimaryHover
    readonly property real radiusSmall: Appearance.rounding.small
    readonly property int borderWidth: 1

    onGamesChanged: root._applyFilter()
    onSearchQueryChanged: root._applyFilter()

    function _applyFilter(): void {
        const q = root.searchQuery.trim().toLowerCase()
        const base = root.games
        if (!q.length) {
            root.filteredGames = base
            return
        }
        const out = []
        for (let i = 0; i < base.length; ++i) {
            const g = base[i]
            const hay = `${g.name} ${g.runner} ${g.platform}`.toLowerCase()
            if (hay.includes(q)) out.push(g)
        }
        root.filteredGames = out
    }

    function _formatPlaytime(hours: real): string {
        if (!hours || hours < 0.05) return Translation.tr("Not played")
        if (hours < 1) return `${Math.round(hours * 60)} ${Translation.tr("min")}`
        return `${hours.toFixed(1)} ${Translation.tr("hours")}`
    }

    function refresh(): void {
        if (lookupProcess.running) return
        root.loading = true
        lookupProcess.running = true
    }

    function launchGame(slug: string, name: string): void {
        if (!slug.length || root.launching) return
        root.launchingSlug = slug
        root.launchingName = name.length ? name : slug
        watchProcess.running = false
        watchProcess.running = true
        Quickshell.execDetached(["lutris", "lutris:rungame/" + slug])
    }

    function _clearLaunching(): void {
        root.launchingSlug = ""
    }

    function openLutris(): void {
        Quickshell.execDetached(["lutris"])
    }

    Process {
        id: lookupProcess
        command: ["python3", Directories.scriptPath + "/lutris/library.py"]
        stdout: SplitParser {
            onRead: line => {
                if (typeof line !== "string" || !line.trim().length) return
                const trimmed = line.trim()
                if (!trimmed.length) return
                let parsed = null
                try {
                    parsed = JSON.parse(trimmed)
                } catch (e) {
                    return
                }
                if (Array.isArray(parsed)) {
                    root.games = parsed
                } else if (parsed && parsed.error) {
                    root.games = []
                    root.errorMessage = parsed.error
                }
            }
        }
        onExited: (code) => {
            if (code !== 0)
                root.errorMessage = Translation.tr("Could not read the Lutris library")
            root.loading = false
        }
    }

    Process {
        id: watchProcess
        command: ["python3", Directories.scriptPath + "/lutris/watcher.py", root.launchingName, "25"]
        stdout: SplitParser {
            onRead: line => {
                if (typeof line !== "string" || !line.trim().length) return
                const status = line.trim().split(" ")[0]
                if (status === "STARTED" || status === "TIMEOUT") {
                    root.launchingSlug = ""
                }
            }
        }
        onExited: () => root.launchingSlug = ""
    }

    Timer {
        id: launchSafetyTimer
        interval: 40000
        repeat: false
        running: false
        onTriggered: if (root.launching) root.launchingSlug = ""
    }

    onLaunchingChanged: if (root.launching) launchSafetyTimer.restart()

    Component.onCompleted: root.refresh()
    onVisibleChanged: if (root.visible) root.refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: root.radiusSmall
                color: root.colSurface
                border.width: root.borderWidth
                border.color: searchField.activeFocus ? root.colPrimary : root.colBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    MaterialSymbol {
                        text: "search"
                        iconSize: 16
                        color: root.colTextSecondary
                    }
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Search games...")
                        placeholderTextColor: root.colTextSecondary
                        color: root.colText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        background: Item {}
                        selectByMouse: true
                        text: root.searchQuery
                        onTextChanged: root.searchQuery = text
                        Keys.onEscapePressed: { text = ""; focus = false }
                    }
                }
            }

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "refresh"
                mainText: ""
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.refresh()
            }

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "open_in_new"
                mainText: ""
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.openLutris()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledIndeterminateProgressBar {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: parent.width - 24
                visible: root.loading
            }

            MaterialPlaceholderMessage {
                anchors.fill: parent
                shown: !root.loading && root.errorMessage.length === 0 && root.filteredGames.length === 0
                icon: "sports_esports"
                text: Translation.tr("No games")
                explanation: Translation.tr("Install a game in Lutris and it will appear here")
            }

            MaterialPlaceholderMessage {
                anchors.fill: parent
                shown: !root.loading && root.errorMessage.length > 0
                icon: "error"
                text: Translation.tr("Lutris library unavailable")
                explanation: root.errorMessage
            }

            StyledListView {
                id: gamesList
                anchors.fill: parent
                visible: !root.loading && root.errorMessage.length === 0 && root.filteredGames.length > 0
                clip: true
                spacing: 6
                model: root.filteredGames

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool rowIsLaunching: row.modelData.slug === root.launchingSlug
                    width: gamesList.width
                    height: 86
                    radius: root.radiusSmall
                    color: rowMouse.containsMouse ? root.colSurfaceHover : root.colSurface
                    border.width: root.borderWidth
                    border.color: rowMouse.containsMouse ? root.colBorder : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchGame(row.modelData.slug, row.modelData.name)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Rectangle {
                            implicitWidth: 46
                            implicitHeight: 70
                            radius: 6
                            clip: true
                            color: root.colSurfaceHover

                            Image {
                                anchors.fill: parent
                                visible: row.modelData.cover.length > 0
                                source: row.modelData.cover.length > 0 ? "file://" + row.modelData.cover : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                smooth: true
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: row.modelData.cover.length === 0
                                text: "videogame_asset"
                                iconSize: 24
                                color: root.colTextSecondary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                color: root.colText
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: [row.modelData.platform, row.modelData.runner].filter(x => x.length > 0).join(" · ")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                elide: Text.ElideRight
                                color: root.colTextSecondary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root._formatPlaytime(row.modelData.playtime)
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                elide: Text.ElideRight
                                color: root.colTextSecondary
                            }
                        }

                        RippleButtonWithIcon {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: root.radiusSmall
                            materialIcon: ""
                            horizontalPadding: 0
                            mainText: ""
                            colBackground: "transparent"
                            colBackgroundHover: rowIsLaunching ? "transparent" : root.colPrimaryHover
                            mainContentComponent: Component {
                                Item {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    MaterialLoadingIndicator {
                                        anchors.centerIn: parent
                                        implicitSize: 18
                                        loading: rowIsLaunching
                                        visible: rowIsLaunching
                                    }
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "play_arrow"
                                        iconSize: 16
                                        color: Appearance.colors.colOnSecondaryContainer
                                        visible: !rowIsLaunching
                                    }
                                }
                            }
                            onClicked: root.launchGame(row.modelData.slug, row.modelData.name)
                        }
                    }
                }
            }
        }
    }
}