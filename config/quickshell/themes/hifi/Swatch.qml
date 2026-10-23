import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core

// A jewel pilot lamp: a domed glass jewel in its color, set in a dark bezel.
// Hovered it brightens; the selected one is lit, in a bright bezel.
Item {
    id: root

    required property C.Swatch control

    implicitWidth: 20
    implicitHeight: 20

    RectangularShadow {
        anchors {
            fill: parent
            margins: 3
        }
        visible: root.control.selected && (Theme.glow.opacity ?? 0) > 0
        radius: width / 2
        blur: 8
        color: Qt.alpha(root.control.color, 0.8 * (Theme.glow.opacity ?? 0))
    }

    // Bezel.
    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        gradient: Gradient {
            GradientStop { position: 0; color: root.control.selected ? Theme.palette.fg : Theme.palette.shadow }
            GradientStop { position: 1; color: root.control.selected ? Theme.palette.dim : Qt.lighter(Theme.palette.border, 1.2) }
        }
    }
    // Jewel.
    Rectangle {
        id: jewel

        anchors {
            fill: parent
            margins: 2.5
        }
        radius: Math.min(width, height) / 2
        readonly property color c: root.control.hovered || root.control.selected ? Qt.lighter(root.control.color, 1.12) : root.control.color
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(jewel.c, 1.35) }
            GradientStop { position: 0.6; color: jewel.c }
            GradientStop { position: 1; color: Qt.darker(jewel.c, 1.5) }
        }
    }
    // Light on the dome.
    Rectangle {
        x: root.width * 0.28
        y: root.height * 0.2
        width: Math.min(root.width * 0.32, 8)
        height: root.height * 0.2
        radius: height / 2
        color: Qt.alpha("white", 0.45)
    }
    C.StyledText {
        anchors.centerIn: parent
        text: root.control.text
        color: Theme.palette.shadow
        font.pixelSize: Theme.font.size - 3
        font.bold: true
        visible: text !== ""
    }
}
