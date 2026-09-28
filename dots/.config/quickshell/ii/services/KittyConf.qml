pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Owns the kitty override file that the settings menus rewrite.
//
// The file is machine-local and gitignored: tweaking the terminal from the
// shell should never dirty the repo. kitty.conf includes it as its last line,
// and kitty processes includes in order, so whatever is written here wins over
// the versioned defaults without editing them.
Singleton {
    id: root

    property string overridesPath: Directories.kittyOverridesPath
    property bool ready: false

    // Debounced so dragging a slider does not rewrite the file per pixel.
    property int writeDelay: 400

    // Kept in sync with the shipped kitty.conf default, used before the config
    // has been read so the UI never shows a bogus value.
    readonly property real fallbackOpacity: 0.9
    readonly property real opacity: Config.ready ? Config.options.terminal.opacity : root.fallbackOpacity

    function buildOverrides() {
        return [
            "# Written by the settings menu (Quickshell).",
            "# Your changes are rewritten whenever a terminal setting changes.",
            "",
            "background_opacity " + root.opacity.toFixed(2),
            ""
        ].join("\n");
    }

    function write() {
        overridesFile.setText(root.buildOverrides());
    }

    // Called by the settings menus after they change a value.
    function scheduleWrite() {
        if (!Config.ready)
            return;
        writeTimer.restart();
    }

    // SIGUSR1 is the same reload the wallpaper theming script uses. Kitty also
    // watches the file on its own, but the signal keeps the two paths equal.
    function reloadTerminals() {
        Quickshell.execDetached(["bash", "-c", "pidof kitty | xargs -r kill -SIGUSR1"]);
    }

    FileView {
        id: overridesFile
        path: root.overridesPath
        blockLoading: true
        onLoaded: {
            root.ready = true;
            // Seed on shell start in case the file was removed or edited while
            // the shell was down. No reload signal: nothing changed on screen.
            if (overridesFile.text() !== root.buildOverrides())
                root.write();
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) {
                console.warn("[KittyConf] Could not read " + root.overridesPath);
                return;
            }
            root.ready = true;
            root.write();
        }
    }

    Timer {
        id: writeTimer
        interval: root.writeDelay
        repeat: false
        onTriggered: {
            root.write();
            root.reloadTerminals();
        }
    }

    // Called from the shell on startup so the file is seeded even if the user
    // never opens the settings menu.
    function load() {
        if (!configWatcher.running)
            configWatcher.restart();
    }

    Component.onCompleted: root.load()

    // The config loads asynchronously, so wait for it before seeding the file.
    Timer {
        id: configWatcher
        interval: 250
        repeat: true
        onTriggered: {
            if (!Config.ready)
                return;
            configWatcher.stop();
            if (overridesFile.text() !== root.buildOverrides())
                root.write();
        }
    }
}
