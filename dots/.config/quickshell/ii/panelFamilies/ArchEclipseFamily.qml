import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.archeclipse.bar
import qs.modules.archeclipse.services
import qs.modules.ii.background
import qs.modules.ii.cheatsheet
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overlay
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.wallpaperSelector

Scope {
    // The bar owns its own left/right side panels (edge-docked pills in
    // the bar layer), so the standalone ii sidebars stay out of this family.
    PanelLoader { component: Bar {} }
    // `qs -c ii ipc call bar ...` (IpcHandler roots cannot be singletons).
    ArchIpc {}
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: WallpaperSelector {} }
}