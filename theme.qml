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

    FontLoader { id: monoRegular; source: "assets/fonts/DejaVuSansMono.ttf" }
    FontLoader { id: monoBold; source: "assets/fonts/DejaVuSansMono-Bold.ttf" }
    readonly property string fontFamily: monoRegular.status === FontLoader.Ready
                                         ? monoRegular.name : "monospace"

    Rectangle {
        anchors.fill: parent
        color: "#262f3b"
    }

    Header {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        fontFamily: root.fontFamily
    }

    FooterHints {
        id: footer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        fontFamily: root.fontFamily
        page: grid.page
        pageCount: grid.pageCount
    }

    SystemGrid {
        id: grid
        objectName: "systemGrid" // test hook: lets the preview harness read grid state
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 88
        anchors.rightMargin: 88
        anchors.topMargin: 36
        anchors.bottomMargin: 36
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

    SystemPlaceholder {
        id: sysScreen
        anchors.fill: parent
        fontFamily: root.fontFamily
        visible: root.screen === "system"
    }

    function enterSystem() {
        var coll = grid.currentCollection()
        if (!coll) return
        api.memory.set("crystalNova.lastSystem", coll.shortName || coll.name || "")
        sysScreen.collection = coll
        root.screen = "system"
    }

    function leaveSystem() {
        root.screen = "home"
    }

    Component.onCompleted: {
        // Restore the last selected system across restarts.
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
    }

    Keys.onPressed: {
        if (root.screen === "system") {
            if (!event.isAutoRepeat && api.keys.isCancel(event)) {
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
