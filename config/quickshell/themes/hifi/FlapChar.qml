import QtQuick
import qs.core

// One split-flap character, showing `value` (a single character; anything
// not on its cards shows as a blank). Like the real thing it only turns
// forward, flipping through every card in between to get to a new one, the
// top half falling to show the next; however far it has to go, it gets
// there in under half a second. `ink` is the lettering.
Item {
    id: root

    // The cards on its drum, in order.
    readonly property string cards: " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:-'!?&/@#%+()"
    property string value: " "
    property color ink: "#f1eee6"
    readonly property int target: Math.max(0, cards.indexOf(value.toUpperCase()))
    property int current: 0
    property int next: 0
    property real phase: 0  // one flip: the top half falls (0-0.5), the bottom lands (0.5-1)
    // On the way to the current target: how many cards each flip moves on (a
    // long way, it skips some), and how long a flip takes.
    property int stride: 1
    property int stepTime: 34

    function step(): void {
        if (current === target || flip.running)
            return;
        const left = (target - current + cards.length) % cards.length;
        next = (current + Math.min(stride, left)) % cards.length;
        flip.start();
    }

    Component.onCompleted: current = next = target
    onTargetChanged: {
        const distance = (target - current + cards.length) % cards.length;
        stride = Math.max(1, Math.ceil(distance / 22));
        stepTime = Math.max(17, Math.min(34, Math.round(380 / Math.max(1, Math.ceil(distance / stride)))));
        step();
    }

    NumberAnimation {
        id: flip

        target: root
        property: "phase"
        from: 0
        to: 1
        duration: root.stepTime
        onFinished: {
            root.current = root.next;
            root.phase = 0;
            root.step();
        }
    }

    component Half: Item {
        id: half

        property int card
        property bool upper

        width: root.width
        height: root.height / 2
        clip: true

        Rectangle {
            y: half.upper ? 0 : -half.height
            width: root.width
            height: root.height
            radius: 1.5
            gradient: Gradient {
                GradientStop { position: 0; color: "#2b2b2d" }
                GradientStop { position: 0.5; color: "#1c1c1e" }
                GradientStop { position: 1; color: "#151516" }
            }

            Text {
                anchors.centerIn: parent
                text: root.cards[half.card]
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: Math.round(root.height * 0.66)
                font.bold: true
            }
        }
    }

    // What's behind the flaps: the next card's top, the current one's bottom.
    Half {
        card: root.next
        upper: true
    }
    Half {
        y: root.height / 2
        card: root.current
        upper: false
    }

    // The falling top half, then the landing bottom half.
    Half {
        card: root.current
        upper: true
        visible: root.phase > 0 && root.phase < 0.5

        transform: Rotation {
            origin.y: root.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: -root.phase * 180
        }
    }
    Half {
        y: root.height / 2
        card: root.next
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
