import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.keys as M

// A laminated quick-reference card on a spring roller behind the panel,
// pulled down like a projector screen: it comes out from under the panel's
// edge on its weighted bottom bar, the pull tab hanging from the middle,
// catches at full length with a little give, and sways to a stop. Going, the
// latch lets go and the roller takes it back up, briskly.
//
// On it, Sway's binds by section: each section's heading printed in a band
// of its own color, then its combos, drawn as keycaps, and what they do.
// Take the pull tab to send it back up.
Item {
    id: root

    required property M.KeysPanel control

    readonly property real columnWidth: 318
    readonly property real gutter: 22
    readonly property real pad: 22
    readonly property real rowHeight: 23
    readonly property real bandHeight: 20
    readonly property real sectionGap: 12
    readonly property real headHeight: 52
    readonly property real footHeight: 34
    // The roller, behind the middle of the panel (the drop's padding above us).
    readonly property real roller: -(Theme.barHeight / 2 + 14)
    readonly property real slatHeight: 14
    readonly property real side: 10
    readonly property color paper: "#f4f1e8"
    readonly property color ink: "#24231f"
    // The section bands' print colors, in turn.
    readonly property var bands: ["#1f8783", "#d9692b", "#3d68b0", "#b8405e", "#5a9338", "#7d58ad", "#c99413"]

    function heightOf(g: var): real {
        return bandHeight + 6 + g.binds.length * rowHeight + sectionGap;
    }
    // Three columns, or four if three would run off the screen.
    readonly property int columnCount: {
        const room = control.maxHeight - headHeight - footHeight - slatHeight - 40;
        const tallest = n => Math.max(...control.split(n, heightOf).map(c => c.reduce((h, g) => h + heightOf(g), 0)));
        return control.groups.length === 0 || tallest(3) <= room ? 3 : 4;
    }
    readonly property var columns: control.split(columnCount, heightOf)
    readonly property real columnsHeight: control.error !== "" ? 60
        : Math.max(0, ...columns.map(c => c.reduce((h, g) => h + heightOf(g), 0))) - sectionGap
    readonly property real cardWidth: columnCount * columnWidth + (columnCount - 1) * gutter + 2 * pad
    readonly property real cardHeight: headHeight + Math.min(columnsHeight, control.maxHeight - headHeight - footHeight - slatHeight - 40) + footHeight
    // From the roller to the bottom of the bar.
    readonly property real length: cardHeight - roller + slatHeight

    // How far down it's pulled (0-1), and its sway on the roller.
    property real down: 0
    property real sway: 0

    implicitWidth: cardWidth + 2 * side
    implicitHeight: roller + length + 36

    Connections {
        target: root.control

        function onOpenChanged(): void {
            if (root.control.open) {
                rollUp.stop();
                flick.contentY = 0;
                pullDown.restart();
            } else {
                pullDown.stop();
                rollUp.restart();
            }
        }
        function onNudged(velocity: real): void {
            flick.flick(0, velocity);
        }
    }
    // Pulled down past the catch, settling back onto it, swaying.
    SequentialAnimation {
        id: pullDown

        NumberAnimation { target: root; property: "down"; to: 1.025; duration: 520; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "down"; to: 1; duration: 200; easing.type: Easing.InOutQuad }
            SequentialAnimation {
                NumberAnimation { target: root; property: "sway"; to: 0.5; duration: 140; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "sway"; to: 0; duration: 1200; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.5 }
            }
        }
    }
    // A tug to free the catch, then the roller takes it.
    SequentialAnimation {
        id: rollUp

        NumberAnimation { target: root; property: "sway"; to: 0; duration: 60 }
        NumberAnimation { target: root; property: "down"; to: Math.max(root.down, 1.02); duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "down"; to: 0; duration: 430; easing.type: Easing.InCubic }
    }

    FontMetrics {
        id: capFont

        font.family: Theme.font.family
        font.pixelSize: 10
        font.bold: true
    }
    function capWidth(label: string): real {
        return Math.max(18, Math.ceil(capFont.advanceWidth(label)) + 10);
    }
    function comboWidth(b: var): real {
        return b.mods.concat(b.key).reduce((w, k) => w + capWidth(k) + 3, -3);
    }

    // A keycap, printed.
    component Cap: Item {
        id: cap

        property string label

        width: root.capWidth(label)
        height: 17

        Rectangle {
            y: 2
            width: parent.width
            height: parent.height - 2
            radius: 3
            color: "#a8a395"
        }
        Rectangle {
            width: parent.width
            height: parent.height - 2
            radius: 3
            color: "#fdfcf8"
            border.width: 1
            border.color: "#8d887a"

            Text {
                anchors.centerIn: parent
                text: cap.label
                color: root.ink
                font: capFont.font
            }
        }
    }

    // The sheet, hanging from the roller: the card, then the bar.
    Item {
        id: sheet

        x: root.side
        y: root.roller + (root.down - 1) * root.length
        width: root.cardWidth
        height: root.length
        visible: root.down > 0.001
        transform: Rotation {
            origin.x: sheet.width / 2
            origin.y: -sheet.y + root.roller
            angle: root.sway
        }

        // Its shadow on what's behind.
        RectangularShadow {
            anchors.fill: parent
            offset.y: 6
            blur: 22
            color: Qt.alpha(Theme.palette.shadow, Math.min(1, (Theme.values.effects?.shadow ?? 0) * 1.1))
        }

        // The card, in its laminate.
        Item {
            id: card

            y: -root.roller
            width: parent.width
            height: root.cardHeight

            // Paper above the card, up to the roller.
            Rectangle {
                y: root.roller
                width: parent.width
                height: -root.roller + 1
                color: Qt.darker(root.paper, 1.04)
            }
            // The laminate, a clear edge round the paper.
            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Qt.rgba(0.93, 0.95, 0.96, 0.85)
                border.width: 1
                border.color: Qt.alpha("black", 0.3)
            }
            Rectangle {
                x: 4
                width: parent.width - 8
                height: parent.height - 4
                color: root.paper
            }

            // ── The head ─────────────────────────────────────────────────────
            Item {
                x: root.pad
                width: parent.width - 2 * root.pad
                height: root.headHeight

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        anchors.baseline: subtitle.baseline
                        text: "KEYS"
                        color: root.ink
                        font.family: Theme.font.family
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 3
                    }
                    Text {
                        id: subtitle

                        text: "QUICK REFERENCE"
                        color: Qt.alpha(root.ink, 0.6)
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                }
                Text {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.control.error !== "" ? "" : `${root.control.count} SHORTCUTS · SWAY`
                    color: Qt.alpha(root.ink, 0.6)
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                // A rule under it.
                Rectangle {
                    y: parent.height - 8
                    width: parent.width
                    height: 2
                    color: root.ink
                }
            }

            // ── The sections ─────────────────────────────────────────────────
            Text {
                y: root.headHeight
                width: parent.width
                height: root.columnsHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: root.control.error !== ""
                text: root.control.error.toUpperCase()
                color: Qt.alpha(root.ink, 0.7)
                font.family: Theme.font.family
                font.pixelSize: 11
                font.letterSpacing: 1.5
            }
            Flickable {
                id: flick

                x: root.pad
                y: root.headHeight
                width: parent.width - 2 * root.pad
                height: root.cardHeight - root.headHeight - root.footHeight
                contentHeight: root.columnsHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                visible: root.control.error === ""

                Row {
                    spacing: root.gutter

                    Repeater {
                        model: root.columns

                        Column {
                            id: column

                            required property var modelData
                            required property int index
                            // The widest combo in it, so what they do lines up.
                            readonly property real capsWidth: Math.max(0, ...modelData.reduce((a, g) => a.concat(g.binds.map(b => root.comboWidth(b))), []))
                            // Where its sections start counting, for their colors.
                            readonly property int first: root.columns.slice(0, index).reduce((n, c) => n + c.length, 0)

                            width: root.columnWidth

                            Repeater {
                                model: column.modelData

                                Column {
                                    id: section

                                    required property var modelData
                                    required property int index
                                    readonly property color band: root.bands[(column.first + index) % root.bands.length]

                                    width: root.columnWidth
                                    bottomPadding: root.sectionGap

                                    // Its heading, in its band.
                                    Rectangle {
                                        width: parent.width
                                        height: root.bandHeight
                                        radius: 2
                                        color: section.band

                                        Text {
                                            x: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: section.modelData.title.toUpperCase()
                                            color: "#fbfaf5"
                                            font.family: Theme.font.family
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.letterSpacing: 1.5
                                        }
                                    }
                                    Item {
                                        width: 1
                                        height: 6
                                    }
                                    Repeater {
                                        model: section.modelData.binds

                                        Item {
                                            id: line

                                            required property var modelData
                                            required property int index

                                            width: root.columnWidth
                                            height: root.rowHeight

                                            Row {
                                                x: 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 3

                                                Repeater {
                                                    model: line.modelData.mods.concat(line.modelData.key)

                                                    Cap {
                                                        required property string modelData

                                                        label: modelData
                                                    }
                                                }
                                            }
                                            Text {
                                                x: 2 + column.capsWidth + 12
                                                width: parent.width - x
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: line.modelData.action
                                                elide: Text.ElideRight
                                                color: root.ink
                                                font.family: Theme.font.family
                                                font.pixelSize: 11
                                            }
                                            // A dotted leader under each, in the band's color.
                                            Rectangle {
                                                y: parent.height - 1
                                                width: parent.width
                                                height: 1
                                                color: Qt.alpha(section.band, 0.18)
                                                visible: line.index < section.modelData.binds.length - 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                WheelHandler {
                    enabled: flick.interactive
                    onWheel: event => flick.flick(0, event.angleDelta.y * 8)
                }
            }

            // ── The foot ─────────────────────────────────────────────────────
            Item {
                x: root.pad
                y: parent.height - root.footHeight
                width: parent.width - 2 * root.pad
                height: root.footHeight

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.alpha(root.ink, 0.35)
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: [["Super", "F1", "toggle"], ["Esc", "", "put away"]]

                        Row {
                            required property var modelData

                            spacing: 3
                            rightPadding: 14

                            Cap {
                                label: modelData[0]
                            }
                            Cap {
                                label: modelData[1]
                                visible: modelData[1] !== ""
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: 4
                                text: modelData[2].toUpperCase()
                                color: Qt.alpha(root.ink, 0.6)
                                font.family: Theme.font.family
                                font.pixelSize: 9
                                font.letterSpacing: 1.5
                            }
                        }
                    }
                }
            }

            // The laminate's sheen.
            Rectangle {
                anchors.fill: parent
                radius: 6
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.28; color: "transparent" }
                    GradientStop { position: 0.36; color: Qt.alpha("white", 0.3) }
                    GradientStop { position: 0.47; color: Qt.alpha("white", 0.06) }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1; color: Qt.alpha("white", 0.08) }
                }
            }
        }

        // The panel's lip throws its shadow on the card where it comes out.
        Rectangle {
            y: -sheet.y - 14
            width: parent.width
            height: 16
            visible: sheet.y < -14
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.palette.shadow, 0.55) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // The weighted bar along the bottom, a bit wider than the card.
        Rectangle {
            x: -6
            y: root.length - root.slatHeight
            width: parent.width + 12
            height: root.slatHeight
            radius: 3
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: "#d7d9dd" }
                GradientStop { position: 0.35; color: "#a4a7ad" }
                GradientStop { position: 1; color: "#5a5d63" }
            }

            // Its end caps.
            Repeater {
                model: [0, 1]

                Rectangle {
                    required property int modelData

                    x: modelData ? parent.width - width : 0
                    width: 10
                    height: parent.height
                    radius: 3
                    color: "#1d1d20"
                }
            }
        }

        // The pull tab, hanging from the middle of the bar: take it to send
        // the card back up.
        Item {
            x: (parent.width - width) / 2
            y: root.length - 3
            width: 46
            height: 26

            Rectangle {
                anchors.fill: parent
                radius: 7
                border.width: 1
                border.color: Theme.palette.shadow
                gradient: Gradient {
                    GradientStop { position: 0; color: tabArea.containsMouse ? "#3a3a40" : "#2c2c31" }
                    GradientStop { position: 1; color: "#141416" }
                }

                // The finger hole.
                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 5
                    }
                    width: 24
                    height: 9
                    radius: 4.5
                    color: "#060607"
                    border.width: 1
                    border.color: "#4a4a50"
                }
            }
            MouseArea {
                id: tabArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.control.dismiss()
            }
        }
    }
}
