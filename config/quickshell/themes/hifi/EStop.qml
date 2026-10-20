import QtQuick
import QtQuick.Effects
import qs.core

// An emergency stop: a mushroom head standing in a recessed collar on a dark
// plinth, under a clear guard tinted like the head and hinged at its top
// edge. `open` swings the guard up toward you and lights the head; `pressed`
// sinks it into the collar; `alarm` makes it throb. A `glyph` can be printed
// on the head. Everything scales with `size`, the plinth's width.
Item {
    id: root

    property real size: 42
    property color color: Theme.palette.error
    property string glyph: ""
    property bool open: false
    property bool pressed: false
    property bool alarm: false

    readonly property real s: size / 42
    readonly property real side: 3 * s
    readonly property real sink: pressed ? 2 * s : 0
    property real throb: 1

    implicitWidth: size
    implicitHeight: size + side

    SequentialAnimation on throb {
        running: root.alarm
        loops: Animation.Infinite
        onStopped: root.throb = 1

        NumberAnimation { to: 0.55; duration: 260; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 260; easing.type: Easing.InOutSine }
    }

    // The plinth: its side, then its top.
    RectangularShadow {
        anchors {
            fill: parent
            topMargin: root.side
        }
        radius: 6 * root.s
        offset.y: 2 * root.s
        blur: 6 * root.s
        color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
    }
    Rectangle {
        anchors {
            fill: parent
            topMargin: root.side
        }
        radius: 6 * root.s
        color: "#0b0b0d"
    }
    Rectangle {
        id: face

        width: parent.width
        height: parent.height - root.side
        radius: 6 * root.s
        border.width: 1
        border.color: "black"
        gradient: Gradient {
            GradientStop { position: 0; color: "#55575e" }
            GradientStop { position: 0.5; color: "#38393f" }
            GradientStop { position: 1; color: "#26272b" }
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 1
                leftMargin: 6 * root.s
                rightMargin: 6 * root.s
            }
            height: 1
            color: Qt.alpha("white", 0.25)
        }
    }

    // The collar: a recess, its metal rim catching the light.
    Rectangle {
        id: collar

        x: (face.width - width) / 2
        y: (face.height - height) / 2
        width: 32 * root.s
        height: width
        radius: width / 2
        border.width: 1.5 * root.s
        border.color: Qt.lighter(Theme.palette.border, 1.25)
        gradient: Gradient {
            GradientStop { position: 0; color: "#050506" }
            GradientStop { position: 1; color: "#2c2d31" }
        }
    }

    // The head: its glow, its shadow in the collar, its skirt, its dome.
    Item {
        id: head

        readonly property color c: root.open ? Qt.lighter(root.color, 1.08) : Qt.darker(root.color, 1.7)

        x: collar.x + 3 * root.s
        y: collar.y + 2 * root.s + root.sink
        width: 26 * root.s
        height: width

        Behavior on y {
            NumberAnimation { duration: 70 }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            blur: 16 * root.s
            spread: 2 * root.s
            color: Qt.alpha(root.color, 0.9 * (Theme.glow.opacity ?? 0))
            opacity: root.open ? root.throb : 0

            Behavior on opacity {
                enabled: !root.alarm
                NumberAnimation { duration: 200 }
            }
        }
        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: 4 * root.s - root.sink
            blur: 4 * root.s
            color: Qt.alpha("black", 0.8)
        }
        // The skirt, below the dome.
        Rectangle {
            y: 3 * root.s - root.sink
            width: parent.width
            height: parent.height
            radius: width / 2
            color: Qt.darker(head.c, 2.4)
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Qt.darker(head.c, 2.2)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(head.c, 1.45) }
                GradientStop { position: 0.55; color: head.c }
                GradientStop { position: 1; color: Qt.darker(head.c, 1.6) }
            }
        }
        // Light bouncing back onto the dome's lower rim.
        Rectangle {
            x: 5 * root.s
            y: parent.height - 7 * root.s
            width: parent.width - 10 * root.s
            height: 3 * root.s
            radius: height / 2
            color: Qt.alpha(Qt.lighter(head.c, 1.6), 0.35)
        }
        // The glyph printed on it.
        Text {
            anchors.centerIn: parent
            text: root.glyph
            color: Qt.alpha("white", root.open ? 0.92 : 0.6)
            font.family: Theme.font.family
            font.pixelSize: Math.round(12 * root.s)
            visible: text !== ""
        }
        // The highlight.
        Rectangle {
            x: 6 * root.s
            y: 4 * root.s
            width: 9 * root.s
            height: 5 * root.s
            radius: height / 2
            rotation: -20
            color: Qt.alpha("white", root.open ? 0.6 : 0.4)
        }
    }

    // The hinge along the top of the plinth.
    Rectangle {
        anchors.horizontalCenter: face.horizontalCenter
        y: 1 * root.s
        width: 24 * root.s
        height: 4 * root.s
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.6) }
            GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.4) }
        }
    }

    // The guard: clear plastic tinted like the head, swinging up toward you.
    Item {
        id: guard

        x: 3 * root.s
        y: 4 * root.s
        width: face.width - 6 * root.s
        height: face.height - 7 * root.s

        transform: Rotation {
            origin.y: 0
            axis { x: 1; y: 0; z: 0 }
            angle: root.open ? 130 : 0

            Behavior on angle {
                NumberAnimation { duration: 260; easing.type: root.open ? Easing.OutBack : Easing.InQuad; easing.overshoot: 1.2 }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 4 * root.s
            color: Qt.alpha(root.color, 0.22)
            border.width: 2 * root.s
            border.color: Qt.alpha(Qt.lighter(root.color, 1.4), 0.75)
        }
        // The tab you lift it by.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 2 * root.s
            width: 12 * root.s
            height: 4 * root.s
            radius: height / 2
            color: Qt.alpha(Qt.lighter(root.color, 1.3), 0.85)
        }
        Gloss {
            anchors {
                fill: parent
                margins: 1
            }
            roundness: 3 * root.s
        }

    }
}
