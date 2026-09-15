import QtQuick 2.12
import "../components"
import "../components/CrystalTheme.js" as T

// Phase 2: per-system game library. 4x2 box-art grid driven by the real
// Pegasus collection model — no demo content in production.
// A launches the selected game via game.launch(); B returns home.
Item {
    id: root

    property var collection: null
    property string shortName: ""
    property string fontFamily: "monospace"

    // navigation / launch surface used by theme.qml
    function moveLeft()  { grid.moveLeft() }
    function moveRight() { grid.moveRight() }
    function moveUp()    { grid.moveUp() }
    function moveDown()  { grid.moveDown() }
    function reset()     { grid.reset() }
    function setGameIndex(i) { grid.setIndex(i) }

    // The real Pegasus launch mechanism: the game's own launch() method.
    // Pegasus owns emulator selection via its metadata; the theme only
    // invokes it. api.memory persists the selection across the reload
    // Pegasus performs after a game exits.
    function launchCurrent() {
        var game = grid.currentGame
        if (!game) return false
        if (typeof api !== "undefined" && api.memory) {
            api.memory.set("crystalNova.lastSystem", root.shortName)
            api.memory.set("crystalNova.lastGame", grid.currentIndex)
        }
        try {
            game.launch()
        } catch (e) {
            return false
        }
        return true
    }

    readonly property bool isEmpty: grid.count === 0
    readonly property int page: grid.page
    readonly property int pageCount: grid.pageCount
    readonly property int gameIndex: grid.currentIndex

    GameGrid {
        id: grid
        objectName: "gameGrid"
        anchors.fill: parent
        games: root.collection ? root.collection.games : null
        shortName: root.shortName
        fontFamily: root.fontFamily
        visible: !root.isEmpty
    }

    // ---- empty collection -------------------------------------------------
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 14
        visible: root.isEmpty

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 40
            font.letterSpacing: 4
            color: T.primaryInk
            text: "NO GAMES FOUND"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: T.fontFooterPx
            font.letterSpacing: 2
            color: T.tileInk
            text: "ADD GAMES TO THIS COLLECTION"
        }
    }

    // ---- selected game title ----------------------------------------------
    // One clean elided line: predictable, firmware-like, never a metadata
    // wall. (QML elide wins over wrapMode in this Qt build, so the title
    // is deliberately single-line rather than a ragged two-line clip.)
    Text {
        id: gameTitle
        objectName: "libraryGameTitle"
        x: T.libGridX
        y: T.libTitleY
        width: T.canvasW - 2 * T.libGridX
        height: T.libTitleH
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.libTitlePx
        font.letterSpacing: 2
        color: T.primaryInk
        visible: !root.isEmpty
        text: {
            var g = grid.currentGame
            if (!g) return ""
            var t = g.title || ""
            if (t === "") return "UNTITLED"
            return t.toUpperCase()
        }
    }
}
