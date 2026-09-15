import QtQuick 2.12
import "CrystalTheme.js" as T

// One game tile: box art inside a dark Crystal frame.
// Selected: warm cream outer frame, dark inner edge, viewfinder corner
// brackets. 90ms colour response only — no zoom, bounce, glow, or motion.
Item {
    id: root
    width: T.libCoverW
    height: T.libCoverH

    property bool selected: false
    property var game: null          // Pegasus game object (or null)
    property string shortName: ""    // collection shortName, for the fallback
    property string fontFamily: "monospace"

    // Best available cover: boxFront first, then poster. Empty -> fallback.
    function artSource() {
        if (!root.game || !root.game.assets) return ""
        var a = root.game.assets
        var s = a.boxFront || a.poster || ""
        return s || ""
    }

    property string title: {
        if (!root.game) return ""
        var t = root.game.title || ""
        return t
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: root.selected ? T.cream : T.tileFill
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
        border.color: T.selectedOutline
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
        source: artSource()
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
