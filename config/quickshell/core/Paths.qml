pragma Singleton

import QtQuick
import Quickshell

// Where things go on disk.
Singleton {
    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") ?? ""

    // "~" or "~/…" → under $HOME; anything else as it is.
    function expand(path: string): string {
        return path.replace(/^~(?=\/|$)/, home);
    }

    // A folder only we can read, for temp files that may hold private data
    // (clipboard images, captures): the session's runtime dir, else the
    // shell's cache, never /tmp, which anyone can write to. Pure: whoever
    // writes there creates it (mkdir -p "$d" && chmod 700 "$d"), or calls
    // makePrivate().
    function privateDir(name: string): string {
        return runtimeDir ? `${runtimeDir}/qs-${name}` : `${Quickshell.cacheDir}/${name}`;
    }

    function makePrivate(dir: string): void {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1"', "sh", dir]);
    }
}
