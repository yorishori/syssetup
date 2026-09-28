import QtQuick
import qs.core

// Thin accent bar on a list's right edge showing the scroll position; only
// visible when the content scrolls. Put it inside the Flickable/ListView's
// parent or the view itself. `inverted` for bottom-to-top lists.
Rectangle {
    required property Flickable view
    property bool inverted: false

    readonly property real ratio: view.visibleArea.heightRatio
    readonly property real position: inverted ? 1 - view.visibleArea.yPosition - ratio : view.visibleArea.yPosition

    x: view.x + view.width - width
    y: view.y + position * view.height
    width: 2
    height: ratio * view.height
    color: Config.colors.accent
    visible: view.visible && ratio < 1
}
