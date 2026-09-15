import QtQuick 2.12

// One console tile: system icon + short label.
// Selected tile: strong cream highlight. Unselected: restrained blue/dark.
// Icon art is resolved from assets/icons/<shortname>.png with a text-glyph
// fallback, so custom Crystal artwork can be dropped in later without
// touching layout code.
Item {
    id: root

    property bool selected: false
    property string shortName: ""
    property string label: ""
    property string fontFamily: "monospace"

    // Palette
    property color tileBg: "#323e4d"
    property color tileBorder: "#4c5d72"
    property color tileInk: "#a9c3d4"
    property color selBg: "#eadfc3"
    property color selBorder: "#fbf6e7"
    property color selInk: "#2a3441"

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 6
        color: root.selected ? root.selBg : root.tileBg
        border.width: root.selected ? 3 : 2
        border.color: root.selected ? root.selBorder : root.tileBorder

        // subtle + fast: colour crossfade only, no movement
        Behavior on color { ColorAnimation { duration: 90 } }
        Behavior on border.color { ColorAnimation { duration: 90 } }
    }

    function iconSource() {
        var base = "../assets/icons/" + root.shortName.toLowerCase().replace(/[^a-z0-9]/g, "")
        return base + (root.selected ? "_selected" : "") + ".png"
    }

    Image {
        id: icon
        // Icon art fills ~0.6 of the tile width, per the approved reference.
        width: 200
        height: 132
        anchors.horizontalCenter: parent.horizontalCenter
        y: 14
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: iconSource()
        visible: status === Image.Ready
    }

    // Fallback glyph if no icon file exists for this system
    Text {
        width: 200
        height: 132
        anchors.horizontalCenter: parent.horizontalCenter
        y: 14
        visible: icon.status !== Image.Ready
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.fontFamily
        font.bold: true
        font.pixelSize: 44
        color: root.selected ? root.selInk : root.tileInk
        text: root.shortName.length >= 2 ? root.shortName.substring(0, 3).toUpperCase() : "?"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 21
        width: parent.width - 24
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.bold: true
        font.pixelSize: 28
        font.letterSpacing: 1
        color: root.selected ? root.selInk : root.tileInk
        text: root.label
    }
}
