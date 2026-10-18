import QtQuick

// Covers the screen behind a big panel while `shown`, to set it apart (the
// compositor may also blur behind it). `strong` for prompts that must not be
// missed (polkit). Children go on top (e.g. a click-to-close area).
Skinned {
    property bool shown: true
    property bool strong: false

    skin: "Backdrop"
}
