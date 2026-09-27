pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.modules.ii.bar
import qs.modules.archeclipse.looks

Row {
    id: root

    spacing: 2
    height: ArchTheme.barContentHeight

    Repeater {
        model: SystemTray.items.values

        delegate: Item {
            id: trayItem
            required property SystemTrayItem modelData
            width: 22
            height: ArchTheme.barContentHeight

            Rectangle {
                anchors.fill: parent
                radius: ArchTheme.radius
                color: itemHover.hovered ? ArchTheme.surfaceHover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                IconImage {
                    anchors.centerIn: parent
                    source: trayItem.modelData.icon
                    width: 14
                    height: 14
                }
            }

            MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onPressed: event => {
                    if (event.button === Qt.LeftButton)
                        trayItem.modelData.activate();
                    else if (event.button === Qt.RightButton) {
                        if (trayItem.modelData.hasMenu) {
                            if (menu.active && menu.item)
                                menu.item.close();
                            else
                                menu.open();
                        }
                    }
                    event.accepted = true;
                }
            }

            Loader {
                id: menu
                function open() {
                    menu.active = true;
                }
                active: false
                onLoaded: menu.item.open()
                sourceComponent: SysTrayMenu {
                    trayItemMenuHandle: trayItem.modelData.menu
                    trayItemId: trayItem.modelData.id
                    anchor {
                        window: root.QsWindow.window
                        item: root
                        gravity: Edges.Bottom
                        edges: Edges.Bottom
                    }
                    onMenuClosed: menu.active = false
                }
            }
        }
    }
}