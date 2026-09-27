pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.settings

// Waffle-specific options. This is the page that exercises the ported
// WSettings* components directly (cards, rows, switches, text field), so the
// iNiR chrome is functional and not just chrome around borrowed pages.
Item {
    id: root

    readonly property int pagePadding: Looks.dp(16)

    implicitWidth: Looks.dp(560)
    implicitHeight: pageFlick.contentHeight

    readonly property string togglesValue: (Config.ready && Config.options.waffles.actionCenter.toggles)
        ? Config.options.waffles.actionCenter.toggles.join(", ")
        : ""

    function commitToggles(value) {
        const parsed = value
            .split(",")
            .map((entry) => entry.trim())
            .filter((entry) => entry.length > 0);
        Config.options.waffles.actionCenter.toggles = parsed;
    }

    Flickable {
        id: pageFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: cards.implicitHeight + root.pagePadding * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: cards
            x: root.pagePadding
            y: root.pagePadding
            width: pageFlick.width - root.pagePadding * 2
            spacing: Looks.dp(10)

        WSettingsCard {
            Layout.fillWidth: true
            title: Translation.tr("Tweaks")
            icon: "options"
            description: Translation.tr("Small consistency fixes for the waffle menus and controls.")

            WSettingsSwitch {
                icon: "checkmark"
                label: Translation.tr("Switch handle position fix")
                description: Translation.tr("Keeps switch handles from visually overflowing their track.")
                checked: Config.ready ? Config.options.waffles.tweaks.switchHandlePositionFix : false
                onCheckedChanged: {
                    if (!Config.ready)
                        return;
                    Config.options.waffles.tweaks.switchHandlePositionFix = checked;
                            }
            }

            WSettingsSwitch {
                icon: "wand"
                label: Translation.tr("Smoother menu animations")
                description: Translation.tr("Replaces the linear menu transitions with eased ones.")
                checked: Config.ready ? Config.options.waffles.tweaks.smootherMenuAnimations : false
                onCheckedChanged: {
                    if (!Config.ready)
                        return;
                    Config.options.waffles.tweaks.smootherMenuAnimations = checked;
                            }
            }

            WSettingsSwitch {
                icon: "search"
                label: Translation.tr("Smoother search bar")
                description: Translation.tr("Animated search field background and cursor transitions.")
                checked: Config.ready ? Config.options.waffles.tweaks.smootherSearchBar : false
                onCheckedChanged: {
                    if (!Config.ready)
                        return;
                    Config.options.waffles.tweaks.smootherSearchBar = checked;
                            }
            }
        }

        WSettingsCard {
            Layout.fillWidth: true
            title: Translation.tr("Bar")
            icon: "apps"

            WSettingsSwitch {
                icon: "caret-down"
                label: Translation.tr("Bottom bar")
                description: Translation.tr("Dock the bar to the bottom edge instead of the top.")
                checked: Config.ready ? Config.options.waffles.bar.bottom : true
                onCheckedChanged: {
                    if (!Config.ready)
                        return;
                    Config.options.waffles.bar.bottom = checked;
                            }
            }

            WSettingsSwitch {
                icon: "chevron-left"
                label: Translation.tr("Left align running apps")
                description: Translation.tr("Keep the app list anchored to the left of the bar.")
                checked: Config.ready ? Config.options.waffles.bar.leftAlignApps : false
                onCheckedChanged: {
                    if (!Config.ready)
                        return;
                    Config.options.waffles.bar.leftAlignApps = checked;
                            }
            }
        }

        WSettingsCard {
            Layout.fillWidth: true
            title: Translation.tr("Action center")
            icon: "widgets"
            description: Translation.tr("Comma separated list of the tiles shown in the quick settings area.")

            WSettingsTextField {
                icon: "list"
                label: Translation.tr("Quick settings tiles")
                placeholder: "network, bluetooth, nightLight"
                text: root.togglesValue
                onEditingFinished: (value) => root.commitToggles(value)
            }
        }

        WSettingsCard {
            Layout.fillWidth: true
            title: Translation.tr("Calendar")
            icon: "calendar-add"

            WSettingsSwitch {
                icon: "caret-down"
                label: Translation.tr("Two character weekdays")
                description: Translation.tr("Render weekdays as short two letter labels in the calendar.")
                checked: Config.ready ? Config.options.waffles.calendar.force2CharDayOfWeek : true
                onCheckedChanged: {
                    if (!Config.ready)
                        return;
                    Config.options.waffles.calendar.force2CharDayOfWeek = checked;
                            }
            }
        }
        }
    }
}
