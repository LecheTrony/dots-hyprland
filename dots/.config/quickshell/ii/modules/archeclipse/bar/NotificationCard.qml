import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Notification history card (upstream NotificationHistoryWidget on the ii
// Notifications service): newest first, click to dismiss.
Item {
    id: root

    readonly property var notifications: {
        Notifications.list;
        return (Notifications.list ?? []).slice().sort((a, b) => (b.time ?? 0) - (a.time ?? 0));
    }
    readonly property int count: notifications.length

    function stamp(time) {
        if (!time)
            return "";
        try {
            return Qt.locale().toString(new Date(time * 1000), "hh:mm");
        } catch (e) {
            return "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                text: "notifications"
                iconSize: ArchTheme.fontSize
                color: Notifications.unread > 0 ? ArchTheme.accent : ArchTheme.muted
            }
            Text {
                Layout.fillWidth: true
                text: Translation.tr("Notifications") + (root.count > 0 ? "  " + root.count : "")
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
            IconActionButton {
                icon: "clear_all"
                tooltip: Translation.tr("Clear all")
                actionEnabled: root.count > 0
                onClicked: Notifications.discardAllNotifications()
            }
        }

        Flickable {
            id: notifFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: notifColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: root.count > 0

            Column {
                id: notifColumn
                width: notifFlick.width
                spacing: 2

                Repeater {
                    model: root.notifications
                    delegate: Rectangle {
                        id: notifRow
                        required property var modelData
                        width: notifFlick.width
                        height: Math.max(28, notifBody.implicitHeight + 8)
                        radius: 4
                        color: notifHover.hovered ? ArchTheme.surfaceHover : "transparent"

                        RowLayout {
                            id: notifBody
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 6

                            IconImage {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                source: notifRow.modelData.appIcon ?? ""
                                asynchronous: true
                                mipmap: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: notifRow.modelData.summary || notifRow.modelData.appName || ""
                                    elide: Text.ElideRight
                                    color: ArchTheme.fg
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeSmall
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: notifRow.modelData.body || ""
                                    elide: Text.ElideRight
                                    visible: (notifRow.modelData.body ?? "") !== ""
                                    color: ArchTheme.muted
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeBadge
                                }
                            }

                            Text {
                                text: root.stamp(notifRow.modelData.time)
                                color: ArchTheme.muted
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSizeBadge
                            }
                        }

                        HoverHandler {
                            id: notifHover
                        }
                        TapHandler {
                            onTapped: Notifications.discardNotification(notifRow.modelData.notificationId)
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.count === 0
            text: Translation.tr("No notifications")
            horizontalAlignment: Text.AlignHCenter
            color: ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSizeSmall
        }
    }
}
