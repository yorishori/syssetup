import QtQuick
import QtQuick.Shapes
import qs.core
import qs.modules.notifications as M

// A lamp just past the top right corner of the screen, out of sight: what
// shows is its light on the corner of the desktop and the panel. Something
// coming in swells it up and down again (two seconds), tinted by how urgent
// it is (cool for low, amber for normal); while anything critical waits, it
// breathes red until that's dealt with. Over a fullscreen window it's
// dimmer. It's only light: nothing to click; what came in is read in the
// drawer.
Item {
    id: root

    required property M.PopupStack control

    // Nothing takes input.
    readonly property Item inputArea: null
    readonly property var waiting: control.popups
    readonly property bool critical: waiting.some(n => control.critical(n))
    // A swell for something new (0-1), in its tint.
    property real swell: 0
    property color swellTint: "#ffb04a"
    property var seen: []
    property real breath: 0
    readonly property color tint: critical ? "#ff3b2a" : swellTint

    onWaitingChanged: {
        const fresh = waiting.filter(n => !seen.includes(n) && !control.critical(n));
        if (fresh.length > 0) {
            swellTint = (fresh[0]?.urgency ?? 1) === 0 ? "#cfe2ff" : "#ffb04a";
            swelling.restart();
        }
        seen = waiting.slice();
    }

    // Each goes after its time.
    Repeater {
        model: root.waiting

        Item {
            required property var modelData

            Timer {
                interval: root.control.timeout(parent.modelData) * 1000
                running: interval > 0
                onTriggered: root.control.hide(parent.modelData)
            }
        }
    }
    SequentialAnimation {
        id: swelling

        NumberAnimation { target: root; property: "swell"; to: 1; duration: 600; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "swell"; to: 0; duration: 1400; easing.type: Easing.InOutQuad }
    }
    SequentialAnimation on breath {
        running: root.critical
        loops: Animation.Infinite

        NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.35; duration: 1400; easing.type: Easing.InOutSine }
    }
    Behavior on breath {
        enabled: !root.critical
        NumberAnimation { duration: 600 }
    }
    onCriticalChanged: if (!critical) breath = 0

    // The light, from past the corner.
    Shape {
        id: glow

        readonly property real reach: 520

        anchors.fill: parent
        opacity: Math.max(root.swell, root.critical ? root.breath : 0) * (root.control.fullscreen ? 0.6 : 1)
        visible: opacity > 0.01
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: glow.width + 60
                centerY: -60
                centerRadius: glow.reach
                focalX: centerX
                focalY: centerY

                GradientStop { position: 0; color: Qt.alpha(Qt.lighter(root.tint, 1.25), 0.7) }
                GradientStop { position: 0.18; color: Qt.alpha(root.tint, 0.42) }
                GradientStop { position: 0.5; color: Qt.alpha(root.tint, 0.12) }
                GradientStop { position: 1; color: Qt.alpha(root.tint, 0) }
            }
            startX: glow.width - glow.reach
            startY: 0

            PathLine { x: glow.width; y: 0 }
            PathLine { x: glow.width; y: glow.reach }
            PathLine { x: glow.width - glow.reach; y: glow.reach }
            PathLine { x: glow.width - glow.reach; y: 0 }
        }
    }
}
