import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

// Settings card for the left panel. Ported from the upstream ArchEclipse
// `widgets/leftPanel/SettingsWidget.qml`: bold accent section headers, rows
// with the control on the trailing edge and a staggered reveal on open. The
// options are the ones this family actually reads (bar placement, auto hide,
// panel locks) plus the shared appearance keys.
Item {
    id: root

    width: parent ? parent.width : 0
    implicitHeight: sections.implicitHeight

    // ---- shared building blocks -------------------------------------------

    component SectionBox: Rectangle {
        id: box

        property string title: ""
        property string iconName: ""
        default property alias content: contentColumn.data

        Layout.fillWidth: true
        implicitHeight: contentColumn.implicitHeight + 20
        radius: ArchTheme.radius
        color: ArchTheme.surface
        border.width: 1
        border.color: ArchTheme.border

        // Staggered reveal, like the upstream settings widget.
        opacity: 0
        transform: Translate { id: boxShift; y: 6 }
        Component.onCompleted: {
            box.opacity = 1;
            boxShift.y = 0;
        }
        Behavior on opacity {
            NumberAnimation {
                duration: ArchTheme.anim.fastEffects
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: ArchTheme.anim.defaultSpatial
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 6
                visible: box.title !== ""

                MaterialSymbol {
                    text: box.iconName
                    iconSize: ArchTheme.fontSize + 1
                    color: ArchTheme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: box.title
                    color: ArchTheme.accent
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }
        }
    }

    component SettingRow: Item {
        id: row

        property string label: ""
        property string caption: ""
        default property alias control: controlHolder.data

        Layout.fillWidth: true
        implicitHeight: Math.max(28, labelColumn.implicitHeight)

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -4
            anchors.rightMargin: -4
            radius: ArchTheme.chipRadius
            color: rowHover.hovered ? ArchTheme.surfaceHover : "transparent"

            HoverHandler { id: rowHover }
        }

        RowLayout {
            id: labelRow
            anchors.left: parent.left
            anchors.right: controlHolder.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            ColumnLayout {
                id: labelColumn
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: row.label
                    color: ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: row.caption !== ""
                    text: row.caption
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            id: controlHolder
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
        }
    }

    component ToggleSwitch: Item {
        id: sw

        property bool checked: false
        signal toggled()

        implicitWidth: 34
        implicitHeight: 18

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: sw.checked ? ArchTheme.accent : ArchTheme.rgba(ArchTheme.fg, 0.18)
            border.width: 1
            border.color: sw.checked ? ArchTheme.accent : ArchTheme.border

            Behavior on color {
                ColorAnimation { duration: ArchTheme.anim.fastEffects }
            }
        }

        Rectangle {
            width: height - 4
            height: width
            radius: width / 2
            y: 2
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? ArchTheme.accentFg : ArchTheme.fg

            Behavior on x {
                NumberAnimation {
                    duration: ArchTheme.anim.fastSpatial
                    easing.type: Easing.OutCubic
                }
            }
        }

        TapHandler {
            onTapped: sw.toggled()
        }
    }

    component Segmented: RowLayout {
        id: seg

        property var options: []
        property int currentIndex: 0
        signal picked(int index)

        spacing: 2

        Repeater {
            model: seg.options

            delegate: Rectangle {
                id: segButton

                required property string modelData
                required property int index

                height: 20
                width: Math.max(28, segLabel.implicitWidth + 10)
                radius: 4
                color: seg.currentIndex === index ? ArchTheme.accent : "transparent"
                border.width: 1
                border.color: seg.currentIndex === index ? ArchTheme.accent : ArchTheme.border

                Behavior on color {
                    ColorAnimation { duration: ArchTheme.anim.fastEffects }
                }

                Text {
                    id: segLabel
                    anchors.centerIn: parent
                    text: segButton.modelData
                    color: seg.currentIndex === segButton.index ? ArchTheme.accentFg : ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                }

                TapHandler {
                    onTapped: seg.picked(segButton.index)
                }
            }
        }
    }

    // ---- content ----------------------------------------------------------

    ColumnLayout {
        id: sections
        width: parent.width
        spacing: ArchTheme.spacing

        readonly property int count: 4

        SectionBox {
            title: Translation.tr("Bar")
            iconName: "view_top"

            SettingRow {
                label: Translation.tr("Position")
                caption: Translation.tr("Dock the bar to the bottom edge")

                Segmented {
                    options: [Translation.tr("Top"), Translation.tr("Bottom")]
                    currentIndex: Config.options.bar.bottom ? 1 : 0
                    onPicked: (index) => {
                        Config.options.bar.bottom = index === 1;
                    }
                }
            }

            SettingRow {
                label: Translation.tr("Auto hide")
                caption: Translation.tr("Reveal the bar when the pointer reaches the screen edge")

                ToggleSwitch {
                    checked: Config.options.bar.autoHide.enable
                    onToggled: Config.options.bar.autoHide.enable = !Config.options.bar.autoHide.enable
                }
            }

            SettingRow {
                label: Translation.tr("Show background")
                caption: Translation.tr("Draw the bar surface instead of only its outline")

                ToggleSwitch {
                    checked: Config.options.bar.showBackground
                    onToggled: Config.options.bar.showBackground = !Config.options.bar.showBackground
                }
            }

            SettingRow {
                label: Translation.tr("Verbose modules")
                caption: Translation.tr("Keep the wide module layout in the bar centre")

                ToggleSwitch {
                    checked: Config.options.bar.verbose
                    onToggled: Config.options.bar.verbose = !Config.options.bar.verbose
                }
            }
        }

        SectionBox {
            title: Translation.tr("Panels")
            iconName: "vertical_split"

            SettingRow {
                label: Translation.tr("Lock left panel")
                caption: Translation.tr("Keep the panel open until it is closed explicitly")

                ToggleSwitch {
                    checked: ArchTheme.leftPanelLocked
                    onToggled: {
                        ArchTheme.leftPanelLocked = !ArchTheme.leftPanelLocked;
                        if (ArchTheme.leftPanelLocked)
                            ArchBarState.activate("left", 0);
                    }
                }
            }

            SettingRow {
                label: Translation.tr("Lock right panel")
                caption: Translation.tr("Keep the panel open until it is closed explicitly")

                ToggleSwitch {
                    checked: ArchTheme.rightPanelLocked
                    onToggled: {
                        ArchTheme.rightPanelLocked = !ArchTheme.rightPanelLocked;
                        if (ArchTheme.rightPanelLocked)
                            ArchBarState.activate("right", 0);
                    }
                }
            }
        }

        SectionBox {
            title: Translation.tr("Appearance")
            iconName: "palette"

            SettingRow {
                label: Translation.tr("Monospace font")
                caption: Translation.tr("Used by the panels, cards and badges")

                Rectangle {
                    implicitWidth: 118
                    implicitHeight: 22
                    radius: 4
                    color: ArchTheme.bg
                    border.width: 1
                    border.color: ArchTheme.border

                    TextInput {
                        id: monoInput
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: ArchTheme.fg
                        font.family: ArchTheme.fontFamily
                        font.pixelSize: ArchTheme.fontSizeCaption
                        selectByMouse: true
                        text: Config.options.appearance.fonts.monospace
                        onEditingFinished: Config.options.appearance.fonts.monospace = text

                        Text {
                            anchors.fill: parent
                            visible: monoInput.text.length === 0
                            text: Translation.tr("unset")
                            color: ArchTheme.muted
                            font.family: ArchTheme.fontFamily
                            font.pixelSize: ArchTheme.fontSizeCaption
                        }
                    }
                }
            }

            SettingRow {
                label: Translation.tr("Extra background tint")
                caption: Translation.tr("Blend a hint of the accent colour into the shell background")

                ToggleSwitch {
                    checked: Config.options.appearance.extraBackgroundTint
                    onToggled: Config.options.appearance.extraBackgroundTint = !Config.options.appearance.extraBackgroundTint
                }
            }
        }

        SectionBox {
            title: Translation.tr("More")
            iconName: "tune"

            SettingRow {
                label: Translation.tr("All settings")
                caption: Translation.tr("Open the full illogical-impulse settings window")

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 22
                    radius: 4
                    color: openHover.hovered ? ArchTheme.surfaceActive : ArchTheme.bg
                    border.width: 1
                    border.color: ArchTheme.border

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "open_in_new"
                        iconSize: ArchTheme.fontSize
                        color: ArchTheme.fg
                    }

                    HoverHandler { id: openHover }
                    TapHandler {
                        onTapped: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])
                    }
                }
            }

            SettingRow {
                label: Translation.tr("Config file")
                caption: `${Directories.config}/illogical-impulse/config.json`

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 22
                    radius: 4
                    color: copyHover.hovered ? ArchTheme.surfaceActive : ArchTheme.bg
                    border.width: 1
                    border.color: ArchTheme.border

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_copy"
                        iconSize: ArchTheme.fontSize
                        color: ArchTheme.fg
                    }

                    HoverHandler { id: copyHover }
                    TapHandler {
                        onTapped: {
                            Quickshell.clipboardText = `${Directories.config}/illogical-impulse/config.json`;
                        }
                    }
                }
            }
        }
    }
}
