#!/usr/bin/env python3
"""Phase 1.7 tests: CrystalTheme constants, display-name resolver, and
hero-measured component inventory.

Loads the REAL components/CrystalTheme.js in a QJSEngine and calls
displayNameFor() directly -- no reimplementation, no drift.

Checks:
  - displayNameFor maps raw Pegasus names to the short intentional labels
    the hero uses (GBA, PS2, PSP, GAMECUBE, PC ENGINE, ...)
  - geometry constants are sane (positive, inside the 1280x960 canvas,
    grid tiles do not overlap)
  - palette entries are valid #rrggbb colors
  - hero-measured components exist: Keycap.qml, TileFrame.qml,
    SelectedMarks.qml
  - the bundled font + OFL licence exist

Usage:
    python3 tests/test_crystal_theme.py
    QML_PY=/path/to/python python3 tests/test_crystal_theme.py
"""
import os
import re
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME_JS = os.path.join(REPO, "components", "CrystalTheme.js")

# (shortName, long name, expected display label)
DISPLAY_CASES = [
    ("gba", "Game Boy Advance", "GBA"),
    ("snes", "Super Nintendo", "SNES"),
    ("ps1", "PlayStation", "PS1"),
    ("psx", "PlayStation", "PS1"),
    ("n64", "Nintendo 64", "N64"),
    ("dreamcast", "Dreamcast", "DREAMCAST"),
    ("psp", "PlayStation Portable", "PSP"),
    ("arcade", "Arcade", "ARCADE"),
    ("mame", "MAME", "ARCADE"),
    ("nds", "Nintendo DS", "NDS"),
    ("ds", "Nintendo DS", "NDS"),
    ("ps2", "PlayStation 2", "PS2"),
    ("gamecube", "GameCube", "GAMECUBE"),
    ("gc", "GameCube", "GAMECUBE"),
    ("tg16", "PC Engine", "PC ENGINE"),
    ("pcengine", "PC Engine", "PC ENGINE"),
    ("genesis", "Sega Genesis", "GENESIS"),
    ("megadrive", "Mega Drive", "GENESIS"),
    ("32x", "Sega 32X", "32X"),
    ("segacd", "Sega CD", "SEGA CD"),
    ("nes", "Nintendo Entertainment System", "NES"),
    ("gb", "Game Boy", "GB"),
    ("gbc", "Game Boy Color", "GBC"),
    ("saturn", "Sega Saturn", "SATURN"),
    ("wii", "Nintendo Wii", "WII"),
    ("3ds", "Nintendo 3DS", "3DS"),
    ("vita", "PlayStation Vita", "PS VITA"),
    ("wiiu", "Nintendo Wii U", "WII U"),
    # case-insensitivity
    ("GBA", "Game Boy Advance", "GBA"),
    ("Dreamcast", "Dreamcast", "DREAMCAST"),
    # long-name fallback when shortName is empty/unknown
    ("", "Nintendo Entertainment System", "NES"),
    ("", "Game Boy Advance", "GBA"),
    # unknown names pass through uppercased
    ("openbor", "OpenBOR", "OPENBOR"),
]

failures = []


def check(name, cond, detail=""):
    status = "ok" if cond else "FAIL"
    print(f"  [{status}] {name}" + (f" -- {detail}" if detail and not cond else ""))
    if not cond:
        failures.append(name)


def load_theme():
    from PySide6.QtCore import QCoreApplication
    from PySide6.QtQml import QJSEngine
    app = QCoreApplication.instance() or QCoreApplication([])
    engine = QJSEngine()
    with open(THEME_JS, encoding="utf-8") as f:
        src = f.read()
    val = engine.evaluate(src)
    if val.isError():
        raise RuntimeError(
            f"CrystalTheme.js error line {val.property('lineNumber').toInt()}: "
            f"{val.toString()}")
    return engine


def main():
    print("displayNameFor() cases (real QJSEngine evaluation)")
    engine = load_theme()
    fn = engine.evaluate("displayNameFor")
    if not fn.isCallable():
        raise RuntimeError("displayNameFor is not callable after evaluating CrystalTheme.js")
    for short, name, want in DISPLAY_CASES:
        got = fn.call([short, name]).toString()
        check(f"displayNameFor({short!r}, {name!r}) == {want!r}", got == want,
              f"got {got!r}")

    print("geometry constants")
    g = lambda n: engine.evaluate(n).toNumber()
    W, H = g("canvasW"), g("canvasH")
    check("canvas is 1280x960", W == 1280 and H == 960, f"got {W}x{H}")
    check("margin positive", g("margin") > 0)
    check("tile size positive", g("tileW") > 0 and g("tileH") > 0)
    # tiles must sit inside the canvas without overlapping
    for row in range(3):
        for col in range(3):
            x = g("gridX") + col * (g("tileW") + g("colGap"))
            y = g("gridY") + row * (g("tileH") + g("rowGap"))
            inside = x >= 0 and y >= 0 and x + g("tileW") <= W and y + g("tileH") <= H
            check(f"tile ({col},{row}) inside canvas", inside, f"x={x} y={y}")
    # no overlap between neighbours
    pitch_x = g("tileW") + g("colGap")
    pitch_y = g("tileH") + g("rowGap")
    check("columns do not overlap", pitch_x >= g("tileW"))
    check("rows do not overlap", pitch_y >= g("tileH"))
    # header/footer dividers span the margins
    check("header divider inside canvas",
          g("headerDividerY") > 0 and g("headerDividerY") < H)
    check("footer divider below grid",
          g("footerDividerY") > g("gridY") + 3 * g("tileH"))
    # keycaps inside canvas
    for kx in ("keycapL1X", "keycapR1X"):
        kx0 = g(kx)
        check(f"{kx} keycap inside canvas",
              kx0 >= 0 and kx0 + g("keycapW") <= W, f"x={kx0}")

    print("palette")
    hexre = re.compile(r"^#[0-9a-fA-F]{6}$")
    for name in ("background tileFill tileBorder tileInk cream creamInk "
                 "primaryInk divider keycapFill keycapInk selectedOutline "
                 "batteryFrame batteryFill").split():
        v = engine.evaluate(name).toString()
        check(f"palette.{name} is #rrggbb", bool(hexre.match(v)), f"got {v!r}")

    print("component + font inventory")
    for rel in ("components/Keycap.qml",
                "components/TileFrame.qml",
                "components/SelectedMarks.qml",
                "components/CrystalTheme.js",
                "components/Header.qml",
                "components/FooterHints.qml",
                "components/SystemTile.qml",
                "components/SystemGrid.qml",
                "components/BatteryIndicator.qml",
                # Phase 2 library components
                "components/GameTile.qml",
                "components/GameGrid.qml",
                "components/GameFallbackArt.qml",
                "components/LibraryFooter.qml",
                "screens/GameLibrary.qml",
                "fonts/DepartureMono-Regular.otf",
                "fonts/OFL.txt"):
        check(rel + " exists", os.path.isfile(os.path.join(REPO, rel)))
    # OFL licence actually mentions the licence
    with open(os.path.join(REPO, "fonts", "OFL.txt"), encoding="utf-8") as f:
        lic = f.read()
    check("OFL.txt is the SIL Open Font License",
          "SIL Open Font License" in lic)

    print("phase 2 library geometry")
    # 4x2 grid fits between header and footer inside the canvas margins
    cw, ch = g("libCoverW"), g("libCoverH")
    gx, gy = g("libGridX"), g("libGridY")
    cols, rows = g("libCols"), g("libRows")
    check("library is 4x2", cols == 4 and rows == 2, f"{cols}x{rows}")
    check("page size is 8", g("libPageSize") == cols * rows)
    gridW = cols * cw + (cols - 1) * g("libColGap")
    gridH = rows * ch + (rows - 1) * g("libRowGap")
    check("library grid inside horizontal margins",
          gx >= g("margin") and gx + gridW <= W - g("margin"),
          f"x={gx} w={gridW}")
    check("library grid below header",
          gy >= g("headerH"), f"y={gy}")
    check("library grid above title area",
          gy + gridH <= g("libTitleY"), f"bottom={gy + gridH}")
    check("title area above footer divider",
          g("libTitleY") + g("libTitleH") <= g("footerDividerY"),
          f"title bottom={g('libTitleY') + g('libTitleH')}")
    # tile helper functions agree with the constants
    check("tile helpers consistent",
          engine.evaluate("libTileX(0)").toNumber() == gx and
          engine.evaluate("libTileX(3)").toNumber() ==
          gx + 3 * (cw + g("libColGap")) and
          engine.evaluate("libTileY(1)").toNumber() ==
          gy + 1 * (ch + g("libRowGap")))

    print()
    if failures:
        print(f"{len(failures)} FAILURES")
        return 1
    print("all CrystalTheme tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
