import QtQuick
import qs.modules.common.widgets
import qs.services
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Quick-settings island: the control body unfolds inside the bar pill.
// Same unfold pattern as SearchIsland — the pill grows while this body
// unfolds. Focus stays OnDemand so typing elsewhere keeps working.
Column {
    id: root

    signal closeRequested()

    property string monitorName: ""
    width: controlBody.width
    height: 30 + spacing + Math.max(0, expand) * bodyFullHeight

    property real expand: 0
    readonly property real bodyFullHeight: controlBody.implicitHeight
    Component.onCompleted: expand = 1

    // small header row keeps the pill readable when closed
    Rectangle {
        width: parent.width
        height: 30
        radius: ArchTheme.radius
        color: ArchTheme.surface

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            MaterialSymbol {
                text: "tune"
                iconSize: 14
                color: ArchTheme.fg
            }
            Text {
                text: Translation.tr("Quick settings")
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
        }

        TapHandler {
            onTapped: root.closeRequested()
        }
    }

    IslandExpandClip {
        expand: root.expand
        contentHeight: root.bodyFullHeight

        ControlPanelBody {
            id: controlBody
            anchors.top: parent.top
            monitorName: root.monitorName
            onCloseRequested: root.closeRequested()
        }
    }
}
