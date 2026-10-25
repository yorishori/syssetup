import QtQuick

// The reflection on a pane of glass: a faint sheen over the top half that
// stops at a sharp line.
Rectangle {
    property real roundness: 0

    radius: roundness
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.alpha("white", 0.075) }
        GradientStop { position: 0.48; color: Qt.alpha("white", 0.025) }
        GradientStop { position: 0.5; color: "transparent" }
        GradientStop { position: 1; color: "transparent" }
    }
}
