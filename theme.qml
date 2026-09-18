import QtQuick 2.12
import "components"
import "components/CrystalAssets.js" as CrystalAssets
import "screens"

// Crystal Nova -- Phase 1: home / system-selection screen for the
// Retroid Pocket Nova (1280x960, 4:3).
//
// Pegasus loads this file with input focus; D-pad / A / B / L1 / R1 are
// handled below through api.keys (user-remappable in Pegasus settings).
// The grid is populated dynamically from api.collections -- nothing is
// hard-coded.
FocusScope {
    id: root
    focus: true

    // "home" | "system"
    property string screen: "home"

    FontLoader { id: departure; source: "fonts/DepartureMono-Regular.otf" }
    readonly property string fontFamily: departure.status === FontLoader.Ready
                                         ? departure.name : "monospace"

    Rectangle {
        anchors.fill: parent
        color: CrystalColors.background
    }

    Header {
        id: header
        objectName: "crystalHeader" // test hook: lets the preview harness fix the clock
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        fontFamily: root.fontFamily
        title: "CRYSTAL"
        subtitle: root.screen === "system" ? "PLAY MORE GAMES" : ""
    }

    FooterHints {
        id: footer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        fontFamily: root.fontFamily
        page: grid.page
        pageCount: grid.pageCount
        visible: root.screen === "home"
    }

    LibraryFooter {
        id: libFooter
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        fontFamily: root.fontFamily
        showPlay: !sysScreen.isEmpty
        showInspect: sysScreen.inspectAvailable
        visible: root.screen === "system"
    }

    SystemGrid {
        id: grid
        objectName: "systemGrid" // test hook: lets the preview harness read grid state
        anchors.fill: parent
        fontFamily: root.fontFamily
        visible: root.screen === "home" && api.collections.count > 0
    }

    // Shown when Pegasus has no collections (Pegasus normally shows its
    // own empty-library screen before the theme loads; this is a fallback).
    Text {
        anchors.centerIn: parent
        font.family: root.fontFamily
        font.pixelSize: 26
        font.letterSpacing: 2
        color: CrystalColors.dimText
        visible: root.screen === "home" && api.collections.count === 0
        text: "NO SYSTEMS FOUND"
    }

    Toast {
        id: toast
        anchors.bottom: footer.top
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        fontFamily: root.fontFamily
    }

    GameLibrary {
        id: sysScreen
        objectName: "gameLibrary" // test hook: lets the preview harness read library state
        anchors.fill: parent
        fontFamily: root.fontFamily
        visible: root.screen === "system"
        onCollectionChanged: reset()
    }

    function enterSystem(restoreGame) {
        var coll = grid.currentCollection()
        if (!coll) return
        // Re-read the scraper index: artwork scraped in the Manager while
        // Pegasus is open appears without a theme restart. The fetch is
        // asynchronous — the grid paints immediately with Pegasus fallback
        // art and tiles upgrade when the parse completes (see
        // GameLibrary.artEpoch). Unchanged index.json is skipped cheaply.
        CrystalAssets.refresh()
        var sn = coll.shortName || coll.name || ""
        api.memory.set("crystalNova.lastSystem", sn)
        api.memory.set("crystalNova.lastScreen", "system")
        sysScreen.collection = coll
        sysScreen.shortName = sn
        sysScreen.reset()
        if (restoreGame === true && api.memory.has("crystalNova.lastGame")) {
            var gi = api.memory.get("crystalNova.lastGame")
            if (typeof gi === "number") sysScreen.setGameIndex(gi)
        }
        root.screen = "system"
    }

    function leaveSystem() {
        api.memory.set("crystalNova.lastScreen", "home")
        root.screen = "home"
    }

    // User colors: the Manager app's APPEARANCE screen writes
    // <themes-root>/crystal-user-colors.json (next to the media bridge,
    // so theme updates never touch it):
    //   {"version":1,"background":"#0a1929","accent":"#7ba7d9",
    //    "cream":"#f0ebdc","joystick":"#ffc93c","updated":<epochSeconds>}
    // All four keys are optional; only present + valid (^#[0-9a-fA-F]{6}$)
    // values are applied to the CrystalColors singleton. A missing,
    // malformed, or invalid file silently keeps theme defaults — a
    // colors problem can never break rendering. NOTE: a cold Pegasus
    // restart picks up color changes (the file is read once at startup).
    function loadUserColors() {
        var url = Qt.resolvedUrl("../crystal-user-colors.json")
        if (typeof XMLHttpRequest === "undefined") return
        try {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", url, true)
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return
                try {
                    var ok = (xhr.status === 200 || xhr.status === 0)
                    if (!ok) return
                    var doc = JSON.parse(xhr.responseText || "")
                    if (!doc || doc.version !== 1) return
                    var hexRe = /^#[0-9a-fA-F]{6}$/
                    var keys = ["background", "accent", "cream", "joystick"]
                    for (var i = 0; i < keys.length; i++) {
                        var k = keys[i]
                        var v = doc[k]
                        if (typeof v === "string" && hexRe.test(v)) {
                            CrystalColors[k] = v
                            CrystalColors[k + "Custom"] = true
                        }
                    }
                } catch (e) { /* silent fallback to theme defaults */ }
            }
            xhr.send()
        } catch (e) { /* silent fallback to theme defaults */ }
    }

    Component.onCompleted: {
        // User-overridable palette (see loadUserColors): applied when the
        // file is present and valid; otherwise the theme renders its
        // measured defaults.
        loadUserColors()
        // Scraper asset bridge: prefer the Manager-written crystal-media-bridge.json
        // (themes root; canonical external-media path) when it is present and
        // valid, else fall back to the legacy sibling directory
        // crystal-nova-data/. Both live next to the installed theme, never
        // inside it, so theme updates and rollback cannot touch scraper data.
        CrystalAssets.configureFromBridge(
            Qt.resolvedUrl("../crystal-media-bridge.json"),
            Qt.resolvedUrl("../crystal-nova-data/"))
        // SD MEDIA PROBE (test only): when the Manager has written
        // crystal-esde-probe.json into the themes root, show the
        // diagnostic overlay proving whether QML can render a file://
        // image straight from the SD card.
        CrystalAssets.loadProbe(Qt.resolvedUrl("../crystal-esde-probe.json"))
        CrystalAssets.setProbeChangedHandler(function() { probeOverlay.refreshProbe() })
        // Whenever the asynchronous index (re)load completes, bump the
        // library's art epoch so tile cover bindings re-evaluate.
        CrystalAssets.setIndexChangedHandler(function() { sysScreen.bumpArtEpoch() })
        // Whenever a selected game's manifest metadata arrives, bump the
        // meta epoch so the hero's meta line / description re-evaluate.
        CrystalAssets.setMetaChangedHandler(function() { sysScreen.bumpMetaEpoch() })
        // Restore the last selected system across restarts. Pegasus reloads
        // the theme after a game exits; if we were inside a library, go
        // straight back there with the game selection intact.
        var lastScreen = api.memory.has("crystalNova.lastScreen")
            ? api.memory.get("crystalNova.lastScreen") : "home"
        if (api.memory.has("crystalNova.lastSystem")) {
            var want = api.memory.get("crystalNova.lastSystem")
            for (var i = 0; i < api.collections.count; i++) {
                var c = api.collections.get(i)
                if (c && (c.shortName === want || c.name === want)) {
                    grid.jumpTo(i)
                    break
                }
            }
        }
        if (lastScreen === "system") {
            enterSystem(true)
        }
    }

    Keys.onPressed: {
        // SD MEDIA PROBE overlay (test only): while it is up it owns
        // every key — A or B dismisses it, everything else is swallowed
        // so the underlying screens cannot move underneath.
        if (probeOverlay.visible) {
            if (!event.isAutoRepeat &&
                (api.keys.isAccept(event) || api.keys.isCancel(event))) {
                event.accepted = true
                probeOverlay.dismissed = true
                probeOverlay.visible = false
            } else {
                event.accepted = true
            }
            return
        }
        if (root.screen === "system") {
            // Physical-media Inspect owns the keys while open: the grid
            // underneath never moves, so B returns to the same tile.
            if (sysScreen.inspecting) {
                if (event.key === Qt.Key_Left)       { event.accepted = true; sysScreen.inspectLeft() }
                else if (event.key === Qt.Key_Right) { event.accepted = true; sysScreen.inspectRight() }
                else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                    event.accepted = true
                    sysScreen.inspectLaunch()
                }
                else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                    event.accepted = true
                    sysScreen.closeInspect()
                }
                return
            }
            // Directional input uses standard QML KeyEvent values — real
            // Pegasus does NOT expose api.keys.isLeft/isRight/isUp/isDown.
            if (event.key === Qt.Key_Left)       { event.accepted = true; sysScreen.moveLeft() }
            else if (event.key === Qt.Key_Right) { event.accepted = true; sysScreen.moveRight() }
            else if (event.key === Qt.Key_Up)    { event.accepted = true; sysScreen.moveUp() }
            else if (event.key === Qt.Key_Down)  { event.accepted = true; sysScreen.moveDown() }
            else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true
                sysScreen.launchCurrent()
            }
            else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                event.accepted = true
                leaveSystem()
            }
            // Details/Inspect: GBA/PS2 only (GameLibrary.inspectAvailable
            // already guards the key's existence and the empty library).
            else if (!event.isAutoRepeat && sysScreen.inspectAvailable
                     && api.keys.isDetails(event)) {
                event.accepted = true
                sysScreen.openInspect()
            }
            // L1/R1: cycle sort / filter. Both are real — the grid
            // rebuilds its display index map on change.
            else if (!event.isAutoRepeat && api.keys.isPrevPage(event)) {
                event.accepted = true
                sysScreen.cycleSort()
            }
            else if (!event.isAutoRepeat && api.keys.isNextPage(event)) {
                event.accepted = true
                sysScreen.cycleFilter()
            }
            return
        }

        // home screen
        // Directional input uses standard QML KeyEvent values — real Pegasus
        // does NOT expose api.keys.isLeft/isRight/isUp/isDown.
        if (event.key === Qt.Key_Left)       { event.accepted = true; grid.moveLeft() }
        else if (event.key === Qt.Key_Right) { event.accepted = true; grid.moveRight() }
        else if (event.key === Qt.Key_Up)    { event.accepted = true; grid.moveUp() }
        else if (event.key === Qt.Key_Down)  { event.accepted = true; grid.moveDown() }
        else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
            event.accepted = true
            enterSystem()
        }
        else if (!event.isAutoRepeat && api.keys.isPrevPage(event)) {
            event.accepted = true
            toast.show("RECENT -- PHASE 2")
        }
        else if (!event.isAutoRepeat && api.keys.isNextPage(event)) {
            event.accepted = true
            toast.show("FAVOURITES -- PHASE 2")
        }
        // NOTE: isCancel is deliberately NOT accepted on the home screen so
        // Pegasus can open its own main menu with B.
    }

    // ------------------------------------------------------------------
    // SD MEDIA PROBE overlay (TEST ONLY — delete after the render test).
    //
    // Visible only when the Manager has written crystal-esde-probe.json
    // into the themes root. Shows the exact diagnostic the Manager
    // produced, the test image itself (proving whether QML can render
    // file:// URLs straight from the SD card), and the result line the
    // user sends back. A or B dismisses it.
    // ------------------------------------------------------------------
    Item {
        id: probeOverlay
        anchors.fill: parent
        z: 1000
        visible: false
        property bool dismissed: false
        property string sdRoot: ""
        property string testAsset: ""
        property string themeUrl: ""

        function refreshProbe() {
            var info = null
            try { info = CrystalAssets.probeInfo() } catch (e) { info = null }
            if (info && !dismissed) {
                sdRoot = info.sdMediaRoot
                testAsset = info.testAsset
                themeUrl = info.themeUrl
                visible = true
            } else {
                visible = false
            }
        }

        Rectangle {
            anchors.fill: parent
            color: CrystalColors.black
            opacity: 0.9
        }

        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 960)
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SD MEDIA PROBE — TEST ONLY"
                color: CrystalColors.joystick
                font.pixelSize: 36
                font.bold: true
                font.family: root.fontFamily
            }
            Text {
                width: parent.width
                text: "External SD media root:\n" + probeOverlay.sdRoot
                color: CrystalColors.white
                font.pixelSize: 17
                font.family: root.fontFamily
                wrapMode: Text.WrapAnywhere
            }
            Text {
                width: parent.width
                text: "Test asset:\n" + probeOverlay.testAsset
                color: CrystalColors.white
                font.pixelSize: 17
                font.family: root.fontFamily
                wrapMode: Text.WrapAnywhere
            }
            Text {
                width: parent.width
                text: "Theme URL:\n" + probeOverlay.themeUrl
                color: CrystalColors.probeLink
                font.pixelSize: 17
                font.family: root.fontFamily
                wrapMode: Text.WrapAnywhere
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 480
                height: 360
                color: CrystalColors.probePanel
                border.color: CrystalColors.joystick
                border.width: 2
                Image {
                    id: probeImage
                    anchors.fill: parent
                    anchors.margins: 4
                    // Bind the overlay's own property, not a JS-module call:
                    // QML cannot track dependencies inside CrystalAssets, so
                    // probeImageUrl() would evaluate once (empty) and never
                    // update. themeUrl is set by refreshProbe() before the
                    // overlay becomes visible.
                    source: probeOverlay.themeUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    text: "NO IMAGE"
                    color: CrystalColors.bad
                    font.pixelSize: 28
                    font.bold: true
                    font.family: root.fontFamily
                    visible: probeImage.status !== Image.Ready
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Result: pending device validation — DOES THE COVER SHOW ABOVE?"
                color: CrystalColors.joystick
                font.pixelSize: 19
                font.bold: true
                font.family: root.fontFamily
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PRESS A OR B TO DISMISS"
                color: CrystalColors.probeDim
                font.pixelSize: 16
                font.family: root.fontFamily
            }
        }
    }
}
