import QtQuick
import QtQuick.Shapes
import qs.core

// A drawer growing out of the bottom screen edge: the bar's drops upside
// down. Angled shoulders flare into the edge, top corners are cut, the
// hairline runs around it. Place it with its bottom on the screen edge; it
// unrolls upward when `open`. Content goes in as children.
Item {
    id: root

    property bool open: false
    property int padding: 14
    property int shoulder: 10

    default property alias content: body.data

    readonly property real openHeight: body.childrenRect.height + 2 * padding

    implicitWidth: body.childrenRect.width + 2 * padding
    height: open ? openHeight : 0
    visible: height > 0

    Behavior on height {
        NumberAnimation {
            duration: root.open ? 300 : 150
            easing.type: root.open ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 0.9
        }
    }

    Shape {
        id: housing

        readonly property real s: Math.min(root.shoulder, root.height)
        readonly property real c: Math.min(Config.shape.cut * 2, root.height / 2)
        readonly property real h: root.height

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Config.colors.bg
            strokeWidth: -1

            startX: -housing.s
            startY: housing.h

            PathLine { x: 0; y: housing.h - housing.s }
            PathLine { x: 0; y: housing.c }
            PathLine { x: housing.c; y: 0 }
            PathLine { x: root.width - housing.c; y: 0 }
            PathLine { x: root.width; y: housing.c }
            PathLine { x: root.width; y: housing.h - housing.s }
            PathLine { x: root.width + housing.s; y: housing.h }
            PathLine { x: -housing.s; y: housing.h }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Config.colors.border
            strokeWidth: Config.shape.border
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap

            startX: -housing.s
            startY: housing.h - 0.5

            PathLine { x: 0.5; y: housing.h - housing.s }
            PathLine { x: 0.5; y: housing.c }
            PathLine { x: housing.c; y: 0.5 }
            PathLine { x: root.width - housing.c; y: 0.5 }
            PathLine { x: root.width - 0.5; y: housing.c }
            PathLine { x: root.width - 0.5; y: housing.h - housing.s }
            PathLine { x: root.width + housing.s; y: housing.h - 0.5 }
        }
    }

    Item {
        anchors {
            fill: parent
            topMargin: housing.c
            leftMargin: 1
            rightMargin: 1
        }
        clip: true

        Scanlines {
            anchors.fill: parent
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: body

            x: root.padding
            y: root.padding
            width: root.width - 2 * root.padding
            opacity: root.open ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: root.open ? 180 : 60 }
            }
        }
    }
}
