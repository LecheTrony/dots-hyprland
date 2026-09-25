import QtQuick
import qs.modules.common
import Quickshell

/**
 * Two-slot wallpaper crossfader adapted from snowarch/iNiR's WallpaperCrossfader
 * to the end-4 base. Pure QML kinematics (no GPU shader transitions, no blur):
 * crossfade / fadeThrough / zoom / slide / push / wipe.
 *
 * The root keeps the same geometry contract as the plain Image it replaces
 * (parallax x/y, scaled width/height), while the two inner slots animate
 * opacity/scale/translation/clip relative to it.
 */
Item {
    id: root

    // ── Public API ──────────────────────────────────────────────────────
    property string source: ""
    property int fillMode: Image.PreserveAspectCrop
    property size sourceSize

    property bool transitionsEnabled: true
    property string transitionType: "crossfade"
    property string transitionDirection: "right" // left | right | up | down
    readonly property int _transitionDuration: 700

    readonly property bool transitioning: _transitioning
    // Stays true during a transition so external consumers (blur layers,
    // visibility guards) don't flicker.
    readonly property bool ready: img0.status === Image.Ready || img1.status === Image.Ready

    signal transitionStarted()
    signal transitionFinished()

    // ── Constants ───────────────────────────────────────────────────────
    readonly property real _dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1
    readonly property real _zoomEnterFrom: 1.12
    readonly property real _zoomExitTo: 0.9
    readonly property real _wipeIncomingParallax: 0.1
    readonly property real _wipeOutgoingParallax: 0.06
    readonly property real _slideExitDistance: 0.45
    readonly property real _pushIncomingOffset: 0.45
    readonly property real _pushExitDistance: 0.32
    readonly property real _crossfadeIncomingScale: 1.018
    readonly property real _crossfadeOutgoingScale: 0.985
    readonly property list<real> _defaultCurve: [0.54, 0.0, 0.34, 0.99, 1, 1]
    readonly property list<string> _randomPool: ["crossfade", "fadeThrough", "zoom", "slide", "push", "wipe"]

    // ── Internal state ─────────────────────────────────────────────────
    property bool _transitioning: false
    property string _transitionKind: "" // concrete type resolved at switch time ("random" becomes a fixed pick)
    property real _transitionWidthSnapshot: 0
    property real _transitionHeightSnapshot: 0
    property size _transitionSourceSizeSnapshot: Qt.size(0, 0)

    QtObject {
        id: internal
        property int activeIndex: 0
        property int transitionFromIndex: -1
        property int transitionToIndex: -1
        property string displayedSource: ""
        property string pendingSource: ""
        property string loadingSource: ""

        function slotImage(slotIndex) {
            return slotIndex === 0 ? img0 : img1
        }
        function activeImage() {
            return slotImage(activeIndex)
        }
        function inactiveImage() {
            return slotImage(activeIndex === 0 ? 1 : 0)
        }
        function resetTransition() {
            transitionAnim.stop()
            transitionState.progress = 0
            transitionFromIndex = -1
            transitionToIndex = -1
            _transitionKind = ""
            _transitionWidthSnapshot = 0
            _transitionHeightSnapshot = 0
            _transitionSourceSizeSnapshot = Qt.size(0, 0)
        }
        function switchTo(newSource) {
            if (newSource === "") {
                resetTransition()
                _transitioning = false
                img0.source = ""
                img1.source = ""
                displayedSource = ""
                pendingSource = ""
                loadingSource = ""
                activeIndex = 0
                return
            }

            pendingSource = newSource

            if (!root._canTransition) {
                activeImage().source = newSource
                inactiveImage().source = ""
                displayedSource = newSource
                pendingSource = ""
                loadingSource = ""
                resetTransition()
                return
            }

            if (newSource === displayedSource && !_transitioning && loadingSource === "") {
                pendingSource = ""
                loadingSource = ""
                return
            }

            if (_transitioning) {
                // Coalesce rapid source changes into the current animation.
                return
            }

            loadPending()
        }
        function loadPending() {
            if (_transitioning)
                return
            if (pendingSource === "" || pendingSource === displayedSource) {
                pendingSource = ""
                loadingSource = ""
                return
            }

            const inactive = inactiveImage()
            if (String(inactive.source) === pendingSource && inactive.status === Image.Ready) {
                loadingSource = ""
                performSwitch()
                return
            }

            loadingSource = pendingSource
            inactive.source = pendingSource
        }
        function handleReady(slotIndex, loadedSource) {
            if (loadedSource === "" || loadedSource !== pendingSource)
                return
            if (slotIndex !== (activeIndex === 0 ? 1 : 0) || _transitioning)
                return
            loadingSource = ""
            performSwitch()
        }
        function handleError(slotIndex, failedSource) {
            if (slotIndex !== (activeIndex === 0 ? 1 : 0))
                return
            if (failedSource !== pendingSource && failedSource !== loadingSource)
                return
            loadingSource = ""
            pendingSource = ""
        }
        function performSwitch() {
            if (pendingSource === "" || pendingSource === displayedSource)
                return
            _transitioning = true
            _transitionKind = _normalizedTransitionType(transitionType)
            _transitionWidthSnapshot = Math.max(1, root.width)
            _transitionHeightSnapshot = Math.max(1, root.height)
            _transitionSourceSizeSnapshot = (root.sourceSize.width > 0 && root.sourceSize.height > 0)
                ? Qt.size(Math.max(0, Number(root.sourceSize.width) || 0),
                           Math.max(0, Number(root.sourceSize.height) || 0))
                : Qt.size(Math.max(1, Math.round(root.width * _dpr)),
                           Math.max(1, Math.round(root.height * _dpr)))
            transitionStarted()
            transitionFromIndex = activeIndex
            transitionToIndex = activeIndex === 0 ? 1 : 0
            transitionState.progress = 0
            transitionAnim.restart()
        }
    }

    QtObject {
        id: transitionState
        property real progress: 0
    }

    readonly property bool _canTransition: transitionsEnabled
        && _normalizedTransitionType(transitionType) !== "none" && root._transitionDuration > 0

    function _clamp01(value) {
        return Math.max(0, Math.min(1, value))
    }
    function _lerp(from, to, progress) {
        return from + ((to - from) * progress)
    }
    function _normalizedTransitionType(rawType) {
        switch (String(rawType ?? "crossfade")) {
        case "none":
            return "none"
        case "simple":
        case "fade":
            return "crossfade"
        case "left":
        case "right":
        case "top":
        case "bottom":
            return "slide"
        case "wave":
            return "wipe"
        case "grow":
        case "center":
        case "outer":
        case "any":
            return "zoom"
        case "random":
            return _randomPool[Math.floor(Math.random() * _randomPool.length)]
        default:
            return String(rawType ?? "crossfade")
        }
    }
    function _resolvedTransitionDirection() {
        if (["left", "right", "top", "bottom"].includes(transitionType))
            return transitionType
        return transitionDirection
    }
    function _isVerticalDirection() {
        const direction = _resolvedTransitionDirection()
        return direction === "top" || direction === "bottom"
    }
    function _directionSign() {
        const direction = _resolvedTransitionDirection()
        return direction === "right" || direction === "bottom" ? 1 : -1
    }
    function _progressCurve() {
        switch (_transitionKind) {
        case "slide":
        case "push":
        case "wipe":
            return Appearance.animationCurves.expressiveDefaultSpatial
        case "zoom":
            return Appearance.animationCurves.emphasizedDecel
        case "fadeThrough":
            return Appearance.animationCurves.emphasized
        default:
            return _defaultCurve
        }
    }
    function _transitionWidth() {
        return Math.max(1, _transitioning ? _transitionWidthSnapshot : root.width)
    }
    function _transitionHeight() {
        return Math.max(1, _transitioning ? _transitionHeightSnapshot : root.height)
    }
    function _slotRenderWidth(slotIndex) {
        if (_transitioning && internal.transitionFromIndex === slotIndex)
            return _transitionWidth()
        return root.width
    }
    function _slotRenderHeight(slotIndex) {
        if (_transitioning && internal.transitionFromIndex === slotIndex)
            return _transitionHeight()
        return root.height
    }
    function _slotSourceSize(slotIndex) {
        if (root.sourceSize !== undefined && root.sourceSize.width > 0 && root.sourceSize.height > 0) {
            if (_transitioning && internal.transitionFromIndex === slotIndex)
                return _transitionSourceSizeSnapshot
            return root.sourceSize
        }
        return Qt.size(Math.max(1, Math.round(_slotRenderWidth(slotIndex) * _dpr)),
                       Math.max(1, Math.round(_slotRenderHeight(slotIndex) * _dpr)))
    }
    function _slotVisible(slotIndex) {
        if (_transitioning)
            return internal.transitionFromIndex === slotIndex || internal.transitionToIndex === slotIndex
        return internal.activeIndex === slotIndex && internal.slotImage(slotIndex).source !== ""
    }
    function _slotOpacity(slotIndex) {
        if (!_transitioning)
            return internal.activeIndex === slotIndex ? 1 : 0

        const progress = _clamp01(transitionState.progress)
        const isFrom = internal.transitionFromIndex === slotIndex
        const isTo = internal.transitionToIndex === slotIndex

        switch (_transitionKind) {
        case "slide":
            return (isFrom || isTo) ? 1 : 0
        case "push":
            return isFrom ? _lerp(1, 0.72, progress) : isTo ? _lerp(0.5, 1, progress) : 0
        case "wipe":
            return isFrom ? _lerp(1, 0.86, progress) : isTo ? _lerp(0.74, 1, progress) : 0
        case "zoom":
            return isFrom ? (1 - progress) : isTo ? progress : 0
        case "fadeThrough": {
            const outProgress = _clamp01(progress / 0.45)
            const inProgress = _clamp01((progress - 0.15) / 0.7)
            return isFrom ? (1 - outProgress) : isTo ? inProgress : 0
        }
        default:
            return isFrom ? (1 - progress) : isTo ? progress : 0
        }
    }
    function _slotX(slotIndex) {
        if (!_transitioning)
            return 0

        const progress = _clamp01(transitionState.progress)
        const travel = _transitionWidth()
        const vertical = _isVerticalDirection()
        const direction = _directionSign()
        const isFrom = internal.transitionFromIndex === slotIndex
        const isTo = internal.transitionToIndex === slotIndex

        if (vertical)
            return 0

        switch (_transitionKind) {
        case "slide":
            if (isFrom)
                return -direction * travel * _slideExitDistance * progress
            if (isTo)
                return direction * travel * (1 - progress)
            return 0
        case "push":
            if (isFrom)
                return -direction * travel * _pushExitDistance * progress
            if (isTo)
                return direction * travel * _pushIncomingOffset * (1 - progress)
            return 0
        case "wipe":
            if (isFrom)
                return -direction * travel * _wipeOutgoingParallax * progress
            if (isTo)
                return direction * travel * _wipeIncomingParallax * (1 - progress)
            return 0
        default:
            return 0
        }
    }
    function _slotY(slotIndex) {
        if (!_transitioning)
            return 0

        const progress = _clamp01(transitionState.progress)
        const travel = _transitionHeight()
        const vertical = _isVerticalDirection()
        const direction = _directionSign()
        const isFrom = internal.transitionFromIndex === slotIndex
        const isTo = internal.transitionToIndex === slotIndex

        if (!vertical)
            return 0

        switch (_transitionKind) {
        case "slide":
            if (isFrom)
                return -direction * travel * _slideExitDistance * progress
            if (isTo)
                return direction * travel * (1 - progress)
            return 0
        case "push":
            if (isFrom)
                return -direction * travel * _pushExitDistance * progress
            if (isTo)
                return direction * travel * _pushIncomingOffset * (1 - progress)
            return 0
        case "wipe":
            if (isFrom)
                return -direction * travel * _wipeOutgoingParallax * progress
            if (isTo)
                return direction * travel * _wipeIncomingParallax * (1 - progress)
            return 0
        default:
            return 0
        }
    }
    function _slotZ(slotIndex) {
        if (_transitioning)
            return internal.transitionToIndex === slotIndex ? 2 : internal.transitionFromIndex === slotIndex ? 1 : 0
        return internal.activeIndex === slotIndex ? 1 : 0
    }
    function _slotScale(slotIndex) {
        if (!_transitioning) {
            if (transitionType === "zoom")
                return internal.activeIndex === slotIndex ? 1 : _zoomEnterFrom
            return 1
        }

        const progress = _clamp01(transitionState.progress)
        const isFrom = internal.transitionFromIndex === slotIndex
        const isTo = internal.transitionToIndex === slotIndex

        switch (_transitionKind) {
        case "crossfade":
            if (isFrom)
                return _lerp(1, _crossfadeOutgoingScale, progress)
            if (isTo)
                return _lerp(_crossfadeIncomingScale, 1, progress)
            return 1
        case "slide":
            if (isFrom)
                return _lerp(1, 0.98, progress)
            if (isTo)
                return _lerp(1.012, 1, progress)
            return 1
        case "push":
            if (isFrom)
                return _lerp(1, 0.96, progress)
            if (isTo)
                return _lerp(1.08, 1, progress)
            return 1
        case "wipe":
            if (isFrom)
                return _lerp(1, 0.975, progress)
            if (isTo)
                return _lerp(1.04, 1, progress)
            return 1
        case "zoom":
            if (isFrom)
                return _lerp(1, _zoomExitTo, progress)
            if (isTo)
                return _lerp(_zoomEnterFrom, 1, progress)
            return 1
        case "fadeThrough": {
            const outProgress = _clamp01(progress / 0.45)
            const inProgress = _clamp01((progress - 0.15) / 0.7)
            if (isFrom)
                return _lerp(1, 0.96, outProgress)
            if (isTo)
                return _lerp(0.94, 1, inProgress)
            return 1
        }
        default:
            return 1
        }
    }
    function _slotClipEnabled(slotIndex) {
        return _transitioning && _transitionKind === "wipe" && internal.transitionToIndex === slotIndex
    }
    function _slotWrapperX(slotIndex) {
        if (!_slotClipEnabled(slotIndex) || _isVerticalDirection())
            return 0

        const progress = _clamp01(transitionState.progress)
        const width = _transitionWidth() * progress
        return _resolvedTransitionDirection() === "right" ? _transitionWidth() - width : 0
    }
    function _slotWrapperY(slotIndex) {
        if (!_slotClipEnabled(slotIndex) || !_isVerticalDirection())
            return 0

        const progress = _clamp01(transitionState.progress)
        const height = _transitionHeight() * progress
        return _resolvedTransitionDirection() === "bottom" ? _transitionHeight() - height : 0
    }
    function _slotWrapperWidth(slotIndex) {
        if (!_slotClipEnabled(slotIndex) || _isVerticalDirection())
            return _slotRenderWidth(slotIndex)
        return Math.max(1, _transitionWidth() * _clamp01(transitionState.progress))
    }
    function _slotWrapperHeight(slotIndex) {
        if (!_slotClipEnabled(slotIndex) || !_isVerticalDirection())
            return _slotRenderHeight(slotIndex)
        return Math.max(1, _transitionHeight() * _clamp01(transitionState.progress))
    }

    NumberAnimation {
        id: transitionAnim
        target: transitionState
        property: "progress"
        from: 0
        to: 1
        duration: root._transitionDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root._progressCurve()
        onFinished: root._onTransitionEnd()
    }

    function _onTransitionEnd() {
        transitionAnim.stop()
        if (internal.transitionToIndex >= 0)
            internal.activeIndex = internal.transitionToIndex
        _transitioning = false
        transitionState.progress = 0
        internal.displayedSource = String(internal.activeImage().source)
        internal.loadingSource = ""
        if (internal.pendingSource === internal.displayedSource)
            internal.pendingSource = ""
        internal.transitionFromIndex = -1
        internal.transitionToIndex = -1

        // Release the old texture; only clear when no pending source needs the slot.
        if (internal.pendingSource === "" || internal.pendingSource === internal.displayedSource)
            internal.inactiveImage().source = ""

        transitionFinished()
        if (internal.pendingSource !== "" && internal.pendingSource !== internal.displayedSource)
            internal.loadPending()
    }

    onSourceChanged: internal.switchTo(root.source)

    clip: true

    // ── Slot 0 ──────────────────────────────────────────────────────────
    Item {
        id: slot0
        x: root._slotWrapperX(0)
        y: root._slotWrapperY(0)
        width: root._slotWrapperWidth(0)
        height: root._slotWrapperHeight(0)
        clip: root._slotClipEnabled(0)
        visible: root._slotVisible(0)
        opacity: 1
        z: root._slotZ(0)

        Image {
            id: img0
            x: root._slotX(0)
            y: root._slotY(0)
            width: root._slotRenderWidth(0)
            height: root._slotRenderHeight(0)
            fillMode: root.fillMode
            sourceSize: root._slotSourceSize(0)
            asynchronous: true
            cache: false
            mipmap: false
            smooth: true
            opacity: root._slotOpacity(0)
            scale: root._slotScale(0)
            transformOrigin: Item.Center

            onStatusChanged: {
                if (status === Image.Ready)
                    internal.handleReady(0, String(source))
                else if (status === Image.Error)
                    internal.handleError(0, String(source))
            }
        }
    }

    // ── Slot 1 ──────────────────────────────────────────────────────────
    Item {
        id: slot1
        x: root._slotWrapperX(1)
        y: root._slotWrapperY(1)
        width: root._slotWrapperWidth(1)
        height: root._slotWrapperHeight(1)
        clip: root._slotClipEnabled(1)
        visible: root._slotVisible(1)
        opacity: 1
        z: root._slotZ(1)

        Image {
            id: img1
            x: root._slotX(1)
            y: root._slotY(1)
            width: root._slotRenderWidth(1)
            height: root._slotRenderHeight(1)
            fillMode: root.fillMode
            sourceSize: root._slotSourceSize(1)
            asynchronous: true
            cache: false
            mipmap: false
            smooth: true
            opacity: root._slotOpacity(1)
            scale: root._slotScale(1)
            transformOrigin: Item.Center

            onStatusChanged: {
                if (status === Image.Ready)
                    internal.handleReady(1, String(source))
                else if (status === Image.Error)
                    internal.handleError(1, String(source))
            }
        }
    }

    Component.onCompleted: {
        if (root.source !== "") {
            img0.source = root.source
            internal.displayedSource = root.source
        }
    }
}