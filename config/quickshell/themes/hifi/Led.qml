import QtQuick
import QtQuick.Effects
import qs.core

// An LED behind a domed lens in a dark bezel. Off, the lens shows its color
// faintly; on, it lights and blooms. `pulse` makes it throb.
Item {
    id: root

    property bool on: false
    property color color: Theme.palette.accent
    property bool pulse: false
    property real size: 8

    implicitWidth: size
    implicitHeight: size

    // Bezel: a recess, so darker above and catching light below.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.palette.shadow }
            GradientStop { position: 1; color: Qt.lighter(Theme.palette.border, 1.2) }
        }
    }

    Item {
        id: light

        anchors {
            fill: parent
            margins: Math.max(1, root.width * 0.14)
        }

        RectangularShadow {
            anchors.fill: parent
            visible: root.on && (Theme.glow.opacity ?? 0) > 0
            radius: width / 2
            blur: Math.max(4, root.width)
            spread: 0.5
            color: Qt.alpha(root.color, 0.8 * (Theme.glow.opacity ?? 0))
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: root.on ? Qt.lighter(root.color, 1.45) : Qt.darker(root.color, 2.6) }
                GradientStop { position: 0.55; color: root.on ? root.color : Qt.darker(root.color, 3.4) }
                GradientStop { position: 1; color: root.on ? Qt.darker(root.color, 1.25) : Qt.darker(root.color, 4.2) }
            }
        }

        SequentialAnimation on opacity {
            running: root.pulse
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.3; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
        }
    }

    // The lens catching the light.
    Rectangle {
        x: root.width * 0.28
        y: root.height * 0.2
        width: root.width * 0.3
        height: root.height * 0.22
        radius: height / 2
        color: Qt.alpha("white", root.on ? 0.55 : 0.18)
        visible: root.width >= 6
    }
}
