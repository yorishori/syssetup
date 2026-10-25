import QtQuick
import qs.components
import qs.services

// What to do with a capture (see CapturePrompt): save it to a path, save and
// copy it, copy it (screenshots), or discard it. The skin shows the capture
// and the path to edit; `inputArea` is what of it takes input, `showing`
// while it's on the screen (opening or closing too).
Skinned {
    id: root

    readonly property bool asking: Capture.state === "asking"
    readonly property string kind: Capture.kind  // "screenshot", "screen", "voice"
    readonly property bool isShot: kind === "screenshot"
    readonly property string file: Capture.file
    readonly property rect area: Capture.selection
    readonly property int elapsed: Capture.elapsed

    skin: "SavePrompt"

    function duration(s: int): string {
        return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
    }
    function suggestedName(): string {
        return Capture.suggestedName();
    }
    function save(path: string, alsoCopy: bool): void {
        Capture.save(path, alsoCopy);
    }
    function copy(): void {
        Capture.copy();
    }
    function discard(): void {
        Capture.discard();
    }

    Keys.onEscapePressed: discard()
}
