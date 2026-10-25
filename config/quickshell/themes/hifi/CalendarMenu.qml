import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.core
import qs.modules.calendar as M

// A kitchen wall calendar, hung on a nail behind the panel, under the clock.
// It comes folded, blank but for its binding, swinging down from behind the
// panel on its wire hanger, rocks to a stop and unfolds its month down from
// over the picture; going, it folds up and swings back up behind the panel.
//
// Each leaf is a picture (made up for the month; its moon is the real one,
// as it is on the day picked, today until another is) over
// the month: its name, the days in a grid with the ISO weeks in the margin.
// Today is ringed in red marker, the days gone are struck through in pencil,
// the day picked is ringed in pencil, and each calendar with something on a
// day leaves a stroke of its color in that day's square.
//
// Turning the month: the corner of the leaf is dog-eared; take it (or scroll
// down) and the leaf rolls up from the bottom, its blank back outward, and
// goes over the binding onto the leaves already turned, bunched up behind
// it. Take those (or scroll up) and the last one unrolls down over the one
// showing. The red ribbon riffles back to this month.
//
// With a calendar server, the leaf folds out a third time: a ruled page
// with the picked day's events in their calendars' ink, as long as it needs
// to be. Pick another day and it folds up and down again with it; pick the
// same one again and it folds away.
Item {
    id: root

    required property M.CalendarPanel control

    readonly property real sheet: 460          // the paper's width
    readonly property real side: 36            // room to swing
    readonly property real hook: 34            // the drop's top, down to the paper's
    // The nail, behind the middle of the panel (the drop's padding above us).
    readonly property real nail: -(Theme.barHeight / 2 + 14)
    // The picture is as tall as the month, so the month folded up over it
    // covers it.
    readonly property real pictureHeight: 352
    readonly property real monthHeight: 352
    readonly property color paper: "#f6f1e5"
    readonly property color ink: "#2a2522"
    readonly property color red: "#c0362b"
    readonly property color pencil: "#55524d"
    readonly property real cellWidth: (sheet - 40 - 16) / 7
    readonly property real cellHeight: 44

    // Hanging: `sway` turns it on its nail (-180, up behind the panel, to 0,
    // hanging), `fold` folds the month up over the picture (180) or hangs it
    // down (0), `agendaFold` the same for the agenda under it.
    property real sway: -180
    property real fold: 180
    property real agendaFold: 180
    // The day on the agenda page, and whether it's wanted out.
    property date agendaDay: control.selected
    property bool agendaWanted: false
    readonly property var agenda: control.eventsOn(agendaDay)
    readonly property real agendaHeight: 44 + Math.max(1, agenda.length) * 28 + 16
    // A leaf turning: `turn` 0-1, `turnWay` 1 on (rolling up), -1 back
    // (unrolling down). The roll: where its line is down the leaf, and how
    // thick it is with the paper on it.
    property real turn: 0
    property int turnWay: 1
    readonly property bool turning: leafTurns.running
    readonly property real leafHeight: pictureHeight + monthHeight
    readonly property real rollLine: leafHeight * (turnWay > 0 ? 1 - turn : turn)
    readonly property real rollRadius: 7 + 11 * (1 - rollLine / leafHeight)

    implicitWidth: sheet + 2 * side
    implicitHeight: hook + leafHeight + (agendaFold < 179 ? agendaHeight : 0) + 40

    function hash(n: real): real {
        const x = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    function pickDay(d: date): void {
        if (!control.eventsAvailable) {
            control.select(d);
            return;
        }
        if (agendaWanted && control.sameDay(d, agendaDay) && control.sameDay(d, control.selected)) {
            agendaWanted = false;
            agendaOut.stop();
            agendaIn.restart();
            return;
        }
        control.select(d);
        if (agendaFold < 1) {
            agendaFlip.restart();
        } else {
            agendaDay = d;
            agendaWanted = true;
            agendaIn.stop();
            agendaOut.restart();
        }
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            for (const a of [hangUp, takeDown, agendaIn, agendaOut, agendaFlip, leafTurns])
                a.stop();
            if (root.control.open) {
                root.agendaDay = root.control.selected;
                root.agendaWanted = root.control.eventsAvailable;
                hangUp.restart();
            } else {
                takeDown.restart();
            }
        }
        function onTurned(months: int): void {
            root.turn = 0;
            root.turnWay = months > 0 ? 1 : -1;
            leafTurns.count = Math.min(4, Math.abs(months));
            leafTurns.restart();
        }
    }

    // Hung up: down from behind the panel, swinging past and rocking to a
    // stop, the month unfolding as it settles, then the agenda.
    SequentialAnimation {
        id: hangUp

        NumberAnimation { target: root; property: "sway"; from: -180; to: 0; duration: 620; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "sway"; to: 14; duration: 170; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: root; property: "sway"; to: 0; duration: 1100; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.45 }
            SequentialAnimation {
                PauseAnimation { duration: 260 }
                NumberAnimation { target: root; property: "fold"; to: 0; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                ScriptAction {
                    script: if (root.agendaWanted) agendaOut.restart()
                }
            }
        }
    }
    // Taken down: folded up and swung back up behind the panel.
    SequentialAnimation {
        id: takeDown

        NumberAnimation { target: root; property: "agendaFold"; to: 180; duration: root.agendaFold < 179 ? 180 : 0; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "fold"; to: 180; duration: 260; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "sway"; to: -180; duration: 640; easing.type: Easing.OutQuad }
    }
    NumberAnimation {
        id: agendaOut

        target: root
        property: "agendaFold"
        to: 0
        duration: 380
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }
    NumberAnimation {
        id: agendaIn

        target: root
        property: "agendaFold"
        to: 180
        duration: 220
        easing.type: Easing.InCubic
    }
    // Another day: up, and down again with it.
    SequentialAnimation {
        id: agendaFlip

        NumberAnimation { target: root; property: "agendaFold"; to: 180; duration: 180; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.agendaDay = root.control.selected;
                root.agendaWanted = true;
            }
        }
        NumberAnimation { target: root; property: "agendaFold"; to: 0; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }

    // Leaves turning, one after another for a jump of months (a riffle).
    // The agenda folds away first, and comes back after.
    SequentialAnimation {
        id: leafTurns

        property int count: 1
        property bool tucked: false

        ScriptAction {
            script: leafTurns.tucked = root.agendaFold < 179
        }
        NumberAnimation { target: root; property: "agendaFold"; to: 180; duration: leafTurns.tucked ? 150 : 0; easing.type: Easing.InCubic }
        SequentialAnimation {
            loops: leafTurns.count

            NumberAnimation {
                target: root
                property: "turn"
                from: 0
                to: 1
                duration: leafTurns.count > 1 ? 260 : 620
                easing.type: Easing.InOutQuad
            }
        }
        ScriptAction {
            script: {
                root.turn = 0;
                if (leafTurns.tucked && root.agendaWanted)
                    agendaOut.restart();
            }
        }
    }

    // A ring drawn round something by hand, in `ink`: not quite round, the
    // stroke running on past where it started.
    component Ring: Shape {
        id: ring

        property color ink: root.red
        property real thickness: 2.4
        property real seed: 1
        readonly property var points: {
            const n = 44;
            const a0 = root.hash(seed) * 6.283;
            const sweep = 6.283 + 0.45 + root.hash(seed + 1) * 0.5;
            const p0 = root.hash(seed + 2) * 6, p1 = root.hash(seed + 3) * 6;
            const pts = [];
            for (let i = 0; i <= n; i++) {
                const t = i / n, a = a0 + t * sweep;
                const rx = width / 2 * (1 + 0.05 * Math.sin(a * 2 + p0) + 0.05 * t);
                const ry = height / 2 * (1 + 0.06 * Math.sin(a * 3 + p1) + 0.05 * t);
                pts.push(Qt.point(width / 2 + Math.cos(a) * rx, height / 2 + Math.sin(a) * ry));
            }
            return pts;
        }

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: ring.ink
            strokeWidth: ring.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline { path: ring.points }
        }
    }

    // A sheet of the calendar's paper, with its shadow on the wall.
    component Paper: Item {
        RectangularShadow {
            anchors.fill: parent
            offset.y: 4
            blur: 14
            color: Qt.alpha("black", 0.45 * (Theme.values.effects?.shadow ?? 0.6))
        }
        Rectangle {
            anchors.fill: parent
            color: root.paper
            border.width: 1
            border.color: Qt.darker(root.paper, 1.15)
        }
    }

    Item {
        id: hanging

        x: root.side
        width: root.sheet
        height: root.height
        // It hangs on the nail, and swings there.
        transform: Rotation {
            origin.x: root.sheet / 2
            origin.y: root.nail
            angle: root.sway
        }

        // The nail, and the wire hanger from it to the binding.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "#7d7f85"
                strokeWidth: 1.6
                fillColor: "transparent"
                startX: root.sheet / 2 - 40
                startY: root.hook + 4

                PathLine { x: root.sheet / 2; y: root.nail }
                PathLine { x: root.sheet / 2 + 40; y: root.hook + 4 }
            }
        }
        Rectangle {
            x: root.sheet / 2 - 4
            y: root.nail - 4
            width: 8
            height: 8
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0; color: "#d9dbdf" }
                GradientStop { position: 1; color: "#5c5e63" }
            }
        }

        // The leaves already turned, bunched up over the binding. Take them
        // to bring the last one back down.
        Item {
            id: turned

            x: 10
            y: root.hook - 12
            width: root.sheet - 20
            height: 14
            visible: root.fold < 90

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    x: index * 2
                    y: 6 - index * 3
                    width: turned.width - index * 4
                    height: 8
                    radius: 3
                    color: Qt.darker(root.paper, 1.04 + index * 0.03)
                    border.width: 1
                    border.color: Qt.darker(root.paper, 1.25)
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.control.shift(-1)
            }
        }

        // The current leaf: the picture, then the month folding down from
        // its foot.
        Item {
            id: leaf

            y: root.hook
            width: root.sheet
            height: root.leafHeight

            Paper {
                width: parent.width
                height: root.pictureHeight

                Landscape {
                    x: 16
                    y: 24
                    width: parent.width - 32
                    height: parent.height - 24 - 18
                    year: root.control.viewYear
                    month: root.control.viewMonth
                    // The moon of the day picked: today's, until another is.
                    moonDay: root.control.selected
                }
            }

            // The month.
            Item {
                id: month

                y: root.pictureHeight
                width: root.sheet
                height: root.monthHeight
                transform: Rotation {
                    origin.y: 0
                    axis { x: 1; y: 0; z: 0 }
                    angle: root.fold
                }

                Paper {
                    anchors.fill: parent
                }
                // Its back, while it's folded over.
                Rectangle {
                    anchors.fill: parent
                    color: Qt.darker(root.paper, 1.08)
                    visible: root.fold > 90
                    z: 2
                }

                Text {
                    x: 18
                    y: 12
                    text: Qt.locale().monthName(root.control.viewMonth).toUpperCase()
                    color: root.ink
                    font.family: Theme.font.family
                    font.pixelSize: 26
                    font.bold: true
                    font.letterSpacing: 5
                }
                Text {
                    anchors {
                        right: parent.right
                        rightMargin: 16
                    }
                    y: 16
                    text: root.control.viewYear
                    color: root.red
                    font.family: Theme.font.family
                    font.pixelSize: 20
                    font.bold: true
                    font.letterSpacing: 3
                }

                // The weekdays over their columns, the weeks down the side.
                Repeater {
                    model: 7

                    Text {
                        required property int index
                        readonly property int weekday: (root.control.weekStart + index) % 7

                        x: 40 + index * root.cellWidth
                        y: 54
                        width: root.cellWidth
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.locale().dayName(weekday, Locale.ShortFormat).slice(0, 2).toUpperCase()
                        color: weekday === 0 ? root.red : Qt.alpha(root.ink, 0.7)
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }
                Repeater {
                    model: 6

                    Text {
                        required property int index

                        x: 16
                        y: 72 + index * root.cellHeight + 4
                        text: String(root.control.isoWeek(root.control.days[index * 7 + 3])).padStart(2, "0")
                        color: Qt.alpha(root.ink, 0.4)
                        font.family: Theme.font.family
                        font.pixelSize: 9
                    }
                }

                // The grid's rules.
                Repeater {
                    model: 7

                    Rectangle {
                        required property int index

                        x: 40
                        y: 72 + index * root.cellHeight
                        width: 7 * root.cellWidth
                        height: 1
                        color: Qt.alpha(root.ink, 0.18)
                    }
                }
                Repeater {
                    model: 8

                    Rectangle {
                        required property int index

                        x: 40 + index * root.cellWidth
                        y: 72
                        width: 1
                        height: 6 * root.cellHeight
                        color: Qt.alpha(root.ink, 0.18)
                    }
                }

                // The days.
                Repeater {
                    model: 42

                    Item {
                        id: cell

                        required property int index
                        readonly property date day: root.control.days[index] ?? new Date()
                        readonly property bool inMonth: day.getMonth() === root.control.viewMonth
                        readonly property bool isToday: root.control.sameDay(day, root.control.today)
                        readonly property bool gone: inMonth && day < new Date(root.control.today.getFullYear(), root.control.today.getMonth(), root.control.today.getDate())
                        readonly property var inks: [...new Set(root.control.eventsOn(day).map(e => e.color))].slice(0, 3)
                        readonly property real seed: day.getFullYear() * 400 + day.getMonth() * 32 + day.getDate()

                        x: 40 + (index % 7) * root.cellWidth
                        y: 72 + Math.floor(index / 7) * root.cellHeight
                        width: root.cellWidth
                        height: root.cellHeight

                        Text {
                            x: 6
                            y: 4
                            text: cell.day.getDate()
                            color: !cell.inMonth ? Qt.alpha(root.ink, 0.25) : cell.day.getDay() === 0 ? root.red : root.ink
                            font.family: Theme.font.family
                            font.pixelSize: 13
                            font.bold: true
                        }
                        // A stroke of each calendar's color.
                        Repeater {
                            model: cell.inks

                            Rectangle {
                                required property int index
                                required property color modelData

                                x: 6 + index * 15
                                y: cell.height - 9 - root.hash(cell.seed + index) * 3
                                width: 13
                                height: 3
                                radius: 1.5
                                rotation: -8 + root.hash(cell.seed + index * 7) * 10
                                color: Qt.alpha(modelData, 0.85)
                            }
                        }
                        // Struck through in pencil once it's gone.
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.hypot(parent.width, parent.height) - 12
                            height: 1.3
                            rotation: -Math.atan2(parent.height, parent.width) * 180 / Math.PI + (root.hash(cell.seed) - 0.5) * 8
                            color: Qt.alpha(root.pencil, 0.5)
                            visible: cell.gone
                        }
                        Ring {
                            x: 2
                            y: 1
                            width: parent.width - 4
                            height: parent.height - 2
                            ink: Qt.alpha(root.red, 0.85)
                            thickness: 2.6
                            seed: cell.seed
                            visible: cell.isToday
                        }
                        Ring {
                            x: 4
                            y: 3
                            width: parent.width - 8
                            height: parent.height - 6
                            ink: Qt.alpha(root.pencil, 0.75)
                            thickness: 1.3
                            seed: cell.seed + 0.5
                            visible: !cell.isToday && root.control.sameDay(cell.day, root.control.selected)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pickDay(cell.day)
                        }
                    }
                }

                // The dog-eared corner: take it to turn the leaf.
                Item {
                    id: corner

                    // Turned up further when the hand's on it.
                    property real flap: cornerArea.containsMouse ? 34 : 26

                    x: parent.width - flap
                    y: parent.height - flap
                    width: flap
                    height: flap

                    Behavior on flap {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    // The next leaf showing under it, then the corner turned up.
                    Shape {
                        anchors.fill: parent

                        ShapePath {
                            strokeColor: "transparent"
                            fillColor: Qt.darker(root.paper, 1.06)
                            startX: corner.width
                            startY: 0

                            PathLine { x: corner.width; y: corner.height }
                            PathLine { x: 0; y: corner.height }
                        }
                        ShapePath {
                            strokeColor: Qt.darker(root.paper, 1.3)
                            strokeWidth: 1
                            fillGradient: LinearGradient {
                                x1: corner.width; y1: corner.height
                                x2: corner.width / 2; y2: corner.height / 2
                                GradientStop { position: 0; color: "#fffdf7" }
                                GradientStop { position: 1; color: "#d9d1bf" }
                            }
                            startX: corner.width
                            startY: 0

                            PathLine { x: 0; y: corner.height }
                            PathLine { x: 0; y: 0 }
                        }
                    }
                    MouseArea {
                        id: cornerArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.control.shift(1)
                    }
                }

                // Scroll to turn.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: wheel => root.control.shift(wheel.angleDelta.y > 0 ? -1 : 1)
                    z: -1
                }

                // The agenda, folding down from the month's foot.
                Item {
                    id: agendaPage

                    y: root.monthHeight
                    width: root.sheet
                    height: root.agendaHeight
                    visible: root.control.eventsAvailable && root.agendaFold < 179
                    transform: Rotation {
                        origin.y: 0
                        axis { x: 1; y: 0; z: 0 }
                        angle: root.agendaFold
                    }

                    Paper {
                        anchors.fill: parent
                    }
                    // Ruled, with a margin.
                    Repeater {
                        model: Math.max(1, root.agenda.length)

                        Rectangle {
                            required property int index

                            x: 8
                            y: 44 + (index + 1) * 28 - 2
                            width: parent.width - 16
                            height: 1
                            color: Qt.alpha("#6b93c4", 0.45)
                        }
                    }
                    Rectangle {
                        x: 62
                        y: 36
                        width: 1
                        height: parent.height - 44
                        color: Qt.alpha(root.red, 0.5)
                    }
                    Text {
                        x: 16
                        y: 12
                        text: Qt.formatDate(root.agendaDay, "dddd d MMMM").toUpperCase()
                        color: root.ink
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Repeater {
                        model: root.agenda

                        Item {
                            id: entry

                            required property int index
                            required property var modelData

                            y: 44 + index * 28
                            width: parent.width
                            height: 28
                            opacity: modelData.end < root.control.now ? 0.5 : 1

                            Text {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.allDay ? "ALL DAY" : Qt.formatTime(entry.modelData.start, "HH:mm")
                                color: Qt.alpha(root.ink, 0.75)
                                font.family: Theme.font.family
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Rectangle {
                                x: 72
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 3.5
                                color: entry.modelData.color
                            }
                            Text {
                                x: 86
                                width: parent.width - x - 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.summary + (entry.modelData.location ? `  · ${entry.modelData.location}` : "")
                                elide: Text.ElideRight
                                color: Qt.darker(entry.modelData.color, 1.6)
                                font.family: Theme.font.family
                                font.pixelSize: 12
                            }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.darker(root.paper, 1.08)
                        visible: root.agendaFold > 90
                    }
                }
            }
        }

        // A leaf turning. The leaf as it was (a picture of it, kept current
        // until the turn) and as it is now (a live picture; the leaf itself
        // is hidden meanwhile): rolling on, the old one rolls up off the new;
        // rolling back, the new one unrolls down over the old. The roll
        // between them shows the paper's blank back, with its shadow under
        // it.
        // (Drawn all the time, clipped away to its top line under the
        // binding, so that it's current.)
        Item {
            y: root.hook
            width: root.sheet
            height: 1
            clip: true

            ShaderEffectSource {
                id: before

                width: root.sheet
                height: root.leafHeight
                sourceItem: leaf
                live: !root.turning
            }
        }
        ShaderEffectSource {
            id: after

            width: root.sheet
            height: root.leafHeight
            sourceItem: root.turning ? leaf : null
            sourceRect: Qt.rect(0, 0, root.sheet, root.leafHeight)
            hideSource: root.turning
            visible: false
        }
        Item {
            y: root.hook
            width: root.sheet
            height: root.leafHeight
            visible: root.turning

            // Above the roll: the leaf that's rolling (on), or coming down
            // (back).
            Item {
                width: parent.width
                height: Math.max(0, root.rollLine)
                clip: true

                ShaderEffect {
                    width: root.sheet
                    height: root.leafHeight
                    property var source: root.turnWay > 0 ? before : after
                }
            }
            // Under it: the leaf it uncovers (on), or the one it covers
            // (back).
            Item {
                y: Math.min(parent.height, root.rollLine + root.rollRadius)
                width: parent.width
                height: parent.height - y
                clip: true

                ShaderEffect {
                    y: -parent.y
                    width: root.sheet
                    height: root.leafHeight
                    property var source: root.turnWay > 0 ? after : before
                }
                // The roll's shadow.
                Rectangle {
                    width: parent.width
                    height: 14
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha("black", 0.3) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }
            // The roll: the paper's back, round.
            Rectangle {
                y: root.rollLine - root.rollRadius
                width: parent.width
                height: 2 * root.rollRadius
                opacity: Math.min(1, root.rollLine / (2 * root.rollRadius) + 0.2)
                radius: root.rollRadius
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.darker(root.paper, 1.14) }
                    GradientStop { position: 0.3; color: Qt.lighter(root.paper, 1.01) }
                    GradientStop { position: 0.65; color: Qt.darker(root.paper, 1.03) }
                    GradientStop { position: 1; color: Qt.darker(root.paper, 1.2) }
                }
            }
        }

        // The binding: a wire spiral through the top of the paper.
        Row {
            x: 18
            y: root.hook - 6
            spacing: 6

            Repeater {
                model: Math.floor((root.sheet - 36) / 9)

                Rectangle {
                    width: 3
                    height: 14
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#5c5e63" }
                        GradientStop { position: 0.5; color: "#e3e5e8" }
                        GradientStop { position: 1; color: "#4a4c51" }
                    }
                }
            }
        }

        // The ribbon, back to this month.
        Item {
            id: ribbon

            property real tug: 0

            x: 2
            y: root.hook - 4
            width: 9
            visible: root.fold < 90
            height: root.leafHeight + 24 + tug
            z: 3

            SequentialAnimation {
                id: tugged

                NumberAnimation { target: ribbon; property: "tug"; to: 10; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: ribbon; property: "tug"; to: 0; duration: 260; easing.type: Easing.OutBack }
            }

            Shape {
                anchors.fill: parent

                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: ribbon.width; y2: 0
                        GradientStop { position: 0; color: "#8f1f18" }
                        GradientStop { position: 0.45; color: "#d4463a" }
                        GradientStop { position: 1; color: "#9d241c" }
                    }
                    startX: 0
                    startY: 0

                    PathLine { x: ribbon.width; y: 0 }
                    PathLine { x: ribbon.width; y: ribbon.height }
                    PathLine { x: ribbon.width / 2; y: ribbon.height - 7 }
                    PathLine { x: 0; y: ribbon.height }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tugged.restart();
                    root.control.goToday();
                }
            }
        }
    }
}
