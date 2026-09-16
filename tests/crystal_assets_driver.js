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

// --- report --------------------------------------------------------------------
if (failures.length > 0) {
    console.error("\nFAILURES (" + failures.length + "):");
    failures.forEach(function (f) { console.error("  FAIL " + f); });
    process.exit(1);
}
console.log("\nAll CrystalAssets assertions passed.");
