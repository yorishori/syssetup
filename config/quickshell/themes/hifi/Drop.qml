import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar as B

// What opens below the panel: a hinged door with its controls on the inside,
// or, for the drops the Spec lists as drawers (layout.drawers), a drawer.
//
// The door swings down from where it's folded up under the panel, comes past
// hanging straight and settles; it's lifted back briskly. A piano hinge runs
// along its top; while it swings, its face turns from the light and darkens.
//
// The drawer is another device pulled out from under the panel: a console in
// a walnut case, its faceplate black matte powder coat. It slides out on its
// runners, everything on it coming out with it, and is pushed back in; a
// pull handle on its wooden front rail.
//
// The door is steel, with screws at its bottom corners.
Item {
    id: root

    required property B.Drop control

    readonly property bool drawer: (Theme.values.layout?.drawers ?? []).includes(control.name)

    readonly property real overhang: 0
    readonly property real inset: 0
    readonly property real popScale: 1

    // The door: folded up (90) to hanging (0).
    property real swing: drawer ? 0 : 90
    // The drawer: how far out it is, 0-1.
    property real out: 0

    readonly property real shownHeight: drawer ? control.openHeight * out : swing < 89.5 ? control.openHeight : 0
    readonly property real contentShift: drawer ? shownHeight - control.openHeight : 0
    // The door's face, and what's on it, turning from the light as it swings.
    readonly property real contentOpacity: 1 - 0.6 * swing / 90

    clip: drawer

    Component.onCompleted: {
        swing = drawer || control.open ? 0 : 90;
        out = drawer && control.open ? 1 : 0;
    }
    Connections {
        target: root.control

        function onOpenChanged(): void {
            for (const a of [dropDoor, liftDoor, pullOut, pushIn])
                a.stop();
            if (root.drawer)
                (root.control.open ? pullOut : pushIn).start();
            else
                (root.control.open ? dropDoor : liftDoor).start();
        }
    }
    NumberAnimation {
        id: dropDoor

        target: root
        property: "swing"
        to: 0
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.4
    }
    NumberAnimation {
        id: liftDoor

        target: root
        property: "swing"
        to: 90
        duration: 230
        easing.type: Easing.InCubic
    }
    // Out on its runners, stopping against the end stop with a little give.
    NumberAnimation {
        id: pullOut

        target: root
        property: "out"
        to: 1
        duration: 380
        easing.type: Easing.OutBack
        easing.overshoot: 0.6
    }
    NumberAnimation {
        id: pushIn

        target: root
        property: "out"
        to: 0
        duration: 240
        easing.type: Easing.InCubic
    }

    // Its shadow on what's below.
    RectangularShadow {
        anchors {
            fill: parent
            topMargin: 14
        }
        visible: !root.drawer
        radius: plate.radius
        offset.y: 6
        blur: 18
        color: Qt.alpha(Theme.palette.shadow, Math.min(1, (Theme.values.effects?.shadow ?? 0) * 1.2))
        opacity: 1 - root.swing / 90
    }

    // The plate; a drawer's slides with it.
    Item {
        id: body

        y: root.contentShift
        width: root.width
        height: root.control.openHeight

        Metal {
            id: plate

            anchors.fill: parent
            squareTop: true
            visible: !root.drawer
        }

        // The drawer's case: walnut cheeks either side, the grain running
        // their length, and a front rail; the faceplate set into it.
        Item {
            anchors.fill: parent
            visible: root.drawer

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("wood.png")
                fillMode: Image.Tile
            }
            Repeater {
                model: [0, 1]

                Item {
                    required property int modelData

                    x: modelData ? parent.width - width : 0
                    width: 12
                    height: parent.height
                    clip: true

                    Image {
                        x: 12
                        width: parent.height
                        height: 96
                        rotation: 90
                        transformOrigin: Item.TopLeft
                        source: Qt.resolvedUrl("wood.png")
                        fillMode: Image.Tile
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "#1c0f07"
            }

            // The faceplate.
            Rectangle {
                id: faceplate

                x: 12
                width: parent.width - 24
                height: parent.height - 16
                border.width: 1
                border.color: "#050506"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#1b1b1e" }
                    GradientStop { position: 1; color: "#111113" }
                }

                Image {
                    anchors {
                        fill: parent
                        margins: 1
                    }
                    source: Qt.resolvedUrl("coat.png")
                    fillMode: Image.Tile
                }
            }
            // The rail's top edge, catching the light.
            Rectangle {
                x: 12
                y: faceplate.height
                width: faceplate.width
                height: 1
                color: Qt.alpha("#e0b48a", 0.35)
            }
        }

        // The door's piano hinge.
        Item {
            width: parent.width
            height: 8
            visible: !root.drawer

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.7) }
                    GradientStop { position: 0.5; color: Theme.palette.border }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.8) }
                }
            }
            Row {
                anchors.fill: parent

                Repeater {
                    model: Math.max(0, Math.ceil(parent.width / 24))

                    Rectangle {
                        required property int index

                        width: 24
                        height: 8
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha("black", index % 2 ? 0.5 : 0.25)
                    }
                }
            }
        }

        // The drawer's pull handle, along its front edge.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 13
            width: 90
            height: 9
            visible: root.drawer

            RectangularShadow {
                anchors.fill: parent
                radius: 4.5
                offset.y: 3
                blur: 4
                color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
            }
            Rectangle {
                anchors.fill: parent
                radius: 4.5
                border.width: 1
                border.color: Theme.palette.shadow
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(Theme.palette.fg, 1.1) }
                    GradientStop { position: 0.45; color: Theme.palette.dim }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.dim, 1.8) }
                }
            }
        }

        Screw {
            x: 5
            y: parent.height - height - 5
            visible: !root.drawer && parent.height > 40 && (Theme.values.effects?.screws ?? true)
            angle: 60
        }
        Screw {
            x: parent.width - width - 5
            y: parent.height - height - 5
            visible: !root.drawer && parent.height > 40 && (Theme.values.effects?.screws ?? true)
            angle: -15
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.6 * root.swing / 90
        }
    }

    // The panel's lip throws its shadow onto the drawer as it comes out.
    Rectangle {
        width: parent.width
        height: Math.min(10, parent.height)
        visible: root.drawer
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.palette.shadow, 0.65) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
