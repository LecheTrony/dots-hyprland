import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Button {
    id: root
    property var imageData
    property var rowHeight
    property bool manualDownload: false
    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath
    property string fileName: decodeURIComponent((imageData.file_url).substring((imageData.file_url).lastIndexOf('/') + 1))
    property string filePath: `${root.previewDownloadPath}/${root.fileName}`
    property int maxTagStringLineLength: 50
    property real imageRadius: Appearance.rounding.small

    property bool showActions: false

    function hideMenu() {
        root.showActions = false;
        Booru.releaseContextMenu(root);
    }

    function repositionMenu() {
        const overlay = contextMenuPopup.parent;
        if (!overlay || !root.showActions) return;
        const menuWidth = contextMenuPopup.implicitWidth;
        const menuHeight = contextMenuPopup.implicitHeight;
        const anchor = menuButton.mapToItem(overlay, menuButton.width, menuButton.height + 8);
        let x = anchor.x - menuWidth;
        x = Math.max(8, Math.min(x, overlay.width - menuWidth - 8));
        let y = anchor.y;
        y = Math.max(8, Math.min(y, overlay.height - menuHeight - 8));
        contextMenuPopup.x = x;
        contextMenuPopup.y = y;
    }

    Component.onDestruction: {
        if (Booru.openContextMenu === root) Booru.openContextMenu = null;
    }

    ImageDownloaderProcess {
        id: imageDownloader
        running: root.manualDownload
        filePath: root.filePath
        sourceUrl: root.imageData.preview_url ?? root.imageData.sample_url
        onDone: (path, width, height) => {
            imageObject.source = ""
            imageObject.source = path
            if (!modelData.width || !modelData.height) {
                modelData.width = width
                modelData.height = height
                modelData.aspect_ratio = width / height
            }
        }
    }

    StyledToolTip {
        text: `${StringUtils.wordWrap(root.imageData.tags, root.maxTagStringLineLength)}`
    }

    padding: 0
    implicitWidth: root.rowHeight * modelData.aspect_ratio
    implicitHeight: root.rowHeight

    background: Rectangle {
        implicitWidth: root.rowHeight * modelData.aspect_ratio
        implicitHeight: root.rowHeight
        radius: imageRadius
        color: Appearance.colors.colLayer2
    }

    contentItem: Item {
        anchors.fill: parent

        StyledImage {
            id: imageObject
            anchors.fill: parent
            width: root.rowHeight * modelData.aspect_ratio
            height: root.rowHeight
            fillMode: Image.PreserveAspectFit
            source: modelData.preview_url

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: root.rowHeight * modelData.aspect_ratio
                    height: root.rowHeight
                    radius: imageRadius
                }
            }
        }

        RippleButton {
            id: menuButton
            anchors.top: parent.top
            anchors.right: parent.right
            property real buttonSize: 30
            anchors.margins: Math.max(root.imageRadius - buttonSize / 2, 8)
            implicitHeight: buttonSize
            implicitWidth: buttonSize

            buttonRadius: Appearance.rounding.full
            colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.3)
            colBackgroundHover: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.8), 0.2)
            colRipple: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.6), 0.1)

            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3onSurface
                text: "more_vert"
            }

            onClicked: {
                if (root.showActions) {
                    root.hideMenu()
                } else {
                    root.showActions = true
                    Booru.requestContextMenu(root)
                    root.repositionMenu()
                    Qt.callLater(root.repositionMenu)
                }
            }
        }

        Popup {
            id: contextMenuPopup
            modal: true
            dim: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            padding: 0
            visible: root.showActions
            implicitWidth: contextMenuColumnLayout.implicitWidth
            implicitHeight: contextMenuColumnLayout.implicitHeight + Appearance.rounding.small * 2

            onClosed: root.hideMenu()

            background: Rectangle {
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainer
            }

            ColumnLayout {
                id: contextMenuColumnLayout
                anchors.fill: parent
                anchors.margins: Appearance.rounding.small
                spacing: 0

                        MenuButton {
                            id: openFileLinkButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Open file link")
                            onClicked: {
                                root.hideMenu()
                                Hyprland.dispatch("hl.config({cursor = {no_warps = true}})")
                                Qt.openUrlExternally(root.imageData.file_url)
                                Hyprland.dispatch("hl.config({cursor = {no_warps = false}})")
                            }
                        }
                        MenuButton {
                            id: sourceButton
                            visible: root.imageData.source && root.imageData.source.length > 0
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Go to source (%1)").arg(StringUtils.getDomain(root.imageData.source))
                            enabled: root.imageData.source && root.imageData.source.length > 0
                            onClicked: {
                                root.hideMenu()
                                Hyprland.dispatch("hl.config({cursor = {no_warps = true}})")
                                Qt.openUrlExternally(root.imageData.source)
                                Hyprland.dispatch("hl.config({cursor = {no_warps = false}})")
                            }
                        }
                        MenuButton {
                            id: downloadButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Download")
                            onClicked: {
                                root.hideMenu();
                                const targetPath = root.imageData.is_nsfw ? root.nsfwPath : root.downloadPath;
                                const userAgent = Config.options?.networking?.userAgent ?? ""
                                const userAgentHeader = userAgent ? ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(userAgent)}'` : ""
                                Quickshell.execDetached(["bash", "-c", 
                                    `mkdir -p '${targetPath}' && curl '${StringUtils.shellSingleQuoteEscape(root.imageData.file_url)}'${userAgentHeader} -o '${targetPath}/${root.fileName}' && notify-send '${Translation.tr("Download complete")}' '${root.downloadPath}/${root.fileName}' -a 'Shell'`
                                ])
                            }
                        }
                        MenuButton {
                            id: fastfetchButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Put in fastfetch")
                            onClicked: {
                                root.hideMenu();
                                const sourcePath = `${root.downloadPath}/fastfetch-logo-src`;
                                const logoPath = `${root.downloadPath}/fastfetch-logo.png`;
                                const userAgent = Config.options?.networking?.userAgent ?? ""
                                const userAgentHeader = userAgent ? ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(userAgent)}'` : ""
                                Quickshell.execDetached(["bash", "-c", 
                                    `mkdir -p '${root.downloadPath}' && curl '${StringUtils.shellSingleQuoteEscape(root.imageData.file_url)}'${userAgentHeader} -o '${sourcePath}' && magick '${sourcePath}' -strip -resize '512x512>' -background none -gravity center -extent 512x512 '${logoPath}' && rm -f '${sourcePath}' && rm -rf ~/.cache/fastfetch/images && notify-send '${Translation.tr("fastfetch logo set")}' '${logoPath}' -a 'Shell' && (kitty -1 &)`
                                ])
                            }
                        }
                        MenuButton {
                            id: sidePanelButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Set as side panel image")
                            onClicked: {
                                root.hideMenu();
                                const sourcePath = `${root.downloadPath}/sidepanel-anime-src`;
                                const panelPath = `${root.downloadPath}/sidepanel-anime.png`;
                                const userAgent = Config.options?.networking?.userAgent ?? ""
                                const userAgentHeader = userAgent ? ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(userAgent)}'` : ""
                                Quickshell.execDetached(["bash", "-c", 
                                    `mkdir -p '${root.downloadPath}' && curl '${StringUtils.shellSingleQuoteEscape(root.imageData.file_url)}'${userAgentHeader} -o '${sourcePath}' && magick '${sourcePath}' -strip -resize '1024x1024>' '${panelPath}' && rm -f '${sourcePath}' && notify-send '${Translation.tr("Side panel anime set")}' '${panelPath}' -a 'Shell'`
                                ])
                            }
                        }
                    }
                }

        }
}
