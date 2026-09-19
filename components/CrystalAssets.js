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
    if (s !== "") return s;
    // The ASCII fold erased everything (pure-CJK or punctuation-only
    // names). Fall back to a deterministic FNV-1a hash exactly like the
    // Manager's TitleNormalizer, so distinct games still get distinct,
    // stable ids instead of all collapsing to "game".
    var uni = unicodeNormalize(fileName);
    if (uni === "") {
        // Whitespace-only after tag-stripping (e.g. " (E).gba"): fall
        // back to the extension-stripped basename, per contract.
        var b = String(fileName === undefined || fileName === null ? "" : fileName);
        var i = Math.max(b.lastIndexOf("/"), b.lastIndexOf("\\"));
        b = i >= 0 ? b.substring(i + 1) : b;
        var dot = b.lastIndexOf(".");
        uni = dot > 0 ? b.substring(0, dot) : b;
    }
    return "game-" + fnv1aHex(uni);
}

// Like normalize() but keeps non-ASCII letters/digits: strip
// extension, strip tags, lowercase, collapse whitespace, trim.
// Exact port of the Manager's TitleNormalizer.unicodeNormalize.
function unicodeNormalize(fileName) {
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
    s = s.replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "");
    return s;
}

// FNV-1a 32-bit over the UTF-8 bytes of s, as 8 lowercase hex chars.
// Exact port of the Manager's TitleNormalizer.fnv1aHex: Math.imul
// gives the 32-bit wraparound the Kotlin Int arithmetic has, and
// (h >>> 0) renders it unsigned. Byte-for-byte identical to Kotlin
// (verified against its "foobar" -> bf9cf968 test vector).
function fnv1aHex(s) {
    var h = 0x811c9dc5;
    var str = String(s === undefined || s === null ? "" : s);
    for (var i = 0; i < str.length; i++) {
        var c = str.charCodeAt(i);
        var bytes;
        if (c < 0x80) {
            bytes = [c];
        } else if (c < 0x800) {
            bytes = [0xc0 | (c >> 6), 0x80 | (c & 0x3f)];
        } else if (c >= 0xd800 && c <= 0xdbff && i + 1 < str.length) {
            var lo = str.charCodeAt(i + 1);
            if (lo >= 0xdc00 && lo <= 0xdfff) {
                var cp = 0x10000 + ((c - 0xd800) << 10) + (lo - 0xdc00);
                bytes = [0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3f),
                         0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f)];
                i++;
            } else {
                bytes = [0xef, 0xbf, 0xbd]; // lone surrogate -> U+FFFD
            }
        } else {
            bytes = [0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f)];
        }
        for (var j = 0; j < bytes.length; j++) {
            h = h ^ bytes[j];
            h = Math.imul(h, 0x01000193);
        }
    }
    return (h >>> 0).toString(16).padStart(8, "0");
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
    _metaCache = {}; // manifests belong to the old media root
    _bumpMeta();
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

// Strict whitelist check for a bridge mediaRoot. Returns true only for an
// absolute Unix path free of control characters and "." / ".." segments.
// Real Android paths contain spaces (and parens, brackets, etc.) — those
// are safe in a file:// URL and must not be rejected. Exported for the
// test driver.
function validMediaRoot(root) {
    if (typeof root !== "string" || root.length === 0) return false;
    if (root.length > MEDIA_ROOT_MAX_LEN) return false;
    if (root.charAt(0) !== "/") return false;
    for (var i = 0; i < root.length; i++) {
        var code = root.charCodeAt(i);
        if (code < 0x20 || code === 0x7f) return false;
    }
    // "." and ".." segments are rejected (no traversal); empty segments
    // (double slashes, trailing slash) are rejected.
    var segs = root.split("/");
    for (var i = 1; i < segs.length; i++) {
        if (segs[i].length === 0 || segs[i] === "." || segs[i] === "..") return false;
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

// ---------------------------------------------------------------------------
// SD media probe (TEST ONLY).
//
// The Manager may write a tiny `crystal-esde-probe.json` into the themes
// root (beside the theme directory) declaring ONE test image inside the
// read-only ES-DE export on the SD card:
//
//   {"version":1,
//    "sdMediaRoot":"/storage/XXXX-XXXX/Crystal/imports/esde",
//    "system":"ps2",
//    "testAsset":"/storage/XXXX-XXXX/Crystal/imports/esde/media/ps2/covers/x.png",
//    "themeUrl":"file:///storage/XXXX-XXXX/Crystal/imports/esde/media/ps2/covers/x.png",
//    "created":<epochSeconds>}
//
// loadProbe() reads it (same async XHR pattern as the media bridge) and
// the theme shows a diagnostic overlay with the image. This is the
// vertical slice proving Pegasus/QML can render file:// URLs straight
// from the SD card — no artwork is ever copied.
//
// Validation: the theme URL must be a file:// URL whose percent-decoded
// path is absolute, length-capped, free of control characters and of
// "." / ".." segments (no traversal), and must equal testAsset exactly.
// Real cover filenames contain spaces and parentheses, so the directory
// character class used by the media bridge does not apply here.
// Anything else is rejected and the probe stays absent. A probe problem must never break the library
// screen: every failure path leaves _probe null.
// ---------------------------------------------------------------------------

var _probe = null;              // {sdMediaRoot,system,testAsset,themeUrl} or null
var _probeEpoch = 0;            // bumped whenever the installed probe changes
var _onProbeChanged = null;     // optional QML change-notification callback

// Validation for a probe *file* path (decoded). Unlike validMediaRoot
// (directory names), real ES-DE cover filenames contain spaces,
// parentheses, brackets, apostrophes, etc. The security properties we
// need are: absolute, length-capped, no control characters, no empty
// segments, and no "." / ".." segments (no traversal). The Manager
// generated the path by listing a real file; the theme only ever
// hands it to QML Image as a read (no shell, no write).
function validProbePath(path) {
    if (typeof path !== "string" || path.length === 0) return false;
    if (path.length > 2048) return false;
    if (path.charAt(0) !== "/") return false;
    for (var i = 0; i < path.length; i++) {
        var code = path.charCodeAt(i);
        if (code < 0x20 || code === 0x7f) return false;
    }
    var segs = path.split("/");
    for (var j = 1; j < segs.length; j++) {
        if (segs[j].length === 0 || segs[j] === "." || segs[j] === "..") return false;
    }
    return true;
}

// Parse + validate a probe document. Returns the probe record on
// success, null on any failure — never throws. Exported for the test
// driver.
//
// The Manager percent-encodes the file path in themeUrl (proper URL
// form: spaces become %20, etc.) while testAsset stays the raw
// filesystem path. Validation decodes the URL path, checks it with
// validProbePath, and requires the decoded path to equal testAsset
// exactly.
function parseProbe(text) {
    try {
        if (!text) return null;
        var doc = JSON.parse(text);
        if (!doc || doc.version !== 1) return null;
        var url = String(doc.themeUrl || "");
        if (url.slice(0, 7) !== "file://") return null;
        var path;
        try {
            path = decodeURIComponent(url.slice(7));
        } catch (e) {
            return null;
        }
        if (!validProbePath(path)) return null;
        var asset = String(doc.testAsset || "");
        if (asset !== path) return null; // decoded URL must match testAsset exactly
        return {
            sdMediaRoot: String(doc.sdMediaRoot || ""),
            system: String(doc.system || ""),
            testAsset: asset,
            themeUrl: url
        };
    } catch (e) {
        return null;
    }
}

// The installed probe record, or null when no valid probe file was
// loaded. Never throws.
function probeInfo() { return _probe; }

// The exact file:// URL handed to QML for the test image, or "" when
// no probe is installed.
function probeImageUrl() { return _probe ? _probe.themeUrl : ""; }

// QML registers a change-notification callback here; invoked on the GUI
// thread whenever the installed probe changes (including "cleared").
function setProbeChangedHandler(fn) {
    _onProbeChanged = (typeof fn === "function") ? fn : null;
}

// Monotonic counter of installed-probe changes.
function probeEpoch() { return _probeEpoch; }

function _notifyProbeChanged() {
    _probeEpoch++;
    var cb = _onProbeChanged;
    if (typeof cb === "function") {
        try { cb(); } catch (e) { /* a QML handler must never break resolution */ }
    }
}

// Test/manual hook: install a parsed probe directly.
function loadProbeFromText(text) {
    _probe = parseProbe(text);
    _notifyProbeChanged();
}

// (Re)load crystal-esde-probe.json from the themes root. Async like the
// bridge: returns immediately; the overlay appears when the parse
// completes. A missing/invalid probe installs null (overlay hidden).
// Safe no-op outside QML (no XMLHttpRequest). Never throws.
function loadProbe(probeUrl) {
    if (typeof XMLHttpRequest === "undefined") {
        _probe = null;
        _notifyProbeChanged();
        return;
    }
    var u = String(probeUrl === undefined || probeUrl === null ? "" : probeUrl);
    if (!u) {
        _probe = null;
        _notifyProbeChanged();
        return;
    }
    try {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", u, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4) return;
            var text = "";
            var ok = false;
            try {
                ok = (xhr.status === 200 || xhr.status === 0);
                if (ok) text = xhr.responseText || "";
            } catch (e) { ok = false; }
            _probe = ok ? parseProbe(text) : null;
            _notifyProbeChanged();
        };
        xhr.send();
    } catch (e) {
        _probe = null;
        _notifyProbeChanged();
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
            var p = a.boxFront || a.poster || "";
            if (p) return p;
        }
    } catch (e2) { /* fall through */ }
    // ES-DE fallback: the importer keeps covers at
    // <mediaRoot>/media/<platform>/covers/<romBaseName>.jpg.
    // Use the ROM filename (stable, from Pegasus) when the Crystal
    // index has no entry and Pegasus has no asset.
    try {
        c = esdeCover(game, shortName);
    } catch (e3) { c = ""; }
    return c || "";
}

// ES-DE cover path: <mediaRoot>/media/<platform>/covers/<romBase>.jpg
// Returns "" when the media root, platform, or ROM name is unavailable.
function esdeCover(game, shortName) {
    if (!_baseUrl) return "";
    var plat = "";
    try {
        plat = platformSlug(shortName);
    } catch (e) { return ""; }
    if (!plat) return "";
    var rom = "";
    try {
        rom = romFileName(game);
    } catch (e2) { return ""; }
    if (!rom) return "";
    // Strip the ROM extension; the cover uses .jpg.
    var dot = rom.lastIndexOf(".");
    var base = dot > 0 ? rom.substring(0, dot) : rom;
    if (!base) return "";
    // encodeURI keeps parentheses/commas readable, encodes spaces.
    return _baseUrl + "media/" + plat + "/covers/" + encodeURI(base) + ".jpg";
}

// ---------------------------------------------------------------------------
// Per-game editorial metadata.
//
// The scraper writes games/<platform>/<gameId>/manifest.json carrying
// description/genre/players/releaseYear (see the Manager's ScraperJson).
// The theme fetches the SELECTED game's manifest lazily — one small
// request per newly selected game, cached by game key — and notifies
// QML through the meta epoch (mirrors the art index pattern).
// ---------------------------------------------------------------------------

var _metaCache = {};       // gameKey -> {genre,players,year,description} ({} while in flight)
var _metaEpoch = 0;
var _onMetaChanged = null; // optional QML change-notification callback

function setMetaChangedHandler(fn) {
    _onMetaChanged = (typeof fn === "function") ? fn : null;
}

function metaEpoch() { return _metaEpoch; }

function _bumpMeta() {
    _metaEpoch++;
    try { if (_onMetaChanged) _onMetaChanged(); } catch (e) { /* never break paint */ }
}

// Editorial metadata for a game: {} when unknown or still loading (the
// fetch completes asynchronously and bumps the meta epoch, so QML
// re-reads). Never throws; never blocks first paint.
function gameMeta(game, shortName) {
    var key = "";
    try { key = gameKey(game, shortName); } catch (e) { return {}; }
    if (!key) return {};
    if (_metaCache.hasOwnProperty(key)) return _metaCache[key];
    _metaCache[key] = {}; // placeholder: fetch in flight (or unavailable)
    if (typeof XMLHttpRequest === "undefined" || !_baseUrl) {
        _bumpMeta();
        return _metaCache[key];
    }
    (function (k, url) {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", url, true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState !== 4) return;
                var m = {};
                try {
                    if (xhr.status === 200 || xhr.status === 0) {
                        var root = JSON.parse(xhr.responseText || "{}");
                        if (root && typeof root === "object") {
                            m = {
                                genre: root.genre ? String(root.genre) : "",
                                players: root.players ? String(root.players) : "",
                                year: (root.releaseYear !== undefined && root.releaseYear !== null)
                                      ? String(root.releaseYear) : "",
                                description: root.description ? String(root.description) : ""
                            };
                        }
                    }
                } catch (e) { m = {}; }
                _metaCache[k] = m;
                _bumpMeta();
            };
            xhr.send();
        } catch (e) {
            _bumpMeta();
        }
    })(key, _baseUrl + "games/" + key + "/manifest.json");
    return _metaCache[key];
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
            unicodeNormalize: unicodeNormalize,
            fnv1aHex: fnv1aHex,
            platformSlug: platformSlug,
            parseIndex: parseIndex,
            configure: configure,
            configureFromBridge: configureFromBridge,
            validMediaRoot: validMediaRoot,
            parseProbe: parseProbe,
            loadProbe: loadProbe,
            loadProbeFromText: loadProbeFromText,
            probeInfo: probeInfo,
            probeImageUrl: probeImageUrl,
            setProbeChangedHandler: setProbeChangedHandler,
            probeEpoch: probeEpoch,
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
            gameMeta: gameMeta,
            setMetaChangedHandler: setMetaChangedHandler,
            metaEpoch: metaEpoch,
            SLOT_FILES: SLOT_FILES
        };
    }
} catch (e) { /* QML: module is undefined */ }
