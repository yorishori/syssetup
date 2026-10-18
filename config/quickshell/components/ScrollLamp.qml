import QtQuick

// Scroll position of a list, shown only when the content scrolls. Put it
// next to the Flickable/ListView (same parent) or inside it; it covers the
// view and the skin draws the indicator. `inverted` for bottom-to-top lists.
Skinned {
    required property Flickable view
    property bool inverted: false

    readonly property real ratio: view.visibleArea.heightRatio
    readonly property real position: inverted ? 1 - view.visibleArea.yPosition - ratio : view.visibleArea.yPosition

    skin: "ScrollLamp"
    x: view.x
    y: view.y
    width: view.width
    height: view.height
    visible: view.visible && ratio < 1
}
