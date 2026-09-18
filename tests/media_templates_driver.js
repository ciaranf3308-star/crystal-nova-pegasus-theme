// Node driver for the MediaTemplates contract tests.
// Loaded by tests/test_physical_media.py. Exits 0 when every assertion
// passes, non-zero with a failure report otherwise.
"use strict";

const fs = require("fs");
const path = require("path");

const REPO = path.resolve(__dirname, "..");
// MediaTemplates.js starts with the QML-only `.pragma library` directive;
// strip it before evaluating under node.
let src = fs.readFileSync(
    path.join(REPO, "components", "PhysicalMedia", "MediaTemplates.js"), "utf8");
src = src.replace(/^\s*\.pragma library\s*/, "");
const mod = { exports: {} };
new Function("module", "exports", src)(mod, mod.exports);
const M = mod.exports;

let failures = [];
function check(name, cond, extra) {
    if (!cond) failures.push(name + (extra ? " :: " + extra : ""));
    else console.log("ok - " + name);
}
function eq(name, actual, expected) {
    check(name, actual === expected,
        "expected " + JSON.stringify(expected) + ", got " + JSON.stringify(actual));
}
function deepEq(name, actual, expected) {
    check(name, JSON.stringify(actual) === JSON.stringify(expected),
        "expected " + JSON.stringify(expected) + ", got " + JSON.stringify(actual));
}

// --- 1. platform families: gba + ps2 bespoke; cart/disc generic --------
eq("family gba", M.familyFor("gba"), "gba");
eq("family GBA case", M.familyFor("GBA"), "gba");
eq("family ps2", M.familyFor("ps2"), "ps2");
eq("family PS2 case/space", M.familyFor("  Ps2 "), "ps2");
eq("family snes cart", M.familyFor("snes"), "cart");
eq("family gbc cart", M.familyFor("gbc"), "cart");
eq("family nes cart", M.familyFor("nes"), "cart");
eq("family psx disc", M.familyFor("psx"), "disc");
eq("family ps1 disc", M.familyFor("ps1"), "disc");
eq("family dreamcast disc", M.familyFor("dreamcast"), "disc");
eq("family arcade framed", M.familyFor("arcade"), "");
eq("family empty", M.familyFor(""), "");
eq("family null", M.familyFor(null), "");
eq("family undefined", M.familyFor(undefined), "");
eq("family no substring match", M.familyFor("gba2"), "");
eq("family no long-name guess", M.familyFor("gameboyadvance"), "");
check("supports gba", M.supportsPhysical("gba") === true);
check("supports ps2", M.supportsPhysical("ps2") === true);
check("supports snes cart", M.supportsPhysical("snes") === true);
check("supports ps1 disc", M.supportsPhysical("ps1") === true);
check("rejects arcade", M.supportsPhysical("arcade") === false);
// Inspect stays exclusive to the two bespoke compositions
check("inspect gba", M.supportsInspect("gba") === true);
check("inspect ps2", M.supportsInspect("ps2") === true);
check("no inspect snes", M.supportsInspect("snes") === false);
check("no inspect ps1", M.supportsInspect("ps1") === false);

// --- 2. inspect view cycles -------------------------------------------------
deepEq("gba views", M.inspectViews("gba"), ["front", "back"]);
deepEq("ps2 views", M.inspectViews("ps2"), ["front", "spine", "back", "open"]);
deepEq("unknown views", M.inspectViews("snes"), []);
eq("view label front", M.viewLabel("front"), "FRONT");
eq("view label open", M.viewLabel("open"), "OPEN");
eq("view label unknown", M.viewLabel("manual"), "");

// gba cycle wraps front<->back
eq("gba next front", M.nextView("gba", "front"), "back");
eq("gba next back wraps", M.nextView("gba", "back"), "front");
eq("gba prev front wraps", M.prevView("gba", "front"), "back");
eq("gba prev back", M.prevView("gba", "back"), "front");
// ps2 cycle: front->spine->back->open->front
eq("ps2 next front", M.nextView("ps2", "front"), "spine");
eq("ps2 next spine", M.nextView("ps2", "spine"), "back");
eq("ps2 next back", M.nextView("ps2", "back"), "open");
eq("ps2 next open wraps", M.nextView("ps2", "open"), "front");
eq("ps2 prev front wraps", M.prevView("ps2", "front"), "open");
eq("ps2 prev open", M.prevView("ps2", "open"), "back");
// unknown family/view degrades
eq("next unknown family", M.nextView("snes", "front"), "");
eq("next unknown view falls back", M.nextView("gba", "manual"), "front");
eq("prev unknown view falls back", M.prevView("ps2", "manual"), "front");

// --- 3. artwork slot chains --------------------------------------------------
const full = { front: "u/front.png", spine: "u/spine.png", back: "u/back.png",
               media: "u/media.png", logo: "", screenshot: "", fullcover: "" };
const noMedia = { front: "u/front.png", spine: "", back: "", media: "",
                  logo: "", screenshot: "", fullcover: "" };
const bare = { front: "", spine: "", back: "", media: "",
               logo: "", screenshot: "", fullcover: "" };

eq("label prefers media", M.labelUrl(full, "tile.png"), "u/media.png");
eq("label falls to front", M.labelUrl(noMedia, "tile.png"), "u/front.png");
eq("label falls to tile chain", M.labelUrl(bare, "tile.png"), "tile.png");
eq("label empty when all missing", M.labelUrl(bare, ""), "");
eq("label null details", M.labelUrl(null, "tile.png"), "tile.png");

eq("disc uses media", M.discUrl(full), "u/media.png");
eq("disc empty without media", M.discUrl(noMedia), "");
eq("disc null details", M.discUrl(null), "");

eq("case front crystal", M.caseFaceUrl(full, "front", "tile.png"), "u/front.png");
eq("case front tile fallback", M.caseFaceUrl(bare, "front", "tile.png"), "tile.png");
eq("case spine crystal", M.caseFaceUrl(full, "spine", "tile.png"), "u/spine.png");
eq("case spine empty->generated", M.caseFaceUrl(bare, "spine", "tile.png"), "");
eq("case back crystal", M.caseFaceUrl(full, "back", "tile.png"), "u/back.png");
eq("case back empty->generated", M.caseFaceUrl(noMedia, "back", "tile.png"), "");

// --- 4. generated-face helpers ------------------------------------------------
eq("spine text basic", M.spineText("Mario Golf: Advance Tour"), "MARIO GOLF: ADVANCE TOUR");
eq("spine text collapses ws", M.spineText("  Ridge   Racer  V "), "RIDGE RACER V");
eq("spine text truncates", M.spineText("a".repeat(40)), "a".repeat(24).toUpperCase());
eq("spine text empty", M.spineText(""), "UNTITLED");
eq("spine text null", M.spineText(null), "UNTITLED");
check("spine max constant", M.SPINE_MAX === 24);

eq("abbr two words", M.abbrFor("Mario Golf"), "MG");
eq("abbr three words", M.abbrFor("Ridge Racer V"), "RR");
eq("abbr single word", M.abbrFor("Tetris"), "TE");
eq("abbr strips symbols", M.abbrFor("Pokémon!"), "PO");
eq("abbr empty", M.abbrFor(""), "??");
eq("abbr null", M.abbrFor(null), "??");

// --- 5. template geometry sanity -----------------------------------------------
// Geometry matches the authored SVG templates in assets/physical/:
// windows are the transparent areas renderers fill with game artwork.
check("gba template portrait-ish", M.GBA.w === 580 && M.GBA.h === 600);
check("gba label inside shell",
    M.GBA.labelX > 0 && M.GBA.labelY > 0 &&
    M.GBA.labelX + M.GBA.labelW < M.GBA.w &&
    M.GBA.labelY + M.GBA.labelH < M.GBA.h);
check("ps2 case dvd proportions",
    Math.abs(M.PS2.caseW / M.PS2.caseH - 0.714) < 0.02);
check("ps2 disc fits open tray",
    M.PS2.discD < M.PS2.openW && M.PS2.discD < M.PS2.openH);
check("ps2 spine narrower than case", M.PS2.spineW < M.PS2.caseW);
check("ps2 cover window inside case",
    M.PS2.coverX + M.PS2.coverW < M.PS2.caseW &&
    M.PS2.coverY + M.PS2.coverH < M.PS2.caseH);

// --- 6. label/disc render-kind classification ----------------------------------
check("gba label kind scan", M.labelKind({ media: "u" }, "") === "scan");
check("gba label kind art", M.labelKind({ front: "u" }, "") === "art");
check("gba label kind none", M.labelKind({}, "") === "none");
check("ps2 disc kind scan", M.discKind({ media: "u" }, "") === "scan");
check("ps2 disc kind art", M.discKind({ front: "u" }, "") === "art");
check("ps2 disc kind none", M.discKind({}, "") === "none");

if (failures.length > 0) {
    console.error("\nFAILURES (" + failures.length + "):");
    failures.forEach(function (f) { console.error("  FAIL " + f); });
    process.exit(1);
} else {
    console.log("\nall MediaTemplates assertions passed");
}
