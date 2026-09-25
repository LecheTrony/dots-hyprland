import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool presented: false
    property bool closing: false
    readonly property string monitorName: screen?.name ?? ""

    visible: presented || closing
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0] ?? null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:wallpaperLauncher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.wallpaperLauncherOpen
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    anchors { top: true; right: true; bottom: true; left: true }

    Component.onCompleted: {
        if (GlobalStates.wallpaperLauncherOpen)
            Qt.callLater(() => root.presented = true)
    }

    Connections {
        target: GlobalStates
        function onWallpaperLauncherOpenChanged(): void {
            if (GlobalStates.wallpaperLauncherOpen) {
                closeTimer.stop()
                root.presented = true
                root.closing = false
            } else {
                root.closing = true
                root.presented = false
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.closing = false
    }

    // Dim the backdrop
    Rectangle {
        anchors.fill: parent
        color: ColorUtils.applyAlpha(Appearance.colors.colScrim, 0.4)
        opacity: root.presented ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.presented ? 320 : 180
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: GlobalStates.wallpaperLauncherOpen
        onClicked: mouse => {
            const local = mapToItem(content, mouse.x, mouse.y)
            if (local.x < 0 || local.x > content.width
                    || local.y < 0 || local.y > content.height)
                GlobalStates.wallpaperLauncherOpen = false
            else
                mouse.accepted = false
        }
    }

    WallpaperLauncherContent {
        id: content
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Math.max(18, Appearance.sizes.hyprlandGapsOut * 2)
        }
        width: Math.min(implicitWidth,
            parent.width - Math.max(36, Appearance.sizes.hyprlandGapsOut * 4))
        height: implicitHeight
        transformOrigin: Item.Bottom
        scale: root.presented ? 1 : (root.closing ? 0.985 : 0.96)
        opacity: root.presented ? 1 : 0
        Behavior on scale {
            enabled: Appearance.animation.elementMoveEnter.duration > 0
            NumberAnimation {
                duration: root.presented
                    ? Appearance.animation.elementMoveEnter.duration
                    : Appearance.animation.elementMoveExit.duration
                easing.type: root.presented
                    ? Appearance.animation.elementMoveEnter.type
                    : Appearance.animation.elementMoveExit.type
                easing.bezierCurve: root.presented
                    ? Appearance.animation.elementMoveEnter.bezierCurve
                    : Appearance.animation.elementMoveExit.bezierCurve
            }
        }
        Behavior on opacity {
            enabled: Appearance.animation.elementMoveEnter.duration > 0
            NumberAnimation {
                duration: root.presented
                    ? Appearance.animation.elementMoveEnter.duration
                    : Appearance.animation.elementMoveExit.duration
                easing.type: Easing.OutCubic
            }
        }
    }
}