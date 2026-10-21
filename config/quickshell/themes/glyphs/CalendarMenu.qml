import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.calendar as M

// Clock readout, month navigation, the month grid with ISO week numbers on
// the left, and the selected day's agenda. Scrolling over the grid changes
// month; the grid slides the way the month went.
Item {
    id: root

    required property M.CalendarPanel control

    implicitWidth: 300
    implicitHeight: column.implicitHeight

    Connections {
        target: root.control

        function onTurned(months: int): void {
            slide.from = months > 0 ? 24 : -24;
            slide.restart();
        }
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        // ── Readout ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            C.StyledText {
                text: Qt.formatDateTime(root.control.now, "HH:mm")
                color: Theme.palette.accent
                glow: true
                font.pixelSize: 34
                font.bold: true
            }
            C.StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 6
                text: Qt.formatDateTime(root.control.now, ":ss")
                color: Theme.palette.dim
                font.pixelSize: Theme.font.size + 2
                font.bold: true
            }
            Item {
                Layout.fillWidth: true
            }
            ColumnLayout {
                spacing: 0

                C.StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: "W" + String(root.control.isoWeek(root.control.today)).padStart(2, "0")
                    color: Theme.palette.dim
                    font.pixelSize: Theme.font.size - 2
                    font.bold: true
                    tracking: 1.5
                }
                C.StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: "D" + String(root.control.dayOfYear(root.control.today)).padStart(3, "0")
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 2
                    tracking: 1.5
                }
            }
        }
        C.StyledText {
            text: Qt.formatDate(root.control.today, "dddd d MMMM yyyy")
            caps: true
            color: Theme.palette.dim
            font.pixelSize: Theme.font.size - 2
            font.bold: true
            tracking: 1.5
        }

        // ── Month navigation ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 4

            C.IconButton {
                size: 24
                icon: "\u{F0141}"
                onClicked: root.control.shift(-1)
            }
            Item {
                Layout.fillWidth: true
                implicitHeight: 24

                C.StyledText {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(root.control.viewYear, root.control.viewMonth, 1), "MMMM yyyy")
                    caps: true
                    color: root.control.onToday ? Theme.palette.fg : monthArea.containsMouse ? Theme.palette.accent : Theme.palette.dim
                    font.bold: true
                    tracking: 1.5
                }
                // Clicking the month label jumps back to today.
                MouseArea {
                    id: monthArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.control.onToday ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.control.goToday()
                }
            }
            C.IconButton {
                size: 24
                icon: "\u{F0142}"
                onClicked: root.control.shift(1)
            }
        }

        // ── Grid ─────────────────────────────────────────────────────────────
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
                    easing.overshoot: Theme.motion.bounce
                }

                // Header: week column, then weekday names.
                C.StyledText {
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

                    C.StyledText {
                        required property int index
                        readonly property int weekday: (root.control.weekStart + index) % 7

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
                        readonly property date day: root.control.days[Math.floor(index / 8) * 7 + (index % 8) - 1] ?? new Date()

                        Layout.fillWidth: true
                        Layout.preferredWidth: isWeek ? 26 : 34
                        implicitHeight: 30

                        C.StyledText {
                            anchors.centerIn: parent
                            text: String(root.control.isoWeek(root.control.days[Math.floor(cell.index / 8) * 7 + (root.control.weekStart === 1 ? 3 : 4)])).padStart(2, "0")
                            color: Theme.palette.muted
                            font.pixelSize: Theme.font.size - 3
                            visible: cell.isWeek
                        }
                        M.CalendarDay {
                            anchors.fill: parent
                            visible: !cell.isWeek
                            day: cell.day
                            isToday: root.control.sameDay(cell.day, root.control.today)
                            selected: !isToday && root.control.sameDay(cell.day, root.control.selected)
                            inMonth: cell.day.getMonth() === root.control.viewMonth
                            // One lamp per calendar with events that day (max 3).
                            lamps: cell.isWeek ? [] : [...new Set(root.control.eventsOn(cell.day).map(e => e.color))].slice(0, 3)
                            onClicked: root.control.select(cell.day)
                        }
                    }
                }
            }

            // Scroll to change month.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => root.control.shift(wheel.angleDelta.y > 0 ? -1 : 1)
            }
        }

        // ── Agenda (only with a reachable CalDAV server) ─────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 4
            visible: root.control.eventsAvailable

            C.SectionTitle {
                text: root.control.sameDay(root.control.selected, root.control.today) ? "today" : Qt.formatDate(root.control.selected, "ddd d MMM")
                code: root.control.agenda.length > 0 ? String(root.control.agenda.length).padStart(2, "0") : ""
            }
            C.StyledText {
                Layout.leftMargin: 8
                text: "-- nothing scheduled --"
                color: Theme.palette.muted
                visible: root.control.agenda.length === 0
            }
            Repeater {
                model: root.control.agenda.slice(0, 8)

                RowLayout {
                    id: event

                    required property var modelData
                    readonly property bool past: modelData.end < root.control.today

                    Layout.fillWidth: true
                    spacing: 8
                    opacity: past ? 0.45 : 1

                    C.Marker {
                        implicitWidth: 3
                        implicitHeight: 14
                        vertical: true
                        color: event.modelData.color
                    }
                    C.StyledText {
                        Layout.preferredWidth: 86
                        text: event.modelData.allDay ? "all day"
                            : `${Qt.formatTime(event.modelData.start, "HH:mm")}–${Qt.formatTime(event.modelData.end, "HH:mm")}`
                        color: Theme.palette.dim
                        font.pixelSize: Theme.font.size - 2
                        font.bold: true
                        caps: true
                        tracking: event.modelData.allDay ? 1.5 : 0
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: event.modelData.summary + (event.modelData.location ? `  · ${event.modelData.location}` : "")
                        elide: Text.ElideRight
                    }
                }
            }
            C.StyledText {
                Layout.leftMargin: 8
                text: `+${root.control.agenda.length - 8} more`
                color: Theme.palette.muted
                font.pixelSize: Theme.font.size - 2
                visible: root.control.agenda.length > 8
            }
        }
    }
}
