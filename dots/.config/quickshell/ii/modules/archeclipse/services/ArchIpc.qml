import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

// Hyprland bindings and scripts drive the bar through `qs ipc`:
//
//   qs -c ii ipc call bar toggleSearch
//   qs -c ii ipc call bar toggleControl
//   qs -c ii ipc call bar toggleLeftPanel  [monitor]
//   qs -c ii ipc call bar toggleRightPanel [monitor]
//   qs -c ii ipc call bar toggleWallpaper
//   qs -c ii ipc call bar barDiag state
//
// Mirrors the upstream `Ipc.qml` surface. Instantiated by the panel family
// (not a singleton: Quickshell needs a non-singleton IpcHandler root).
Item {
    id: root

    IpcHandler {
        target: "bar"

        function toggleSearch(): string {
            if (ArchBarState.state === "search") {
                ArchBarState.deactivate("search");
                return "search closed";
            }
            ArchBarState.activate("search", 0);
            return "search open";
        }

        function toggleControl(): string {
            if (ArchBarState.state === "control") {
                ArchBarState.deactivate("control");
                return "control closed";
            }
            ArchBarState.activate("control", 0);
            return "control open";
        }

        function toggleLeftPanel(monitor: string): string {
            if (ArchBarState.leftOpen) {
                ArchBarState.deactivate("left");
                return "left closed";
            }
            ArchBarState.activate("left", 0);
            return monitor ? "left open on " + monitor : "left open";
        }

        function toggleRightPanel(monitor: string): string {
            if (ArchBarState.rightOpen) {
                ArchBarState.deactivate("right");
                return "right closed";
            }
            ArchBarState.activate("right", 0);
            return monitor ? "right open on " + monitor : "right open";
        }

        // Side panels are independent overlays: this opens the requested one
        // without touching whatever else is up (upstream behaviour).
        function openPanel(side: string): string {
            // The side overlays are independent, so "both" just opens the two
            // of them in turn; anything else is a middle-page name.
            if (side === "both") {
                ArchBarState.activate("left", 0);
                ArchBarState.activate("right", 0);
                return "open left right";
            }
            ArchBarState.activate(side, 0);
            return "open " + side;
        }

        function closePanel(side: string): string {
            ArchBarState.deactivate(side);
            return "closed " + side;
        }

        function togglePanelLock(side: string): string {
            if (side === "right") {
                ArchTheme.rightPanelLocked = !ArchTheme.rightPanelLocked;
                return "rightPanelLocked=" + ArchTheme.rightPanelLocked;
            }
            ArchTheme.leftPanelLocked = !ArchTheme.leftPanelLocked;
            return "leftPanelLocked=" + ArchTheme.leftPanelLocked;
        }

        // The ii wallpaper selector is its own panel with its own IPC target;
        // route the reference's wallpaper binding at it.
        function toggleWallpaper(): string {
            Quickshell.execDetached(["qs", "-c", Quickshell.shellPath(""), "ipc", "call", "wallpapers", "openFallbackPicker"]);
            return "sent to the ii wallpaper selector";
        }

        // Diagnostic: query is "state", "pulse:<name>:<holdMs>", or
        // "on:<name>" / "off:<name>" for persistent states.
        function barDiag(query: string): string {
            try {
                if (query === "state")
                    return "state=" + ArchBarState.state + " left=" + ArchBarState.leftOpen + " right=" + ArchBarState.rightOpen;
                if (query.startsWith("pulse:")) {
                    const rest = query.substring(6).split(":");
                    ArchBarState.activate(rest[0], Number(rest[1]) || 2000);
                    return "pulsed=" + rest[0] + " state=" + ArchBarState.state;
                }
                if (query.startsWith("on:")) {
                    ArchBarState.activate(query.substring(3));
                    return "on state=" + ArchBarState.state;
                }
                if (query.startsWith("off:")) {
                    ArchBarState.deactivate(query.substring(4));
                    return "off state=" + ArchBarState.state;
                }
                if (query === "all-off") {
                    for (const name of Object.keys(ArchBarState.activeStates))
                        ArchBarState.deactivate(name);
                    return "reset state=" + ArchBarState.state;
                }
                return "unknown query";
            } catch (e) {
                return "EX: " + e;
            }
        }

        // Brings the left island settings card into view (same path as the
        // bar's settings button).
        function focusSettings(): string {
            ArchBarState.settingsRequested();
            return "settings focused";
        }

        // Left island probe: widget list + scroll geometry (QA / debugging).
        function islandDiag(): string {
            try {
                return ArchBarState._leftIslandDiag ? ArchBarState._leftIslandDiag() : "no island";
            } catch (e) {
                return "EX: " + e;
            }
        }

        // Player probe for MPRIS QA: "title | artist | playing".
        function playerDiag(): string {
            try {
                const p = ArchBarState._activePlayer;
                if (!p)
                    return "no players";
                return (p.trackTitle || "?") + " | " + (p.trackArtist || "?") + " | " + (p.isPlaying ? "playing" : "stopped");
            } catch (e) {
                return "EX: " + e;
            }
        }
    }
}
