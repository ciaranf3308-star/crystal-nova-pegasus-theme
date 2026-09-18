import QtQuick 2.12
import "CrystalTheme.js" as T

// 3x3 box-art grid with clean paging. Renders only the current page
// (9 tiles); D-pad navigation crosses page boundaries. Never lands on
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

    // Sort/filter state from GameLibrary (L1/R1). The grid builds a
    // display index map so sort/filter are real, not just labels.
    // sortMode: 0=Original (Pegasus order), 1=Name A-Z, 2=Name Z-A
    property int sortMode: 0
    property int filterMode: 0  // 0=All, 1=Favorites

    // Maps display position -> model index, applying filter then sort.
    // Rebuilt when games, sortMode, or filterMode change.
    readonly property var indexMap: {
        // Depend on the inputs so the binding re-evaluates.
        var sm = root.sortMode, fm = root.filterMode, g = root.games;
        if (!g) return [];
        var n = 0;
        try { n = g.count; } catch (e) { return []; }
        if (typeof n !== "number" || n <= 0) return [];
        var indices = [];
        for (var i = 0; i < n; i++) {
            var game = null;
            try { game = g.get(i); } catch (e) { continue; }
            if (!game) continue;
            if (fm === 1) {
                var fav = false;
                try { fav = !!game.favorite; } catch (e) {}
                if (!fav) continue;
            }
            indices.push(i);
        }
        // Sort by title (locale-aware). Mode 0 keeps Pegasus order.
        if (sm === 1 || sm === 2) {
            var desc = (sm === 2);
            indices.sort(function(a, b) {
                var ta = "", tb = "";
                try { ta = (g.get(a).title || "").toString(); } catch (e) {}
                try { tb = (g.get(b).title || "").toString(); } catch (e) {}
                var c = ta.localeCompare(tb);
                return desc ? -c : c;
            });
        }
        return indices;
    }

    property int currentIndex: 0

    readonly property int count: root.indexMap.length
    readonly property int page: Math.floor(root.currentIndex / T.libPageSize)
    readonly property int pageCount: Math.ceil(root.count / T.libPageSize)
    readonly property int pageStart: root.page * T.libPageSize

    function gameAt(i) {
        if (i < 0 || i >= root.indexMap.length) return null
        var modelIdx = root.indexMap[i]
        try { return root.games.get(modelIdx) } catch (e) { return null }
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
        LibraryGameTile {
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
