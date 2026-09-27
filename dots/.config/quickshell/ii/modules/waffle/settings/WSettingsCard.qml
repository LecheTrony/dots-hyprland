pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Settings card: the Win11 "card" container from the iNiR reference, minus
// the cookie-face easter egg (this config has no cookie theme). Optional
// collapsible header, wash fill and hairline stroke from Looks.settings.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property string description: ""
    property bool expanded: true
    property bool collapsible: false
    default property alias content: contentColumn.data

    readonly property int cardRadius: Looks.settings.radiusXLarge
    readonly property int cardPadding: Looks.settings.panelPadding

    Layout.fillWidth: true
    implicitHeight: mainColumn.implicitHeight

    Rectangle {
        z: 1
        anchors.fill: parent
        radius: root.cardRadius
        color: Looks.settings.tile
        border.width: 1
        border.color: Looks.settings.stroke
    }

    ColumnLayout {
        id: mainColumn
        z: 2
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 0

        Item {
            visible: root.title !== ""
            Layout.fillWidth: true
            implicitHeight: Math.max(Looks.dp(48), headerRow.implicitHeight + root.cardPadding)

            Rectangle {
                id: headerBg
                anchors.fill: parent
                radius: root.expanded ? 0 : root.cardRadius
                topLeftRadius: root.cardRadius
                topRightRadius: root.cardRadius
                color: root.collapsible && headerMa.containsMouse ? Looks.colors.bg1Hover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 70 }
                }
            }

            MouseArea {
                id: headerMa
                anchors.fill: parent
                enabled: root.collapsible
                cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
                hoverEnabled: root.collapsible
                onClicked: if (root.collapsible) root.expanded = !root.expanded
            }

            RowLayout {
                id: headerRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.cardPadding
                    rightMargin: root.cardPadding
                }
                spacing: Looks.dp(12)

                Rectangle {
                    visible: root.icon !== ""
                    implicitWidth: Looks.dp(28)
                    implicitHeight: Looks.dp(28)
                    radius: Looks.settings.radiusLarge
                    color: ColorUtils.applyAlpha(Looks.colors.accent, 0.16)
                    Layout.alignment: root.description !== "" ? Qt.AlignTop : Qt.AlignVCenter

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: root.icon
                        implicitSize: Looks.dp(15)
                        color: Looks.colors.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Looks.dp(3)

                    WText {
                        Layout.fillWidth: true
                        text: root.title
                        font.pixelSize: Looks.font.pixelSize.normal
                        font.weight: Looks.font.weight.strong
                        color: Looks.colors.fg
                        elide: Text.ElideRight
                    }

                    WText {
                        visible: root.description !== ""
                        Layout.fillWidth: true
                        text: root.description
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.subfg
                        wrapMode: Text.WordWrap
                        lineHeight: 1.3
                    }
                }

                FluentIcon {
                    visible: root.collapsible
                    icon: "chevron-up"
                    implicitSize: Looks.dp(12)
                    color: Looks.colors.subfg
                    Layout.alignment: root.description !== "" ? Qt.AlignTop : Qt.AlignVCenter

                    rotation: root.expanded ? 0 : 180
                    Behavior on rotation {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: root.expanded
                ? contentColumn.implicitHeight + contentColumn.anchors.topMargin + contentColumn.anchors.bottomMargin
                : 0
            clip: true

            Behavior on implicitHeight {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: contentColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    leftMargin: root.cardPadding
                    rightMargin: root.cardPadding
                    topMargin: root.title !== "" ? 0 : Looks.dp(10)
                    bottomMargin: Looks.dp(10)
                }
                spacing: 0
                opacity: root.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
