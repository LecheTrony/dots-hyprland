pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Windows 11 style settings chrome: searchable nav rail on the left, page
// title header plus page host on the right. Adapted from the iNiR reference
// (WSettingsContent.qml) - the reference's 1000-line hardcoded search index is
// not ported, the page host simply loads the real config pages instead.
Item {
    id: root

    property var pages: []
    property int currentPage: 0

    signal closeRequested()
    // The rail collapses on its own in narrow windows so the page host always
    // keeps enough room for the option pages.
    property bool _navExpanded: true
    readonly property bool navExpanded: root._navExpanded && root.width >= Looks.dp(880)
    property string searchText: ""

    readonly property int railWidth: root.navExpanded ? Looks.dp(212) : Looks.dp(58)

    readonly property var filteredPages: {
        const query = root.searchText.trim().toLowerCase();
        if (query === "")
            return root.pages;
        return root.pages.filter((page) => (page.name || "").toLowerCase().includes(query)
            || (page.keywords || []).some((keyword) => keyword.toLowerCase().includes(query)));
    }

    function selectPage(index) {
        if (index < 0 || index >= root.filteredPages.length)
            return;
        const target = root.filteredPages[index];
        const realIndex = root.pages.indexOf(target);
        if (realIndex >= 0 && realIndex !== root.currentPage)
            root.currentPage = realIndex;
    }

    function movePage(delta) {
        const list = root.filteredPages;
        if (list.length === 0)
            return;
        let index = list.indexOf(root.pages[root.currentPage]);
        if (index < 0)
            index = 0;
        index = Math.min(list.length - 1, Math.max(0, index + delta));
        selectPage(index);
    }

    function currentPageData() {
        return root.pages[root.currentPage] || {};
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
        else if (event.key === Qt.Key_PageDown) {
            root.movePage(1);
            event.accepted = true;
        }
        else if (event.key === Qt.Key_PageUp) {
            root.movePage(-1);
            event.accepted = true;
        }
        else if (event.modifiers === Qt.ControlModifier
            && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            root.movePage(event.key === Qt.Key_Tab ? 1 : -1);
            event.accepted = true;
        }
    }

    Rectangle { // Window fill
        anchors.fill: parent
        color: Looks.colors.bg0
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Navigation rail. The width is pinned with min/preferred/max: a
        // layout-attached property must never be animated, otherwise the row
        // layout hands the leftover space to the rail and squeezes the pages
        // down to a few pixels.
        ColumnLayout {
            Layout.minimumWidth: root.railWidth
            Layout.preferredWidth: root.railWidth
            Layout.maximumWidth: root.railWidth
            Layout.fillHeight: true
            Layout.margins: Looks.dp(10)
            spacing: Looks.dp(4)

            // Expand button (only while collapsed)
            Rectangle {
                visible: !root.navExpanded
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Looks.dp(36)
                implicitHeight: Looks.dp(36)
                Layout.bottomMargin: Looks.dp(4)
                radius: Looks.settings.radiusLarge
                color: expandMa.containsMouse ? Looks.colors.bg1Hover : Looks.settings.tile
                border.width: 1
                border.color: Looks.settings.stroke

                MouseArea {
                    id: expandMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._navExpanded = true
                }

                FluentIcon {
                    anchors.centerIn: parent
                    icon: "chevron-right"
                    implicitSize: Looks.dp(14)
                    color: Looks.colors.subfg
                }
            }

            // Search + collapse
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Looks.dp(8)
                spacing: Looks.dp(4)
                visible: root.navExpanded

                WTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search settings")
                    text: root.searchText
                    implicitHeight: Looks.dp(36)
                    onTextChanged: root.searchText = text
                }

                Rectangle {
                    implicitWidth: Looks.dp(36)
                    implicitHeight: Looks.dp(36)
                    radius: Looks.settings.radiusLarge
                    color: collapseMa.containsMouse ? Looks.colors.bg1Hover : Looks.settings.tile
                    border.width: 1
                    border.color: Looks.settings.stroke

                    MouseArea {
                        id: collapseMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._navExpanded = false
                    }

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: "chevron-left"
                        implicitSize: Looks.dp(14)
                        color: Looks.colors.subfg
                    }
                }
            }

            Flickable {
                id: navScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Looks.dp(120)
                contentWidth: width
                contentHeight: navList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: navList
                    width: navScroll.width
                    spacing: Looks.dp(2)

                    Repeater {
                        model: root.filteredPages

                        WSettingsNavItem {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            text: modelData.name
                            navIcon: modelData.icon
                            selected: root.pages[root.currentPage] === modelData
                            expanded: root.navExpanded
                            onClicked: root.selectPage(index)
                        }
                    }
                }
            }

            // Config file shortcut, same trick as the ii window
            Rectangle {
                visible: root.navExpanded
                Layout.fillWidth: true
                Layout.preferredHeight: Looks.dp(34)
                radius: Looks.settings.radiusLarge
                color: fileMa.containsMouse ? Looks.colors.bg1Hover : "transparent"
                border.width: 1
                border.color: Looks.settings.stroke

                MouseArea {
                    id: fileMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Looks.dp(10)
                    anchors.rightMargin: Looks.dp(10)
                    spacing: Looks.dp(8)

                    FluentIcon {
                        icon: "open"
                        implicitSize: Looks.dp(12)
                        color: Looks.colors.subfg
                    }

                    WText {
                        Layout.fillWidth: true
                        text: Translation.tr("Config file")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.subfg
                    }
                }
            }
        }

        // Page host
        Rectangle {
            Layout.minimumWidth: Looks.dp(420)
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Looks.dp(10)
            Layout.rightMargin: Looks.dp(10)
            Layout.bottomMargin: Looks.dp(10)
            radius: Looks.settings.radiusXLarge
            color: Looks.colors.bg1
            border.width: 1
            border.color: Looks.settings.stroke
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Page header
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: Looks.dp(20)
                    Layout.bottomMargin: Looks.dp(12)
                    spacing: Looks.dp(4)

                    WText {
                        Layout.fillWidth: true
                        text: root.currentPageData().name || ""
                        font.pixelSize: Looks.font.pixelSize.xlarger
                        font.weight: Looks.font.weight.strongest
                        color: Looks.colors.fg
                        elide: Text.ElideRight
                    }

                    WText {
                        visible: (root.currentPageData().description || "") !== ""
                        Layout.fillWidth: true
                        text: root.currentPageData().description || ""
                        font.pixelSize: Looks.font.pixelSize.normal
                        color: Looks.colors.subfg
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Looks.dp(20)
                    Layout.rightMargin: Looks.dp(20)
                    implicitHeight: 1
                    color: Looks.settings.stroke
                }

                Loader {
                    id: pageLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: Config.ready
                    source: root.currentPageData().component || ""
                    opacity: 1

                    onLoaded: if (item && item.forceWidth !== undefined) item.forceWidth = true

                    SequentialAnimation {
                        id: switchAnim
                        PauseAnimation { duration: 1 }
                        PropertyAction { target: pageLoader; property: "opacity"; value: 0.2 }
                        NumberAnimation { target: pageLoader; property: "opacity"; to: 1.0; duration: 130; easing.type: Easing.OutCubic }
                    }

                    onSourceChanged: switchAnim.restart()
                }
            }
        }
    }
}
