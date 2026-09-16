import QtQuick 2.12
import "MediaTemplates.js" as MT
import "../CrystalAssets.js" as CrystalAssets

// PhysicalObject — the single entry point the library uses to render a
// game as a physical object. Platform checks live in MediaTemplates.js;
// callers only ask `active`.
//
// mode "tile": static 2.5D pose for the selected grid tile (front view,
// slight tilt toward the user, no animation — the tile contract is
// colour-only on browse).
// mode "inspect": larger, view-driven (front/spine/back/open), tilt off —
// the Inspect screen owns the interaction.
//
// All artwork resolves through the existing CrystalAssets bridge with
// the same artEpoch dependency the tiles use, so covers upgrade when
// the async index (re)load completes. Missing assets degrade to the
// generated Crystal faces inside each renderer — never a broken image.
Item {
    id: root

    property var game: null
    property string shortName: ""
    property int artEpoch: 0
    property string mode: "tile"        // "tile" | "inspect"
    property string view: "front"       // inspect view; tile forces front
    property string fontFamily: "monospace"
    property bool lifting: false        // PS2 launch transition
    property bool inserting: false      // GBA launch transition

    readonly property string family: MediaTemplates.familyFor(root.shortName)
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

    readonly property int naturalW: {
        if (root.family === "gba") return MT.GBA.w
        if (root.view === "spine") return 120
        if (root.view === "open") return 600
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
        width: root.naturalW
        height: root.naturalH
        scale: root.fitScale()
        transformOrigin: Item.Center
        visible: root.active && root.family === "gba"
        view: root.mode === "tile" ? "front" : root.view
        labelArt: MediaTemplates.labelUrl(root.assetDetails, root.tileFrontUrl)
        titleText: root.titleText
        fontFamily: root.fontFamily
        inserting: root.inserting
        transform: Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: root.mode === "tile" ? -8 : 0
            origin.x: MT.GBA.w / 2
            origin.y: MT.GBA.h / 2
        }
    }

    Ps2Case {
        anchors.centerIn: parent
        width: root.naturalW
        height: root.naturalH
        scale: root.fitScale()
        transformOrigin: Item.Center
        visible: root.active && root.family === "ps2"
        view: root.mode === "tile" ? "front" : root.view
        frontArt: MediaTemplates.caseFaceUrl(root.assetDetails, "front", root.tileFrontUrl)
        spineArt: root.assetDetails ? (root.assetDetails.spine || "") : ""
        backArt: root.assetDetails ? (root.assetDetails.back || "") : ""
        discArt: MediaTemplates.discUrl(root.assetDetails)
        titleText: root.titleText
        fontFamily: root.fontFamily
        lifting: root.lifting
        transform: Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: root.mode === "tile" ? -8 : 0
            origin.x: root.naturalW / 2
            origin.y: MT.PS2.caseH / 2
        }
    }
}
