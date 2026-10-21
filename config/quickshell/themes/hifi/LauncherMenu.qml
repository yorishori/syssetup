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
// display you type into. Under them, the title rack: the results are title
// strips, cream cards with red rules printed with the app's icon and name,
// standing behind a pane of glass in a chrome frame, backlit warm. A lamp in
// the rack's margin points at the selected strip, which stands a little
// forward; the rack flips along when the selection runs past what's shown,
// and strips with nothing printed fill the slots that are empty. Beside the
// rack, the quick-action keys and the big SELECT key, which goes down when a
// strip is run (its NEW lamp lights for a new instance).
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

    // How the last run went: SELECT down, NEW lit for a new instance.
    property bool selecting: false
    property bool fresh: false

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
        function onRan(modifiers: int): void {
            root.selecting = true;
            root.fresh = (modifiers & Qt.ShiftModifier) !== 0;
        }
        function onOpenChanged(): void {
            if (root.control.open) {
                root.selecting = false;
                root.fresh = false;
            }
        }
    }

    // A section of the faceplate, outlined in silkscreen.
    component Frame: Rectangle {
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(root.silk, 0.55)
    }

    // The paper of a title strip, red rules along its edges.
    component Card: Rectangle {
        radius: 1.5
        border.width: 1
        border.color: Qt.darker(root.card, 1.6)
        gradient: Gradient {
            GradientStop { position: 0; color: root.card }
            GradientStop { position: 1; color: Qt.darker(root.card, 1.08) }
        }

        Rectangle {
            x: 6
            y: 3
            width: parent.width - 12
            height: 1.5
            color: root.rule
            opacity: 0.8
        }
        Rectangle {
            x: 6
            y: parent.height - 4.5
            width: parent.width - 12
            height: 1.5
            color: root.rule
            opacity: 0.8
        }
    }

    // The MODE dial: a three-way rotary, the modes printed round it. Click it
    // for the next, right click for the previous, scroll, or click a mode.
    component ModeDial: Item {
        id: dial

        readonly property int index: root.control.modes.indexOf(root.control.mode)
        readonly property var angles: [-58, 0, 58]
        property real angle: angles[Math.max(0, index)]

        width: 168
        height: 66

        Behavior on angle {
            SpringAnimation { spring: 6; damping: 0.45; epsilon: 0.2 }
        }

        // The modes, each by its stop.
        Repeater {
            model: root.control.modes

            Item {
                id: stop

                required property int index
                required property string modelData
                readonly property bool on: dial.index === index
                readonly property real a: dial.angles[index] * Math.PI / 180

                Rectangle {
                    x: dial.width / 2 + Math.sin(stop.a) * 24 - 1.5
                    y: 42 - Math.cos(stop.a) * 24 - 1.5
                    width: 3
                    height: 3
                    radius: 1.5
                    color: stop.on ? Theme.palette.accent : Qt.alpha(Theme.palette.fg, 0.3)
                }
                C.StyledText {
                    id: name

                    x: stop.index === 0 ? dial.width / 2 - 30 - width
                        : stop.index === 2 ? dial.width / 2 + 30
                        : (dial.width - width) / 2
                    y: stop.index === 1 ? 0 : 14
                    text: stop.modelData === "windows" ? `windows ${root.control.windowCount}` : stop.modelData
                    caps: true
                    color: stop.on ? Theme.palette.accent : root.silk
                    glow: stop.on
                    font.pixelSize: 9
                    font.bold: true
                    tracking: 1

                    MouseArea {
                        anchors {
                            fill: parent
                            margins: -4
                        }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.control.setMode(stop.modelData)
                    }
                }
            }
        }
        // The knob.
        Item {
            x: (dial.width - 34) / 2
            y: 25
            width: 34
            height: 34

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
            Item {
                anchors.fill: parent
                rotation: dial.angle

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3
                    width: 3
                    height: 12
                    radius: 1.5
                    color: Theme.palette.fg
                }
            }

            MouseArea {
                id: knobArea

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => root.control.switchTab(mouse.button === Qt.RightButton ? -1 : 1)
                onWheel: wheel => root.control.switchTab(wheel.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }

    // One title strip: the result's icon and name, what it is, and what
    // SELECT does to it in red.
    component Strip: Item {
        id: strip

        required property var modelData
        required property int index
        readonly property bool current: root.control.selected === index

        width: ListView.view.width
        height: root.strip

        Item {
            id: paper

            width: parent.width
            height: parent.height
            // The selected one stands forward.
            scale: strip.current ? 1.025 : 1
            z: strip.current ? 1 : 0

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            RectangularShadow {
                anchors.fill: parent
                radius: 2
                offset.y: strip.current ? 4 : 1
                blur: strip.current ? 8 : 2
                color: Qt.alpha("black", strip.current ? 0.7 : 0.4)
            }
            Card {
                anchors.fill: parent
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

            Frame {
                anchors.fill: parent
            }
            ModeDial {
                x: 6
                y: 8
            }
            C.TextField {
                id: field

                x: 186
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - 14
                prompt: root.control.prompt
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

                Layout.fillWidth: true
                implicitHeight: root.slots * (root.strip + root.gap) - root.gap + 2 * 14

                // The chrome frame.
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#e9eaee" }
                        GradientStop { position: 0.15; color: "#9a9ca3" }
                        GradientStop { position: 0.5; color: "#d4d6db" }
                        GradientStop { position: 0.85; color: "#7c7e85" }
                        GradientStop { position: 1; color: "#babcc2" }
                    }
                }
                // The inside, backlit warm.
                Rectangle {
                    id: inside

                    anchors {
                        fill: parent
                        margins: 4
                    }
                    radius: 3
                    color: "#17110b"
                    border.width: 1
                    border.color: "black"
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.alpha("#ffb25e", 0.05) }
                            GradientStop { position: 0.5; color: Qt.alpha("#ffb25e", 0.2) }
                            GradientStop { position: 1; color: Qt.alpha("#ffb25e", 0.05) }
                        }
                    }

                    // Blank strips in every slot; the results stand over them.
                    Column {
                        x: 26
                        y: 10
                        spacing: root.gap

                        Repeater {
                            model: root.slots

                            Card {
                                required property int index

                                width: inside.width - 26 - 12
                                height: root.strip
                                opacity: 0.85

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

                        x: 26
                        y: 10
                        width: inside.width - 26 - 12
                        height: root.slots * (root.strip + root.gap) - root.gap
                        spacing: root.gap
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.control.results
                        delegate: Strip {}
                        // The rack flips along to keep the selection in view.
                        // (A new model resets currentIndex, so it's set again.)
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

                    // The pointer lamp in the margin, at the selected strip.
                    Led {
                        x: 9
                        y: list.y + (list.currentItem ? list.currentItem.y - list.contentY : 0) + (root.strip - height) / 2
                        size: 9
                        on: list.count > 0
                        color: Theme.palette.warn
                        visible: list.count > 0

                        Behavior on y {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
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
            Item {
                Layout.fillHeight: true
                implicitWidth: 76

                Frame {
                    anchors.fill: parent
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 12
                    spacing: 10

                    Repeater {
                        model: root.control.actions

                        C.IconButton {
                            required property var modelData

                            anchors.horizontalCenter: parent.horizontalCenter
                            size: 34
                            icon: modelData.icon
                            enabled: !(modelData.busy && root.control.capturing)
                            opacity: enabled ? 1 : 0.4
                            onClicked: modelData.run()
                        }
                    }
                }

                // SELECT, with the NEW lamp over it.
                Column {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 12
                    }
                    spacing: 6

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5

                        Led {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 7
                            on: root.fresh
                            color: Theme.palette.accent
                        }
                        Legend {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "new"
                            size: 7
                        }
                    }
                    C.IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: 56
                        size: 48
                        icon: "\u{F0311}"
                        lit: root.selecting
                        enabled: list.count > 0
                        opacity: enabled || root.selecting ? 1 : 0.4
                        onClicked: root.control.run(root.control.selected, 0)
                    }
                    Legend {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "select"
                        size: 8
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
