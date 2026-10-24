import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.capture as M

// A rangefinder's viewfinder. Bright frame lines float over the scene,
// round the area, gliding to a hovered window or drawn out with the hand;
// past them the view goes dark. In the middle of the frame, the focus
// patch: while the frame's being dragged its double image is apart, and it
// comes together when the hand stops. Along the bottom, the viewfinder's
// red LEDs: the size, what's framed (a window, a region, the screen), a
// blinking REC to record.
//
// Taken (a screenshot), the leaf shutter fires over the frame: its blades
// turn in to close the circle and open again.
Item {
    id: root

    required property M.Selection control

    // The frame: the area, or with nothing chosen, the screen.
    readonly property rect r: control.hasArea ? control.area : Qt.rect(0, 0, width, height)
    readonly property bool still: !control.moving
    readonly property bool choosing: !control.marking
    readonly property color frameLine: "#fff1d2"
    readonly property color led: "#ff3b2a"
    property real edgeL: r.x
    property real edgeR: r.x + r.width
    property real edgeT: r.y
    property real edgeB: r.y + r.height
    // The patch's double image, apart while the frame moves.
    readonly property real ghost: control.moving ? 9 : 0
    property real ghostShown: ghost
    // The shutter: 1 open, 0 shut.
    property real aperture: 1

    Behavior on edgeL { enabled: root.still; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on edgeR { enabled: root.still; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on edgeT { enabled: root.still; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on edgeB { enabled: root.still; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on ghostShown { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }

    Connections {
        target: root.control

        function onMarkingChanged(): void {
            if (root.control.marking)
                shutter.restart();
        }
    }
    SequentialAnimation {
        id: shutter

        NumberAnimation { target: root; property: "aperture"; from: 1; to: 0; duration: 110; easing.type: Easing.InQuad }
        PauseAnimation { duration: 70 }
        NumberAnimation { target: root; property: "aperture"; to: 1; duration: 190; easing.type: Easing.OutQuad }
    }

    // Dark past the frame.
    component Dark: Rectangle {
        color: "#050506"
        opacity: 0.62
    }
    Dark { width: parent.width; height: root.edgeT }
    Dark { y: root.edgeB; width: parent.width; height: parent.height - y }
    Dark { y: root.edgeT; width: root.edgeL; height: root.edgeB - root.edgeT }
    Dark { x: root.edgeR; y: root.edgeT; width: parent.width - x; height: root.edgeB - root.edgeT }

    // ── The frame lines ──────────────────────────────────────────────────────
    Item {
        x: root.edgeL
        y: root.edgeT
        width: root.edgeR - root.edgeL
        height: root.edgeB - root.edgeT
        visible: root.choosing && root.control.hasArea

        Rectangle {
            anchors {
                fill: parent
                margins: -3
            }
            color: "transparent"
            border.width: 5
            border.color: Qt.alpha(root.frameLine, 0.12)
        }
        // A dark line outside the bright one, so it reads over light too.
        Rectangle {
            anchors {
                fill: parent
                margins: -1.5
            }
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha("black", 0.55)
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1.5
            border.color: Qt.alpha(root.frameLine, 0.9)
        }
        // Brighter at the corners.
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]

            Item {
                required property var modelData
                readonly property real mark: Math.min(26, parent.width / 3, parent.height / 3)

                x: modelData[0] ? parent.width - mark : 0
                y: modelData[1] ? parent.height - mark : 0
                width: mark
                height: mark

                Rectangle {
                    y: parent.modelData[1] ? parent.height - height : 0
                    width: parent.width
                    height: 3
                    color: root.frameLine
                }
                Rectangle {
                    x: parent.modelData[0] ? parent.width - width : 0
                    width: 3
                    height: parent.height
                    color: root.frameLine
                }
            }
        }

        // The focus patch, and its double image.
        Item {
            anchors.centerIn: parent
            width: 74
            height: 48
            visible: parent.width > 160 && parent.height > 110

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Qt.alpha("#ffcf6a", 0.13)
                border.width: 1
                border.color: Qt.alpha("#ffd98a", 0.55)
            }
            Rectangle {
                x: root.ghostShown
                y: -root.ghostShown * 0.3
                width: parent.width
                height: parent.height
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha("#ffd98a", 0.4)
                visible: Math.abs(root.ghostShown) > 0.3
            }
        }
    }

    // ── The LEDs along the bottom ────────────────────────────────────────────
    Row {
        id: leds

        property bool blink: true

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 36
        }
        spacing: 18
        visible: root.choosing
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: false
            shadowEnabled: true
            shadowColor: root.led
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Timer {
            interval: 600
            running: leds.visible && root.control.kind !== "screenshot"
            repeat: true
            onTriggered: leds.blink = !leds.blink
        }

        component Lit: Text {
            color: root.led
            font.family: Theme.font.family
            font.pixelSize: 14
            font.bold: true
            font.letterSpacing: 2
        }
        Lit {
            text: "● REC"
            visible: root.control.kind !== "screenshot"
            opacity: leds.blink ? 1 : 0.15
        }
        Lit {
            text: `${Math.round(root.r.width)}×${Math.round(root.r.height)}`
        }
        Lit {
            text: !root.control.hasArea ? "SCREEN" : root.control.moving ? "REGION" : "WINDOW"
        }
        Lit {
            text: "CLICK · DRAG · ENTER"
            opacity: 0.45
        }
    }

    // ── The shutter ──────────────────────────────────────────────────────────
    // Its blades turn in round the frame's middle, each a steel leaf whose
    // edge is the circle's.
    Item {
        x: root.control.area.x
        y: root.control.area.y
        width: root.control.area.width
        height: root.control.area.height
        clip: true
        visible: root.aperture < 0.999

        Item {
            id: iris

            readonly property real reach: Math.hypot(parent.width, parent.height) / 2 + 4
            readonly property int blades: 7

            x: parent.width / 2
            y: parent.height / 2

            Repeater {
                model: iris.blades

                Item {
                    required property int index

                    rotation: index * 360 / iris.blades + 50 * (1 - root.aperture)

                    Rectangle {
                        x: -iris.reach * 0.35
                        y: iris.reach * root.aperture
                        width: iris.reach * 1.6
                        height: iris.reach * 1.2
                        radius: 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#4a4c52" }
                            GradientStop { position: 0.08; color: "#2a2b30" }
                            GradientStop { position: 1; color: "#141417" }
                        }

                        // The leaf's edge catching the light.
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Qt.alpha("white", 0.25)
                        }
                    }
                }
            }
        }
    }
}
