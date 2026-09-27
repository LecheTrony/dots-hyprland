pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Networking
import qs.services
import qs.modules.archeclipse.looks

// ArchEclipse bar state, ported from the upstream `BarState` service.
//
// Several states can be active at the same time; the main pill renders the
// highest-priority one. Side panels (left/right) are independent overlays:
// they never win the main pill and can be open simultaneously, which is why
// they live in their own open flags instead of the resolved state.
//
// Priority map (default base 0 < recording 40 < pulses 80 < overview 85 <
// control 90 < side pills 93 < wallpaper 95 < search 100).
Singleton {
    id: root

    readonly property var priority: ({
        "default": 0,
        "recording": 40,
        "volume": 80,
        "brightness": 80,
        "network": 80,
        "player": 80,
        "weather": 80,
        "system": 80,
        "overview": 85,
        "control": 90,
        "left": 93,
        "right": 93,
        "wallpaper": 95,
        "search": 100
    })

    // name -> { priority }. Reassigned wholesale so bindings stay reactive.
    property var activeStates: ({ "default": ({ priority: 0 }) })
    // name -> Timer, for states that auto-deactivate.
    property var holdTimers: ({})

    readonly property string state: root.resolveState()
    readonly property bool leftOpen: "left" in root.activeStates
    readonly property bool rightOpen: "right" in root.activeStates
    readonly property bool islandOpen: root.state !== "default"
    readonly property bool anyOpen: root.islandOpen || root.leftOpen || root.rightOpen

    // Open in-bar popovers (tray overflow, menus) hold the hover-leave
    // collapse while they are up.
    property int popupCount: 0

    // Emitido por el boton de ajustes para que el panel izquierdo salte a su
    // tarjeta de ajustes (el widget vive dentro del island, no en una ventana).
    signal settingsRequested()

    // Probe de diagnostico instalado por el LeftIsland (ver islandDiag).
    property var _leftIslandDiag: null

    function holdPopup() {
        root.popupCount++;
    }
    function releasePopup() {
        root.popupCount = Math.max(0, root.popupCount - 1);
    }

    // True when a state is active with no auto-deactivate timer, i.e. it was
    // pinned rather than pulsed.
    function isPersistent(name) {
        return (name in (root.activeStates || {})) && !(root.holdTimers || {})[name];
    }

    function resolveState() {
        let best = "default";
        let bestPriority = -Infinity;
        const active = root.activeStates || {};
        for (const name in active) {
            // Side panels are independent overlays, never main-pill states.
            if (name === "left" || name === "right" || name === "recording")
                continue;
            const entry = active[name];
            if (entry && entry.priority > bestPriority) {
                best = name;
                bestPriority = entry.priority;
            }
        }
        return best;
    }

    // holdMs > 0 arms an auto-deactivate; 0 keeps the state until it is
    // explicitly deactivated.
    function activate(name, holdMs) {
        const priority = root.priority[name];
        if (priority === undefined || name === "default")
            return;

        // Both pulses render through the control island: a lingering rival
        // would flip the resolved state when its own timer expires.
        if (name === "volume" || name === "brightness") {
            const rival = name === "volume" ? "brightness" : "volume";
            root.deactivate(rival);
        }

        const timers = Object.assign({}, root.holdTimers || {});
        if (timers[name]) {
            timers[name].stop();
            timers[name].destroy();
            delete timers[name];
        }

        const next = Object.assign({}, root.activeStates || {});
        next[name] = { priority: priority };
        root.activeStates = next;

        if (holdMs !== undefined && holdMs > 0) {
            const t = Qt.createQmlObject("import QtQuick; Timer { repeat: false; interval: " + holdMs + " }", root);
            t.triggered.connect(() => {
                root.deactivate(name);
                t.destroy();
            });
            t.start();
            timers[name] = t;
            root.holdTimers = timers;
        }
    }

    function deactivate(name) {
        if (!name || name === "default")
            return;

        const timers = Object.assign({}, root.holdTimers || {});
        if (timers[name]) {
            timers[name].stop();
            timers[name].destroy();
            delete timers[name];
            root.holdTimers = timers;
        }

        if (!(name in (root.activeStates || {})))
            return;

        const next = Object.assign({}, root.activeStates);
        delete next[name];
        root.activeStates = next;
    }

    function toggle(name) {
        if (name in (root.activeStates || {}))
            root.deactivate(name);
        else
            root.activate(name);
    }

    // ------------------------------------------------------------------
    // Pulse watchers. Each one opens its island for a few seconds when the
    // underlying thing actually changes, so volume/brightness keys, network
    // transitions and track changes surface without touching the bar.
    // ------------------------------------------------------------------

    // ---- volume (default sink) ----
    property bool _volumeWired: false
    property real _lastVolume: 0
    property bool _volumeFirstRender: true

    function setupVolumeWatcher() {
        if (root._volumeWired)
            return;
        const sink = Audio.sink;
        if (!sink || !sink.audio) {
            const retry = Qt.createQmlObject("import QtQuick; Timer { repeat: false; interval: 1000 }", root);
            retry.triggered.connect(() => {
                retry.destroy();
                root.setupVolumeWatcher();
            });
            retry.start();
            return;
        }
        root._volumeWired = true;
        root._lastVolume = sink.audio.volume ?? 0;
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            const sink = Audio.sink;
            if (!sink || !sink.audio)
                return;
            const vol = sink.audio.volume;
            if (vol === undefined || vol === null || isNaN(vol) || vol < 0)
                return;
            if (root._volumeFirstRender) {
                root._volumeFirstRender = false;
                root._lastVolume = vol;
                return;
            }
            if (vol === root._lastVolume)
                return;
            root._lastVolume = vol;
            if (!root.isPersistent("volume"))
                root.activate("volume", ArchTheme.revealOutPressure);
        }
    }

    // ---- brightness ----
    property real _lastBrightness: 0
    property bool _brightnessFirstRender: true

    function primaryBrightness() {
        const monitors = Brightness.monitors || [];
        for (const m of monitors) {
            if (m && m.ready)
                return m.multipliedBrightness;
        }
        return null;
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            const val = root.primaryBrightness();
            if (val === null || val === undefined || isNaN(val))
                return;
            if (root._brightnessFirstRender) {
                root._brightnessFirstRender = false;
                root._lastBrightness = val;
                return;
            }
            if (val === root._lastBrightness)
                return;
            root._lastBrightness = val;
            if (!root.isPersistent("brightness"))
                root.activate("brightness", ArchTheme.revealOutPressure);
        }
    }

    // ---- player ----
    property var _activePlayer: null
    property string _playerKey: ""
    property bool _playerFirstRender: true
    property bool _playerStarting: true

    function pickPlayer() {
        const players = MprisController.players || [];
        for (const p of players) {
            if ((p.trackTitle ?? "").trim() !== "" || p.isPlaying)
                return p;
        }
        return null;
    }

    function previewUrl(p) {
        try {
            const md = p ? p.metadata : null;
            if (!md)
                return "";
            const u = md["xesam:url"];
            return u === undefined || u === null ? "" : String(u);
        } catch (e) {
            return "";
        }
    }

    function playerItemKey(p) {
        if (!p)
            return "";
        return (p.uniqueId ?? "?") + "|" + (p.trackTitle ?? "") + "|" + (p.trackArtist ?? "") + "|" + root.previewUrl(p);
    }

    // YouTube browse pages publish the hovered video's title as transient
    // metadata; that is preview noise, not a new item.
    function isPreviewUpdate(p) {
        const m = root.previewUrl(p).match(/^https?:\/\/(?:www\.|m\.)?youtube\.com(\/[^?#]*)?/i);
        if (!m)
            return false;
        const path = (m[1] || "/").toLowerCase();
        return !(/^\/(watch|shorts\/|embed\/|live\/|v\/)/.test(path));
    }

    function notePlayerUpdate() {
        const player = root.pickPlayer();
        root._activePlayer = player;
        const key = root.playerItemKey(player);

        if (root._playerFirstRender) {
            root._playerFirstRender = false;
            root._playerKey = key;
            return;
        }
        if (key === root._playerKey)
            return;
        root._playerKey = key;

        if (!player || root.isPreviewUpdate(player))
            return;
        if (root._playerStarting)
            return;
        root.activate("player", 2500);
    }

    Connections {
        target: MprisController
        function onPlayersChanged() {
            root.notePlayerUpdate();
        }
    }

    Connections {
        target: root._activePlayer
        function onTrackChanged() {
            root.notePlayerUpdate();
        }
        function onPostTrackChanged() {
            root.notePlayerUpdate();
        }
        function onTrackTitleChanged() {
            root.notePlayerUpdate();
        }
        function onTrackArtistChanged() {
            root.notePlayerUpdate();
        }
        function onMetadataChanged() {
            root.notePlayerUpdate();
        }
    }

    // ---- network ----
    property var _networkDevice: null
    property bool _networkFirstRender: true
    property var _lastNetSig: ({})

    function primaryNetworkDevice() {
        const devices = Networking.devices?.values;
        if (!devices)
            return null;
        for (const d of devices) {
            if (d && d.connected)
                return d;
        }
        return devices.length > 0 ? devices[0] : null;
    }

    function noteNetworkUpdate() {
        let device = root.primaryNetworkDevice();
        if (device !== root._networkDevice) {
            root._networkDevice = device;
            if (!device)
                return;
            root._networkFirstRender = true;
        }
        if (!device)
            return;
        if (root._networkFirstRender) {
            root._networkFirstRender = false;
            root._lastNetSig = { state: device.state, connected: device.connected };
            return;
        }
        const changed = device.connected !== root._lastNetSig.connected || device.state !== root._lastNetSig.state;
        root._lastNetSig = { state: device.state, connected: device.connected };
        if (changed)
            root.activate("network", 3000);
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.noteNetworkUpdate()
    }

    Component.onCompleted: {
        root.notePlayerUpdate();
        root.noteNetworkUpdate();
        // MPRIS metadata trickles in over the first seconds after start; a
        // late first item must not pulse the player island on every boot.
        const grace = Qt.createQmlObject("import QtQuick; Timer { repeat: false; interval: 5000 }", root);
        grace.triggered.connect(() => {
            root._playerStarting = false;
            grace.destroy();
        });
        grace.start();
        const wire = Qt.createQmlObject("import QtQuick; Timer { repeat: false; interval: 1000 }", root);
        wire.triggered.connect(() => {
            wire.destroy();
            root.setupVolumeWatcher();
        });
        wire.start();
    }
}
