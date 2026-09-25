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

    property string currentView: "list"
    property bool loading: false
    property string errorMessage: ""

    property var mangaList: []
    property var selectedManga: null
    property var chapters: []
    property var selectedChapter: null
    property var pages: []
    property var pageCache: ({})
    property int currentPageIndex: 0
    property int opToken: 0
    property string activeOp: ""
    property string pendingOp: ""
    property var pendingArgs: ([])
    property int pageLoading: -1
    property var pageQueue: ([])
    property bool standalone: false
    property var openMangaOnLoad: null
    property var openChapterOnLoad: null

    property string searchQuery: ""

    readonly property color colText: Appearance.colors.colOnLayer0
    readonly property color colTextSecondary: Appearance.colors.colSubtext
    readonly property color colSurface: Appearance.colors.colLayer1
    readonly property color colSurfaceHover: Appearance.colors.colLayer1Hover
    readonly property color colBorder: Appearance.colors.colOutlineVariant
    readonly property color colPrimary: Appearance.colors.colPrimary
    readonly property color colPrimaryHover: Appearance.colors.colPrimaryHover
    readonly property color colOnPrimary: Appearance.colors.colOnPrimary
    readonly property real radiusSmall: Appearance.rounding.small
    readonly property int borderWidth: 1

    readonly property string scriptPath: Directories.scriptPath + "/manga/manga_oni.py"

    function runScript(op: string, args: var): void {
        root.pendingOp = op
        root.pendingArgs = args
        if (!mangaProcess.running) root._startPending()
    }

    function _startPending(): void {
        root.activeOp = root.pendingOp
        root.opToken = root.opToken + 1
        const cmd = ["python3", root.scriptPath].concat(root.pendingArgs)
        root.pendingOp = ""
        root.pendingArgs = ([])
        mangaProcess.command = cmd
        mangaProcess.running = true
    }

    function loadPopular(): void {
        if (root.loading) return
        root.errorMessage = ""
        root.loading = true
        root.runScript("popular", ["--popular", "--limit", "20"])
    }

    function searchManga(q: string): void {
        if (!q.trim().length) {
            root.loadPopular()
            return
        }
        if (root.loading) return
        root.errorMessage = ""
        root.loading = true
        root.runScript("search", ["--search", q.trim(), "--limit", "20"])
    }

    function openManga(item): void {
        if (!item || !item.id) return
        root.selectedManga = item
        root.fetchChapters()
    }

    function fetchChapters(): void {
        if (!root.selectedManga) return
        root.errorMessage = ""
        root.loading = true
        root.runScript("chapters", ["--chapters", "--manga-id", root.selectedManga.id])
    }

    function openChapter(ch): void {
        if (!ch || !ch.id) return
        root.selectedChapter = ch
        root.fetchPages()
    }

    function fetchPages(): void {
        if (!root.selectedChapter) return
        root.errorMessage = ""
        root.loading = true
        root.runScript("pages", ["--pages", "--chapter-id", root.selectedChapter.id])
    }

    function loadPageAt(index: int): void {
        if (index < 0 || index >= root.pages.length) return
        if (root.pageCache[index] && root.pageCache[index].path) return
        if (index === root.pageLoading) return
        for (const q of root.pageQueue) {
            if (q === index) return
        }
        root.pageQueue.push(index)
        root._drainPages()
    }

    function _drainPages(): void {
        if (root.pageLoading !== -1) return
        if (!root.pageQueue.length) return
        const index = root.pageQueue.shift()
        root.pageLoading = index
        root.runScript("page", ["--page", root.pages[index].url, "--index", String(index)])
    }

    function navigatePage(dir: string): void {
        const target = dir === "next" ? root.currentPageIndex + 1 : root.currentPageIndex - 1
        if (target < 0 || target >= root.pages.length) return
        root.currentPageIndex = target
        root.loadPageAt(target)
        if (target + 1 < root.pages.length) root.loadPageAt(target + 1)
        if (target - 1 >= 0) root.loadPageAt(target - 1)
    }

    function sortedChapters(): var {
        const out = root.chapters.slice()
        out.sort((a, b) => {
            const na = parseFloat(a.chapter || "0"), nb = parseFloat(b.chapter || "0")
            if (!isNaN(na) && !isNaN(nb) && na !== nb) return nb - na
            return new Date(b.publish_date) - new Date(a.publish_date)
        })
        return out
    }

    function chapterIndex(): int {
        return root.sortedChapters().findIndex(c => c.id === (root.selectedChapter ? root.selectedChapter.id : ""))
    }

    function hasPrevChapter(): bool {
        const index = root.chapterIndex()
        return index >= 0 && index + 1 < root.chapters.length
    }

    function hasNextChapter(): bool {
        const index = root.chapterIndex()
        return index > 0
    }

    function goToChapter(dir: string): void {
        if (!root.selectedChapter) return
        const list = root.sortedChapters()
        const index = list.findIndex(c => c.id === root.selectedChapter.id)
        if (index === -1) return
        const targetIndex = dir === "prev" ? index + 1 : index - 1
        if (targetIndex < 0 || targetIndex >= list.length) return
        root.selectedChapter = list[targetIndex]
        root.fetchPages()
    }

    function chapterLabel(ch): string {
        if (!ch) return ""
        if (ch.title && ch.title.length > 0) return ch.title
        const num = ch.chapter
        return num ? Translation.tr("Chapter") + " " + num : Translation.tr("Chapter")
    }

    function shortDate(raw: string): string {
        if (!raw) return ""
        const parts = raw.split(" ")
        return parts.length > 0 ? parts[0] : raw
    }

    function currentUrl(): string {
        if (root.selectedChapter) {
            const parts = root.selectedChapter.id.split("/")
            if (parts.length === 2) return "https://manga-oni.com/lector/" + parts[0] + "/" + parts[1] + "/"
        }
        if (root.selectedManga) return "https://manga-oni.com/manga/" + root.selectedManga.id + "/"
        return "https://manga-oni.com/"
    }

    function openInBrowser(): void {
        const url = root.currentUrl()
        if (url.length > 0) Quickshell.execDetached(["xdg-open", url])
    }

    function goBack(): void {
        if (root.currentView === "reader") {
            root.currentView = "chapters"
        } else if (root.currentView === "chapters") {
            root.currentView = "list"
        }
    }

    function openFullscreen(): void {
        root.openFullscreenRequested(root.selectedManga, root.selectedChapter)
    }

    signal openFullscreenRequested(var manga, var chapter)

    Process {
        id: mangaProcess
        stdout: SplitParser {
            onRead: line => {
                if (typeof line !== "string" || !line.trim().length) return
                let parsed = null
                try {
                    parsed = JSON.parse(line.trim())
                } catch (e) {
                    return
                }
                const op = root.activeOp
                if (parsed && parsed.error) {
                    if (op !== "page") root.errorMessage = String(parsed.error)
                } else if (Array.isArray(parsed)) {
                    if (op === "popular" || op === "search") {
                        root.mangaList = parsed
                    } else if (op === "chapters") {
                        root.chapters = parsed
                        root.currentView = "chapters"
                        if (root.openChapterOnLoad) {
                            const wanted = root.openChapterOnLoad.id
                            const target = parsed.find(c => c && c.id === wanted)
                            root.selectedChapter = target || (parsed.length ? parsed[0] : null)
                            root.openChapterOnLoad = null
                            if (root.selectedChapter) root.fetchPages()
                        }
                    } else if (op === "pages") {
                        root.pages = parsed
                        root.pageCache = ({})
                        root.currentPageIndex = 0
                        root.pageLoading = -1
                        root.pageQueue = ([])
                        root.currentView = "reader"
                        root.loadPageAt(0)
                    }
                } else if (parsed && parsed.url && parsed.path) {
                    const key = parsed.key !== undefined ? String(parsed.key) : String(root.currentPageIndex)
                    const merged = ({})
                    for (const k in root.pageCache) merged[k] = root.pageCache[k]
                    merged[key] = parsed
                    root.pageCache = merged
                }
            }
        }
        onExited: code => {
            if (root.activeOp !== "page") {
                if (code !== 0) root.errorMessage = Translation.tr("Could not load data")
                root.loading = false
            } else {
                root.pageLoading = -1
                Qt.callLater(root._drainPages)
            }
            if (root.pendingOp !== "") Qt.callLater(root._startPending)
        }
    }

    Keys.onPressed: (event) => {
        if (root.currentView !== "reader") return
        if (event.key === Qt.Key_Left) {
            root.navigatePage("prev")
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.navigatePage("next")
            event.accepted = true
        }
    }

    Component.onCompleted: {
        if (root.openMangaOnLoad) {
            root.selectedManga = root.openMangaOnLoad
            root.fetchChapters()
        } else {
            root.loadPopular()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                id: viewTabs
                model: [
                    { value: "list", label: Translation.tr("Manga"), enabled: true },
                    { value: "chapters", label: Translation.tr("Chapters"), enabled: root.selectedManga !== null },
                    { value: "reader", label: Translation.tr("Reader"), enabled: root.selectedChapter !== null }
                ]

                Rectangle {
                    Layout.preferredHeight: 34
                    Layout.fillWidth: true
                    radius: root.radiusSmall
                    color: (modelData.value === root.currentView) ? root.colPrimary : root.colSurface
                    border.width: root.borderWidth
                    border.color: (modelData.value === root.currentView) ? "transparent" : root.colBorder
                    opacity: modelData.enabled ? 1 : 0.45

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    MaterialSymbol {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value === "list" ? "menu_book"
                            : modelData.value === "chapters" ? "format_list_bulleted" : "auto_stories"
                        iconSize: 16
                        color: (modelData.value === root.currentView) ? root.colOnPrimary : root.colTextSecondary
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: (modelData.value === root.currentView) ? root.colOnPrimary : root.colText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: modelData.enabled
                        onClicked: root.currentView = modelData.value
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.currentView === "list"
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
                        placeholderText: Translation.tr("Search manga...")
                        placeholderTextColor: root.colTextSecondary
                        color: root.colText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        background: Item {}
                        selectByMouse: true
                        text: root.searchQuery
                        onTextChanged: root.searchQuery = text
                        onAccepted: root.searchManga(text)
                        Keys.onEscapePressed: {
                            text = ""
                            root.loadPopular()
                            focus = false
                        }
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
                onClicked: {
                    searchField.text = ""
                    root.loadPopular()
                }
            }

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "fullscreen"
                mainText: ""
                visible: !root.standalone
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.openFullscreen()
            }

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "open_in_new"
                mainText: ""
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.openInBrowser()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.currentView !== "list"
            spacing: 6

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "arrow_back"
                mainText: ""
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.goBack()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: root.radiusSmall
                color: root.colSurface
                border.width: root.borderWidth
                border.color: root.colBorder

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentView === "chapters" && root.selectedManga
                        ? root.selectedManga.title
                        : root.currentView === "reader" && root.selectedChapter
                            ? root.chapterLabel(root.selectedChapter)
                            : ""
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideRight
                    color: root.colText
                }
            }

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "fullscreen"
                mainText: ""
                visible: !root.standalone
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.openFullscreen()
            }

            RippleButtonWithIcon {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                materialIcon: "open_in_new"
                mainText: ""
                colBackground: root.colSurface
                colBackgroundHover: root.colSurfaceHover
                onClicked: root.openInBrowser()
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
                shown: !root.loading && root.errorMessage.length === 0
                    && root.currentView === "list" && root.mangaList.length === 0
                icon: "menu_book"
                text: Translation.tr("No manga found")
                explanation: Translation.tr("Search on manga-oni.com or refresh the latest updates")
            }

            MaterialPlaceholderMessage {
                anchors.fill: parent
                shown: !root.loading && root.errorMessage.length > 0
                icon: "error"
                text: Translation.tr("Could not load manga")
                explanation: root.errorMessage
            }

            StyledListView {
                id: listView
                anchors.fill: parent
                visible: !root.loading && root.errorMessage.length === 0 && root.currentView === "list" && root.mangaList.length > 0
                clip: true
                spacing: 6
                model: root.mangaList

                delegate: Rectangle {
                    id: mangaRow
                    required property var modelData
                    width: listView.width
                    height: 72
                    radius: root.radiusSmall
                    color: mangaRowMouse.containsMouse ? root.colSurfaceHover : root.colSurface
                    border.width: root.borderWidth
                    border.color: mangaRowMouse.containsMouse ? root.colBorder : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    MouseArea {
                        id: mangaRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openManga(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 56
                            radius: 5
                            clip: true
                            color: root.colSurfaceHover

                            Image {
                                anchors.fill: parent
                                visible: modelData.cover_path && modelData.cover_path.length > 0
                                source: modelData.cover_path && modelData.cover_path.length > 0 ? "file://" + modelData.cover_path : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                smooth: true
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: !modelData.cover_path || modelData.cover_path.length === 0
                                text: "image"
                                iconSize: 20
                                color: root.colTextSecondary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                color: root.colText
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: [modelData.tags.length > 0 ? modelData.tags.join(" · ") : "", modelData.date ? root.shortDate(modelData.date) : ""]
                                    .filter(x => x.length > 0).join("  ·  ")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                elide: Text.ElideRight
                                color: root.colTextSecondary
                            }
                        }

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: "chevron_right"
                            iconSize: 18
                            color: root.colTextSecondary
                        }
                    }
                }
            }

            StyledListView {
                id: chaptersList
                anchors.fill: parent
                visible: !root.loading && root.errorMessage.length === 0 && root.currentView === "chapters"
                clip: true
                spacing: 6
                model: root.chapters

                delegate: Rectangle {
                    id: chapterRow
                    required property var modelData
                    width: chaptersList.width
                    height: 46
                    radius: root.radiusSmall
                    color: chapterRowMouse.containsMouse ? root.colSurfaceHover : root.colSurface
                    border.width: root.borderWidth
                    border.color: chapterRowMouse.containsMouse ? root.colBorder : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    MouseArea {
                        id: chapterRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openChapter(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                text: root.chapterLabel(modelData)
                                font.pixelSize: Appearance.font.pixelSize.small
                                elide: Text.ElideRight
                                color: root.colText
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: [modelData.publish_date ? root.shortDate(modelData.publish_date) : "", modelData.user ? modelData.user : ""]
                                    .filter(x => x.length > 0).join("  ·  ")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                elide: Text.ElideRight
                                color: root.colTextSecondary
                            }
                        }

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: "auto_stories"
                            iconSize: 16
                            color: root.colTextSecondary
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                visible: !root.loading && root.errorMessage.length === 0 && root.currentView === "reader" && root.pages.length > 0
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: root.radiusSmall
                        color: root.colSurface
                        border.width: root.borderWidth
                        border.color: root.colBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            StyledText {
                                Layout.fillWidth: true
                                text: root.chapterLabel(root.selectedChapter)
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                elide: Text.ElideRight
                                color: root.colText
                            }

                            StyledText {
                                text: (root.currentPageIndex + 1) + " / " + root.pages.length
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: root.colTextSecondary
                            }
                        }
                    }

                    RippleButtonWithIcon {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: root.radiusSmall
                        materialIcon: "open_in_browser"
                        horizontalPadding: 0
                        mainText: ""
                        colBackground: "transparent"
                        colBackgroundHover: root.colPrimaryHover
                        onClicked: root.openInBrowser()
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledIndeterminateProgressBar {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        visible: !!(root.pageCache[root.currentPageIndex] && root.pageCache[root.currentPageIndex].path)
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        visible: !!(root.pageCache[root.currentPageIndex] && root.pageCache[root.currentPageIndex].path)
                        source: root.pageCache[root.currentPageIndex] && root.pageCache[root.currentPageIndex].path
                            ? "file://" + root.pageCache[root.currentPageIndex].path : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: root.radiusSmall
                        materialIcon: "skip_previous"
                        mainText: ""
                        colBackground: root.colSurface
                        colBackgroundHover: root.colPrimaryHover
                        opacity: root.hasPrevChapter() ? 1 : 0.4
                        onClicked: if (root.hasPrevChapter()) root.goToChapter("prev")
                    }

                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: root.radiusSmall
                        materialIcon: "chevron_left"
                        mainText: ""
                        colBackground: root.colSurface
                        colBackgroundHover: root.colPrimaryHover
                        opacity: root.currentPageIndex > 0 ? 1 : 0.4
                        onClicked: if (root.currentPageIndex > 0) root.navigatePage("prev")
                    }

                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: root.radiusSmall
                        materialIcon: "chevron_right"
                        mainText: ""
                        colBackground: root.colSurface
                        colBackgroundHover: root.colPrimaryHover
                        opacity: root.currentPageIndex < root.pages.length - 1 ? 1 : 0.4
                        onClicked: if (root.currentPageIndex < root.pages.length - 1) root.navigatePage("next")
                    }

                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: root.radiusSmall
                        materialIcon: "skip_next"
                        mainText: ""
                        colBackground: root.colSurface
                        colBackgroundHover: root.colPrimaryHover
                        opacity: root.hasNextChapter() ? 1 : 0.4
                        onClicked: if (root.hasNextChapter()) root.goToChapter("next")
                    }
                }
            }
        }
    }
}