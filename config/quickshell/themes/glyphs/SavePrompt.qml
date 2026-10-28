import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.capture as M

// A drawer from the bottom edge with a preview and a path, and the choices
// under it.
Item {
    id: root

    required property M.SavePrompt control

    // What takes clicks: the drawer's place, unscaled. A skin may grow the
    // drawer in by its scale, which the window's input region doesn't follow.
    readonly property Item inputArea: hit
    readonly property bool showing: drawer.height > 0

    implicitWidth: drawer.width + 2 * drawer.overhang

    Connections {
        target: root.control

        function onAskingChanged(): void {
            if (root.control.asking) {
                path.text = root.control.suggestedName();
                path.focusInput();
            }
        }
    }

    Item {
        id: hit

        anchors.fill: drawer
    }

    BottomDrawer {
        id: drawer

        name: "capture"

        anchors {
            bottom: parent.bottom
            bottomMargin: drawer.lift
            horizontalCenter: parent.horizontalCenter
        }
        width: 560
        open: root.control.asking

        ColumnLayout {
            width: parent.width
            spacing: 12

            SectionTitle {
                text: root.control.isShot ? "Screenshot" : root.control.kind === "screen" ? "Screen recording" : "Voice memo"
                code: root.control.isShot ? `${Math.round(root.control.area.width)}×${Math.round(root.control.area.height)}` : root.control.duration(root.control.elapsed)
            }

            // Preview
            Item {
                Layout.fillWidth: true
                implicitHeight: root.control.isShot ? 200 : 44

                Image {
                    anchors.fill: parent
                    source: root.control.isShot && root.control.asking ? "file://" + root.control.file : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    visible: root.control.isShot
                }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !root.control.isShot

                    StyledText {
                        text: root.control.kind === "screen" ? "\u{F0567}" : "\u{F036C}"
                        color: Theme.palette.accent
                        glow: true
                        font.pixelSize: 26
                    }
                    StyledText {
                        text: root.control.duration(root.control.elapsed)
                        font.pixelSize: 22
                        font.bold: true
                    }
                }
            }

            TextField {
                id: path

                Layout.fillWidth: true
                prompt: "save>"
                onAccepted: root.control.save(text, false)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextButton {
                    text: "\u{F0193}  save"
                    lit: true
                    onClicked: root.control.save(path.text, false)
                }
                TextButton {
                    text: "save + copy"
                    visible: root.control.isShot
                    onClicked: root.control.save(path.text, true)
                }
                TextButton {
                    text: "\u{F018F}  copy"
                    visible: root.control.isShot
                    onClicked: root.control.copy()
                }
                Item {
                    Layout.fillWidth: true
                }
                TextButton {
                    text: "\u{F01B4}  discard"
                    onClicked: root.control.discard()
                }
            }

            KeyHints {
                Layout.alignment: Qt.AlignHCenter
                hints: [["↵", "save"], ["esc", "discard"]]
            }
        }
    }
}
