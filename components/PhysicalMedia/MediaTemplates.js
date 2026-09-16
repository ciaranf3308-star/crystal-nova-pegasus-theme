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

// How the GBA label should be rendered:
//   "scan" — real cartridge/media artwork: shown as-is in the label well
//   "art"  — cover art only: the renderer builds a deliberate Crystal
//            label composition from it (never a blind crop)
//   "none" — no artwork: the renderer draws a designed fallback sticker
function labelKind(details, tileFrontUrl) {
    if (details && details.media) return "scan";
    return labelUrl(details, tileFrontUrl) ? "art" : "none";
}

// PS2 disc texture: the disc-art scan ("media" slot), "" when absent —
// the renderer draws a generated Crystal disc instead.
function discUrl(details) {
    if (details && details.media) return details.media;
    return "";
}

// How the PS2 disc face should be rendered: "scan" for real disc art,
// "art" when only cover art exists (dimmed under the disc template),
// "none" for the fully authored fallback face.
function discKind(details, tileFrontUrl) {
    if (details && details.media) return "scan";
    if (caseFaceUrl(details, "front", tileFrontUrl)) return "art";
    return "none";
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
// Template geometry (design units; renderers scale to fit)
//
// Kept here so inspect and tests share one set of proportions. These
// match the authored SVG templates in assets/physical/ exactly:
// label/disc windows are the transparent areas the renderers fill with
// game artwork UNDERNEATH the template layers.
//
// GBA cart: 580x600 (real carts ~57x60mm). Label well at (70,150).
// PS2 keep case: 680x950 closed (~135x190mm DVD proportions),
// 150x950 spine, 1400x950 open spread, 560 disc on a (1080,475) hub.

var GBA = {
    w: 580, h: 600,
    labelX: 70, labelY: 150, labelW: 440, labelH: 300
};

var PS2 = {
    caseW: 680, caseH: 950,
    spineW: 150,
    openW: 1400, openH: 950,
    discD: 560, discX: 1080, discY: 475,   // disc art box + hub centre in open units
    coverX: 26, coverY: 26, coverW: 628, coverH: 898,  // front/back window
    spineArtX: 30, spineArtY: 26, spineArtW: 90, spineArtH: 898,
    innerX: 34, innerY: 34, innerW: 572, innerH: 882    // open left-panel window
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
            labelKind: labelKind,
            discUrl: discUrl,
            discKind: discKind,
            caseFaceUrl: caseFaceUrl,
            spineText: spineText,
            abbrFor: abbrFor,
            SPINE_MAX: SPINE_MAX,
            GBA: GBA,
            PS2: PS2
        };
    }
} catch (e) { /* QML: module is undefined */ }
