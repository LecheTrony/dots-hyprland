import QtQuick
import qs.modules.archeclipse.looks

// Shared unfold body clip. Callers set `expand` 0->1 (discretely) and pass the
// target body height; the clip animates the fold itself so the surface wipes
// as one unit, like the ArchEclipse side pills.
Item {
    id: root

    property real expand: 0
    property real contentHeight: 0

    width: parent ? parent.width : 0
    height: Math.max(0, root.expand * root.contentHeight)
    implicitHeight: height
    clip: true
    opacity: Math.max(0, Math.min(1, root.expand * 1.4))
    transform: Translate {
        y: (1 - root.expand) * -8
    }

    Behavior on expand {
        enabled: ArchTheme.animationsEnabled
        NumberAnimation {
            duration: ArchTheme.anim.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ArchTheme.anim.emphasizedDecel
        }
    }
}
