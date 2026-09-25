import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.ii.wallpaperSelector
import QtQuick
import Quickshell

PathView {
    id: root

    required property var folderModel
    required property string currentWallpaperPath
    property int maxVisibleItems: 5
    property real cardWidth: 240
    property real cardHeight: Math.round(cardWidth / (4 / 3))

    signal applyRequested(string path)
    signal directoryRequested(string path)

    readonly property real itemWidth: cardWidth
    readonly property int visibleItems: {
        let visible = Math.min(maxVisibleItems, count)
        if (visible === 2) return 1
        if (visible > 1 && visible % 2 === 0) visible--
        return visible
    }
    readonly property string selectedPath:
        model.get(currentIndex, "filePath") ?? ""

    implicitWidth: itemWidth * Math.max(1, visibleItems)
    implicitHeight: cardHeight
    pathItemCount: visibleItems
    cacheItemCount: 4
    interactive: count > 1
    snapMode: PathView.SnapToItem
    highlightMoveDuration: Appearance.animation.elementMoveFast.duration
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    model: root.folderModel

    Component.onCompleted: Qt.callLater(syncCurrentIndex)
    onCountChanged: syncCurrentIndex()
    onCurrentWallpaperPathChanged: Qt.callLater(syncCurrentIndex)

    function syncCurrentIndex(): void {
        if (count === 0) {
            root.currentIndex = 0
            return
        }
        const target = FileUtils.trimFileProtocol(String(root.currentWallpaperPath ?? ""))
        for (let i = 0; i < count; i++) {
            if (FileUtils.trimFileProtocol(String(model.get(i, "filePath") ?? "")) === target) {
                root.currentIndex = i
                return
            }
        }
        root.currentIndex = 0
    }

    function moveSelection(delta: int): void {
        if (count <= 0) return
        const steps = Math.abs(delta)
        for (let step = 0; step < steps; step++) {
            if (delta > 0)
                incrementCurrentIndex()
            else if (delta < 0)
                decrementCurrentIndex()
        }
    }

    function activateCurrent(): void {
        const path = model.get(currentIndex, "filePath")
        const isDir = Boolean(model.get(currentIndex, "fileIsDir") ?? false)
        if (path) {
            if (isDir) root.directoryRequested(path)
            else root.applyRequested(path)
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.moveSelection(event.angleDelta.y > 0 ? -1 : 1)
            event.accepted = true
        }
    }

    delegate: WallpaperLauncherItem {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        onActivated: selectedIndex => {
            const path = root.model.get(selectedIndex, "filePath")
            const isDir = Boolean(root.model.get(selectedIndex, "fileIsDir") ?? false)
            if (path) {
                if (isDir) root.directoryRequested(path)
                else root.applyRequested(path)
            }
        }
    }

    path: Path {
        startY: root.height / 2
        PathAttribute { name: "z"; value: 0 }
        PathLine { x: root.width / 2; relativeY: 0 }
        PathAttribute { name: "z"; value: 1 }
        PathLine { x: root.width; relativeY: 0 }
    }
}