import QtQuick
import qs.components
import qs.core
import qs.services

// The calendar: a month of days with ISO week numbers, today marked. With a
// CalDAV server configured (services/Events.qml), days with events are marked
// in their calendar's color and an agenda lists the selected day's events
// (click a day to select it). The skin (CalendarMenu) lays it out.
// Keys: Left/Right or PageUp/PageDown change month, Home jumps back to today,
// Escape closes.
Skinned {
    id: root

    property bool open: false

    signal done
    // The month shown moved by `months` (back when negative).
    signal turned(int months)

    readonly property date today: Time.now
    readonly property date now: Time.nowSeconds
    readonly property int weekStart: Setup.calendar.weekStart
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property bool onToday: viewYear === today.getFullYear() && viewMonth === today.getMonth()
    property date selected: today
    readonly property bool eventsAvailable: Events.available
    readonly property var agenda: Events.on(selected)

    // 42 dates (6 weeks) starting on the week that contains the 1st.
    readonly property var days: {
        const first = new Date(viewYear, viewMonth, 1);
        const offset = (first.getDay() - weekStart + 7) % 7;
        return Array.from({ length: 42 }, (_, i) => new Date(viewYear, viewMonth, 1 - offset + i));
    }

    skin: "CalendarMenu"
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

    // The events on a day: { summary, location, start, end, allDay, color }.
    function eventsOn(d: date): var {
        return Events.on(d);
    }

    function select(d: date): void {
        selected = d;
    }

    function shift(months: int): void {
        const d = new Date(viewYear, viewMonth + months, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        turned(months);
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
        const months = (today.getFullYear() - viewYear) * 12 + today.getMonth() - viewMonth;
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
        turned(months);
    }

    // Seconds while open.
    Live { target: Time; when: root.open }

    onOpenChanged: {
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
}
