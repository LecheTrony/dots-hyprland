import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.archeclipse.looks

// Media pill: app icon + play state + track title (upstream). Hover or click
// pulses the player island; middle click toggles playback.
Rectangle {
    id: root

    signal stateRequested(string state)

    readonly property var player: MprisController.activePlayer
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string title: player?.trackTitle ?? ""

    readonly property string iconSource: {
        const id = String(player?.identity ?? "").trim();
        if (id === "")
            return "";
        let raw = "";
        try {
            const de = String(player?.desktopEntry ?? "").trim();
            let entry = null;
            if (de !== "")
                entry = DesktopEntries.byId(de) ?? DesktopEntries.heuristicLookup(de);
            if (!entry)
                entry = DesktopEntries.heuristicLookup(id);
            if (entry && entry.icon)
                raw = entry.icon;
        } catch (e) {}
        if (raw === "")
            raw = id.toLowerCase();
        if (raw === "")
            return "";
        try {
            return Quickshell.iconPath(raw, true);
        } catch (e) {
            return "";
        }
    }

    visible: root.player !== null
    width: visible ? contentRow.implicitWidth + 16 : 0
    height: ArchTheme.barContentHeight
    radius: ArchTheme.radius
    color: playerHover.hovered ? ArchTheme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: ArchTheme.anim.fastEffects
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                id: playerIcon
                anchors.fill: parent
                source: root.iconSource
                visible: status === Image.Ready && root.iconSource !== ""
                asynchronous: true
            }
            Text {
                visible: !playerIcon.visible
                anchors.centerIn: parent
                text: "󰎈"
                color: ArchTheme.muted
                font.family: ArchTheme.fontFamily
                font.pixelSize: 12
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isPlaying ? "" : "▶"
            color: root.isPlaying ? ArchTheme.accent : ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize - 2
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 180)
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }
    }

    Timer {
        id: playerDwellTimer
        interval: ArchTheme.revealInPressure
        repeat: false
        onTriggered: {
            if (playerHover.hovered && root.player)
                root.stateRequested("player");
        }
    }

    HoverHandler {
        id: playerHover
        onHoveredChanged: {
            if (playerHover.hovered && root.player) {
                if (ArchTheme.revealInPressure <= 0)
                    root.stateRequested("player");
                else
                    playerDwellTimer.restart();
            } else {
                playerDwellTimer.stop();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (!root.player)
                return;
            if (mouse.button === Qt.MiddleButton) {
                MprisController.togglePlaying();
                return;
            }
            root.stateRequested("player");
        }
    }
}
