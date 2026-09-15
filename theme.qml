import QtQuick 2.12
import "components"
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
        color: "#0a1929"
    }

    Header {
        id: header
        objectName: "crystalHeader" // test hook: lets the preview harness fix the clock
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        fontFamily: root.fontFamily
        title: root.screen === "system"
               ? "CRYSTAL / " + (sysScreen.shortName || "").toUpperCase()
               : "CRYSTAL"
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
        page: sysScreen.page
        pageCount: sysScreen.pageCount
        showPlay: !sysScreen.isEmpty
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
        color: "#8ba3b5"
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

    Component.onCompleted: {
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
        if (root.screen === "system") {
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
}
