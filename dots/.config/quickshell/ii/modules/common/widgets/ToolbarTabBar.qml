pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property alias currentIndex: tabBar.currentIndex
    required property var tabButtonList

    function incrementCurrentIndex() {
        tabBar.incrementCurrentIndex();
    }
    function decrementCurrentIndex() {
        tabBar.decrementCurrentIndex();
    }
    function setCurrentIndex(index) {
        tabBar.setCurrentIndex(index);
    }

    function recenterContent() {
        if (contentWrapper.width > contentFlick.width) {
            contentFlick.contentX = Math.max(0, (contentWrapper.width - contentFlick.width) / 2);
        } else {
            contentFlick.contentX = 0;
        }
    }

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.fillWidth: true
    implicitWidth: contentItem.implicitWidth
    implicitHeight: 40

    property Component delegate: ToolbarTabButton {
        required property int index
        required property var modelData
        current: index == root.currentIndex
        text: modelData.name
        materialSymbol: modelData.icon
        onClicked: {
            root.setCurrentIndex(index);
        }
    }

    Component.onCompleted: Qt.callLater(root.recenterContent)

    // Scrollable, clampable tab strip. When the tabs fit, they center;
    // when they overflow the widget, they can be dragged horizontally.
    Flickable {
        id: contentFlick
        z: 1
        anchors.fill: parent
        contentWidth: contentWrapper.width
        contentHeight: contentWrapper.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        onWidthChanged: Qt.callLater(root.recenterContent)

        Item {
            id: contentWrapper
            width: Math.max(Math.max(contentItem.implicitWidth, activeIndicator.implicitWidth), contentFlick.width)
            height: root.implicitHeight

            Row {
                id: contentItem
                anchors.horizontalCenter: parent.horizontalCenter
                y: (parent.height - implicitHeight) / 2
                spacing: 4

                onImplicitWidthChanged: Qt.callLater(root.recenterContent)

                Repeater {
                    model: root.tabButtonList
                    delegate: root.delegate
                }
            }

            Rectangle {
                id: activeIndicator
                z: 0
                color: Appearance.colors.colSecondaryContainer
                implicitWidth: contentItem.children[root.currentIndex]?.implicitWidth ?? 0
                implicitHeight: contentItem.children[root.currentIndex]?.implicitHeight ?? 0
                y: (contentWrapper.height - (contentItem.children[root.currentIndex]?.implicitHeight ?? 0)) / 2
                radius: height / 2
                // Animation
                property var targetItem: contentItem.children[root.currentIndex] ?? null
                AnimatedTabIndexPair {
                    id: leftBound
                    idx1Duration: 50
                    idx2Duration: 200
                    index: (activeIndicator.targetItem?.x ?? 0) + contentItem.x
                }
                AnimatedTabIndexPair {
                    id: rightBound
                    idx1Duration: 50
                    idx2Duration: 200
                    index: (activeIndicator.targetItem?.x ?? 0) + (activeIndicator.targetItem?.width ?? 0) + contentItem.x
                }
                x: Math.min(leftBound.idx1, leftBound.idx2)
                width: Math.max(rightBound.idx1, rightBound.idx2) - x
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onWheel: event => {
            if (event.angleDelta.y < 0) {
                root.incrementCurrentIndex();
            } else {
                root.decrementCurrentIndex();
            }
        }
    }

    // TabBar doesn't allow tabs to be of different sizes. That's what I thought...
    // We use it only for the logic and draw stuff manually
    TabBar {
        id: tabBar
        z: -1
        background: null
        Repeater {
            // This is to fool the TabBar that it has tabs so it does the indices properly
            model: root.tabButtonList.length
            delegate: TabButton {
                background: null
            }
        }
    }
}