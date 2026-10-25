import QtQuick
import Quickshell.Widgets
import qs.modules.bar.widgets as W

// The tray icons side by side in their own compartment. Hidden when empty.
Item {
    id: root

    required property W.Tray control
    readonly property bool shown: control.items.length > 0
    readonly property int icon: 16
    readonly property int gap: 8
    readonly property int padding: 7

    function slotRect(index: int): rect {
        return Qt.rect(padding + index * (icon + gap), (height - icon) / 2, icon, icon);
    }

    implicitWidth: Math.max(0, control.items.length * (icon + gap) - gap) + 2 * padding
    implicitHeight: 22

    W.BarBox {
        anchors.fill: parent
    }

    Repeater {
        model: root.control.items

        IconImage {
            required property int index
            required property var modelData
            readonly property rect slot: root.slotRect(index)

            x: slot.x
            y: slot.y
            implicitSize: root.icon
            source: modelData.icon
        }
    }
}
