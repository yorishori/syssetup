import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// Four ON AIR signs, MIC, CAM, SCR and IDLE: a pane of colored glass with the
// letters cut clear through a black mask. Dark, the glass shows its deep
// color and the letters are blacked out. Lit, the lamp behind turns the
// letters white and glowing, while the glass, never quite clear, barely
// glows. The privacy ones are red, idle is blue.
Rectangle {
    id: root

    required property W.StatusLamps control
    readonly property bool shown: true
    readonly property color red: Theme.palette.error
    readonly property color blue: Theme.values.display?.idle ?? Theme.palette.accent
    readonly property var lamps: [
        { label: "mic", on: control.mic, color: red },
        { label: "cam", on: control.camera, color: red },
        { label: "scr", on: control.screen, color: red },
        { label: "idle", on: control.idle, color: blue }
    ]

    implicitWidth: grid.implicitWidth + 6
    implicitHeight: grid.implicitHeight + 6
    radius: 3
    color: "#050506"
    border.width: 1
    border.color: Qt.lighter(Theme.palette.bg, 1.3)

    Grid {
        id: grid

        anchors.centerIn: parent
        columns: 2
        spacing: 2

        Repeater {
            model: root.lamps

            Item {
                id: lamp

                required property var modelData
                readonly property bool on: modelData.on
                readonly property color tint: modelData.color

                width: 38
                height: 17

                // The glass, just barely glowing when lit.
                RectangularShadow {
                    anchors.fill: parent
                    visible: lamp.on && (Theme.glow.opacity ?? 0) > 0
                    radius: 2
                    blur: 6
                    color: Qt.alpha(lamp.tint, 0.3 * (Theme.glow.opacity ?? 0))
                }
                Rectangle {
                    id: glass

                    property color c: Qt.darker(lamp.tint, lamp.on ? 2.1 : 3.8)

                    anchors.fill: parent
                    radius: 2
                    border.width: 1
                    border.color: "black"
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(glass.c, 1.25) }
                        GradientStop { position: 1; color: Qt.darker(glass.c, 1.2) }
                    }

                    Behavior on c {
                        ColorAnimation { duration: 120 }
                    }
                }
                // The letters: blacked out, or white with the lamp behind.
                C.StyledText {
                    anchors.centerIn: parent
                    text: lamp.modelData.label.toUpperCase()
                    color: lamp.on ? Qt.tint("white", Qt.alpha(lamp.tint, 0.12)) : "#0a0909"
                    glow: lamp.on
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }
                Gloss {
                    anchors.fill: parent
                    roundness: 2
                }
            }
        }
    }
}
