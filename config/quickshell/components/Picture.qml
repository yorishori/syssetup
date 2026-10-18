import QtQuick

// A framed picture (cover art): `source`, or the `icon` (theme icon or path)
// when there's no picture. Give it its size.
Skinned {
    property string source
    property string icon: ""

    skin: "Picture"
}
