import QtQuick

// Keeps a service's live readings going while `when` holds: counts itself in
// the service's `users` (an int; the service polls while it's above 0), so
// any number of things can show the same readings and none turns them off
// for the others.
//
//   Live { target: Sysinfo; when: root.open }
QtObject {
    id: root

    required property QtObject target
    property bool when: true

    property bool counted: false

    function update(): void {
        const want = when && !!target;
        if (want === counted)
            return;
        target.users += want ? 1 : -1;
        counted = want;
    }

    onWhenChanged: update()
    Component.onCompleted: update()
    Component.onDestruction: {
        if (counted)
            target.users -= 1;
    }
}
