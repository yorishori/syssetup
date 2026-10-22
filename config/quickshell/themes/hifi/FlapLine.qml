import QtQuick
import qs.core

// A wide split-flap card with a whole line on it, like a departure board's
// destinations, showing `value`. To get to a new one it flips through a few
// of the other cards on its drum (filler lines, of all lengths) first,
// briskly, the top half falling to show the next. `ink` is the lettering.
Item {
    id: root

    property string value: ""
    property color ink: "#f1eee6"
    // The other cards on its drum.
    readonly property var filler: [
        "LOREM IPSUM", "DOLOR SIT AMET", "CONSECTETUR ADIPISCING ELIT", "SED DO", "EIUSMOD TEMPOR INCIDIDUNT",
        "UT LABORE", "ET DOLORE MAGNA ALIQUA", "UT ENIM AD MINIM", "VENIAM", "QUIS NOSTRUD EXERCITATION",
        "ULLAMCO LABORIS", "NISI UT ALIQUIP", "EX EA COMMODO CONSEQUAT"
    ]
    property string current: ""
    property string next: ""
    property real phase: 0  // one flip: the top half falls (0-0.5), the bottom lands (0.5-1)
    // The cards still to flip through on the way, and where it started on
    // the drum.
    property int toGo: 0
    property int seed: 0

    function step(): void {
        if (flip.running)
            return;
        if (toGo > 0) {
            next = filler[(seed + toGo) % filler.length];
            toGo--;
        } else if (current !== value) {
            next = value;
        } else {
            return;
        }
        flip.start();
    }

    Component.onCompleted: current = next = value
    onValueChanged: {
        seed = Math.floor(Math.random() * filler.length);
        toGo = current === "" && value === "" ? 0 : 3 + Math.floor(Math.random() * 3);
        step();
    }

    NumberAnimation {
        id: flip

        target: root
        property: "phase"
        from: 0
        to: 1
        duration: 60
        onFinished: {
            root.current = root.next;
            root.phase = 0;
            root.step();
        }
    }

    component Half: Item {
        id: half

        property string line
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
                x: 8
                width: parent.width - 16
                anchors.verticalCenter: parent.verticalCenter
                text: half.line
                elide: Text.ElideRight
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: Math.round(root.height * 0.6)
                font.bold: true
                font.letterSpacing: 2
            }
        }
    }

    // What's behind the flaps: the next card's top, the current one's bottom.
    Half {
        line: root.next
        upper: true
    }
    Half {
        y: root.height / 2
        line: root.current
        upper: false
    }

    // The falling top half, then the landing bottom half.
    Half {
        line: root.current
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
        line: root.next
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
