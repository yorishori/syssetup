import QtQuick
import qs.components

// One day in the month grid. `lamps`: the colors of the calendars with
// events that day (at most 3). Click selects it.
Skinned {
    id: root

    property date day
    property bool isToday: false
    property bool selected: false
    property bool inMonth: true
    property var lamps: []
    readonly property bool weekend: day.getDay() === 0 || day.getDay() === 6
    readonly property bool hovered: area.containsMouse

    signal clicked

    skin: "CalendarDay"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
