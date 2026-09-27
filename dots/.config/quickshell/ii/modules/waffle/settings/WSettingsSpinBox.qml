pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Numeric row with -/+ steppers, matching the reference's compact spinner.
WSettingsRow {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1

    function bump(delta) {
        const next = Math.max(root.from, Math.min(root.to, root.value + delta * root.stepSize));
        root.value = next;
    }

    control: Component {
        RowLayout {
            spacing: Looks.dp(4)

            Repeater {
                model: ["remove", "add"]

                Rectangle {
                    required property string modelData
                    required property int index
                    implicitWidth: Looks.dp(26)
                    implicitHeight: Looks.dp(26)
                    radius: Looks.settings.radiusSmall
                    color: ma.containsMouse ? Looks.colors.bg1Hover : Looks.settings.tile
                    border.width: 1
                    border.color: Looks.settings.stroke

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.bump(index === 0 ? -1 : 1)
                    }

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: modelData
                        implicitSize: Looks.dp(12)
                        color: Looks.colors.subfg
                    }
                }
            }

            WText {
                Layout.preferredWidth: Looks.dp(44)
                horizontalAlignment: Text.AlignHCenter
                text: Math.round(root.value)
                color: Looks.colors.fg
                font.pixelSize: Looks.font.pixelSize.normal
            }
        }
    }
}
