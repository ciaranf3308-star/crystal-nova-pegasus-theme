#!/usr/bin/env python3
"""Phase 1.6 tests: IconResolver logic + production PNG validation.

The resolver tests load the REAL components/IconResolver.js in a
QJSEngine and call iconFor() directly -- no reimplementation, no drift.

Checks:
  - known shortNames resolve to the expected asset
  - common aliases resolve correctly
  - unknown shortNames fall back safely ("" -> text glyph, no broken image)
  - the icon source does not change when the tile becomes selected
  - every mapped icon file actually exists
  - every final PNG is 512x512, RGBA, has real alpha transparency,
    and has visible non-transparent pixels
  - no obsolete _selected.png files remain

Usage:
    python3 tests/test_icon_resolver.py
    QML_PY=/path/to/python python3 tests/test_icon_resolver.py
"""
import glob
import os
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESOLVER = os.path.join(REPO, "components", "IconResolver.js")
ICON_DIR = os.path.join(REPO, "assets", "icons")

# (input shortName, expected icon filename, selected flag)
CASES = [
    # canonical names, mixed case
    ("gba", "gba.png", False),
    ("GBA", "gba.png", False),
    ("snes", "snes.png", False),
    ("ps1", "ps1.png", False),
    ("n64", "n64.png", False),
    ("dreamcast", "dreamcast.png", False),
    ("psp", "psp.png", False),
    ("nds", "nds.png", False),
    ("3ds", "3ds.png", False),
    ("wii", "wii.png", False),
    ("vita", "vita.png", False),
    # aliases from the Phase 1.6 brief
    ("game-boy", "gb.png", False),
    ("game boy", "gb.png", False),
    ("gameboy", "gb.png", False),
    ("gameboycolor", "gbc.png", False),
    ("game boy color", "gbc.png", False),
    ("gameboyadvance", "gba.png", False),
    ("game boy advance", "gba.png", False),
    ("famicom", "nes.png", False),
    ("nintendo entertainment system", "nes.png", False),
    ("supernintendo", "snes.png", False),
    ("super famicom", "snes.png", False),
    ("megadrive", "genesis.png", False),
    ("mega drive", "genesis.png", False),
    ("sega genesis", "genesis.png", False),
    ("sega cd", "segacd.png", False),
    ("mega-cd", "segacd.png", False),
    ("megacd", "segacd.png", False),
    ("32x", "sega32x.png", False),
    ("sega32x", "sega32x.png", False),
    ("sega 32x", "sega32x.png", False),
    ("psx", "ps1.png", False),
    ("playstation", "ps1.png", False),
    ("playstation1", "ps1.png", False),
    ("nintendo64", "n64.png", False),
    ("segasaturn", "saturn.png", False),
    ("dc", "dreamcast.png", False),
    ("pce", "pcengine.png", False),
    ("turbografx16", "pcengine.png", False),
    ("turbografx", "pcengine.png", False),
    ("tg16", "pcengine.png", False),
    ("TG-16", "pcengine.png", False),
    ("mame", "arcade.png", False),
    ("fbneo", "arcade.png", False),
    ("finalburnneo", "arcade.png", False),
    ("playstationportable", "psp.png", False),
    ("ds", "nds.png", False),
    ("nintendods", "nds.png", False),
    ("n3ds", "3ds.png", False),
    ("nintendo3ds", "3ds.png", False),
    ("playstation2", "ps2.png", False),
    ("gc", "gamecube.png", False),
    ("ngc", "gamecube.png", False),
    ("psvita", "vita.png", False),
    ("playstationvita", "vita.png", False),
    ("wii u", "wiiu.png", False),
    ("nintendoswitch", "switch.png", False),
    ("windows", "pc.png", False),
    ("steam", "pc.png", False),
    ("gamenative", "pc.png", False),
    # utility aliases
    ("favorites", "favourites.png", False),
    ("favourite", "favourites.png", False),
    ("favorite", "favourites.png", False),
    ("recentlyplayed", "recent.png", False),
    ("history", "recent.png", False),
    ("all games", "allgames.png", False),
    ("games", "allgames.png", False),
    ("library", "allgames.png", False),
    ("pokemon", "pokemon.png", False),
    ("pok\u00e9mon", "pokemon.png", False),
    ("moresystems", "more.png", False),
    ("collection", "collections.png", False),
    ("categories", "collections.png", False),
    # unknown -> safe fallback (empty string, tile shows text glyph)
    ("neogeo", "", False),
    ("zzzz-unknown", "", False),
    ("", "", False),
    # selected must NOT change the artwork (cream tile is the signal)
    ("gba", "gba.png", True),
    ("favourites", "favourites.png", True),
    ("32X", "sega32x.png", True),
]

EXPECTED_ICONS = {
    "3ds.png", "allgames.png", "arcade.png", "collections.png",
    "dreamcast.png", "favourites.png", "gamecube.png", "gb.png",
    "gba.png", "gbc.png", "genesis.png", "more.png", "n64.png",
    "nds.png", "nes.png", "pc.png", "pcengine.png", "pokemon.png",
    "ps1.png", "ps2.png", "psp.png", "recent.png", "saturn.png",
    "sega32x.png", "segacd.png", "snes.png", "switch.png", "vita.png",
    "wii.png", "wiiu.png",
}

failures = []


def load_resolver():
    from PySide6.QtCore import QCoreApplication
    from PySide6.QtQml import QJSEngine
    app = QCoreApplication.instance() or QCoreApplication([])
    engine = QJSEngine()
    with open(RESOLVER, encoding="utf-8") as f:
        src = f.read()
    val = engine.evaluate(src)
    if val.isError():
        raise RuntimeError(
            f"IconResolver.js error line {val.property('lineNumber').toInt()}: "
            f"{val.toString()}")
    fn = engine.evaluate("iconFor")
    if not fn.isCallable():
        raise RuntimeError("iconFor is not callable after evaluating IconResolver.js")
    return engine, fn


def main():
    print("IconResolver logic tests (real QJSEngine evaluation)")
    try:
        engine, icon_for = load_resolver()
    except Exception as e:
        print(f"  FAIL setup: {e}")
        sys.exit(1)

    for short_name, expected_file, selected in CASES:
        got = icon_for.call([short_name, selected]).toString()
        want = f"../assets/icons/{expected_file}" if expected_file else ""
        tag = f"iconFor({short_name!r}, selected={selected})"
        if got != want:
            failures.append((tag, f"got {got!r}, want {want!r}"))
            print(f"  FAIL {tag}")
        else:
            print(f"  PASS {tag}")

    print("\nIcon inventory tests")
    on_disk = {os.path.basename(p) for p in glob.glob(os.path.join(ICON_DIR, "*.png"))}
    if on_disk != EXPECTED_ICONS:
        missing = sorted(EXPECTED_ICONS - on_disk)
        extra = sorted(on_disk - EXPECTED_ICONS)
        failures.append(("inventory", f"missing={missing} extra={extra}"))
        print(f"  FAIL inventory: missing={missing} extra={extra}")
    else:
        print(f"  PASS inventory: exactly {len(EXPECTED_ICONS)} production icons")

    stale = [p for p in glob.glob(os.path.join(ICON_DIR, "*_selected.png"))]
    if stale:
        failures.append(("no _selected files", str(stale)))
        print(f"  FAIL obsolete _selected files remain: {stale}")
    else:
        print("  PASS no _selected.png files remain")

    print("\nPNG validation (512x512, RGBA, real alpha, visible pixels)")
    from PIL import Image
    import numpy as np
    for name in sorted(EXPECTED_ICONS):
        path = os.path.join(ICON_DIR, name)
        tag = f"png:{name}"
        try:
            with Image.open(path) as im:
                ok_size = im.size == (512, 512)
                ok_mode = im.mode == "RGBA"
                a = np.asarray(im)[:, :, 3]
                has_transparent = bool((a < 255).any())
                has_visible = bool((a > 8).any())
        except Exception as e:
            failures.append((tag, f"unreadable: {e}"))
            print(f"  FAIL {tag}: unreadable")
            continue
        problems = []
        if not ok_size:
            problems.append("not 512x512")
        if not ok_mode:
            problems.append(f"mode={im.mode}")
        if not has_transparent:
            problems.append("no transparent pixels")
        if not has_visible:
            problems.append("no visible pixels")
        if problems:
            failures.append((tag, ", ".join(problems)))
            print(f"  FAIL {tag}: {', '.join(problems)}")
        else:
            print(f"  PASS {tag}")

    print()
    if failures:
        print(f"{len(failures)} FAILED:")
        for name, why in failures:
            print(f"  - {name}: {why}")
        sys.exit(1)
    print(f"All resolver + PNG checks passed "
          f"({len(CASES)} resolve cases, {len(EXPECTED_ICONS)} icons).")


if __name__ == "__main__":
    main()
