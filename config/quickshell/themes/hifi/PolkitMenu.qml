import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.polkit as M

// A plain agreement on top of a stack of paper: POLKIT at the head, one
// paragraph saying who allows which app to do what, and a line to sign on.
// The password goes down on it as a pen signature, a stroke for each
// letter, never the letters themselves (shown as written when the request
// isn't secret). Enter signs; a wrong one gets DENIED stamped across it in
// red and the paper shakes; sign again. Where there's more than one
// account to sign as, click the name to change it.
Item {
    id: root

    required property M.PolkitAsk control

    readonly property color pen: "#1f3a8a"
    readonly property color ink: "#1e1e1e"
    readonly property color red: "#b3261e"
    readonly property real margin: 54
    // The app asking: its part of the action's name (org.freedesktop.
    // systemd1.manage-units: systemd1).
    readonly property string app: {
        const parts = (control.flow?.actionId ?? "").split(".");
        return parts.length >= 3 ? parts[parts.length - 2] : parts[0] || "an app";
    }
    // What it's asking, as polkit puts it, less its "Authentication is
    // required to".
    readonly property string message: control.flow?.message ?? ""
    readonly property string asks: message.replace(/^\s*authentication is required (to|for)\s+/i, "")
    // The last signature, denied, until signing again; how long it was.
    property bool struck: false
    property int lastLength: 0
    // How long a signature to draw: the one being written, or the denied one.
    readonly property int signed: field.text.length || (struck ? lastLength : 0)

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
    function escaped(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    Connections {
        target: root.control

        function onActiveChanged(): void {
            field.text = "";
            root.struck = false;
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
        id: sheet

        anchors.centerIn: parent
        width: 560
        height: body.height + 2 * root.margin

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
            anchors.margins: -4
            offset.y: 12
            blur: 30
            color: Qt.alpha("black", 0.6)
        }
        // The sheets under it.
        Repeater {
            model: [[6, 7, 1.2], [3, 3.5, -0.6]]

            Rectangle {
                required property var modelData

                x: modelData[0]
                y: modelData[1]
                width: sheet.width
                height: sheet.height
                rotation: modelData[2]
                color: "#ecebe6"
                border.width: 1
                border.color: "#cfcdc6"
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "#fbfbf8"
            border.width: 1
            border.color: "#d6d4cc"
        }

        Column {
            id: body

            x: root.margin
            y: root.margin
            width: sheet.width - 2 * root.margin
            spacing: 26

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "POLKIT"
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: 30
                font.bold: true
                font.letterSpacing: 2
            }

            // The paragraph.
            Text {
                width: parent.width
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                lineHeight: 1.35
                color: root.ink
                font.family: Theme.font.family
                font.pixelSize: 14
                linkColor: root.ink
                text: {
                    const who = root.escaped(root.control.nameOf(root.control.identity) || "the undersigned");
                    const name = root.control.identities.length > 1 ? `<a href="who"><b>${who}</b></a>` : `<b>${who}</b>`;
                    const app = `<b>${root.escaped(root.app)}</b>`;
                    const asks = root.asks !== root.message
                        ? `to <b>${root.escaped(root.asks)}</b>`
                        : `the following: <b>${root.escaped(root.message)}</b>`;
                    return `I, ${name}, allow ${app} ${asks}`;
                }
                // Another account to sign as.
                onLinkActivated: {
                    const ids = root.control.identities;
                    root.control.choose(ids[(ids.indexOf(root.control.identity) + 1) % ids.length]);
                }

                HoverHandler {
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            // ── The signature ────────────────────────────────────────────────
            Item {
                width: parent.width * 0.7
                height: 92

                Item {
                    id: sign

                    width: parent.width
                    height: 66

                    Text {
                        y: parent.height - 24
                        text: "✗"
                        color: root.ink
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
                    Text {
                        y: parent.height + 6
                        text: (root.control.flow?.inputPrompt ?? "").replace(/:\s*$/, "").toLowerCase() || "password"
                        color: root.ink
                        opacity: 0.55
                        font.family: Theme.font.family
                        font.pixelSize: 10
                    }
                }

                // DENIED, stamped across it.
                Item {
                    x: sign.width * 0.22
                    y: 6
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
                height: 18

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property string extra: root.control.flow?.supplementaryMessage ?? ""

                    width: parent.width - choices.width - 20
                    text: root.control.checking ? "Checking…" : extra
                    elide: Text.ElideRight
                    color: root.control.flow?.supplementaryIsError ? root.red : root.ink
                    opacity: 0.7
                    font.family: Theme.font.family
                    font.pixelSize: 11
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

                        Text {
                            required property var modelData

                            text: modelData.text
                            color: root.ink
                            opacity: hit.containsMouse || modelData.strong ? 1 : 0.55
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
    }
}
