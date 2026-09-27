import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.archeclipse.looks
import qs.modules.archeclipse.services

// Weather island: current conditions plus the details the bar cell hides
// (feels like, humidity, wind, pressure, UV, sunrise/sunset).
Item {
    id: root

    signal closeRequested()

    property string monitorName: ""

    width: 300
    height: content.implicitHeight

    readonly property var weatherData: Weather.data

    Column {
        id: content
        anchors.fill: parent
        spacing: ArchTheme.spacing

        Row {
            spacing: ArchTheme.spacing
            width: parent.width

            MaterialSymbol {
                fill: 0
                text: ArchWeather.icon(root.weatherData.wCode)
                iconSize: 26
                color: ArchTheme.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: Math.round(root.weatherData.temp) + "°C"
                    color: ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeLarge
                }
                Text {
                    text: Translation.tr("Feels like %1°").arg(Math.round(root.weatherData.tempFeelsLike))
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeSmall
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: ArchTheme.border
        }

        Grid {
            columns: 2
            columnSpacing: ArchTheme.spacing * 2
            rowSpacing: ArchTheme.spacing / 2
            width: parent.width

            component Detail: Column {
                property string label: ""
                property string value: ""
                spacing: 1
                width: (root.width - ArchTheme.spacing * 2) / 2
                Text {
                    text: parent.label
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeCaption
                }
                Text {
                    text: parent.value
                    color: ArchTheme.fg
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSize
                }
            }

            Detail {
                label: Translation.tr("Humidity")
                value: Math.round(root.weatherData.humidity) + "%"
            }
            Detail {
                label: Translation.tr("Wind")
                value: Math.round(root.weatherData.wind) + " km/h"
            }
            Detail {
                label: Translation.tr("Pressure")
                value: Math.round(root.weatherData.press) + " hPa"
            }
            Detail {
                label: Translation.tr("UV index")
                value: Math.round(root.weatherData.uv).toString()
            }
            Detail {
                label: Translation.tr("Precipitation")
                value: Math.round(root.weatherData.precip) + " mm"
            }
            Detail {
                label: Translation.tr("Visibility")
                value: Math.round(root.weatherData.visib) + " km"
            }
        }
    }
}
