import QtQuick
import qs.core
import qs.modules.calendar as M

// The calendar's agenda page: the day's events, folding down from the
// month's foot (see CalendarMenu).
Item {
    id: agendaPage

    required property M.CalendarPanel control
    // The day shown, its events, and the fold: 0 hanging down, 180 folded up.
    required property date day
    required property var events
    required property real fold
    required property color paper
    required property color ink
    required property color red

    visible: control.eventsAvailable && fold < 179
    transform: Rotation {
        origin.y: 0
        axis { x: 1; y: 0; z: 0 }
        angle: fold
    }

    CalendarSheet {
        paper: agendaPage.paper
        anchors.fill: parent
    }
    // Ruled, with a margin.
    Repeater {
        model: Math.max(1, events.length)

        Rectangle {
            required property int index

            x: 8
            y: 44 + (index + 1) * 28 - 2
            width: parent.width - 16
            height: 1
            color: Qt.alpha("#6b93c4", 0.45)
        }
    }
    Rectangle {
        x: 62
        y: 36
        width: 1
        height: parent.height - 44
        color: Qt.alpha(red, 0.5)
    }
    Text {
        x: 16
        y: 12
        text: Qt.formatDate(day, "dddd d MMMM").toUpperCase()
        color: ink
        font.family: Theme.font.family
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 2
    }
    Repeater {
        model: events

        Item {
            id: entry

            required property int index
            required property var modelData

            y: 44 + index * 28
            width: parent.width
            height: 28
            opacity: modelData.end < control.now ? 0.5 : 1

            Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: entry.modelData.allDay ? "ALL DAY" : Qt.formatTime(entry.modelData.start, "HH:mm")
                color: Qt.alpha(ink, 0.75)
                font.family: Theme.font.family
                font.pixelSize: 10
                font.bold: true
            }
            Rectangle {
                x: 72
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: 3.5
                color: entry.modelData.color
            }
            Text {
                x: 86
                width: parent.width - x - 14
                anchors.verticalCenter: parent.verticalCenter
                text: entry.modelData.summary + (entry.modelData.location ? `  · ${entry.modelData.location}` : "")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Qt.darker(entry.modelData.color, 1.6)
                font.family: Theme.font.family
                font.pixelSize: 12
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.darker(paper, 1.08)
        visible: fold > 90
    }
}
