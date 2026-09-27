import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.archeclipse.looks

// Player island: cover/icon, track metadata and transport controls for the
// active MPRIS player.
Item {
    id: root

    signal closeRequested()

    width: 320
    height: content.implicitHeight

    readonly property var player: MprisController.activePlayer
    visible: root.player !== null

    readonly property string iconSource: {
        const ident = String(root.player?.identity ?? "").trim();
        if (ident === "")
            return "";
        let raw = "";
        try {
            const de = String(root.player?.desktopEntry ?? "").trim();
            let entry = null;
            if (de !== "")
                entry = DesktopEntries.byId(de) ?? DesktopEntries.heuristicLookup(de);
            if (!entry)
                entry = DesktopEntries.heuristicLookup(ident);
            if (entry && entry.icon)
                raw = entry.icon;
        } catch (e) {}
        if (raw === "")
            raw = ident.toLowerCase();
        if (raw === "")
            return "";
        try {
            return Quickshell.iconPath(raw, true);
        } catch (e) {
            return "";
        }
    }

    Column {
        id: content
        width: parent.width
        spacing: ArchTheme.spacing

        Row {
            spacing: ArchTheme.spacing

            Rectangle {
                id: artBox
                width: 40
                height: 40
                radius: ArchTheme.cardRadius
                color: ArchTheme.surfaceActive
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    id: artIcon
                    anchors.fill: parent
                    anchors.margins: 6
                    source: root.iconSource
                    visible: status === Image.Ready && root.iconSource !== ""
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: !artIcon.visible
                    text: "󰎈"
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: 18
                }
            }

            Column {
                spacing: 2
                width: parent.width - 48
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: root.player?.trackTitle ?? ""
                    elide: Text.ElideRight
                    color: ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                }
                Text {
                    width: parent.width
                    text: root.player?.trackArtist ?? ""
                    elide: Text.ElideRight
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeSmall
                }
            }
        }

        Row {
            spacing: ArchTheme.spacing

            component TransportButton: Rectangle {
                id: btn
                // tracked explicitly: the child handler id is not visible
                // from this component's own bindings in this engine
                property bool hovered: false
                property string glyph: ""
                property bool active: false
                signal triggered()
                width: 32
                height: 26
                radius: ArchTheme.chipRadius
                color: btn.hovered ? ArchTheme.surfaceHover : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: ArchTheme.anim.fastEffects
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: btn.glyph
                    color: btn.active ? ArchTheme.accent : ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                }
                HoverHandler {
                    onHoveredChanged: btn.hovered = hovered
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btn.triggered()
                }
            }

            TransportButton {
                glyph: "⏮"
                onTriggered: root.player?.previous()
            }
            TransportButton {
                glyph: root.player?.isPlaying ? "⏸" : "⏵"
                onTriggered: MprisController.togglePlaying()
            }
            TransportButton {
                glyph: "⏭"
                onTriggered: root.player?.next()
            }
        }
    }
}
