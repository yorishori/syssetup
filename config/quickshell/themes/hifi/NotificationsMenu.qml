import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components as C
import qs.core
import qs.modules.notifications as M

// A teleprinter in a drawer. The notifications are printed on its paper
// roll, continuous form with sprocket holes down both edges, behind a
// window: each one a block (when, from whom, the summary in bold, the body
// under it) with a perforation under it, the newest at the platen at the
// bottom; critical ones print in red. There's only as much paper as there
// is printed, its end cut finely serrated; once it's longer than the window,
// the overflow latch drops onto it at the top and holds it, and scrolling
// feeds it through under the latch. Click a message to act on it; its tear
// tab (or a right click) tears it off along its perforation. One that comes
// in while it's open types out letter by letter as the paper feeds.
//
// Beside the window: DO NOT DISTURB, a three-way rotary (OFF, ON, 1H) with
// its STANDBY lamp and, for the hour, the minutes left on a red display;
// the TEAR OFF lever: the cutter cuts the paper at the platen and it's
// thrown off to the right. Under it all, a
// switch per source, labelled by hand: up prints, down mutes.
Item {
    id: root

    required property M.NotificationsPanel control

    readonly property real margin: 12
    readonly property color paper: "#f7f4ea"
    readonly property color ink: "#23222a"
    readonly property color redInk: "#b8261b"
    readonly property color segRed: Theme.values.display?.clock ?? Theme.palette.error
    // Newest first: the list stacks up from the platen.
    readonly property var printed: control.history
    // The one typing out, and how far it's got (0-1).
    property var typing: null
    property real typed: 1
    // Everything printed cut off at once: the cutter's flash, then the paper
    // thrown off to the right (0-1).
    property real cutFlash: 0
    property real cutAway: 0
    property int seen: 0

    implicitWidth: unit.implicitWidth + 2 * margin
    implicitHeight: unit.implicitHeight + 2 * margin

    function dndMode(): int {
        return !control.dnd ? 0 : control.dndUntil > 0 ? 2 : 1;
    }
    function setDndMode(mode: int): void {
        if (mode === 0)
            control.setDnd(false, 0);
        else
            control.setDnd(true, mode === 2 ? 60 : 0);
    }

    // A cut end of the paper: fine teeth along it, pointing up (or `down`).
    component Serration: Shape {
        id: teeth

        property bool down: false

        width: parent?.width ?? 0
        height: 2

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.paper
            startX: 0
            startY: teeth.down ? 0 : teeth.height

            PathPolyline {
                path: {
                    const pts = [];
                    const base = teeth.down ? 0 : teeth.height, tip = teeth.down ? teeth.height : 0;
                    for (let x = 0; x <= teeth.width; x += 2.4)
                        pts.push(Qt.point(x, base), Qt.point(x + 1.2, tip));
                    pts.push(Qt.point(teeth.width, base));
                    return pts;
                }
            }
        }
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            root.seen = root.printed.length;
            root.typing = null;
            root.typed = 1;
        }
    }
    // Something new while it's open: it types out.
    onPrintedChanged: {
        if (control.open && printed.length > seen && printed.length > 0) {
            typing = printed[0];
            typeOut.restart();
        }
        seen = printed.length;
    }
    NumberAnimation {
        id: typeOut

        target: root
        property: "typed"
        from: 0
        to: 1
        duration: Math.min(2200, 18 * ((root.typing?.summary?.length ?? 0) + root.control.plain(root.typing).length + 24))
    }
    SequentialAnimation {
        id: tearOff

        NumberAnimation { target: root; property: "cutFlash"; from: 0; to: 1; duration: 60 }
        NumberAnimation { target: root; property: "cutFlash"; to: 0; duration: 120 }
        NumberAnimation { target: root; property: "cutAway"; from: 0; to: 1; duration: 460; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.control.clear();
                root.cutAway = 0;
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
                spacing: 18

                // ── The paper window ─────────────────────────────────────────
                Item {
                    id: window

                    width: 340
                    height: 420

                    Well {
                        anchors.fill: parent
                        roundness: 4
                        fill: "#0c0c0d"
                    }
                    Item {
                        id: feed

                        anchors {
                            fill: parent
                            margins: 6
                            bottomMargin: 30
                        }
                        clip: true

                        // The paper: as long as what's printed on it, up from
                        // the platen, its end cut finely serrated. Cut off,
                        // it's thrown off to the right.
                        Item {
                            id: strip

                            readonly property real printedLength: list.contentHeight + 16
                            readonly property bool overflowing: printedLength > feed.height
                            property real length: Math.min(feed.height, printedLength)

                            x: root.cutAway * feed.width * 1.4
                            y: feed.height - length - root.cutAway * 50
                            width: feed.width
                            height: length
                            rotation: root.cutAway * 22
                            transformOrigin: Item.BottomLeft
                            visible: root.printed.length > 0

                            Behavior on length {
                                enabled: !strip.overflowing
                                NumberAnimation { duration: 260; easing.type: Easing.OutQuad }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.paper
                            }
                            // The sprocket holes, moving with the paper.
                            Item {
                                anchors.fill: parent
                                clip: true

                                Repeater {
                                    model: 2

                                    Column {
                                        required property int index

                                        x: index ? strip.width - 13 : 5
                                        y: 6 - ((list.contentY % 16) + 16) % 16
                                        spacing: 9

                                        Repeater {
                                            model: Math.ceil(feed.height / 16) + 2

                                            Rectangle {
                                                width: 7
                                                height: 7
                                                radius: 3.5
                                                color: "#141416"
                                            }
                                        }
                                    }
                                }
                                Repeater {
                                    model: [18, strip.width - 19]

                                    Rectangle {
                                        required property real modelData

                                        x: modelData
                                        width: 1
                                        height: strip.height
                                        color: Qt.alpha(root.ink, 0.12)
                                    }
                                }
                            }
                            // The ends, cut: serrated, the top one while it's
                            // short of the latch, the bottom one once it's cut.
                            Serration {
                                y: -height + 0.5
                                visible: !strip.overflowing
                            }
                            Serration {
                                y: strip.height - 0.5
                                down: true
                                visible: root.cutAway > 0
                            }

                            // The print, clipped to the paper; the list itself
                            // is the window's height, so how long it is doesn't
                            // hang on how long the paper is.
                            Item {
                                anchors.fill: parent
                                clip: true

                            ListView {
                                id: list

                                x: 26
                                y: parent.height - height
                                width: strip.width - 52
                                height: feed.height
                                interactive: strip.overflowing
                                boundsBehavior: Flickable.StopAtBounds
                                // Printed from the platen up: the newest at the
                                // bottom, older ones fed up above it.
                                verticalLayoutDirection: ListView.BottomToTop
                                model: root.printed
                                onCountChanged: Qt.callLater(() => positionViewAtBeginning())

                                Behavior on contentY {
                                    enabled: !list.moving
                                    NumberAnimation { duration: 260; easing.type: Easing.OutQuad }
                                }

                                delegate: Item {
                                    id: block

                                    required property var modelData
                                    readonly property bool critical: root.control.critical(modelData)
                                    readonly property real progress: modelData === root.typing ? root.typed : 1
                                    readonly property string head: {
                                        const at = root.control.receivedAt(modelData);
                                        return `${at ? Qt.formatTime(at, "HH:mm") : "--:--"}  ${(modelData?.appName ?? "").toUpperCase()}`;
                                    }
                                    readonly property string summary: modelData?.summary ?? ""
                                    readonly property string body: root.control.plain(modelData)
                                    // How much has been typed of head, summary, body.
                                    readonly property int chars: Math.round(progress * (head.length + summary.length + body.length))
                                    property real tear: 0

                                    width: ListView.view.width
                                    height: lines.implicitHeight + 26

                                    SequentialAnimation {
                                        id: tearing

                                        NumberAnimation { target: block; property: "tear"; to: 1; duration: 280; easing.type: Easing.InCubic }
                                        ScriptAction { script: root.control.dismiss(block.modelData) }
                                    }

                                    Item {
                                        width: parent.width
                                        height: parent.height
                                        x: block.tear * 60
                                        y: -block.tear * 14
                                        rotation: block.tear * 5
                                        opacity: 1 - block.tear

                                        Column {
                                            id: lines

                                            x: 4
                                            y: 10
                                            width: parent.width - 8
                                            spacing: 3

                                            Text {
                                                width: parent.width
                                                text: block.head.slice(0, block.chars)
                                                color: Qt.alpha(block.critical ? root.redInk : root.ink, 0.6)
                                                font.family: Theme.font.family
                                                font.pixelSize: 10
                                                font.letterSpacing: 1
                                            }
                                            Text {
                                                width: parent.width
                                                text: block.summary.slice(0, Math.max(0, block.chars - block.head.length))
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                                color: block.critical ? root.redInk : root.ink
                                                font.family: Theme.font.family
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                width: parent.width
                                                text: block.body.slice(0, Math.max(0, block.chars - block.head.length - block.summary.length))
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 3
                                                elide: Text.ElideRight
                                                color: Qt.alpha(block.critical ? root.redInk : root.ink, 0.85)
                                                font.family: Theme.font.family
                                                font.pixelSize: 11
                                                visible: block.body !== ""
                                            }
                                        }
                                        // The perforation it tears along.
                                        Row {
                                            y: parent.height - 2
                                            spacing: 4

                                            Repeater {
                                                model: Math.floor(block.width / 7)

                                                Rectangle {
                                                    width: 3
                                                    height: 1
                                                    color: Qt.alpha(root.ink, 0.35)
                                                }
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: mouse => {
                                                if (mouse.button === Qt.RightButton)
                                                    tearing.start();
                                                else
                                                    root.control.invoke(block.modelData);
                                            }

                                            // The tear tab, in the margin by the perforation.
                                            Rectangle {
                                                x: parent.width - width + 2
                                                y: parent.height - height - 3
                                                width: 18
                                                height: 14
                                                radius: 2
                                                color: tabArea.containsMouse ? "#e6dcc4" : "#efe8d6"
                                                border.width: 1
                                                border.color: Qt.alpha(root.ink, 0.3)
                                                visible: parent.containsMouse || tabArea.containsMouse

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✂"
                                                    color: Qt.alpha(root.ink, 0.7)
                                                    font.pixelSize: 10
                                                }
                                                MouseArea {
                                                    id: tabArea

                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: tearing.start()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            }
                        }

                        // The overflow latch: once the paper's longer than the
                        // window, it drops onto it and holds it at the top; the
                        // paper feeds through under it.
                        Item {
                            width: feed.width
                            height: 12
                            y: strip.overflowing && root.cutAway === 0 ? 0 : -16

                            Behavior on y {
                                NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 }
                            }

                            Rectangle {
                                anchors.fill: parent
                                border.width: 1
                                border.color: "black"
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#e9eaee" }
                                    GradientStop { position: 0.5; color: "#9a9ca3" }
                                    GradientStop { position: 1; color: "#4d4f55" }
                                }
                            }
                            Repeater {
                                model: [40, feed.width - 60]

                                Rectangle {
                                    required property real modelData

                                    x: modelData
                                    y: parent.height - 3
                                    width: 20
                                    height: 6
                                    radius: 3
                                    color: "#1c1c1e"
                                }
                            }
                            RectangularShadow {
                                anchors.fill: parent
                                offset.y: 3
                                blur: 6
                                color: Qt.alpha("black", 0.5)
                                z: -1
                            }
                        }
                        // The cutter's flash across the platen.
                        Rectangle {
                            y: feed.height - 2
                            width: feed.width
                            height: 2
                            color: "#f4f6f8"
                            opacity: root.cutFlash
                        }
                        // The paper curling over the platen at the bottom.
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 18
                            gradient: Gradient {
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: Qt.alpha("black", 0.25) }
                            }
                        }
                    }
                    // The platen, and the type head on it.
                    Rectangle {
                        x: 6
                        y: parent.height - 30
                        width: parent.width - 12
                        height: 24
                        radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#3a3a3d" }
                            GradientStop { position: 0.45; color: "#1a1a1c" }
                            GradientStop { position: 1; color: "#060607" }
                        }
                    }
                    Rectangle {
                        x: 32 + (list.width - width) * (root.typing && typeOut.running ? (root.typed * 37) % 1 : 0.5)
                        y: parent.height - 36
                        width: 30
                        height: 22
                        radius: 3
                        border.width: 1
                        border.color: "black"
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#c9cbd0" }
                            GradientStop { position: 1; color: "#6c6f75" }
                        }
                    }
                    Gloss {
                        anchors {
                            fill: parent
                            margins: 1
                        }
                        roundness: 4
                    }
                }

                // ── The controls ─────────────────────────────────────────────
                Column {
                    spacing: 18

                    // Do not disturb: the rotary, its lamp, and the hour.
                    Column {
                        spacing: 10

                        Silk {
                            text: "do not disturb"
                        }
                        Item {
                            id: rotary

                            readonly property var stops: [-50, 0, 50]
                            property real angle: stops[root.dndMode()]

                            width: 150
                            height: 70

                            Behavior on angle {
                                SpringAnimation { spring: 6; damping: 0.45; epsilon: 0.2 }
                            }

                            Repeater {
                                model: ["off", "on", "1h"]

                                Silk {
                                    required property int index
                                    required property string modelData
                                    readonly property real a: rotary.stops[index] * Math.PI / 180

                                    x: rotary.width / 2 + Math.sin(a) * 40 - width / 2
                                    y: 44 - Math.cos(a) * 40 - height / 2
                                    text: modelData

                                    MouseArea {
                                        anchors {
                                            fill: parent
                                            margins: -4
                                        }
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setDndMode(parent.index)
                                    }
                                }
                            }
                            Item {
                                x: (rotary.width - 36) / 2
                                y: 26
                                width: 36
                                height: 36

                                RectangularShadow {
                                    anchors.fill: parent
                                    radius: width / 2
                                    offset.y: 2
                                    blur: 4
                                    color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    border.width: 1
                                    border.color: Theme.palette.shadow
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: knobArea.containsMouse ? Qt.lighter(Theme.palette.surface, 1.6) : Qt.lighter(Theme.palette.surface, 1.3) }
                                        GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.7) }
                                    }
                                }
                                // A pointer bar across its face.
                                Item {
                                    anchors.fill: parent
                                    rotation: rotary.angle

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 3
                                        width: 4
                                        height: 14
                                        radius: 2
                                        color: Theme.palette.fg
                                    }
                                }
                                MouseArea {
                                    id: knobArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => root.setDndMode((root.dndMode() + (mouse.button === Qt.RightButton ? 2 : 1)) % 3)
                                    onWheel: wheel => root.setDndMode(Math.max(0, Math.min(2, root.dndMode() + (wheel.angleDelta.y > 0 ? -1 : 1))))
                                }
                            }
                        }
                        Row {
                            spacing: 10

                            Led {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 10
                                on: root.control.dnd
                                color: Theme.palette.error
                            }
                            Silk {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "standby"
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

                                            width: 11
                                            height: 18
                                            thickness: 2.4
                                            color: root.segRed
                                            digit: root.control.dndMinutesLeft > 0
                                                ? (index === 0 ? Math.floor(Math.min(99, root.control.dndMinutesLeft) / 10) : Math.min(99, root.control.dndMinutesLeft) % 10)
                                                : -1
                                        }
                                    }
                                }
                            }
                        }
                        Silk {
                            text: "critical\nmessages print"
                            font.pixelSize: 8
                            opacity: 0.8
                        }
                    }

                    // The tear-off lever: pull it to tear off everything
                    // printed.
                    Row {
                        spacing: 12

                        Item {
                            id: lever

                            property real pull: 0
                            readonly property bool live: root.printed.length > 0

                            width: 30
                            height: 90
                            opacity: live ? 1 : 0.5

                            SequentialAnimation {
                                id: pulled

                                NumberAnimation { target: lever; property: "pull"; to: 1; duration: 160; easing.type: Easing.OutCubic }
                                ScriptAction { script: tearOff.restart() }
                                PauseAnimation { duration: 300 }
                                NumberAnimation { target: lever; property: "pull"; to: 0; duration: 320; easing.type: Easing.OutBack }
                            }

                            // Its slot.
                            Well {
                                x: (parent.width - width) / 2
                                width: 10
                                height: parent.height
                                roundness: 5
                            }
                            // The lever, down when pulled, and its knob.
                            Item {
                                x: (parent.width - width) / 2
                                y: 6 + lever.pull * (parent.height - 40)
                                width: 30
                                height: 28

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 6
                                    height: 20
                                    color: "#9a9ca2"
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 14
                                    radius: 7
                                    border.width: 1
                                    border.color: "black"
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: leverArea.containsMouse && lever.live ? "#e05246" : "#c0362b" }
                                        GradientStop { position: 1; color: "#6e130c" }
                                    }
                                }
                            }
                            MouseArea {
                                id: leverArea

                                anchors.fill: parent
                                enabled: lever.live
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!pulled.running) pulled.start()
                            }
                        }
                        Silk {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "tear\noff"
                        }
                    }
                }
            }

            // ── The sources ──────────────────────────────────────────────────
            Framed {
                width: window.width + 18 + 150
                name: "sources"
                visible: root.control.apps.length > 0

                Flow {
                    width: parent.width
                    spacing: 16

                    Repeater {
                        model: root.control.apps

                        Column {
                            id: source

                            required property string modelData
                            readonly property bool prints: !root.control.isMuted(modelData)

                            spacing: 6

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: rocker.implicitWidth
                                height: rocker.implicitHeight

                                Rocker {
                                    id: rocker

                                    on: source.prints
                                    hovered: sourceArea.containsMouse
                                    lit: source.prints
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
