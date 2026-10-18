import QtQuick
import QtQuick.Layouts

// Panel section label, with an optional `code` on the far side (a count, a
// name).
Skinned {
    property string text
    property string code: ""

    skin: "SectionTitle"
    Layout.fillWidth: true
}
