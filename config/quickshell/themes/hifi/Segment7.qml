import QtQuick
import QtQuick.Shapes

// One seven-segment digit, `digit` 0-9 (-1 blank). Lit segments in `color`;
// the unlit ones stay faintly visible behind the glass, as on a real display.
// Size it with width and height; `thickness` is the segments'.
Item {
    id: root

    property int digit: -1
    property color color: "red"
    property real thickness: Math.max(2, width * 0.2)
    readonly property color ghost: Qt.alpha(color, 0.09)

    // Which segments each digit lights: a b c d e f g.
    readonly property var masks: [0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f]
    readonly property int mask: digit >= 0 && digit <= 9 ? masks[digit] : 0

    readonly property real t: thickness
    readonly property real g: t * 0.22  // gap between segments
    readonly property real w: width
    readonly property real h: height

    function lit(segment: int): color {
        return mask & (1 << segment) ? color : ghost;
    }
    // A horizontal segment at y0, and a vertical one at x0 between y0 and y1.
    function across(y0: real): var {
        const x0 = t / 2 + g, x1 = w - t / 2 - g;
        return [Qt.point(x0, y0 + t / 2), Qt.point(x0 + t / 2, y0), Qt.point(x1 - t / 2, y0),
                Qt.point(x1, y0 + t / 2), Qt.point(x1 - t / 2, y0 + t), Qt.point(x0 + t / 2, y0 + t),
                Qt.point(x0, y0 + t / 2)];
    }
    function down(x0: real, y0: real, y1: real): var {
        return [Qt.point(x0 + t / 2, y0), Qt.point(x0 + t, y0 + t / 2), Qt.point(x0 + t, y1 - t / 2),
                Qt.point(x0 + t / 2, y1), Qt.point(x0, y1 - t / 2), Qt.point(x0, y0 + t / 2),
                Qt.point(x0 + t / 2, y0)];
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath { strokeWidth: -1; fillColor: root.lit(0); PathPolyline { path: root.across(0) } }
        ShapePath { strokeWidth: -1; fillColor: root.lit(1); PathPolyline { path: root.down(root.w - root.t, root.t / 2 + root.g, root.h / 2 - root.g) } }
        ShapePath { strokeWidth: -1; fillColor: root.lit(2); PathPolyline { path: root.down(root.w - root.t, root.h / 2 + root.g, root.h - root.t / 2 - root.g) } }
        ShapePath { strokeWidth: -1; fillColor: root.lit(3); PathPolyline { path: root.across(root.h - root.t) } }
        ShapePath { strokeWidth: -1; fillColor: root.lit(4); PathPolyline { path: root.down(0, root.h / 2 + root.g, root.h - root.t / 2 - root.g) } }
        ShapePath { strokeWidth: -1; fillColor: root.lit(5); PathPolyline { path: root.down(0, root.t / 2 + root.g, root.h / 2 - root.g) } }
        ShapePath { strokeWidth: -1; fillColor: root.lit(6); PathPolyline { path: root.across(root.h / 2 - root.t / 2) } }
    }
}
