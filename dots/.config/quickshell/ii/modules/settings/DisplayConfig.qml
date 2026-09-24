import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

ContentPage {
    forceWidth: true

    // Live monitor layout ported from end4-pC: drag-to-position canvas,
    // Extend / Duplicate per output, applied through hyprctl.

    MonitorConfigOption { id: monitorConfig }

    readonly property int selIndex: monitorCanvas.selectedIndex
    readonly property var selMonitor: monitorConfig.monitors[selIndex]

    // Position spinboxes snapshot the model value; any user edit is applied
    // through a debounce so we do one applyAndSave flush instead of one per tick.
    Timer {
        id: positionApplyTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (monitorCanvas.selectedIndex < 0) return
            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
        }
    }

    MonitorCanvas {
        id: monitorCanvas
        Layout.fillWidth: true
        Layout.preferredHeight: 230
        monitorConfig: monitorConfig
    }

    ContentSubsection {
        title: (selMonitor?.name ?? Translation.tr("No monitor")) + " · " + (selMonitor?.currentMode ?? "")

        ConfigSelectionArray {
            currentValue: selMonitor
                ? (selMonitor.mirror ? 1 : 0)
                : 0
            options: [
                { "displayName": Translation.tr("Extend"), "value": 0 },
                { "displayName": Translation.tr("Duplicate"), "value": 1 }
            ]
            onSelected: value => configureMode(value)
        }

        ConfigSpinBox {
            text: Translation.tr("X position")
            from: -10000
            to: 20000
            stepSize: 100
            value: selMonitor ? selMonitor.x : 0
            onValueChanged: {
                if (!selMonitor || monitorConfig.monitors.length === 0) return
                if (selMonitor.x === value) return
                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { x: value, y: selMonitor.y })
                positionApplyTimer.restart()
            }
        }

        ConfigSpinBox {
            text: Translation.tr("Y position")
            from: -10000
            to: 20000
            stepSize: 100
            value: selMonitor ? selMonitor.y : 0
            onValueChanged: {
                if (!selMonitor || monitorConfig.monitors.length === 0) return
                if (selMonitor.y === value) return
                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { x: selMonitor.x, y: value })
                positionApplyTimer.restart()
            }
        }
    }

    // --- Helpers ---
    function configureMode(value) {
        const idx = monitorCanvas.selectedIndex
        const m = monitorConfig.monitors[idx]
        if (!m) return

        // Hyprland duplicating = mirroring another output, not overlapping positions.
        const others = monitorConfig.monitors.filter(o => o.name !== m.name)
        const active = others.filter(o => !o.disabled)
        const primary = active[0] ?? others[0]

        if (value === 1) {
            // Duplicate: mirror the dominant display (focused one) if the selected
            // output is different, otherwise mirror the other output.
            const source = m.name !== primary?.name ? primary : others[0]
            if (source) monitorConfig.updateMonitor(idx, { disabled: false, mirror: source.name })
            else monitorConfig.updateMonitor(idx, { disabled: false })
        } else {
            // Extend: give the output a sane position when it was disabled or
            // already overlapping (e.g. a just-hotplugged panel at 0x0).
            let { x, y } = m
            if (m.disabled || monitorConfig.monitors.some(o => o.name !== m.name && !o.disabled && o !== m &&
                    x < o.x + monitorConfig.logicalWidth(o) && x + monitorConfig.logicalWidth(m) > o.x &&
                    y < o.y + monitorConfig.logicalHeight(o) && y + monitorConfig.logicalHeight(m) > o.y)) {
                const rightEdge = monitorConfig.monitors.reduce((max, o) =>
                    (o.name === m.name || o.disabled) ? max : Math.max(max, o.x + monitorConfig.logicalWidth(o)), -Infinity)
                x = rightEdge > -Infinity ? rightEdge : 0
                y = monitorConfig.monitors.reduce((min, o) =>
                    (o.name !== m.name && !o.disabled) ? Math.min(min, o.y) : min, 0)
                console.log(`[Display] Extend: ${m.name} reubicado a ${x}x${y}`)
            }
            monitorConfig.updateMonitor(idx, { disabled: false, mirror: null, x, y })
        }
        monitorConfig.applyAndSave(idx)
    }

    ConfigRow {
        ContentSubsection {
            title: Translation.tr("Pantalla dominante")
            Layout.fillWidth: true

            ConfigSwitch {
                buttonIcon: "star_half"
                text: Translation.tr("Hacer esta pantalla la principal (foco + workspaces)")
                checked: selMonitor?.focused ?? false
                onCheckedChanged: {
                    if (!checked) return
                    makePrimary(monitorCanvas.selectedIndex)
                }
            }
        }
    }

    function makePrimary(idx) {
        const m = monitorConfig.monitors[idx]
        if (!m || !m.name) return
        // This config uses the lua parser; only the hl.dsp.* dispatcher API works.
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ monitor = "${m.name}" })`])
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.workspace.move({ monitor = "${m.name}" })`])
        monitorConfig.update()
    }
}