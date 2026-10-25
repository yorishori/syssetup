import QtQuick
import qs.components
import qs.services

// The clipboard panel's behaviour: the tabs (history, then the symbol
// sets), the filter, the selection and picking. Whatever you pick is pasted
// into the window you were in (Enter), or only copied (Shift+Enter). Tab /
// Shift+Tab switch tabs, arrows move, Escape closes. The skin
// (ClipboardMenu) lays it out, with the filter field; `cleared` asks it to
// empty the field, `focusRequested` to give it the keys.
Skinned {
    id: root

    readonly property var tabs: [
        { key: "history", label: "History" },
        { key: "emoji", label: "Emoji" },
        { key: "nerd", label: "Nerd" },
        { key: "symbol", label: "Symbols" },
        { key: "kaomoji", label: "Kaomoji" }
    ]
    property int current: 0
    readonly property string tab: tabs[current].key
    readonly property bool onHistory: tab === "history"
    readonly property bool open: Clipboard.open

    property string query: ""
    property int selected: 0

    // Symbol results for the current tab. The list and grid read their own
    // source, never `entries`: on a tab switch they could otherwise catch it
    // before it updates and get the other kind of entry for a moment.
    readonly property var symbols: onHistory ? [] : Symbols.search(query, tab)
    readonly property var clips: Clipboard.filtered
    // History entries, or symbol results for the current tab.
    readonly property var entries: onHistory ? clips : symbols
    readonly property int columns: tab === "kaomoji" ? 3 : 12
    // All the history, unfiltered; thumbnails of the images in it.
    readonly property var allHistory: Clipboard.entries
    readonly property var thumbs: Clipboard.thumbs
    readonly property bool symbolsLoaded: Symbols.loaded

    signal cleared
    signal focusRequested

    skin: "ClipboardMenu"

    function move(step: int): void {
        if (entries.length > 0)
            selected = Math.max(0, Math.min(entries.length - 1, selected + step));
    }

    function switchTab(step: int): void {
        current = (current + step + tabs.length) % tabs.length;
    }

    function pick(index: int, modifiers: int): void {
        const entry = entries[index];
        if (!entry)
            return;
        const paste = !(modifiers & Qt.ShiftModifier);
        if (onHistory)
            Clipboard.pick(entry, paste);
        else
            Clipboard.insert(entry.ch, paste);
    }

    // The filter, as typed.
    function setQuery(text: string): void {
        query = text;
        Clipboard.query = onHistory ? text : "";
        selected = 0;
    }

    function hide(): void {
        Clipboard.hide();
    }
    function wipe(): void {
        Clipboard.wipe();
    }
    function remove(entry: var): void {
        Clipboard.remove(entry);
    }

    Connections {
        target: Clipboard

        function onOpenChanged(): void {
            root.selected = 0;
            root.cleared();
            if (!Clipboard.open)
                return;
            const start = root.tabs.findIndex(t => t.key === Clipboard.startTab);
            root.current = start >= 0 ? start : 0;
            Clipboard.startTab = "";
            root.focusRequested();
        }
    }
    onTabChanged: {
        selected = 0;
        cleared();
        // `tab`, not `onHistory`: that may not have caught up yet.
        if (tab !== "history")
            Symbols.load();
        focusRequested();
    }
    onEntriesChanged: selected = Math.min(selected, Math.max(0, entries.length - 1))

    // Up goes up the list, whichever end its newest is at (the skin's
    // `newestAtTop`; else at the bottom, by the prompt).
    readonly property bool newestAtTop: view?.newestAtTop ?? false

    Keys.onUpPressed: move(onHistory ? (newestAtTop ? -1 : 1) : -columns)
    Keys.onDownPressed: move(onHistory ? (newestAtTop ? 1 : -1) : columns)
    Keys.onTabPressed: switchTab(1)
    Keys.onBacktabPressed: switchTab(-1)
    Keys.onEscapePressed: hide()
}
