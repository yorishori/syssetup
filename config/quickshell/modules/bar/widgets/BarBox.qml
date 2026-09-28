import QtQuick
import qs.components
import qs.core

// A small outlined compartment in the bar that groups related items (tray
// icons, recording indicators), like a recessed panel on a console.
Item {
    id: root

    property color stroke: Config.colors.border
    property int padding: 7
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: 22

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: Config.colors.bgAlt
        stroke: root.stroke
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8
    }
}
