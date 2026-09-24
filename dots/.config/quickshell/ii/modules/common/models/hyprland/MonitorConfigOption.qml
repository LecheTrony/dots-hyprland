pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.functions
import "../"

NestableObject {
    id: root

    property var monitors: []
    property var _pendingChanges: ({})

    readonly property string configuratorScriptPath: Quickshell.shellPath("scripts/hyprland/monitor_configurator.py")
    readonly property string capsScriptPath: Quickshell.shellPath("scripts/hyprland/monitor_caps.py")
    readonly property string monitorsLuaPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/monitors.lua`)

    Component.onCompleted: fetchProc.running = true

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorlayout", "configreloaded"].includes(event.name))
                refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        repeat: false
        onTriggered: fetchProc.running = true
    }

    function update() {
        refreshTimer.restart()
    }

    function updateMonitor(index, changes) {
        let m = root.monitors.slice()
        m[index] = Object.assign({}, m[index], changes)
        root.monitors = m

        let pending = Object.assign({}, root._pendingChanges)
        pending[index] = Object.assign({}, pending[index] || {}, changes)
        root._pendingChanges = pending
    }

    function _mergeByName(patchByName) {
        root.monitors = root.monitors.map(mon => {
            const patch = patchByName[mon.name]
            return patch ? Object.assign({}, mon, patch) : mon
        })
    }

    function _modeToLua(m) {
        const parts = m.currentMode.match(/(\d+)x(\d+)@([\d.]+)Hz/)
        return parts ? `${parts[1]}x${parts[2]}@${parseFloat(parts[3])}` : m.currentMode
    }

    function _fieldsToWrite(m, changedKeys) {
        const setPairs = {}
        const resetKeys = []

        if (changedKeys.has("disabled")) {
            if (m.disabled) {
                setPairs["disabled"] = "1"
                // A disabled output cannot stay mirrored.
                if (m.mirror) resetKeys.push("mirror")
            } else {
                resetKeys.push("disabled")
            }
        }
        if (changedKeys.has("mirror")) {
            if (m.mirror) setPairs["mirror"] = m.mirror
            else resetKeys.push("mirror")
        }
        if (changedKeys.has("x") || changedKeys.has("y")) {
            setPairs["position"] = `${m.x}x${m.y}`
        }
        if (changedKeys.has("currentMode") || changedKeys.has("width") || changedKeys.has("height") || changedKeys.has("refreshRate")) {
            setPairs["mode"] = root._modeToLua(m)
        }
        if (changedKeys.has("scale")) setPairs["scale"] = m.scale
        if (changedKeys.has("transform")) {
            if (m.transform && m.transform !== 0) setPairs["transform"] = m.transform
            else resetKeys.push("transform")
        }
        if (changedKeys.has("bitdepth")) {
            if (m.bitdepth) setPairs["bitdepth"] = m.bitdepth
            else resetKeys.push("bitdepth")
        }
        if (changedKeys.has("cm")) {
            if (m.cm && m.cm !== "auto") setPairs["cm"] = m.cm
            else resetKeys.push("cm")
        }
        if (changedKeys.has("sdrBrightness")) setPairs["sdrbrightness"] = m.sdrBrightness
        if (changedKeys.has("sdrSaturation")) setPairs["sdrsaturation"] = m.sdrSaturation
        if (changedKeys.has("minLuminance")) setPairs["min_luminance"] = m.minLuminance
        if (changedKeys.has("maxLuminance")) setPairs["max_luminance"] = m.maxLuminance
        if (changedKeys.has("maxAvgLuminance")) setPairs["max_avg_luminance"] = m.maxAvgLuminance
        if (changedKeys.has("sdrMinLuminance")) setPairs["sdr_min_luminance"] = m.sdrMinLuminance
        if (changedKeys.has("sdrMaxLuminance")) setPairs["sdr_max_luminance"] = m.sdrMaxLuminance
        if (changedKeys.has("vrr")) setPairs["vrr"] = m.vrr ? "1" : "0"

        return { setPairs, resetKeys }
    }

    function save(index) {
        const m = root.monitors[index]
        if (!m || !m.name) return

        const changed = root._pendingChanges[index]
        if (!changed) return
        const changedKeys = new Set(Object.keys(changed))
        const { setPairs, resetKeys } = root._fieldsToWrite(m, changedKeys)

        if (Object.keys(setPairs).length === 0 && resetKeys.length === 0) return

        let args = ["python3", root.configuratorScriptPath, "--file", root.monitorsLuaPath, "--output", m.name]
        for (const key in setPairs) args.push("--set", key, String(setPairs[key]))
        for (const key of resetKeys) args.push("--reset", key)

        root._saveQueue.push(args)
        if (!root._reloadPending) {
            root._reloadPending = true
            root._saveQueue.push(null)
        }
        root._drainSaveQueue()

        let pending = Object.assign({}, root._pendingChanges)
        delete pending[index]
        root._pendingChanges = pending
    }

    property var _saveQueue: []
    property bool _reloadPending: false
    function _drainSaveQueue() {
        if (saveProc.running || root._saveQueue.length === 0) return
        saveProc.command = root._saveQueue.shift()
        saveProc.running = true
    }

    function applyMonitor(m) {
        if (!m.name) return

        // This config uses the lua parser (hyprland.lua); 'hyprctl keyword'
        // silently fails there, so changes go through 'hyprctl eval'.
        const fields = []
        if (m.disabled) {
            fields.push(`output = "${m.name}"`, `disabled = true`)
        } else if (m.mirror) {
            fields.push(`output = "${m.name}"`, `mirror = "${m.mirror}"`, `disabled = false`)
        } else {
            // "mirror = \"\"" is required to actually un-mirror an output
            // that was previously mirrored.
            fields.push(
                `output = "${m.name}"`,
                `mirror = ""`,
                `position = "${m.x}x${m.y}"`,
                `scale = ${m.scale}`,
                ...(m.transform && m.transform !== 0 ? [`transform = ${m.transform}`] : [])
            )
        }
        // Escaped for the lua code that hyprctl eval runs.
        const lua = `hl.monitor({ ${fields.join(", ")} })`
        root._applyQueue.push(["hyprctl", "eval", lua])
        root._drainApplyQueue()
    }

    property var _applyQueue: []
    function _drainApplyQueue() {
        if (applyProc.running || root._applyQueue.length === 0) return
        applyProc.command = root._applyQueue.shift()
        applyProc.running = true
    }

    function applyAndSave(index) {
        root.applyMonitor(root.monitors[index])
        root.save(index)
    }

    function saveHdr(index) {
        root.save(index)
    }

    function logicalWidth(m) {
        return (m.transform === 1 || m.transform === 3) ? m.height : m.width
    }

    function logicalHeight(m) {
        return (m.transform === 1 || m.transform === 3) ? m.width : m.height
    }

    Process {
        id: fetchProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rawMonitors = JSON.parse(text)
                    const idToName = {}
                    for (const m of rawMonitors) idToName[String(m.id)] = m.name
                    root.monitors = rawMonitors.map(m => ({
                        name:          m.name,
                        description:   m.description,
                        width:         m.width,
                        height:        m.height,
                        refreshRate:   m.refreshRate,
                        x:             m.x,
                        y:             m.y,
                        scale:         m.scale,
                        transform:     m.transform ?? 0,
                        mirror:        m.mirrorOf && m.mirrorOf !== "none" ? (idToName[String(m.mirrorOf)] ?? null) : null,
                        disabled:      m.disabled,
                        focused:       m.focused,
                        availableModes: m.availableModes,
                        currentMode:   `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}Hz`,
                        cm:            m.colorManagementPreset ?? "auto",
                        sdrBrightness: m.sdrBrightness ?? 1.0,
                        sdrSaturation: m.sdrSaturation ?? 1.0,
                        sdrMinLuminance: m.sdrMinLuminance ?? 0,
                        sdrMaxLuminance: m.sdrMaxLuminance ?? 0,
                        vrr:           m.vrr ?? false,
                        bitdepth:        null,
                        minLuminance:    null,
                        maxLuminance:    null,
                        maxAvgLuminance: null,

                        hdrSupported: null,
                        maxBpc:       null,
                    }))
                    if (root.monitors.length > 0) {
                        capsProc.command = ["python3", root.capsScriptPath].concat(root.monitors.map(mon => mon.name))
                        capsProc.running = true
                        dumpProc.command = ["python3", root.configuratorScriptPath, "--file", root.monitorsLuaPath, "--dump-all"]
                        dumpProc.running = true
                    }
                } catch(e) {
                    console.log("[MonitorConfig] Error parseando JSON:", e)
                }
            }
        }
    }

    Process {
        id: capsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const caps = JSON.parse(text)
                    let patch = {}
                    for (const name in caps) {
                        patch[name] = { hdrSupported: caps[name].hdr, maxBpc: caps[name].maxBpc }
                    }
                    root._mergeByName(patch)
                } catch(e) {
                    console.log("[MonitorConfig] Error parsing caps JSON:", e)
                }
            }
        }
    }

    Process {
        id: dumpProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const dump = JSON.parse(text)
                    let patch = {}
                    for (const name in dump) {
                        const d = dump[name]
                        patch[name] = {
                            bitdepth:        d.bitdepth ?? null,
                            minLuminance:    d.min_luminance ?? null,
                            maxLuminance:    d.max_luminance ?? null,
                            maxAvgLuminance: d.max_avg_luminance ?? null,
                        }
                    }
                    root._mergeByName(patch)
                } catch(e) {
                    console.log("[MonitorConfig] Error parsing monitors.lua dump JSON:", e)
                }
            }
        }
    }

    Process {
        id: applyProc
        onRunningChanged: if (!running) root._drainApplyQueue()
    }

    Process {
        id: saveProc
        onRunningChanged: {
            if (running) return
            if (root._saveQueue.length > 0 && root._saveQueue[0] === null) {
                root._saveQueue.shift()
                root._reloadPending = false
                reloadProc.running = true
            } else {
                root._drainSaveQueue()
            }
        }
    }

    Process {
        id: reloadProc
        command: ["hyprctl", "reload"]
    }
}
