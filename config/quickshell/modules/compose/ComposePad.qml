import QtQuick
import qs.components
import qs.services

// The compose overlay's behaviour. Type a sequence (' then e) and every
// character it can still become is offered with its keys; a complete,
// unambiguous sequence inserts right away. Typing something that starts no
// sequence searches by name ("euro"). Enter inserts the selected one,
// arrows move, Escape closes. The skin (ComposeMenu) lays it out, with the
// field the sequence is typed in (it sets `typed`); `cleared` asks it to
// empty that and take the keys.
Skinned {
    id: root

    readonly property bool open: Compose.open
    readonly property bool loaded: Compose.loaded
    readonly property int sequences: Compose.entries.length

    property string typed: ""
    property int selected: 0
    readonly property var results: Compose.search(typed)
    readonly property bool byName: typed !== "" && results.length > 0 && !results[0].seq.startsWith(typed)
    // How many results to a row (Up/Down move a row): the skin's.
    readonly property int columns: view?.columns ?? 8
    // Where the sequence can go next: { key: { count, result } }, the key's
    // character, how many sequences go on through it, and what it makes if
    // typing it completes one. Empty when searching by name.
    readonly property var next: {
        if (byName)
            return {};
        const out = {};
        const at = typed.length;
        for (const e of Compose.entries) {
            if (e.seq.length <= at || !e.seq.startsWith(typed))
                continue;
            const k = e.seq[at];
            const n = out[k] ?? (out[k] = { count: 0, result: "" });
            n.count++;
            if (e.seq.length === at + 1)
                n.result = e.result;
        }
        return out;
    }

    signal cleared

    skin: "ComposeMenu"

    function move(step: int): void {
        if (results.length > 0)
            selected = Math.max(0, Math.min(results.length - 1, selected + step));
    }

    function insert(result: string): void {
        Compose.insert(result);
    }
    function insertSelected(): void {
        const r = results[selected];
        if (r)
            Compose.insert(r.result);
    }
    function close(): void {
        Panels.close();
    }

    Connections {
        target: Compose

        function onOpenChanged(): void {
            root.typed = "";
            root.cleared();
        }
    }
    onTypedChanged: {
        selected = 0;
        const done = Compose.complete(typed);
        if (done)
            Compose.insert(done.result);
    }

    Keys.onUpPressed: move(-columns)
    Keys.onDownPressed: move(columns)
    Keys.onEscapePressed: close()
}
