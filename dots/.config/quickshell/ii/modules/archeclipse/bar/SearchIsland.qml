import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Search island: input + launcher results inline in the bar pill, driven by
// our LauncherSearch service (apps, web-search, math, clipboard, actions…).
Column {
    id: root

    signal closeRequested()

    property string monitorName: ""
    width: 516
    spacing: ArchTheme.spacing
    height: 30 + spacing + Math.max(0, expand) * bodyFullHeight

    // Expand driver: 0 -> 1 on creation unfolds the results body.
    property real expand: 0
    property int bodyFullHeight: 448
    property int selectedIndex: 0
    Component.onCompleted: expand = 1

    Rectangle {
        id: searchInput
        width: parent.width
        height: 30
        radius: ArchTheme.radius
        color: ArchTheme.surface

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
            clip: true
            focus: true

            onTextEdited: {
                root.selectedIndex = 0;
                LauncherSearch.query = input.text;
                resultsView.positionViewAtIndex(0, ListView.Contain);
            }
            onAccepted: root.activateSelected()

            Keys.onEscapePressed: root.closeRequested()
            Keys.onDownPressed: root.navigate(1)
            Keys.onUpPressed: root.navigate(-1)

            Timer {
                interval: 50
                running: true
                onTriggered: input.forceActiveFocus()
            }
        }

        Text {
            visible: input.text === "" && !input.focus
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            text: Translation.tr("Search…")
            color: ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }

        Text {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12
            text: "\uF002"
            color: ArchTheme.muted
            font.family: ArchTheme.iconFamily
            font.pixelSize: 12
        }
    }

    IslandExpandClip {
        expand: root.expand
        contentHeight: root.bodyFullHeight

        ListView {
            id: resultsView
            anchors.top: parent.top
            width: parent.width
            height: root.bodyFullHeight
            clip: true
            model: LauncherSearch.results
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4

            delegate: Rectangle {
                id: resultDelegate
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 40
                radius: ArchTheme.chipRadius
                color: root.selectedIndex === index ? ArchTheme.surfaceHover : "transparent"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    spacing: 10

                    MaterialSymbol {
                        visible: modelData.iconType === LauncherSearchResult.IconType.Material && !!modelData.iconName
                        text: modelData.iconName ?? "badge"
                        iconSize: 15
                        color: root.selectedIndex === index ? ArchTheme.accent : ArchTheme.muted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name ?? ""
                        elide: Text.ElideRight
                        color: root.selectedIndex === index ? ArchTheme.fg : modelData.name !== "" ? ArchTheme.fg : ArchTheme.muted
                        font.family: modelData.fontType === LauncherSearchResult.FontType.Monospace ? ArchTheme.fontFamily : defaultFont
                        font.pixelSize: ArchTheme.fontSize
                    }

                    Text {
                        visible: !!modelData.verb
                        text: modelData.verb ?? ""
                        color: ArchTheme.muted
                        font.family: ArchTheme.fontFamily
                        font.pixelSize: ArchTheme.fontSize - 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedIndex = index;
                        root.activateSelected();
                    }
                    onPositionChanged: root.selectedIndex = index
                }
            }
        }
    }

    function navigate(direction) {
        const count = LauncherSearch.results.length;
        if (count === 0)
            return;
        root.selectedIndex = (root.selectedIndex + direction + count) % count;
        resultsView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function activateSelected() {
        const results = LauncherSearch.results;
        if (results.length === 0)
            return false;
        const entry = results[Math.min(root.selectedIndex, results.length - 1)];
        if (entry)
            entry.execute();
        root.closeRequested();
        return true;
    }
}