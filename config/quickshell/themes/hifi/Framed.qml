import QtQuick
import qs.core

// A section of a faceplate, outlined in silkscreen with its `name` printed
// in the corner. What it holds goes inside, `pad` in from the outline.
Item {
    id: root

    property string name
    default property alias content: inner.data
    readonly property real pad: 14

    implicitWidth: inner.childrenRect.width + 2 * pad
    implicitHeight: inner.childrenRect.height + 2 * pad + (name ? 18 : 0)

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.values.display?.silk ?? Theme.palette.dim, 0.55)
    }
    Silk {
        x: root.pad
        y: 9
        text: root.name
        visible: root.name !== ""
    }
    Item {
        id: inner

        x: root.pad
        y: root.pad + (root.name ? 18 : 0)
        width: root.width - 2 * root.pad
    }
}
