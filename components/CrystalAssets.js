.pragma library

// CrystalAssets — theme-side resolver for Crystal Nova scraper assets.
//
// Reads the persistent sibling directory `crystal-nova-data/` (written by
// Crystal Nova Manager, never inside the updatable theme directory) and
// resolves per-game artwork URLs without exposing scraper storage details
// to the rest of the theme.
//
// Game identity contract: docs/GAME_ID_CONTRACT.md
//   canonical key = "<platformSlug>/<gameId>", gameId = slugify(romFileName)
//
// This file is intentionally runnable under both QML and plain Node.js:
// no QML globals are touched at import time. All failure modes return ""
// or null — a scraper problem must never break the library screen.

"use strict";

// ---------------------------------------------------------------------------
// Normalization — exact port of the Manager's TitleNormalizer (U2).
// Do not "improve" this; cross-repo fixture tests pin its behaviour.
// ---------------------------------------------------------------------------

function normalize(fileName) {
    var s = String(fileName === undefined || fileName === null ? "" : fileName);
    var i = s.lastIndexOf("/");
    if (i >= 0) s = s.substring(i + 1);
    i = s.lastIndexOf("\\");
    if (i >= 0) s = s.substring(i + 1);
    var dot = s.lastIndexOf(".");
    if (dot > 0) s = s.substring(0, dot);
    s = s.replace(/[(\[][^)\]]*[)\]]/g, " ");
    s = s.toLowerCase();
    s = s.split("_").join(" ");
    s = s.replace(/[^a-z0-9 ]/g, " ");
    s = s.replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "");
    var m = /^(.*),\s*(the|a|an)$/.exec(s);
    if (m) s = m[2] + " " + m[1];
    return s;
}

function slugify(fileName) {
    var n = normalize(fileName);
    var s = n.replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    return s === "" ? "game" : s;
}

// ---------------------------------------------------------------------------
// Platform mapping — Pegasus collection shortName -> Manager platform slug.
// ---------------------------------------------------------------------------

var PLATFORM_SLUGS = [
    "nes", "snes", "n64", "gamecube", "gb", "gbc", "gba", "nds", "n3ds",
    "genesis", "mastersystem", "gamegear", "segacd", "saturn", "dreamcast",
    "psx", "ps2", "psp", "atari2600", "atari7800", "lynx", "wonderswan",
    "ngp", "virtualboy", "pcengine", "3do", "amiga", "c64", "arcade"
];

var SHORTNAME_ALIASES = {
    "gc": "gamecube",
    "md": "genesis", "megadrive": "genesis",
    "sms": "mastersystem",
    "gg": "gamegear",
    "megacd": "segacd",
    "ps1": "psx", "psone": "psx",
    "3ds": "n3ds",
    "tg16": "pcengine", "turbografx": "pcengine", "turbografx16": "pcengine",
    "a2600": "atari2600", "a7800": "atari7800",
    "ws": "wonderswan", "wsc": "wonderswan",
    "vboy": "virtualboy",
    "neogeo": "arcade", "mame": "arcade", "fba": "arcade"
};

function platformSlug(shortName) {
    if (shortName === undefined || shortName === null) return "";
    var k = String(shortName).replace(/^\s+|\s+$/g, "").toLowerCase();
    if (PLATFORM_SLUGS.indexOf(k) >= 0) return k;
    return SHORTNAME_ALIASES[k] || "";
}

// ---------------------------------------------------------------------------
// Asset slots.
// ---------------------------------------------------------------------------

var SLOT_FILES = {
    front: "front.png",
    spine: "spine.png",
    back: "back.png",
    media: "media.png",
    logo: "logo.png",
    screenshot: "screenshot.png",
    fullcover: "fullcover.png"
};

// ---------------------------------------------------------------------------
// State (shared across importers via .pragma library).
// ---------------------------------------------------------------------------

var _baseUrl = "";
var _index = null;   // { byId: {}, byTitle: {} } or null
var _loaded = false;

function configure(baseUrl) {
    var u = String(baseUrl === undefined || baseUrl === null ? "" : baseUrl);
    if (u !== "" && u.charAt(u.length - 1) !== "/") u += "/";
    _baseUrl = u;
    _loaded = false;
    _index = null;
}

// Test/manual hook: install a parsed index directly.
function loadFromText(text) {
    _index = parseIndex(text);
    _loaded = true;
}

// Parse index.json into lookup maps. Returns null when missing,
// malformed, or an unknown version — never throws.
function parseIndex(text) {
    var byId = {};
    var byTitle = {};
    try {
        if (!text) return null;
        var root = JSON.parse(text);
        if (!root || root.version !== 1) return null;
        var games = root.games;
        if (!games || typeof games !== "object") return null;
        Object.keys(games).forEach(function (key) {
            var e = games[key];
            if (!e || typeof e !== "object") return;
            var plat = e.platform ? String(e.platform) : "";
            var gid = e.gameId ? String(e.gameId) : "";
            if (!plat || !gid) return;
            var assets = {};
            var list = e.assets;
            if (list && typeof list.length === "number") {
                for (var i = 0; i < list.length; i++) assets[String(list[i])] = true;
            }
            var entry = {
                platform: plat,
                gameId: gid,
                title: e.title ? String(e.title) : "",
                assets: assets,
                completeness: e.completeness ? String(e.completeness) : ""
            };
            byId[plat + "/" + gid] = entry;
            var tkey = plat + "/" + slugify(entry.title);
            if (!byTitle[tkey]) byTitle[tkey] = entry;
        });
        return { byId: byId, byTitle: byTitle };
    } catch (err) {
        return null;
    }
}

// (Re)load index.json from the configured data directory. Safe no-op
// outside QML (no XMLHttpRequest) or when unconfigured.
function refresh() {
    _index = null;
    _loaded = true;
    try {
        if (typeof XMLHttpRequest === "undefined" || !_baseUrl) return;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", _baseUrl + "index.json", false);
        xhr.send();
        if (xhr.status === 200 || xhr.status === 0) {
            _index = parseIndex(xhr.responseText);
        }
    } catch (e) {
        _index = null;
    }
}

function _ensureLoaded() {
    if (!_loaded) refresh();
}

// ---------------------------------------------------------------------------
// Identity.
// ---------------------------------------------------------------------------

// ROM file name for a Pegasus game object. Uses the experimental
// "Game files" API (files[].name is the file's name); degrades to "".
function romFileName(game) {
    try {
        if (!game) return "";
        var files = game.files;
        if (!files) return "";
        var f = null;
        if (typeof files.length === "number") {
            if (files.length > 0) f = files[0];
        } else if (typeof files.count === "number" && files.count > 0) {
            f = files.get ? files.get(0) : null;
        }
        if (!f) return "";
        if (f.name) return String(f.name);
        var p = f.path ? String(f.path) : "";
        var j = Math.max(p.lastIndexOf("/"), p.lastIndexOf("\\"));
        return j >= 0 ? p.substring(j + 1) : p;
    } catch (e) {
        return "";
    }
}

// Canonical "<platformSlug>/<gameId>" for a Pegasus game, or "" when the
// platform is unknown. Filename-derived when possible (stable across
// display-title renames), title-derived otherwise.
function gameKey(game, shortName) {
    var plat = platformSlug(shortName);
    if (!plat || !game) return "";
    var fn = romFileName(game);
    var id = fn ? slugify(fn) : slugify(game.title || "");
    return id ? plat + "/" + id : "";
}

// Find the index entry for a game: filename identity first, title
// fallback second. Returns null when the game was never scraped.
function _entryFor(game, shortName) {
    _ensureLoaded();
    if (!_index) return null;
    var plat = platformSlug(shortName);
    if (!plat || !game) return null;
    var fn = romFileName(game);
    if (fn) {
        var e = _index.byId[plat + "/" + slugify(fn)];
        if (e) return e;
    }
    var title = game.title || "";
    if (title) {
        var t = _index.byTitle[plat + "/" + slugify(title)];
        if (t) return t;
    }
    return null;
}

// ---------------------------------------------------------------------------
// Resolution.
// ---------------------------------------------------------------------------

// URL of one crystal asset slot for a game, or "" when not scraped /
// slot not stored. Provenance (REAL/GENERATED/USER) is intentionally
// ignored: the renderer treats every stored asset identically.
function assetUrl(game, shortName, slot) {
    var file = SLOT_FILES[slot];
    if (!file) return "";
    var e;
    try {
        e = _entryFor(game, shortName);
    } catch (err) {
        return "";
    }
    if (!e || !_baseUrl) return "";
    if (!e.assets[slot]) return "";
    return _baseUrl + "games/" + e.platform + "/" + e.gameId + "/" + file;
}

function front(game, shortName) { return assetUrl(game, shortName, "front"); }
function spine(game, shortName) { return assetUrl(game, shortName, "spine"); }
function back(game, shortName) { return assetUrl(game, shortName, "back"); }
function media(game, shortName) { return assetUrl(game, shortName, "media"); }
function logo(game, shortName) { return assetUrl(game, shortName, "logo"); }
function screenshot(game, shortName) { return assetUrl(game, shortName, "screenshot"); }

// Library tile front-art chain:
//   crystal scraped front -> Pegasus boxFront -> Pegasus poster -> ""
// ("" lets the tile render its built-in fallback art.)
function tileFront(game, shortName) {
    var c = "";
    try {
        c = front(game, shortName);
    } catch (e) { c = ""; }
    if (c) return c;
    try {
        if (game && game.assets) {
            var a = game.assets;
            return a.boxFront || a.poster || "";
        }
    } catch (e2) { /* fall through */ }
    return "";
}

// Detail-layer accessor for the future physical-case renderer: every
// resolved crystal asset URL for a game ("") when absent. Provenance is
// not exposed — display treats all assets identically.
function details(game, shortName) {
    return {
        front: front(game, shortName),
        spine: spine(game, shortName),
        back: back(game, shortName),
        media: media(game, shortName),
        logo: logo(game, shortName),
        screenshot: screenshot(game, shortName),
        fullcover: assetUrl(game, shortName, "fullcover")
    };
}

// Node.js export for the test harness (harmless under QML).
try {
    if (typeof module !== "undefined" && module.exports) {
        module.exports = {
            normalize: normalize,
            slugify: slugify,
            platformSlug: platformSlug,
            parseIndex: parseIndex,
            configure: configure,
            loadFromText: loadFromText,
            refresh: refresh,
            romFileName: romFileName,
            gameKey: gameKey,
            assetUrl: assetUrl,
            front: front, spine: spine, back: back, media: media,
            logo: logo, screenshot: screenshot,
            tileFront: tileFront,
            details: details,
            SLOT_FILES: SLOT_FILES
        };
    }
} catch (e) { /* QML: module is undefined */ }
