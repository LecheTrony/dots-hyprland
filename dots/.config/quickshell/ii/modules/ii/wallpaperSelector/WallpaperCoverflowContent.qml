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

/**
 * Coverflow wallpaper browser — fullscreen gallery with a scaled card layout.
 *
 * Depth is conveyed purely through scale + overlap + opacity (no 3D rotation:
 * QML has no depth buffer, so Y-axis rotations look wrong and cost perf).
 * The center card is dominant, side cards peek from behind, progressively
 * smaller and dimmer, with clean gaps so cards breathe.
 */
Item {
    id: root

    required property var folderModel
    required property string currentWallpaperPath
    property bool useDarkMode: Appearance.m3colors.darkmode

    signal wallpaperSelected(string filePath)
    signal directorySelected(string dirPath)
    signal closeRequested()
    signal switchToGridRequested()

    readonly property string currentFolderPath: String(folderModel?.folder ?? "")
    readonly property string currentFolderName: FileUtils.folderNameForPath(currentFolderPath)
    readonly property bool canGoBack: (folderModel?.currentFolderHistoryIndex ?? 0) > 0
    readonly property bool canGoForward: (folderModel?.currentFolderHistoryIndex ?? 0) < ((folderModel?.folderHistory?.length ?? 0) - 1)

    readonly property int totalCount: folderModel?.count ?? 0
    readonly property bool hasItems: totalCount > 0
    readonly property real _dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1
    readonly property real pageMargin: Math.max(22, Math.round(width * 0.02))
    readonly property real topInset: Math.max(64, Math.round(height * 0.09))
    readonly property real bottomInset: Math.max(140, Math.round(height * 0.18))

    // Card geometry (16:10 landscape)
    readonly property real cardW: Math.min(width * 0.42, 560)
    readonly property real cardH: Math.round(cardW * 0.625)

    readonly property int visiblePerSide: Math.max(
        2, Math.min(4, Math.floor(Math.max(1, (width - cardW * 0.7) / Math.max(1, cardW * 0.6)))))
    readonly property int slotCount: hasItems ? (1 + visiblePerSide * 2) : 0

    readonly property real cardRadius: Appearance.rounding.large
    readonly property real panelRadius: Appearance.rounding.normal
    readonly property color surfaceColor: Appearance.colors.colLayer1
    readonly property color elevatedColor: Appearance.colors.colLayer2
    readonly property color baseColor: Appearance.colors.colLayer0
    readonly property color textColor: Appearance.colors.colOnLayer1
    readonly property color subtleTextColor: Appearance.colors.colSubtext
    readonly property color borderColor: ColorUtils.applyAlpha(Appearance.colors.colOutlineVariant, 0.55)

    property string _lastThumbnailSizeName: "x-large"
    property int currentIndex: 0
    property bool _initialized: false
    property int _hoveredSlot: -999
    property bool showKeyboardGuide: true
    property int _wheelAccum: 0

    readonly property string _sideThumbnailSizeName: Images.thumbnailSizeNameForDimensions(
        Math.round(cardW * _dpr * 0.8), Math.round(cardH * _dpr * 0.8))

    function _filePath(i) {
        return (i >= 0 && i < totalCount) ? String(folderModel.get(i, "filePath") ?? "") : ""
    }
    function _fileName(i) {
        return (i >= 0 && i < totalCount) ? String(folderModel.get(i, "fileName") ?? "") : ""
    }
    function _fileIsDir(i) {
        return (i >= 0 && i < totalCount) ? Boolean(folderModel.get(i, "fileIsDir") ?? false) : false
    }
    function _fileUrl(i) {
        return (i >= 0 && i < totalCount) ? String(folderModel.get(i, "fileUrl") ?? "") : ""
    }

    function updateThumbnails() {
        const w = Math.round(cardW * _dpr * 2)
        const h = Math.round(cardH * _dpr * 2)
        let sizeName = Images.thumbnailSizeNameForDimensions(w, h)
        if (sizeName === "normal" || sizeName === "large") sizeName = "x-large"
        _lastThumbnailSizeName = sizeName
        Wallpapers.generateThumbnail(sizeName)
    }

    Timer {
        id: thumbnailDebounce
        interval: 150
        onTriggered: {
            if (root.totalCount <= 0 || root.cardW <= 8 || root.cardH <= 8) return
            root.updateThumbnails()
        }
    }

    function scaleAt(d) {
        if (d === 0) return 1.0
        const a = Math.abs(d)
        return Math.max(0.2, 0.72 * Math.pow(0.78, a - 1))
    }
    function opacityAt(d) {
        if (d === 0) return 1.0
        const a = Math.abs(d)
        return Math.max(0.06, 0.76 * Math.pow(0.7, a - 1))
    }
    function zAt(d) {
        return 500 - Math.abs(d) * 10
    }
    function xOffsetAt(d) {
        if (d === 0) return 0
        const sign = d > 0 ? 1 : -1
        const baseGap = root.cardW * 0.55
        let offset = baseGap
        for (let i = 2; i <= Math.abs(d); i++) {
            offset += baseGap * root.scaleAt(i - 1) * 0.78
        }
        return sign * offset
    }

    function _goToIndex(index) {
        if (!hasItems) return
        const next = Math.max(0, Math.min(totalCount - 1, index))
        currentIndex = next
        showKeyboardGuide = false
    }

    function moveSelection(delta) {
        _goToIndex(currentIndex + delta)
    }

    function activateCurrent() {
        if (totalCount === 0) return
        const fp = _filePath(currentIndex)
        showKeyboardGuide = false
        if (fp.length === 0) return
        if (_fileIsDir(currentIndex)) directorySelected(fp)
        else wallpaperSelected(fp)
    }

    function _scrollToCurrentWallpaper() {
        if (_initialized || totalCount === 0) return
        for (let i = 0; i < totalCount; i++) {
            if (FileUtils.trimFileProtocol(_filePath(i)) === FileUtils.trimFileProtocol(String(currentWallpaperPath ?? ""))) {
                currentIndex = i
                _initialized = true
                return
            }
        }
        _initialized = true
    }

    onCardWChanged: thumbnailDebounce.restart()
    onCardHChanged: thumbnailDebounce.restart()
    onTotalCountChanged: _scrollToCurrentWallpaper()
    Component.onCompleted: {
        _scrollToCurrentWallpaper()
        updateThumbnails()
    }

    Connections {
        target: root.folderModel
        function onFolderChanged() {
            root._initialized = false
            root.currentIndex = 0
            root._scrollToCurrentWallpaper()
            thumbnailDebounce.restart()
        }
    }
    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            thumbnailDebounce.restart()
        }
    }
    onCurrentWallpaperPathChanged: {
        _initialized = false
        _scrollToCurrentWallpaper()
    }

    Keys.onPressed: event => {
        const alt = (event.modifiers & Qt.AltModifier) !== 0
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0

        if (event.key === Qt.Key_Slash && !searchField.activeFocus) {
            searchField.forceActiveFocus()
            event.accepted = true
            return
        }

        switch (event.key) {
        case Qt.Key_Escape:
            root.closeRequested(); break
        case Qt.Key_Left:
            if (alt || ctrl) Wallpapers.navigateBack()
            else root.moveSelection(-(shift ? 3 : 1))
            break
        case Qt.Key_Right:
            if (alt || ctrl) Wallpapers.navigateForward()
            else root.moveSelection(shift ? 3 : 1)
            break
        case Qt.Key_Up:
            if (alt || ctrl) Wallpapers.navigateUp()
            else root.moveSelection(-root.visiblePerSide)
            break
        case Qt.Key_Down:
            root.moveSelection(root.visiblePerSide); break
        case Qt.Key_PageUp:
            root.moveSelection(-root.visiblePerSide); break
        case Qt.Key_PageDown:
            root.moveSelection(root.visiblePerSide); break
        case Qt.Key_Home:
            root.currentIndex = 0; break
        case Qt.Key_End:
            root.currentIndex = Math.max(0, root.totalCount - 1); break
        case Qt.Key_Return: case Qt.Key_Enter:
            root.activateCurrent(); break
        case Qt.Key_Backspace:
            if (alt || ctrl) Wallpapers.navigateUp()
            else { event.accepted = false; return }
            break
        default:
            event.accepted = false; return
        }
        event.accepted = true
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.showKeyboardGuide = false
            const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
            root._wheelAccum += d
            const steps = root._wheelAccum >= 0
                ? Math.floor(root._wheelAccum / 120)
                : Math.ceil(root._wheelAccum / 120)
            if (steps !== 0) {
                root._wheelAccum -= steps * 120
                root.moveSelection(-steps)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ColorUtils.applyAlpha(root.baseColor, 0.1)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.09) }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1.0; color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.09) }
        }
    }

    // ─── Top pill: counter + folder ───
    Rectangle {
        id: topPill
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: root.pageMargin
        }
        implicitWidth: Math.max(220, topRow.implicitWidth + 24)
        implicitHeight: topRow.implicitHeight + 18
        radius: Appearance.rounding.full
        color: root.surfaceColor
        border.width: 1
        border.color: root.borderColor

        RowLayout {
            id: topRow
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            StyledText {
                text: root.totalCount > 0 ? "%1 / %2".arg(root.currentIndex + 1).arg(root.totalCount) : "0 / 0"
                color: root.subtleTextColor
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.monospace
            }
            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: root.borderColor
                opacity: 0.3
            }
            MaterialSymbol {
                text: "wallpaper"
                iconSize: Appearance.font.pixelSize.small
                color: root.subtleTextColor
            }
            StyledText {
                text: root.currentFolderName || Translation.tr("Wallpapers")
                color: root.subtleTextColor
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }
        }
    }

    // ─── Center stage ───
    Item {
        id: stageArea
        anchors {
            top: parent.top
            topMargin: root.topInset
            left: parent.left
            right: parent.right
            bottom: toolbarArea.top
            bottomMargin: root.pageMargin
        }

        Repeater {
            model: root.slotCount

            delegate: Item {
                id: slot
                required property int index

                readonly property int offset: index - root.visiblePerSide
                readonly property int modelIdx: root.currentIndex + offset
                readonly property bool hasData: modelIdx >= 0 && modelIdx < root.totalCount
                readonly property string filePath: hasData ? root._filePath(modelIdx) : ""
                readonly property string fileName: hasData ? root._fileName(modelIdx) : ""
                readonly property bool fileIsDir: hasData ? root._fileIsDir(modelIdx) : false
                readonly property url fileUrl: hasData ? root._fileUrl(modelIdx) : ""
                readonly property bool isCurrent: offset === 0
                readonly property bool isActive: filePath.length > 0
                    && FileUtils.trimFileProtocol(filePath) === FileUtils.trimFileProtocol(String(root.currentWallpaperPath ?? ""))
                readonly property bool isHovered: root._hoveredSlot === offset && !isCurrent

                visible: hasData
                width: root.cardW
                height: root.cardH
                x: stageArea.width / 2 - width / 2 + root.xOffsetAt(offset)
                y: (stageArea.height - height) / 2
                z: root.zAt(offset) + (isHovered ? 5 : 0)
                scale: root.scaleAt(offset) * (isHovered ? 1.03 : 1.0)
                opacity: isCurrent ? 1.0 : root.opacityAt(offset)

                Behavior on x {
                    enabled: Appearance.animation.elementMoveEnter.duration > 0
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
                Behavior on scale {
                    enabled: Appearance.animation.elementMoveEnter.duration > 0
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
                Behavior on opacity {
                    enabled: Appearance.animation.elementMoveFast.duration > 0
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                StyledRectangularShadow {
                    target: card
                    radius: card.radius
                    opacity: slot.isCurrent ? 0.24 : 0.1
                }

                Rectangle {
                    id: card
                    anchors.fill: parent
                    radius: root.cardRadius
                    color: root.surfaceColor
                    clip: true
                    border.width: slot.isCurrent ? 2 : slot.isActive ? 1.4 : 0.6
                    border.color: slot.isCurrent ? Appearance.colors.colPrimary
                        : slot.isActive ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.7)
                        : root.borderColor

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    Loader {
                        active: slot.hasData && slot.fileIsDir
                        anchors.fill: parent
                        anchors.margins: 1
                        sourceComponent: DirectoryIcon {
                            fileModelData: ({
                                filePath: slot.filePath,
                                fileName: slot.fileName,
                                fileIsDir: slot.fileIsDir,
                                fileUrl: slot.fileUrl
                            })
                        }
                    }

                    ThumbnailImage {
                        id: thumb
                        anchors.fill: parent
                        readonly property bool shouldShow: slot.hasData && !slot.fileIsDir
                            && slot.filePath.length > 0 && Images.isValidImageByName(slot.fileName)
                        visible: shouldShow
                        generateThumbnail: false
                        sourcePath: shouldShow ? slot.filePath : ""
                        thumbnailSizeName: slot.isCurrent ? root._lastThumbnailSizeName : root._sideThumbnailSizeName
                        cache: true
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        mipmap: false

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: thumb.width
                                height: thumb.height
                                radius: root.cardRadius
                            }
                        }

                        Connections {
                            target: Wallpapers
                            function onThumbnailGeneratedFile(filePath) {
                                if (thumb.status !== Image.Error) return
                                if (Qt.resolvedUrl(thumb.sourcePath) !== Qt.resolvedUrl(filePath)) return
                                thumb.source = ""
                                thumb.source = thumb.thumbnailPath
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: root.cardRadius
                        color: root.baseColor
                        opacity: slot.isCurrent ? 0.0 : slot.isHovered ? 0.04
                            : Math.min(0.44, 0.1 + Math.abs(slot.offset) * 0.075)
                    }

                    // Info strip
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: infoStrip.implicitHeight + 18
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.55; color: ColorUtils.applyAlpha(Appearance.colors.colScrim, slot.isCurrent ? 0.2 : 0.5) }
                            GradientStop { position: 1.0; color: ColorUtils.applyAlpha(Appearance.colors.colScrim, slot.isCurrent ? 0.74 : 0.84) }
                        }

                        ColumnLayout {
                            id: infoStrip
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 12
                            }
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: typeLabel.implicitWidth + 12
                                    implicitHeight: typeLabel.implicitHeight + 6
                                    radius: height / 2
                                    color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
                                    border.width: 1
                                    border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.38)

                                    StyledText {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: slot.fileIsDir ? Translation.tr("Folder") : Translation.tr("Wallpaper")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer0
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    visible: slot.isActive
                                    implicitWidth: activeBadgeText.implicitWidth + 14
                                    implicitHeight: activeBadgeText.implicitHeight + 6
                                    radius: height / 2
                                    color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.9)

                                    StyledText {
                                        id: activeBadgeText
                                        anchors.centerIn: parent
                                        text: Translation.tr("Active")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: slot.fileName
                                font.pixelSize: slot.isCurrent ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
                                font.weight: slot.isCurrent ? Font.DemiBold : Font.Medium
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideMiddle
                                maximumLineCount: 1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: slot.isCurrent
                                text: {
                                    if (!root.hasItems) return Translation.tr("No wallpapers in this folder")
                                    if (slot.fileIsDir) return Translation.tr("Open folder")
                                    if (slot.isActive) return Translation.tr("Current wallpaper")
                                    return Translation.tr("Ready to apply")
                                }
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.84)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root._hoveredSlot = slot.offset
                        onExited: {
                            if (root._hoveredSlot === slot.offset)
                                root._hoveredSlot = -999
                        }
                        onClicked: {
                            root.showKeyboardGuide = false
                            if (slot.isCurrent) {
                                if (slot.fileIsDir) root.directorySelected(slot.filePath)
                                else root.wallpaperSelected(slot.filePath)
                            } else {
                                root._goToIndex(slot.modelIdx)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(stageArea.width * 0.6, 420)
            height: emptyColumn.implicitHeight + 28
            radius: root.cardRadius
            color: ColorUtils.applyAlpha(root.surfaceColor, 0.92)
            border.width: 1
            border.color: root.borderColor
            visible: !root.hasItems

            ColumnLayout {
                id: emptyColumn
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "imagesmode"
                    iconSize: 36
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("No wallpapers found here")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    color: root.textColor
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Try another folder, go up one level, or clear the current search.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: root.subtleTextColor
                }
            }
        }

        // Arrow buttons
        Repeater {
            model: 2
            delegate: RippleButton {
                required property int index
                readonly property bool isLeft: index === 0

                anchors {
                    left: isLeft ? parent.left : undefined
                    right: isLeft ? undefined : parent.right
                    leftMargin: 12
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: 52
                implicitHeight: 52
                buttonRadius: 26
                visible: root.totalCount > 1
                    && (isLeft ? root.currentIndex > 0 : root.currentIndex < root.totalCount - 1)
                opacity: visible ? 0.9 : 0.0
                z: 100
                colBackground: root.surfaceColor
                colBackgroundHover: root.elevatedColor

                onClicked: root.moveSelection(isLeft ? -1 : 1)

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: isLeft ? "chevron_left" : "chevron_right"
                    iconSize: 26
                    color: root.textColor
                }

                StyledRectangularShadow {
                    target: parent
                    radius: 26
                    opacity: 0.14
                }
            }
        }

        // Click empty area to close
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.BackButton | Qt.ForwardButton
            onClicked: {
                root.closeRequested()
            }
            onPressed: event => {
                if (event.button === Qt.BackButton) Wallpapers.navigateBack()
                else if (event.button === Qt.ForwardButton) Wallpapers.navigateForward()
                else event.accepted = false
            }
        }
    }

    // Keyboard hint pill
    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: toolbarArea.top
            bottomMargin: 14
        }
        visible: root.showKeyboardGuide
        opacity: visible ? 1.0 : 0.0
        z: 220
        radius: height / 2
        color: ColorUtils.applyAlpha(Appearance.colors.colScrim, 0.72)
        width: guideText.implicitWidth + 24
        height: guideText.implicitHeight + 10
        Behavior on opacity {
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }

        StyledText {
            id: guideText
            anchors.centerIn: parent
            text: Translation.tr("/ Search  ·  Arrows Navigate  ·  Enter Apply  ·  Esc Close")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnLayer0
        }
    }

    // ─── Toolbar ───
    Toolbar {
        id: toolbarArea
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 22
        }

        IconToolbarButton {
            implicitWidth: height
            enabled: root.canGoBack
            onClicked: Wallpapers.navigateBack()
            text: "arrow_back"
            StyledToolTip { text: Translation.tr("Back") }
        }
        IconToolbarButton {
            implicitWidth: height
            onClicked: Wallpapers.navigateUp()
            text: "arrow_upward"
            StyledToolTip { text: Translation.tr("Up") }
        }
        IconToolbarButton {
            implicitWidth: height
            enabled: root.canGoForward
            onClicked: Wallpapers.navigateForward()
            text: "arrow_forward"
            StyledToolTip { text: Translation.tr("Forward") }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: Math.min(root.width * 0.16, 220)
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.textColor
            text: root.currentFolderName || "/"
            elide: Text.ElideMiddle
            maximumLineCount: 1
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 16
            color: root.borderColor
            opacity: 0.2
        }

        IconToolbarButton {
            implicitWidth: height
            onClicked: root.useDarkMode = !root.useDarkMode
            text: root.useDarkMode ? "dark_mode" : "light_mode"
            StyledToolTip { text: Translation.tr("Toggle light/dark mode") }
        }
        IconToolbarButton {
            implicitWidth: height
            onClicked: Wallpapers.randomFromCurrentFolder(root.useDarkMode)
            text: "shuffle"
            StyledToolTip { text: Translation.tr("Random wallpaper") }
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 16
            color: root.borderColor
            opacity: 0.2
        }

        Item { Layout.fillWidth: true }

        ToolbarTextField {
            id: searchField
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(root.width * 0.22, 300)
            implicitHeight: 38
            placeholderText: activeFocus ? Translation.tr("Search wallpapers") : Translation.tr("Hit \"/\" to search")
            text: Wallpapers.searchQuery
            onTextChanged: Wallpapers.searchQuery = text
        }

        IconToolbarButton {
            implicitWidth: height
            enabled: (Wallpapers.searchQuery ?? "").length > 0
            onClicked: Wallpapers.searchQuery = ""
            text: "backspace"
            StyledToolTip { text: Translation.tr("Clear search") }
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 16
            color: root.borderColor
            opacity: 0.2
        }

        IconToolbarButton {
            implicitWidth: height
            onClicked: root.switchToGridRequested()
            text: "grid_view"
            StyledToolTip { text: Translation.tr("Switch to grid view") }
        }
        IconToolbarButton {
            implicitWidth: height
            onClicked: root.closeRequested()
            text: "close"
            StyledToolTip { text: Translation.tr("Close") }
        }
    }
}