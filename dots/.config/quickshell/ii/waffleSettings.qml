//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Waffle-flavoured settings window. Visual language ported from the iNiR
// reference (Win11 style nav rail, searchable pages, card chrome) while the
// options themselves are the very same config pages the ii window uses.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.settings

ApplicationWindow {
    id: root

    property var pages: [
        {
            name: Translation.tr("Waffle"),
            icon: "widgets",
            description: Translation.tr("Waffle-specific tweaks for the bar, action center and calendar."),
            keywords: ["waffle", "bar", "quick settings", "calendar"],
            component: Quickshell.shellPath("modules/waffle/settings/WaffleConfig.qml")
        },
        {
            name: Translation.tr("Quick"),
            icon: "wand",
            keywords: ["preset", "wizard", "setup"],
            component: Quickshell.shellPath("modules/settings/QuickConfig.qml")
        },
        {
            name: Translation.tr("General"),
            icon: "options",
            keywords: ["language", "autostart", "wipe", "hostname"],
            component: Quickshell.shellPath("modules/settings/GeneralConfig.qml")
        },
        {
            name: Translation.tr("Bar"),
            icon: "apps",
            keywords: ["height", "margin", "anchor", "workspaces"],
            component: Quickshell.shellPath("modules/settings/BarConfig.qml")
        },
        {
            name: Translation.tr("Background"),
            icon: "image",
            keywords: ["wallpaper", "color", "shader", "blur"],
            component: Quickshell.shellPath("modules/settings/BackgroundConfig.qml")
        },
        {
            name: Translation.tr("Interface"),
            icon: "dark-theme",
            keywords: ["theme", "dark", "light", "font", "icon", "cursor"],
            component: Quickshell.shellPath("modules/settings/InterfaceConfig.qml")
        },
        {
            name: Translation.tr("Services"),
            icon: "settings",
            keywords: ["audio", "network", "bluetooth", "battery", "weather"],
            component: Quickshell.shellPath("modules/settings/ServicesConfig.qml")
        },
        {
            name: Translation.tr("Advanced"),
            icon: "settings-cog-multiple",
            keywords: ["ipc", "dev", "logs", "debug"],
            component: Quickshell.shellPath("modules/settings/AdvancedConfig.qml")
        },
        {
            name: Translation.tr("Display"),
            icon: "desktop",
            keywords: ["scale", "refresh", "output", "hdmi"],
            component: Quickshell.shellPath("modules/settings/DisplayConfig.qml")
        },
        {
            name: Translation.tr("About"),
            icon: "info",
            keywords: ["version", "license", "credits"],
            component: Quickshell.shellPath("modules/settings/About.qml")
        }
    ]

    visible: true
    onClosing: Qt.quit()
    title: "Waffle Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0
    }

    minimumWidth: 900
    minimumHeight: 560
    width: 1240
    height: 760
    color: Looks.colors.bg0Base

    WSettingsShell {
        id: shell

        anchors {
            fill: parent
            margins: Looks.dp(6)
        }

        pages: root.pages
        currentPage: 0

        onCloseRequested: root.close()
    }
}
