import QtQuick
import QtQuick.Effects
import qs.core

// An illuminated rocker switch in a black bezel, marked I and O. On, the I
// side is pressed in and sits in shadow while the O side stands up into the
// light; it snaps over when flipped. Its lens, above the I, glows in
// `lampColor` when `lit` and can `blink`; `dead` leaves it grey and dark.
Item {
    id: root

    property bool on: false
    property bool hovered: false
    property bool dead: false
    property color lampColor: Theme.palette.accent
    property bool lit: false
    property bool blink: false

    // 1 = on (I pressed), -1 = off (O pressed).
    property real tilt: on ? 1 : -1
    readonly property color body: dead ? Qt.darker(Theme.palette.muted, 1.6) : hovered ? "#34363b" : "#27282c"
    readonly property bool glowing: lit && !dead

    implicitWidth: 22
    implicitHeight: 36

    Behavior on tilt {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }

    // The bezel, a recess.
    Rectangle {
        anchors.fill: parent
        radius: 4
        border.width: 1
        border.color: Qt.lighter(Theme.palette.bg, 1.5)
        gradient: Gradient {
            GradientStop { position: 0; color: "#060607" }
            GradientStop { position: 1; color: "#1c1d20" }
        }
    }

    Item {
        id: rocker

        // Seen from the front, the half standing toward you looks taller
        // than the pressed one: the crease sits off center, away from it.
        readonly property real crease: height * (0.5 - 0.11 * root.tilt)

        anchors {
            fill: parent
            margins: 3
        }

        // The pressed half, turned from the light and sunk in shadow; the
        // standing half facing it, a bright edge along its far end.
        Rectangle {
            id: upper

            width: rocker.width
            height: rocker.crease
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: root.tilt < 0 ? Qt.lighter(root.body, 2.3) : Qt.darker(root.body, 1.9) }
                GradientStop { position: 0.15; color: root.tilt < 0 ? Qt.lighter(root.body, 1.6) : Qt.darker(root.body, 1.6) }
                GradientStop { position: 1; color: root.tilt < 0 ? root.body : Qt.darker(root.body, 1.3) }
            }
        }
        Rectangle {
            id: lower

            y: rocker.crease
            width: rocker.width
            height: rocker.height - rocker.crease
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: root.tilt > 0 ? Qt.lighter(root.body, 1.25) : Qt.darker(root.body, 1.3) }
                GradientStop { position: 0.85; color: root.tilt > 0 ? Qt.lighter(root.body, 1.5) : Qt.darker(root.body, 1.7) }
                GradientStop { position: 1; color: root.tilt > 0 ? Qt.lighter(root.body, 2.1) : Qt.darker(root.body, 2) }
            }
        }
        // The standing half's shadow falling onto the pressed one.
        Rectangle {
            y: root.tilt > 0 ? rocker.crease - height : rocker.crease
            width: rocker.width
            height: 4
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("black", root.tilt > 0 ? 0 : 0.7) }
                GradientStop { position: 1; color: Qt.alpha("black", root.tilt > 0 ? 0.7 : 0) }
            }
        }
        Rectangle {
            y: rocker.crease - 0.5
            width: rocker.width
            height: 1
            color: "black"
        }

        // The lens, above the I.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 3
            width: 10
            height: 4

            RectangularShadow {
                anchors.fill: parent
                visible: root.glowing && (Theme.glow.opacity ?? 0) > 0
                radius: 1
                blur: 7
                color: Qt.alpha(root.lampColor, 0.9 * (Theme.glow.opacity ?? 0))
            }
            Rectangle {
                anchors.fill: parent
                radius: 1
                color: root.glowing ? Qt.lighter(root.lampColor, 1.2) : Qt.darker(root.dead ? Theme.palette.muted : root.lampColor, 4)
                border.width: 1
                border.color: Qt.alpha("black", 0.6)
            }

            SequentialAnimation on opacity {
                running: root.blink && !root.dead
                loops: Animation.Infinite
                alwaysRunToEnd: true

                NumberAnimation { to: 0.3; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
            }
        }

        // The marks: a bar for on, a ring for off.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 9 + (rocker.crease - 9 - height) / 2
            width: 2
            height: 6
            color: Qt.alpha("white", root.dead ? 0.2 : 0.6)
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: rocker.crease + (rocker.height - rocker.crease - height) / 2
            width: 7
            height: 7
            radius: 3.5
            color: "transparent"
            border.width: 1.5
            border.color: Qt.alpha("white", root.dead ? 0.2 : 0.6)
        }
    }
}
