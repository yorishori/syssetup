import QtQuick

// Panel surface for content that floats on its own (lock console, polkit
// prompt, notification popups). `tone` makes it call for attention in that
// color (critical, hovered, a prompt that needs you).
Skinned {
    property color tone: "transparent"

    skin: "Card"
}
