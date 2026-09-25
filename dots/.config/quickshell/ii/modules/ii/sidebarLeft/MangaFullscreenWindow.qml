import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell

Window {
    id: root
    property var seedManga: null
    property var seedChapter: null

    title: Translation.tr("Manga reader")
    color: Appearance.colors.colLayer0
    width: 920
    height: 1280
    minimumWidth: 420
    minimumHeight: 560

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: "transparent"
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
            }
        }

        MangaView {
            anchors.fill: parent
            anchors.margins: 10
            standalone: true
            openMangaOnLoad: root.seedManga
            openChapterOnLoad: root.seedChapter
        }
    }

    RippleButtonWithIcon {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.top: parent.top
        anchors.topMargin: 18
        implicitWidth: 42
        implicitHeight: 42
        buttonRadius: 21
        materialIcon: "close"
        mainText: ""
        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.2)
        colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
        onClicked: root.close()
    }
}