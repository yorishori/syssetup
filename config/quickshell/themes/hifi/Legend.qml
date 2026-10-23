import QtQuick
import qs.core

// A label punched on a label maker and stuck on the panel beside a part:
// glossy black plastic tape, the letters pressed into it standing out white
// where the plastic was stretched. `tape` for
// another color of tape; `hovered` when the label itself is a button.
Item {
    id: root

    property string text
    property color tape: "#141416"
    property bool hovered: false
    property real size: 9  // the letters' nominal height, px
    // Printed a little larger than nominal, and not thin, so they stay
    // readable at a desk's distance.
    readonly property real px: size + 1.5
    readonly property var letters: text.toUpperCase().split("")
    readonly property real pitch: px * 0.71

    implicitWidth: letters.length * pitch + px
    implicitHeight: px + 5

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

    // The letters.
    Repeater {
        model: root.letters

        Item {
            id: letter

            required property int index
            required property string modelData
            x: root.px / 2 + index * root.pitch
            width: root.pitch
            height: root.height

            // The stretched plastic catching light above, shade below.
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.px / 11
                text: letter.modelData
                color: Qt.alpha("black", 0.7)
                font.family: Theme.font.family
                font.pixelSize: root.px
                font.weight: Font.Normal
            }
            Text {
                anchors.centerIn: parent
                text: letter.modelData
                color: Qt.alpha("#f4f2ec", 0.93)
                font.family: Theme.font.family
                font.pixelSize: root.px
                font.weight: Font.Normal
            }
        }
    }
}
