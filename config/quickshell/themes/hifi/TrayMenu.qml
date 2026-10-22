import QtQuick
import QtQuick.Shapes
import qs.core
import qs.modules.tray as M

// The app's plug, pulled out of its socket in the panel: the socket feeds
// its cable out and the plug drops and hangs on the end, swinging to a stop.
// Along the cable, flag labels like a cable printer's, wrapped round it:
// the app's name on the first, then one per thing the app offers, in a run
// down the cable, a gap where it groups them. A tick box or a circle on the
// ones that toggle or pick; › on the ones with more; faint for what can't be
// used. The one under the hand (or the keys) lifts. More: the labels spin
// round the cable to show it, ← BACK on the first after the name. Done, the
// cable's reeled back in and the plug goes home. The cable is the color of
// the app's icon.
Item {
    id: root

    required property M.TrayPanel control

    readonly property real flapLength: 168
    readonly property real tagHeight: 18
    readonly property real pitch: 25
    // The socket, in the panel above (the drop's padding above us).
    readonly property real socket: -(Theme.barHeight / 2 + 14)
    readonly property real cableX: flapLength + 24
    readonly property real firstTag: 22
    readonly property color ink: "#1d1d20"
    // Label tape colors, round the run.
    readonly property var tapes: ["#ffe14a", "#f6f3ea", "#86d873", "#69b6f2", "#ff8a6a"]
    // The cable's color: the icon's, once it's been looked at; until then (or
    // if it can't be), one made up from the app's name.
    property var colors: ({})
    readonly property color cable: colors[control.icon] ?? fallbackColor(control.title)

    // The labels down the cable: the name, BACK in a submenu, then the
    // entries ({ entry, y }).
    readonly property var run: {
        const out = [];
        let y = firstTag;
        out.push({ kind: "name", y: y });
        y += pitch;
        if (control.stack.length > 0) {
            out.push({ kind: "back", y: y });
            y += pitch;
        }
        for (const e of control.entries) {
            if (e.isSeparator) {
                y += 10;
                continue;
            }
            out.push({ kind: "entry", entry: e, index: control.entries.indexOf(e), y: y });
            y += pitch;
        }
        if (control.entries.length === 0) {
            out.push({ kind: "loading", y: y });
            y += pitch;
        }
        return out;
    }
    readonly property real plugAt: (run.length > 0 ? run[run.length - 1].y : firstTag) + 40

    // Fed out (0-1), the swing it comes out with, and the labels spinning
    // round to a submenu (0-1).
    property real out: 0
    property real swing: 0
    property real spin: 1
    property int depth: 0

    implicitWidth: 2 * cableX
    implicitHeight: plugAt + 24

    function fallbackColor(name: string): color {
        let h = 0;
        for (const c of name ?? "")
            h = (h * 31 + c.charCodeAt(0)) >>> 0;
        return Qt.hsla((h % 360) / 360, 0.45, 0.5, 1);
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            if (root.control.open) {
                reelIn.stop();
                feedOut.restart();
            } else {
                feedOut.stop();
                reelIn.restart();
            }
        }
        function onStackChanged(): void {
            if (root.control.stack.length !== root.depth) {
                root.depth = root.control.stack.length;
                spinRound.restart();
            }
        }
    }
    // The plug drops, the cable feeding out after it, and swings to a stop.
    ParallelAnimation {
        id: feedOut

        NumberAnimation { target: root; property: "out"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBounce }
        NumberAnimation { target: root; property: "swing"; from: 9; to: 0; duration: 1400; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.4 }
    }
    // Reeled back in.
    NumberAnimation {
        id: reelIn

        target: root
        property: "out"
        to: 0
        duration: 240
        easing.type: Easing.InCubic
    }
    NumberAnimation {
        id: spinRound

        target: root
        property: "spin"
        from: 0
        to: 1
        duration: 460
        easing.type: Easing.OutCubic
    }

    // The icon's strongest color, for the cable.
    IconTone {
        id: tone

        source: root.control.icon
        onKnownChanged: {
            if (known) {
                const next = Object.assign({}, root.colors);
                next[source] = color;
                root.colors = next;
            }
        }
    }

    Item {
        id: hanging

        // Where the plug is: in the socket, to the end of the cable.
        readonly property real end: root.socket + (root.plugAt - root.socket) * root.out

        width: root.width
        height: root.height
        visible: root.out > 0.01
        transform: Rotation {
            origin.x: root.cableX
            origin.y: root.socket
            angle: root.swing
        }

        // The cable, out of the socket down to the plug.
        Rectangle {
            x: root.cableX - 4
            y: root.socket
            width: 8
            height: Math.max(0, hanging.end - root.socket)
            radius: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.darker(root.cable, 1.6) }
                GradientStop { position: 0.4; color: Qt.lighter(root.cable, 1.25) }
                GradientStop { position: 1; color: Qt.darker(root.cable, 1.8) }
            }
        }

        // The labels, there once the cable's out past them.
        Repeater {
            model: root.run

            Item {
                id: tag

                required property var modelData
                required property int index
                readonly property bool isName: modelData.kind === "name"
                readonly property var entry: modelData.entry ?? null
                readonly property bool usable: modelData.kind === "back" || (entry?.enabled ?? false)
                readonly property bool here: modelData.kind === "entry" && root.control.highlighted === modelData.index
                readonly property int kind: entry?.buttonType ?? 0  // 1 tick box, 2 circle
                readonly property bool on: entry?.checkState === Qt.Checked
                readonly property color tape: isName ? "#232327" : root.tapes[index % root.tapes.length]
                readonly property string words: isName ? root.control.title.toUpperCase()
                    : modelData.kind === "back" ? "← BACK"
                    : modelData.kind === "loading" ? "loading..."
                    : root.control.label(entry)
                // Spinning round the cable to a submenu, one after another.
                readonly property real turn: 90 * (1 - Math.max(0, Math.min(1, (root.spin * 1.7 - index * 0.08) / 0.7)))

                x: root.cableX - 9
                y: modelData.y
                width: root.flapLength + 18
                height: root.tagHeight
                visible: hanging.end > y + height
                opacity: modelData.kind === "entry" && !usable ? 0.5 : 1
                transform: [
                    Rotation {
                        origin.x: 9
                        axis { x: 0; y: 1; z: 0 }
                        angle: tag.turn
                    },
                    Rotation {
                        origin.x: 9
                        origin.y: root.tagHeight / 2
                        angle: tag.here || tagArea.containsMouse && tag.usable ? -5 : 0

                        Behavior on angle {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }
                ]

                // The flap, out to the side.
                Rectangle {
                    x: 14
                    width: Math.min(root.flapLength, lettering.implicitWidth + (tag.kind ? 34 : 18) + (tag.entry?.hasChildren ? 14 : 0))
                    height: parent.height
                    radius: 3
                    color: tag.here || tagArea.containsMouse && tag.usable ? Qt.lighter(tag.tape, 1.08) : tag.tape
                    border.width: 1
                    border.color: Qt.darker(tag.tape, 1.25)

                    // A tick box, or a circle to fill in.
                    Rectangle {
                        x: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: tag.kind === 2 ? 5 : 1
                        color: "transparent"
                        border.width: 1.2
                        border.color: root.ink
                        visible: tag.kind !== 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: tag.kind === 2 ? 4 : 6
                            height: width
                            radius: tag.kind === 2 ? 2 : 0.5
                            color: root.ink
                            visible: tag.on
                        }
                    }
                    Text {
                        id: lettering

                        x: tag.kind ? 23 : 8
                        width: Math.min(implicitWidth, root.flapLength - x - (tag.entry?.hasChildren ? 20 : 8))
                        anchors.verticalCenter: parent.verticalCenter
                        text: tag.words
                        elide: Text.ElideRight
                        color: tag.isName ? "#f4f2ec" : root.ink
                        font.family: Theme.font.family
                        font.pixelSize: tag.isName ? 10 : 11
                        font.bold: tag.isName || tag.modelData.kind === "back"
                        font.letterSpacing: tag.isName ? 1.5 : 0
                    }
                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        text: "›"
                        color: root.ink
                        font.family: Theme.font.family
                        font.pixelSize: 14
                        font.bold: true
                        visible: tag.entry?.hasChildren ?? false
                    }
                }
                // Wrapped round the cable.
                Rectangle {
                    width: 18
                    height: parent.height
                    radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.darker(tag.tape, 1.35) }
                        GradientStop { position: 0.45; color: Qt.lighter(tag.tape, 1.05) }
                        GradientStop { position: 1; color: Qt.darker(tag.tape, 1.3) }
                    }
                }
                MouseArea {
                    id: tagArea

                    anchors.fill: parent
                    enabled: tag.usable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: if (tag.modelData.kind === "entry") root.control.highlighted = tag.modelData.index
                    onClicked: tag.modelData.kind === "back" ? root.control.back() : root.control.activate(tag.entry)
                }
            }
        }

        // The plug, hanging on the end, its cap the one from the socket.
        Item {
            x: root.cableX - 13
            y: hanging.end - 8
            width: 26
            height: 34

            // Its sleeve, where the cable goes in.
            Rectangle {
                x: 8
                width: 10
                height: 12
                radius: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#6c6f75" }
                    GradientStop { position: 0.5; color: "#d6d8dc" }
                    GradientStop { position: 1; color: "#55585e" }
                }
            }
            Rectangle {
                y: 8
                width: 26
                height: 26
                radius: 13
                border.width: 1
                border.color: Theme.palette.shadow
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(Theme.palette.surface, 1.3) }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.5) }
                }
            }
            Sticker {
                x: 1
                y: 9
                source: root.control.icon
                seed: Math.max(0, root.control.slot)
            }
        }
    }
}
