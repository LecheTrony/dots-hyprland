import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.archeclipse.looks

// Network throughput for the bar, sampled from /proc/net/dev once a second
// (upstream reads the same counters through its SysInfo service). Shown as
// the fixed-width "down arrow / up arrow" pair so the pill never shifts.
Item {
    id: root

    property real bytesPerSecondDown: 0
    property real bytesPerSecondUp: 0

    // Fixed-width dynamic speed: always 4 chars (3-char number + unit).
    function fmtSpeed(bps) {
        if (bps < 1000)
            return String(Math.round(bps)).padStart(3, " ") + "B";
        const kb = bps / 1024;
        if (kb < 10)
            return kb.toFixed(1) + "K";
        if (kb < 1000)
            return String(Math.round(kb)).padStart(3, " ") + "K";
        const mb = kb / 1024;
        if (mb < 10)
            return mb.toFixed(1) + "M";
        if (mb < 1000)
            return String(Math.round(mb)).padStart(3, " ") + "M";
        const gb = mb / 1024;
        if (gb < 10)
            return gb.toFixed(1) + "G";
        return String(Math.round(gb)).padStart(3, " ") + "G";
    }

    implicitWidth: row.implicitWidth
    implicitHeight: ArchTheme.barContentHeight
    height: ArchTheme.barContentHeight

    property var lastTotals: null
    property real lastSample: 0

    FileView {
        id: netDev
        path: "/proc/net/dev"
        blockWrites: false
        onLoaded: {
            const t = text();
            if (!t)
                return;
            let down = 0;
            let up = 0;
            for (const line of t.split("\n")) {
                const idx = line.indexOf(":");
                if (idx < 0)
                    continue;
                const name = line.slice(0, idx).trim();
                if (name === "lo" || name.length === 0)
                    continue;
                const cols = line.slice(idx + 1).trim().split(/\s+/);
                down += Number(cols[0] ?? 0);
                up += Number(cols[8] ?? 0);
            }
            const now = Date.now();
            if (lastTotals !== null) {
                const dt = (now - root.lastSample) / 1000;
                if (dt > 0) {
                    root.bytesPerSecondDown = Math.max(0, (down - lastTotals.down) / dt);
                    root.bytesPerSecondUp = Math.max(0, (up - lastTotals.up) / dt);
                }
            }
            lastTotals = {
                down: down,
                up: up
            };
            lastSample = now;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netDev.reload()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.fmtSpeed(root.bytesPerSecondDown)
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "↓"
            color: ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.fmtSpeed(root.bytesPerSecondUp)
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "↑"
            color: ArchTheme.muted
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
        }
    }
}
