import QtQuick
import qs.modules.common
import qs.modules.archeclipse.looks

// Hot-zone strips at the bar's left/right ends: reveal the side panels on
// hover (no dwell by default, the dwell only guards deliberate crossings).
// Full-height edge strips; per-side enable + lock mirror the reference —
// a locked panel is not reopened by the strip, it just stays pinned open.
Rectangle {
    id: root

    property string side: "left"
    property real size: 5
    property bool hotZoneEnabled: true
    property bool panelLock: false

    anchors.left: side === "left" ? parent.left : undefined
    anchors.right: side === "right" ? parent.right : undefined
    anchors.top: Config.options.bar.bottom ? undefined : parent.top
    anchors.bottom: Config.options.bar.bottom ? parent.bottom : undefined

    width: size
    height: parent.height
    color: "transparent"

    signal revealRequested()

    readonly property bool armed: root.hotZoneEnabled && !root.panelLock

    property int dwellMs: ArchTheme.revealInPressure

    Timer {
        id: dwellTimer
        interval: root.dwellMs
        repeat: false
        onTriggered: {
            if (root.armed)
                root.revealRequested();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.hotZoneEnabled
        onEntered: {
            if (!root.armed)
                return;
            if (root.dwellMs <= 0)
                root.revealRequested();
            else
                dwellTimer.restart();
        }
        onExited: dwellTimer.stop()
        onClicked: {
            if (!root.armed)
                return;
            dwellTimer.stop();
            root.revealRequested();
        }
    }
}
