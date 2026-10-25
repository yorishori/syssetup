import QtQuick
import qs.core

// The tonearm, seen from above: the tube from the pivot, the headshell
// on its neck hooking up onto the record, the cartridge and the finger
// lift on it. Solid parts, lit from above.
Item {
    property real tube

    // The tube: a polished cylinder, its highlight along the top.
    Rectangle {
        y: -4
        width: tube
        height: 8
        radius: 4
        gradient: Gradient {
            GradientStop { position: 0; color: "#6d6e72" }
            GradientStop { position: 0.25; color: "#f6f6f4" }
            GradientStop { position: 0.4; color: "#d9dadc" }
            GradientStop { position: 0.75; color: "#7c7d81" }
            GradientStop { position: 1; color: "#3b3c40" }
        }
    }
    Item {
        x: tube - 4
        rotation: -52

        // The neck.
        Rectangle {
            y: -3.5
            width: 48
            height: 7
            radius: 3.5
            gradient: Gradient {
                GradientStop { position: 0; color: "#6d6e72" }
                GradientStop { position: 0.3; color: "#f6f6f4" }
                GradientStop { position: 0.75; color: "#7c7d81" }
                GradientStop { position: 1; color: "#3b3c40" }
            }
        }
        // The headshell, bevelled, the cartridge under it.
        Rectangle {
            x: 40
            y: -11
            width: 32
            height: 22
            radius: 3
            border.width: 1
            border.color: "black"
            gradient: Gradient {
                GradientStop { position: 0; color: "#5a5b61" }
                GradientStop { position: 0.15; color: "#3a3b40" }
                GradientStop { position: 1; color: "#141517" }
            }

            Rectangle {
                x: 2
                y: 1
                width: parent.width - 4
                height: 1
                color: Qt.alpha("white", 0.3)
            }
            Rectangle {
                x: 9
                y: 5
                width: 16
                height: 12
                radius: 2
                border.width: 1
                border.color: Qt.darker(Theme.palette.error, 2.5)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(Theme.palette.error, 1.15) }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.error, 1.6) }
                }
            }
        }
        // The finger lift.
        Rectangle {
            x: 70
            y: -18
            width: 5
            height: 16
            radius: 2.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#f2f2f0" }
                GradientStop { position: 1; color: "#6d6e72" }
            }
        }
    }
}
