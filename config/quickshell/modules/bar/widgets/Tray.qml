import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// System tray icons in their own compartment, all visible. Left click:
// activate, middle: secondary action, right (or left on menu-only items):
// menuRequested, which the bar shows as a drop (TrayMenu).
BarBox {
    id: tray

    signal menuRequested(SystemTrayItem trayItem, Item anchor)

    // Open the menu of the first item whose id or title contains `query`.
    function openMenu(query: string): bool {
        const q = query.toLowerCase();
        const items = SystemTray.items.values;
        const index = items.findIndex(i => `${i.id} ${i.title}`.toLowerCase().includes(q));
        if (index < 0 || !items[index].hasMenu)
            return false;
        menuRequested(items[index], icons.itemAt(index));
        return true;
    }

    visible: SystemTray.items.values.length > 0

    Repeater {
        id: icons

        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();
                } else if (modelData.hasMenu) {
                    tray.menuRequested(modelData, item);
                }
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
