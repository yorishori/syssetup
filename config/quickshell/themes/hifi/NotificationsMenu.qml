import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.notifications as M

// A telegraph station in a drawer.
//
// The notifications are telegrams, stacked newest on top: a form headed
// TELEGRAM with who it's from, stamped with when it came, the message on
// strips of ticker tape pasted on in capitals, STOP between. Critical ones
// are stamped URGENT in red. Scroll to go through the stack; click the top
// one to act on it; flick it off the stack to be done with it.
//
// Beside it: the ticker under its glass dome, which prints one that comes
// in while it's open (its tape running out, the telegram dropping onto the
// stack); the key: tap it to be done with the top telegram, hold it down to
// clear them all; and the knife switch on the line: closed, the station's
// receiving; open, it's closed to all but the critical. The 1H switch closes
// it for an hour, the minutes left on its display. Under it all, a line per
// source, a hand-labelled switch to cut it.
Item {
    id: root

    required property M.NotificationsPanel control

    readonly property real margin: 12
    readonly property color form: "#f2ead6"
    readonly property color tapeColor: "#fbf6e6"
    readonly property color ink: "#26231f"
    readonly property color stampInk: "#3b4a8c"
    readonly property color redInk: "#b8261b"
    readonly property color segRed: Theme.values.display?.clock ?? Theme.palette.error
    readonly property var stack: control.history  // newest first
    // Which telegram's on top (0 the newest).
    property int current: 0
    readonly property var uppermost: stack[Math.min(current, stack.length - 1)] ?? null
    property int seen: 0
    // The ticker printing (0-1), and a telegram dropping onto the stack.
    property real ticking: 0
    property real dropping: 1

    implicitWidth: unit.implicitWidth + 2 * margin
    implicitHeight: unit.implicitHeight + 2 * margin

    // The message as it goes out on the tape: capitals, STOP between, in
    // strips of up to 30 characters, six at most.
    function tape(n: var): var {
        const parts = [n?.summary ?? "", control.plain(n)].filter(p => p).map(p => p.replace(/[.!?]+$/, ""));
        const words = (parts.join(" STOP ") + " STOP").toUpperCase().split(/\s+/).filter(w => w);
        const strips = [];
        let line = "";
        for (const w of words) {
            if ((line + " " + w).trim().length > 30) {
                strips.push(line);
                line = w;
            } else {
                line = (line + " " + w).trim();
            }
        }
        if (line)
            strips.push(line);
        return strips.length > 6 ? strips.slice(0, 5).concat([strips[5].slice(0, 26) + " ..."]) : strips;
    }
    function hash(n: real): real {
        const x = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            root.current = 0;
            root.seen = root.stack.length;
            root.dropping = 1;
        }
    }
    // One comes in while it's open: the ticker prints it, and it drops onto
    // the stack.
    onStackChanged: {
        current = Math.min(current, Math.max(0, stack.length - 1));
        if (control.open && stack.length > seen) {
            current = 0;
            arrival.restart();
        }
        seen = stack.length;
    }
    SequentialAnimation {
        id: arrival

        ScriptAction { script: root.dropping = 0 }
        NumberAnimation { target: root; property: "ticking"; from: 0; to: 1; duration: 900; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "dropping"; from: 0; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        ScriptAction { script: root.ticking = 0 }
    }

    // A telegram form. `n` the notification; without one, a blank form (the
    // ones under the top one).
    component Telegram: Item {
        id: telegram

        property var n: null
        readonly property bool critical: root.control.critical(n)
        readonly property var strips: n ? root.tape(n) : []

        width: 360
        height: 236

        RectangularShadow {
            anchors.fill: parent
            offset.y: 2
            blur: 6
            color: Qt.alpha("black", 0.35)
        }
        Rectangle {
            anchors.fill: parent
            radius: 1
            color: root.form
            border.width: 1
            border.color: Qt.darker(root.form, 1.2)
        }
        Item {
            anchors.fill: parent
            visible: telegram.n !== null

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 10
                text: "TELEGRAM"
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 8
            }
            Rectangle {
                x: 14
                y: 42
                width: parent.width - 28
                height: 2
                color: root.ink
            }
            Rectangle {
                x: 14
                y: 46
                width: parent.width - 28
                height: 1
                color: root.ink
            }
            Text {
                x: 16
                y: 58
                text: "FROM"
                color: Qt.alpha(root.ink, 0.55)
                font.family: Theme.font.family
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.5
            }
            Text {
                x: 56
                y: 54
                width: 170
                text: (telegram.n?.appName ?? "").toUpperCase()
                elide: Text.ElideRight
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: 13
                font.bold: true
            }
            Rectangle {
                x: 54
                y: 72
                width: 172
                height: 1
                color: Qt.alpha(root.ink, 0.4)
            }

            // The tape, pasted on by hand.
            Column {
                x: 22
                y: 92
                spacing: 6

                Repeater {
                    model: telegram.strips

                    Rectangle {
                        required property int index
                        required property string modelData

                        x: (root.hash(index + (telegram.n?.id ?? 0) * 7) - 0.5) * 6
                        width: stripText.implicitWidth + 12
                        height: 18
                        rotation: (root.hash(index * 3 + (telegram.n?.id ?? 0)) - 0.5) * 1.6
                        color: root.tapeColor
                        border.width: 1
                        border.color: Qt.alpha(root.ink, 0.12)

                        Text {
                            id: stripText

                            anchors.centerIn: parent
                            text: parent.modelData
                            color: telegram.critical ? root.redInk : root.ink
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }
                }
            }

            // Stamped with when it came, and URGENT if it is.
            Rectangle {
                x: parent.width - width - 18
                y: 52
                width: 104
                height: 36
                radius: 4
                rotation: -6
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(root.stampInk, 0.7)

                Column {
                    anchors.centerIn: parent

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "RECEIVED"
                        color: Qt.alpha(root.stampInk, 0.75)
                        font.family: Theme.font.family
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            const at = root.control.receivedAt(telegram.n);
                            return at ? Qt.formatDateTime(new Date(at), "dd MMM HH:mm").toUpperCase() : "";
                        }
                        color: Qt.alpha(root.stampInk, 0.8)
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
            Rectangle {
                x: parent.width - width - 22
                y: parent.height - height - 18
                width: urgentText.implicitWidth + 16
                height: 26
                radius: 3
                rotation: -12
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(root.redInk, 0.8)
                visible: telegram.critical

                Text {
                    id: urgentText

                    anchors.centerIn: parent
                    text: "URGENT"
                    color: Qt.alpha(root.redInk, 0.85)
                    font.family: Theme.font.family
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 3
                }
            }
        }
    }

    Framed {
        id: unit

        x: root.margin
        y: root.margin

        Column {
            spacing: 14

            Row {
                spacing: 20

                // ── The stack ────────────────────────────────────────────────
                Item {
                    id: desk

                    width: 392
                    height: 280

                    // An empty tray's outline, with nothing in it.
                    Rectangle {
                        x: 6
                        y: 6
                        width: 360
                        height: 236
                        radius: 3
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(Theme.values.display?.silk ?? Theme.palette.dim, 0.4)
                        visible: root.stack.length === 0

                        Silk {
                            anchors.centerIn: parent
                            text: "no telegrams"
                            opacity: 0.7
                        }
                    }
                    // The ones under it, their edges showing.
                    Repeater {
                        model: Math.min(4, Math.max(0, root.stack.length - 1 - root.current))

                        Telegram {
                            required property int index

                            x: 6 + (index + 1) * 5
                            y: 6 + (index + 1) * 6
                            rotation: (root.hash(index + 3) - 0.5) * 3
                            z: -1 - index
                        }
                    }
                    // The top one: click it to act on it, flick it off.
                    Telegram {
                        id: topForm

                        property real fly: 0
                        property int flyWay: 1

                        function flyOff(way: int): void {
                            flyWay = way;
                            flight.restart();
                        }

                        x: 6 + drag.activeTranslation.x + fly * flyWay * 520
                        y: 6 - (1 - root.dropping) * 60 + fly * 40
                        rotation: fly * flyWay * 18 + drag.activeTranslation.x / 30
                        opacity: root.dropping * (1 - fly * 0.6)
                        n: root.uppermost
                        visible: root.uppermost !== null

                        SequentialAnimation {
                            id: flight

                            NumberAnimation { target: topForm; property: "fly"; to: 1; duration: 280; easing.type: Easing.InCubic }
                            ScriptAction {
                                script: {
                                    const n = root.uppermost;
                                    topForm.fly = 0;
                                    root.control.dismiss(n);
                                }
                            }
                        }

                        DragHandler {
                            id: drag

                            yAxis.enabled: false
                            onActiveChanged: {
                                if (!active && Math.abs(activeTranslation.x) > 110)
                                    topForm.flyOff(activeTranslation.x > 0 ? 1 : -1);
                            }
                        }
                        TapHandler {
                            onTapped: root.control.invoke(root.uppermost)
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                    // Scroll to go through the stack.
                    WheelHandler {
                        onWheel: event => root.current = Math.max(0, Math.min(root.stack.length - 1, root.current + (event.angleDelta.y > 0 ? -1 : 1)))
                    }
                    Silk {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        text: root.stack.length > 0 ? `${root.current + 1} of ${root.stack.length}` : ""
                        font.pixelSize: 9
                    }
                }

                // ── The instruments ──────────────────────────────────────────
                Column {
                    spacing: 18

                    // The ticker under its dome, its tape running out when it
                    // prints.
                    Item {
                        width: 190
                        height: 92

                        Rectangle {
                            x: 70 - width
                            y: 52
                            width: 60 * Math.min(1, root.ticking * 1.4)
                            height: 9
                            color: root.tapeColor
                            visible: root.ticking > 0 && root.ticking < 0.95
                        }
                        // The plinth, the works, the dome.
                        Rectangle {
                            x: 60
                            y: 78
                            width: 110
                            height: 12
                            radius: 3
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#5b3a22" }
                                GradientStop { position: 1; color: "#2b1a0f" }
                            }
                        }
                        Rectangle {
                            x: 95
                            y: 34
                            width: 40
                            height: 44
                            color: "#7a6a4a"
                            border.width: 1
                            border.color: "#3a3020"
                        }
                        Rectangle {
                            x: 104
                            y: 40
                            width: 22
                            height: 22
                            radius: 11
                            color: "#c8a85a"
                            border.width: 1
                            border.color: "#5a4520"
                            rotation: root.ticking * 1440

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 2
                                height: parent.height
                                color: "#5a4520"
                            }
                        }
                        Rectangle {
                            x: 66
                            y: 8
                            width: 98
                            height: 72
                            topLeftRadius: 49
                            topRightRadius: 49
                            color: Qt.alpha("#cfe3ea", 0.14)
                            border.width: 1
                            border.color: Qt.alpha("white", 0.35)

                            Rectangle {
                                x: 16
                                y: 10
                                width: 10
                                height: 40
                                radius: 5
                                color: Qt.alpha("white", 0.25)
                            }
                        }
                    }

                    // The key: tap to be done with the top telegram, hold to
                    // clear them all.
                    Row {
                        spacing: 12

                        Item {
                            id: key

                            readonly property bool down: keyArea.pressed || clearing.running
                            readonly property bool live: root.stack.length > 0

                            width: 120
                            height: 54
                            opacity: live ? 1 : 0.5

                            Timer {
                                id: holdTimer

                                interval: 700
                                onTriggered: clearing.restart()
                            }
                            SequentialAnimation {
                                id: clearing

                                PauseAnimation { duration: 200 }
                                ScriptAction { script: root.control.clear() }
                            }

                            // The wooden base, the brass lever on its pivot,
                            // the knob.
                            Rectangle {
                                y: 38
                                width: parent.width
                                height: 14
                                radius: 3
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#7a4e2c" }
                                    GradientStop { position: 1; color: "#3a2414" }
                                }
                            }
                            Item {
                                x: 10
                                y: 24
                                width: 100
                                height: 10
                                rotation: key.down ? -4 : 0
                                transformOrigin: Item.Right

                                Behavior on rotation {
                                    NumberAnimation { duration: 60 }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: "#f1d27a" }
                                        GradientStop { position: 0.5; color: "#c79a3e" }
                                        GradientStop { position: 1; color: "#7a5a1e" }
                                    }
                                }
                                Rectangle {
                                    x: -6
                                    y: -10
                                    width: 26
                                    height: 16
                                    radius: 8
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: keyArea.containsMouse && key.live ? "#3a3a3e" : "#232326" }
                                        GradientStop { position: 1; color: "#0b0b0c" }
                                    }
                                }
                            }
                            Rectangle {
                                x: 96
                                y: 26
                                width: 12
                                height: 12
                                radius: 6
                                color: "#a07a2e"
                                border.width: 1
                                border.color: "#4a3510"
                            }
                            MouseArea {
                                id: keyArea

                                anchors.fill: parent
                                enabled: key.live
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: holdTimer.restart()
                                onReleased: {
                                    if (holdTimer.running) {
                                        holdTimer.stop();
                                        topForm.flyOff(1);
                                    }
                                }
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Silk {
                                text: "tap · done"
                                font.pixelSize: 9
                            }
                            Silk {
                                text: "hold · clear"
                                font.pixelSize: 9
                            }
                        }
                    }

                    // The line: the knife switch, and the hour.
                    Row {
                        spacing: 16

                        Item {
                            id: knife

                            readonly property bool closed: !root.control.dnd
                            // Open, the blade's pulled out toward you on its
                            // hinge, out of the jaws.
                            property real swing: closed ? 0 : 105

                            width: 64
                            height: 96

                            Behavior on swing {
                                SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.3 }
                            }

                            // The slate it's mounted on.
                            Rectangle {
                                anchors.fill: parent
                                radius: 3
                                color: "#2c2f33"
                                border.width: 1
                                border.color: "black"
                            }
                            // The jaws it closes into, up top, and its hinge.
                            Repeater {
                                model: [18, 38]

                                Rectangle {
                                    required property real modelData

                                    x: modelData
                                    y: 10
                                    width: 8
                                    height: 16
                                    color: "#b8733a"
                                    border.width: 1
                                    border.color: "#5a3010"
                                }
                            }
                            Rectangle {
                                x: 24
                                y: 70
                                width: 16
                                height: 10
                                color: "#b8733a"
                                border.width: 1
                                border.color: "#5a3010"
                            }
                            // The blade, with its handle.
                            Item {
                                x: 26
                                y: 14
                                width: 12
                                height: 62
                                transform: Rotation {
                                    origin.x: 6
                                    origin.y: 62
                                    axis { x: 1; y: 0; z: 0 }
                                    angle: -knife.swing
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 2
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0; color: "#8a5426" }
                                        GradientStop { position: 0.5; color: "#e3a06a" }
                                        GradientStop { position: 1; color: "#8a5426" }
                                    }
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: -12
                                    width: 16
                                    height: 16
                                    radius: 8
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: knifeArea.containsMouse ? "#e05246" : "#b8261b" }
                                        GradientStop { position: 1; color: "#5e0f0a" }
                                    }
                                }
                            }
                            MouseArea {
                                id: knifeArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.control.setDnd(knife.closed, 0)
                            }
                        }
                        Column {
                            spacing: 10

                            Silk {
                                text: root.control.dnd ? "station\nclosed" : "receiving"
                                font.pixelSize: 9
                            }
                            Row {
                                spacing: 8

                                PushSwitch {
                                    icon: "1h"
                                    latched: root.control.dndUntil > 0
                                    onPushed: root.control.setDnd(true, 60)
                                }
                                // The hour's minutes left.
                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 40
                                    height: 28

                                    Well {
                                        anchors.fill: parent
                                        roundness: 3
                                        fill: Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.segRed, 0.05))
                                    }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Repeater {
                                            model: 2

                                            Segment7 {
                                                required property int index
                                                readonly property int minutes: Math.min(99, root.control.dndMinutesLeft)

                                                width: 11
                                                height: 18
                                                thickness: 2.4
                                                color: root.segRed
                                                digit: minutes > 0 ? (index === 0 ? Math.floor(minutes / 10) : minutes % 10) : -1
                                            }
                                        }
                                    }
                                }
                            }
                            Silk {
                                text: "critical\ngets through"
                                font.pixelSize: 8
                                opacity: 0.8
                            }
                        }
                    }
                }
            }

            // ── The lines ────────────────────────────────────────────────────
            Framed {
                width: desk.width + 20 + 190
                name: "lines"
                visible: root.control.apps.length > 0

                Flow {
                    width: parent.width
                    spacing: 16

                    Repeater {
                        model: root.control.apps

                        Column {
                            id: source

                            required property string modelData
                            readonly property bool open: !root.control.isMuted(modelData)

                            spacing: 6

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: rocker.implicitWidth
                                height: rocker.implicitHeight

                                Rocker {
                                    id: rocker

                                    on: source.open
                                    hovered: sourceArea.containsMouse
                                    lit: source.open
                                }
                                MouseArea {
                                    id: sourceArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.control.toggleApp(source.modelData)
                                }
                            }
                            // Labelled by hand.
                            Legend {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: source.modelData.slice(0, 12)
                                size: 7
                            }
                        }
                    }
                }
            }
        }
    }
}
