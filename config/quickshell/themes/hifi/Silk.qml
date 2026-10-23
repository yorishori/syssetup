import QtQuick
import qs.components as C
import qs.core

// Print on a faceplate, in the silkscreen's gold: what the maker named a
// part or a section.
C.StyledText {
    caps: true
    color: Theme.values.display?.silk ?? Theme.palette.dim
    font.pixelSize: 10
    font.bold: true
    tracking: 1.5
}
