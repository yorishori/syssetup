import QtQuick
import QtQuick.Effects
import qs.core

// A jukebox selector key: an ivory cap, the same stock as the strips,
// in a chrome bezel. It goes in when pressed; `lit`, it's held in and
// the bulbs behind it light its edges. Dead when not `live`.
Item {
    id: key

    required property color card
    required property color ink

    property string icon
    property real glyphSize: 15
    property bool live: true
    property bool lit: false
    readonly property bool down: lit || keyArea.pressed

    signal clicked(int modifiers)

    opacity: live || lit ? 1 : 0.45

    // The bezel.
    Rectangle {
        anchors.fill: parent
        radius: 4
        border.width: 1
        border.color: "black"
        gradient: Gradient {
            GradientStop { position: 0; color: "#eceef1" }
            GradientStop { position: 0.4; color: "#86888e" }
            GradientStop { position: 0.65; color: "#c6c8cd" }
            GradientStop { position: 1; color: "#4c4e53" }
        }
    }
    Rectangle {
        id: pit

        anchors {
            fill: parent
            margins: 3
        }
        radius: 2
        color: "#0c0b0a"
    }
    RectangularShadow {
        anchors.fill: cap
        radius: 2
        blur: 8
        spread: 1
        color: Qt.alpha("#ffb85c", 0.8)
        visible: key.lit
    }
    // The cap, standing proud of the bezel until it's pushed in.
    Rectangle {
        id: cap

        x: pit.x + 2
        y: pit.y + 1 + (key.down ? 2 : 0)
        width: pit.width - 4
        height: pit.height - 4
        radius: 2
        border.width: 1
        border.color: Qt.darker(card, 1.9)
        gradient: Gradient {
            GradientStop { position: 0; color: key.lit ? "#fff1cf" : keyArea.containsMouse && key.live ? Qt.lighter(card, 1.06) : card }
            GradientStop { position: 0.8; color: key.lit ? "#ffd48a" : Qt.darker(card, key.down ? 1.12 : 1.05) }
            GradientStop { position: 1; color: Qt.darker(card, key.down ? 1.25 : 1.4) }
        }

        Behavior on y {
            NumberAnimation { duration: 60 }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: key.icon
            color: ink
            font.family: Theme.font.family
            font.pixelSize: key.glyphSize
        }
    }

    MouseArea {
        id: keyArea

        anchors.fill: parent
        enabled: key.live
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => key.clicked(mouse.modifiers)
    }
}
