import QtQuick 2.12
import "CrystalTheme.js" as T

// 4x2 box-art grid with clean paging. Renders only the current page
// (8 tiles); D-pad navigation crosses page boundaries. Never lands on
// an invalid slot. Works from 0 to N games.
Item {
    id: root
    objectName: "gameGrid"

    property var games: null          // Pegasus collection.games item model
    property string shortName: ""
    property string fontFamily: "monospace"

    // Crystal index epoch from GameLibrary: when the asynchronous index
    // (re)load completes, tiles re-resolve their cover art.
    property int artEpoch: 0

    property int currentIndex: 0

    readonly property int count: {
        if (!root.games) return 0
        var c = root.games.count
        return (typeof c === "number" && c > 0) ? c : 0
    }
    readonly property int page: Math.floor(root.currentIndex / T.libPageSize)
    readonly property int pageCount: Math.ceil(root.count / T.libPageSize)
    readonly property int pageStart: root.page * T.libPageSize

    function gameAt(i) {
        if (!root.games || i < 0 || i >= root.count) return null
        try { return root.games.get(i) } catch (e) { return null }
        return null
    }

    readonly property var currentGame: gameAt(root.currentIndex)

    function reset() { root.currentIndex = 0 }

    function setIndex(i) {
        if (root.count === 0) { root.currentIndex = 0; return }
        if (i < 0) i = 0
        if (i >= root.count) i = root.count - 1
        root.currentIndex = i
    }

    function moveLeft() {
        if (root.count === 0 || root.currentIndex <= 0) return
        setIndex(root.currentIndex - 1)
    }

    function moveRight() {
        if (root.count === 0) return
        setIndex(root.currentIndex + 1)
    }

    function moveUp() {
        if (root.count === 0) return
        var target = root.currentIndex - T.libCols
        if (target < 0) return
        root.currentIndex = target
    }

    function moveDown() {
        if (root.count === 0) return
        var target = root.currentIndex + T.libCols
        if (target >= root.count) return
        root.currentIndex = target
    }

    Repeater {
        model: T.libPageSize
        GameTile {
            x: T.libTileX(index % T.libCols)
            y: T.libTileY(Math.floor(index / T.libCols))
            selected: root.pageStart + index === root.currentIndex
            game: root.gameAt(root.pageStart + index)
            shortName: root.shortName
            fontFamily: root.fontFamily
            artEpoch: root.artEpoch
            visible: root.gameAt(root.pageStart + index) !== null
        }
    }
}
