import QtQuick
import qs.modules.wallpaper as W

// The wallpaper is the forest (Forest.qml), on every screen; it holds
// still while a fullscreen window covers it.
Forest {
    required property W.Scene control

    paused: control.covered
}
