import QtQuick
import Quickshell

// Loads one module in isolation.
//
// The module is compiled at runtime instead of being referenced as a type, so
// a broken module (syntax error, missing import, failed dependency) is reported
// to Health instead of taking the whole shell down with it.
//
// Modules that draw windows are unloaded while no monitor is connected and
// loaded again when one comes back: the compositor closes a window whose
// monitor goes away (as on waking from sleep), and it isn't reopened.
LazyLoader {
    id: root

    required property string name
    required property string path  // relative to the shell root
    // false for a module that handles monitors coming and going itself.
    property bool needsScreen: true

    // Qt stands in a nameless placeholder screen while there's no real one.
    readonly property bool hasScreen: Quickshell.screens.some(s => s.name !== "")
    property bool compiled: false

    // Set, not bound: LazyLoader drops a binding on `active` once it unloads.
    function update(): void {
        active = compiled && (hasScreen || !needsScreen);
    }
    onHasScreenChanged: update()

    Component.onCompleted: {
        const url = Qt.resolvedUrl("../" + path);
        const comp = Qt.createComponent(url);
        if (comp.status === Component.Error) {
            Health.report(name, comp.errorString().trim());
            return;
        }

        // Loaded from `source`, so the loader keeps its own component; one
        // set from here would be garbage collected after the first unload.
        source = url;
        compiled = true;
        update();

        // The item is created once the shell finishes loading, not right away.
        Qt.callLater(() => {
            if (active && !item)
                Health.report(name, "failed to create (see log)");
        });
    }
}
