import QtQuick
import Quickshell.Io

// Runs one command at a time and says how it went: `done(ok, output)` with
// the exit status and what it printed (stdout and stderr together, colour
// codes removed, on one line). For the user's actions (connect, mount…),
// whose error text is worth showing.
//
//   Action { id: action; onDone: (ok, output) => … }
//   action.run(["udisksctl", "mount", "-b", device])
Process {
    id: root

    // false: only stderr is kept (for tools whose stdout is noise).
    property bool keepStdout: true

    signal done(bool ok, string output)

    // false if one is still running (nothing is started then).
    function run(argv: var): bool {
        if (running)
            return false;
        command = ["sh", "-c", keepStdout ? '"$@" 2>&1; echo "exit:$?"' : '"$@" 2>&1 >/dev/null; echo "exit:$?"', "sh", ...argv];
        running = true;
        return true;
    }

    stdout: StdioCollector {
        onStreamFinished: {
            const out = text.replace(/\x1b\[[0-9;]*m/g, "").trim().split("\n");
            const code = out.pop();
            root.done(code === "exit:0", out.join(" ").trim());
        }
    }
}
