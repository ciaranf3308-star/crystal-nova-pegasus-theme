// Node driver for the CrystalAssets contract tests.
// Loaded by tests/test_crystal_assets.py. Exits 0 when every assertion
// passes, non-zero with a failure report otherwise.
"use strict";

const fs = require("fs");
const path = require("path");

const REPO = path.resolve(__dirname, "..");
// CrystalAssets.js starts with the QML-only `.pragma library` directive;
// strip it before evaluating under node.
let src = fs.readFileSync(path.join(REPO, "components", "CrystalAssets.js"), "utf8");
src = src.replace(/^\s*\.pragma library\s*/, "");
const mod = { exports: {} };
new Function("module", "exports", src)(mod, mod.exports);
const A = mod.exports;

let failures = [];
function check(name, cond, extra) {
    if (!cond) failures.push(name + (extra ? " :: " + extra : ""));
    else console.log("ok - " + name);
}
function eq(name, actual, expected) {
    check(name, actual === expected,
        "expected " + JSON.stringify(expected) + ", got " + JSON.stringify(actual));
}

const BASE = "file:///themes/crystal-nova-data/";
const sampleIndex = fs.readFileSync(
    path.join(REPO, "tests", "fixtures", "scraper_index_sample.json"), "utf8");
const fixtures = JSON.parse(fs.readFileSync(
    path.join(REPO, "tests", "fixtures", "u2_gameid_fixtures.json"), "utf8"));

// --- 1. game-ID mapping matches Manager U2 fixtures -------------------------
Object.keys(fixtures).forEach(function (input) {
    eq("slugify[" + input + "]", A.slugify(input), fixtures[input]);
});

// --- 2. platform mapping -----------------------------------------------------
eq("platform gba", A.platformSlug("gba"), "gba");
eq("platform GC alias", A.platformSlug("GC"), "gamecube");
eq("platform md alias", A.platformSlug("md"), "genesis");
eq("platform whitespace/case", A.platformSlug("  Ps2 "), "ps2");
eq("platform unknown", A.platformSlug("novaland"), "");

// --- 3. gameKey --------------------------------------------------------------
const mgFiles = [{ name: "Mario Golf - Advance Tour (E).gba",
                   path: "/roms/gba/Mario Golf - Advance Tour (E).gba" }];
const mg = { title: "Mario Golf: Advance Tour", files: mgFiles,
             assets: { boxFront: "pegasus/mg-box.png", poster: "pegasus/mg-poster.png" } };
eq("gameKey filename-derived", A.gameKey(mg, "gba"), "gba/mario-golf-advance-tour");
eq("gameKey unknown platform", A.gameKey(mg, "novaland"), "");
eq("gameKey title-only game", A.gameKey({ title: "TOCA Race Driver 3" }, "ps2"),
    "ps2/toca-race-driver-3");

// --- 4. scraped front overrides Pegasus boxFront -----------------------------
A.configure(BASE);
A.loadFromText(sampleIndex);
eq("scraped front overrides boxFront",
    A.tileFront(mg, "gba"),
    BASE + "games/gba/mario-golf-advance-tour/front.png");
eq("crystal front()", A.front(mg, "gba"),
    BASE + "games/gba/mario-golf-advance-tour/front.png");

// --- 5. no scraped asset -> Pegasus fallbacks --------------------------------
const unscraped = { title: "Some Unscraped Game",
    files: [{ name: "Some Unscraped Game.gba" }],
    assets: { boxFront: "pegasus/u-box.png", poster: "pegasus/u-poster.png" } };
eq("unscraped falls back to boxFront", A.tileFront(unscraped, "gba"), "pegasus/u-box.png");
const noBox = { title: "Some Unscraped Game",
    files: [{ name: "Some Unscraped Game.gba" }],
    assets: { poster: "pegasus/u-poster.png" } };
eq("boxFront missing falls back to poster", A.tileFront(noBox, "gba"), "pegasus/u-poster.png");
const noArt = { title: "Some Unscraped Game",
    files: [{ name: "Some Unscraped Game.gba" }], assets: {} };
eq("no art at all -> empty (theme fallback)", A.tileFront(noArt, "gba"), "");
eq("null game -> empty", A.tileFront(null, "gba"), "");

// --- 6. malformed index never breaks resolution -------------------------------
["not json at all", '{"version":2,"games":{}}', '{"version":1}',
 '{"version":1,"games":null}', "", null].forEach(function (bad, i) {
    A.configure(BASE);
    A.loadFromText(bad);
    check("malformed index returns null [" + i + "]", A.parseIndex(bad) === null);
    eq("malformed index tileFront falls back [" + i + "]",
        A.tileFront(mg, "gba"), "pegasus/mg-box.png");
    eq("malformed index assetUrl empty [" + i + "]", A.front(mg, "gba"), "");
});
A.loadFromText(sampleIndex); // restore

// --- 7. missing asset file (slot not stored) ----------------------------------
const zelda = { title: "The Legend of Zelda: A Link to the Past",
    files: [{ name: "Zelda, The - A Link to the Past.smc" }],
    assets: { boxFront: "pegasus/zelda-box.png" } };
eq("stored front resolves", A.front(zelda, "snes"),
    BASE + "games/snes/zelda-the-a-link-to-the-past/front.png");
eq("unstored spine -> empty", A.spine(zelda, "snes"), "");
eq("tileFront still uses stored front", A.tileFront(zelda, "snes"),
    BASE + "games/snes/zelda-the-a-link-to-the-past/front.png");

// --- 8. generated and real assets resolve identically -------------------------
// Provenance is Manager-only info: two entries differing only in a
// (hypothetical) provenance field must produce identical URLs.
const provIndex = JSON.stringify({ version: 1, games: {
    "gba/prov-real":    { platform: "gba", gameId: "prov-real",
                          title: "Prov Real", assets: ["front"],
                          provenance: { front: "REAL" } },
    "gba/prov-gen":     { platform: "gba", gameId: "prov-gen",
                          title: "Prov Generated", assets: ["front"],
                          provenance: { front: "GENERATED" } },
    "gba/prov-user":    { platform: "gba", gameId: "prov-user",
                          title: "Prov User", assets: ["front"],
                          provenance: { front: "USER" } }
}});
A.configure(BASE);
A.loadFromText(provIndex);
const mk = (t, n) => ({ title: t, files: [{ name: n }] });
eq("REAL front", A.front(mk("Prov Real", "Prov Real.gba"), "gba"),
    BASE + "games/gba/prov-real/front.png");
eq("GENERATED front identical shape", A.front(mk("Prov Generated", "Prov Generated.gba"), "gba"),
    BASE + "games/gba/prov-gen/front.png");
eq("USER front identical shape", A.front(mk("Prov User", "Prov User.gba"), "gba"),
    BASE + "games/gba/prov-user/front.png");
A.loadFromText(sampleIndex); // restore

// --- 9. rename safety: title changed, filename stable --------------------------
const renamed = { title: "Mario Golf 2: Totally Retitled",
    files: [{ name: "Mario Golf - Advance Tour (E).gba" }],
    assets: { boxFront: "pegasus/mg-box.png" } };
eq("renamed title keeps artwork (filename identity)",
    A.tileFront(renamed, "gba"),
    BASE + "games/gba/mario-golf-advance-tour/front.png");

// --- 10. title fallback when the files API is absent ---------------------------
const noFilesApi = { title: "TOCA Race Driver 3",
    assets: { boxFront: "pegasus/toca-box.png" } };
eq("title fallback resolves", A.tileFront(noFilesApi, "ps2"),
    BASE + "games/ps2/toca-race-driver-3/front.png");

// --- 11. details() for the future case renderer --------------------------------
const toca = { title: "TOCA Race Driver 3",
    files: [{ name: "TOCA Race Driver 3.iso" }] };
const d = A.details(toca, "ps2");
eq("details front", d.front, BASE + "games/ps2/toca-race-driver-3/front.png");
eq("details spine", d.spine, BASE + "games/ps2/toca-race-driver-3/spine.png");
eq("details back", d.back, BASE + "games/ps2/toca-race-driver-3/back.png");
eq("details media", d.media, BASE + "games/ps2/toca-race-driver-3/media.png");
eq("details logo", d.logo, BASE + "games/ps2/toca-race-driver-3/logo.png");
eq("details screenshot", d.screenshot, BASE + "games/ps2/toca-race-driver-3/screenshot.png");
const dNone = A.details(unscraped, "gba");
eq("details unscraped front empty", dNone.front, "");
eq("details unscraped spine empty", dNone.spine, "");

// --- 12. unconfigured / missing data dir ---------------------------------------
A.configure("");
A.loadFromText(sampleIndex);
eq("unconfigured base -> empty", A.front(mg, "gba"), "");
eq("unconfigured tileFront -> Pegasus", A.tileFront(mg, "gba"), "pegasus/mg-box.png");
// refresh() with no XMLHttpRequest (node) must be a safe no-op
A.configure(BASE);
A.refresh();
check("refresh() no-op outside QML", true);

// --- 13. entries with missing fields are skipped safely ----------------------
// An entry without platform/gameId (or with a null assets list) must not
// break the parse and must not resolve; the game falls back to Pegasus art.
const missingFieldsIndex = JSON.stringify({ version: 1, games: {
    "gba/ok-game":   { platform: "gba", gameId: "ok-game",
                       title: "Ok Game", assets: ["front"] },
    "bad/noplat":    { gameId: "noplat", title: "No Platform",
                       assets: ["front"] },
    "bad/nogid":     { platform: "gba", title: "No GameId", assets: ["front"] },
    "bad/nullentry": null,
    "bad/notobject":  "just a string",
    "gba/nullassets":{ platform: "gba", gameId: "nullassets",
                       title: "Null Assets", assets: null },
    "bad/numfields": { platform: 42, gameId: "numfields",
                       title: "Numeric Platform", assets: ["front"] }
}});
A.configure(BASE);
A.loadFromText(missingFieldsIndex);
const mf = (t, n) => ({ title: t, files: [{ name: n }] });
eq("valid entry beside broken ones still resolves",
    A.front(mf("Ok Game", "Ok Game.gba"), "gba"),
    BASE + "games/gba/ok-game/front.png");
eq("missing platform -> Pegasus fallback",
    A.tileFront(mf("No Platform", "Noplat.gba"), "gba"), "");
eq("missing gameId -> Pegasus fallback",
    A.tileFront(mf("No GameId", "Nogid.gba"), "gba"), "");
eq("null assets -> no slots resolve",
    A.front(mf("Null Assets", "Nullassets.gba"), "gba"), "");
eq("numeric platform -> skipped",
    A.tileFront(mf("Numeric Platform", "Numfields.gba"), "gba"), "");
A.loadFromText(sampleIndex); // restore

// --- 14. platform/gameId are validated, never trusted verbatim --------------
// The platform goes through the theme's platformSlug() mapping; anything
// that is not a clean [a-z0-9-] slug on either side is skipped so it can
// never land verbatim in a lookup key or file:// URL.
const untrustedIndex = JSON.stringify({ version: 1, games: {
    "x/padded":   { platform: "GBA ", gameId: "padded-game",
                    title: "Padded", assets: ["front"] },
    "x/unknown":  { platform: "novaland", gameId: "unknown-game",
                    title: "Unknown", assets: ["front"] },
    "x/spaced":   { platform: "gba", gameId: "spaced game",
                    title: "Spaced", assets: ["front"] },
    "x/slashed":  { platform: "gba", gameId: "a/b",
                    title: "Slashed", assets: ["front"] },
    "x/aliased":  { platform: "gc", gameId: "aliased-game",
                    title: "Aliased", assets: ["front"] }
}});
A.configure(BASE);
A.loadFromText(untrustedIndex);
eq("padded platform normalizes through platformSlug",
    A.front(mf("Padded", "Padded Game.gba"), "gba"),
    BASE + "games/gba/padded-game/front.png");
eq("unknown platform skipped",
    A.tileFront(mf("Unknown", "Unknown Game.gba"), "novaland"), "");
eq("gameId with space skipped",
    A.tileFront(mf("Spaced", "Spaced Game.gba"), "gba"), "");
eq("gameId with slash skipped",
    A.tileFront(mf("Slashed", "A-B.gba"), "gba"), "");
eq("platform alias resolves to canonical slug",
    A.front(mf("Aliased", "Aliased Game.gba"), "gamecube"),
    BASE + "games/gamecube/aliased-game/front.png");
A.loadFromText(sampleIndex); // restore

// --- 15. duplicate gameIds: last-wins in both maps ---------------------------
// Matches the JSON.parse key semantics the Manager applies when writing
// index.json; byId and byTitle must agree on the same canonical entry.
const dupIndex = JSON.stringify({ version: 1, games: {
    "gba/dup-game": { platform: "gba", gameId: "dup-game",
                      title: "Dup Game", assets: ["front"] },
    "gba/dup-game-duplicate-key": { platform: "gba", gameId: "dup-game",
                      title: "Dup Game", assets: ["front", "back"] }
}});
A.configure(BASE);
A.loadFromText(dupIndex);
eq("byId duplicate last-wins",
    A.front(mf("Dup Game", "Dup Game.gba"), "gba"),
    BASE + "games/gba/dup-game/front.png");
eq("byTitle duplicate last-wins (back slot only in second entry)",
    A.back({ title: "Dup Game" }, "gba"),
    BASE + "games/gba/dup-game/back.png");
A.loadFromText(sampleIndex); // restore

// --- 16. async refresh() -----------------------------------------------------
// Fake XMLHttpRequest: requests are captured and completed manually so the
// async load path is deterministic under node.
var xhrLog = [];
function FakeXHR() {
    this.readyState = 0;
    this.status = 0;
    this.responseText = "";
    this.onreadystatechange = null;
    this._url = "";
    this._async = false;
    xhrLog.push(this);
}
FakeXHR.prototype.open = function (method, url, async) {
    this._url = url;
    this._async = async;
    this.readyState = 1;
    check("open is async GET of index.json, bridge/probe file, or manifest",
        async === true && (url.slice(-10) === "index.json" ||
            url.slice(-25) === "crystal-media-bridge.json" ||
            url.slice(-23) === "crystal-esde-probe.json" ||
            url.slice(-13) === "manifest.json"));
};
FakeXHR.prototype.send = function () { /* completed manually below */ };
function completeXHR(xhr, status, text) {
    xhr.status = status;
    xhr.responseText = text;
    xhr.readyState = 4;
    if (typeof xhr.onreadystatechange === "function") xhr.onreadystatechange();
}
global.XMLHttpRequest = FakeXHR;

var notified = 0;
A.configure(BASE);
A.setIndexChangedHandler(function () { notified++; });
var epoch0 = A.indexEpoch();
A.refresh();
check("refresh() returns with request in flight", xhrLog.length === 1);
eq("fallback art while async load is pending",
    A.tileFront(mg, "gba"), "pegasus/mg-box.png");
completeXHR(xhrLog[0], 200, sampleIndex);
eq("async load installs the index",
    A.tileFront(mg, "gba"),
    BASE + "games/gba/mario-golf-advance-tour/front.png");
check("change handler fired on completion", notified === 1);
check("index epoch bumped on completion", A.indexEpoch() === epoch0 + 1);
// Unchanged file: same text length -> re-parse and notification skipped.
var epoch1 = A.indexEpoch();
A.refresh();
completeXHR(xhrLog[1], 200, sampleIndex);
check("unchanged index skips re-parse (no notify)",
    A.indexEpoch() === epoch1 && notified === 1);
// Changed file: re-parse installs and notifies; art still resolves.
A.refresh();
completeXHR(xhrLog[2], 200, sampleIndex + " ");
check("changed index re-parses and notifies",
    A.indexEpoch() === epoch1 + 1 && notified === 2);
eq("art still resolves after re-parse",
    A.tileFront(mg, "gba"),
    BASE + "games/gba/mario-golf-advance-tour/front.png");
// Failed re-read: stale index is cleared, tiles fall back, still notifies.
A.refresh();
completeXHR(xhrLog[3], 404, "");
eq("failed re-read clears stale art", A.front(mg, "gba"), "");
eq("failed re-read falls back to Pegasus", A.tileFront(mg, "gba"),
    "pegasus/mg-box.png");
check("failed re-read notifies", notified === 3);
// Overlapping refreshes: only the latest completion installs.
A.refresh();
var staleReq = xhrLog[xhrLog.length - 1];
A.refresh(); // supersedes the previous request
var latestReq = xhrLog[xhrLog.length - 1];
completeXHR(latestReq, 200, sampleIndex);
var notifiedAfterLatest = notified;
completeXHR(staleReq, 200, "not json"); // must be ignored
check("stale overlapping response ignored",
    notified === notifiedAfterLatest &&
    A.tileFront(mg, "gba") ===
        BASE + "games/gba/mario-golf-advance-tour/front.png");
A.setIndexChangedHandler(null);

// --- 15. media bridge resolution ------------------------------------------------
var BRIDGE_URL = "file:///themes/crystal-media-bridge.json";
var SD_BASE = "file:///storage/1234-ABCD/CrystalNova/Media/";

// validMediaRoot: strict whitelist
[["/storage/1234-ABCD/CrystalNova/Media", true],
 ["/sdcard", true],
 ["/storage/1234-ABCD/CrystalNova/.thumbcache", true],
 ["", false],
 ["/", false],
 ["crystal-nova-data", false],
 ["../crystal-nova-data", false],
 ["content://com.example/files", false],
 ["file:///storage/x", false],
 ["/storage/../etc", false],
 ["/storage/..", false],
 ["/storage/./media", false],
 ["/storage/my dir", false],
 ["/storage/evil;rm -rf", false],
 ["/storage/\"quoted\"", false],
 ["/storage/a".repeat(40), false], // > 256 chars
 ["/a/", false],
 [null, false],
 ["/storage/1234_abc-DEF.ghi", true]
].forEach(function (c, i) {
    eq("validMediaRoot[" + i + "] " + JSON.stringify(c[0]), A.validMediaRoot(c[0]), c[1]);
});

// Helper: resolve the configured base URL by loading the sample index and
// reading a known asset URL back (no getter for the base itself).
function resolvedFront() {
    A.loadFromText(sampleIndex);
    return A.front(mg, "gba");
}

var bridgeDoc = JSON.stringify({
    version: 1, mediaRoot: "/storage/1234-ABCD/CrystalNova/Media", updated: 1700000000
});

// valid bridge -> SD base, then index loads from it
A.configureFromBridge(BRIDGE_URL, BASE);
check("bridge request issued", xhrLog.length > 0 && xhrLog[xhrLog.length - 1]._url === BRIDGE_URL);
completeXHR(xhrLog[xhrLog.length - 1], 200, bridgeDoc);
check("bridge index request targets SD base",
    xhrLog[xhrLog.length - 1]._url === SD_BASE + "index.json");
eq("valid bridge resolves assets under mediaRoot",
    resolvedFront(), SD_BASE + "games/gba/mario-golf-advance-tour/front.png");

// missing bridge -> legacy fallback
A.configureFromBridge(BRIDGE_URL, BASE);
completeXHR(xhrLog[xhrLog.length - 1], 404, "");
eq("missing bridge falls back to legacy base", resolvedFront(),
    BASE + "games/gba/mario-golf-advance-tour/front.png");

// each invalid bridge document -> legacy fallback
[["garbage (parse error)", "not json at all"],
 ["version mismatch (number)", '{"version":2,"mediaRoot":"/storage/x","updated":1}'],
 ["version mismatch (string)", '{"version":"1","mediaRoot":"/storage/x","updated":1}'],
 ["missing mediaRoot", '{"version":1,"updated":1}'],
 ["content:// URI", '{"version":1,"mediaRoot":"content://com.x/y","updated":1}'],
 ["relative path", '{"version":1,"mediaRoot":"crystal-nova-data","updated":1}'],
 ["dot-dot traversal", '{"version":1,"mediaRoot":"/storage/../etc","updated":1}'],
 ["over-long path", JSON.stringify({ version: 1, mediaRoot: "/x".repeat(200), updated: 1 })]
].forEach(function (c) {
    A.configureFromBridge(BRIDGE_URL, BASE);
    completeXHR(xhrLog[xhrLog.length - 1], 200, c[1]);
    eq("invalid bridge -> fallback [" + c[0] + "]", resolvedFront(),
        BASE + "games/gba/mario-golf-advance-tour/front.png");
});

// no XMLHttpRequest (non-QML / Node) -> plain fallback configure
delete global.XMLHttpRequest;
A.configureFromBridge(BRIDGE_URL, BASE);
eq("no-XHR environment configures fallback", resolvedFront(),
    BASE + "games/gba/mario-golf-advance-tour/front.png");
global.XMLHttpRequest = FakeXHR;
A.configure(BASE); // restore default state for the report

// --- 12. shared golden contract: Manager fixture -> exact theme URLs -----
// The golden fixture is the single shared scraper->theme contract. The
// Manager's ScraperThemeContractTest pins every value in it against
// real production code (TitleNormalizer, ScraperStorage.assetPath,
// ScraperJson.indexEntryToJson); this section proves the theme
// resolver requests exactly those files — in legacy mode AND in
// dedicated MEDIA-root (bridge) mode — from the fixture's indexJson.
// If either side drifts, its test fails.
const golden = JSON.parse(fs.readFileSync(
    path.join(REPO, "tests", "fixtures", "scraper_theme_contract_mario_golf.json"), "utf8"));
const goldenGame = { title: "Mario Golf: Advance Tour",
    files: [{ name: golden.romFileName }] };
["legacy", "dedicated"].forEach(function (mode) {
    A.configure(golden.baseUrls[mode]);
    A.loadFromText(golden.indexJson);
    const want = golden.expectedUrls[mode];
    eq("golden front [" + mode + "]", A.front(goldenGame, "gba"), want.front);
    eq("golden spine [" + mode + "]", A.spine(goldenGame, "gba"), want.spine);
    eq("golden back [" + mode + "]", A.back(goldenGame, "gba"), want.back);
    eq("golden media [" + mode + "]", A.media(goldenGame, "gba"), want.media);
    // Missing slot in the index -> "" (graceful fallback, never a guess).
    eq("golden absent slot [" + mode + "]", A.logo(goldenGame, "gba"), "");
    // The golden fixture lists the exact on-disk paths the scraper
    // writes; the deterministic fixture media tree must contain every
    // one of them (front/spine/back/media + manifest) plus the root
    // index.json. This closes the loop: path math AND real files.
    const treeRoot = path.join(REPO, "tests", "fixtures", "media-tree");
    Object.keys(golden.assetPaths).forEach(function (slot) {
        const rel = golden.assetPaths[slot];
        const abs = path.join(treeRoot, rel);
        eq("fixture file exists: " + rel, fs.existsSync(abs), true);
    });
    eq("fixture manifest exists",
        fs.existsSync(path.join(treeRoot, golden.manifestPath)), true);
    eq("fixture index.json exists",
        fs.existsSync(path.join(treeRoot, "index.json")), true);
});
A.configure(BASE); // restore

// --- 13. per-game manifest metadata (gameMeta) ---------------------------------
// gameMeta() reads <media-root>/games/<platform>/<gameId>/manifest.json
// lazily, caches per game key, and bumps metaEpoch on completion.
// Missing manifests degrade to {} without throwing.
(function () {
    var game = { title: "Mario Golf: Advance Tour",
        files: [{ name: "Mario Golf - Advance Tour (USA).gba" }] };
    // prime the index so gameKey resolves
    A.configure(BASE);
    // gameMeta with no manifest fetched yet returns {} (placeholder)
    var m1 = A.gameMeta(game, "gba");
    eq("gameMeta missing manifest -> object", typeof m1, "object");
    // metaEpoch starts at 0 and is a number
    eq("metaEpoch is number", typeof A.metaEpoch(), "number");
    // changing media root clears the cache (configure bumps epoch)
    var e1 = A.metaEpoch();
    A.configure(BASE + "/");
    var e2 = A.metaEpoch();
    eq("configure clears meta cache (epoch bumps)", e2 > e1, true);
})();
A.configure(BASE); // restore

// --- 17. SD media probe --------------------------------------------------------
(function () {
    var GOOD = JSON.stringify({
        version: 1,
        sdMediaRoot: "/storage/1234-ABCD/Crystal/imports/esde",
        system: "ps2",
        testAsset: "/storage/1234-ABCD/Crystal/imports/esde/media/ps2/covers/x.png",
        themeUrl: "file:///storage/1234-ABCD/Crystal/imports/esde/media/ps2/covers/x.png",
        created: 1700000000
    });
    // parseProbe: strict validation
    var p = A.parseProbe(GOOD);
    check("parseProbe accepts a valid probe",
        p !== null &&
        p.sdMediaRoot === "/storage/1234-ABCD/Crystal/imports/esde" &&
        p.system === "ps2" &&
        p.themeUrl === "file:///storage/1234-ABCD/Crystal/imports/esde/media/ps2/covers/x.png");
    check("parseProbe rejects bad version",
        A.parseProbe(GOOD.replace('"version":1', '"version":2')) === null);
    check("parseProbe rejects non-file URL",
        A.parseProbe(GOOD.replace("file:///storage", "content:///storage")) === null);
    check("parseProbe rejects .. in path",
        A.parseProbe(GOOD.split("media/ps2").join("media/../x")) === null);
    check("parseProbe rejects themeUrl/testAsset mismatch",
        A.parseProbe(GOOD.replace(
            '"themeUrl":"file:///storage/1234-ABCD/Crystal/imports/esde/media/ps2/covers/x.png"',
            '"themeUrl":"file:///storage/1234-ABCD/Crystal/imports/esde/media/ps2/covers/y.png"')) === null);
    check("parseProbe rejects garbage", A.parseProbe("not json") === null);
    check("parseProbe rejects empty", A.parseProbe("") === null);
    // install + accessors
    check("no probe installed initially", A.probeInfo() === null && A.probeImageUrl() === "");
    A.loadProbeFromText(GOOD);
    check("probeInfo installed", A.probeInfo() !== null);
    check("probeImageUrl hands the exact file:// URL to QML",
        A.probeImageUrl() === "file:///storage/1234-ABCD/Crystal/imports/esde/media/ps2/covers/x.png");
    // async loadProbe through the fake XHR
    var probeNotified = 0;
    var epoch0 = A.probeEpoch();
    A.setProbeChangedHandler(function () { probeNotified++; });
    A.loadProbe("file:///themes/crystal-esde-probe.json");
    check("loadProbe issues an async GET", xhrLog.length > 0);
    completeXHR(xhrLog[xhrLog.length - 1], 200, GOOD);
    check("loadProbe installs the probe", A.probeImageUrl().indexOf("file:///storage/") === 0);
    check("probe change handler fired", probeNotified === 1);
    check("probe epoch bumped", A.probeEpoch() === epoch0 + 1);
    // invalid probe clears
    A.loadProbe("file:///themes/crystal-esde-probe.json");
    completeXHR(xhrLog[xhrLog.length - 1], 200, "garbage");
    check("invalid probe clears the install", A.probeInfo() === null && A.probeImageUrl() === "");
    // missing probe file clears
    A.loadProbeFromText(GOOD);
    A.loadProbe("file:///themes/crystal-esde-probe.json");
    completeXHR(xhrLog[xhrLog.length - 1], 404, "");
    check("missing probe file clears the install", A.probeInfo() === null);
    A.setProbeChangedHandler(null);
})();

// --- report --------------------------------------------------------------------
if (failures.length > 0) {
    console.error("\nFAILURES (" + failures.length + "):");
    failures.forEach(function (f) { console.error("  FAIL " + f); });
    process.exit(1);
}
console.log("\nAll CrystalAssets assertions passed.");
