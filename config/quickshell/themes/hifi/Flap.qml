import QtQuick
import qs.core

// One split-flap card, showing `value` (0-9). Like the real thing it only
// turns forward: to get to a new value it flips through every one in
// between, the top half falling to show the next card.
Item {
    id: root

    property int value: 0
    property int current: 0
    property int next: 0
    property real phase: 0  // one flip: the top half falls (0-0.5), the bottom lands (0.5-1)

    function step(): void {
        if (current === value || flip.running)
            return;
        next = (current + 1) % 10;
        flip.start();
    }

    Component.onCompleted: current = next = value
    onValueChanged: step()

    NumberAnimation {
        id: flip

        target: root
        property: "phase"
        from: 0
        to: 1
        duration: 120
        onFinished: {
            root.current = root.next;
            root.phase = 0;
            root.step();
        }
    }

    component Half: Item {
        id: half

        property int digit
        property bool upper

        width: root.width
        height: root.height / 2
        clip: true

        Rectangle {
            y: half.upper ? 0 : -half.height
            width: root.width
            height: root.height
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: "#2b2b2d" }
                GradientStop { position: 0.5; color: "#1c1c1e" }
                GradientStop { position: 1; color: "#151516" }
            }

            Text {
                anchors.centerIn: parent
                text: half.digit
                color: "#f1eee6"
                font.family: Theme.font.family
                font.pixelSize: Math.round(root.height * 0.72)
                font.bold: true
            }
        }
    }

    // What's behind the flaps: the next card's top, the current one's bottom.
    Half {
        digit: root.next
        upper: true
    }
    Half {
        y: root.height / 2
        digit: root.current
        upper: false
    }

    // The falling top half, then the landing bottom half.
    Half {
        digit: root.current
        upper: true
        visible: root.phase < 0.5

        transform: Rotation {
            origin.y: root.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: -root.phase * 180
        }
    }
    Half {
        y: root.height / 2
        digit: root.next
        upper: false
        visible: root.phase >= 0.5

        transform: Rotation {
            origin.y: 0
            axis { x: 1; y: 0; z: 0 }
            angle: (1 - root.phase) * 180
        }
    }

    // The split.
    Rectangle {
        y: root.height / 2 - 0.5
        width: root.width
        height: 1
        color: Theme.palette.shadow
    }
}
