import QtQuick

// The paper of a title strip, red rules along its edges.
Rectangle {
    required property color card
    required property color rule

    radius: 1.5
    border.width: 1
    border.color: Qt.darker(card, 1.6)
    gradient: Gradient {
        GradientStop { position: 0; color: card }
        GradientStop { position: 1; color: Qt.darker(card, 1.08) }
    }

    Rectangle {
        x: 6
        y: 3
        width: parent.width - 12
        height: 1.5
        color: rule
        opacity: 0.8
    }
    Rectangle {
        x: 6
        y: parent.height - 4.5
        width: parent.width - 12
        height: 1.5
        color: rule
        opacity: 0.8
    }
}
