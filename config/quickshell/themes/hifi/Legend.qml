import QtQuick
import qs.core

// A label punched on a label maker and stuck on the panel beside a part:
// glossy black plastic tape, the letters pressed into it standing out thin and
// white where the plastic was stretched, never quite in line. `tape` for
// another color of tape; `hovered` when the label itself is a button.
Item {
    id: root

    property string text
    property color tape: "#141416"
    property bool hovered: false
    readonly property var letters: text.toUpperCase().split("")
    readonly property real pitch: 6.4

    implicitWidth: letters.length * pitch + 9
    implicitHeight: 14

    // The tape, its edges curling a little.
    Rectangle {
        id: strip

        property color c: root.hovered ? Qt.lighter(root.tape, 1.6) : root.tape

        anchors.fill: parent
        radius: 1.5
        border.width: 1
        border.color: Qt.darker(strip.c, 1.6)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(strip.c, 1.9) }
            GradientStop { position: 0.18; color: strip.c }
            GradientStop { position: 0.82; color: strip.c }
            GradientStop { position: 1; color: Qt.lighter(strip.c, 1.4) }
        }

        Behavior on c {
            ColorAnimation { duration: 120 }
        }
    }

    // The letters, each pressed a little off from the last.
    Repeater {
        model: root.letters

        Item {
            id: letter

            required property int index
            required property string modelData
            // Steady per letter, so the label doesn't shift between frames.
            readonly property int seed: (index * 7919 + modelData.charCodeAt(0) * 31) % 7

            x: 4.5 + index * root.pitch
            y: (seed - 3) * 0.25
            width: root.pitch
            height: root.height
            rotation: (seed - 3) * 0.6

            // The stretched plastic catching light above, shade below.
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0.8
                text: letter.modelData
                color: Qt.alpha("black", 0.7)
                font.family: Theme.font.family
                font.pixelSize: 9
                font.weight: Font.Light
            }
            Text {
                anchors.centerIn: parent
                text: letter.modelData
                color: Qt.alpha("#f4f2ec", 0.93)
                font.family: Theme.font.family
                font.pixelSize: 9
                font.weight: Font.Light
            }
        }
    }
}
