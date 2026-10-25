import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.launcher as M

// The MODE dial: a three-way rotary, the modes printed round it. Click it
// for the next, right click for the previous, scroll, or click a mode.
Item {
    id: dial

    required property M.LauncherPanel control
    property color silk: Theme.values.display?.silk ?? Theme.palette.dim

    readonly property int index: control.modes.indexOf(control.mode)
    readonly property var angles: [-58, 0, 58]
    property real angle: angles[Math.max(0, index)]

    width: 168
    height: 66

    Behavior on angle {
        SpringAnimation { spring: 6; damping: 0.45; epsilon: 0.2 }
    }

    // The modes, each by its stop.
    Repeater {
        model: control.modes

        Item {
            id: stop

            required property int index
            required property string modelData
            readonly property real a: dial.angles[index] * Math.PI / 180

            Rectangle {
                x: dial.width / 2 + Math.sin(stop.a) * 24 - 1.5
                y: 42 - Math.cos(stop.a) * 24 - 1.5
                width: 3
                height: 3
                radius: 1.5
                color: Qt.alpha(Theme.palette.fg, 0.4)
            }
            C.StyledText {
                id: name

                x: stop.index === 0 ? dial.width / 2 - 30 - width
                    : stop.index === 2 ? dial.width / 2 + 30
                    : (dial.width - width) / 2
                y: stop.index === 1 ? 0 : 14
                text: stop.modelData === "windows" ? `windows ${control.windowCount}` : stop.modelData
                caps: true
                color: silk
                font.pixelSize: 9
                font.bold: true
                tracking: 1

                MouseArea {
                    anchors {
                        fill: parent
                        margins: -4
                    }
                    cursorShape: Qt.PointingHandCursor
                    onClicked: control.setMode(stop.modelData)
                }
            }
        }
    }
    // The knob.
    Item {
        x: (dial.width - 34) / 2
        y: 25
        width: 34
        height: 34

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: 2
            blur: 4
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: knobArea.containsMouse ? Qt.lighter(Theme.palette.surface, 1.6) : Qt.lighter(Theme.palette.surface, 1.3) }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.7) }
            }
        }
        Item {
            anchors.fill: parent
            rotation: dial.angle

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 3
                width: 3
                height: 12
                radius: 1.5
                color: Theme.palette.fg
            }
        }

        MouseArea {
            id: knobArea

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => control.switchTab(mouse.button === Qt.RightButton ? -1 : 1)
            onWheel: wheel => control.switchTab(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
