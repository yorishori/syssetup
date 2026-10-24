import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.polkit as M

// The sign-in book at the desk: a ruled page with its columns, TIME, NAME,
// FOR, SIGNATURE, and on the next free line the request, filled in for
// you: the time, who you're signing as (ringed in pencil, where there's a
// choice), what it's for. Sign for it: the password goes down as a pen
// signature, a stroke for each letter, never the letters themselves
// (shown as written when the request isn't secret). Enter hands the book
// back; a wrong one is struck through in red and the page shakes, sign
// again. The choices are printed at the foot of the page.
Item {
    id: root

    required property M.PolkitAsk control

    readonly property color pen: "#1f3a8a"
    readonly property color ink: "#2a2824"
    readonly property color red: "#b8402e"
    readonly property color paper: "#f2ecdc"
    readonly property color rule: "#9fb9c9"
    readonly property real lineHeight: 30
    // The columns: [title, width].
    readonly property var columns: [["TIME", 70], ["NAME", 130], ["FOR", 250], ["SIGNATURE", 200]]
    // The last signature, struck through, until signing again; how long
    // it was.
    property bool struck: false
    property int lastLength: 0
    // How long a signature to draw: the one being written, or the struck one.
    readonly property int signed: field.text.length || (struck ? lastLength : 0)
    property string time: Qt.formatTime(new Date(), "HH:mm")

    function refocus(): void {
        if (root.control.active)
            field.forceActiveFocus();
    }
    function submit(): void {
        const length = field.text.length;
        if (root.control.submit(field.text)) {
            root.lastLength = length;
            field.text = "";
        }
    }

    Connections {
        target: root.control

        function onActiveChanged(): void {
            field.text = "";
            root.struck = false;
            root.time = Qt.formatTime(new Date(), "HH:mm");
        }
        function onDenied(): void {
            root.struck = true;
            shakeAnim.restart();
        }
        function onRefocusRequested(): void {
            root.refocus();
        }
    }

    // The response, typed; the signature's drawn from how long it is.
    TextInput {
        id: field

        width: 1
        height: 1
        opacity: 0
        echoMode: root.control.hidden ? TextInput.Password : TextInput.Normal
        onTextChanged: {
            if (text !== "")
                root.struck = false;
        }
        onAccepted: root.submit()
        onActiveFocusChanged: {
            if (!activeFocus)
                Qt.callLater(root.refocus);
        }
        Keys.onEscapePressed: root.control.cancel()
    }

    Item {
        id: page

        anchors.centerIn: parent
        width: 2 * 44 + root.columns.reduce((w, c) => w + c[1], 0)
        height: 58 + 2 * root.lineHeight + entry.height + 2 * root.lineHeight + 64

        transform: Translate {
            id: shake
        }
        SequentialAnimation {
            id: shakeAnim

            NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: -6; duration: 60 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 90; easing.type: Easing.OutBack }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: 3
            offset.y: 10
            blur: 30
            color: Qt.alpha("black", 0.6)
        }
        Rectangle {
            anchors.fill: parent
            radius: 3
            color: root.paper
            border.width: 1
            border.color: "#c9bea2"
        }
        // The margin, in red.
        Rectangle {
            x: 34
            width: 1
            height: parent.height
            color: Qt.alpha(root.red, 0.45)
        }

        // ── The heads ────────────────────────────────────────────────────────
        Row {
            id: heads

            x: 44
            y: 26

            Repeater {
                model: root.columns

                Text {
                    required property var modelData

                    width: modelData[1]
                    text: modelData[0]
                    color: root.ink
                    opacity: 0.7
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 2
                }
            }
        }

        // The rules: a couple of lines, the entry, a couple more.
        Repeater {
            model: [58, 58 + root.lineHeight, 58 + 2 * root.lineHeight, 58 + 2 * root.lineHeight + entry.height, 58 + 3 * root.lineHeight + entry.height, 58 + 4 * root.lineHeight + entry.height]

            Rectangle {
                required property real modelData

                x: 10
                y: modelData - 1
                width: page.width - 20
                height: 1
                color: Qt.alpha(root.rule, 0.8)
            }
        }
        // The column lines.
        Repeater {
            model: root.columns.slice(1).map((c, i) => 44 + root.columns.slice(0, i + 1).reduce((w, d) => w + d[1], 0) - 10)

            Rectangle {
                required property real modelData

                x: modelData
                y: 20
                width: 1
                height: 58 + 4 * root.lineHeight + entry.height - 20
                color: Qt.alpha(root.rule, 0.6)
            }
        }

        // ── The entry ────────────────────────────────────────────────────────
        Item {
            id: entry

            x: 44
            y: 58 + 2 * root.lineHeight
            width: page.width - 88
            height: Math.max(3 * root.lineHeight, request.height + 16)

            component Pen: Text {
                color: root.pen
                font.family: Theme.font.family
                font.pixelSize: 13
                font.italic: true
            }

            Pen {
                y: 8
                text: root.time
            }
            // Who you're signing as; ringed, where there's a choice.
            Column {
                x: root.columns[0][1]
                y: 8
                width: root.columns[1][1] - 14
                spacing: 4

                Pen {
                    width: parent.width
                    text: root.control.nameOf(root.control.identity)
                    elide: Text.ElideRight
                    visible: root.control.identities.length <= 1
                }
                Repeater {
                    model: root.control.identities.length > 1 ? root.control.identities : []

                    Item {
                        id: who

                        required property var modelData
                        readonly property bool chosen: root.control.identity === modelData

                        width: parent.width
                        height: 22

                        Rectangle {
                            x: -4
                            width: Math.min(parent.width, whoName.contentWidth + 10)
                            height: parent.height
                            radius: height / 2
                            rotation: -2
                            color: "transparent"
                            border.width: 1.3
                            border.color: Qt.alpha("#4a4a4a", 0.7)
                            visible: who.chosen
                        }
                        Pen {
                            id: whoName

                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            text: root.control.nameOf(who.modelData)
                            elide: Text.ElideRight
                            opacity: who.chosen ? 1 : 0.55
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.control.choose(who.modelData)
                        }
                    }
                }
            }
            // What it's for.
            Column {
                id: request

                x: root.columns[0][1] + root.columns[1][1]
                y: 8
                width: root.columns[2][1] - 16
                spacing: 3

                Text {
                    width: parent.width
                    text: root.control.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    color: root.ink
                    font.family: Theme.font.family
                    font.pixelSize: 12
                }
                Text {
                    width: parent.width
                    text: root.control.flow?.actionId ?? ""
                    elide: Text.ElideMiddle
                    color: root.ink
                    opacity: 0.5
                    font.family: Theme.font.family
                    font.pixelSize: 9
                }
            }
            // The signature.
            Item {
                id: sign

                x: root.columns[0][1] + root.columns[1][1] + root.columns[2][1]
                width: root.columns[3][1]
                height: parent.height

                Canvas {
                    id: signature

                    anchors.fill: parent
                    visible: root.control.hidden
                    onVisibleChanged: requestPaint()
                    Connections {
                        target: root

                        function onSignedChanged(): void {
                            signature.requestPaint();
                        }
                    }
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const n = root.signed;
                        if (n === 0)
                            return;
                        ctx.strokeStyle = root.pen;
                        ctx.lineWidth = 1.6;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        // The same flourish every time: it only says how much.
                        let seed = 7;
                        const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
                        const base = height * 0.55;
                        const step = Math.min(14, (width - 24) / Math.max(1, n));
                        let x = 6, y = base;
                        ctx.beginPath();
                        ctx.moveTo(x, y);
                        for (let i = 0; i < n; i++) {
                            const up = (i % 2 ? 1 : -1) * (6 + rnd() * 12);
                            const nx = x + step;
                            ctx.bezierCurveTo(x + step * 0.2, y + up, nx - step * 0.1, base - up * 0.6, nx, base + (rnd() - 0.5) * 6);
                            x = nx;
                            y = base;
                        }
                        // The flourish under it.
                        ctx.quadraticCurveTo(x + 14, base + 14, 8, base + 12);
                        ctx.stroke();
                    }
                }
                // Not secret: as written.
                Text {
                    x: 6
                    y: 8
                    width: parent.width - 12
                    text: field.text
                    elide: Text.ElideLeft
                    visible: !root.control.hidden
                    color: root.pen
                    font.family: Theme.font.family
                    font.pixelSize: 14
                    font.italic: true
                }
                // Where to sign.
                Text {
                    x: 6
                    y: parent.height - 18
                    text: root.control.flow?.inputPrompt ? `✗ ${(root.control.flow.inputPrompt).replace(/:\s*$/, "").toLowerCase()}` : "✗ password"
                    color: root.ink
                    opacity: 0.4
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    visible: field.text === "" && !root.struck
                }
                // Struck through, in red.
                Rectangle {
                    x: 2
                    y: parent.height * 0.55
                    width: Math.min(parent.width - 8, root.signed * Math.min(14, (parent.width - 24) / Math.max(1, root.signed)) + 22)
                    height: 2
                    rotation: -4
                    color: root.red
                    visible: root.struck
                }
            }
        }

        // What the desk says, in pencil.
        Text {
            x: 44
            y: 58 + 4 * root.lineHeight + entry.height + 8
            width: page.width - 88
            readonly property string extra: root.control.flow?.supplementaryMessage ?? ""

            text: root.control.checking ? "checking…"
                : extra ? extra
                : root.struck || root.control.failed ? "not accepted, sign again"
                : ""
            wrapMode: Text.Wrap
            color: root.struck || root.control.failed || root.control.flow?.supplementaryIsError ? root.red : "#4a4a4a"
            font.family: Theme.font.family
            font.pixelSize: 12
            font.italic: true
        }

        // The choices, printed at the foot.
        Row {
            anchors {
                right: parent.right
                rightMargin: 44
                bottom: parent.bottom
                bottomMargin: 18
            }
            spacing: 22

            Repeater {
                model: [
                    { text: "CANCEL esc", act: () => root.control.cancel(), strong: false },
                    { text: "▸ SIGN ↵", act: () => root.submit(), strong: true }
                ]

                Text {
                    required property var modelData

                    text: modelData.text
                    color: root.ink
                    opacity: hit.containsMouse || modelData.strong ? 1 : 0.6
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.5

                    MouseArea {
                        id: hit

                        anchors {
                            fill: parent
                            margins: -5
                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.act()
                    }
                }
            }
        }
    }
}
