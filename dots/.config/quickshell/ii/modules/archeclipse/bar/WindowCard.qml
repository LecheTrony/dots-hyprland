import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Open windows card (upstream TaskItem list on the Hyprland service): click to
// focus, middle click / close button to dismiss.
Item {
    id: root

    readonly property var windows: {
        Hyprland.toplevels.values;
        return Hyprland.toplevels.values;
    }

    function appIcon(toplevel) {
        try {
            const cls = toplevel.lastIpcObject?.class ?? toplevel.class ?? "";
            if (!cls)
                return "";
            const entry = DesktopEntries.heuristicLookup(cls);
            if (entry && entry.icon)
                return Quickshell.iconPath(entry.icon, true);
        } catch (e) {}
        return "";
    }

    function toggle(toplevel) {
        if (!toplevel)
            return;
        if (!toplevel.active)
            toplevel.focus();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                text: "view_carousel"
                iconSize: ArchTheme.fontSize
                color: root.windows.length > 0 ? ArchTheme.accent : ArchTheme.muted
            }
            Text {
                Layout.fillWidth: true
                text: Translation.tr("Windows") + (root.windows.length > 0 ? "  " + root.windows.length : "")
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
        }

        Flickable {
            id: winFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: winColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: root.windows.length > 0

            Column {
                id: winColumn
                width: winFlick.width
                spacing: 2

                Repeater {
                    model: root.windows
                    delegate: Rectangle {
                        id: winRow
                        required property var modelData
                        readonly property var toplevel: winRow.modelData
                        width: winFlick.width
                        height: 26
                        radius: 4
                        color: winRow.toplevel?.active ? ArchTheme.surfaceActive : winHover.hovered ? ArchTheme.surfaceHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 2
                            spacing: 6

                            IconImage {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                source: root.appIcon(winRow.toplevel)
                                asynchronous: true
                                mipmap: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: winRow.toplevel?.title || winRow.toplevel?.lastIpcObject?.title || ""
                                elide: Text.ElideRight
                                color: winRow.toplevel?.active ? ArchTheme.accent : ArchTheme.fg
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSizeSmall
                            }

                            MaterialSymbol {
                                Layout.preferredWidth: 14
                                text: "close"
                                iconSize: ArchTheme.fontSize - 2
                                color: closeHover.hovered ? ArchTheme.danger : ArchTheme.muted

                                HoverHandler {
                                    id: closeHover
                                }
                                TapHandler {
                                    onTapped: winRow.toplevel?.close()
                                }
                            }
                        }

                        HoverHandler {
                            id: winHover
                        }
                        TapHandler {
                            onTapped: root.toggle(winRow.toplevel)
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.windows.length === 0
            text: Translation.tr("No windows")
            horizontalAlignment: Text.AlignHCenter
            color: ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSizeSmall
        }
    }
}
