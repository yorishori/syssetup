import QtQuick

// A drawer growing out of the bottom screen edge. Place it with its bottom on
// the screen edge; it opens upward when `open`. Content goes in as children.
//
// The skin animates it: its `shownHeight` is the drawer's height and
// `contentOpacity` the content's, and `overhang` is how far it draws past
// the sides (windows sized to the drawer leave room for that).
Skinned {
    id: root

    property bool open: false
    property int padding: 14

    default property alias content: body.data

    readonly property real openHeight: body.childrenRect.height + 2 * padding
    readonly property real overhang: view?.overhang ?? 0

    skin: "BottomDrawer"
    implicitWidth: body.childrenRect.width + 2 * padding
    implicitHeight: openHeight
    height: view?.shownHeight ?? 0
    visible: height > 0

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: body

            x: root.padding
            y: root.padding
            width: root.width - 2 * root.padding
            opacity: root.view?.contentOpacity ?? 1
        }
    }
}
