import QtQuick 2.12
import "IconResolver.js" as IconResolver
import "CrystalTheme.js" as T

// One console tile: system icon + short display label.
//
// Unselected: dark tile with the hero's open-corner frame (border segments
// stop short of the corners; a registration dot sits in each gap).
// Selected: warm ivory fill, subtle dark outline, four dark "viewfinder"
// corner brackets. Selection never changes the artwork — the cream tile is
// the selection signal, per the approved Crystal reference.
Item {
    id: root

    property bool selected: false
    property string shortName: ""
    property string label: ""
    property string fontFamily: "monospace"

    Rectangle {
        id: bg
        anchors.fill: parent
        color: root.selected ? T.cream : T.tileFill

        // subtle + fast: colour crossfade only, no movement
        Behavior on color { ColorAnimation { duration: 90 } }
    }

    TileFrame {
        visible: !root.selected
    }

    // subtle dark outline around the cream tile
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: T.selectedOutline
        visible: root.selected
    }

    SelectedMarks {
        visible: root.selected
    }

    function iconSource() {
        // Single artwork for both states; "" falls back to the text glyph.
        return IconResolver.iconFor(root.shortName, root.selected)
    }

    Image {
        id: icon
        // Production art sits large and confident: square display sized so
        // the ~76% content lands at the hero's ~200px visual width,
        // optically centred just above the tile middle.
        property real iscale: T.iconScaleFor(root.shortName)
        width: T.iconSize * iscale
        height: T.iconSize * iscale
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: T.iconCenterYOffset
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: iconSource()
        visible: source !== "" && status === Image.Ready
    }

    // Fallback glyph if no icon file exists for this system
    Text {
        width: T.iconSize
        height: T.iconSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: T.iconCenterYOffset
        visible: icon.source === "" || icon.status !== Image.Ready
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.fontFamily
        font.pixelSize: 44
        color: root.selected ? T.creamInk : T.tileInk
        text: root.shortName.length >= 2 ? root.shortName.substring(0, 3).toUpperCase() : "?"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: T.labelBottomMargin
        width: parent.width - 24
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.fontLabelPx
        font.letterSpacing: T.labelLetterSpacing
        font.bold: true
        color: root.selected ? T.creamInk : T.tileInk
        text: root.label
    }
}
