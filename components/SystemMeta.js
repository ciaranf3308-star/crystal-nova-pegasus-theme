.pragma library

// Per-system editorial metadata for the library hero: maker, launch
// year, and the short script tagline the hero sets beside the physical
// composition. Keyed by normalized shortName (lowercase, trimmed).
// Unknown systems get empty strings — the hero simply omits those lines.
var SYSTEM_META = {
    "gba":   { maker: "NINTENDO", year: "2001", tagline: "Small Console.\nBig Adventures." },
    "gbc":   { maker: "NINTENDO", year: "1998", tagline: "Color Your World." },
    "gb":    { maker: "NINTENDO", year: "1989", tagline: "Play Anywhere." },
    "snes":  { maker: "NINTENDO", year: "1990", tagline: "Play It Loud." },
    "nes":   { maker: "NINTENDO", year: "1983", tagline: "Where It All Began." },
    "n64":   { maker: "NINTENDO", year: "1996", tagline: "Get N Or Get Out." },
    "gc":    { maker: "NINTENDO", year: "2001", tagline: "Born To Play." },
    "gamecube": { maker: "NINTENDO", year: "2001", tagline: "Born To Play." },
    "wii":   { maker: "NINTENDO", year: "2006", tagline: "Wii Would Like To Play." },
    "nds":   { maker: "NINTENDO", year: "2004", tagline: "Touch The Future." },
    "ds":    { maker: "NINTENDO", year: "2004", tagline: "Touch The Future." },
    "3ds":   { maker: "NINTENDO", year: "2011", tagline: "Depth Without Glasses." },
    "ps1":   { maker: "SONY", year: "1994", tagline: "Do Not Underestimate\nThe Power Of PlayStation." },
    "psx":   { maker: "SONY", year: "1994", tagline: "Do Not Underestimate\nThe Power Of PlayStation." },
    "ps2":   { maker: "SONY", year: "2000", tagline: "The Third Place." },
    "ps3":   { maker: "SONY", year: "2006", tagline: "This Is Living." },
    "psp":   { maker: "SONY", year: "2004", tagline: "Portable Play." },
    "vita":  { maker: "SONY", year: "2011", tagline: "Never Stop Playing." },
    "psvita":{ maker: "SONY", year: "2011", tagline: "Never Stop Playing." },
    "genesis": { maker: "SEGA", year: "1988", tagline: "To Be This Good\nTakes Ages." },
    "megadrive": { maker: "SEGA", year: "1988", tagline: "To Be This Good\nTakes Ages." },
    "saturn": { maker: "SEGA", year: "1994", tagline: "The Future Is Here." },
    "dreamcast": { maker: "SEGA", year: "1998", tagline: "It's Thinking." },
    "segacd": { maker: "SEGA", year: "1991", tagline: "Welcome To The\nNext Level." },
    "32x":   { maker: "SEGA", year: "1994", tagline: "32 Bits Of Power." },
    "gamegear": { maker: "SEGA", year: "1990", tagline: "Full Color\nPortable Power." },
    "mastersystem": { maker: "SEGA", year: "1985", tagline: "The Challenge\nWill Always Be There." },
    "arcade": { maker: "ARCADE", year: "", tagline: "Insert Coin." },
    "mame":  { maker: "ARCADE", year: "", tagline: "Insert Coin." },
    "neogeo": { maker: "SNK", year: "1990", tagline: "The Future Is Now." },
    "pce":   { maker: "NEC", year: "1987", tagline: "Small Wonder." },
    "pcengine": { maker: "NEC", year: "1987", tagline: "Small Wonder." },
    "tg16":  { maker: "NEC", year: "1987", tagline: "Small Wonder." },
    "atari2600": { maker: "ATARI", year: "1977", tagline: "Have You Played\nAtari Today?" },
    "lynx":  { maker: "ATARI", year: "1989", tagline: "Portable Power." }
};

function metaFor(shortName) {
    var k = (shortName || "").toString().trim().toLowerCase();
    if (SYSTEM_META.hasOwnProperty(k)) return SYSTEM_META[k];
    return { maker: "", year: "", tagline: "" };
}

// Node.js export for the test harness (harmless under QML).
try {
    if (typeof module !== "undefined" && module.exports) {
        module.exports = { SYSTEM_META: SYSTEM_META, metaFor: metaFor };
    }
} catch (e) { /* QML: module is undefined */ }
