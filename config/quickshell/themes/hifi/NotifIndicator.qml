import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A two-card split-flap counter printed MSG: how many notifications wait.
// The cards flip through every number on the way to a new count. In
// do-not-disturb a louvred shutter slides down over it.
Row {
    id: root

    required property W.NotifIndicator control
    readonly property int shownCount: Math.min(99, control.count)

    spacing: 5

    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "msg"
        color: root.control.active ? Theme.palette.accent : root.control.hovered ? Theme.palette.fg : Theme.palette.dim
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: cards.width + 8
        height: 34

        Well {
            id: window

            anchors.fill: parent
            roundness: 3
            fill: "#050505"
            ring: root.control.active ? Qt.alpha(Theme.palette.accent, 0.6) : "transparent"
        }
        Row {
            id: cards

            anchors.centerIn: parent
            spacing: 2

            Flap { width: 17; height: 26; value: Math.floor(root.shownCount / 10) }
            Flap { width: 17; height: 26; value: root.shownCount % 10 }
        }

        // The shutter.
        Item {
            anchors {
                fill: parent
                margins: 1
            }
            clip: true

            Metal {
                width: parent.width
                height: root.control.dnd ? parent.height : 0
                roundness: 2
                squareTop: true

                Behavior on height {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }

                // Louvres.
                Column {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    x: 4
                    spacing: 5

                    Repeater {
                        model: 5

                        Rectangle {
                            width: parent.parent.width - 8
                            height: 1
                            color: Qt.alpha(Theme.palette.shadow, 0.6)
                        }
                    }
                }
            }
        }
    }
}
