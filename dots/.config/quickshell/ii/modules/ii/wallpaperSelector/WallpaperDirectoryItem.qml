import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

MouseArea {
    id: root
    required property var fileModelData
    property bool isDirectory: fileModelData.fileIsDir
    property bool useThumbnail: Images.isValidImageByName(fileModelData.fileName)
    property bool isVideo: Wallpapers.isVideoFile(fileModelData.fileName)
    property string videoThumbPath: root.isVideo ? `${Directories.mpvpaperThumbnails}/${fileModelData.fileName}.jpg` : ""
    property bool videoThumbAvailable: false
    property int reloadSeq: 0

    FileView {
        path: root.videoThumbPath
        watchChanges: root.isVideo
        onLoaded: root.videoThumbAvailable = true
        onFileChanged: {
            root.reloadSeq += 1;
            root.videoThumbAvailable = true;
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.videoThumbAvailable = false;
        }
    }

    property alias colBackground: background.color
    property alias colText: wallpaperItemName.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    property alias padding: wallpaperItemColumnLayout.anchors.margins
    margins: Appearance.sizes.wallpaperSelectorItemMargins
    padding: Appearance.sizes.wallpaperSelectorItemPadding

    signal activated()

    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: wallpaperItemColumnLayout
            anchors.fill: parent
            spacing: 4

            Item {
                id: wallpaperItemImageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Loader {
                    id: thumbnailShadowLoader
                    active: thumbnailImageLoader.active && thumbnailImageLoader.item.status === Image.Ready
                    anchors.fill: thumbnailImageLoader
                    sourceComponent: StyledRectangularShadow {
                        target: thumbnailImageLoader
                        anchors.fill: undefined
                        radius: Appearance.rounding.small
                    }
                }

                Loader {
                    id: thumbnailImageLoader
                    anchors.fill: parent
                    active: root.useThumbnail
                    sourceComponent: ThumbnailImage {
                        id: thumbnailImage
                        generateThumbnail: false
                        sourcePath: fileModelData.filePath

                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        clip: true

                        Connections {
                            target: Wallpapers
                            function onThumbnailGenerated(directory) {
                                if (thumbnailImage.status !== Image.Error) return;
                                if (FileUtils.parentDirectory(thumbnailImage.sourcePath) !== FileUtils.trimFileProtocol(directory)) return;
                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }
                            function onThumbnailGeneratedFile(filePath) {
                                if (thumbnailImage.status !== Image.Error) return;
                                if (Qt.resolvedUrl(thumbnailImage.sourcePath) !== Qt.resolvedUrl(filePath)) return;
                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: wallpaperItemImageContainer.width
                                height: wallpaperItemImageContainer.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }
                }

                Loader {
                    id: videoImageLoader
                    anchors.fill: parent
                    active: root.isVideo && root.videoThumbAvailable
                    sourceComponent: StyledImage {
                        asynchronous: true
                        source: `${root.videoThumbPath}?r=${root.reloadSeq}`
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            enabled: Appearance.animation.elementMoveFast.duration > 0
                            NumberAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: wallpaperItemImageContainer.width
                                height: wallpaperItemImageContainer.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }
                }

                Loader {
                    id: iconLoader
                    active: !root.useThumbnail && !(root.isVideo && root.videoThumbAvailable)
                    anchors.fill: parent
                    sourceComponent: DirectoryIcon {
                        fileModelData: root.fileModelData
                    }
                }

                Rectangle {
                    visible: root.isVideo
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 24
                    height: 20
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.55)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 14
                        text: "movie"
                        color: "white"
                    }
                }
            }

            StyledText {
                id: wallpaperItemName
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: fileModelData.fileName
            }
        }
    }
}
