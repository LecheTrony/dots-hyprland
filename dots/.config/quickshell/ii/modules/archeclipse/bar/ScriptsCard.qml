import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Script runner card (upstream CustomScriptsWidget shape, on config.json):
// a persisted list of named shell commands with a run button and an optional
// auto-run interval, so no external script service is needed.
Item {
    id: root

    readonly property var scripts: {
        const stored = Config.options?.arch?.scripts;
        return Array.isArray(stored) ? stored : [];
    }

    signal requestRun(string command)
    signal requestRemove(int index)

    // The persisted list is owned by this card; the island only relays the
    // run command, so removal has to happen where the data lives.
    function removeAt(index) {
        if (index < 0 || index >= root.scripts.length)
            return;
        const list = root.scripts.slice();
        list.splice(index, 1);
        Config.setNestedValue("arch.scripts", JSON.stringify(list));
        root.requestRemove(index);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                text: "terminal"
                iconSize: ArchTheme.fontSize
                color: root.scripts.length > 0 ? ArchTheme.accent : ArchTheme.muted
            }
            Text {
                Layout.fillWidth: true
                text: Translation.tr("Scripts")
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
            Text {
                visible: root.scripts.length === 0
                text: Translation.tr("Add under arch.scripts in config.json")
                color: ArchTheme.muted
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSizeBadge
            }
        }

        Flickable {
            id: scriptFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: scriptColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: root.scripts.length > 0

            Column {
                id: scriptColumn
                width: scriptFlick.width
                spacing: 2

                Repeater {
                    model: root.scripts

                    delegate: Item {
                        id: scriptRow
                        required property var modelData
                        required property int index
                        width: scriptFlick.width
                        height: 26

                        readonly property string name: scriptRow.modelData?.name ?? Translation.tr("script")
                        readonly property string command: scriptRow.modelData?.command ?? ""
                        readonly property int interval: scriptRow.modelData?.interval ?? 0

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: rowHover.hovered ? ArchTheme.surfaceHover : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 2
                            spacing: 6

                            MaterialSymbol {
                                text: "play_arrow"
                                iconSize: ArchTheme.fontSize - 2
                                color: ArchTheme.accent

                                TapHandler {
                                    onTapped: root.requestRun(scriptRow.command)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: scriptRow.name
                                    elide: Text.ElideRight
                                    color: ArchTheme.fg
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeSmall
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: scriptRow.command
                                    elide: Text.ElideRight
                                    visible: scriptRow.interval === 0
                                    color: ArchTheme.muted
                                    font.family: ArchTheme.fontFamily
                                    font.pixelSize: ArchTheme.fontSizeBadge
                                }
                            }

                            Text {
                                visible: scriptRow.interval > 0
                                text: Math.round(scriptRow.interval / 60) + "m"
                                color: ArchTheme.muted
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSizeBadge
                            }

                            MaterialSymbol {
                                Layout.preferredWidth: 14
                                text: "close"
                                iconSize: ArchTheme.fontSize - 3
                                color: delHover.hovered ? ArchTheme.danger : ArchTheme.muted

                                HoverHandler {
                                    id: delHover
                                }
                                TapHandler {
                                    onTapped: root.requestRemove(scriptRow.index)
                                }
                            }
                        }

                        HoverHandler {
                            id: rowHover
                        }
                    }
                }
            }
        }
    }

    // Optional periodic runs, one timer per script that declares an interval.
    Instantiator {
        model: root.scripts.filter(s => (s?.interval ?? 0) > 0)
        delegate: Timer {
            running: true
            repeat: true
            interval: modelData.interval * 1000
            onTriggered: root.requestRun(modelData.command)
        }
    }
}
