import QtQuick
import qs.components
import qs.core

// Which parts of the shell are down (`issues`: their names). The skin may
// hide it while all is fine (`shown`).
Skinned {
    readonly property var issues: Object.keys(Health.issues)

    skin: "HealthIndicator"
    visible: view?.shown ?? true
}
