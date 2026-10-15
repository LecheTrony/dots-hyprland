import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "view_quilt"
        title: Translation.tr("Desktop Widgets")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "lock"
                text: Translation.tr("Lock widgets")
                checked: Config.options.background.widgetsLocked
                onCheckedChanged: {
                    Config.options.background.widgetsLocked = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "grid_on"
                text: Translation.tr("Show grid")
                checked: Config.options.background.showGrid
                onCheckedChanged: {
                    Config.options.background.showGrid = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "linear_scale"
                text: Translation.tr("Show snap lines")
                checked: Config.options.background.showSnapLines
                onCheckedChanged: {
                    Config.options.background.showSnapLines = checked;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "screen_lock_portrait"
            text: Translation.tr("Show widgets when locked")
            checked: Config.options.lock.showWidgets
            onCheckedChanged: {
                Config.options.lock.showWidgets = checked;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Widget Toggles")

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: DesktopWidgets.catalog
                delegate: RippleButton {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    property bool widgetEnabled: DesktopWidgets.isEnabled(modelData.key)
                    colBackground: widgetEnabled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                    colBackgroundHover: widgetEnabled ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colPrimary
                    onClicked: {
                        DesktopWidgets.setEnabled(modelData.key, !widgetEnabled)
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        MaterialSymbol {
                            Layout.leftMargin: 6
                            text: modelData.icon
                            iconSize: 28
                            color: widgetEnabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            Layout.fillWidth: true
                            Layout.rightMargin: 6
                            text: modelData.name
                            color: widgetEnabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "image"
        title: Translation.tr("Image Widgets")

        Process {
            id: imagePickerProc
            property string targetKey: ""
            command: [
                "zenity", "--file-selection",
                "--title=" + Translation.tr("Choose an image"),
                "--file-filter=" + Translation.tr("Images") + " | *.png *.jpg *.jpeg *.webp *.avif *.bmp *.gif *.tiff *.tif"
            ]
            stdout: StdioCollector {
                id: imagePickerOutput
                onStreamFinished: {
                    const p = imagePickerOutput.text.trim();
                    if (p.length > 0 && imagePickerProc.targetKey.length > 0) {
                        Config.options.background.widgets[imagePickerProc.targetKey].path = p;
                    }
                }
            }
        }

        Repeater {
            model: [
                { key: "customImage", icon: "image", name: Translation.tr("Custom Image") },
                { key: "imageCard", icon: "photo_size_select_large", name: Translation.tr("Image Card") },
                { key: "sticker", icon: "sticker", name: Translation.tr("Sticker") }
            ]
            delegate: RippleButtonWithIcon {
                required property var modelData
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: modelData.icon
                mainText: {
                    const p = Config.options.background.widgets[modelData.key].path;
                    return modelData.name + " · " + ((p && p.length > 0) ? p.replace(/^.*\//, "") : Translation.tr("no image"));
                }
                onClicked: {
                    imagePickerProc.targetKey = modelData.key;
                    imagePickerProc.running = true;
                }
                StyledToolTip {
                    text: Translation.tr("Choose an image for this widget")
                }
            }
        }
    }
}