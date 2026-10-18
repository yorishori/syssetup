import QtQuick

// A key with a text label. `lit` latches it on (e.g. the active mode).
Skinned {
    id: root

    property string text
    property bool lit: false
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    signal clicked

    skin: "TextButton"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
