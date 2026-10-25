import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.capture as M

// A strip of tools on a card: below the selection if there's room, else
// above, else inside.
Item {
    id: root

    required property M.MarkTools control

    function clamp(v: real, lo: real, hi: real): real {
        return Math.max(lo, Math.min(hi, v));
    }

    Item {
        id: strip

        readonly property rect sel: root.control.area

        x: root.clamp(sel.x + sel.width / 2 - width / 2, 12, root.width - width - 12)
        y: sel.y + sel.height + height + 16 < root.height ? sel.y + sel.height + 12
            : sel.y - height - 12 > 0 ? sel.y - height - 12
            : sel.y + sel.height - height - 12
        width: tools.implicitWidth + 24
        height: tools.implicitHeight + 16

        Card {
            anchors.fill: parent
        }

        RowLayout {
            id: tools

            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.control.tools

                IconButton {
                    required property var modelData
                    required property int index

                    icon: modelData.glyph
                    lit: root.control.tool === modelData.key
                    onClicked: root.control.toolPicked(modelData.key)
                }
            }
            Divider {
                implicitHeight: 20
                vertical: true
            }
            Repeater {
                model: root.control.inks

                Item {
                    required property color modelData

                    implicitWidth: 22
                    implicitHeight: 22

                    Swatch {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        color: parent.modelData
                        selected: Qt.colorEqual(root.control.ink, parent.modelData)
                        onClicked: root.control.inkPicked(parent.modelData)
                    }
                }
            }
            Divider {
                implicitHeight: 20
                vertical: true
            }
            IconButton {
                icon: "\u{F054C}"
                enabled: root.control.canUndo
                opacity: enabled ? 1 : 0.35
                onClicked: root.control.undone()
            }
            TextButton {
                text: "done"
                lit: true
                onClicked: root.control.done()
            }
            TextButton {
                text: "cancel"
                onClicked: root.control.cancelled()
            }
        }
    }
}
