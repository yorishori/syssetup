import QtQuick
import qs.components

// A small compartment in the bar that groups related items (tray icons,
// recording indicators). `tone` colors it when it calls for attention.
Skinned {
    id: root

    property color tone: "transparent"
    property int padding: 7
    default property alias content: row.data

    skin: "BarBox"
    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: 22

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8
    }
}
