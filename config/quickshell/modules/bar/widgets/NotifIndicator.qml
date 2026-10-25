import QtQuick
import qs.components
import qs.services

// Notifications waiting (`count`), and do-not-disturb. Click opens the
// notification center (`active` while it's open), right click toggles
// do-not-disturb.
Skinned {
    id: root

    property bool active: false
    readonly property int count: Notifs.list.length
    readonly property bool dnd: Notifs.dnd
    readonly property bool hovered: area.containsMouse

    signal clicked

    skin: "NotifIndicator"

    MouseArea {
        id: area

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Notifs.setDnd(!Notifs.dnd, 0);
            else
                root.clicked();
        }
    }
}
