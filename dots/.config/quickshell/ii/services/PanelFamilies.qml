pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common

// Single source of truth for the panel families. The settings selector, the
// Super+Shift+W picker and the cycling shortcut all read this list, so adding a
// family only means touching this file plus the family loader in shell.qml.
Singleton {
    id: root

    readonly property list<var> families: [
        {
            value: "ii",
            label: Translation.tr("II"),
            icon: "dashboard",
            description: Translation.tr("Material You sidebars, launcher and bar")
        },
        {
            value: "waffle",
            label: Translation.tr("Waffle"),
            icon: "grid_view",
            description: Translation.tr("Compact grid bar with its own start menu")
        },
        {
            value: "archeclipse",
            label: Translation.tr("ArchEclipse"),
            icon: "router",
            description: Translation.tr("Arch themed bar with the settings card")
        }
    ]

    readonly property list<string> ids: families.map(family => family.value)

    function indexOf(value: string): int {
        return root.ids.indexOf(value);
    }

    function next(current: string): string {
        return root.ids[(root.indexOf(current) + 1) % root.ids.length];
    }
}
