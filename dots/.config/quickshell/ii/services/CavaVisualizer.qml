pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

// Audio spectrum for the screen edge visualiser.
//
// One cava process feeds the bottom strip, which mirrors the values around the
// centre of the screen. It is separate from the media widgets' cava because
// those are scoped to a player card: this one has to stay alive whenever the
// shell does, so the edge reacts to system audio and not just to a playing
// track.
Singleton {
    id: root

    // Raw values, most recent frame first. The visualiser decides how to shape
    // them so this stays a dumb transport.
    property list<real> points: []

    // True while cava is producing frames. Used to fade the strip out when the
    // process dies instead of leaving a frozen spectrum on screen.
    property bool running: false

    readonly property real maxValue: 1000

    // Geometry of the bottom strip. The bar step is not fixed here: it is
    // derived from the surface width at paint time so the bars always span the
    // full screen on any resolution. Only the height and the fill ratio are
    // tunable.
    readonly property real stripHeight: 150
    readonly property real barFill: 0.55

    Process {
        id: cava

        running: true

        command: [
            "cava",
            "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/bottom_output_config.txt`
        ]

        stdout: SplitParser {
            onRead: data => {
                let frame = [];
                for (const chunk of data.trim().split(";")) {
                    const value = parseFloat(chunk);
                    if (!isNaN(value))
                        frame.push(value);
                }
                if (frame.length > 0) {
                    root.points = frame;
                    root.running = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: stream => {
                const text = stream.text.trim();
                if (text.length > 0)
                    console.warn("[CavaVisualizer] " + text);
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.running = false;
            root.points = [];
            console.warn(`[CavaVisualizer] el visualizador de audio termino (codigo ${exitCode})`);
        }
    }
}