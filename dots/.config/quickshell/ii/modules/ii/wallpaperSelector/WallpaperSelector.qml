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
import qs.modules.ii.wallpaperLauncher

Scope {
    id: root

    Loader {
        id: wallpaperSelectorLoader
        active: GlobalStates.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaperSelector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            mask: Region {
                item: content
            }

            implicitHeight: Appearance.sizes.wallpaperSelectorHeight
            implicitWidth: Appearance.sizes.wallpaperSelectorWidth

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }

            WallpaperSelectorContent {
                id: content
                anchors {
                    fill: parent
                }
            }
        }
    }

    Loader {
        id: coverflowSelectorLoader
        active: GlobalStates.coverflowSelectorOpen
        sourceComponent: WallpaperCoverflow {}
    }

    Loader {
        id: wallpaperLauncherLoader
        active: GlobalStates.wallpaperLauncherOpen
        sourceComponent: WallpaperLauncher {}
    }

    readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""

    function openGrid() {
        GlobalStates.coverflowSelectorOpen = false;
        GlobalStates.wallpaperLauncherOpen = false;
        GlobalStates.wallpaperSelectorOpen = true;
    }

    function toggleCoverflow() {
        if (GlobalStates.coverflowSelectorOpen) {
            GlobalStates.coverflowSelectorOpen = false;
            return;
        }
        GlobalStates.wallpaperSelectorOpen = false;
        GlobalStates.wallpaperLauncherOpen = false;
        GlobalStates.wallpaperSelectorTargetMonitor = root.focusedMonitorName;
        GlobalStates.coverflowSelectorOpen = true;
    }

    function openLauncher(mode: string) {
        const nextMode = mode === "animated" ? "animated" : "static";
        GlobalStates.wallpaperSelectorOpen = false;
        GlobalStates.coverflowSelectorOpen = false;
        GlobalStates.wallpaperLauncherMode = nextMode;
        GlobalStates.wallpaperSelectorTargetMonitor = root.focusedMonitorName;
        GlobalStates.wallpaperLauncherOpen = true;
    }

    function toggle() {
        if (GlobalStates.wallpaperLauncherOpen) {
            GlobalStates.wallpaperLauncherOpen = false;
            return;
        }
        if (GlobalStates.coverflowSelectorOpen) {
            GlobalStates.coverflowSelectorOpen = false;
            return;
        }
        if (Config.options.wallpaperSelector.useSystemFileDialog) {
            Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode);
            return;
        }
        const selectorStyle = String(Config.options.wallpaperSelector.style ?? "grid");
        if (selectorStyle === "launcher") {
            root.openLauncher("");
            return;
        }
        if (selectorStyle === "coverflow") {
            root.toggleCoverflow();
            return;
        }
        GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            if (!GlobalStates.wallpaperSelectorOpen
                    && !GlobalStates.wallpaperLauncherOpen
                    && !GlobalStates.coverflowSelectorOpen)
                root.toggle();
        }

        function close(): void {
            GlobalStates.wallpaperSelectorOpen = false;
            GlobalStates.wallpaperLauncherOpen = false;
            GlobalStates.coverflowSelectorOpen = false;
        }

        function openLauncher(mode: string): void {
            root.openLauncher(mode);
        }

        function random(): void {
            Wallpapers.randomFromCurrentFolder();
        }

        function set(path: string): void {
            Wallpapers.select(path);
        }

        function status(): string {
            return JSON.stringify({
                style: String(Config.options.wallpaperSelector.style ?? "grid"),
                gridOpen: GlobalStates.wallpaperSelectorOpen,
                launcherOpen: GlobalStates.wallpaperLauncherOpen,
                coverflowOpen: GlobalStates.coverflowSelectorOpen,
                focusedMonitor: root.focusedMonitorName,
                selectionTarget: "main"
            });
        }
    }

    IpcHandler {
        target: "coverflowSelector"

        function toggle(): void {
            root.toggleCoverflow();
        }

        function open(): void {
            if (!GlobalStates.coverflowSelectorOpen)
                root.toggleCoverflow();
        }

        function close(): void {
            GlobalStates.coverflowSelectorOpen = false;
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    GlobalShortcut {
        name: "coverflowSelectorToggle"
        description: "Toggle coverflow wallpaper selector"
        onPressed: {
            root.toggleCoverflow();
        }
    }
}