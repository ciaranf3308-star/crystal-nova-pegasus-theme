import QtQuick 2.12
import "../components"
import "../components/CrystalTheme.js" as T
import "../components/PhysicalMedia"
import "../components/PhysicalMedia/MediaTemplates.js" as MediaTemplates

// Library: selected-game hero on the left (55%), 3x3 box-art grid on the
// right (37%). Rebuilt 2026-09-19: no framed panel, no heavy chrome —
// spacing, scale, and typography create the hierarchy.
// A launches the selected game via game.launch(); B returns home.
// Y (Details) opens the physical-media Inspect view on GBA/PS2 systems.
Item {
    id: root

    property var collection: null
    property string shortName: ""
    property string fontFamily: "monospace"

    // Bumped whenever the crystal index finishes (re)loading. Tile art
    // bindings depend on it, so covers upgrade without blocking first
    // paint. The refresh itself is triggered by theme.qml's enterSystem().
    property int artEpoch: 0
    function bumpArtEpoch() { artEpoch++ }
    // Bumped when a selected game's manifest metadata arrives.
    property int metaEpoch: 0
    function bumpMetaEpoch() { metaEpoch++ }

    // navigation / launch surface used by theme.qml
    function moveLeft()  { grid.moveLeft() }
    function moveRight() { grid.moveRight() }
    function moveUp()    { grid.moveUp() }
    function moveDown()  { grid.moveDown() }
    function reset()     { grid.reset() }
    function setGameIndex(i) { grid.setIndex(i) }

    // ---- sort / filter (L1/R1) --------------------------------------------
    // L1 cycles sort mode, R1 cycles filter mode. Both are real: the
    // grid rebuilds its index map when these change.
    property int sortMode: 0    // 0=Name A-Z, 1=Name Z-A
    property int filterMode: 0  // 0=All, 1=Favorites
    readonly property var sortLabels: ["OFF", "A-Z", "Z-A"]
    readonly property var filterLabels: ["ALL", "FAVS"]
    readonly property string sortLabel: sortLabels[sortMode] || "OFF"
    readonly property string filterLabel: filterLabels[filterMode] || "ALL"
    function cycleSort() {
        sortMode = (sortMode + 1) % sortLabels.length
        grid.reset()
    }
    function cycleFilter() {
        filterMode = (filterMode + 1) % filterLabels.length
        grid.reset()
    }

    // ---- physical-media Inspect -------------------------------------------
    readonly property bool inspectAvailable: {
        if (root.isEmpty) return false
        if (typeof api === "undefined" || !api.keys) return false
        if (typeof api.keys.isDetails !== "function") return false
        return MediaTemplates.supportsInspect(root.shortName)
    }
    property bool inspecting: false

    function tileRectFor(i) {
        var ps = Math.floor(i / T.libPageSize) * T.libPageSize
        var slot = i - ps
        return {
            x: T.libTileX(slot % T.libCols),
            y: T.libTileY(Math.floor(slot / T.libCols)),
            w: T.gtileArtW,
            h: T.gtileArtH + T.gtileTitleH
        }
    }

    function openInspect() {
        if (!inspectAvailable || root.inspecting) return
        if (inspectView.open(grid.currentGame, root.shortName,
                             tileRectFor(grid.currentIndex))) {
            root.inspecting = true
        }
    }
    function closeInspect()  { inspectView.beginClose() }
    function inspectLeft()   { inspectView.prevView() }
    function inspectRight()  { inspectView.nextView() }
    function inspectLaunch() { inspectView.launch() }

    // The real Pegasus launch mechanism: the game's own launch() method.
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

    // ---- left: selected-game hero (55%) ----
    LibraryHero {
        id: hero
        x: T.heroLeftX; y: 0
        width: T.heroLeftW; height: 868
        collection: root.collection
        game: grid.currentGame
        shortName: root.shortName
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
        metaEpoch: root.metaEpoch
        visible: !root.isEmpty
    }

    // ---- right: grid utilities (subtle, no panel chrome) ----
    // Sort/filter/page live as quiet text above the grid — utilities,
    // not the main content.
    Item {
        x: T.libGridX; y: 118
        width: T.panelW; height: 36
        visible: !root.isEmpty

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 15
            font.letterSpacing: 2
            color: CrystalColors.mutedBlue
            opacity: 0.75
            text: "SORT " + root.sortLabel
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 15
            font.letterSpacing: 2
            color: CrystalColors.mutedBlue
            opacity: 0.75
            text: "FILTER " + root.filterLabel
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 15
            font.letterSpacing: 2
            color: CrystalColors.mutedBlue
            opacity: 0.6
            text: (grid.page + 1) + " / " + grid.pageCount
            visible: grid.pageCount > 1
        }
    }

    // L1/R1 hints — only if shoulder buttons are actually wired.
    // (Kept minimal; remove if not functional on Nova.)
    Text {
        x: T.libGridX; y: 846
        font.family: root.fontFamily
        font.pixelSize: 13
        font.letterSpacing: 2
        color: CrystalColors.mutedBlue
        opacity: 0.5
        text: "L1 SORT · R1 FILTER"
        visible: !root.isEmpty
    }

    GameGrid {
        id: grid
        objectName: "gameGrid"
        anchors.fill: parent
        games: root.collection ? root.collection.games : null
        shortName: root.shortName
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
        sortMode: root.sortMode
        filterMode: root.filterMode
        visible: !root.isEmpty
    }

    // Physical-media Inspect overlay.
    PhysicalInspect {
        id: inspectView
        objectName: "physicalInspect"
        anchors.fill: parent
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
        onClosed: root.inspecting = false
        onLaunchRequested: {
            if (!root.launchCurrent()) inspectView.resetLaunch()
        }
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
            font.pixelSize: 36
            font.letterSpacing: 4
            color: CrystalColors.ink
            text: "NO GAMES FOUND"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 2
            color: CrystalColors.tileInk
            text: "ADD GAMES TO THIS COLLECTION"
        }
    }
}
