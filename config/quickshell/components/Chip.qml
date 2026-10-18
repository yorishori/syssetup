import QtQuick

// An on/off toggle with a short label (e.g. a notification source, muted or
// not). Emits clicked; the owner flips it.
Skinned {
    id: root

    property string text
    property bool on: true
    readonly property bool hovered: area.containsMouse

    signal clicked

    skin: "Chip"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
