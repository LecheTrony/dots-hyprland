import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.archeclipse.looks

// Single launcher tile: icon over name, launches the desktop entry.
Rectangle {
    id: root

    property var entry: null
    signal launchRequested(var entry)

    height: width + 14
    radius: ArchTheme.chipRadius
    color: hover.hovered ? ArchTheme.surfaceHover : "transparent"
    Behavior on color {
        ColorAnimation {
            duration: ArchTheme.anim.fastEffects
        }
    }

    IconImage {
        id: icon
        width: Math.min(28, root.width * 0.5)
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4
        source: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
        asynchronous: true
        mipmap: true
    }

    Text {
        anchors.top: icon.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 4
        text: root.entry?.name ?? ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: hover.hovered ? ArchTheme.fg : ArchTheme.fgDim
        font.family: ArchTheme.fontFamily
        font.pixelSize: ArchTheme.fontSizeBadge
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.entry)
                return;
            try {
                root.entry.execute();
            } catch (e) {
                console.warn("archeclipse: failed to launch", root.entry.id, e);
            }
            root.launchRequested(root.entry);
        }
    }
}
