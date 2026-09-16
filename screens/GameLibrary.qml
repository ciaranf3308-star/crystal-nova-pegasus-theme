import QtQuick 2.12
import "../components"
import "../components/CrystalTheme.js" as T
import "../components/PhysicalMedia"
import "../components/PhysicalMedia/MediaTemplates.js" as MediaTemplates

// Phase 2: per-system game library. 4x2 box-art grid driven by the real
// Pegasus collection model — no demo content in production.
// A launches the selected game via game.launch(); B returns home.
// Y (Details) opens the physical-media Inspect view on GBA/PS2 systems.
Item {
    id: root

    property var collection: null
    property string shortName: ""
    property string fontFamily: "monospace"

    // Bumped whenever the crystal index finishes (re)loading. Tile art
    // bindings depend on it, so covers upgrade without blocking first
    // paint. The refresh itself is triggered by theme.qml's enterSystem();
    // the one-shot onCompleted refresh that used to live here fired before
    // CrystalAssets.configure() and was a guaranteed no-op.
    property int artEpoch: 0
    function bumpArtEpoch() { artEpoch++ }

    // navigation / launch surface used by theme.qml
    function moveLeft()  { grid.moveLeft() }
    function moveRight() { grid.moveRight() }
    function moveUp()    { grid.moveUp() }
    function moveDown()  { grid.moveDown() }
    function reset()     { grid.reset() }
    function setGameIndex(i) { grid.setIndex(i) }

    // ---- physical-media Inspect -------------------------------------------
    // Available only for the GBA/PS2 families and only when Pegasus
    // exposes the Details key; every other system keeps the production
    // library untouched. The platform check lives in MediaTemplates —
    // this file never names a system.
    readonly property bool inspectAvailable: {
        if (root.isEmpty) return false
        if (typeof api === "undefined" || !api.keys) return false
        if (typeof api.keys.isDetails !== "function") return false
        return MediaTemplates.supportsPhysical(root.shortName)
    }
    property bool inspecting: false

    function tileRectFor(i) {
        var ps = Math.floor(i / T.libPageSize) * T.libPageSize
        var slot = i - ps
        return {
            x: T.libTileX(slot % T.libCols),
            y: T.libTileY(Math.floor(slot / T.libCols)),
            w: T.libCoverW,
            h: T.libCoverH
        }
    }

    function openInspect() {
        if (!inspectAvailable || root.inspecting) return
        root.inspecting = true
        inspectView.open(grid.currentGame, root.shortName,
                         tileRectFor(grid.currentIndex))
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

    GameGrid {
        id: grid
        objectName: "gameGrid"
        anchors.fill: parent
        games: root.collection ? root.collection.games : null
        shortName: root.shortName
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
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
