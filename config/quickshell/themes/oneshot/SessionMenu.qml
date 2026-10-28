import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core
import qs.modules.session as M

// The session menu as a save point: a campfire to rest by (with the host
// and uptime), the keys stacked, the key hints below.
Item {
    id: root

    required property M.SessionPanel control

    implicitWidth: 320
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        // The fire, and a moment's rest by it.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fire.implicitHeight + 12
            color: Theme.palette.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12
                spacing: 12

                Campfire {
                    id: fire
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    C.StyledText {
                        text: "Rest a while?"
                        color: Theme.palette.accent
                        font.pixelSize: Theme.font.size + 4
                        font.weight: Font.DemiBold
                    }
                    C.StyledText {
                        Layout.fillWidth: true
                        text: `${root.control.hostname} · up ${root.control.uptimeText}`
                        caps: true
                        color: Theme.palette.dim
                        font.family: Theme.get("font.labels") ?? Theme.font.family
                        font.pixelSize: Theme.font.size - 4
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Repeater {
            model: root.control.actions

            M.SessionKey {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                label: armed ? "confirm?" : modelData.label
                key: modelData.key
                glyph: modelData.glyph
                number: index + 1
                current: root.control.selected === index
                armed: root.control.armed === index
                onHoveredChanged: {
                    if (hovered)
                        root.control.hover(index);
                }
                onClicked: root.control.activate(index)
                onFused: root.control.execute(index)
            }
        }

        C.KeyHints {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            hints: [["1-4", "select"], ["↵", "confirm"], ["esc", "cancel"]]
        }
    }
}
