import QtQuick
import qs.core

// An Ethernet jack: its shield, the latch slot, its two LEDs. Plugged,
// a cable's in it.
Item {
    id: jack

    property bool plugged: false

    width: 44
    height: 52

    Rectangle {
        y: 6
        width: parent.width
        height: 34
        radius: 2
        border.width: 1
        border.color: "black"
        gradient: Gradient {
            GradientStop { position: 0; color: "#c9cbd0" }
            GradientStop { position: 1; color: "#7c7f85" }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 30
            height: 22
            color: "#060606"

            // The contacts, and the slot for the latch.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 3
                spacing: 1.5

                Repeater {
                    model: 8

                    Rectangle {
                        width: 2
                        height: 5
                        color: "#b8913a"
                    }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - 6
                width: 12
                height: 6
                color: "#1b1b1d"
            }
        }
    }
    // The cable's plug, clear plastic, and the cable going down.
    Item {
        visible: jack.plugged

        Rectangle {
            x: 9
            y: 12
            width: 26
            height: 24
            radius: 2
            color: Qt.alpha("#d7e3ea", 0.55)
            border.width: 1
            border.color: Qt.alpha("white", 0.6)
        }
        Rectangle {
            x: 14
            y: 30
            width: 16
            height: 22
            radius: 3
            color: "#2f63b3"
            border.width: 1
            border.color: Qt.alpha("black", 0.6)
        }
    }
    Led {
        x: 2
        y: 0
        size: 6
        on: jack.plugged
        color: Theme.palette.ok
    }
    Led {
        x: jack.width - width - 2
        y: 0
        size: 6
        on: false
        color: Theme.palette.warn
    }
}
