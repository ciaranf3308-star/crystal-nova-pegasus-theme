import QtQuick 2.12
import "MediaTemplates.js" as MT
import "../CrystalAssets.js" as CrystalAssets

// PhysicalObject — the single entry point Inspect uses to render a
// game as a physical object. Platform checks live in MediaTemplates.js;
// callers only ask `active` and set `view`.
//
// Thin by design: it resolves artwork through the existing
// CrystalAssets bridge (same artEpoch dependency the tiles use, so art
// upgrades when the async index finishes) and hands the game-owned
// textures to the platform-owned template renderers (GbaCartridge /
// Ps2Case). It draws nothing itself.
Item {
    id: root

    property var game: null
    property string shortName: ""
    property int artEpoch: 0
    property string view: "front"       // inspect view: front/spine/back/open
    property string fontFamily: "monospace"
    property bool lifting: false        // PS2 launch transition
    property bool inserting: false      // GBA launch transition

    readonly property string family: MT.familyFor(root.shortName)
    readonly property bool active: root.family !== ""
                                   && root.game !== null
                                   && root.game !== undefined

    // Resolved crystal assets for this game ("" per absent slot).
    // artEpoch is read first so the binding re-evaluates when the async
    // index finishes loading.
    property var assetDetails: {
        root.artEpoch
        return root.active ? CrystalAssets.details(root.game, root.shortName) : null
    }
    property string tileFrontUrl: {
        root.artEpoch
        return root.active ? CrystalAssets.tileFront(root.game, root.shortName) : ""
    }
    property string titleText: {
        if (!root.active) return ""
        try { return root.game.title || "" } catch (e) { return "" }
    }

    // Natural template size for the current view; the parent scales to
    // fit. PS2 sizes the slot for the OPEN spread (the largest view) so
    // every view shares one stable hero position.
    readonly property int naturalW: {
        if (root.family === "gba") return MT.GBA.w
        if (root.view === "spine") return MT.PS2.spineW
        if (root.view === "open") return MT.PS2.openW
        return MT.PS2.caseW
    }
    readonly property int naturalH: {
        if (root.family === "gba") return MT.GBA.h
        return MT.PS2.caseH
    }

    function fitScale() {
        var s = Math.min(root.width / root.naturalW, root.height / root.naturalH)
        return (isFinite(s) && s > 0) ? s : 1
    }

    GbaCartridge {
        anchors.centerIn: parent
        scale: root.fitScale()
        transformOrigin: Item.Center
        visible: root.active && root.family === "gba"
        view: root.view
        labelArt: MT.labelUrl(root.assetDetails, root.tileFrontUrl)
        labelKind: MT.labelKind(root.assetDetails, root.tileFrontUrl)
        titleText: root.titleText
        fontFamily: root.fontFamily
        inserting: root.inserting
    }

    Ps2Case {
        anchors.centerIn: parent
        scale: root.fitScale()
        transformOrigin: Item.Center
        visible: root.active && root.family === "ps2"
        view: root.view
        frontArt: MT.caseFaceUrl(root.assetDetails, "front", root.tileFrontUrl)
        spineArt: root.assetDetails ? (root.assetDetails.spine || "") : ""
        backArt: root.assetDetails ? (root.assetDetails.back || "") : ""
        discArt: MT.discUrl(root.assetDetails)
        discKind: MT.discKind(root.assetDetails, root.tileFrontUrl)
        titleText: root.titleText
        fontFamily: root.fontFamily
        lifting: root.lifting
    }
}
