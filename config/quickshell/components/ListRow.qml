import QtQuick
import QtQuick.Layouts
import qs.core

// A row in any panel list: cut-corner hover/selection fill, an accent marker
// when `current` (keyboard selection), and a click area. Content goes in as
// children and is laid out in a row with side margins.
//
//   ListRow { current: …; onClicked: mouse => …; StyledText { … } }
Item {
    id: root

    property bool current: false      // keyboard selection: fill + marker
    property bool highlighted: false  // extra "on" state without the marker
    property bool marker: true
    property int acceptedButtons: Qt.LeftButton
    readonly property bool hovered: area.containsMouse

    default property alias content: row.data
    property alias spacing: row.spacing
    property int leftPadding: 12
    property int rightPadding: 10

    signal clicked(var mouse)
    signal entered

    Layout.fillWidth: true
    implicitHeight: 28
    opacity: enabled ? 1 : 0.5

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: root.current || root.highlighted || (root.hovered && root.enabled) ? Config.colors.surface : "transparent"
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 14
        color: Config.colors.accent
        visible: root.marker && root.current
    }

    // Under the content, so buttons inside the row keep their own clicks.
    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: root.acceptedButtons
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.entered()
        onClicked: mouse => {
            if (root.enabled)
                root.clicked(mouse);
        }
    }

    RowLayout {
        id: row

        anchors {
            fill: parent
            leftMargin: root.leftPadding
            rightMargin: root.rightPadding
        }
        spacing: 10
    }

}
