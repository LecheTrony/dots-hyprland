import QtQuick

// Material-3 expressive motion tokens used across the ArchEclipse family
// (durations + bezier control points). `root.animationsEnabled` / `animScale`
// come from the owning theme, which injects itself as `motion`.
QtObject {
    id: root

    property QtObject motion: null
    readonly property real scale: motion && motion.animationsEnabled ? motion.animScale : 0

    readonly property int small: Math.round(200 * root.scale)
    readonly property int normal: Math.round(400 * root.scale)
    readonly property int large: Math.round(600 * root.scale)
    readonly property int extraLarge: Math.round(1000 * root.scale)
    readonly property int fastSpatial: Math.round(350 * root.scale)
    readonly property int defaultSpatial: Math.round(500 * root.scale)
    readonly property int slowSpatial: Math.round(650 * root.scale)
    readonly property int fastEffects: Math.round(150 * root.scale)
    readonly property int defaultEffects: Math.round(200 * root.scale)
    readonly property int slowEffects: Math.round(300 * root.scale)

    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
    readonly property var emphasized: [0.05, 0, 0.1333, 0.06, 0.1667, 0.4, 0.2083, 0.82, 0.25, 1, 1, 1]
    readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
}
