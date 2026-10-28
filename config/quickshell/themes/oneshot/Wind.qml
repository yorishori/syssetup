pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Now and then a gentle gust through the cabin: it crosses the bar from one
// side to the other, and what hangs on twine (the workspace tags, the
// potion bottles) sways a degree or two as it passes, then settles. Ask
// `sway(x, seed)` for the angle of something hanging at screen x; `started`
// says a gust is on its way (a good time to find where you are).
Singleton {
    id: root

    // Through the gust, 0 to 1 (it's still between gusts), and which way
    // it goes.
    property real t: 1
    property int direction: 1

    // How wide the screen is, so it crosses all of it; how long a gust
    // takes, crossing and settling.
    readonly property real span: Quickshell.screens[0]?.width ?? 1920
    readonly property int length: 6000
    readonly property bool animate: Theme.get("pixel.animate") ?? true

    signal started

    function sway(x: real, seed: int): real {
        if (t >= 1)
            return 0;
        // It reaches x a while after it starts, crossing at ~700 px a second.
        const reach = (direction > 0 ? x : span - x) / 0.7;
        const local = t * length - reach;
        if (local <= 0)
            return 0;
        const fade = Math.exp(-local / 650);
        return 2.4 * fade * Math.sin(local / 150 + seed * 0.7);
    }

    Timer {
        running: root.animate
        repeat: true
        interval: 20000 + Math.random() * 25000
        onTriggered: {
            interval = 20000 + Math.random() * 25000;
            root.direction = Math.random() < 0.5 ? 1 : -1;
            root.started();
            gust.restart();
        }
    }
    NumberAnimation {
        id: gust

        target: root
        property: "t"
        from: 0
        to: 1
        duration: root.length
    }
}
