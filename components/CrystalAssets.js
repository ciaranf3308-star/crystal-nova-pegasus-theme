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
var _epoch = 0;              // bumped whenever the installed index changes
var _onIndexChanged = null;  // optional QML change-notification callback
var _lastTextLen = -1;       // responseText.length of the last installed index
var _requestSeq = 0;         // guards against overlapping async refreshes

function configure(baseUrl) {
    var u = String(baseUrl === undefined || baseUrl === null ? "" : baseUrl);
    if (u !== "" && u.charAt(u.length - 1) !== "/") u += "/";
    _baseUrl = u;
    _loaded = false;
    _index = null;
    _lastTextLen = -1;
    _requestSeq++; // invalidate any in-flight refresh against the old URL
    _notifyChanged();
}

// ---------------------------------------------------------------------------
// Media bridge — Manager-configured external media library.
//
// The Manager (never the theme) may write a tiny `crystal-media-bridge.json`
// into the themes root (beside the theme directory) declaring a canonical
// *filesystem* path for the external media library:
//
//   {"version":1,"mediaRoot":"/storage/XXXX-XXXX/CrystalNova/Media","updated":<epochSeconds>}
//
// configureFromBridge() reads that file first and falls back to the legacy
// sibling directory (crystal-nova-data/) when the bridge is absent or
// invalid. A bridge problem must never break the library screen: every
// failure path ends in configure(fallbackUrl).
//
// Security: mediaRoot is validated against a strict whitelist — an absolute
// Unix path of safe characters only, capped at 256 chars, with no "." or
// ".." segments — before it is ever combined into a file:// URL. Anything
// else (relative paths, "..", content:// URIs, over-long or odd-character
// strings) is rejected and treated as "bridge invalid".
// ---------------------------------------------------------------------------

var MEDIA_ROOT_MAX_LEN = 256;
var MEDIA_ROOT_RE = /^\/[A-Za-z0-9_.\-]+(\/[A-Za-z0-9_.\-]+)*$/;

// Strict whitelist check for a bridge mediaRoot. Returns true only for an
// absolute Unix path of safe characters. Exported for the test driver.
function validMediaRoot(root) {
    if (typeof root !== "string" || root.length === 0) return false;
    if (root.length > MEDIA_ROOT_MAX_LEN) return false;
    if (!MEDIA_ROOT_RE.test(root)) return false;
    // "." and ".." pass the character class above as segments; reject them.
    var segs = root.split("/");
    for (var i = 1; i < segs.length; i++) {
        if (segs[i] === "." || segs[i] === "..") return false;
    }
    return true;
}

// Parse + validate a bridge document. Returns the file:// base URL on
// success, "" on any failure — never throws.
function _bridgeBaseUrl(text) {
    try {
        if (!text) return "";
        var doc = JSON.parse(text);
        if (!doc || doc.version !== 1) return "";
        if (!validMediaRoot(doc.mediaRoot)) return "";
        return "file://" + doc.mediaRoot + "/";
    } catch (e) {
        return "";
    }
}

// Resolve the scraper asset base URL through the Manager's media bridge,
// falling back to `fallbackUrl` (the legacy ../crystal-nova-data/) when the
// bridge is absent or invalid. Outside QML (no XMLHttpRequest) this is a
// plain configure(fallbackUrl). Async: configure() happens when the bridge
// request completes, so first paint always uses Pegasus fallback art.
function configureFromBridge(bridgeUrl, fallbackUrl) {
    if (typeof XMLHttpRequest === "undefined") {
        configure(fallbackUrl);
        return;
    }
    var b = String(bridgeUrl === undefined || bridgeUrl === null ? "" : bridgeUrl);
    if (!b) {
        configure(fallbackUrl);
        return;
    }
    try {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", b, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4) return;
            var text = "";
            var ok = false;
            try {
                ok = (xhr.status === 200 || xhr.status === 0);
                if (ok) text = xhr.responseText || "";
            } catch (e) { ok = false; }
            var base = ok ? _bridgeBaseUrl(text) : "";
            if (base) {
                configure(base); // configure() normalizes the trailing slash
                refresh();       // kick off the normal async index load path
            } else {
                configure(fallbackUrl);
            }
        };
        xhr.send();
    } catch (e) {
        configure(fallbackUrl);
    }
}

// QML registers a change-notification callback here. It is invoked on the
// GUI thread whenever the installed index changes (including "cleared"),
// so tile art bindings can re-evaluate. Never throws into the caller.
function setIndexChangedHandler(fn) {
    _onIndexChanged = (typeof fn === "function") ? fn : null;
}

// Monotonic counter of installed-index changes; lets QML/tests observe
// updates without a callback.
function indexEpoch() { return _epoch; }

function _notifyChanged() {
    _epoch++;
    var cb = _onIndexChanged;
    if (typeof cb === "function") {
        try { cb(); } catch (e) { /* a QML handler must never break resolution */ }
    }
}

// Test/manual hook: install a parsed index directly.
function loadFromText(text) {
    _index = parseIndex(text);
    _loaded = true;
    _notifyChanged();
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
            // Never trust the writer: normalize the platform through the
            // same mapping used for lookups, and reject any entry whose
            // platform or gameId is not a clean slug. A bad field must
            // drop just that entry — never poison the whole index, and
            // never end up verbatim in a lookup key or file:// URL.
            var plat = platformSlug(e.platform);
            var gid = e.gameId ? String(e.gameId) : "";
            if (!/^[a-z0-9-]+$/.test(plat) || !/^[a-z0-9-]+$/.test(gid)) return;
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
            // Duplicate policy: last-wins in BOTH maps, matching the
            // JSON.parse key semantics the Manager already applies when
            // it writes index.json.
            byId[plat + "/" + gid] = entry;
            byTitle[plat + "/" + slugify(entry.title)] = entry;
        });
        return { byId: byId, byTitle: byTitle };
    } catch (err) {
        return null;
    }
}

// (Re)load index.json from the configured data directory.
//
// Asynchronous: returns immediately — the library renders with Pegasus
// fallback art on first paint and tiles upgrade when the parse completes
// (QML observes this via setIndexChangedHandler / indexEpoch). Safe
// no-op outside QML (no XMLHttpRequest) or when unconfigured.
//
// The previously installed index is kept until the request completes,
// so a re-read never flashes tiles to fallback art. Completion installs
// whatever the request returned — including null on failure — so a
// deleted index.json clears stale art instead of resurrecting it. When
// the fetched text has the same length as the last installed index the
// re-parse (and the change notification) is skipped: entering a system
// re-reads cheaply in the common no-scrape-happened case. Overlapping
// refreshes are guarded by a sequence number; only the latest wins.
function refresh() {
    if (typeof XMLHttpRequest === "undefined" || !_baseUrl) {
        _index = null;
        _loaded = true;
        _lastTextLen = -1;
        _notifyChanged();
        return;
    }
    var seq = ++_requestSeq;
    try {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", _baseUrl + "index.json", true);
        _loaded = true;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4 || seq !== _requestSeq) return;
            var text = "";
            var ok = false;
            try {
                ok = (xhr.status === 200 || xhr.status === 0);
                if (ok) text = xhr.responseText || "";
            } catch (e) { ok = false; }
            if (ok && text.length === _lastTextLen) return; // unchanged
            _index = ok ? parseIndex(text) : null;
            _lastTextLen = ok ? text.length : -1;
            _notifyChanged();
        };
        xhr.send();
    } catch (e) {
        // Keep the previous index; the next refresh() retries.
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
            configureFromBridge: configureFromBridge,
            validMediaRoot: validMediaRoot,
            loadFromText: loadFromText,
            refresh: refresh,
            setIndexChangedHandler: setIndexChangedHandler,
            indexEpoch: indexEpoch,
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
