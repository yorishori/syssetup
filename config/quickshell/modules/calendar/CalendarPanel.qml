import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services

// Clock readout and a month grid with ISO week numbers on the left. With a
// CalDAV server configured (services/Events.qml), days with events are marked
// in their calendar's color and an agenda lists the selected day's events
// (click a day to select it).
// Keys: Left/Right or PageUp/PageDown change month, Home jumps back to today,
// Escape closes. Scrolling over the grid changes month too.
ColumnLayout {
    id: root

    property bool open: false

    signal done

    readonly property date today: Time.now
    readonly property int weekStart: Config.calendar.weekStart
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property bool onToday: viewYear === today.getFullYear() && viewMonth === today.getMonth()
    property date selected: today
    readonly property var agenda: Events.on(selected)

    // 42 dates (6 weeks) starting on the week that contains the 1st.
    readonly property var days: {
        const first = new Date(viewYear, viewMonth, 1);
        const offset = (first.getDay() - weekStart + 7) % 7;
        return Array.from({ length: 42 }, (_, i) => new Date(viewYear, viewMonth, 1 - offset + i));
    }

    width: 300
    spacing: 10
    focus: open

    function isoWeek(d: date): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }

    function dayOfYear(d: date): int {
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1;
    }

    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function shift(months: int): void {
        const d = new Date(viewYear, viewMonth + months, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        slide.from = months > 0 ? 24 : -24;
        slide.restart();
    }

    // Ask the server for the six visible weeks.
    function loadEvents(): void {
        const last = days[days.length - 1];
        Events.load(days[0], new Date(last.getFullYear(), last.getMonth(), last.getDate() + 1));
    }

    function goToday(): void {
        selected = today;
        if (onToday)
            return;
        const forward = today > new Date(viewYear, viewMonth, 1);
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
        slide.from = forward ? 24 : -24;
        slide.restart();
    }

    onOpenChanged: {
        Time.secondsNeeded = open;
        if (open) {
            viewYear = today.getFullYear();
            viewMonth = today.getMonth();
            selected = today;
            loadEvents();
            forceActiveFocus();
        }
    }
    onDaysChanged: if (open) loadEvents()

    Keys.onLeftPressed: shift(-1)
    Keys.onRightPressed: shift(1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_PageUp)
            shift(-1);
        else if (event.key === Qt.Key_PageDown)
            shift(1);
        else if (event.key === Qt.Key_Home)
            goToday();
    }
    Keys.onEscapePressed: done()

    // ── Readout ──────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            text: Qt.formatDateTime(Time.nowSeconds, "HH:mm")
            color: Theme.palette.accent
            glow: true
            font.pixelSize: 34
            font.bold: true
        }
        StyledText {
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 6
            text: Qt.formatDateTime(Time.nowSeconds, ":ss")
            color: Theme.palette.dim
            font.pixelSize: Theme.font.size + 2
            font.bold: true
        }
        Item {
            Layout.fillWidth: true
        }
        ColumnLayout {
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignRight
                text: "W" + String(root.isoWeek(root.today)).padStart(2, "0")
                color: Theme.palette.dim
                font.pixelSize: Theme.font.size - 2
                font.bold: true
                tracking: 1.5
            }
            StyledText {
                Layout.alignment: Qt.AlignRight
                text: "D" + String(root.dayOfYear(root.today)).padStart(3, "0")
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                tracking: 1.5
            }
        }
    }
    StyledText {
        text: Qt.formatDate(root.today, "dddd d MMMM yyyy")
        caps: true
        color: Theme.palette.dim
        font.pixelSize: Theme.font.size - 2
        font.bold: true
        tracking: 1.5
    }

    // ── Month navigation ─────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4

        IconButton {
            size: 24
            icon: "\u{F0141}"
            onClicked: root.shift(-1)
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 24

            StyledText {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                caps: true
                color: root.onToday ? Theme.palette.fg : monthArea.containsMouse ? Theme.palette.accent : Theme.palette.dim
                font.bold: true
                tracking: 1.5
            }
            // Clicking the month label jumps back to today.
            MouseArea {
                id: monthArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.onToday ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.goToday()
            }
        }
        IconButton {
            size: 24
            icon: "\u{F0142}"
            onClicked: root.shift(1)
        }
    }

    // ── Grid ─────────────────────────────────────────────────────────────────
    Item {
        Layout.fillWidth: true
        implicitHeight: grid.implicitHeight
        clip: true

        GridLayout {
            id: grid

            width: parent.width
            columns: 8
            columnSpacing: 2
            rowSpacing: 2

            NumberAnimation on x {
                id: slide

                to: 0
                duration: 220
                easing.type: Theme.motion.spring
            }

            // Header: week column, then weekday names.
            StyledText {
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignHCenter
                text: "wk"
                caps: true
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 4
                font.bold: true
            }
            Repeater {
                model: 7

                StyledText {
                    required property int index
                    readonly property int weekday: (root.weekStart + index) % 7

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName(weekday, Locale.ShortFormat).slice(0, 2)
                    caps: true
                    color: weekday === 0 || weekday === 6 ? Theme.palette.muted : Theme.palette.dim
                    font.pixelSize: Theme.font.size - 3
                    font.bold: true
                    tracking: 1
                }
            }

            // 6 weeks: week number + 7 days.
            Repeater {
                model: 48

                Item {
                    id: cell

                    required property int index
                    readonly property bool isWeek: index % 8 === 0
                    readonly property date day: root.days[Math.floor(index / 8) * 7 + (index % 8) - 1] ?? new Date()

                    Layout.fillWidth: true
                    Layout.preferredWidth: isWeek ? 26 : 34
                    implicitHeight: 30

                    StyledText {
                        anchors.centerIn: parent
                        text: String(root.isoWeek(root.days[Math.floor(cell.index / 8) * 7 + (root.weekStart === 1 ? 3 : 4)])).padStart(2, "0")
                        color: Theme.palette.muted
                        font.pixelSize: Theme.font.size - 3
                        visible: cell.isWeek
                    }
                    CalendarDay {
                        anchors.fill: parent
                        visible: !cell.isWeek
                        day: cell.day
                        isToday: root.sameDay(cell.day, root.today)
                        selected: !isToday && root.sameDay(cell.day, root.selected)
                        inMonth: cell.day.getMonth() === root.viewMonth
                        // One lamp per calendar with events that day (max 3).
                        lamps: cell.isWeek ? [] : [...new Set(Events.on(cell.day).map(e => e.color))].slice(0, 3)
                        onClicked: root.selected = cell.day
                    }
                }
            }
        }

        // Scroll to change month.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => root.shift(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    // ── Agenda (only with a reachable CalDAV server) ─────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4
        visible: Events.available

        SectionTitle {
            text: root.sameDay(root.selected, root.today) ? "today" : Qt.formatDate(root.selected, "ddd d MMM")
            code: root.agenda.length > 0 ? String(root.agenda.length).padStart(2, "0") : ""
        }
        StyledText {
            Layout.leftMargin: 8
            text: "-- nothing scheduled --"
            color: Theme.palette.muted
            visible: root.agenda.length === 0
        }
        Repeater {
            model: root.agenda.slice(0, 8)

            RowLayout {
                id: event

                required property var modelData
                readonly property bool past: modelData.end < Time.now

                Layout.fillWidth: true
                spacing: 8
                opacity: past ? 0.45 : 1

                Marker {
                    implicitWidth: 3
                    implicitHeight: 14
                    vertical: true
                    color: event.modelData.color
                }
                StyledText {
                    Layout.preferredWidth: 86
                    text: event.modelData.allDay ? "all day"
                        : `${Qt.formatTime(event.modelData.start, "HH:mm")}–${Qt.formatTime(event.modelData.end, "HH:mm")}`
                    color: Theme.palette.dim
                    font.pixelSize: Theme.font.size - 2
                    font.bold: true
                    caps: true
                    tracking: event.modelData.allDay ? 1.5 : 0
                }
                StyledText {
                    Layout.fillWidth: true
                    text: event.modelData.summary + (event.modelData.location ? `  · ${event.modelData.location}` : "")
                    elide: Text.ElideRight
                }
            }
        }
        StyledText {
            Layout.leftMargin: 8
            text: `+${root.agenda.length - 8} more`
            color: Theme.palette.muted
            font.pixelSize: Theme.font.size - 2
            visible: root.agenda.length > 8
        }
    }
}
