import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components as C
import qs.core
import qs.modules.session as M

// Blast doors. Opening the session menu slams two steel doors shut over the
// whole screen from the sides, hazard-striped where they meet, the session
// buttons mounted on them (lock and shutdown on the left, reboot and sleep
// on the right). Arming shutdown or reboot brings spinning red sirens in
// from the corners while a third door comes down from the top over
// everything; the action runs when it's shut (the key's fuse). Cancelled,
// it goes back up and the sirens leave. Closing the menu opens the doors.
Item {
    id: root

    required property M.SessionPanel control

    // Whether any of it is still on screen (the window stays up until not).
    readonly property bool covering: shut > 0 || lid > 0.001 || sirens > 0.001

    readonly property color steel: "#3a3c42"
    readonly property color hazard: Theme.values.display?.hazard ?? Theme.palette.warn
    readonly property color alarm: Theme.palette.error
    readonly property real band: 140

    // The side doors: 0 open, 1 shut. `jolt` shakes everything when they slam.
    property real shut: 0
    property real jolt: 0

    // The top door follows the armed key's fuse down, and goes back up when
    // it's cancelled.
    readonly property M.SessionKey armedKey: control.armed < 0 ? null : control.armed < 2 ? leftKeys.itemAt(control.armed) : rightKeys.itemAt(control.armed - 2)
    readonly property real lid: armedKey ? 1 - armedKey.fuse : rising
    property real lastLid: 0
    property real rising: 0  // where it is while going back up
    property real sirens: control.armed >= 0 ? 1 : 0
    property real spin: 0

    onLidChanged: {
        if (armedKey)
            lastLid = lid;
    }
    Behavior on sirens {
        NumberAnimation { duration: 450; easing.type: root.sirens < 0.5 ? Easing.OutBack : Easing.InQuad }
    }

    NumberAnimation on spin {
        running: root.sirens > 0
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
    }

    NumberAnimation {
        id: rise

        target: root
        property: "rising"
        to: 0
        duration: 500
        easing.type: Easing.OutCubic
    }

    Connections {
        target: root.control

        function onArmedChanged(): void {
            if (root.control.armed >= 0) {
                rise.stop();
            } else {
                rise.from = root.lastLid;
                rise.start();
            }
        }

        function onOpenChanged(): void {
            if (root.control.open) {
                part.stop();
                slam.start();
            } else {
                slam.stop();
                part.start();
            }
        }
    }

    // Heavy doors: they gather speed and slam; the impact shakes them.
    SequentialAnimation {
        id: slam

        NumberAnimation { target: root; property: "shut"; to: 1; duration: 420; easing.type: Easing.InQuad }
        SequentialAnimation {
            NumberAnimation { target: root; property: "jolt"; to: 1; duration: 40 }
            NumberAnimation { target: root; property: "jolt"; to: -0.6; duration: 60 }
            NumberAnimation { target: root; property: "jolt"; to: 0.3; duration: 60 }
            NumberAnimation { target: root; property: "jolt"; to: 0; duration: 80 }
        }
    }
    NumberAnimation {
        id: part

        target: root
        property: "shut"
        to: 0
        duration: 380
        easing.type: Easing.InOutCubic
    }

    // The room darkening behind the doors as they close.
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.shadow
        opacity: 0.6 * root.shut
    }

    // Hazard stripes, over safety yellow, worn by the steel's grain; mirrored
    // on the right so the two bands make chevrons where they meet.
    component Hazard: Item {
        id: hazardBand

        property bool mirrored: false

        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(root.hazard, 1.08) }
                GradientStop { position: 1; color: Qt.darker(root.hazard, 1.25) }
            }
        }
        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("hazard.png")
            fillMode: Image.Tile
            transform: Scale {
                origin.x: hazardBand.width / 2
                xScale: hazardBand.mirrored ? -1 : 1
            }
        }
        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("brushed.png")
            fillMode: Image.Tile
            opacity: 0.5
        }
    }

    // A rivet: a little steel dome.
    component Rivet: Rectangle {
        width: 10
        height: 10
        radius: 5
        border.width: 1
        border.color: Qt.alpha("black", 0.7)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(root.steel, 1.9) }
            GradientStop { position: 1; color: Qt.darker(root.steel, 1.5) }
        }
    }

    // A door: a steel plate with a hazard band along its leading edge
    // (`leading`: which side meets the other door), and a rubber seal on it.
    component Door: Item {
        id: door

        property string leading: "right"
        readonly property bool horizontal: leading === "left" || leading === "right"

        Metal {
            anchors.fill: parent
            roundness: 0
            tint: root.steel
        }

        Hazard {
            x: door.leading === "right" ? door.width - width : 0
            y: door.leading === "bottom" ? door.height - height : 0
            width: door.horizontal ? root.band : door.width
            height: door.horizontal ? door.height : root.band
            mirrored: door.leading === "left"
        }
        // The band's raised edge, catching the light.
        Rectangle {
            x: door.leading === "right" ? door.width - root.band - 2 : door.leading === "left" ? root.band : 0
            y: door.leading === "bottom" ? door.height - root.band - 2 : 0
            width: door.horizontal ? 2 : door.width
            height: door.horizontal ? door.height : 2
            gradient: Gradient {
                orientation: door.horizontal ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: Qt.alpha("black", 0.6) }
                GradientStop { position: 1; color: Qt.alpha("white", 0.2) }
            }
        }
        // The seal.
        Rectangle {
            x: door.leading === "right" ? door.width - width : 0
            y: door.leading === "bottom" ? door.height - height : 0
            width: door.horizontal ? 7 : door.width
            height: door.horizontal ? door.height : 7
            color: "#0c0c0d"
        }

        // Rivets along the edges of the steel.
        Repeater {
            model: door.horizontal ? Math.max(0, Math.floor(door.height / 90)) : 0

            Item {
                required property int index

                x: door.leading === "right" ? 24 : door.width - 34
                y: 45 + index * 90
                width: 10
                height: 10

                Rivet {}
            }
        }
        Repeater {
            model: Math.max(0, Math.floor((door.width - (door.horizontal ? root.band : 0)) / 90))

            Item {
                required property int index

                x: (door.leading === "left" ? root.band : 0) + 45 + index * 90
                y: door.leading === "bottom" ? 24 : door.height - 34
                width: 10
                height: 10

                Rivet {}
            }
        }
    }

    // A session button, wired to the menu; `slot` is its action's index.
    component Button: M.SessionKey {
        id: button

        required property int modelData
        readonly property int slot: modelData
        readonly property var action: root.control.actions[slot]

        width: 220
        height: 222
        key: action.key
        label: action.label
        glyph: action.glyph
        number: slot + 1
        current: root.control.selected === slot
        armed: root.control.armed === slot
        onHoveredChanged: {
            if (hovered)
                root.control.hover(button.slot);
        }
        onClicked: root.control.activate(button.slot)
        onFused: root.control.execute(button.slot)
    }

    Item {
        id: stage

        width: root.width
        height: root.height
        y: root.jolt * 7

        // The left door, with lock and shutdown, and what this is.
        Door {
            id: leftDoor

            x: -width * (1 - root.shut)
            width: root.width / 2
            height: root.height
            leading: "right"

            Column {
                x: 70
                y: 70
                spacing: 8

                Legend {
                    text: "session"
                    size: 15
                }
                C.StyledText {
                    text: `${root.control.hostname} · up ${root.control.uptimeText}`
                    caps: true
                    tracking: 1
                    color: Theme.palette.dim
                    font.pixelSize: Theme.font.size
                }
            }

            Repeater {
                id: leftKeys

                model: [0, 1]

                Button {
                    x: (leftDoor.width - root.band - width) / 2
                    y: root.height / 2 - height - 115 + slot * (height + 230)
                }
            }
        }

        // The right door, with reboot and sleep, and how to drive it.
        Door {
            id: rightDoor

            x: root.width - width * root.shut
            width: root.width / 2
            height: root.height
            leading: "left"

            Repeater {
                id: rightKeys

                model: [2, 3]

                Button {
                    x: root.band + (rightDoor.width - root.band - width) / 2
                    y: root.height / 2 - height - 115 + (slot - 2) * (height + 230)
                }
            }

            Row {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 70
                    bottomMargin: 70
                }
                spacing: 14

                Repeater {
                    model: ["1-4 select", "↵ confirm", "esc cancel"]

                    Legend {
                        required property string modelData

                        text: modelData
                        size: 12
                    }
                }
            }
        }

        // The top door, coming down while an action is armed.
        RectangularShadow {
            x: 0
            y: topDoor.y + topDoor.height - 30
            width: root.width
            height: 30
            visible: root.lid > 0
            blur: 30
            color: Qt.alpha("black", 0.8)
        }
        Door {
            id: topDoor

            y: -height * (1 - root.lid)
            width: root.width
            height: root.height
            leading: "bottom"
            visible: root.lid > 0
        }
    }

    // The sirens' light sweeping the room, and its glare.
    Rectangle {
        anchors.fill: parent
        color: root.alarm
        opacity: root.sirens * (0.07 + 0.06 * Math.sin(root.spin * Math.PI / 90))
        visible: root.sirens > 0
    }

    // The sirens, one sliding in from each corner.
    Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]

        Item {
            id: siren

            required property var modelData
            readonly property real inset: 110
            // How far in from its corner: from beyond it to in place.
            readonly property real d: -inset + 2 * inset * root.sirens
            readonly property real cx: modelData[0] ? root.width - d : d
            readonly property real cy: modelData[1] ? root.height - d : d
            // Each turns at its own phase.
            readonly property real angle: root.spin + (modelData[0] * 90 + modelData[1] * 180)
            readonly property real facing: Math.cos(angle * Math.PI / 180)

            visible: root.sirens > 0.001

            // Two beams from the reflector, sweeping round.
            Item {
                x: siren.cx
                y: siren.cy
                rotation: siren.angle

                Repeater {
                    model: [0, 180]

                    Shape {
                        required property real modelData

                        rotation: modelData
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: 0
                                centerY: 0
                                centerRadius: 1200
                                focalX: 0
                                focalY: 0

                                GradientStop { position: 0; color: Qt.alpha(root.alarm, 0.5) }
                                GradientStop { position: 1; color: Qt.alpha(root.alarm, 0) }
                            }

                            startX: 0
                            startY: 0

                            PathLine { x: 1200 * Math.cos(-0.22); y: 1200 * Math.sin(-0.22) }
                            PathLine { x: 1200 * Math.cos(0.22); y: 1200 * Math.sin(0.22) }
                            PathLine { x: 0; y: 0 }
                        }
                    }
                }
            }

            // The beacon: a base, and a ribbed red dome with the lamp
            // turning inside it.
            Item {
                x: siren.cx - width / 2
                y: siren.cy - height / 2
                width: 70
                height: 80

                RectangularShadow {
                    anchors.fill: dome
                    radius: 30
                    blur: 40
                    spread: 6
                    color: Qt.alpha(root.alarm, 0.9 * (0.4 + 0.6 * Math.max(0, siren.facing)) * (Theme.glow.opacity ?? 0))
                }
                Rectangle {
                    id: base

                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 20
                    radius: 3
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(root.steel, 1.6) }
                        GradientStop { position: 1; color: Qt.darker(root.steel, 1.6) }
                    }
                }
                Rectangle {
                    id: dome

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: base.top
                    width: 56
                    height: 58
                    topLeftRadius: 28
                    topRightRadius: 28
                    border.width: 1
                    border.color: Qt.darker(root.alarm, 2.5)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.darker(root.alarm, 2.2) }
                        GradientStop { position: 0.45; color: Qt.darker(root.alarm, 1.1) }
                        GradientStop { position: 1; color: Qt.darker(root.alarm, 2.6) }
                    }
                    clip: true

                    // The lamp and its reflector, seen through the dome.
                    Rectangle {
                        x: parent.width / 2 - width / 2 + Math.sin(siren.angle * Math.PI / 180) * 18
                        y: 12
                        width: 20
                        height: 36
                        radius: 10
                        color: Qt.lighter(root.alarm, 1.8)
                        opacity: Math.max(0.15, siren.facing)
                    }
                    // The ribs.
                    Repeater {
                        model: 5

                        Rectangle {
                            required property int index

                            x: (index + 1) * parent.width / 6
                            width: 1
                            height: parent.height
                            color: Qt.alpha("black", 0.25)
                        }
                    }
                    Gloss {
                        anchors.fill: parent
                    }
                }
            }
        }
    }
}
