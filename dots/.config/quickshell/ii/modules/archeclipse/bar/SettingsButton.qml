import QtQuick
import Quickshell
import qs.modules.common.widgets
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

Item {
    id: root

    width: 22
    implicitWidth: 22
    height: ArchTheme.barContentHeight
    implicitHeight: ArchTheme.barContentHeight

    Rectangle {
        anchors.fill: parent
        radius: ArchTheme.radius
        color: hoverHandler.hovered ? ArchTheme.surfaceHover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: ArchTheme.anim.fastEffects
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "settings"
            iconSize: 14
            color: hoverHandler.hovered ? ArchTheme.fg : ArchTheme.fgDim
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    // The settings UI is a card inside the left island (upstream layout), so
    // the button opens that panel and scrolls to the card instead of spawning
    // the ii settings window.
    TapHandler {
        onTapped: {
            if (!ArchBarState.leftOpen)
                ArchBarState.activate("left", 0);
            focusDelay.restart();
        }
    }

    Timer {
        id: focusDelay
        interval: 280
        onTriggered: ArchBarState.settingsRequested()
    }
}
