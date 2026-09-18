import QtQuick 2.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets

// One game tile: box art inside a dark Crystal frame.
// Selected: warm cream outer frame, dark inner edge, viewfinder corner
// brackets. 90ms colour response only — no zoom, bounce, glow, or motion.
// Physical media lives in the dedicated Inspect view (Y / Details);
// tiles stay fast, clear, box-art based.
Item {
    id: root
    width: T.libCoverW
    height: T.libCoverH

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

    Rectangle {
        id: bg
        anchors.fill: parent
        color: root.selected ? CrystalColors.cream : CrystalColors.tile
        Behavior on color { ColorAnimation { duration: 90 } }
    }

    TileFrame {
        visible: !root.selected
    }

    // dark inner edge inside the cream frame
    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        color: "transparent"
        border.width: 2
        border.color: CrystalColors.selectedOutline
        visible: root.selected
    }

    SelectedMarks {
        visible: root.selected
    }

    Image {
        id: art
        anchors.fill: parent
        anchors.margins: root.selected ? 16 : 12
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        source: {
            // Depend on the crystal index epoch so covers upgrade when the
            // async index (re)load finishes; game/shortName are tracked
            // through artSource() as before.
            root.artEpoch
            return artSource()
        }
        visible: source !== "" && status === Image.Ready
    }

    GameFallbackArt {
        anchors.fill: parent
        anchors.margins: root.selected ? 16 : 12
        shortName: root.shortName
        title: root.title
        fontFamily: root.fontFamily
        visible: art.source === "" || art.status !== Image.Ready
    }
}
