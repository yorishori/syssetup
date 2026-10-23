import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.modules.session as M

// The session menu as a drop: a title with the host and uptime, the keys
// stacked, the key hints below.
Item {
    id: root

    required property M.SessionPanel control

    implicitWidth: 300
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        C.SectionTitle {
            text: "Session"
            code: `${root.control.hostname} · up ${root.control.uptimeText}`
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
