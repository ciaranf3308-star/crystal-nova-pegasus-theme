import QtQuick 2.12
import ".."
import "../CrystalTheme.js" as T
import "../CrystalAssets.js" as CrystalAssets
import "MediaTemplates.js" as MT

// PhysicalInspect — the focused physical-media view for one game.
//
// Still unmistakably Crystal: dark navy dim over the live library,
// a tileFill panel in the open-corner frame language, Departure Mono,
// the footer keycap prompt language. Only the object itself is
// richly rendered.
//
// Controller: LEFT/RIGHT cycles views (PS2: FRONT/SPINE/BACK/OPEN —
// opening is a view, no extra button to discover; GBA: FRONT/BACK),
// A launches (tactile transition, then the existing game.launch()
// path), B returns to the exact same grid tile.
//
// Grid -> inspect reads as "brought forward": the object animates
// from the selected tile's rect to its panel slot; closing reverses
// it. The grid selection underneath never moves.
Item {
    id: root
    visible: false

    property string fontFamily: "monospace"
    property int artEpoch: 0

    signal closed()
    signal launchRequested()

    property var game: null
    property string shortName: ""
    readonly property string family: MT.familyFor(root.shortName)
    readonly property var views: MT.inspectViews(root.family)
    property int viewIndex: 0
    readonly property string view: root.views.length > 0
                                     ? root.views[root.viewIndex % root.views.length] : "front"
    property string sourceLine: ""
    property bool busy: false        // transition running: ignore keys
    property bool launching: false
    property bool liftStarted: false
    property bool slotGraphicOn: false

    // panel geometry (derived from the theme's 1280x960 canvas)
    readonly property int panelX: 140
    readonly property int panelY: 110
    readonly property int panelW: 1000
    readonly property int panelH: 700
    readonly property int slotX: 180
    readonly property int slotY: 220
    readonly property int slotW: 540
    readonly property int slotH: 500

    function setView(v) {
        var i = root.views.indexOf(v)
        root.viewIndex = i >= 0 ? i : 0
    }
    function prevView() {
        if (root.busy || root.launching || root.views.length === 0) return
        root.viewIndex = (root.viewIndex - 1 + root.views.length) % root.views.length
    }
    function nextView() {
        if (root.busy || root.launching || root.views.length === 0) return
        root.viewIndex = (root.viewIndex + 1) % root.views.length
    }

    // Returns true when Inspect actually opened. Never throws and never
    // leaves input ownership half-taken: any failure resets to
    // hidden/idle and reports false, so the caller can keep the grid
    // in charge of the keys.
    function open(game, shortName, fromRect) {
        if (root.visible) return true
        try {
            if (!game || !MT.supportsPhysical(shortName || "")) return false
            root.game = game
            root.shortName = shortName || ""
            root.returnRect = fromRect
            root.viewIndex = 0
            root.launching = false
            root.liftStarted = false
            root.slotGraphicOn = false
            root.sourceLine = artworkSource()
            // start the object exactly on the selected tile, then bring it
            // forward into the panel slot
            objectWrap.x = fromRect.x
            objectWrap.y = fromRect.y
            objectWrap.width = fromRect.w
            objectWrap.height = fromRect.h
            root.visible = true
            root.busy = true
            dim.opacity = 0.88
            panel.scale = 0.97
            panelIn.start()
            panelZoomIn.start()
            wrapX.to = root.slotX; wrapY.to = root.slotY
            wrapW.to = root.slotW; wrapH.to = root.slotH
            wrapX.start(); wrapY.start(); wrapW.start(); wrapH.start()
            armWatchdog("open")
            return true
        } catch (e) {
            hardReset()
            return false
        }
    }

    function artworkSource() {
        try {
            var d = CrystalAssets.details(root.game, root.shortName)
            for (var k in d) { if (d[k]) return "SCRAPED" }
            var g = root.game
            if (g && g.assets && (g.assets.boxFront || g.assets.poster))
                return "SCRAPED"
        } catch (e) { /* fall through */ }
        return "GENERATED"
    }

    // B must always escape: when a transition is stuck (or a launch is
    // mid-flight), jump-cut closed instead of waiting on an animation
    // that may never finish. The animated path is only for the healthy
    // idle case, and it is watchdog-backed too.
    function beginClose() {
        if (!root.visible) return
        if (root.busy || root.launching) {
            resetLaunch()
            hardClose()
            return
        }
        root.busy = true
        armWatchdog("close")
        // return the object to its tile, then hide
        wrapX.to = returnRect.x; wrapY.to = returnRect.y
        wrapW.to = returnRect.w; wrapH.to = returnRect.h
        wrapX.start(); wrapY.start(); wrapW.start(); wrapH.start()
        dim.opacity = 0
        panelOut.start()
    }

    property var returnRect: ({ x: 0, y: 0, w: 10, h: 10 })

    function launch() {
        if (root.launching || root.busy) return
        root.launching = true
        if (root.family === "ps2" && root.view !== "open") {
            setView("open")            // hinge swings open first
            launchTimer.interval = 520
        } else {
            beginLift()
            launchTimer.interval = 540
        }
        launchTimer.start()
    }

    function beginLift() {
        root.liftStarted = true
        if (root.family === "gba") {
            root.slotGraphicOn = true
            phys.inserting = true
        } else {
            phys.lifting = true
        }
    }

    function resetLaunch() {
        root.launching = false
        root.liftStarted = false
        root.slotGraphicOn = false
        phys.inserting = false
        phys.lifting = false
        launchTimer.stop()
    }

    Timer {
        id: launchTimer
        onTriggered: {
            if (!root.liftStarted) {
                beginLift()
                interval = 540
                start()
            } else {
                root.launchRequested()
            }
        }
    }

    // ---- input-safety net ---------------------------------------------------
    // No animation-completion callback is the single point of failure for
    // input recovery: every transition arms the watchdog below, and any
    // path that cannot afford to wait (B during a stuck transition, an
    // exception inside open()) jump-cuts to a known-good state instead.
    property string pendingTransition: ""

    function armWatchdog(which) {
        root.pendingTransition = which
        busyWatchdog.restart()
    }

    function stopAllMotion() {
        busyWatchdog.stop()
        launchTimer.stop()
        wrapX.stop(); wrapY.stop(); wrapW.stop(); wrapH.stop()
        panelIn.stop(); panelOut.stop(); panelZoomIn.stop()
        root.pendingTransition = ""
    }

    // Snap to the fully-open state: the watchdog path for a stuck open.
    function forceSettleOpen() {
        stopAllMotion()
        objectWrap.x = root.slotX; objectWrap.y = root.slotY
        objectWrap.width = root.slotW; objectWrap.height = root.slotH
        dim.opacity = 0.88
        panel.opacity = 1
        panel.scale = 1
        root.busy = false
    }

    // Snap fully shut and hand input back: the watchdog path for a stuck
    // close, and the B-during-busy / B-during-launch escape path.
    function hardClose() {
        stopAllMotion()
        objectWrap.x = returnRect.x; objectWrap.y = returnRect.y
        objectWrap.width = returnRect.w; objectWrap.height = returnRect.h
        dim.opacity = 0
        panel.opacity = 0
        panel.scale = 0.97
        phys.inserting = false
        phys.lifting = false
        root.launching = false
        root.liftStarted = false
        root.slotGraphicOn = false
        root.busy = false
        root.visible = false
        root.closed()
    }

    // Same end state as hardClose but silent: a failed open() never took
    // input ownership, so there is nothing to hand back.
    function hardReset() {
        stopAllMotion()
        dim.opacity = 0
        panel.opacity = 0
        phys.inserting = false
        phys.lifting = false
        root.launching = false
        root.liftStarted = false
        root.slotGraphicOn = false
        root.busy = false
        root.visible = false
    }

    Timer {
        id: busyWatchdog
        interval: 900
        repeat: false
        onTriggered: {
            if (!root.visible) { root.busy = false; return }
            if (root.pendingTransition === "open") forceSettleOpen()
            else hardClose()
        }
    }

    // ---- dim ------------------------------------------------------------------
    Rectangle {
        id: dim
        anchors.fill: parent
        color: T.background
        opacity: 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // ---- panel ------------------------------------------------------------------
    Item {
        id: panel
        x: root.panelX; y: root.panelY
        width: root.panelW; height: root.panelH
        opacity: 0
        scale: 0.97
        transformOrigin: Item.Center

        Rectangle {
            anchors.fill: parent
            color: T.tileFill
        }
        TileFrame { anchors.fill: parent }

        Text {
            x: 40; y: 28
            width: parent.width - 80; height: 40
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: T.libTitlePx
            font.letterSpacing: 2
            color: T.primaryInk
            text: {
                var t = ""
                try { t = root.game ? (root.game.title || "") : "" } catch (e) {}
                return (t === "" ? "UNTITLED" : t).toUpperCase()
            }
        }
        Rectangle { // header hairline, footer-divider language
            x: 40; y: 76
            width: parent.width - 80; height: T.footerDividerH
            color: T.divider
        }

        // info column
        Text {
            x: 620; y: 110
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 3
            color: T.tileInk
            text: T.displayNameFor(root.shortName, "")
        }
        Text {
            x: 620; y: 168
            font.family: root.fontFamily
            font.pixelSize: 16
            font.letterSpacing: 3
            color: T.tileInk
            opacity: 0.7
            text: "VIEW"
        }
        Text {
            x: 620; y: 194
            font.family: root.fontFamily
            font.pixelSize: 40
            font.letterSpacing: 4
            color: T.primaryInk
            text: MT.viewLabel(root.view)
        }
        // view cycle readout: current view lit, rest dim
        Row {
            x: 620; y: 262
            spacing: 14
            Repeater {
                model: root.views
                Text {
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    font.letterSpacing: 2
                    color: index === root.viewIndex ? T.primaryInk : T.tileInk
                    opacity: index === root.viewIndex ? 1 : 0.45
                    text: MT.viewLabel(modelData)
                }
            }
        }
        Text {
            x: 620; y: 330
            font.family: root.fontFamily
            font.pixelSize: 16
            font.letterSpacing: 2
            color: T.tileInk
            opacity: 0.6
            text: "ARTWORK  " + root.sourceLine
        }
        Text {
            x: 620; y: 560
            width: 340
            wrapMode: Text.WordWrap
            font.family: root.fontFamily
            font.pixelSize: 16
            font.letterSpacing: 1
            color: T.tileInk
            opacity: 0.55
            lineHeight: 1.5
            text: root.family === "ps2"
                  ? "BROWSE THE VIEWS. OPEN REVEALS THE DISC."
                  : "BROWSE THE VIEWS. A SLOTS THE CARTRIDGE."
        }

        // footer prompts: the footer keycap language, in-panel
        Keycap { x: 40;  y: root.panelH - 74; fontFamily: root.fontFamily; text: "<" }
        Keycap { x: 132; y: root.panelH - 74; fontFamily: root.fontFamily; text: ">" }
        Text {
            x: 227; y: root.panelH - 74
            font.family: root.fontFamily
            font.pixelSize: T.fontFooterPx
            font.letterSpacing: T.footerLetterSpacing
            color: T.tileInk
            text: root.family === "gba" ? "ROTATE" : "VIEWS"
        }
        Keycap { x: 470; y: root.panelH - 74; fontFamily: root.fontFamily; text: "A" }
        Text {
            x: 565; y: root.panelH - 74
            font.family: root.fontFamily
            font.pixelSize: T.fontFooterPx
            font.letterSpacing: T.footerLetterSpacing
            color: T.tileInk
            text: "LAUNCH"
        }
        Keycap { x: 770; y: root.panelH - 74; fontFamily: root.fontFamily; text: "B" }
        Text {
            x: 865; y: root.panelH - 74
            font.family: root.fontFamily
            font.pixelSize: T.fontFooterPx
            font.letterSpacing: T.footerLetterSpacing
            color: T.tileInk
            text: "BACK"
        }

        // GBA cartridge slot: fades in for the launch insertion
        Item {
            id: slotGraphic
            x: (parent.width - 380) / 2
            y: root.panelH - 130
            width: 380; height: 30
            opacity: root.slotGraphicOn ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Rectangle {
                anchors.fill: parent
                color: "#050c14"
                border.width: 2
                border.color: T.tileBorder
            }
            Text {
                anchors.centerIn: parent
                font.family: root.fontFamily
                font.pixelSize: 14
                font.letterSpacing: 3
                color: T.tileInk
                text: "CARTRIDGE SLOT"
            }
        }

        NumberAnimation { id: panelIn; target: panel; property: "opacity"; to: 1; duration: 200 }
        NumberAnimation { id: panelOut; target: panel; property: "opacity"; to: 0; duration: 180 }
    }
    // panel scale settles with the fade
    NumberAnimation { id: panelZoomIn; target: panel; property: "scale"; to: 1; duration: 220;
                      easing.type: Easing.OutQuad }

    // ---- the object: tile rect -> panel slot --------------------------------------
    Item {
        id: objectWrap
        PhysicalObject {
            id: phys
            anchors.fill: parent
            game: root.game
            shortName: root.shortName
            artEpoch: root.artEpoch
            fontFamily: root.fontFamily
            mode: "inspect"
            view: root.view
        }
    }

    NumberAnimation { id: wrapX; target: objectWrap; property: "x"; duration: 240; easing.type: Easing.InOutQuad }
    NumberAnimation { id: wrapY; target: objectWrap; property: "y"; duration: 240; easing.type: Easing.InOutQuad }
    NumberAnimation { id: wrapW; target: objectWrap; property: "width"; duration: 240; easing.type: Easing.InOutQuad }
    NumberAnimation {
        id: wrapH; target: objectWrap; property: "height"; duration: 240
        easing.type: Easing.InOutQuad
        onFinished: {
            // Fast path only: the watchdog above is the real guarantee.
            busyWatchdog.stop()
            root.pendingTransition = ""
            if (root.visible && root.busy) {
                // open finished: settle; close finished: hide + notify
                if (panel.opacity > 0.5) {
                    root.busy = false
                } else {
                    root.visible = false
                    root.busy = false
                    // reset launch leftovers so a re-open starts clean
                    phys.inserting = false
                    phys.lifting = false
                    root.launching = false
                    root.liftStarted = false
                    root.slotGraphicOn = false
                    root.closed()
                }
            }
        }
    }


}
