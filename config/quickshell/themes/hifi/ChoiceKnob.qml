import QtQuick
import QtQuick.Effects
import qs.core

// A rotary selector: a pointer knob, its positions printed round it.
Item {
    id: sel

    property var options: []  // [{ label, value }]
    property var current
    property real spread: Math.min(150, 46 * (options.length - 1))
    property real reach: 64
    readonly property int index: Math.max(0, options.findIndex(o => o.value === current))

    signal picked(var value)

    function angleOf(i: int): real {
        return options.length > 1 ? -spread / 2 + i * spread / (options.length - 1) : 0;
    }
    function step(by: int): void {
        const i = Math.max(0, Math.min(options.length - 1, index + by));
        if (i !== index)
            picked(options[i].value);
    }

    width: 2 * reach + 70
    height: reach + 50

    readonly property real cx: width / 2
    readonly property real cy: reach + 12

    // The positions, ticks and names.
    Repeater {
        model: sel.options

        Item {
            id: position

            required property var modelData
            required property int index
            readonly property real a: sel.angleOf(index) * Math.PI / 180
            readonly property bool on: sel.index === index

            Rectangle {
                x: sel.cx + (sel.reach - 26) * Math.sin(position.a) - width / 2
                y: sel.cy - (sel.reach - 26) * Math.cos(position.a) - height / 2
                width: 2
                height: 7
                rotation: sel.angleOf(position.index)
                color: Theme.values.display?.silk ?? Theme.palette.dim
            }
            Silk {
                id: name

                x: sel.cx + sel.reach * Math.sin(position.a) - width / 2
                y: sel.cy - sel.reach * Math.cos(position.a) - height / 2
                text: position.modelData.label
                color: position.on ? Theme.palette.fg : Theme.values.display?.silk ?? Theme.palette.dim
                font.pixelSize: 9

                MouseArea {
                    anchors {
                        fill: parent
                        margins: -6
                    }
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sel.picked(position.modelData.value)
                }
            }
        }
    }
    // The knob.
    Item {
        x: sel.cx - 25
        y: sel.cy - 25
        width: 50
        height: 50

        RectangularShadow {
            anchors.fill: parent
            radius: 25
            offset.y: 3
            blur: 8
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0.6)
        }
        Rectangle {
            anchors.fill: parent
            radius: 25
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(Theme.palette.surface, 1.35) }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.6) }
            }
        }
        // The pointer, a bar across it with a white line to the position.
        Item {
            anchors.fill: parent
            rotation: sel.angleOf(sel.index)

            Behavior on rotation {
                NumberAnimation { duration: 180; easing.type: Easing.OutBack }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -6
                width: 18
                height: 62
                radius: 9
                border.width: 1
                border.color: Theme.palette.shadow
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.darker(Theme.palette.surface, 1.3) }
                    GradientStop { position: 0.5; color: Qt.lighter(Theme.palette.surface, 1.5) }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.5) }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -3
                width: 2
                height: 18
                color: Theme.palette.fg
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sel.step(sel.index === sel.options.length - 1 ? -sel.index : 1)
        }
    }
    WheelHandler {
        onWheel: event => sel.step(event.angleDelta.y > 0 ? -1 : 1)
    }
}
