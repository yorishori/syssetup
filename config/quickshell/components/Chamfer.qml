import QtQuick
import QtQuick.Shapes
import qs.core

// Box with 45-degree cut corners, the basic retro-futurist shape. Pick which
// corners are cut; the hairline outline is optional.
Shape {
    id: root

    property int cut: Config.shape.cut
    property color fill: Config.colors.bg
    property color stroke: "transparent"
    property real strokeWidth: Config.shape.border
    property bool cutTopLeft: true
    property bool cutTopRight: false
    property bool cutBottomRight: true
    property bool cutBottomLeft: false

    // Corner sizes, and a half-pixel inset so hairlines stay crisp and inside.
    readonly property real c: Math.max(0, Math.min(cut, width / 2, height / 2))
    readonly property real i: stroke.a > 0 ? strokeWidth / 2 : 0

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeColor: root.stroke
        strokeWidth: root.stroke.a > 0 ? root.strokeWidth : -1
        joinStyle: ShapePath.MiterJoin

        startX: root.i + (root.cutTopLeft ? root.c : 0)
        startY: root.i

        PathLine { x: root.width - root.i - (root.cutTopRight ? root.c : 0); y: root.i }
        PathLine { x: root.width - root.i; y: root.i + (root.cutTopRight ? root.c : 0) }
        PathLine { x: root.width - root.i; y: root.height - root.i - (root.cutBottomRight ? root.c : 0) }
        PathLine { x: root.width - root.i - (root.cutBottomRight ? root.c : 0); y: root.height - root.i }
        PathLine { x: root.i + (root.cutBottomLeft ? root.c : 0); y: root.height - root.i }
        PathLine { x: root.i; y: root.height - root.i - (root.cutBottomLeft ? root.c : 0) }
        PathLine { x: root.i; y: root.i + (root.cutTopLeft ? root.c : 0) }
        PathLine { x: root.i + (root.cutTopLeft ? root.c : 0); y: root.i }
    }
}
