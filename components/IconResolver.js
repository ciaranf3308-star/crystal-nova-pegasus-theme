// Centralized collection -> icon resolver for Crystal Nova (Phase 1.6).
//
// Pegasus collection shortNames are not guaranteed to match our icon
// filenames, so every lookup goes through here. The input is normalized
// (lowercase, diacritics folded, spaces/hyphens/underscores stripped) and
// then matched against common alternative system names.
//
// Selection does NOT change the artwork: the cream selected tile is the
// selection signal, exactly as in the approved Crystal reference.
// SELECTED_VARIANTS is the hook for alternate selected art later -- it is
// intentionally empty for now, so iconFor(name, true) === iconFor(name, false).
//
// Unknown names resolve to "" so the tile falls back to its text glyph
// instead of showing a broken image.
//
// NOTE: no ".pragma library" here on purpose -- the file is plain script
// so the test suite can load it in a QJSEngine and verify the real logic.

var ICON_DIR = "../assets/icons/";

// Canonical icon bases shipped in assets/icons/.
var CANONICAL = {
    "3ds": "3ds",
    "allgames": "allgames",
    "arcade": "arcade",
    "collections": "collections",
    "dreamcast": "dreamcast",
    "favourites": "favourites",
    "gamecube": "gamecube",
    "gb": "gb",
    "gba": "gba",
    "gbc": "gbc",
    "genesis": "genesis",
    "more": "more",
    "n64": "n64",
    "nds": "nds",
    "nes": "nes",
    "pc": "pc",
    "pcengine": "pcengine",
    "pokemon": "pokemon",
    "ps1": "ps1",
    "ps2": "ps2",
    "psp": "psp",
    "recent": "recent",
    "saturn": "saturn",
    "sega32x": "sega32x",
    "segacd": "segacd",
    "snes": "snes",
    "switch": "switch",
    "vita": "vita",
    "wii": "wii",
    "wiiu": "wiiu"
};

// Normalized alias -> canonical base.
var ALIASES = {
    // Nintendo handhelds / consoles
    "gameboy": "gb",
    "gameboycolor": "gbc",
    "gameboyadvance": "gba",
    "famicom": "nes",
    "nintendoentertainmentsystem": "nes",
    "supernintendo": "snes",
    "superfamicom": "snes",
    "nintendo64": "n64",
    "ds": "nds",
    "nintendods": "nds",
    "n3ds": "3ds",
    "nintendo3ds": "3ds",
    "nintendoswitch": "switch",
    // Sega
    "megadrive": "genesis",
    "segagenesis": "genesis",
    "megacd": "segacd",
    "32x": "sega32x",
    "sega32x": "sega32x",
    "segasaturn": "saturn",
    "dc": "dreamcast",
    // Sony
    "psx": "ps1",
    "playstation": "ps1",
    "playstation1": "ps1",
    "playstation2": "ps2",
    "playstationportable": "psp",
    "psvita": "vita",
    "playstationvita": "vita",
    // NEC / arcade / misc
    "pce": "pcengine",
    "turbografx": "pcengine",
    "turbografx16": "pcengine",
    "tg16": "pcengine",
    "mame": "arcade",
    "fbneo": "arcade",
    "finalburnneo": "arcade",
    "gc": "gamecube",
    "ngc": "gamecube",
    "windows": "pc",
    "steam": "pc",
    "gamenative": "pc",
    // Utility tiles
    "favorites": "favourites",
    "favourite": "favourites",
    "favorite": "favourites",
    "recentlyplayed": "recent",
    "history": "recent",
    "games": "allgames",
    "library": "allgames",
    "moresystems": "more",
    "collection": "collections",
    "categories": "collections"
};

// Future hook for alternate selected-state artwork. Empty = the finished
// artwork is used in both states.
var SELECTED_VARIANTS = {};

function foldDiacritics(s) {
    return s
        .replace(/[\u00e0\u00e1\u00e2\u00e3\u00e4\u00e5]/g, "a")
        .replace(/[\u00e8\u00e9\u00ea\u00eb]/g, "e")
        .replace(/[\u00ec\u00ed\u00ee\u00ef]/g, "i")
        .replace(/[\u00f2\u00f3\u00f4\u00f5\u00f6\u00f8]/g, "o")
        .replace(/[\u00f9\u00fa\u00fb\u00fc]/g, "u")
        .replace(/[\u00fd\u00ff]/g, "y")
        .replace(/\u00f1/g, "n")
        .replace(/\u00e7/g, "c")
        .replace(/\u00e6/g, "ae")
        .replace(/\u0153/g, "oe")
        .replace(/\u00df/g, "ss");
}

function normalize(raw) {
    var s = String(raw === undefined || raw === null ? "" : raw).toLowerCase();
    s = foldDiacritics(s);
    return s.replace(/[^a-z0-9]/g, "");
}

function canonicalBase(shortName) {
    var key = normalize(shortName);
    if (!key) return "";
    if (ALIASES.hasOwnProperty(key)) key = ALIASES[key];
    return CANONICAL.hasOwnProperty(key) ? CANONICAL[key] : "";
}

function iconFor(shortName, selected) {
    var base = canonicalBase(shortName);
    if (!base) return "";
    if (selected && SELECTED_VARIANTS.hasOwnProperty(base))
        return ICON_DIR + SELECTED_VARIANTS[base] + ".png";
    return ICON_DIR + base + ".png";
}
