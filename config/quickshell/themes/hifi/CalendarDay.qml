import QtQuick
import qs.components as C
import qs.core
import qs.modules.calendar as M

// The month as a keypad: each day of the month a key, the selected one
// latched in, today backlit in the display color. Days of other months are
// only printed on the plate. Events are tiny LEDs under the number.
Item {
    id: root

    required property M.CalendarDay control

    Key {
        id: key

        anchors {
            fill: parent
            margins: 2
        }
        visible: root.control.inMonth
        down: root.control.selected
        hovered: root.control.hovered
        glowColor: root.control.isToday ? Theme.palette.accent : "transparent"
    }

    Engraved {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (root.control.inMonth ? key.shift - key.travel / 2 : 0) - (root.control.lamps.length > 0 ? 3 : 0)
        text: root.control.day.getDate()
        color: root.control.isToday ? Theme.palette.accent
            : !root.control.inMonth ? Theme.palette.muted
            : root.control.weekend ? Theme.palette.dim
            : Theme.palette.fg
        opacity: root.control.inMonth ? 1 : 0.6
        glow: root.control.isToday
        font.bold: root.control.isToday || root.control.selected
    }
    Row {
        anchors {
            bottom: parent.bottom
            bottomMargin: 7 + (root.control.inMonth ? 2 - key.shift : 0)
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 2

        Repeater {
            model: root.control.lamps

            Rectangle {
                required property string modelData

                width: 4
                height: 4
                radius: 2
                color: modelData
                opacity: root.control.inMonth ? 1 : 0.4
            }
        }
    }
}
