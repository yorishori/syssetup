import QtQuick
import QtQuick.Layouts
import qs.core

// Stencilled tab strip; a lamp slides under the current tab.
Item {
    id: root

    property var tabs: []  // labels
    property int current: 0
    readonly property real tabWidth: width / Math.max(1, tabs.length)

    Layout.fillWidth: true
    implicitHeight: 26

    Repeater {
        model: root.tabs

        Item {
            id: tab

            required property int index
            required property string modelData
            readonly property bool active: root.current === index

            x: index * root.tabWidth
            width: root.tabWidth
            height: root.height - 3

            StyledText {
                anchors.centerIn: parent
                text: tab.modelData
                color: tab.active ? Config.colors.accent : area.containsMouse ? Config.colors.fg : Config.colors.dim
                glow: tab.active
                font.pixelSize: Config.font.size - 2
                font.bold: true
                font.letterSpacing: 1.5
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.current = tab.index
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Config.colors.border
    }

    Rectangle {
        x: root.current * root.tabWidth + 12
        anchors.bottom: parent.bottom
        width: root.tabWidth - 24
        height: 2
        color: Config.colors.accent

        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack }
        }
    }
}
