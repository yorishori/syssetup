import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.settings as M

// The settings plate on the back of the unit: a row of hardware.
//   THEME and SCREEN: rotary selectors, a pointer knob with its positions
//   printed round it (take a position, click the knob for the next, or
//   scroll).
//   IDLE: LOCK and SCREEN OFF, each a stepping knob and its minutes on red
//   seven segments (0 = never).
//   LOCK: the passcode's length on flap digits, ▲▼ to set it (0 = press
//   Enter).
//   WALLPAPER: the image's path behind glass (type a new one, Enter), its fit
//   on a small selector; no image, the plain color's chips.
//   RESTART, a latching switch; and the SETUP hatch, opening the setup.
Item {
    id: root

    required property M.SettingsPanel control

    readonly property color red: Theme.values.display?.clock ?? Theme.palette.error
    readonly property color vfd: Theme.palette.accent

    implicitWidth: plate.implicitWidth + 28
    implicitHeight: plate.implicitHeight + 28

    function item(path: string): var {
        return control.items.find(i => i.path === path);
    }

    // Minutes on a stepping knob and red seven segments.
    component Minutes: Row {
        id: mins

        property string path
        property string name
        readonly property var spec: root.item(path)
        readonly property int value: root.control.value(path) ?? 0

        spacing: 12

        TuningKnob {
            anchors.verticalCenter: parent.verticalCenter
            width: 60
            height: 60
            position: mins.value
            onStepped: step => root.control.set(mins.path, Math.max(mins.spec.min, Math.min(mins.spec.max, mins.value + step)))
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Silk {
                text: mins.name
            }
            Item {
                width: digits.width + 16
                height: 40

                Well {
                    anchors.fill: parent
                    roundness: 3
                    fill: Qt.tint("#0a0505", Qt.alpha(root.red, 0.04))
                }
                Row {
                    id: digits

                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 3

                        Segment7 {
                            required property int index
                            readonly property string text: String(mins.value).padStart(3, " ")

                            width: 14
                            height: 24
                            thickness: 3
                            color: root.red
                            digit: text[index] === " " ? -1 : Number(text[index])
                        }
                    }
                }
            }
            Silk {
                text: mins.value === 0 ? "never" : "min"
                font.pixelSize: 8
                opacity: 0.8
            }
        }
    }

    Column {
        id: plate

        x: 14
        y: 14
        spacing: 12

        Row {
            spacing: 12

            Framed {
                name: "theme"

                ChoiceKnob {
                    options: root.item("theme").options
                    current: root.control.value("theme")
                    onPicked: v => root.control.set("theme", v)
                }
            }
            Framed {
                name: "screen"

                ChoiceKnob {
                    options: [{ label: "auto", value: "" }, ...root.control.screens.map(s => ({ label: s, value: s }))]
                    current: root.control.value("screen")
                    onPicked: v => root.control.set("screen", v)
                }
            }
            Framed {
                name: "idle"

                Column {
                    spacing: 12

                    Minutes {
                        path: "idle.lock"
                        name: "lock after"
                    }
                    Minutes {
                        path: "idle.screenOff"
                        name: "screen off"
                    }
                }
            }
        }

        Row {
            spacing: 12

            Framed {
                name: "wallpaper"

                Column {
                    spacing: 10

                    // The path, behind glass.
                    Item {
                        width: 330
                        height: 30

                        Well {
                            anchors.fill: parent
                            roundness: 3
                            fill: Qt.tint("#050807", Qt.alpha(root.vfd, 0.05))
                        }
                        TextInput {
                            id: wallpaper

                            readonly property string saved: root.control.value("wallpaper.path") ?? ""

                            x: 10
                            width: parent.width - 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: saved
                            clip: true
                            color: root.vfd
                            selectionColor: Qt.alpha(root.vfd, 0.3)
                            selectedTextColor: root.vfd
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            onSavedChanged: text = saved
                            onEditingFinished: {
                                if (text.trim() !== saved)
                                    root.control.set("wallpaper.path", text.trim());
                            }

                            Text {
                                anchors.fill: parent
                                text: "no image: plain"
                                color: Qt.alpha(root.vfd, 0.35)
                                font: wallpaper.font
                                visible: wallpaper.text === "" && !wallpaper.activeFocus
                            }
                        }
                        Gloss {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            roundness: 3
                        }
                    }
                    // Its fit, or the plain color.
                    ChoiceKnob {
                        anchors.horizontalCenter: parent.horizontalCenter
                        reach: 52
                        visible: wallpaper.saved !== ""
                        options: root.item("wallpaper.fit").options
                        current: root.control.value("wallpaper.fit")
                        onPicked: v => root.control.set("wallpaper.fit", v)
                    }
                    C.Swatches {
                        visible: wallpaper.saved === ""
                        palette: dark
                        current: root.control.value("wallpaper.color") || Theme.palette.bg
                        onPicked: color => root.control.set("wallpaper.color", color)
                    }
                }
            }
            Framed {
                name: "lock"

                Column {
                    spacing: 8

                    Silk {
                        text: "passcode"
                    }
                    Row {
                        spacing: 8

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Flap {
                                width: 22
                                height: 34
                                value: Math.floor((root.control.value("passcode") ?? 0) / 10)
                            }
                            Flap {
                                width: 22
                                height: 34
                                value: (root.control.value("passcode") ?? 0) % 10
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Nudge {
                                glyph: "▲"
                                onPressed: root.control.set("passcode", Math.min(root.item("passcode").max, (root.control.value("passcode") ?? 0) + 1))
                            }
                            Nudge {
                                glyph: "▼"
                                onPressed: root.control.set("passcode", Math.max(0, (root.control.value("passcode") ?? 0) - 1))
                            }
                        }
                    }
                    Silk {
                        text: (root.control.value("passcode") ?? 0) === 0 ? "enter to unlock" : "characters"
                        font.pixelSize: 8
                        opacity: 0.8
                    }
                }
            }
            Framed {
                name: "shell"

                Column {
                    spacing: 14

                    Row {
                        spacing: 10

                        PushSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "\u{F0453}"
                            onPushed: root.control.restart()
                        }
                        Silk {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "restart"
                        }
                    }

                    // The setup hatch: a little screwed plate with a pull.
                    Item {
                        width: 130
                        height: 70

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            border.width: 1
                            border.color: Theme.palette.shadow
                            gradient: Gradient {
                                GradientStop { position: 0; color: hatchArea.containsMouse ? Qt.lighter(Theme.palette.bg, 1.3) : Qt.lighter(Theme.palette.bg, 1.15) }
                                GradientStop { position: 1; color: Qt.darker(Theme.palette.bg, 1.2) }
                            }
                        }
                        Repeater {
                            model: [[0, 0], [1, 0], [0, 1], [1, 1]]

                            Screw {
                                required property var modelData

                                x: modelData[0] ? parent.width - width - 4 : 4
                                y: modelData[1] ? parent.height - height - 4 : 4
                                angle: 15 + 40 * modelData[0] + 25 * modelData[1]
                            }
                        }
                        Silk {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -6
                            text: "setup"
                            font.pixelSize: 11
                        }
                        // The pull.
                        Rectangle {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                                bottomMargin: 12
                            }
                            width: 40
                            height: 6
                            radius: 3
                            color: Theme.palette.shadow
                        }
                        MouseArea {
                            id: hatchArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.control.editSetup()
                        }
                    }
                }
            }
        }
    }
}
