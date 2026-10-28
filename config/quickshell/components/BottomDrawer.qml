import QtQuick

// A drawer growing out of the bottom screen edge. Place it with its bottom on
// the screen edge; it opens upward when `open`. Content goes in as children.
//
// The skin animates it: its `shownHeight` is the drawer's height,
// `contentOpacity` the content's, `contentShift` moves the content down
// (room for a title the skin draws) and `popScale` the drawer's scale.
// `overhang` is how far it draws past the sides (windows sized to the
// drawer leave room for that) and `lift` how far it floats off the screen
// edge (set it as the drawer's bottom margin). `name` says which one it is
// (the OSD's is "osd"; "clipboard", "compose",
// "capture"), for skins that dress them differently.
Skinned {
    id: root

    property bool open: false
    property int padding: 14
    property string name: ""

    default property alias content: body.data

    readonly property real openHeight: body.childrenRect.height + 2 * padding
    readonly property real overhang: view?.overhang ?? 0
    readonly property real lift: view?.lift ?? 0

    skin: "BottomDrawer"
    implicitWidth: body.childrenRect.width + 2 * padding
    implicitHeight: openHeight
    height: view?.shownHeight ?? 0
    visible: height > 0
    scale: view?.popScale ?? 1
    transformOrigin: Item.Bottom

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: body

            x: root.padding
            y: root.padding + (root.view?.contentShift ?? 0)
            width: root.width - 2 * root.padding
            opacity: root.view?.contentOpacity ?? 1
        }
    }
}
