import QtQuick
import qs.components
import qs.core

// Which parts of the shell are down, as a red warning tag. Hidden when all is
// fine; loud on purpose when not.
Tag {
    visible: Health.count > 0
    text: "\u{F0026} " + Object.keys(Health.issues).join(" ")
    fill: Theme.palette.error
    size: Theme.font.size - 2
}
