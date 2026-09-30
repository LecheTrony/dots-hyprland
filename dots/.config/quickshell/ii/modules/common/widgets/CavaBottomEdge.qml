pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// Screen edge audio visualiser.
//
// A thin layer surface pinned to the bottom of every screen, drawing the cava
// spectrum as bars mirrored around the horizontal centre. It lives outside the
// panel families on purpose: it is a screen decoration, not part of a bar, so it
// survives switching between ii, waffle and archeclipse.
Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: root

        required property var modelData
        readonly property bool isPrimary: modelData === Quickshell.primaryScreen

        // The delegate is a separate scope, so the geometry lives in the visualiser
        // service instead of on the Variants root.
        readonly property real stripHeight: CavaVisualizer.stripHeight
        readonly property real barStep: CavaVisualizer.barStep
        readonly property real barWidth: CavaVisualizer.barWidth

        screen: modelData
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "quickshell:cavaedge"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            bottom: true
            left: true
            right: true
        }

        // Only as tall as the bars can grow, and transparent everywhere else so
        // only the bars themselves are on screen.
        color: "transparent"
        implicitHeight: root.stripHeight

        Loader {
            id: opacityLoader
            anchors.fill: parent
            active: CavaVisualizer.running
            opacity: active ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

            sourceComponent: Canvas {
                id: canvas
                anchors.fill: parent

                // Canvas only redraws when asked, so every new spectrum frame has
                // to request a repaint. Reading the points through a property
                // is what wires that signal up; reading them straight from the
                // service inside onPaint would leave the first frame on screen
                // forever.
                property list<real> spectrum: CavaVisualizer.points

                // Bars lerp towards the incoming value instead of jumping, which
                // hides the difference between cava's actual frame rate and the
                // display refresh.
                property list<real> shown: []

                onSpectrumChanged: {
                    const target = canvas.spectrum;
                    if (canvas.shown.length !== target.length) {
                        canvas.shown = target.slice();
                    }
                    tick.restart();
                }

                // A 60Hz timer keeps the animation smooth when cava delivers
                // frames slower than the screen refreshes.
                Timer {
                    id: tick
                    interval: 16
                    repeat: true
                    running: canvas.spectrum.length > 1
                    onTriggered: canvas.step()
                }

                function step() {
                    const target = canvas.spectrum;
                    if (target.length < 2)
                        return;

                    const current = canvas.shown;
                    let moving = false;
                    for (let i = 0; i < target.length; i++) {
                        const from = current[i] ?? 0;
                        // Rise fast, fall slower: audio decays look better than
                        // a value that snaps back down.
                        const rate = target[i] > from ? 0.55 : 0.18;
                        const next = from + (target[i] - from) * rate;
                        current[i] = Math.abs(next - target[i]) < 0.5 ? target[i] : next;
                        if (Math.abs(current[i] - target[i]) > 0.5)
                            moving = true;
                    }

                    canvas.shown = current;
                    canvas.requestPaint();
                    // Keep ticking until everything settles at rest.
                    if (!moving)
                        tick.stop();
                }

                // Canvas has no roundRect here, so the rounded top of each bar
                // is traced by hand: flat sides, quarter circles on the caps.
                function roundedBar(ctx, x, y, w, h, r) {
                    const radius = Math.min(r, w / 2, h / 2);
                    ctx.beginPath();
                    ctx.moveTo(x, y + h);
                    ctx.lineTo(x, y + radius);
                    ctx.arcTo(x, y, x + radius, y, radius);
                    ctx.lineTo(x + w - radius, y);
                    ctx.arcTo(x + w, y, x + w, y + radius, radius);
                    ctx.lineTo(x + w, y + h);
                    ctx.closePath();
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const points = canvas.shown;
                    if (points.length < 2)
                        return;

                    const center = width / 2;
                    const maxHeight = root.stripHeight;
                    const step = root.barStep;
                    const barWidth = root.barWidth;
                    const radius = barWidth / 2;
                    const half = Math.ceil(points.length / 2);
                    const tint = Appearance.colors.colPrimary;

                    for (let i = 0; i < half; i++) {
                        // Slight gamma so quiet passages still move instead of
                        // hugging the floor.
                        const norm = Math.min(1, points[i] / CavaVisualizer.maxValue);
                        const barHeight = Math.pow(norm, 0.85) * maxHeight;
                        if (barHeight < 0.5)
                            continue;

                        const y = maxHeight - barHeight;
                        const right = center + i * step;
                        const left = center - (i + 1) * step;

for (const x of [left, right]) {
                        // Wide translucent pass first for the glow, then the
                        // solid bar, which is cheaper than a blur effect.
                        ctx.fillStyle = Qt.rgba(tint.r, tint.g, tint.b, 0.16);
                        roundedBar(ctx, x - 3, y - 3, barWidth + 6, barHeight + 3, radius + 3);
                        ctx.fill();

                        ctx.fillStyle = Qt.rgba(tint.r, tint.g, tint.b, 0.95);
                        roundedBar(ctx, x, y, barWidth, barHeight, radius);
                        ctx.fill();
                    }
                }
                }
            }
        }
    }
}