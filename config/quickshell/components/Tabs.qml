import QtQuick
import QtQuick.Layouts

// Tab strip of equal-width tabs; click one to make it `current`.
Skinned {
    id: root

    property var tabs: []  // labels
    property int current: 0
    property int hovered: -1
    readonly property real tabWidth: width / Math.max(1, tabs.length)

    skin: "Tabs"
    Layout.fillWidth: true

    Repeater {
        model: root.tabs

        MouseArea {
            required property int index

            x: index * root.tabWidth
            width: root.tabWidth
            height: root.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = index
            onExited: {
                if (root.hovered === index)
                    root.hovered = -1;
            }
            onClicked: root.current = index
        }
    }
}
