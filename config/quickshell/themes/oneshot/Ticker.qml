import QtQuick
import qs.core

// The pixel art's clock: counts frames, `fps` a second. Loops read `frame`
// and pick their step from it, so everything moves in whole frames, never
// tweened. With the theme's pixel.animate off it holds still.
Timer {
    property int frame: 0
    property real fps: Theme.get("pixel.fps") ?? 4

    interval: Math.round(1000 / fps)
    repeat: true
    running: Theme.get("pixel.animate") ?? true
    // Wraps at a number every loop length divides, so no loop jumps.
    onTriggered: frame = (frame + 1) % 55440
}
