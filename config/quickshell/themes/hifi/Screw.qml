import QtQuick
import qs.core

// A countersunk screw head holding a plate on, its slot at `angle`. Hidden
// when the theme's screws are off.
Rectangle {
    property real angle: 30
    property real size: 7

    width: size
    height: size
    radius: size / 2
    visible: Theme.values.effects?.screws ?? true
    border.width: 1
    border.color: Qt.alpha(Theme.palette.shadow, 0.8)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.5) }
        GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.6) }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 2
        height: 1
        rotation: parent.angle
        color: Qt.alpha(Theme.palette.shadow, 0.9)
    }
}
