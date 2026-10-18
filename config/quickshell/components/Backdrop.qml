import QtQuick

// Covers the screen behind a big panel while `shown`, to set it apart (the
// compositor may also blur behind it). `strong` for prompts that must not be
// missed (polkit). Children go on top (e.g. a click-to-close area).
// `covering`: whether it's on screen at all (still fading out, too).
Skinned {
    property bool shown: true
    property bool strong: false
    readonly property bool covering: (view?.opacity ?? 0) > 0

    skin: "Backdrop"
}
