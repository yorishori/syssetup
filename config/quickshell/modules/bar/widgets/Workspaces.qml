import QtQuick
import qs.components
import qs.services

// Workspaces 1 to `slots` (the Sway config binds keys up to 7), more if a
// higher one exists (`count`). Click one to go there, scroll to step through
// them. The skin lays them out and says which one is under a point
// (workspaceAt(x), 0 for none).
Skinned {
    id: root

    readonly property int slots: 7
    readonly property int count: Math.max(slots, ...Wm.workspaces.map(w => w.id))
    readonly property int active: Wm.activeWorkspace
    readonly property int hovered: area.containsMouse ? at(area.mouseX) : 0

    function occupied(id: int): bool {
        return Wm.isOccupied(id);
    }

    function at(x: real): int {
        return root.view?.workspaceAt(x) ?? 0;
    }

    skin: "Workspaces"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.hovered > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            const id = root.at(mouse.x);
            if (id > 0)
                Wm.focusWorkspace(id);
        }
        onWheel: wheel => {
            const id = Math.max(1, Math.min(root.count, root.active + (wheel.angleDelta.y > 0 ? -1 : 1)));
            if (id !== root.active)
                Wm.focusWorkspace(id);
        }
    }
}
