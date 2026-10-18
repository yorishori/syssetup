import QtQuick
import qs.components

// One big session key. `armed`: waiting for confirmation; a 3 s fuse burns
// down (`fuse`, 1 to 0) and fused() fires when it runs out.
Skinned {
    id: root

    property string label
    property string glyph
    property int number
    property bool current: false
    property bool armed: false
    property real fuse: 1
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    signal clicked
    signal fused

    skin: "SessionKey"
    implicitHeight: 76

    NumberAnimation on fuse {
        running: root.armed
        from: 1
        to: 0
        duration: 3000
        onFinished: {
            if (root.armed)
                root.fused();
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
