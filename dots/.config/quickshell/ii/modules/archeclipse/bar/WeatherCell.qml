import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

// Weather cell: condition glyph + temperature + description on a
// weather-code-coloured background (upstream WeatherButton). Click pulses
// the weather island, right-click refreshes the forecast.
Rectangle {
    id: root

    signal stateRequested(string state)

    readonly property var cur: Weather.data ?? ({})
    // The ii service seeds `city` with 0 before the first fetch.
    readonly property bool hasData: {
        const c = Weather.data?.city;
        return c !== undefined && c !== null && c !== 0 && c !== "";
    }

    // implicitWidth (not width) so the cell keeps its natural size in the
    // RowLayout but still stretches into the slack on the left zone.
    implicitWidth: content.implicitWidth + 14
    height: ArchTheme.barContentHeight
    radius: ArchTheme.radius
    readonly property string weatherBg: root.hasData ? ArchWeather.background(root.cur.wCode) : "transparent"
    color: hover.hovered ? (root.hasData ? root.weatherBg : ArchTheme.surfaceHover) : (root.hasData ? root.weatherBg : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            id: iconText
            visible: root.hasData
            fill: 0
            text: ArchWeather.icon(root.cur.wCode)
            iconSize: ArchTheme.fontSize + 1
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.hasData
            text: {
                if (!root.hasData)
                    return "";
                const t = Math.round(root.cur.temp ?? 0);
                const desc = ArchWeather.description(root.cur.wCode);
                return `${t}° ${desc}`;
            }
            elide: Text.ElideRight
            width: {
                // root.width is 0 before the layout resolves: fall back to
                // the natural size so the cell never collapses to nothing.
                const avail = root.width - 14 - content.spacing - (iconText.visible ? iconText.width : 0);
                if (root.width <= 0 || avail < 0)
                    return implicitWidth;
                return Math.min(implicitWidth, avail);
            }
            color: ArchTheme.fg
            font.family: ArchTheme.fontFamily
            font.pixelSize: ArchTheme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer {
        id: dwellTimer
        interval: ArchTheme.revealInPressure
        repeat: false
        onTriggered: root.stateRequested("weather")
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hover.hovered) {
                if (ArchTheme.revealInPressure <= 0)
                    root.stateRequested("weather");
                else
                    dwellTimer.restart();
            } else {
                dwellTimer.stop();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Weather.getData();
                Quickshell.execDetached(["notify-send", "Weather", Translation.tr("Refreshing (manually triggered)"), "-a", "Shell"]);
                return;
            }
            root.stateRequested("weather");
        }
    }
}
