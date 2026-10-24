import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.polkit as M

// An authorization to sign, on heavy bond paper inside a security border of
// fine interlaced lines, like a certificate's. Under its title, the terms
// in numbered clauses: what's being asked for (and by which action), and
// who signs (ticked, where there's a choice). Then the declaration, and the
// signature line: the password goes down on it as a pen signature, a
// stroke for each letter, never the letters themselves (shown as written
// when the request isn't secret), beside the date. An embossed seal in the
// corner. Enter signs; a wrong one gets DENIED stamped across it in red and
// the paper shakes; sign again. Cancel and sign are printed at the foot.
Item {
    id: root

    required property M.PolkitAsk control

    readonly property color pen: "#1f3a8a"
    readonly property color ink: "#26241f"
    readonly property color red: "#b3261e"
    readonly property color paper: "#f6f1e3"
    readonly property color security: "#5f8a76"
    readonly property real margin: 56
    // The last signature, denied, until signing again; how long it was.
    property bool struck: false
    property int lastLength: 0
    // How long a signature to draw: the one being written, or the denied one.
    readonly property int signed: field.text.length || (struck ? lastLength : 0)
    property date opened: new Date()

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
            root.opened = new Date();
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

    // Printed text on the document.
    component Print: Text {
        color: root.ink
        font.family: Theme.font.family
        font.pixelSize: 12
    }
    // A clause's number and heading.
    component Heading: Print {
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 2.5
        opacity: 0.75
    }

    Item {
        id: sheet

        anchors.centerIn: parent
        width: 640
        height: body.height + 2 * root.margin + 10

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
            offset.y: 12
            blur: 34
            color: Qt.alpha("black", 0.65)
        }
        Rectangle {
            anchors.fill: parent
            color: root.paper
            border.width: 1
            border.color: "#cfc4a6"
        }

        // ── The security border ──────────────────────────────────────────────
        // Fine waves interlaced round a band inside the edge, between two
        // rules.
        Canvas {
            id: border

            readonly property real inset: 18
            readonly property real band: 16

            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height, i = inset, b = band;
                ctx.strokeStyle = root.security;
                ctx.lineWidth = 1;
                ctx.strokeRect(i, i, w - 2 * i, h - 2 * i);
                ctx.strokeRect(i + b, i + b, w - 2 * (i + b), h - 2 * (i + b));
                // The centre line round the band, walked by length.
                const c = i + b / 2, cw = w - 2 * c, ch = h - 2 * c;
                const length = 2 * (cw + ch);
                const at = s => {
                    s = ((s % length) + length) % length;
                    if (s < cw) return [c + s, c, 0, 1];
                    s -= cw;
                    if (s < ch) return [c + cw, c + s, -1, 0];
                    s -= ch;
                    if (s < cw) return [c + cw - s, c + ch, 0, -1];
                    s -= cw;
                    return [c, c + ch - s, 1, 0];
                };
                ctx.lineWidth = 0.6;
                const wave = Math.round(length / 18) ;
                for (let k = 0; k < 6; k++) {
                    ctx.beginPath();
                    for (let s = 0; s <= length; s += 2) {
                        const [x, y, nx, ny] = at(s);
                        const a = (b / 2 - 1.5) * Math.sin(2 * Math.PI * s * wave / length + k * Math.PI / 3);
                        if (s === 0)
                            ctx.moveTo(x + nx * a, y + ny * a);
                        else
                            ctx.lineTo(x + nx * a, y + ny * a);
                    }
                    ctx.globalAlpha = 0.55;
                    ctx.stroke();
                }
            }
        }

        // ── The document ─────────────────────────────────────────────────────
        Column {
            id: body

            x: root.margin
            y: root.margin + 4
            width: sheet.width - 2 * root.margin
            spacing: 14

            // The title.
            Column {
                width: parent.width
                spacing: 4

                Print {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "ADMINISTRATIVE PRIVILEGES"
                    font.pixelSize: 9
                    font.letterSpacing: 3
                    opacity: 0.7
                }
                Print {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "AUTHORIZATION"
                    font.pixelSize: 24
                    font.bold: true
                    font.letterSpacing: 7
                }
                Print {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `REF. ${Qt.formatDateTime(root.opened, "yyyyMMdd-HHmmss")}`
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    opacity: 0.6
                }
            }
            // A double rule.
            Column {
                width: parent.width
                spacing: 2

                Rectangle { width: parent.width; height: 1.5; color: root.ink }
                Rectangle { width: parent.width; height: 0.8; color: root.ink }
            }

            // 1. The request.
            Column {
                width: parent.width
                spacing: 5

                Heading {
                    text: "1.  REQUEST"
                }
                Print {
                    width: parent.width
                    leftPadding: 22
                    text: root.control.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.pixelSize: 13
                }
            }
            // 2. The action.
            Column {
                width: parent.width
                spacing: 5

                Heading {
                    text: "2.  ACTION"
                }
                Print {
                    width: parent.width
                    leftPadding: 22
                    text: root.control.flow?.actionId ?? ""
                    elide: Text.ElideMiddle
                    opacity: 0.75
                }
            }
            // 3. Who signs.
            Column {
                width: parent.width
                spacing: 5

                Heading {
                    text: "3.  SIGNATORY"
                }
                Flow {
                    width: parent.width
                    leftPadding: 22
                    spacing: 22

                    Repeater {
                        model: root.control.identities

                        Item {
                            id: who

                            required property var modelData
                            readonly property bool chosen: root.control.identity === modelData

                            width: whoRow.width
                            height: whoRow.height

                            Row {
                                id: whoRow

                                spacing: 8

                            // Its box, ticked.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12
                                height: 12
                                color: "transparent"
                                border.width: 1
                                border.color: root.ink
                                visible: root.control.identities.length > 1

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -1
                                    text: "✓"
                                    color: root.pen
                                    font.pixelSize: 15
                                    font.bold: true
                                    visible: who.chosen
                                }
                            }
                            Print {
                                text: root.control.nameOf(who.modelData)
                                font.pixelSize: 13
                                font.bold: who.chosen
                                opacity: who.chosen ? 1 : 0.6
                            }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.control.identities.length > 1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.control.choose(who.modelData)
                            }
                        }
                    }
                }
            }

            // The declaration.
            Print {
                width: parent.width
                topPadding: 6
                text: `I, the signatory above, confirm that I am ${root.control.nameOf(root.control.identity) || "the account named"}, and authorize the action requested under clause 2 to proceed with administrative privileges.`
                wrapMode: Text.Wrap
                font.italic: true
                opacity: 0.85
            }

            // ── The signature ────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 86

                // Signature, over its line.
                Item {
                    id: sign

                    width: parent.width * 0.62
                    height: 60

                    Print {
                        y: parent.height - 22
                        text: "✗"
                        font.pixelSize: 16
                        opacity: 0.7
                    }
                    Canvas {
                        id: signature

                        x: 20
                        width: parent.width - 20
                        height: parent.height
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
                            ctx.lineWidth = 1.7;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            // The same flourish every time: it only says how much.
                            let seed = 7;
                            const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
                            const base = height * 0.62;
                            const step = Math.min(15, (width - 30) / Math.max(1, n));
                            let x = 4;
                            ctx.beginPath();
                            ctx.moveTo(x, base);
                            for (let i = 0; i < n; i++) {
                                const up = (i % 2 ? 1 : -1) * (7 + rnd() * 14);
                                const nx = x + step;
                                ctx.bezierCurveTo(x + step * 0.2, base + up, nx - step * 0.1, base - up * 0.6, nx, base + (rnd() - 0.5) * 6);
                                x = nx;
                            }
                            ctx.quadraticCurveTo(x + 16, base + 16, 10, base + 13);
                            ctx.stroke();
                        }
                    }
                    // Not secret: as written.
                    Text {
                        x: 22
                        y: parent.height - 30
                        width: parent.width - 26
                        text: field.text
                        elide: Text.ElideLeft
                        visible: !root.control.hidden
                        color: root.pen
                        font.family: Theme.font.family
                        font.pixelSize: 15
                        font.italic: true
                    }
                    Rectangle {
                        y: parent.height
                        width: parent.width
                        height: 1
                        color: root.ink
                    }
                    Heading {
                        y: parent.height + 6
                        text: `SIGNATURE · ${(root.control.flow?.inputPrompt ?? "").replace(/:\s*$/, "").toUpperCase() || "PASSWORD"}`
                        font.pixelSize: 8
                    }
                }
                // The date, beside it.
                Item {
                    x: parent.width * 0.7
                    width: parent.width * 0.3
                    height: 60

                    Text {
                        y: parent.height - 24
                        text: Qt.formatDate(root.opened, "d MMMM yyyy")
                        color: root.pen
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        font.italic: true
                    }
                    Rectangle {
                        y: parent.height
                        width: parent.width
                        height: 1
                        color: root.ink
                    }
                    Heading {
                        y: parent.height + 6
                        text: "DATE"
                        font.pixelSize: 8
                    }
                }

                // DENIED, stamped across it.
                Item {
                    x: sign.width * 0.18
                    y: 2
                    width: stampText.implicitWidth + 28
                    height: stampText.implicitHeight + 10
                    rotation: -9
                    visible: root.struck
                    opacity: 0.85

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: "transparent"
                        border.width: 3
                        border.color: root.red
                    }
                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 5
                        }
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.red
                    }
                    Text {
                        id: stampText

                        anchors.centerIn: parent
                        text: "DENIED"
                        color: root.red
                        font.family: Theme.font.family
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 6
                    }
                }
            }

            // What's going on, and the choices.
            Item {
                width: parent.width
                height: 22

                Print {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property string extra: root.control.flow?.supplementaryMessage ?? ""

                    width: parent.width - choices.width - 20
                    text: root.control.checking ? "Verifying signature…"
                        : extra ? extra
                        : root.struck || root.control.failed ? "Signature not recognized. Sign again."
                        : ""
                    elide: Text.ElideRight
                    color: root.struck || root.control.failed || root.control.flow?.supplementaryIsError ? root.red : root.ink
                    font.italic: true
                }
                Row {
                    id: choices

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 22

                    Repeater {
                        model: [
                            { text: "CANCEL esc", act: () => root.control.cancel(), strong: false },
                            { text: "▸ SIGN ↵", act: () => root.submit(), strong: true }
                        ]

                        Print {
                            required property var modelData

                            text: modelData.text
                            opacity: hit.containsMouse || modelData.strong ? 1 : 0.6
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

        // ── The seal ─────────────────────────────────────────────────────────
        // Embossed into the paper by the title: a rosette round a padlock.
        Item {
            id: seal

            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 58
                topMargin: 50
            }
            width: 74
            height: 74

            Canvas {
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const c = width / 2;
                    // The raised paper: light above, shadow below.
                    for (const [dy, color] of [[1, "rgba(0,0,0,0.16)"], [-1, "rgba(255,255,255,0.7)"]]) {
                        ctx.strokeStyle = color;
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.arc(c, c + dy, c - 2, 0, 2 * Math.PI);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(c, c + dy, c - 12, 0, 2 * Math.PI);
                        ctx.stroke();
                        // The rosette: petals of overlapping circles.
                        for (let k = 0; k < 24; k++) {
                            const a = k * Math.PI / 12;
                            ctx.beginPath();
                            ctx.arc(c + Math.cos(a) * 8, c + dy + Math.sin(a) * 8, c - 22, 0, 2 * Math.PI);
                            ctx.stroke();
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                text: "\u{F033E}"
                color: Qt.darker(root.paper, 1.18)
                style: Text.Raised
                styleColor: Qt.alpha("white", 0.8)
                font.family: Theme.font.family
                font.pixelSize: 20
            }
        }
    }
}
