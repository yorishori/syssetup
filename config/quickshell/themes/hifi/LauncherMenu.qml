import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components as C
import qs.core
import qs.modules.launcher as M

// A jukebox selector in a drawer.
//
// On top, a three-way MODE dial (search, windows, apps) beside the glass
// display you type into. Under them, the title rack: the results are
// title strips, cream cards with red rules printed with the app's icon and
// name, each in its own holder in a dark cabinet behind glass. Two hidden
// bulbs in the selected holder light its strip from either end, warming up
// and cooling down as the selection moves; the rack scrolls along when it runs
// past what's shown, and strips with nothing printed fill the empty holders.
//
// The strips are printed on a tape running behind the holders: turning the
// MODE dial runs it sideways onto the next mode's strips, all together. While
// you type, a strip that changes flips over in its holder, one after the
// other down the rack; the ones that stay put don't move.
//
// Beside the rack, the selector keys, ivory caps in chrome: the extras
// (capture, clipboard, settings) and the big SELECT key, which goes in and
// lights when a strip is run.
Item {
    id: root

    required property M.LauncherPanel control

    readonly property color silk: Theme.values.display?.silk ?? Theme.palette.dim
    readonly property real margin: 12
    // The title rack: how many strips show, and their pitch.
    readonly property int slots: 8
    readonly property real strip: 34
    readonly property real gap: 4

    // The title strips' paper and ink.
    readonly property color card: "#ebe1c5"
    readonly property color ink: "#2a2119"
    readonly property color rule: "#b5382c"

    // A strip was run: SELECT stays down as the drawer goes in.
    property bool selecting: false

    // The tape: `turn` runs 0-1 as it runs on to the next mode, `way` the
    // way it runs (1 to the left, -1 to the right). What it ran away from is
    // a snapshot.
    property real turn: 1
    property int way: 1
    property int lastMode: 0
    readonly property bool turning: tapeRun.running
    // What each slot showed before the results last changed, and when, so
    // strips that change flip over.
    property var printed: []
    property var before: []
    property real changedAt: 0

    function keyOf(result: var): string {
        return result ? `${result.kind} ${result.name} ${result.detail}` : "";
    }

    implicitWidth: 640 + 2 * margin
    implicitHeight: column.implicitHeight + 2 * margin

    Connections {
        target: root.control

        function onFocusRequested(): void {
            field.focusInput();
        }
        // The query can also be set from outside (IPC).
        function onQueryChanged(): void {
            if (field.text !== root.control.query)
                field.text = root.control.query;
        }
        function onSelectedChanged(): void {
            list.follow();
        }
        function onModeChanged(): void {
            const now = root.control.modes.indexOf(root.control.mode);
            const step = now - root.lastMode;
            root.lastMode = now;
            if (!root.control.open || step === 0)
                return;
            // Round the dial from the last mode to the first is still onwards.
            root.way = Math.abs(step) === 2 ? -Math.sign(step) : Math.sign(step);
            tapeRun.restart();
        }
        function onResultsChanged(): void {
            root.before = root.printed;
            root.printed = root.control.results.map(r => root.keyOf(r));
            root.changedAt = Date.now();
        }
        function onRan(modifiers: int): void {
            root.selecting = true;
        }
        function onOpenChanged(): void {
            if (root.control.open) {
                root.selecting = false;
                root.lastMode = root.control.modes.indexOf(root.control.mode);
            }
        }
    }

    // The tape running on to the next mode's strips, all of them together.
    NumberAnimation {
        id: tapeRun

        target: root
        property: "turn"
        from: 0
        to: 1
        duration: 440
        easing.type: Easing.InOutCubic
    }

    // One title strip: the result's icon and name, what it is, and what
    // SELECT does to it in red.
    component Strip: Item {
        id: strip

        required property var modelData
        required property int index
        readonly property bool current: root.control.selected === index
        // The bulbs: they come on quickly and take a moment to go out.
        property real lit: current ? 1 : 0
        // Flipping over in its holder: edge on (90) to flat (0).
        property real flap: 0

        width: ListView.view.width
        height: root.strip

        Behavior on lit {
            NumberAnimation { duration: strip.current ? 90 : 260; easing.type: Easing.OutQuad }
        }

        // A strip that's new to its slot flips over into it, after the ones
        // above it.
        Component.onCompleted: {
            // New results can make the strips before onResultsChanged has run,
            // when `printed` is still what was there; or after it, when it's
            // `before`. (A strip made by scrolling matches `printed`.)
            const key = root.keyOf(modelData);
            const changed = key !== root.printed[index] || (Date.now() - root.changedAt < 150 && key !== root.before[index]);
            if (index < root.slots && !root.turning && changed) {
                flap = 90;
                flip.start();
            }
        }
        SequentialAnimation {
            id: flip

            PauseAnimation { duration: strip.index * 28 }
            NumberAnimation { target: strip; property: "flap"; to: 0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        // The light spilling round it.
        RectangularShadow {
            anchors.fill: parent
            radius: 2
            blur: 16
            spread: 2
            color: Qt.alpha("#ffbf66", 0.45 * strip.lit)
            visible: strip.lit > 0
        }

        Item {
            id: paper

            width: parent.width
            height: parent.height
            transform: Rotation {
                origin.y: paper.height / 2
                axis { x: 1; y: 0; z: 0 }
                angle: strip.flap
            }

            RectangularShadow {
                anchors.fill: parent
                radius: 2
                offset.y: 1
                blur: 2
                color: Qt.alpha("black", 0.4)
            }
            RecordCard {
                card: root.card
                rule: root.rule
                anchors.fill: parent
            }
            // The bulbs either side, lighting the paper from its ends.
            Rectangle {
                anchors.fill: parent
                radius: 1.5
                visible: strip.lit > 0
                opacity: strip.lit
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha("#ffd27a", 0.75) }
                    GradientStop { position: 0.18; color: Qt.alpha("#ffe3a3", 0.3) }
                    GradientStop { position: 0.5; color: Qt.alpha("#fff0c8", 0.12) }
                    GradientStop { position: 0.82; color: Qt.alpha("#ffe3a3", 0.3) }
                    GradientStop { position: 1; color: Qt.alpha("#ffd27a", 0.75) }
                }
            }
            Item {
                x: 12
                width: 20
                height: parent.height

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 20
                    source: strip.modelData.icon
                    visible: strip.modelData.icon !== ""
                }
                Text {
                    anchors.centerIn: parent
                    text: strip.modelData.glyph
                    color: strip.modelData.kind === "calc" ? root.rule : root.ink
                    font.family: Theme.font.family
                    font.pixelSize: 16
                    font.bold: true
                    visible: strip.modelData.icon === ""
                }
            }
            Row {
                x: 42
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - verb.width - 22
                spacing: 10

                Text {
                    id: title

                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 250)
                    text: strip.modelData.kind === "web" ? `"${strip.modelData.name}"` : strip.modelData.name
                    color: root.ink
                    elide: Text.ElideRight
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - title.width - parent.spacing
                    text: strip.modelData.detail
                    color: Qt.alpha(root.ink, 0.6)
                    elide: Text.ElideRight
                    font.family: Theme.font.family
                    font.pixelSize: 11
                }
            }
            Text {
                id: verb

                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: (root.control.verbs[strip.modelData.kind] ?? "").toUpperCase()
                color: root.rule
                font.family: Theme.font.family
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.5
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.control.selected = strip.index
            onClicked: mouse => root.control.run(strip.index, mouse.modifiers)
        }
    }

    ColumnLayout {
        id: column

        x: root.margin
        y: root.margin
        width: parent.width - 2 * root.margin
        spacing: 12

        // ── The MODE dial and the display ────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: 82

            SilkFrame {
                anchors.fill: parent
            }
            ModeDial {
                control: root.control
                x: 6
                y: 8
            }
            C.TextField {
                id: field

                x: 186
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - 14
                // The dial says what it's for.
                prompt: ""
                placeholder: root.control.placeholder
                onTextChanged: root.control.setQuery(text)
                onAccepted: modifiers => root.control.run(root.control.selected, modifiers)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // ── The title rack ───────────────────────────────────────────────
            Item {
                id: rack

                readonly property real pitch: root.strip + root.gap
                // The first strip showing.
                readonly property int first: Math.round((list.contentY - list.originY) / pitch)

                Layout.fillWidth: true
                implicitHeight: root.slots * pitch - root.gap + 2 * 15

                // The cabinet: a cast frame round a dark plate, each strip in
                // its own holder.
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#55575d" }
                        GradientStop { position: 0.08; color: "#34363b" }
                        GradientStop { position: 1; color: "#1a1b1e" }
                    }
                }
                Rectangle {
                    id: inside

                    anchors {
                        fill: parent
                        margins: 5
                    }
                    radius: 3
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#16130f" }
                        GradientStop { position: 1; color: "#0d0b09" }
                    }
                    clip: true

                    // The bulbs' light leaking out round the selected holder,
                    // onto the plate.
                    Repeater {
                        model: root.slots

                        RectangularShadow {
                            id: leak

                            required property int index
                            property real lit: list.count > 0 && rack.first + index === root.control.selected ? 1 : 0

                            x: 15
                            y: 9 + index * rack.pitch
                            width: inside.width - 30
                            height: root.strip + 2
                            radius: 3
                            blur: 12
                            spread: 1
                            color: Qt.alpha("#ffb85c", 0.45)
                            opacity: lit
                            visible: lit > 0

                            Behavior on lit {
                                NumberAnimation { duration: leak.lit < 0.5 ? 90 : 260; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    // The tape: blank strips in every slot, the results over
                    // them, showing only through the holders' windows.
                    Item {
                        id: tape

                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: windows
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 0.2
                        }

                        Item {
                            id: page

                            width: inside.width
                            height: inside.height
                            transform: Translate {
                                x: root.way * (1 - root.turn) * page.width
                            }

                            Column {
                                x: 16
                                y: 10
                                spacing: root.gap

                                Repeater {
                                    model: root.slots

                                    RecordCard {
                                        card: root.card
                                        rule: root.rule
                                        required property int index

                                        width: inside.width - 32
                                        height: root.strip

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.control.query.trim() !== "" ? "NO SELECTION"
                                                : root.control.listed ? `NO ${root.control.mode.toUpperCase()}` : ""
                                            color: root.rule
                                            font.family: Theme.font.family
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.letterSpacing: 3
                                            visible: parent.index === 0 && list.count === 0
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: list

                                x: 16
                                y: 10
                                width: inside.width - 32
                                height: root.slots * rack.pitch - root.gap
                                spacing: root.gap
                                boundsBehavior: Flickable.StopAtBounds
                                snapMode: ListView.SnapToItem
                                model: root.control.results
                                delegate: Strip {}
                                // The rack runs along to keep the selection in
                                // view. (A new model resets currentIndex, so
                                // it's set again.)
                                function follow(): void {
                                    currentIndex = root.control.selected;
                                }
                                Component.onCompleted: follow()
                                onCountChanged: Qt.callLater(follow)
                                highlight: Item {}
                                highlightMoveDuration: 160
                                highlightRangeMode: ListView.ApplyRange
                                preferredHighlightBegin: 0
                                preferredHighlightEnd: height
                            }
                        }

                        // What was on the tape before it ran: a picture of
                        // it, kept current (it's drawn all the time, clipped
                        // away to a line, so it doesn't go stale).
                        Item {
                            width: page.width
                            height: root.turning ? page.height : 1
                            clip: true

                            ShaderEffectSource {
                                y: root.turning ? 0 : -page.height
                                width: page.width
                                height: page.height
                                sourceItem: page
                                live: !root.turning
                                transform: Translate {
                                    x: root.turning ? -root.way * root.turn * page.width : 0
                                }
                            }
                        }
                    }

                    // The holders' windows, for the tape's mask.
                    Item {
                        id: windows

                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Repeater {
                            model: root.slots

                            Rectangle {
                                required property int index

                                x: 18
                                y: 12 + index * rack.pitch
                                width: inside.width - 36
                                height: root.strip - 4
                                radius: 2
                            }
                        }
                    }

                    // The holders: a bezel round each window, shading the
                    // top of the strip in it. The bulbs inside the selected
                    // one light its edges.
                    Repeater {
                        model: root.slots

                        Item {
                            id: holder

                            required property int index
                            property real lit: list.count > 0 && rack.first + index === root.control.selected ? 1 : 0

                            x: 15
                            y: 9 + index * rack.pitch
                            width: inside.width - 30
                            height: root.strip + 2

                            Behavior on lit {
                                NumberAnimation { duration: holder.lit < 0.5 ? 90 : 260; easing.type: Easing.OutQuad }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 3
                                color: "transparent"
                                border.width: 3
                                border.color: Qt.tint("#3f4146", Qt.alpha("#ffc070", 0.35 * holder.lit))
                            }
                            // Light catching the bezel's top and bottom edges.
                            Rectangle {
                                x: 3
                                width: parent.width - 6
                                height: 1
                                color: Qt.alpha("white", 0.22)
                            }
                            Rectangle {
                                x: 3
                                y: parent.height - 1
                                width: parent.width - 6
                                height: 1
                                color: Qt.alpha("black", 0.6)
                            }
                            // The window's edge, and the bezel's shadow on the strip.
                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: 3
                                }
                                radius: 2
                                color: "transparent"
                                border.width: 1
                                border.color: "black"
                            }
                            Rectangle {
                                x: 4
                                y: 4
                                width: parent.width - 8
                                height: 5
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.alpha("black", 0.45) }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                            }
                        }
                    }
                }
                // The glass over it all.
                Gloss {
                    anchors {
                        fill: inside
                        margins: 1
                    }
                    roundness: 3
                }
            }

            // ── The keys ─────────────────────────────────────────────────────
            // The extras (capture, clipboard, settings) up the side, and the
            // big SELECT key under them.
            Item {
                Layout.fillHeight: true
                implicitWidth: 84

                SilkFrame {
                    anchors.fill: parent
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 12
                    spacing: 8

                    Repeater {
                        model: root.control.actions

                        JukeKey {
                            card: root.card
                            ink: root.ink
                            required property var modelData

                            width: 46
                            height: 30
                            icon: modelData.icon
                            live: !(modelData.busy && root.control.capturing)
                            onClicked: modelData.run()
                        }
                    }
                }
                Column {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 12
                    }
                    spacing: 7

                    JukeKey {
                        card: root.card
                        ink: root.ink
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        height: 58
                        icon: "\u{F0311}"
                        glyphSize: 24
                        live: list.count > 0
                        lit: root.selecting
                        onClicked: modifiers => root.control.run(root.control.selected, modifiers)
                    }
                    C.StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "select"
                        caps: true
                        color: root.silk
                        font.pixelSize: 10
                        font.bold: true
                        tracking: 1.5
                    }
                }
            }
        }

        C.KeyHints {
            Layout.alignment: Qt.AlignRight
            hints: root.control.hints
        }
    }
}
