import QtQuick 2.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets

// Library grid tile (rebuilt 2026-09-19): the cover IS the tile.
// No frame, no border on unselected tiles — just art with breathing room.
// Selected: warm cream card behind the art (the approved reference).
// Missing art: quiet Crystal placeholder, deliberately not equal to real art.
Item {
    id: root
    width: T.gtileArtW
    height: T.gtileArtH + T.gtileTitleH

    property bool selected: false
    property var game: null
    property string shortName: ""
    property string fontFamily: "monospace"
    property int artEpoch: 0

    function artSource() {
        return CrystalAssets.tileFront(root.game, root.shortName)
    }

    property string title: {
        if (!root.game) return ""
        return root.game.title || ""
    }

    // Selected: cream card (art + title sit on it). Unselected: transparent.
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: CrystalColors.cream
        visible: root.selected
    }

    // Cover art — dominates the tile. No border, no frame.
    Image {
        id: art
        x: root.selected ? 7 : 0
        y: root.selected ? 7 : 0
        width: T.gtileArtW - (root.selected ? 14 : 0)
        height: T.gtileArtH - (root.selected ? 14 : 0)
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        source: {
            root.artEpoch
            return artSource()
        }
        visible: source !== "" && status === Image.Ready
    }

    // Quiet placeholder for missing art: dark tile with a subtle Crystal
    // mark. Obviously intentional, never confused with real artwork.
    Rectangle {
        x: root.selected ? 7 : 0
        y: root.selected ? 7 : 0
        width: T.gtileArtW - (root.selected ? 14 : 0)
        height: T.gtileArtH - (root.selected ? 14 : 0)
        radius: 6
        color: root.selected ? CrystalColors.alpha(CrystalColors.creamInk, 0.08)
                             : CrystalColors.alpha(CrystalColors.tile, 0.6)
        visible: art.source === "" || art.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            font.family: root.fontFamily
            font.pixelSize: 28
            font.letterSpacing: 3
            color: root.selected ? CrystalColors.creamInk : CrystalColors.mutedBlue
            opacity: 0.4
            text: "◇"
        }
    }

    // Title: secondary, quiet, single line. Never a text block.
    Text {
        x: root.selected ? 7 : 0
        y: T.gtileArtH + (root.selected ? 2 : 6)
        width: T.gtileArtW - (root.selected ? 14 : 0)
        height: T.gtileTitleH
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: root.fontFamily
        font.pixelSize: 14
        font.letterSpacing: 1
        color: root.selected ? CrystalColors.creamInk : CrystalColors.tileInk
        opacity: root.selected ? 1.0 : 0.75
        text: root.title.toUpperCase()
    }
}
