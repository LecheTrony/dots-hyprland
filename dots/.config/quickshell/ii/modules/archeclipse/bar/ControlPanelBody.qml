import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Quick-settings body, upstream layout: two columns — left holds the volume
// + connectivity cards, right holds the 2x2 action grid, the brightness
// slider and the power profile selector. Lives inside the bar pill.
Item {
    id: body

    signal closeRequested()

    property string monitorName: ""

    width: 680
    height: contentRow.height + 32

    // ---- dynamic brightness icon (3 thresholds, upstream parity) ----
    readonly property var screenMonitor: Brightness.monitors.find(m => m.screen?.name === body.monitorName) ?? Brightness.monitors[0]
    readonly property bool hasBacklight: body.screenMonitor !== undefined && body.screenMonitor !== null
    readonly property real brightnessLevel: body.screenMonitor?.multipliedBrightness ?? 0
    readonly property string brightnessIcon: {
        const bri = body.brightnessLevel;
        if (bri > 0.75)
            return "󰃠";
        if (bri > 0.5)
            return "󰃟";
        return "󰃞";
    }

    readonly property int powerIndex: {
        if (PowerProfiles.profile === PowerProfile.Performance)
            return 2;
        if (PowerProfiles.profile === PowerProfile.PowerSaver)
            return 0;
        return 1;
    }

    property var themeToggle: DarkModeToggle {}
    property var dndToggle: NotificationToggle {}
    property var nightLightToggle: NightLightToggle {}
    property var snipToggle: ScreenSnipToggle {}

    Row {
        id: contentRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 16

        // ===== left column: sections =====
        Column {
            width: (parent.width - parent.spacing) / 2
            spacing: 16

            VolumeSection {
                width: parent.width
            }
            ConnectivitySection {
                width: parent.width
            }
        }

        // ===== right column: actions, brightness, power =====
        Column {
            width: (parent.width - parent.spacing) / 2
            spacing: 16

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                component ActionCell: Rectangle {
                    id: cell
                    property bool hovered: false
                    property var toggle: null
                    property string glyph: ""
                    signal triggered()
                    width: (parent.width - parent.columnSpacing) / 2
                    height: 46
                    radius: ArchTheme.radius
                    color: cell.hovered ? ArchTheme.surfaceHover : ArchTheme.surface

                    Behavior on color {
                        ColorAnimation {
                            duration: ArchTheme.anim.fastEffects
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: cell.glyph
                        iconSize: ArchTheme.fontSize + 2
                        color: cell.toggle?.toggled ? ArchTheme.accent : cell.hovered ? ArchTheme.fg : ArchTheme.fgDim
                    }

                    HoverHandler {
                        onHoveredChanged: cell.hovered = hovered
                    }
                    TapHandler {
                        onTapped: {
                            cell.toggle?.mainAction?.();
                            cell.triggered();
                        }
                    }
                }

                ActionCell {
                    toggle: body.themeToggle
                    glyph: body.themeToggle.icon
                }
                ActionCell {
                    toggle: body.dndToggle
                    glyph: body.dndToggle.icon
                }
                ActionCell {
                    toggle: body.nightLightToggle
                    glyph: body.nightLightToggle.icon
                }
                ActionCell {
                    toggle: body.snipToggle
                    glyph: body.snipToggle.icon
                }
            }

            // ---- brightness ----
            Column {
                width: parent.width
                spacing: 6
                visible: body.hasBacklight

                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: body.brightnessIcon
                        color: ArchTheme.fg
                        font.family: ArchTheme.iconFamily
                        font.pixelSize: 18
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        text: Translation.tr("Brightness")
                        color: ArchTheme.muted
                        font.family: ArchTheme.fontFamily
                        font.pixelSize: ArchTheme.fontSizeSmall
                    }
                }

                Slider {
                    id: brightSlider
                    width: parent.width
                    from: 0
                    to: 1
                    stepSize: 0.01
                    value: body.brightnessLevel
                    onMoved: body.screenMonitor?.setBrightness(brightSlider.value)

                    background: Rectangle {
                        x: brightSlider.leftPadding
                        y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                        width: brightSlider.availableWidth
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.15)
                        Rectangle {
                            width: brightSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: ArchTheme.accent
                        }
                    }
                    handle: Rectangle {
                        x: brightSlider.leftPadding + brightSlider.visualPosition * (brightSlider.availableWidth - width)
                        y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                        width: 12
                        height: 12
                        radius: 6
                        color: ArchTheme.accent
                    }
                }
            }

            // ---- power profile ----
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "󰓅"
                        color: ArchTheme.fg
                        font.family: ArchTheme.iconFamily
                        font.pixelSize: 18
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        text: Translation.tr("Power")
                        color: ArchTheme.muted
                        font.family: ArchTheme.fontFamily
                        font.pixelSize: ArchTheme.fontSizeSmall
                    }
                    Text {
                        text: {
                            if (PowerProfiles.profile === PowerProfile.Performance)
                                return Translation.tr("Performance");
                            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                return Translation.tr("Power Saver");
                            return Translation.tr("Balanced");
                        }
                        color: ArchTheme.accent
                        font.family: ArchTheme.fontFamily
                        font.pixelSize: ArchTheme.fontSizeCaption
                    }
                }

                Row {
                    width: parent.width
                    spacing: 6

                    component ProfileCell: Rectangle {
                        id: profile
                        property bool hovered: false
                        property string label: ""
                        property bool active: false
                        property var profileValue: null
                        signal picked()
                        width: (parent.width - 12) / 3
                        height: 26
                        radius: ArchTheme.chipRadius
                        color: profile.active ? ArchTheme.accent : profile.hovered ? ArchTheme.surfaceHover : ArchTheme.surface

                        Behavior on color {
                            ColorAnimation {
                                duration: ArchTheme.anim.fastEffects
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: profile.label
                            color: profile.active ? ArchTheme.accentFg : profile.hovered ? ArchTheme.fg : ArchTheme.fgDim
                            font.family: ArchTheme.fontFamily
                            font.pixelSize: ArchTheme.fontSizeSmall
                        }
                        HoverHandler {
                            onHoveredChanged: profile.hovered = hovered
                        }
                        TapHandler {
                            onTapped: {
                                if (profile.profileValue !== null)
                                    PowerProfiles.profile = profile.profileValue;
                                profile.picked();
                            }
                        }
                    }

                    ProfileCell {
                        label: Translation.tr("Saver")
                        active: body.powerIndex === 0
                        profileValue: PowerProfile.PowerSaver
                    }
                    ProfileCell {
                        label: Translation.tr("Balanced")
                        active: body.powerIndex === 1
                        profileValue: PowerProfile.Balanced
                    }
                    ProfileCell {
                        label: Translation.tr("Perf")
                        active: body.powerIndex === 2
                        enabled: PowerProfiles.hasPerformanceProfile
                        profileValue: PowerProfile.Performance
                    }
                }
            }
        }
    }
}
