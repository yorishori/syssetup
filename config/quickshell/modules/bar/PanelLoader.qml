import QtQuick
import qs.components
import qs.core

// Loads one panel (a drop's contents, modules/<name>/<Name>Panel.qml) in
// isolation: it's compiled at runtime rather than referenced as a type, so a
// broken panel is reported to Health and shows a stand-in, while the bar and
// every other panel keep working.
//
// Panels may declare `property bool open` (kept bound to the drop), `signal
// done` (closes the drop) and `signal fallback`; `bindings` keeps any other
// panel properties bound: { item: () => bar.trayItem }.
Item {
    id: root

    required property string name
    property bool open: false
    property var bindings: ({})

    signal done
    signal fallback

    property Item panel: null
    property string error: ""

    readonly property string path: {
        const file = name.charAt(0).toUpperCase() + name.slice(1) + "Panel.qml";
        return `modules/${name}/${file}`;
    }

    implicitWidth: panel ? panel.width : stand.implicitWidth
    implicitHeight: panel ? panel.height : stand.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: {
        const comp = Qt.createComponent(Qt.resolvedUrl("../../" + path));
        if (comp.status === Component.Error) {
            error = comp.errorString().trim();
            Health.report(name, error);
            return;
        }

        const props = {};
        for (const key in bindings)
            props[key] = Qt.binding(bindings[key]);
        const obj = comp.createObject(root, props);
        if (!obj) {
            error = "failed to create (see log)";
            Health.report(name, error);
            return;
        }
        if ("open" in obj)
            obj.open = Qt.binding(() => root.open);
        if (obj.done)
            obj.done.connect(root.done);
        if (obj.fallback)
            obj.fallback.connect(root.fallback);
        panel = obj;
    }

    Placeholder {
        id: stand

        width: 260
        visible: root.panel === null && root.error !== ""
        text: `-- ${root.name} is down (see the red tag) --`
        wrapMode: Text.Wrap
    }
}
