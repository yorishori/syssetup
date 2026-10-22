import QtQuick
import QtQuick.Shapes
import qs.core
import qs.modules.notifications as M

// A lamp just past the top right corner of the screen, out of sight: what
// shows is its light on the desktop. It comes up when something comes in,
// tinted by how urgent the most urgent waiting one is (cool for low, amber
// for normal, red for critical), and dies down over the time those take to
// go; a critical one keeps it breathing until it's dealt with. Over a
// fullscreen window it's dimmer. It's only light: nothing to click; what came
// in is read in the drawer.
Item {
    id: root

    required property M.PopupStack control

    // Nothing takes input.
    readonly property Item inputArea: null
    readonly property var waiting: control.popups
    readonly property int urgency: waiting.reduce((most, n) => Math.max(most, n?.urgency ?? 1), -1)
    readonly property bool critical: waiting.some(n => control.critical(n))
    readonly property color tint: urgency >= 2 ? "#ff3b2a" : urgency === 1 ? "#ffb04a" : "#cfe2ff"
    // Now, kept current while it glows, for how far each has died down.
    property real now: Date.now()
    // How bright: the brightest of what's waiting, each dying down over its
    // time.
    readonly property real level: {
        let most = 0;
        for (const n of waiting) {
            const t = control.timeout(n);
            const at = control.receivedAt(n);
            const left = t > 0 && at ? 1 - (now - at) / (t * 1000) : 1;
            most = Math.max(most, Math.max(0.25, Math.min(1, left)));
        }
        return most;
    }
    property real breath: 1

    Timer {
        interval: 120
        running: root.waiting.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
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
    SequentialAnimation on breath {
        running: root.critical
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.55; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
    }

    // The light, from past the corner.
    Shape {
        id: glow

        readonly property real reach: 520

        anchors.fill: parent
        opacity: root.waiting.length > 0 ? root.level * (root.critical ? root.breath : 1) * (root.control.fullscreen ? 0.6 : 1) : 0
        preferredRendererType: Shape.CurveRenderer

        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.OutQuad }
        }

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
