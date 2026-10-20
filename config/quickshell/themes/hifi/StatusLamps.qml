import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// An annunciator panel: four lenses with their legends, MIC, CAM, SCR and
// IDLE. Dark, the legend shows faintly through the smoked lens; lit, the
// lens glows and the legend reads dark on it. The privacy ones are amber.
Rectangle {
    id: root

    required property W.StatusLamps control
    readonly property bool shown: true
    readonly property var lamps: [
        { label: "mic", on: control.mic, color: Theme.palette.warn },
        { label: "cam", on: control.camera, color: Theme.palette.warn },
        { label: "scr", on: control.screen, color: Theme.palette.warn },
        { label: "idle", on: control.idle, color: Theme.palette.fg }
    ]

    implicitWidth: grid.implicitWidth + 6
    implicitHeight: grid.implicitHeight + 6
    radius: 3
    color: Theme.palette.shadow
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

                width: 36
                height: 16

                RectangularShadow {
                    anchors.fill: parent
                    visible: lamp.modelData.on && (Theme.glow.opacity ?? 0) > 0
                    radius: 2
                    blur: 8
                    color: Qt.alpha(lamp.modelData.color, 0.6 * (Theme.glow.opacity ?? 0))
                }
                Rectangle {
                    id: lens

                    property color c: lamp.modelData.on ? lamp.modelData.color : Qt.darker(lamp.modelData.color, 5)

                    anchors.fill: parent
                    radius: 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(lens.c, 1.25) }
                        GradientStop { position: 1; color: Qt.darker(lens.c, 1.25) }
                    }

                    Behavior on c {
                        ColorAnimation { duration: 90 }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: lamp.modelData.label.toUpperCase()
                    color: lamp.modelData.on ? Qt.darker(lamp.modelData.color, 4) : Qt.alpha(lamp.modelData.color, 0.3)
                    font.family: Theme.font.family
                    font.pixelSize: 9
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
