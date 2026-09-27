pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// ArchEclipse theme tokens. Colors come from a pywal/cwal `colors.scss`
// (like upstream) so the shell re-themes with the wallpaper; when that file
// is missing we derive the palette from our Material-3 Appearance colors so
// the family still looks coherent.
QtObject {
    id: root

    // ---- raw palette (pywal) ----
    property string background: "#08080c"
    property string foreground: "#aaabb2"
    property string color0: "#08080c"
    property string color1: "#493028"
    property string color2: "#413945"
    property string color3: "#4e505d"
    property string color4: "#917f7a"
    property string color5: "#b7b5ae"
    property string color6: "#d7af96"
    property string color7: "#aaabb2"
    property string color8: "#555765"
    property bool themed: false

    // ---- helpers (upstream parity) ----
    readonly property real phi: 1.618
    readonly property real phiMin: phi - 1

    function mix(a, b, t) {
        const pa = Qt.rgba(parseInt(a.slice(1, 3), 16) / 255, parseInt(a.slice(3, 5), 16) / 255, parseInt(a.slice(5, 7), 16) / 255, 1);
        const pb = Qt.rgba(parseInt(b.slice(1, 3), 16) / 255, parseInt(b.slice(3, 5), 16) / 255, parseInt(b.slice(5, 7), 16) / 255, 1);
        const c = Qt.rgba(pa.r + (pb.r - pa.r) * t, pa.g + (pb.g - pa.g) * t, pa.b + (pb.b - pa.b) * t, 1);
        return "#" + Math.round(c.r * 255).toString(16).padStart(2, "0") + Math.round(c.g * 255).toString(16).padStart(2, "0") + Math.round(c.b * 255).toString(16).padStart(2, "0");
    }
    function rgba(hex, alpha) {
        const r = parseInt(hex.slice(1, 3), 16) / 255;
        const g = parseInt(hex.slice(3, 5), 16) / 255;
        const b = parseInt(hex.slice(5, 7), 16) / 255;
        return Qt.rgba(r, g, b, alpha).toString();
    }

    // ---- semantic colors ----
    readonly property string bg: background
    readonly property string fg: foreground
    readonly property string fgDim: rgba(foreground, 0.5)
    readonly property string accent: color5
    readonly property string muted: mix(foreground, color2, phiMin)
    readonly property string surface: rgba(background, uiOpacity)
    readonly property string surfaceHover: background
    readonly property string surfaceActive: mix(background, accent, 0.2)
    readonly property string border: rgba(foreground, 0.15)
    readonly property string danger: "#ff4444"
    readonly property string dangerBg: Qt.rgba(1.0, 0.26, 0.26, 0.1).toString()

    // Resource bar hues (upstream ResourceMonitor).
    readonly property string cpuColor: "#ff9f1c"
    readonly property string ramColor: "#4aa8ff"
    readonly property string gpuColor: "#ff5d5d"

    // ---- settings-driven scale ----
    readonly property real uiOpacity: 0.618
    readonly property int uiScale: 10
    readonly property int uiFontSize: 12
    readonly property bool animationsEnabled: true
    readonly property real animScale: 1.0
    readonly property real revealInPressure: 250
    readonly property real revealOutPressure: 1000
    property int leftPanelWidth: 400
    property int rightPanelWidth: 250
    property bool leftPanelLocked: false
    property bool rightPanelLocked: false
    property bool leftPanelHotZone: true
    property bool rightPanelHotZone: true
    readonly property int hotZoneSize: 5
    property var dateFormats: ["HH:mm", "hh:mm AP"]
    property int dateFormatIndex: 0
    readonly property string dateFormat: dateFormats[dateFormatIndex % dateFormats.length]

    function cycleDateFormat() {
        root.dateFormatIndex = (root.dateFormatIndex + 1) % root.dateFormats.length;
        return root.dateFormat;
    }

    // ---- typography / geometry ----
    readonly property string fontFamily: "JetBrainsMono NFP"
    readonly property string iconFamily: "JetBrainsMono NFP"
    readonly property int fontSize: uiFontSize
    readonly property int fontSizeSmall: Math.max(8, fontSize - 1)
    readonly property int fontSizeCaption: Math.max(7, fontSize - 2)
    readonly property int fontSizeBadge: Math.max(7, fontSize - 3)
    readonly property int fontSizeLarge: fontSize + 2
    readonly property int scale: uiScale
    readonly property int radius: 10
    readonly property int cardRadius: 8
    readonly property int chipRadius: 6
    readonly property string accentFg: "white"
    readonly property int spacing: 8
    readonly property int sectionSpacing: 20
    readonly property int barContentHeight: 18
    readonly property int barHeight: 32

    // ---- animation tokens (Material-3 expressive port) ----
    readonly property ArchAnim anim: ArchAnim {
        motion: root
    }

    // ---- pywal source; falls back to our M3 colors ----
    readonly property FileView cwal: FileView {
        path: `${Quickshell.env("HOME")}/.cache/cwal/colors.scss`
        watchChanges: true
        blockWrites: true
        onFileChanged: reload()
        onLoaded: {
            const t = text();
            const grab = (name, fb) => {
                const m = t.match(new RegExp("\\$" + name + "\\s*:\\s*(#[0-9a-fA-F]{6})"));
                return m ? m[1] : fb;
            };
            root.background = grab("background", root.background);
            root.foreground = grab("foreground", root.foreground);
            root.color0 = grab("color0", root.color0);
            root.color1 = grab("color1", root.color1);
            root.color2 = grab("color2", root.color2);
            root.color3 = grab("color3", root.color3);
            root.color4 = grab("color4", root.color4);
            root.color5 = grab("color5", root.color5);
            root.color6 = grab("color6", root.color6);
            root.color7 = grab("color7", root.color7);
            root.color8 = grab("color8", root.color8);
            root.themed = true;
        }
        onLoadFailed: {
            // No pywal palette: derive one from our Material-3 colors so the
            // family keeps the ArchEclipse feel on any wallpaper.
            const m3 = Appearance?.colors ?? {};
            const base = m3.colLayer0 ?? "#08080c";
            root.background = base;
            root.color0 = base;
            root.color1 = m3.colPrimary ?? "#493028";
            root.color2 = m3.colSecondary ?? "#413945";
            root.color3 = m3.colTertiary ?? "#4e505d";
            root.color4 = m3.colOnLayer2 ?? "#917f7a";
            root.color5 = m3.colPrimary ?? "#b7b5ae";
            root.color6 = m3.colSecondary ?? "#d7af96";
            root.foreground = m3.colOnLayer ?? "#aaabb2";
            root.color7 = root.foreground;
            root.color8 = m3.colOutline ?? "#555765";
        }
    }

    Component.onCompleted: cwal.reload()
}
