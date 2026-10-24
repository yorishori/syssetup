import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.capture as M

// An enlarging easel. The room is under the safelight: everything but the
// area is in its deep red. Four steel masking blades frame the area, a
// ruler printed along each inner edge in the screen's pixels; hovering a
// window slides them to it, dragging pulls them out by hand. A plate along
// the front edge gives the size and how to choose; recording, a red lamp.
Item {
    id: root

    required property M.Selection control

    readonly property real blade: 30
    // The opening: the area, or with nothing chosen, the whole screen (the
    // blades parked off its edges).
    readonly property rect r: control.hasArea ? control.area : Qt.rect(0, 0, width, height)
    readonly property bool still: !control.moving
    property real edgeL: r.x
    property real edgeR: r.x + r.width
    property real edgeT: r.y
    property real edgeB: r.y + r.height

    Behavior on edgeL { enabled: root.still; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on edgeR { enabled: root.still; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on edgeT { enabled: root.still; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on edgeB { enabled: root.still; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    // The safelight, outside the opening.
    component Safelight: Rectangle {
        color: "#2b0503"
        opacity: 0.7
    }
    Safelight { width: parent.width; height: root.edgeT }
    Safelight { y: root.edgeB; width: parent.width; height: parent.height - y }
    Safelight { y: root.edgeT; width: root.edgeL; height: root.edgeB - root.edgeT }
    Safelight { x: root.edgeR; y: root.edgeT; width: parent.width - x; height: root.edgeB - root.edgeT }

    // A blade, across the opening and over the others at the corners, its
    // ruler (in the screen's pixels) on the edge toward the opening
    // (`inner`: 0 its top or left, 1 its bottom or right).
    component Blade: Item {
        id: bladeItem

        property bool across: true
        property int inner: 0

        x: across ? root.edgeL - root.blade : 0
        y: across ? 0 : root.edgeT - root.blade
        width: across ? root.edgeR - root.edgeL + 2 * root.blade : root.blade
        height: across ? root.blade : root.edgeB - root.edgeT + 2 * root.blade

        RectangularShadow {
            anchors.fill: parent
            offset: Qt.vector2d(0, 3)
            blur: 10
            color: Qt.alpha("black", 0.6)
        }
        Rectangle {
            anchors.fill: parent
            border.width: 1
            border.color: "#1b1c1f"
            gradient: Gradient {
                orientation: bladeItem.across ? Gradient.Vertical : Gradient.Horizontal
                GradientStop { position: 0; color: "#a7aab0" }
                GradientStop { position: 0.5; color: "#c9ccd1" }
                GradientStop { position: 1; color: "#8c8f95" }
            }
        }
        // The ruler's printed the length of the screen; the blade shows
        // its stretch of it.
        Item {
            anchors.fill: parent
            clip: true

            Canvas {
                x: bladeItem.across ? -bladeItem.x : 0
                y: bladeItem.across ? 0 : -bladeItem.y
                width: bladeItem.across ? root.width : root.blade
                height: bladeItem.across ? root.blade : root.height
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = "#1d1d20";
                    ctx.font = `bold 9px "${Theme.font.family}"`;
                    const length = bladeItem.across ? width : height;
                    const edge = bladeItem.inner ? root.blade : 0;
                    const sign = bladeItem.inner ? -1 : 1;
                    for (let p = 0; p <= length; p += 10) {
                        const tick = p % 100 === 0 ? 11 : p % 50 === 0 ? 7 : 4;
                        const a = edge + (sign < 0 ? -tick : 0);
                        if (bladeItem.across)
                            ctx.fillRect(p, a, 1, tick);
                        else
                            ctx.fillRect(a, p, tick, 1);
                        if (p % 100 === 0 && p > 0) {
                            const at = edge + sign * 20;
                            if (bladeItem.across)
                                ctx.fillText(p, p + 3, at + 3);
                            else {
                                ctx.save();
                                ctx.translate(at - 3, p + 3);
                                ctx.rotate(Math.PI / 2);
                                ctx.fillText(p, 0, 0);
                                ctx.restore();
                            }
                        }
                    }
                }
            }
        }
    }
    // The side blades under, the top and bottom over them.
    Blade { across: false; inner: 1; x: root.edgeL - root.blade }
    Blade { across: false; inner: 0; x: root.edgeR }
    Blade { inner: 1; y: root.edgeT - root.blade }
    Blade { inner: 0; y: root.edgeB }

    // The front plate: the size, how to choose; the lamp, recording.
    Item {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 54
        }
        width: plate.width
        height: plate.height
        visible: !root.control.marking

        RectangularShadow {
            anchors.fill: parent
            radius: 4
            offset.y: 4
            blur: 14
            color: Qt.alpha("black", 0.7)
        }
        Metal {
            anchors.fill: parent
        }
        Row {
            id: plate

            padding: 10
            spacing: 14

            Led {
                anchors.verticalCenter: parent.verticalCenter
                size: 9
                on: true
                color: Theme.palette.error
                visible: root.control.kind !== "screenshot"
            }
            Readout {
                anchors.verticalCenter: parent.verticalCenter
                width: 104
                height: 22
                line1: `${Math.round(root.r.width)} × ${Math.round(root.r.height)}`
                size: 11
            }
            Silk {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.control.kind === "screenshot" ? "" : "record: ") + "click a window · drag a region · enter for the screen"
            }
        }
    }
}
