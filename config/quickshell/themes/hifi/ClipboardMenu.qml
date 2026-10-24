import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.clipboard as M

// A clipboard, the real thing: a hardboard board with a steel clip, handed
// up from the bottom of the screen. Clipped to it, a sheet per tab, the
// index tabs down its side (take one, or Tab, to turn to it):
//   history, the clips cut out as slips of paper and stuck down the sheet,
//   newest at the top: typed text, or a picture cut out and pasted;
//   the symbol sets, dry-transfer lettering sheets, a set to a sheet, the
//   one under the hand ringed in pencil, its name printed under the sheet.
// What you're looking for is written in pen at the top of the sheet. Pick
// one and it's pasted where you were (copied, with Shift).
Item {
    id: root

    required property M.ClipboardPicker control

    readonly property bool showing: rise > 0.001
    // The newest clip's at the top of the sheet.
    readonly property bool newestAtTop: true
    // Every sheet's as big, so turning to another doesn't move a thing.
    readonly property real bodyHeight: 420
    readonly property real sheetWidth: 600
    readonly property real margin: 24
    readonly property real tabRoom: 84
    readonly property real clipRoom: 46
    readonly property color pen: "#1f3a8a"
    readonly property color ink: "#2a2824"
    readonly property color paper: "#f6f3ea"
    readonly property color transfer: "#e7edef"
    // The index tabs' colors, in turn.
    readonly property var tabColors: ["#ffe14a", "#ff8a6a", "#69b6f2", "#86d873", "#c9a3f0"]
    readonly property var hints: control.onHistory
        ? "↵ PASTE   ⇧↵ COPY   ↑↓ MOVE   TAB SHEETS   ⇧DEL REMOVE   ESC CLOSE"
        : "↵ PASTE   ⇧↵ COPY   ←↑↓→ MOVE   TAB SHEETS   ESC CLOSE"
    // Up from the bottom edge (0-1).
    property real rise: 0

    Connections {
        target: root.control

        function onOpenChanged(): void {
            if (root.control.open) {
                drop.stop();
                handUp.restart();
            } else {
                handUp.stop();
                drop.restart();
            }
        }
        function onCleared(): void {
            field.text = "";
        }
        function onFocusRequested(): void {
            field.forceActiveFocus();
        }
        function onSelectedChanged(): void {
            if (root.control.onHistory)
                list.positionViewAtIndex(root.control.selected, ListView.Contain);
            else
                grid.positionViewAtIndex(root.control.selected, GridView.Contain);
        }
    }
    NumberAnimation {
        id: handUp

        target: root
        property: "rise"
        to: 1
        duration: 480
        easing.type: Easing.OutBack
        easing.overshoot: 0.9
    }
    NumberAnimation {
        id: drop

        target: root
        property: "rise"
        to: 0
        duration: 230
        easing.type: Easing.InCubic
    }

    // ── The board ────────────────────────────────────────────────────────────
    Item {
        id: board

        x: (parent.width - width) / 2
        y: parent.height - (height - 18) * root.rise
        width: root.margin + root.sheetWidth + root.tabRoom
        height: sheet.y + sheet.height + root.margin + 18
        visible: root.showing
        rotation: 3 * (1 - root.rise)

        // Clicks on it stay on it.
        MouseArea {
            anchors.fill: parent
        }
        RectangularShadow {
            anchors.fill: parent
            radius: 14
            offset.y: 10
            blur: 30
            color: Qt.alpha("black", 0.65)
        }
        Rectangle {
            anchors.fill: parent
            radius: 14
            border.width: 1
            border.color: "#3e2a17"
            gradient: Gradient {
                GradientStop { position: 0; color: "#8d6743" }
                GradientStop { position: 1; color: "#6c4b2d" }
            }
        }
        // The hardboard's grain, faint.
        Image {
            anchors {
                fill: parent
                margins: 2
            }
            source: Qt.resolvedUrl("wood.png")
            fillMode: Image.Tile
            opacity: 0.12
        }

        // The index tabs, their roots under the sheets.
        Column {
            x: root.margin + root.sheetWidth - 14
            y: root.clipRoom + 34
            spacing: 6

            Repeater {
                model: root.control.tabs

                Item {
                    id: tab

                    required property var modelData
                    required property int index
                    readonly property bool on: root.control.current === index

                    width: root.tabRoom - 2 + (on ? 6 : 0)
                    height: 30

                    Behavior on width {
                        NumberAnimation { duration: 120 }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: tab.on || tabArea.containsMouse ? Qt.lighter(root.tabColors[tab.index], 1.06) : Qt.darker(root.tabColors[tab.index], 1.08)
                        border.width: 1
                        border.color: Qt.darker(root.tabColors[tab.index], 1.4)
                    }
                    Text {
                        x: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label.toUpperCase()
                        color: root.ink
                        font.family: Theme.font.family
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1
                    }
                    MouseArea {
                        id: tabArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.control.current = tab.index
                    }
                }
            }
        }

        // ── The sheet ────────────────────────────────────────────────────────
        Rectangle {
            id: sheet

            x: root.margin
            y: root.clipRoom - 26
            width: root.sheetWidth
            height: 26 + 52 + root.bodyHeight + 40
            color: root.control.onHistory ? root.paper : root.transfer
            border.width: 1
            border.color: Qt.alpha("black", 0.18)

            // What you're looking for, in pen.
            Item {
                id: find

                x: 20
                y: 36
                width: parent.width - 40
                height: 30

                Text {
                    id: findLabel

                    anchors.baseline: field.baseline
                    text: root.control.onHistory ? "FIND" : root.control.tabs[root.control.current].label.toUpperCase()
                    color: root.ink
                    opacity: 0.6
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                TextInput {
                    id: field

                    x: findLabel.width + 12
                    width: parent.width - x - (clearAll.visible ? clearAll.width + 16 : 0)
                    anchors.bottom: rule.top
                    anchors.bottomMargin: 2
                    color: root.pen
                    selectionColor: Qt.alpha(root.pen, 0.25)
                    selectedTextColor: root.pen
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    font.italic: true
                    clip: true
                    onTextChanged: root.control.setQuery(text)
                    Keys.onLeftPressed: event => {
                        if (root.control.onHistory)
                            event.accepted = false;
                        else
                            root.control.move(-1);
                    }
                    Keys.onRightPressed: event => {
                        if (root.control.onHistory)
                            event.accepted = false;
                        else
                            root.control.move(1);
                    }
                    Keys.onReturnPressed: event => root.control.pick(root.control.selected, event.modifiers)
                    Keys.onEnterPressed: event => root.control.pick(root.control.selected, event.modifiers)

                    Text {
                        anchors.fill: parent
                        text: root.control.onHistory ? "anything clipped…" : "arrow, smile, cod-git, table flip…"
                        color: Qt.alpha(root.pen, 0.35)
                        font: field.font
                        visible: field.text === ""
                    }
                }
                Rectangle {
                    id: rule

                    x: field.x
                    anchors.bottom: parent.bottom
                    width: field.width
                    height: 1
                    color: Qt.alpha(root.ink, 0.45)
                }
                Text {
                    id: clearAll

                    anchors {
                        right: parent.right
                        baseline: field.baseline
                    }
                    visible: root.control.onHistory && root.control.allHistory.length > 0
                    text: "✕ CLEAR ALL"
                    color: "#b8402e"
                    opacity: clearArea.containsMouse ? 1 : 0.7
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.5

                    MouseArea {
                        id: clearArea

                        anchors {
                            fill: parent
                            margins: -5
                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.control.wipe()
                    }
                }
            }

            // Nothing here.
            Text {
                y: 78
                width: parent.width
                height: 70
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: root.control.entries.length === 0
                text: root.control.onHistory
                    ? (root.control.allHistory.length === 0 ? "nothing clipped yet" : "nothing like that")
                    : (root.control.symbolsLoaded ? "nothing like that" : "fetching the sheet…")
                color: Qt.alpha(root.pen, 0.6)
                font.family: Theme.font.family
                font.pixelSize: 13
                font.italic: true
            }

            // ── History: the slips ───────────────────────────────────────────
            ListView {
                id: list

                x: 16
                y: 78
                width: parent.width - 32
                height: root.bodyHeight
                visible: root.control.onHistory && root.control.entries.length > 0
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: root.control.onHistory ? root.control.clips : []

                delegate: Item {
                    id: slip

                    required property var modelData
                    required property int index
                    readonly property bool current: root.control.selected === index
                    readonly property string thumb: root.control.thumbs[modelData.id] ?? ""

                    width: ListView.view.width
                    height: modelData.image ? 70 : 30

                    Item {
                        id: cut

                        x: 4 + (slip.modelData.image ? 0 : (Number(slip.modelData.id) * 13) % 9)
                        width: slip.modelData.image ? photo.x + photo.width + 8 : slip.width - 8 - x
                        height: slip.height
                        scale: slip.current ? 1.015 : 1

                        Behavior on scale {
                            NumberAnimation { duration: 110 }
                        }
                        // Its shadow on the sheet, deeper lifted.
                        Rectangle {
                            x: 1
                            y: slip.current ? 3 : 1
                            width: parent.width
                            height: parent.height
                            color: Qt.alpha("black", slip.current ? 0.22 : 0.13)
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "#fffdf7"
                        }
                        // The one in hand, highlighted.
                        Rectangle {
                            x: 30
                            y: 6
                            width: Math.min(parent.width - 40, typed.implicitWidth + 8)
                            height: parent.height - 12
                            color: Qt.alpha("#ffe14a", 0.55)
                            visible: slip.current && !slip.modelData.image
                        }
                        Text {
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(slip.index + 1).padStart(2, "0")
                            color: "#b8402e"
                            opacity: 0.8
                            font.family: Theme.font.family
                            font.pixelSize: 9
                            font.bold: true
                        }
                        Text {
                            id: typed

                            x: 34
                            width: parent.width - x - meta.width - 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: slip.modelData.image ? "" : slip.modelData.text
                            elide: Text.ElideRight
                            color: root.ink
                            font.family: Theme.font.family
                            font.pixelSize: 12
                        }
                        Image {
                            id: photo

                            x: 32
                            y: 6
                            width: 102
                            height: parent.height - 12
                            source: slip.thumb
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 204
                            sourceSize.height: 116
                            asynchronous: true
                            visible: slip.modelData.image
                        }
                        Text {
                            id: meta

                            anchors {
                                right: parent.right
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            text: slip.modelData.image ? "" : "TXT"
                            color: root.ink
                            opacity: 0.45
                            font.family: Theme.font.family
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                    }
                    // A picture's size, written on the sheet beside it.
                    Text {
                        x: cut.x + cut.width + 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: slip.modelData.image
                        text: slip.modelData.meta
                        color: root.pen
                        opacity: 0.7
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.italic: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.control.selected = slip.index
                        onClicked: mouse => root.control.pick(slip.index, mouse.modifiers)
                    }
                }
            }

            // ── Symbols: the transfer sheet ──────────────────────────────────
            GridView {
                id: grid

                x: 16
                y: 78
                width: parent.width - 32
                height: root.bodyHeight - 44
                visible: !root.control.onHistory && root.control.entries.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: Math.floor(width / root.control.columns)
                cellHeight: 47
                model: root.control.symbols

                delegate: Item {
                    id: letter

                    required property var modelData
                    required property int index
                    readonly property bool current: root.control.selected === index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    // Ringed in pencil.
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.control.tab === "kaomoji" ? Math.min(parent.width - 4, glyph.contentWidth + 22) : Math.min(parent.width, parent.height) - 4
                        height: parent.height - 6
                        radius: height / 2
                        color: "transparent"
                        border.width: 1.5
                        border.color: Qt.alpha("#4a4a4a", 0.75)
                        visible: letter.current
                        rotation: -3
                    }
                    Text {
                        id: glyph

                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        text: letter.modelData.ch
                        color: "#111"
                        font.family: Theme.font.family
                        font.pixelSize: root.control.tab === "kaomoji" ? 13 : 20
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.control.selected = letter.index
                        onClicked: mouse => root.control.pick(letter.index, mouse.modifiers)
                    }
                }
            }
            // What the ringed one is, printed under the sheet's letters.
            Row {
                readonly property var current: root.control.symbols[root.control.selected] ?? null

                x: 20
                y: grid.y + grid.height + 14
                spacing: 12
                visible: !root.control.onHistory && current !== null

                Text {
                    text: (parent.current?.name ?? "").toUpperCase()
                    color: root.ink
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                Text {
                    text: parent.current?.detail ?? ""
                    color: root.ink
                    opacity: 0.55
                    font.family: Theme.font.family
                    font.pixelSize: 10
                }
            }

            // How to use it, printed along the foot of the sheet.
            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 12
                }
                text: root.hints
                color: root.ink
                opacity: 0.45
                font.family: Theme.font.family
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.5
            }
        }

        // ── The clip ─────────────────────────────────────────────────────────
        Item {
            x: root.margin + root.sheetWidth / 2 - width / 2
            y: 8
            width: 230
            height: 50

            RectangularShadow {
                anchors.fill: plate
                radius: 8
                offset.y: 4
                blur: 10
                color: Qt.alpha("black", 0.5)
            }
            // The lever, arched over it.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -4
                width: 120
                height: 26
                radius: 13
                color: "transparent"
                border.width: 5
                border.color: "#b9bcc2"
            }
            Rectangle {
                id: plate

                y: 8
                width: parent.width
                height: 40
                radius: 8
                border.width: 1
                border.color: "#3b3d42"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#e3e5e9" }
                    GradientStop { position: 0.45; color: "#b4b7bd" }
                    GradientStop { position: 1; color: "#7e8188" }
                }

                // Its rivets.
                Repeater {
                    model: [0.18, 0.82]

                    Rectangle {
                        required property real modelData

                        x: parent.width * modelData - 5
                        y: 8
                        width: 10
                        height: 10
                        radius: 5
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#f2f3f5" }
                            GradientStop { position: 1; color: "#6c6f75" }
                        }
                    }
                }
            }
        }
    }
}
