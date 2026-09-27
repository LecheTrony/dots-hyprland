pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Slider row with an optional value readout on the leading side of the track.
WSettingsRow {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property bool showValue: true
    property int decimals: 0

    control: Component {
        RowLayout {
            spacing: Looks.dp(8)

            WText {
                visible: root.showValue
                text: Number(root.value).toFixed(root.decimals)
                color: Looks.colors.subfg
                font.pixelSize: Looks.font.pixelSize.small
            }

            WSlider {
                Layout.preferredWidth: Looks.dp(150)
                from: root.from
                to: root.to
                value: root.value
                onMoved: root.value = value
            }
        }
    }
}
