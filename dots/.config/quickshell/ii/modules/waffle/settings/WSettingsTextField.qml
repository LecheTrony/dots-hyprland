pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Free-text row bound to a config path through `text` / `onEditingFinished`.
WSettingsRow {
    id: root

    property string text: ""
    property string placeholder: ""
    signal editingFinished(string value)

    control: Component {
        WTextField {
            Layout.preferredWidth: Looks.dp(170)
            placeholderText: root.placeholder
            text: root.text
            onEditingFinished: root.editingFinished(text)
        }
    }
}
