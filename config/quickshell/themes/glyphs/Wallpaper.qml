import QtQuick
import qs.modules.wallpaper as W

// No shared scene: a theme without a Wallpaper skin of its own shows your
// image (modules/wallpaper/Wallpaper.qml never loads this).
Item {
    required property W.Scene control
}
