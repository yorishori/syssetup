import QtQuick
import QtQuick.Shapes
import qs.components as C
import qs.core

// The bar's drops upside down: angled shoulders flare into the screen edge,
// top corners are cut, the hairline runs around it. Unrolls with a spring.
Item {
    id: root

    required property C.BottomDrawer control

    readonly property int shoulder: 10
    readonly property real overhang: shoulder
    property real shownHeight: control.open ? control.openHeight : 0
    property real contentOpacity: control.open ? 1 : 0

    Behavior on shownHeight {
        NumberAnimation {
            duration: root.control.open ? 300 : 150
            easing.type: root.control.open ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 0.9
        }
    }
    Behavior on contentOpacity {
        NumberAnimation { duration: root.control.open ? 180 : 60 }
    }

    Shape {
        id: housing

        readonly property real s: Math.min(root.shoulder, root.height)
        readonly property real c: Math.min(Theme.values.shape.cut * 2, root.height / 2)
        readonly property real h: root.height

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.palette.bg
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
            strokeColor: Theme.palette.border
            strokeWidth: Theme.values.shape.border
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
}
