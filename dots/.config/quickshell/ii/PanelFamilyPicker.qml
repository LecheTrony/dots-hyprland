import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Panel family picker, opened with Super+Shift+W. It lives at the config root
// and is instantiated once from shell.qml, like ReloadPopup, so it stays
// available no matter which family is currently loaded.
Scope {
    id: root

    function open() {
        GlobalStates.panelFamilyPickerOpen = true;
    }

    function close() {
        GlobalStates.panelFamilyPickerOpen = false;
    }

    function toggle() {
        if (GlobalStates.panelFamilyPickerOpen) {
            close();
            return;
        }
        open();
    }

    // Switching families destroys the picker window, so close before writing.
    function select(value: string) {
        close();
        if (Config.options.panelFamily === value)
            return;
        Config.options.panelFamily = value;
    }

    IpcHandler {
        target: "panelFamilyPicker"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }

        function select(family: string): void {
            if (PanelFamilies.ids.indexOf(family) === -1) {
                console.warn("[PanelFamilyPicker] unknown family: " + family);
                return;
            }
            root.select(family);
        }

        function status(): string {
            return JSON.stringify({
                open: GlobalStates.panelFamilyPickerOpen,
                current: String(Config.options.panelFamily)
            });
        }
    }

    GlobalShortcut {
        name: "panelFamilyPicker"
        description: "Open the panel family picker"

        onPressed: root.toggle()
    }

    Loader {
        id: pickerLoader
        active: GlobalStates.panelFamilyPickerOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:panelFamilyPicker"
            WlrLayershell.layer: WlrLayer.Overlay
            // Exclusive so the menu keeps the keyboard: the arrows and Enter land
            // here, and the focus grab in GlobalFocusGrab is not dropped, which
            // would otherwise dismiss the picker on the next focus change.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            // Full monitor surface like the cheatsheet, with the menu centered
            // inside. The mask keeps the rest of the screen clickable.
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: content
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            Component.onCompleted: GlobalFocusGrab.addDismissable(panelWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    root.close();
                }
            }

            FocusScope {
                id: content
                focus: true
                anchors.centerIn: parent

                readonly property int margin: 10

                implicitWidth: 360
                implicitHeight: layout.implicitHeight + margin * 2

                // Start the keyboard cursor on the family in use, so Enter
                // re-picks the current one instead of jumping somewhere else.
                property int highlighted: Math.max(0, PanelFamilies.indexOf(Config.options.panelFamily))

                function move(delta: int) {
                    const count = PanelFamilies.families.length;
                    highlighted = (highlighted + delta + count) % count;
                }

                Component.onCompleted: content.forceActiveFocus()

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                        move(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                        move(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.select(PanelFamilies.families[content.highlighted].value);
                        event.accepted = true;
                    }
                }

                StyledRectangularShadow {
                    target: background
                }

                Rectangle {
                    id: background
                    anchors {
                        fill: parent
                        margins: content.margin
                    }
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    radius: Appearance.rounding.unsharpenmore

                    // Clicking the padding closes, the rows below take their own clicks.
                    MouseArea {
                        anchors.fill: parent
                        onPressed: root.close()
                    }

                    ColumnLayout {
                        id: layout
                        anchors {
                            fill: parent
                            margins: content.margin / 2
                        }
                        spacing: 2

                        StyledText {
                            Layout.leftMargin: 8
                            Layout.bottomMargin: 4
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.7
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            text: Translation.tr("Panel family")
                        }

                        Repeater {
                            model: PanelFamilies.families

                            delegate: Rectangle {
                                id: familyRow
                                required property var modelData
                                required property int index

                                readonly property bool isCurrent: Config.options.panelFamily === modelData.value
                                readonly property bool isHighlighted: content.highlighted === index

                                Layout.fillWidth: true
                                implicitHeight: rowLayout.implicitHeight + 16
                                radius: Appearance.rounding.unsharpen
                                color: isCurrent
                                    ? Appearance.colors.colSecondaryContainer
                                    : isHighlighted
                                        ? Appearance.colors.colLayer1Hover
                                        : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                RowLayout {
                                    id: rowLayout
                                    anchors {
                                        fill: parent
                                        margins: 8
                                    }
                                    spacing: 12

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: familyRow.modelData.icon
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: familyRow.isCurrent
                                            ? Appearance.colors.colOnSecondaryContainer
                                            : Appearance.colors.colOnLayer0
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            color: Appearance.colors.colOnLayer0
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            text: familyRow.modelData.label
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            color: Appearance.colors.colOnLayer0
                                            opacity: 0.6
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            text: familyRow.modelData.description
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: familyRow.isCurrent
                                        text: "check"
                                        iconSize: Appearance.font.pixelSize.large
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: content.highlighted = index
                                    onPressed: root.select(familyRow.modelData.value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
