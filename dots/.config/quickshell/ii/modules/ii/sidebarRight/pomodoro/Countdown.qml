import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    function _format(seconds) {
        let minutes = Math.floor(seconds / 60).toString().padStart(2, '0');
        let secs = Math.floor(seconds % 60).toString().padStart(2, '0');
        return `${minutes}:${secs}`;
    }

    function _atFull() {
        return TimerService.countdownSecondsLeft >= TimerService.countdownDuration;
    }

    function _curM() {
        return Math.min(99, Math.floor(TimerService.countdownDuration / 60));
    }

    function _curS() {
        return TimerService.countdownDuration % 60;
    }

    function _set(m, s) {
        m = Math.max(0, Math.min(99, Math.round(m)));
        s = Math.max(0, Math.min(59, Math.round(s)));
        const total = m * 60 + s;
        TimerService.setCountdownDuration(Math.max(total, 1));
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 10

        CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            lineWidth: 8
            value: TimerService.countdownDuration > 0 ? TimerService.countdownSecondsLeft / TimerService.countdownDuration : 0
            implicitSize: 170
            enableAnimation: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root._format(TimerService.countdownSecondsLeft)
                    font.pixelSize: 40
                    color: Appearance.m3colors.m3onSurface
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: TimerService.countdownRunning
                          ? Translation.tr("Running")
                          : TimerService.countdownSecondsLeft === 0
                              ? Translation.tr("Done!")
                              : root._atFull() ? Translation.tr("Countdown") : Translation.tr("Paused")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Presets
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            property var presets: [1, 5, 10, 25, 60]

            Repeater {
                model: parent.presets
                delegate: RippleButton {
                    required property int index
                    required property int modelData
                    implicitHeight: 26
                    implicitWidth: 40
                    font.pixelSize: Appearance.font.pixelSize.small
                    enabled: root._atFull() || TimerService.countdownSecondsLeft === 0
                    onClicked: TimerService.setCountdownDuration(modelData * 60)
                    colBackground: TimerService.countdownDuration === modelData * 60 ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("%1m").arg(modelData)
                        color: TimerService.countdownDuration === modelData * 60 ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                    }
                }
            }
        }

        // Custom minutes / seconds
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            enabled: root._atFull() || TimerService.countdownSecondsLeft === 0

            RowLayout {
                spacing: 4
                StyledText {
                    text: Translation.tr("Min")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                StepperButton { value: root._curM(); onDecrease: root._set(root._curM() - 1, root._curS()); onIncrease: root._set(root._curM() + 1, root._curS()) }
            }

            RowLayout {
                spacing: 4
                StyledText {
                    text: Translation.tr("Sec")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                StepperButton { value: root._curS(); onDecrease: root._set(root._curM(), root._curS() - 1); onIncrease: root._set(root._curM(), root._curS() + 1) }
            }
        }

        // Start/Stop and Reset buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            RippleButton {
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.countdownRunning ? Translation.tr("Pause") : TimerService.countdownSecondsLeft === 0 ? Translation.tr("Start") : Translation.tr("Resume")
                    color: TimerService.countdownRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                }
                implicitHeight: 35
                implicitWidth: 90
                font.pixelSize: Appearance.font.pixelSize.larger
                onClicked: TimerService.toggleCountdown()
                colBackground: TimerService.countdownRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colSecondaryContainer
                colRipple: Appearance.colors.colSecondaryContainerActive
            }

            RippleButton {
                implicitHeight: 35
                implicitWidth: 90

                onClicked: TimerService.countdownReset()
                enabled: !root._atFull() || TimerService.countdownRunning

                font.pixelSize: Appearance.font.pixelSize.larger
                colBackground: Appearance.colors.colErrorContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive

                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Reset")
                    color: Appearance.colors.colOnErrorContainer
                }
            }
        }
    }

    component StepperButton: Item {
        id: stepper
        property int value: 0
        signal decrease()
        signal increase()
        implicitWidth: stepperRow.implicitWidth
        implicitHeight: 26

        RowLayout {
            id: stepperRow
            anchors.fill: parent
            spacing: 2

            RippleButton {
                implicitHeight: 26
                implicitWidth: 26
                onClicked: stepper.decrease()
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover

                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: "-"
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer2
                }
            }

            StyledText {
                text: stepper.value
                font.pixelSize: Appearance.font.pixelSize.small
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 30
                color: Appearance.colors.colOnLayer2
            }

            RippleButton {
                implicitHeight: 26
                implicitWidth: 26
                onClicked: stepper.increase()
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover

                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }
}