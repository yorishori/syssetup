import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// The service hatch: a pull handle set into a pocket, printed SERVICE. Pull
// it to open the control center; it stays out while that's open.
Item {
    id: root

    required property W.ControlButton control
    readonly property bool pulled: control.active || control.pressed

    implicitWidth: 52
    implicitHeight: 40

    Well {
        id: pocket

        width: parent.width
        height: 26
        roundness: 4
        fill: Qt.darker(Theme.palette.bg, 1.6)
    }

    // The handle: a bar on two posts, coming toward you when pulled.
    Item {
        anchors.centerIn: pocket
        anchors.verticalCenterOffset: root.pulled ? 2 : 0
        width: 34
        height: 9
        scale: root.pulled ? 1.08 : 1

        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: 4.5
            offset.y: root.pulled ? 5 : 2
            blur: root.pulled ? 8 : 3
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
        }
        Repeater {
            model: [3, 27]

            Rectangle {
                required property real modelData

                x: modelData
                y: 1
                width: 4
                height: 7
                radius: 1
                color: Qt.darker(Theme.palette.border, 1.8)
            }
        }
        Rectangle {
            id: bar

            readonly property color c: root.control.hovered || root.pulled ? Theme.palette.fg : Theme.palette.dim

            width: parent.width
            height: 7
            radius: 3.5
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(bar.c, 1.15) }
                GradientStop { position: 0.45; color: bar.c }
                GradientStop { position: 1; color: Qt.darker(bar.c, 1.8) }
            }
        }
    }

    Legend {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: "service"
        color: root.control.active ? Theme.palette.accent : root.control.hovered ? Theme.palette.fg : Theme.palette.dim
    }
}
