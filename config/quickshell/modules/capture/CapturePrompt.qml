import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// What to do with a capture: a drawer from the bottom edge with a preview and
// a path. SAVE (Enter), SAVE + COPY, COPY (screenshots), DISCARD (Escape).
// Nothing is kept until one is chosen.
PanelWindow {
    id: win

    readonly property bool asking: Capture.state === "asking"
    readonly property bool isShot: Capture.kind === "screenshot"

    function duration(s: int): string {
        return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
    }

    screen: Display.primary
    anchors.bottom: true
    implicitWidth: drawer.width + 2 * drawer.shoulder
    implicitHeight: 420
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: asking || drawer.height > 0
    mask: Region {
        item: drawer
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-capture-prompt"
    WlrLayershell.keyboardFocus: asking ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onAskingChanged: {
        if (asking) {
            path.text = Capture.suggestedName();
            path.focusInput();
        }
    }

    BottomDrawer {
        id: drawer

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: 560
        open: win.asking

        ColumnLayout {
            width: parent.width
            spacing: 12

            Keys.onEscapePressed: Capture.discard()

            SectionTitle {
                text: win.isShot ? "SCREENSHOT" : Capture.kind === "screen" ? "SCREEN RECORDING" : "VOICE MEMO"
                code: win.isShot ? `${Math.round(Capture.selection.width)}×${Math.round(Capture.selection.height)}` : win.duration(Capture.elapsed)
            }

            // Preview
            Item {
                Layout.fillWidth: true
                implicitHeight: win.isShot ? 200 : 44

                Image {
                    anchors.fill: parent
                    source: win.isShot && win.asking ? "file://" + Capture.file : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    visible: win.isShot
                }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !win.isShot

                    StyledText {
                        text: Capture.kind === "screen" ? "\u{F0567}" : "\u{F036C}"
                        color: Config.colors.accent
                        glow: true
                        font.pixelSize: 26
                    }
                    StyledText {
                        text: win.duration(Capture.elapsed)
                        font.pixelSize: 22
                        font.bold: true
                    }
                }
            }

            TextField {
                id: path

                Layout.fillWidth: true
                prompt: "save>"
                onAccepted: Capture.save(text, false)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextButton {
                    text: "\u{F0193}  save"
                    lit: true
                    onClicked: Capture.save(path.text, false)
                }
                TextButton {
                    text: "save + copy"
                    visible: win.isShot
                    onClicked: Capture.save(path.text, true)
                }
                TextButton {
                    text: "\u{F018F}  copy"
                    visible: win.isShot
                    onClicked: Capture.copy()
                }
                Item {
                    Layout.fillWidth: true
                }
                TextButton {
                    text: "\u{F01B4}  discard"
                    onClicked: Capture.discard()
                }
            }

            KeyHints {
                Layout.alignment: Qt.AlignHCenter
                hints: [["↵", "save"], ["esc", "discard"]]
            }
        }
    }
}
