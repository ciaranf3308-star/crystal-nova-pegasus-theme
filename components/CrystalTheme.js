.pragma library

// Crystal Nova — centralized production constants for Phase 1.7.
//
// Every number here was measured from the approved hero reference
// (reference/approved-crystal-nova-ui.png, normalized to 1280x960 in
// comparison/hero-screen-1280x960.png). Do not eyeball new values:
// re-measure the hero and update this file, then re-run the overlay
// comparison in comparison/.

// ---------------------------------------------------------------- palette
var background      = "#0a1929"; // very dark navy screen
var tileFill        = "#0e2236"; // unselected tile fill
var tileBorder      = "#7ba7d9"; // muted steel-blue tile frame
var tileInk         = "#d7e3ec"; // pale icy label text on dark tiles
var cream           = "#f0ebdc"; // selected tile fill (warm ivory)
var creamInk        = "#1b2c4e"; // dark navy ink on the cream tile
var primaryInk      = "#e9f1f6"; // muted white: CRYSTAL brand, clock
var divider         = "#8fa5b8"; // header / footer hairlines
var keycapFill      = "#f0ebdc"; // warm ivory: matches selected-tile cream
var keycapInk       = "#1b2c4e"; // footer keycap glyphs
var selectedOutline = "#081425"; // subtle dark outline around cream tile
var batteryFrame    = "#9fb2c2"; // battery shell
var batteryFill     = "#dfe9f1"; // battery charge segments
var batteryLow      = "#c46a5a"; // low-battery fill

// ---------------------------------------------------------------- geometry
var canvasW = 1280;
var canvasH = 960;
var margin  = 60;                // outer content margin (dividers, header)

// Header (measured: CRYSTAL x62-275 y44-71; clock ends x1068;
// battery x1105-1175 y39-71; divider y84-88 x60-1219)
var headerH          = 92;
var headerDividerY   = 85;
var headerDividerH   = 3;
var brandX           = 59;         // glyph left bearing puts ink at 62
var brandBaselineY   = 71;       // cap-height top 44
var clockRightX      = 1068;
var clockBaselineY   = 70;
var batteryX         = 1105;
var batteryY         = 39;
var batteryW         = 70;
var batteryH         = 32;

// Grid (measured tile pitches: 371px horizontal, ~224px vertical;
// grid origin at tile-1 top-left)
var tileW   = 360;
var tileH   = 210;
var gridX   = 61;                // left edge of column 1
var gridY   = 119;               // top edge of row 1
var colGap  = 11;                // 371 - 360
var rowGap  = 16;                // ~226 - 210

function tileX(col) { return gridX + col * (tileW + colGap); }
function tileY(row) { return gridY + row * (tileH + rowGap); }

// Unselected tile frame: open corners. Border segments stop 8px short of
// each corner; a 5x5 registration dot sits in every corner gap.
var frameBorderW = 3;
var frameCornerCut = 8;
var frameDotSize = 5;

// Selected (cream) tile: four dark "viewfinder" corner brackets, inset 7px
// from the tile edges, 8px-thick arms, 32px long.
var markInset = 7;
var markThick = 8;
var markLen   = 32;

// Icon presentation: production art is large and confident, optically
// centred in the upper part of the tile, clear of the frame and label.
// The 512px sources carry ~76% content; a 230px square display puts the
// artwork at the hero's ~200px visual width.
var iconSize = 240;
var iconCenterYOffset = -14;      // optical: icons sit a touch high
// Per-icon optical corrections (multiplier on iconSize).
var iconScale = {
    "arcade": 0.62,              // hero's cabinet is small and tall
    "mame": 0.62,
    "fba": 0.62,
    "fbneo": 0.62
};

function iconScaleFor(shortName) {
    var k = (shortName || "").toString().trim().toLowerCase();
    return iconScale.hasOwnProperty(k) ? iconScale[k] : 1.0;
}

// Tile labels: glyph cap top sits ~18px above the tile bottom edge
// (measured: SNES glyphs at y292-310 in a tile ending at y329).
var labelBottomMargin = 2;

// Footer (measured: divider y805-809 x60-1219; keycaps y828-869;
// L1 keycap x71-153, RECENT x188-320; R1 keycap x851-931,
// FAVOURITES x964-1175)
var footerH        = 92;
var footerDividerY = 806;        // relative to footer top (footer sits at 868)
var footerDividerH = 3;
var keycapY        = 22;          // 828 abs, relative to the footer divider
var keycapW        = 82;
var keycapH        = 41;
var keycapL1X      = 71;
var recentX        = 185;        // glyph left bearing puts ink at 188
var keycapR1X      = 851;
var favouritesX   = 961;        // glyph left bearing puts ink at 964

// ---------------------------------------------------------------- typography
// Departure Mono (SIL OFL 1.1, Helena Zhang) — bundled in fonts/.
// Pixel-perfect at 11px increments; sizes below were matched to the hero's
// measured cap heights (title 27px, footer 22px, tile labels 18px).
var fontTitlePx  = 36;   // CRYSTAL brand + clock
var fontFooterPx = 30;   // RECENT / FAVOURITES
var fontLabelPx  = 26;   // tile system labels
var titleLetterSpacing  = 10;
var footerLetterSpacing = 3;
var labelLetterSpacing  = 2;

// ----------------------------------------------------------------
// Library hero (rebuilt 2026-09-19): two-panel 4:3 library.
// Left hero (emotional): x32-736 (55%). Right grid (browsing):
// x768-1248 (37.5%). No framed panel, no heavy chrome.
// ----------------------------------------------------------------
// Left hero panel
var heroLeftX = 32;
var heroLeftW = 704;             // 32..736
var heroTopY  = 100;
var heroKickerPx = 16;
var heroKickerY  = 116;
var sysTitlePx = 64;             // responsive: shrinks for long names
var sysTitleY  = 138;
var sysSubPx   = 20;
var sysSubY    = 210;
var taglinePx  = 20;
var compY      = 248;            // physical-media composition zone
var compH      = 360;
var selKickerY = 628;
var selTitlePx = 34;
var selTitleY  = 652;
var metaPx     = 17;
var metaY      = 698;
var metaW      = 640;
var descPx     = 17;
var descY      = 722;
var descW      = 640;
var shotsX     = 32;
var shotsY     = 790;
var shotSize   = 76;

// Right grid: 3x3, no panel frame. Tiles are art-dominant.
var panelX = 768;                // (legacy: grid now frameless)
var panelY = 108;
var panelW = 480;
var panelH = 728;
var panelTopY = 124;

// Grid: 3x3 tiles; cover art dominates, title is secondary.
// 480px wide: 3x148 + 2x18 gaps = 480. Art 148x182.
var libCols   = 3;
var libRows   = 3;
var libPageSize = 9;
var gtileArtW = 148;
var gtileArtH = 182;
var gtileTitleH = 32;
var gtileColGap = 18;
var gtileRowGap = 16;
var libGridX  = 768;
var libGridY  = 168;

function libTileX(col) { return libGridX + col * (gtileArtW + gtileColGap); }
function libTileY(row) { return libGridY + row * (gtileArtH + gtileTitleH + gtileRowGap); }

var pageY = 800;                 // page indicator baseline row

// Library footer divider.
var libFooterDividerY = 868;

// Game tile frame: dark inner edge + cream outer frame on selection,
// with the same viewfinder corner-bracket language as the system tiles.
var gameFrameW = 3;
var gameSelFrameW = 5;
var gameMarkInset = 8;
var gameMarkThick = 7;
var gameMarkLen = 28;

// Fallback card typography
var fallbackAbbrPx = 40;
var fallbackTitlePx = 20;

// ---------------------------------------------------------------- display names
// Central resolver: raw Pegasus collection names become the short,
// intentional labels the hero uses (GBA, PS2, PSP, GAMECUBE, PC ENGINE).
// IconResolver.js keeps mapping artwork; this maps the visible label.
var DISPLAY_NAMES = {
    "gba": "GBA", "gbc": "GBC", "gb": "GB",
    "snes": "SNES", "nes": "NES",
    "n64": "N64", "gc": "GAMECUBE", "gamecube": "GAMECUBE", "wii": "WII",
    "wiiu": "WII U", "switch": "SWITCH",
    "ps1": "PS1", "psx": "PS1", "ps2": "PS2", "ps3": "PS3",
    "psp": "PSP", "vita": "PS VITA", "psvita": "PS VITA",
    "dreamcast": "DREAMCAST", "saturn": "SATURN",
    "genesis": "GENESIS", "megadrive": "GENESIS", "md": "GENESIS",
    "32x": "32X", "segacd": "SEGA CD", "mega-cd": "SEGA CD", "megacd": "SEGA CD",
    "mastersystem": "MASTER SYSTEM", "sms": "MASTER SYSTEM",
    "gamegear": "GAME GEAR", "gg": "GAME GEAR",
    "neogeo": "NEO GEO", "ngp": "NEO GEO POCKET", "ngpc": "NEO GEO POCKET",
    "nds": "NDS", "ds": "NDS", "3ds": "3DS",
    "pce": "PC ENGINE", "pcengine": "PC ENGINE", "tg16": "PC ENGINE",
    "sgx": "SUPERGRAFX",
    "arcade": "ARCADE", "mame": "ARCADE", "fba": "ARCADE", "fbneo": "ARCADE",
    "atari2600": "ATARI 2600", "atari7800": "ATARI 7800",
    "atarilynx": "LYNX", "lynx": "LYNX", "jaguar": "JAGUAR",
    "colecovision": "COLECOVISION", "intellivision": "INTELLIVISION",
    "amiga": "AMIGA", "c64": "C64", "zx": "ZX SPECTRUM", "zxspectrum": "ZX SPECTRUM",
    "msx": "MSX", "msx2": "MSX2",
    "wonderswan": "WONDERSWAN", "ws": "WONDERSWAN",
    "ngage": "N-GAGE", "xbox": "XBOX", "xbox360": "XBOX 360",
    "ports": "PORTS", "pc": "PC", "windows": "PC", "dos": "DOS",
    "scummvm": "SCUMMVM", "tic80": "TIC-80", "pico8": "PICO-8",
    // full long names (normalized: lowercase, separators stripped), used
    // when Pegasus reports an empty shortName
    "gameboyadvance": "GBA", "gameboycolor": "GBC", "gameboy": "GB",
    "supernintendo": "SNES", "superfamicom": "SNES",
    "nintendoentertainmentsystem": "NES", "famicom": "NES",
    "nintendo64": "N64", "nintendogamecube": "GAMECUBE",
    "nintendowii": "WII", "nintendowiiu": "WII U",
    "nintendoswitch": "SWITCH", "nintendods": "NDS", "nintendo3ds": "3DS",
    "playstation": "PS1", "playstation2": "PS2", "playstation3": "PS3",
    "playstationportable": "PSP", "playstationvita": "PS VITA",
    "segagenesis": "GENESIS", "segamegadrive": "GENESIS",
    "segasaturn": "SATURN", "segadreamcast": "DREAMCAST",
    "sega32x": "32X", "segacd": "SEGA CD", "segamegacd": "SEGA CD",
    "pcengine": "PC ENGINE", "turbografx16": "PC ENGINE",
    "neogeo": "NEO GEO", "neogeopocket": "NEO GEO POCKET",
    "atari2600": "ATARI 2600", "atari7800": "ATARI 7800",
    "atarilynx": "LYNX", "atarijaguar": "JAGUAR"
};

function displayNameFor(shortName, name) {
    var raw = (shortName || "").toString().trim().toLowerCase();
    if (DISPLAY_NAMES.hasOwnProperty(raw)) return DISPLAY_NAMES[raw];
    // try the long name: "Nintendo Entertainment System" -> "NES"
    var n = (name || "").toString().trim().toLowerCase().replace(/[^a-z0-9]+/g, "");
    if (DISPLAY_NAMES.hasOwnProperty(n)) return DISPLAY_NAMES[n];
    var s = (shortName || name || "").toString().trim().toUpperCase();
    return s.length > 12 ? s.substring(0, 12) : s;
}
