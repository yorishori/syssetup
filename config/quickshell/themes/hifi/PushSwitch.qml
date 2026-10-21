import QtQuick
import QtQuick.Effects
import qs.core

// A latching push switch: a black cap in a chrome bezel. Pushed, it stays
// in, a ring lit round it, until what it started is done.
Item {
    id: root

    property bool latched: false
    property string icon
    readonly property bool down: latched || pushArea.pressed

    signal pushed

    width: 42
    height: 42

    RectangularShadow {
        anchors.fill: parent
        radius: width / 2
        offset.y: 2
        blur: 5
        color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        border.width: 1
        border.color: "black"
        gradient: Gradient {
            GradientStop { position: 0; color: "#eef0f3" }
            GradientStop { position: 0.45; color: "#85878d" }
            GradientStop { position: 0.7; color: "#cfd1d5" }
            GradientStop { position: 1; color: "#4a4c51" }
        }
    }
    // The ring, lit while it's held in.
    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: width / 2
        color: "#070707"
        border.width: 2
        border.color: root.latched ? Theme.palette.warn : Qt.alpha(Theme.palette.warn, 0.12)
    }
    RectangularShadow {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: width / 2
        blur: 8
        color: Qt.alpha(Theme.palette.warn, 0.5)
        visible: root.latched
        z: -1
    }
    Rectangle {
        anchors.centerIn: parent
        width: 26
        height: 26
        radius: width / 2
        scale: root.down ? 0.88 : 1
        border.width: 1
        border.color: "black"
        gradient: Gradient {
            GradientStop { position: 0; color: pushArea.containsMouse && !root.latched ? "#4c4e54" : "#3a3c41" }
            GradientStop { position: 1; color: root.down ? "#1a1b1e" : "#111214" }
        }

        Behavior on scale {
            NumberAnimation { duration: 70 }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: Qt.alpha(Theme.palette.fg, 0.7)
            font.family: Theme.font.family
            font.pixelSize: 12
        }
    }
    MouseArea {
        id: pushArea

        anchors.fill: parent
        enabled: !root.latched
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pushed()
    }
}
