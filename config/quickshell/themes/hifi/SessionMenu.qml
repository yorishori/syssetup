import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.session as M

// Blast doors. Opening the session menu slams two steel doors shut over the
// whole screen from the sides, hazard-striped where they meet, the session
// buttons mounted on them in a row across the middle (lock and shutdown on
// the left, reboot and sleep on the right). Arming shutdown or reboot brings
// a third door down from the top over everything; the action runs when it's
// shut (the key's fuse). Cancelled, it goes back up. Closing the menu opens
// the doors.
Item {
    id: root

    required property M.SessionPanel control

    // Whether any of it is still on screen (the window stays up until not).
    readonly property bool covering: shut > 0 || lid > 0.001

    readonly property color steel: "#3a3c42"
    readonly property color hazard: Theme.values.display?.hazard ?? Theme.palette.warn
    readonly property real band: 140

    // The side doors: 0 open, 1 shut. `jolt` shakes everything when they slam.
    property real shut: 0
    property real jolt: 0

    // The top door follows the armed key's fuse down, and goes back up when
    // it's cancelled.
    readonly property M.SessionKey armedKey: control.armed < 0 ? null : (control.armed < 2 ? leftKeys.itemAt(control.armed) : rightKeys.itemAt(control.armed - 2)) as M.SessionKey
    readonly property real lid: armedKey ? 1 - armedKey.fuse : rising
    property real lastLid: 0
    property real rising: 0  // where it is while going back up

    onLidChanged: {
        if (armedKey)
            lastLid = lid;
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

    // The buttons' row, gathered toward the seam: how far from the hazard
    // band the nearest one sits, and the gap between the two on a door.
    readonly property real seamGap: 70
    readonly property real gap: 50

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
                    x: leftDoor.width - root.band - root.seamGap - width - (1 - slot) * (width + root.gap)
                    y: (root.height - height) / 2
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
                    x: root.band + root.seamGap + (slot - 2) * (width + root.gap)
                    y: (root.height - height) / 2
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
}
