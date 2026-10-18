import QtQuick
import qs.core

// Glyph key (Nerd Font). `lit` latches it on (e.g. play/pause, the active
// tool).
Skinned {
    id: root

    property string icon
    property color iconColor: Theme.palette.fg
    property bool lit: false
    property int size: 28
    property real iconRotation: 0  // rotates only the glyph, not the key
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    signal clicked

    skin: "IconButton"
    implicitWidth: size
    implicitHeight: size

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
