import QtQuick
import qs.components as C
import qs.core
import qs.modules.calendar as M

// Days are round: today a filled accent bubble, the selected day ringed,
// days of other months faded. Events are little dots underneath.
Item {
    id: root

    required property M.CalendarDay control
    readonly property real size: Math.min(width, height) - 2

    Rectangle {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        color: root.control.isToday ? Theme.palette.accent : root.control.hovered ? Theme.palette.surface : "transparent"
        border.color: Theme.palette.accent
        border.width: root.control.selected ? 2 : 0
    }
    C.StyledText {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.control.lamps.length > 0 ? -2 : 0
        text: root.control.day.getDate()
        color: root.control.isToday ? Theme.palette.shadow
            : !root.control.inMonth ? Theme.palette.surface
            : root.control.weekend ? Theme.palette.dim
            : Theme.palette.fg
        font.bold: root.control.isToday
    }
    Row {
        anchors {
            bottom: parent.bottom
            bottomMargin: 5
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 2

        Repeater {
            model: root.control.lamps

            Rectangle {
                required property string modelData

                width: 4
                height: 4
                color: root.control.isToday ? Theme.palette.shadow : modelData
                opacity: root.control.inMonth ? 1 : 0.4
            }
        }
    }
}
