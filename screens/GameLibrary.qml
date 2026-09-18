import QtQuick 2.12
import "../components"
import "../components/CrystalTheme.js" as T
import "../components/PhysicalMedia"
import "../components/PhysicalMedia/MediaTemplates.js" as MediaTemplates

// Library hero: selected-game detail panel on the left, 3x3 box-art
// grid in a framed panel on the right. A launches the selected game
// via game.launch(); B returns home.
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
    // Available only for the bespoke GBA/PS2 compositions and only when
    // Pegasus exposes the Details key; every other system keeps the
    // production library untouched. The platform check lives in
    // MediaTemplates — this file never names a system.
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
        // open() reports success: only take input ownership when the
        // overlay actually opened, so a failed open can never trap keys.
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

    // ---- left: selected-game detail hero ----
    LibraryHero {
        id: hero
        x: 0; y: 0
        width: 740; height: 844
        collection: root.collection
        game: grid.currentGame
        shortName: root.shortName
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
        metaEpoch: root.metaEpoch
        visible: !root.isEmpty
    }

    // ---- right: framed grid panel ----
    Item {
        id: panel
        x: T.panelX; y: T.panelY
        width: T.panelW; height: T.panelH
        visible: !root.isEmpty

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: CrystalColors.gridTile
            border.width: 2
            border.color: CrystalColors.gridBorder
        }

        // open corner brackets over the panel corners
        Item {  // top-left
            x: -7; y: -7; width: 32; height: 32
            Rectangle { x: 0; y: 0; width: 32; height: 5; color: CrystalColors.frame }
            Rectangle { x: 0; y: 0; width: 5; height: 32; color: CrystalColors.frame }
        }
        Item {  // top-right
            x: parent.width - 25; y: -7; width: 32; height: 32
            Rectangle { x: 0; y: 0; width: 32; height: 5; color: CrystalColors.frame }
            Rectangle { x: 27; y: 0; width: 5; height: 32; color: CrystalColors.frame }
        }
        Item {  // bottom-left
            x: -7; y: parent.height - 25; width: 32; height: 32
            Rectangle { x: 0; y: 27; width: 32; height: 5; color: CrystalColors.frame }
            Rectangle { x: 0; y: 0; width: 5; height: 32; color: CrystalColors.frame }
        }
        Item {  // bottom-right
            x: parent.width - 25; y: parent.height - 25; width: 32; height: 32
            Rectangle { x: 0; y: 27; width: 32; height: 5; color: CrystalColors.frame }
            Rectangle { x: 27; y: 0; width: 5; height: 32; color: CrystalColors.frame }
        }

        // top row: L1 / SORT / FILTER / R1
        // L1 cycles sort mode, R1 cycles filter mode (both functional).
        Rectangle {  // L1 keycap
            x: 25; y: T.panelTopY - T.panelY
            width: 46; height: 28
            radius: 6
            color: CrystalColors.cream
            border.width: 1
            border.color: CrystalColors.frameDim
            Text {
                anchors.centerIn: parent
                font.family: root.fontFamily
                font.pixelSize: 16
                font.bold: true
                color: CrystalColors.creamInk
                text: "L1"
            }
        }
        Rectangle {  // R1 keycap
            x: parent.width - 25 - 46; y: T.panelTopY - T.panelY
            width: 46; height: 28
            radius: 6
            color: CrystalColors.cream
            border.width: 1
            border.color: CrystalColors.frameDim
            Text {
                anchors.centerIn: parent
                font.family: root.fontFamily
                font.pixelSize: 16
                font.bold: true
                color: CrystalColors.creamInk
                text: "R1"
            }
        }
        Text {
            x: 85
            y: T.panelTopY - T.panelY + 1
            font.family: root.fontFamily
            font.pixelSize: 18
            font.letterSpacing: 2
            color: CrystalColors.mutedBlue
            text: "SORT: " + root.sortLabel
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 85
            y: T.panelTopY - T.panelY + 1
            font.family: root.fontFamily
            font.pixelSize: 18
            font.letterSpacing: 2
            color: CrystalColors.mutedBlue
            text: "FILTER: " + root.filterLabel
        }

        // page indicator
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: T.pageY - T.panelY
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 2
            color: CrystalColors.mutedBlue
            text: "\u25C0  " + (grid.page + 1) + " / " + grid.pageCount + "  \u25B6"
        }
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

    // Physical-media Inspect overlay. The grid selection underneath never
    // moves, so closing returns to the exact same tile; launching goes
    // through the unchanged launchCurrent() path below.
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
            font.pixelSize: 40
            font.letterSpacing: 4
            color: CrystalColors.ink
            text: "NO GAMES FOUND"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: T.fontFooterPx
            font.letterSpacing: 2
            color: CrystalColors.tileInk
            text: "ADD GAMES TO THIS COLLECTION"
        }
    }
}
