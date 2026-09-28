import QtQuick
import qs.core

// Glyph key (Nerd Font). Transparent until hovered; `lit` makes it a filled,
// glowing accent key (e.g. play/pause).
Item {
    id: root

    property string icon
    property color iconColor: Config.colors.fg
    property bool lit: false
    property int size: 28
    property real iconRotation: 0  // rotates only the glyph, not the key

    signal clicked

    implicitWidth: size
    implicitHeight: size
    scale: area.pressed ? 0.9 : 1

    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutBack }
    }

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: root.lit ? Config.colors.accent : area.containsMouse ? Config.colors.surface : "transparent"
    }

    StyledText {
        anchors.centerIn: parent
        text: root.icon
        color: root.lit ? Config.colors.shadow : root.iconColor
        rotation: root.iconRotation
        font.bold: true
        font.pixelSize: Math.round(root.size * 0.55)
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
