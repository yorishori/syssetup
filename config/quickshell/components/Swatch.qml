import QtQuick

// One pickable color; `selected` marks the current one, `text` an optional
// label on it (e.g. its number in a list).
Skinned {
    id: root

    property color color
    property bool selected: false
    property string text: ""
    readonly property bool hovered: area.containsMouse

    signal clicked

    skin: "Swatch"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
