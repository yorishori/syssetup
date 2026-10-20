import QtQuick
import QtQuick.Effects
import qs.core

// A bat-handle toggle switch seen from the front: a threaded bushing in a
// nut, the lever pointing up when `on`, down when off. It flips through
// pointing straight at you, and snaps. The ball on its tip can glow
// (`tipColor`, `tipLit`, `tipBlink`); `dead` greys it out.
Item {
    id: root

    property bool on: false
    property bool hovered: false
    property bool dead: false
    property color tipColor: Theme.palette.accent
    property bool tipLit: false
    property bool tipBlink: false

    // 1 = up, -1 = down; it passes through 0 while flipping.
    property real extent: on ? 1 : -1
    readonly property real reach: height / 2 - 5
    readonly property color metal: dead ? Theme.palette.muted : hovered ? Qt.lighter(Theme.palette.fg, 1.05) : Theme.palette.dim

    implicitWidth: 26
    implicitHeight: 44

    Behavior on extent {
        NumberAnimation { duration: 110; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }

    // The nut.
    Rectangle {
        anchors.centerIn: parent
        width: 20
        height: 20
        radius: 4
        rotation: 45 / 2
        border.width: 1
        border.color: Theme.palette.shadow
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.4) }
            GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.5) }
        }
    }
    // The bushing.
    Rectangle {
        anchors.centerIn: parent
        width: 12
        height: 12
        radius: 6
        border.width: 1
        border.color: Theme.palette.shadow
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.darker(Theme.palette.border, 1.6) }
            GradientStop { position: 1; color: Qt.lighter(Theme.palette.border, 1.3) }
        }
    }

    // The lever, foreshortened as it swings.
    Rectangle {
        id: lever

        readonly property real length: Math.abs(root.extent) * root.reach

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.extent >= 0 ? root.height / 2 - length : root.height / 2
        width: 6
        height: length
        radius: 3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.darker(root.metal, 1.5) }
            GradientStop { position: 0.4; color: Qt.lighter(root.metal, 1.25) }
            GradientStop { position: 1; color: Qt.darker(root.metal, 1.8) }
        }
    }
    // Its shadow on the panel, below it.
    Rectangle {
        anchors.horizontalCenter: lever.horizontalCenter
        anchors.horizontalCenterOffset: 2
        y: lever.y + 3
        width: lever.width
        height: lever.height
        radius: 3
        z: -1
        color: Qt.alpha(Theme.palette.shadow, 0.5 * (Theme.values.effects?.shadow ?? 0))
    }

    // The ball on the tip.
    Item {
        id: tip

        x: (root.width - width) / 2
        y: root.height / 2 - root.extent * root.reach - height / 2
        width: 9 + 2 * (1 - Math.abs(root.extent))
        height: width

        RectangularShadow {
            anchors.fill: parent
            visible: root.tipLit && !root.dead && (Theme.glow.opacity ?? 0) > 0
            radius: width / 2
            blur: 8
            color: Qt.alpha(root.tipColor, 0.9 * (Theme.glow.opacity ?? 0))
        }
        Rectangle {
            id: ball

            readonly property color c: root.tipLit && !root.dead ? root.tipColor : root.metal

            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Qt.alpha(Theme.palette.shadow, 0.7)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(ball.c, 1.35) }
                GradientStop { position: 1; color: Qt.darker(ball.c, 1.6) }
            }
        }

        SequentialAnimation on opacity {
            running: root.tipBlink && !root.dead
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.35; duration: 450; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
        }
    }
}
