import QtQuick 2.12
import ".."
import "../CrystalTheme.js" as T
import "MediaTemplates.js" as MT

// PhysicalInspect — the focused physical-media view for one game.
//
// The physical object is the hero: it floats large over the dimmed
// library with only a title, an understated view indicator, and
// minimal controller hints. Still unmistakably Crystal: the dark navy
// dim, Departure Mono, the footer keycap prompt language. Nothing here
// proves the implementation — no provenance lines, no debug labels,
// no explanatory paragraphs.
//
// Controller: LEFT/RIGHT cycles views (PS2: FRONT/SPINE/BACK/OPEN —
// opening is a view, no extra button to discover; GBA: FRONT/BACK),
// A launches (tactile transition, then the existing game.launch()
// path), B returns to the exact same grid tile.
//
// Grid -> inspect reads as "brought forward": the object travels from
// the selected tile's rect to its hero slot while the library dims;
// the grid selection underneath never moves.
//
// INPUT SAFETY (do not weaken): open() reports success/failure and
// never throws; every transition is backed by the 900ms busyWatchdog;
// beginClose() jump-cuts out of busy/launching so B always escapes;
// no animation-completion callback is the single point of failure for
// input recovery.
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
    property bool busy: false        // transition running: ignore keys
    property bool launching: false
    property bool liftStarted: false
    property bool slotGraphicOn: false

    // hero slot geometry, set from the family in open()
    property int slotX: 0
    property int slotY: 140
    property int slotW: 600
    property int slotH: 620

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

    // Hero slot for a family: the object gets a large, stable, centered
    // stage with room to breathe. PS2 sizes for the OPEN spread (the
    // largest view) so FRONT/SPINE/BACK share the same hero position.
    function slotFor(fam) {
        var nw = fam === "gba" ? MT.GBA.w : MT.PS2.openW
        var nh = fam === "gba" ? MT.GBA.h : MT.PS2.openH
        var s = Math.min(1000 / nw, 620 / nh)
        var w = Math.round(nw * s), h = Math.round(nh * s)
        return { x: Math.round((1280 - w) / 2), y: 140, w: w, h: h }
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
            var sl = slotFor(root.family)
            root.slotX = sl.x; root.slotY = sl.y
            root.slotW = sl.w; root.slotH = sl.h
            // start the object exactly on the selected tile, then bring
            // it forward into the hero slot
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
            setView("open")            // the tray reveals itself first
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

    // ---- chrome: title, view indicator, hints (transparent container) -----------
    // The object is the hero; this fades/scales in around it. No panel
    // box, no info column — the composition breathes.
    Item {
        id: panel
        anchors.fill: parent
        opacity: 0
        scale: 0.97
        transformOrigin: Item.Center

        Text {
            x: 40; y: 44
            width: parent.width - 80; height: 44
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 34
            font.letterSpacing: 5
            color: T.primaryInk
            text: {
                var t = ""
                try { t = root.game ? (root.game.title || "") : "" } catch (e) {}
                return t.toUpperCase()
            }
        }
        // quiet divider under the title
        Rectangle {
            x: (parent.width - 120) / 2; y: 104
            width: 120; height: T.footerDividerH
            color: T.divider
            opacity: 0.7
        }

        // understated view indicator: current view lit, rest dim
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 814
            spacing: 22
            Repeater {
                model: root.views
                Text {
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    font.letterSpacing: 3
                    color: index === root.viewIndex ? T.primaryInk : T.tileInk
                    opacity: index === root.viewIndex ? 1 : 0.4
                    text: MT.viewLabel(modelData)
                }
            }
        }

        // minimal controller hints in the footer keycap language
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 862
            spacing: 40
            Row {
                spacing: 10
                Keycap { fontFamily: root.fontFamily; text: "<" }
                Keycap { fontFamily: root.fontFamily; text: ">" }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.fontFamily
                    font.pixelSize: T.fontFooterPx
                    font.letterSpacing: T.footerLetterSpacing
                    color: T.tileInk
                    text: root.family === "gba" ? "ROTATE" : "VIEWS"
                }
            }
            Row {
                spacing: 10
                Keycap { fontFamily: root.fontFamily; text: "A" }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.fontFamily
                    font.pixelSize: T.fontFooterPx
                    font.letterSpacing: T.footerLetterSpacing
                    color: T.tileInk
                    text: "LAUNCH"
                }
            }
            Row {
                spacing: 10
                Keycap { fontFamily: root.fontFamily; text: "B" }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.fontFamily
                    font.pixelSize: T.fontFooterPx
                    font.letterSpacing: T.footerLetterSpacing
                    color: T.tileInk
                    text: "BACK"
                }
            }
        }

        // GBA cartridge slot: a quiet Crystal target that fades in for
        // the launch insertion. Pure chrome — no labels.
        Item {
            id: slotGraphic
            visible: root.family === "gba"
            x: (1280 - 380) / 2; y: 778
            width: 380; height: 24
            opacity: root.slotGraphicOn ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#050c14"
                border.width: 2
                border.color: T.tileBorder
            }
        }

        NumberAnimation { id: panelIn; target: panel; property: "opacity"; to: 1; duration: 200 }
        NumberAnimation { id: panelOut; target: panel; property: "opacity"; to: 0; duration: 180 }
    }
    // chrome settles with the fade
    NumberAnimation { id: panelZoomIn; target: panel; property: "scale"; to: 1; duration: 220;
                      easing.type: Easing.OutQuad }

    // ---- the object: tile rect -> hero slot ---------------------------------------
    Item {
        id: objectWrap
        PhysicalObject {
            id: phys
            anchors.fill: parent
            game: root.game
            shortName: root.shortName
            artEpoch: root.artEpoch
            fontFamily: root.fontFamily
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
