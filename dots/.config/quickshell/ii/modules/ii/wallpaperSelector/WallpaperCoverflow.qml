import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property var defaultScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0] ?? null

    readonly property var targetScreen: {
        const targetMon = GlobalStates.wallpaperSelectorTargetMonitor
            || (Config.options?.wallpaperSelector?.targetMonitor ?? "")
        if (GlobalStates.wallpaperSelectorTargetMonitor || targetMon) {
            const s = Quickshell.screens.find(s => s.name === targetMon)
            if (s) return s
        }
        return root.defaultScreen
    }

    property bool _closing: false

    Timer {
        id: _closeTimer
        interval: 250
        repeat: false
        onTriggered: root._closing = false
    }

    Connections {
        target: GlobalStates
        function onCoverflowSelectorOpenChanged() {
            if (!GlobalStates.coverflowSelectorOpen && coverflowLoader.item) {
                root._closing = true
                _closeTimer.restart()
            }
        }
    }

    Loader {
        id: coverflowLoader
        active: GlobalStates.coverflowSelectorOpen || root._closing

        sourceComponent: PanelWindow {
            id: panelWindow
            screen: root.targetScreen

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:coverflowSelector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root._closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.applyAlpha(Appearance.colors.colScrim, 0.5)
                opacity: root._closing ? 0 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: root._closing ? 180 : 320
                        easing.type: Easing.OutCubic
                    }
                }
            }

            WallpaperCoverflowContent {
                id: content
                anchors.fill: parent
                focus: true
                folderModel: Wallpapers.folderModel
                currentWallpaperPath: Config.options.background.wallpaperPath

                onWallpaperSelected: filePath => {
                    Wallpapers.select(filePath, content.useDarkMode)
                }
                onDirectorySelected: dirPath => {
                    Wallpapers.setDirectory(dirPath)
                }
                onCloseRequested: {
                    GlobalStates.coverflowSelectorOpen = false
                }
                onSwitchToGridRequested: {
                    GlobalStates.coverflowSelectorOpen = false
                    Config.setNestedValue("wallpaperSelector.style", "grid")
                    gridSwitchTimer.restart()
                }

                Timer {
                    id: gridSwitchTimer
                    interval: 80
                    repeat: false
                    onTriggered: GlobalStates.wallpaperSelectorOpen = true
                }

                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}