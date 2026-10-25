import QtQuick
import qs.core

// One wheel of a mechanical counter, showing `digit` (0 to `wheel` - 1).
// It rolls forward to each new digit, over the top from the last back to 0,
// and back down when it's rewound to 0 from further along.
Item {
    id: root

    property int digit: 0
    property int wheel: 10
    property real position: 0

    clip: true

    Component.onCompleted: position = digit
    onDigitChanged: {
        roll.stop();
        const from = Math.round(position) % wheel;
        roll.to = digit === 0 && from === wheel - 1 ? wheel : digit;
        roll.start();
    }

    NumberAnimation {
        id: roll

        target: root
        property: "position"
        duration: 260
        easing.type: Easing.OutCubic
        onFinished: root.position = root.position % root.wheel
    }

    // The drum: dark plastic, its digits printed white; 0 again at the end
    // for the roll over.
    Column {
        y: -root.position * root.height

        Repeater {
            model: root.wheel + 1

            Item {
                required property int index

                width: root.width
                height: root.height

                Text {
                    anchors.centerIn: parent
                    text: parent.index % root.wheel
                    color: "#f1eee6"
                    font.family: Theme.font.family
                    font.pixelSize: Math.round(root.height * 0.72)
                    font.bold: true
                }
            }
        }
    }

    // The drum curving away at the top and bottom.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.palette.shadow, 0.85) }
            GradientStop { position: 0.3; color: "transparent" }
            GradientStop { position: 0.7; color: "transparent" }
            GradientStop { position: 1; color: Qt.alpha(Theme.palette.shadow, 0.85) }
        }
    }
}
