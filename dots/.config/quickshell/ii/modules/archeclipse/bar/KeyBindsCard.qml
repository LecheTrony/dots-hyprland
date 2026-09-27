import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.looks

// Keybind browser (upstream KeyBindsWidget, on the ii HyprlandKeybinds
// service): searchable list grouped by the description prefix, with the
// modifier mask decoded to a readable combo.
Item {
    id: root

    property string filter: ""
    property string expandedCategory: ""

    readonly property var binds: HyprlandKeybinds.keybinds ?? []

    readonly property var groups: {
        root.filter;
        const needle = root.filter.trim().toLowerCase();
        const out = [];
        for (const b of root.binds) {
            const desc = b.description ?? "";
            if (desc.length === 0)
                continue;
            const combo = root.combo(b);
            if (needle !== "" && !(combo + " " + desc).toLowerCase().includes(needle))
                continue;
            const cat = desc.includes(":") ? desc.substring(0, desc.indexOf(":")) : "";
            let g = out.find(o => o.name === cat);
            if (!g) {
                g = { name: cat, items: [] };
                out.push(g);
            }
            g.items.push({ combo: combo, desc: desc, dispatcher: b.dispatcher ?? "" });
        }
        return out;
    }

    function combo(bind) {
        const mods = [];
        const mask = bind.modmask ?? 0;
        if (mask & (1 << 2))
            mods.push("Ctrl");
        if (mask & (1 << 6))
            mods.push("Super");
        if (mask & (1 << 0))
            mods.push("Shift");
        if (mask & (1 << 3))
            mods.push("Alt");
        if (mask & (1 << 1))
            mods.push("Caps");
        if (mask & (1 << 4))
            mods.push("Mod2");
        if (mask & (1 << 5))
            mods.push("Mod3");
        if (mask & (1 << 7))
            mods.push("Mod5");
        const key = (bind.key ?? "").toUpperCase();
        return mods.length > 0 ? mods.join("+") + "+" + key : key;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                text: "keyboard"
                iconSize: ArchTheme.fontSize
                color: root.binds.length > 0 ? ArchTheme.accent : ArchTheme.muted
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Filter keybinds")
                text: root.filter
                onTextChanged: root.filter = text
                color: ArchTheme.fg
                placeholderTextColor: ArchTheme.muted
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize - 1
                background: Rectangle {
                    radius: 4
                    color: ArchTheme.surfaceHover
                    border.width: 1
                    border.color: searchField.activeFocus ? ArchTheme.accent : ArchTheme.border
                }
            }
        }

        Flickable {
            id: bindFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: bindColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: root.groups.length > 0

            Column {
                id: bindColumn
                width: bindFlick.width
                spacing: 6

                Repeater {
                    model: root.groups

                    delegate: Column {
                        id: group
                        required property var modelData
                        width: bindColumn.width
                        spacing: 2

                        // category header doubles as a collapse toggle
                        Item {
                            width: group.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: group.modelData.name === "" ? Translation.tr("Uncategorized") : group.modelData.name
                                color: ArchTheme.muted
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSizeCaption
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: group.modelData.items.length
                                color: ArchTheme.muted
                                font.family: ArchTheme.fontFamily
                                font.pixelSize: ArchTheme.fontSizeBadge
                            }
                            TapHandler {
                                onTapped: root.expandedCategory = root.expandedCategory === group.modelData.name ? "" : group.modelData.name;
                            }
                        }

                        Repeater {
                            model: group.modelData.items
                            delegate: Item {
                                id: bindRow
                                required property var modelData
                                visible: root.expandedCategory === "" || root.expandedCategory === group.modelData.name
                                width: group.width
                                height: 20

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: bindHover.hovered ? ArchTheme.surfaceHover : "transparent"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 4
                                    spacing: 6

                                    Rectangle {
                                        Layout.preferredWidth: Math.min(120, bindCombo.implicitWidth + 10)
                                        Layout.preferredHeight: 16
                                        radius: 3
                                        color: ArchTheme.surfaceActive
                                        border.width: 1
                                        border.color: ArchTheme.border

                                        Text {
                                            id: bindCombo
                                            anchors.centerIn: parent
                                            text: bindRow.modelData.combo
                                            color: ArchTheme.accent
                                            font.family: ArchTheme.fontFamily
                                            font.pixelSize: ArchTheme.fontSizeBadge
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: bindRow.modelData.desc
                                        elide: Text.ElideRight
                                        color: ArchTheme.fgDim
                                        font.family: ArchTheme.fontFamily
                                        font.pixelSize: ArchTheme.fontSizeBadge
                                    }
                                }

                                HoverHandler {
                                    id: bindHover
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.groups.length === 0
            text: Translation.tr("No keybinds")
            horizontalAlignment: Text.AlignHCenter
            color: ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSizeSmall
        }
    }
}
