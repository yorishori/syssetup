import QtQuick
import qs.components as C
import qs.core
import qs.modules.calendar as M

// Today is a filled bubble, the selected day outlined; days of other
// months faded. Event lamps are short bars along the bottom.
Item {
    id: root

    required property M.CalendarDay control

    Box {
        anchors.fill: parent
        fill: root.control.isToday ? Theme.palette.accent : root.control.hovered ? Theme.palette.surface : "transparent"
        stroke: root.control.selected ? Theme.palette.accent : "transparent"
    }
    C.StyledText {
        anchors.centerIn: parent
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
            bottomMargin: 3
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 2

        Repeater {
            model: root.control.lamps

            Rectangle {
                required property string modelData

                width: 5
                height: 2
                color: root.control.isToday ? Theme.palette.shadow : modelData
                opacity: root.control.inMonth ? 1 : 0.4
            }
        }
    }
}
