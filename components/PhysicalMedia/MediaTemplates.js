.pragma library

// MediaTemplates — physical-media logic layer for the Crystal Nova
// game library.
//
// Pure logic only: no QML globals are touched at import time, so this
// file runs under both QML and plain Node.js (see
// tests/media_templates_driver.js). The QML renderers
// (GbaCartridge.qml, Ps2Case.qml, PhysicalInspect.qml) own all visuals;
// GameLibrary.qml owns selection state. Nothing outside this module
// needs a platform check: callers ask familyFor()/supportsPhysical()
// and get "" for every system that keeps the production flat library.
//
// Exactly two platform families are supported: "gba" (cartridge path)
// and "ps2" (case + disc path). Every other shortName keeps the
// current production experience, unchanged.

"use strict";

// ---------------------------------------------------------------------------
// Platform families
// ---------------------------------------------------------------------------

// Canonical family for a Pegasus collection shortName, or "" when the
// system keeps the flat production library. Matching is intentionally
// strict: only the exact shortNames below gain the physical-media
// experience — no long-name guessing, no substring matching.
function familyFor(shortName) {
    if (shortName === undefined || shortName === null) return "";
    var k = String(shortName).replace(/^\s+|\s+$/g, "").toLowerCase();
    if (k === "gba") return "gba";
    if (k === "ps2") return "ps2";
    return "";
}

function supportsPhysical(shortName) {
    return familyFor(shortName) !== "";
}

// ---------------------------------------------------------------------------
// Inspect views
// ---------------------------------------------------------------------------

// Ordered view cycle per family. PS2 opens as a view in the same
// left/right cycle so no extra button has to be discovered; GBA is a
// loose cartridge with a simple front/back rotation.
var VIEWS = {
    gba: ["front", "back"],
    ps2: ["front", "spine", "back", "open"]
};

var VIEW_LABELS = {
    front: "FRONT",
    spine: "SPINE",
    back: "BACK",
    open: "OPEN"
};

function inspectViews(family) {
    return VIEWS.hasOwnProperty(family) ? VIEWS[family].slice() : [];
}

function viewLabel(view) {
    return VIEW_LABELS.hasOwnProperty(view) ? VIEW_LABELS[view] : "";
}

// Next/previous view in the family cycle, wrapping around. Unknown
// family or view falls back to the first view (or "" when unsupported).
function nextView(family, current) {
    var vs = inspectViews(family);
    if (vs.length === 0) return "";
    var i = vs.indexOf(current);
    return vs[(i + 1) % vs.length];
}

function prevView(family, current) {
    var vs = inspectViews(family);
    if (vs.length === 0) return "";
    var i = vs.indexOf(current);
    if (i < 0) return vs[0];
    return vs[(i - 1 + vs.length) % vs.length];
}

// ---------------------------------------------------------------------------
// Artwork slot chains
// ---------------------------------------------------------------------------
//
// `details` is the object returned by CrystalAssets.details(game,
// shortName): every resolved crystal asset URL, "" when absent.
// Provenance is ignored here exactly as in CrystalAssets — generated
// and real assets display through the same renderer.

// GBA cartridge label texture chain: the cart-label scan ("media" slot
// for cart systems) first, then the front cover, then the library tile
// chain (which already falls back to Pegasus boxFront/poster).
function labelUrl(details, tileFrontUrl) {
    if (details) {
        if (details.media) return details.media;
        if (details.front) return details.front;
    }
    return tileFrontUrl || "";
}

// PS2 disc texture: the disc-art scan ("media" slot), "" when absent —
// the renderer draws a generated Crystal disc instead.
function discUrl(details) {
    if (details && details.media) return details.media;
    return "";
}

// PS2 case faces: crystal slot first, then the library tile chain for
// the front face (Pegasus boxFront/poster), "" otherwise — the
// renderer draws generated Crystal faces instead.
function caseFaceUrl(details, face, tileFrontUrl) {
    if (details && details[face]) return details[face];
    if (face === "front") return tileFrontUrl || "";
    return "";
}

// ---------------------------------------------------------------------------
// Generated-face helpers
// ---------------------------------------------------------------------------

// Spine text: short uppercase title for the generated PS2 spine.
// Collapses whitespace; over-long titles are hard-truncated (the
// renderer elides visually as a second guard).
var SPINE_MAX = 24;

function spineText(title) {
    var t = String(title === undefined || title === null ? "" : title);
    t = t.replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "").toUpperCase();
    if (t === "") return "UNTITLED";
    if (t.length > SPINE_MAX) t = t.substring(0, SPINE_MAX);
    return t;
}

// Abbreviation for generated labels/discs: first letters of the first
// two words, e.g. "Mario Golf" -> "MG". Falls back to the first two
// characters of the cleaned title.
function abbrFor(title) {
    var t = String(title === undefined || title === null ? "" : title);
    t = t.replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "").toUpperCase();
    if (t === "") return "??";
    var words = t.split(" ").filter(function (w) { return w.length > 0; });
    if (words.length >= 2) return (words[0].charAt(0) + words[1].charAt(0));
    var clean = t.replace(/[^A-Z0-9]/g, "");
    if (clean.length >= 2) return clean.substring(0, 2);
    return (clean + "?").substring(0, 2);
}

// ---------------------------------------------------------------------------
// Template geometry (design units; renderers scale to fit)
// ---------------------------------------------------------------------------
//
// Kept here so tile, inspect, and tests share one set of proportions.
// GBA cart: near-square (real carts ~57x60mm). PS2 keep case: DVD
// proportions (~135x190mm).

var GBA = {
    w: 300, h: 320,
    labelX: 34, labelY: 40, labelW: 232, labelH: 168,
    bodyRadius: 26
};

var PS2 = {
    caseW: 300, caseH: 420,
    spineW: 64,
    discD: 252, discY: 150,   // disc diameter / centre-Y inside the open tray
    plasticEdge: 7            // clear-sleeve edge around cover art
};

// Node.js export for the test harness (harmless under QML).
try {
    if (typeof module !== "undefined" && module.exports) {
        module.exports = {
            familyFor: familyFor,
            supportsPhysical: supportsPhysical,
            inspectViews: inspectViews,
            viewLabel: viewLabel,
            nextView: nextView,
            prevView: prevView,
            labelUrl: labelUrl,
            discUrl: discUrl,
            caseFaceUrl: caseFaceUrl,
            spineText: spineText,
            abbrFor: abbrFor,
            SPINE_MAX: SPINE_MAX,
            GBA: GBA,
            PS2: PS2
        };
    }
} catch (e) { /* QML: module is undefined */ }
