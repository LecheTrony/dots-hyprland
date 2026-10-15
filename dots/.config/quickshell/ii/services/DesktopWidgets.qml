pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property var catalog: [
        { key: "clock",       icon: "schedule",          name: Translation.tr("Clock") },
        { key: "weather",     icon: "partly_cloudy_day", name: Translation.tr("Weather") },
        { key: "calendar",    icon: "calendar_month",    name: Translation.tr("Calendar") },
        { key: "worldClock",  icon: "public",            name: Translation.tr("World Clock") },
        { key: "media",       icon: "music_note",        name: Translation.tr("Media") },
        { key: "visualizer",  icon: "graphic_eq",        name: Translation.tr("Visualizer") },
        { key: "resources",   icon: "monitor_heart",     name: Translation.tr("Resources") },
        { key: "userCard",    icon: "person",            name: Translation.tr("User Card") },
        { key: "todo",        icon: "add_task",          name: Translation.tr("To-Do") },
        { key: "notes",       icon: "note_stack_add",    name: Translation.tr("Notes") },
        { key: "timers",      icon: "timer",             name: Translation.tr("Timers") },
        { key: "images",      icon: "photo_library",     name: Translation.tr("Image Converter") },
        { key: "customImage", icon: "image",             name: Translation.tr("Custom Image") },
        { key: "imageCard",   icon: "photo_size_select_large", name: Translation.tr("Image Card") },
        { key: "sticker",     icon: "sticker",           name: Translation.tr("Sticker") }
    ]

    readonly property var hidden: Array.from(Config.options.background.widgets.menuHidden)
    readonly property var menuItems: catalog.filter(w => !hidden.includes(w.key))
    readonly property int enabledCount: catalog.filter(w => isEnabled(w.key)).length

    function isEnabled(key) {
        return Config.options.background.widgets[key].enable;
    }

    function setEnabled(key, value) {
        if (value) {
            const widgets = Config.options.background.widgets;
            const entry = widgets[key];
            let x = entry.x;
            let y = entry.y;
            let tries = 0;
            while (tries < 40 && catalog.some(w => w.key !== key && isEnabled(w.key)
                    && Math.abs(widgets[w.key].x - x) < 1 && Math.abs(widgets[w.key].y - y) < 1)) {
                x += 40;
                y += 40;
                tries++;
            }
            entry.x = x;
            entry.y = y;
        }
        Config.options.background.widgets[key].enable = value;
    }

    function isStarred(key) {
        return !hidden.includes(key);
    }

    function setStarred(key, starred) {
        const next = hidden.filter(k => k !== key);
        if (!starred) next.push(key);
        Config.options.background.widgets.menuHidden = next;
    }

    function toggleStar(key) {
        setStarred(key, !isStarred(key));
    }
}
