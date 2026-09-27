import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.archeclipse.looks

// Calendar card: live month grid (Monday-first), month/year navigation,
// today shortcut and a selected-date label (upstream CalendarWidget).
Item {
    id: root

    property bool weekStartsMonday: true
    property date todayDate: new Date()
    property date viewDate: new Date(todayDate.getFullYear(), todayDate.getMonth(), 1)
    property date selectedDate: new Date(todayDate.getFullYear(), todayDate.getMonth(), todayDate.getDate())
    property var cells: []

    readonly property real navSize: 22

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.todayDate = new Date()
    }

    readonly property var weekdayNames: {
        root.weekStartsMonday;
        const out = [];
        for (let i = 0; i < 7; i++) {
            const qtDay = root.weekStartsMonday ? i + 1 : (i === 0 ? 7 : i);
            let s = "";
            try {
                s = Qt.locale().dayName(qtDay, Locale.ShortFormat);
            } catch (e) {}
            out.push((s || "?").slice(0, 2));
        }
        return out;
    }

    readonly property bool showingCurrentMonth: viewDate.getFullYear() === todayDate.getFullYear() && viewDate.getMonth() === todayDate.getMonth()
    readonly property string monthTitle: Qt.locale().monthName(viewDate.getMonth(), Locale.LongFormat) + " " + viewDate.getFullYear()

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function isToday(y, m, d) {
        const t = root.todayDate;
        return y === t.getFullYear() && m === t.getMonth() && d === t.getDate();
    }

    function isSelected(y, m, d) {
        const s = root.selectedDate;
        return y === s.getFullYear() && m === s.getMonth() && d === s.getDate();
    }

    function moveMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
    }

    function moveYear(delta) {
        viewDate = new Date(viewDate.getFullYear() + delta, viewDate.getMonth(), 1);
    }

    function goToday() {
        const t = new Date();
        root.todayDate = t;
        root.selectedDate = new Date(t.getFullYear(), t.getMonth(), t.getDate());
        root.viewDate = new Date(t.getFullYear(), t.getMonth(), 1);
    }

    function updateCells() {
        const y = viewDate.getFullYear();
        const m = viewDate.getMonth();
        const firstDay = new Date(y, m, 1).getDay();
        const lead = weekStartsMonday ? (firstDay + 6) % 7 : firstDay;
        const daysInMonth = new Date(y, m + 1, 0).getDate();
        const prevDays = new Date(y, m, 0).getDate();
        const out = [];
        for (let i = lead - 1; i >= 0; i--) {
            const pm = m === 0 ? 11 : m - 1;
            const py = m === 0 ? y - 1 : y;
            out.push({ d: prevDays - i, m: pm, y: py, inMonth: false });
        }
        for (let d = 1; d <= daysInMonth; d++)
            out.push({ d: d, m: m, y: y, inMonth: true });
        const rem = 42 - out.length;
        const nm = m === 11 ? 0 : m + 1;
        const ny = m === 11 ? y + 1 : y;
        for (let d = 1; d <= rem; d++)
            out.push({ d: d, m: nm, y: ny, inMonth: false });
        cells = out;
    }

    onViewDateChanged: updateCells()
    onWeekStartsMondayChanged: updateCells()
    Component.onCompleted: updateCells()

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // ---- header: year/month nav + title (click = today) ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            IconActionButton {
                icon: "keyboard_double_arrow_left"
                tooltip: Translation.tr("Previous year")
                onClicked: root.moveYear(-1)
            }
            IconActionButton {
                icon: "chevron_left"
                tooltip: Translation.tr("Previous month")
                onClicked: root.moveMonth(-1)
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.monthTitle
                color: ArchTheme.fg
                font.family: ArchTheme.fontFamily
                font.pixelSize: ArchTheme.fontSize

                TapHandler {
                    onTapped: root.goToday()
                }
            }

            IconActionButton {
                icon: "chevron_right"
                tooltip: Translation.tr("Next month")
                onClicked: root.moveMonth(1)
            }
            IconActionButton {
                icon: "keyboard_double_arrow_right"
                tooltip: Translation.tr("Next year")
                onClicked: root.moveYear(1)
            }
        }

        // ---- weekday header ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.weekdayNames
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: ArchTheme.muted
                    font.family: ArchTheme.fontFamily
                    font.pixelSize: ArchTheme.fontSizeBadge
                }
            }
        }

        // ---- day grid ----
        Grid {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 1
            rowSpacing: 1

            Repeater {
                model: root.cells
                delegate: Rectangle {
                    id: dayCell
                    required property var modelData
                    readonly property bool today: root.isToday(modelData.y, modelData.m, modelData.d)
                    readonly property bool selected: root.isSelected(modelData.y, modelData.m, modelData.d)

                    Layout.preferredWidth: (dayGrid.width - 6) / 7
                    Layout.preferredHeight: Math.max(14, (dayGrid.width - 6) / 7)
                    radius: 4
                    color: selected ? ArchTheme.accent : today ? ArchTheme.surfaceActive : dayHover.hovered ? ArchTheme.surfaceHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.modelData.d
                        color: dayCell.today || dayCell.selected ? ArchTheme.accent : dayCell.modelData.inMonth ? ArchTheme.fg : ArchTheme.muted
                        font.family: ArchTheme.fontFamily
                        font.pixelSize: ArchTheme.fontSizeCaption
                    }

                    HoverHandler {
                        id: dayHover
                    }
                    TapHandler {
                        onTapped: {
                            root.selectedDate = new Date(dayCell.modelData.y, dayCell.modelData.m, dayCell.modelData.d);
                            if (!dayCell.modelData.inMonth)
                                root.viewDate = new Date(dayCell.modelData.y, dayCell.modelData.m, 1);
                        }
                    }
                }
            }

            id: dayGrid
        }
    }
}
