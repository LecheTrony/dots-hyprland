//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}
    PanelFamilyPicker {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
        KittyConf.load()
    }


    // Panel families
    function cyclePanelFamily() {
        Config.options.panelFamily = PanelFamilies.next(Config.options.panelFamily)
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }

    PanelFamilyLoader {
        identifier: "archeclipse"
        component: ArchEclipseFamily {}
    }


    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}

