import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components as C
import qs.core
import qs.modules.session as M

// Blast doors. Opening the session menu slams two steel doors shut over the
// whole screen from the sides; their hazard-striped edges are toothed and
// interlock where they meet. The session buttons are mounted on them in a
// row across the middle (lock and shutdown on the left, reboot and sleep on
// the right), and the uptime reads out on a VFD. Arming shutdown or reboot
// brings a third door down from the top over everything; the action runs
// when it's shut (the key's fuse). Cancelled, it goes back up. Closing the
// menu opens the doors.
Item {
    id: root

    required property M.SessionPanel control

    // Whether any of it is still on screen (the window stays up until not).
    readonly property bool covering: shut > 0 || lid > 0.001

    readonly property color vfd: Theme.palette.accent

    // The doors' toothed edge (see BlastDoor): teeth `depth` deep, one every
    // `period`; a door's plate begins `edgeWidth` in from it.
    readonly property real depth: leftDoor.depth
    readonly property real period: leftDoor.period
    readonly property real edgeWidth: leftDoor.edgeWidth

    // The side doors: 0 open, 1 shut. `jolt` shakes everything when they slam.
    property real shut: 0
    property real jolt: 0

    // The top door follows the armed key's fuse down, and goes back up when
    // it's cancelled.
    readonly property M.SessionKey armedKey: control.armed < 0 ? null : (control.armed < 2 ? leftKeys.itemAt(control.armed) : rightKeys.itemAt(control.armed - 2)) as M.SessionKey
    readonly property real lid: armedKey ? 1 - armedKey.fuse : rising
    property real lastLid: 0
    property real rising: 0  // where it is while going back up

    // The buttons' row, gathered toward the seam: how far from the edge the
    // nearest one sits, and the gap between the two on a door.
    readonly property real seamGap: 60
    readonly property real gap: 50

    onLidChanged: {
        if (armedKey)
            lastLid = lid;
    }
    NumberAnimation {
        id: rise

        target: root
        property: "rising"
        to: 0
        duration: 600
        easing.type: Easing.InOutCubic
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

    // The room darkening behind the doors as they close.
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.shadow
        opacity: 0.6 * root.shut
    }

    Item {
        id: stage

        width: root.width
        height: root.height
        y: root.jolt * 7

        // The left door, with lock and shutdown, and the uptime.
        BlastDoor {
            id: leftDoor

            x: -width * (1 - root.shut)
            width: root.width / 2 + root.depth / 2
            height: root.height


            UptimeCounter {
                hostname: root.control.hostname
                uptime: root.control.uptime
                x: 70
                y: 70
            }

            Repeater {
                id: leftKeys

                model: [0, 1]

                Button {
                    x: leftDoor.width - root.edgeWidth - root.seamGap - width - (1 - slot) * (width + root.gap)
                    y: (root.height - height) / 2
                }
            }
        }

        // The right door, with reboot and sleep, and how to drive it. Its
        // teeth sit half a tooth along, in the left door's notches.
        BlastDoor {
            id: rightDoor

            edge: "left"
            phase: root.period / 2

            x: root.width - width * root.shut
            width: root.width / 2 + root.depth / 2
            height: root.height


            Repeater {
                id: rightKeys

                model: [2, 3]

                Button {
                    x: root.edgeWidth + root.seamGap + (slot - 2) * (width + root.gap)
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

        // The top door, coming down while an action is armed, toothed along
        // its leading edge; its shadow under it.
        RectangularShadow {
            y: topDoor.y + topDoor.height - root.depth - 20
            width: topDoor.width
            height: 20
            visible: topDoor.visible
            offset.y: 14
            blur: 30
            color: Qt.alpha("black", 0.8)
        }
        BlastDoor {
            id: topDoor

            edge: "bottom"

            y: -height * (1 - root.lid)
            width: root.width
            height: root.height + root.depth
            visible: root.lid > 0
        }
    }
}
