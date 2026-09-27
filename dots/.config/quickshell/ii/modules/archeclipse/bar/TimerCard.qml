import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Focus / timer card on the ii TimerService: pomodoro (with cycle progress)
// and a stopwatch, using the service's own toggle/reset functions and its
// 10ms stopwatch units.
Item {
    id: root

    readonly property bool onBreak: TimerService.pomodoroBreak
    readonly property int secondsLeft: TimerService.pomodoroSecondsLeft
    readonly property real progress: TimerService.pomodoroLapDuration > 0 ? 1 - (TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration) : 0
    readonly property real stopwatchSeconds: TimerService.stopwatchTime / 10

    function clockText(total) {
        const s = Math.max(0, Math.floor(total));
        const m = Math.floor(s / 60);
        return (m < 10 ? "0" : "") + m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    // Repaint trigger for the stopwatch readout (service ticks in 10ms units).
    Timer {
        interval: 250
        running: TimerService.stopwatchRunning || TimerService.pomodoroRunning
        repeat: true
        onTriggered: root.clockText(0)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                text: TimerService.pomodoroRunning ? "timer" : "timer_off"
                iconSize: ArchTheme.fontSize
                color: TimerService.pomodoroRunning ? (root.onBreak ? ArchTheme.ramColor : ArchTheme.accent) : ArchTheme.muted
            }
            Text {
                Layout.fillWidth: true
                text: TimerService.pomodoroRunning ? (root.onBreak ? Translation.tr("Break") : Translation.tr("Focus")) : Translation.tr("Timer")
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
            Text {
                text: TimerService.pomodoroRunning ? root.clockText(root.secondsLeft) : root.clockText(root.stopwatchSeconds)
                color: ArchTheme.accent
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize
            }
        }

        // progress bar while a pomodoro lap is running
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            radius: 1.5
            color: ArchTheme.border
            visible: TimerService.pomodoroRunning

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                height: parent.height
                radius: 1.5
                color: root.onBreak ? ArchTheme.ramColor : ArchTheme.accent

                Behavior on width {
                    NumberAnimation {
                        duration: 400
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: Translation.tr("Cycle") + " " + (TimerService.pomodoroCycle + 1) + "/" + TimerService.cyclesBeforeLongBreak
                color: ArchTheme.muted
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSizeBadge
            }

            IconActionButton {
                icon: TimerService.pomodoroRunning ? "pause" : "play_arrow"
                tooltip: TimerService.pomodoroRunning ? Translation.tr("Pause") : Translation.tr("Start")
                active: TimerService.pomodoroRunning
                onClicked: TimerService.togglePomodoro()
            }
            IconActionButton {
                icon: "restart_alt"
                tooltip: Translation.tr("Reset")
                onClicked: TimerService.resetPomodoro()
            }
            IconActionButton {
                icon: TimerService.stopwatchRunning ? "stop" : "timer"
                tooltip: TimerService.stopwatchRunning ? Translation.tr("Stop stopwatch") : Translation.tr("Start stopwatch")
                active: TimerService.stopwatchRunning
                onClicked: TimerService.toggleStopwatch()
            }
            IconActionButton {
                icon: "clear_all"
                tooltip: Translation.tr("Reset stopwatch")
                actionEnabled: !TimerService.stopwatchRunning
                onClicked: TimerService.stopwatchReset()
            }
        }
    }
}
