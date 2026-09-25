import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string panelImagePath: Directories.sidePanelAnime
    property bool hasImage: false

    FileView {
        id: panelFileView
        path: root.panelImagePath
        watchChanges: true
        onLoaded: root.refresh()
        onFileChanged: root.refresh()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.hasImage = false;
            } else {
                console.log("[AnimePanel] Error loading image: " + error);
            }
        }
    }

    function refresh() {
        root.hasImage = true;
        panelImage.source = `${Qt.resolvedUrl(root.panelImagePath)}?m=${Date.now()}`;
        panelFileView.reload();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Item {
            id: imageHost
            Layout.fillWidth: true
            Layout.fillHeight: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: imageHost.width
                    height: imageHost.height
                    radius: Appearance.rounding.normal
                }
            }

            Rectangle {
                id: panelBackground
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                visible: !root.hasImage
            }

            StyledImage {
                id: panelImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: root.hasImage
                source: root.hasImage ? Qt.resolvedUrl(root.panelImagePath) : ""
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.hasImage
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            text: Translation.tr("No anime image yet. Pick one in the left Anime tab → its ⋮ menu → “Set as side panel image”.")
        }

        RippleButton {
            Layout.alignment: Qt.AlignHCenter
            visible: root.hasImage
            implicitHeight: 30
            implicitWidth: 130
            onClicked: root.refresh()
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive

            contentItem: StyledText {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("Refresh")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
    }
}