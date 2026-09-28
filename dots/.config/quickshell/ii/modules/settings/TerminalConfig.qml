import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Terminal settings, shared by the ii and waffle menus. Kitty reads the values
// from the override file this writes, so changes land in the running terminal
// without a restart.
ContentPage {
    id: root
    forceWidth: true

    readonly property bool usesKitty: (Config.options.apps.terminal || "").startsWith("kitty")

    ContentSection {
        icon: "opacity"
        title: Translation.tr("Transparency")

        ContentSubsection {
            title: Translation.tr("Background opacity")
            tooltip: Translation.tr("How solid the terminal background is. Lower values let more of the blurred desktop show through.")

            ConfigSlider {
                text: Translation.tr("Background opacity")
                buttonIcon: "contrast"
                from: 50
                to: 100
                value: Math.round((KittyConf.opacity * 100) * 100) / 100
                onValueChanged: {
                    Config.options.terminal.opacity = value / 100;
                    KittyConf.scheduleWrite();
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 6
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
            text: root.usesKitty
                ? Translation.tr("The blur behind the terminal is drawn by the compositor and is already enabled for kitty. At 100% the background is fully opaque, so no blur is visible.")
                : Translation.tr("These settings are written to kitty, but your launcher is set to \"%1\". Change it in Services to have them apply.").arg(Config.options.apps.terminal)
        }
    }

    ContentSection {
        icon: "palette"
        title: Translation.tr("Colors")

        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Match terminal colors to wallpaper")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Applies the next time the wallpaper changes. Requires shell and utilities theming to be enabled.")
            }
        }
    }
}
