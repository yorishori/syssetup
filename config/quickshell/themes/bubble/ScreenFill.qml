import QtQuick
import qs.components as C
import qs.core

// The base color, deepening toward the bottom.
Rectangle {
    required property C.ScreenFill control

    gradient: Gradient {
        GradientStop { position: 0; color: Theme.palette.bg }
        GradientStop { position: 1; color: Theme.palette.shadow }
    }
}
