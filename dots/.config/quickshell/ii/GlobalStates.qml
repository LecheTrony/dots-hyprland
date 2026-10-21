import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool desktopWidgetKeyboardFocus: false
    property bool sidebarLeftOpen: false
    property bool sidebarLeftHoldOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property list<real> visualizerPoints: CavaVisualizer.points
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool panelFamilyPickerOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool wallpaperLauncherOpen: false
    property string wallpaperLauncherMode: "static"
    property bool coverflowSelectorOpen: false
    property string wallpaperSelectionTarget: "main"
    property string wallpaperSelectorTargetMonitor: ""
    property bool workspaceShowNumbers: false

    // Centered wallpaper shapes available for scroll-wheel cycling.
    readonly property var centeredWallpaperShapeCycle: [
        "Circle", "Square", "Cookie12Sided", "Clover4Leaf", "Pill", "Heart"
    ]

    function cycleCenteredWallpaperShape(direction) {
        const shapes = root.centeredWallpaperShapeCycle;
        if (shapes.length === 0) return;
        const current = Config.options.background.centeredWallpaperShape;
        let index = shapes.indexOf(current);
        if (index === -1) index = 0;
        index = (index + (direction > 0 ? 1 : -1) + shapes.length) % shapes.length;
        Config.options.background.centeredWallpaperShape = shapes[index];
    }

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}