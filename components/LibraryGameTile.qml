import QtQuick 2.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets

// Library grid tile: box art in a thin steel frame with the title set
// below the art (never over it). Selected: warm cream card behind the
// art + title, dark inner edge — the hero's selection language.
// 90ms colour response only — no zoom, bounce, glow, or motion.
Item {
    id: root
    width: T.gtileArtW
    height: T.gtileArtH + T.gtileTitleH

    property bool selected: false
    property var game: null          // Pegasus game object (or null)
    property string shortName: ""    // collection shortName, for the fallback
    property string fontFamily: "monospace"

    // Crystal index epoch: re-resolve cover art whenever the asynchronous
    // index (re)load completes. Reading it here registers the binding
    // dependency; first paint still uses Pegasus fallback art and never
    // blocks on the index fetch.
    property int artEpoch: 0

    // Best available cover: crystal scraped front first, then Pegasus
    // boxFront, then poster. Empty -> theme fallback art.
    function artSource() {
        return CrystalAssets.tileFront(root.game, root.shortName)
    }

    property string title: {
        if (!root.game) return ""
        var t = root.game.title || ""
        return t
    }

    // selected cream card (art + title sit on it)
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: T.cream
        visible: root.selected
    }

    // art frame
    Rectangle {
        id: frame
        x: root.selected ? 8 : 0
        y: root.selected ? 8 : 0
        width: T.gtileArtW - (root.selected ? 16 : 0)
        height: T.gtileArtH - (root.selected ? 16 : 0)
        color: root.selected ? "transparent" : T.tileFill
        border.width: 2
        border.color: root.selected ? T.selectedOutline : "#3a5a7a"

        Image {
            id: art
            anchors.fill: parent
            anchors.margins: 5
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: {
                // Depend on the crystal index epoch so covers upgrade when
                // the async index (re)load finishes.
                root.artEpoch
                return artSource()
            }
            visible: source !== "" && status === Image.Ready
        }

        GameFallbackArt {
            anchors.fill: parent
            anchors.margins: 5
            shortName: root.shortName
            title: root.title
            fontFamily: root.fontFamily
            visible: art.source === "" || art.status !== Image.Ready
        }
    }

    Text {
        x: root.selected ? 8 : 0
        y: T.gtileArtH + (root.selected ? 2 : 6)
        width: T.gtileArtW - (root.selected ? 16 : 0)
        height: T.gtileTitleH - 6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        // Long titles wrap to 2 lines then shrink to fit — never "..."
        // (1-to-1: reference shows full game names, never clipped).
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        fontSizeMode: Text.Fit
        minimumPixelSize: 10
        font.family: root.fontFamily
        font.pixelSize: 17
        font.letterSpacing: 1
        color: root.selected ? T.creamInk : T.tileInk
        text: root.title.toUpperCase()
    }
}
