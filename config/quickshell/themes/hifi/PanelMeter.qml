import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.core

// A moving-coil panel meter: a cream face lit from behind, a printed arc
// with its red zone, the needle on its pivot. `value` 0-1.
Item {
    id: root

    readonly property color inkColor: "#2a2119"

    property real value: 0
    property string name
    property string detail
    property string reading
    property bool hot: false
    readonly property point pivot: Qt.point(width / 2, height - 18)
    readonly property real reach: 78
    property real needle: -50 + 100 * Math.max(0, Math.min(1, value))

    width: 170
    height: 122

    Behavior on needle {
        SpringAnimation { spring: 2.2; damping: 0.18; epsilon: 0.05 }
    }

    // The case and the backlit face.
    Rectangle {
        anchors.fill: parent
        radius: 5
        color: "#0b0b0c"
        border.width: 1
        border.color: "black"
    }
    Rectangle {
        id: face

        anchors {
            fill: parent
            margins: 5
        }
        radius: 3
        gradient: Gradient {
            GradientStop { position: 0; color: "#f3e7c4" }
            GradientStop { position: 1; color: "#d9c79a" }
        }
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha("#7a4a10", 0.18) }
                GradientStop { position: 0.5; color: Qt.alpha("#fff3c8", 0.25) }
                GradientStop { position: 1; color: Qt.alpha("#7a4a10", 0.18) }
            }
        }
    }

    // The scale: an arc, ticks every tenth, the last stretch in red.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.inkColor
            strokeWidth: 1.2
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.pivot.x
                centerY: root.pivot.y
                radiusX: root.reach - 8
                radiusY: root.reach - 8
                startAngle: -140
                sweepAngle: 100 * 0.85
            }
        }
        ShapePath {
            strokeColor: "#c0281c"
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.pivot.x
                centerY: root.pivot.y
                radiusX: root.reach - 6
                radiusY: root.reach - 6
                startAngle: -140 + 85
                sweepAngle: 15
            }
        }
    }
    Repeater {
        model: 11

        Item {
            required property int index

            x: root.pivot.x
            y: root.pivot.y
            rotation: -50 + index * 10

            Rectangle {
                x: -0.6
                y: -root.reach + (parent.index % 5 === 0 ? 0 : 3)
                width: parent.index % 5 === 0 ? 1.6 : 1.2
                height: parent.index % 5 === 0 ? 10 : 6
                color: parent.index >= 9 ? "#c0281c" : root.inkColor
            }
        }
    }
    Repeater {
        model: [0, 50, 100]

        Text {
            required property int modelData
            readonly property real a: (-50 + modelData) * Math.PI / 180

            x: root.pivot.x + Math.sin(a) * (root.reach + 9) - width / 2
            y: root.pivot.y - Math.cos(a) * (root.reach + 9) - height / 2
            text: modelData
            color: root.inkColor
            font.family: Theme.font.family
            font.pixelSize: 8
        }
    }

    // What it reads.
    Text {
        anchors {
            left: parent.left
            leftMargin: 12
            bottom: parent.bottom
            bottomMargin: 8
        }
        text: root.name
        color: root.inkColor
        font.family: Theme.font.family
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 2
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pivot.y - 34
        width: parent.width - 60
        horizontalAlignment: Text.AlignHCenter
        text: root.detail
        elide: Text.ElideRight
        color: Qt.alpha(root.inkColor, 0.65)
        font.family: Theme.font.family
        font.pixelSize: 8
    }
    Text {
        anchors {
            right: parent.right
            rightMargin: 12
            bottom: parent.bottom
            bottomMargin: 9
        }
        text: root.reading
        color: root.hot ? "#c0281c" : root.inkColor
        font.family: Theme.font.family
        font.pixelSize: 9
        font.bold: true
    }

    // The needle and its pivot.
    Item {
        x: root.pivot.x
        y: root.pivot.y
        rotation: root.needle

        Rectangle {
            x: -1
            y: -root.reach + 2
            width: 2
            height: root.reach + 6
            radius: 1
            antialiasing: true
            color: "#1a1612"
        }
    }
    Rectangle {
        x: root.pivot.x - 7
        y: root.pivot.y - 7
        width: 14
        height: 14
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0; color: "#4a4b50" }
            GradientStop { position: 1; color: "#111113" }
        }
    }

    Gloss {
        anchors {
            fill: face
            margins: 1
        }
        roundness: 3
    }
}
