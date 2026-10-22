import QtQuick
import Quickshell.Services.SystemTray
import qs.components

// System tray apps, all visible. The skin draws them and places each one
// (slotRect(index)); here they take the clicks. Left click: activate, middle:
// secondary action, right (or left on menu-only items): menuRequested, which
// the bar shows as a drop (TrayMenu). The skin may hide it while empty
// (`shown`).
Skinned {
    id: tray

    readonly property var items: SystemTray.items.values
    // The app whose menu is open, if any (skins may show it pulled out).
    property var pulled: null

    signal menuRequested(SystemTrayItem trayItem, Item anchor)

    // Open the menu of the first item whose id or title contains `query`.
    function openMenu(query: string): bool {
        const q = query.toLowerCase();
        const index = items.findIndex(i => `${i.id} ${i.title}`.toLowerCase().includes(q));
        if (index < 0 || !items[index].hasMenu)
            return false;
        menuRequested(items[index], icons.itemAt(index));
        return true;
    }

    skin: "Tray"
    visible: view?.shown ?? true

    Repeater {
        id: icons

        model: SystemTray.items

        MouseArea {
            id: item

            required property int index
            required property SystemTrayItem modelData
            readonly property rect slot: tray.view?.slotRect(index) ?? Qt.rect(0, 0, 0, 0)

            x: slot.x
            y: slot.y
            width: slot.width
            height: slot.height
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
        }
    }
}
