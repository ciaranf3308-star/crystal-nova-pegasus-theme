#!/usr/bin/env python3
"""Physical-media milestone tests: MediaTemplates logic + architecture guards.

Runs the Node.js driver (tests/media_templates_driver.js), which asserts:
  - exactly two platform families (gba, ps2); everything else unsupported
  - inspect view cycles (gba: front/back; ps2: front/spine/back/open)
  - artwork slot fallback chains (label/disc/case faces)
  - generated-face helpers (spine text, abbreviations)
  - template geometry sanity (label inside shell, disc inside tray)

Plus static architecture guards (no QML runtime needed):
  - authored SVG templates exist, parse, and avoid QtSvg-unsafe features
    (no filters/turbulence/masks/text elements)
  - renderers compose the templates (referenced paths resolve); the
    cartridge/case is never drawn from QML primitives
  - GameTile is pure box-art again (no PhysicalObject, no PhysicalMedia)
  - platform checks live only in MediaTemplates.js (no "gba"/"ps2"
    literals scattered through GameLibrary.qml, GameTile.qml, theme.qml)
  - new QML uses only existing CrystalTheme.js tokens (no invented colors)
  - no true-3D imports, no Socket references, no new audio subsystem
  - launch still flows through GameLibrary.launchCurrent (no game.launch()
    in the PhysicalMedia layer)
  - QML brace balance on new/modified files
  - JS import aliases match their uses (regression: the 74b8868 Nova
    freeze was a MediaTemplates-vs-MT alias mismatch)
  - Inspect input safety net: open() success flag, transition watchdog,
    B escape while busy/launching (regression: the stuck-busy freeze)
  - U3.2 cleanup: PS2 disc uses a genuine circular OpacityMask (no bare
    rounded-rect clip); BACK never re-shows the front cover; OPEN
    interior is authored (no exterior art wallpapered); GBA art label
    is a composed sticker (authored layout + vignette)

Run:
    python3 tests/test_physical_media.py
Requires: node for the driver (skipped with a warning when absent).
"""
import os
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRIVER = os.path.join(REPO, "tests", "media_templates_driver.js")
PM = os.path.join(REPO, "components", "PhysicalMedia")
PHYS = os.path.join(REPO, "assets", "physical")

# Authored template inventory: platform-owned artwork the renderers
# compose. Game textures are layered UNDER these; the renderers must
# never draw the objects from QML primitives instead.
EXPECTED_TEMPLATES = {
    "gba": ["shell-front.svg", "shell-back.svg", "shadow.svg",
            "label-frame.svg", "sheen.svg",
            "label-art-composition.svg", "label-art-vignette.svg"],
    "ps2": ["case-front.svg", "case-back.svg", "case-spine.svg",
            "case-open.svg", "disc.svg", "case-shadow.svg",
            "disc-mask.svg", "case-back-fallback.svg", "case-interior.svg"],
}

# SVG features QtSvg (Pegasus Qt 5.15) handles unreliably or not at all.
BANNED_SVG = ("<filter", "fegaussianblur", "feturbulence", "<mask", "<text")

EXPECTED_PM_FILES = {
    "MediaTemplates.js",
    "PhysicalObject.qml",
    "GbaCartridge.qml",
    "Ps2Case.qml",
    "PhysicalInspect.qml",
}

# QML files that may reference MediaTemplates but must not name platforms.
NO_PLATFORM_LITERAL_FILES = [
    os.path.join(REPO, "screens", "GameLibrary.qml"),
    os.path.join(REPO, "components", "GameTile.qml"),
    os.path.join(REPO, "theme.qml"),
]


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def check_authored_templates():
    # The authored-template visual method: every expected SVG exists,
    # parses as XML, and avoids SVG features QtSvg cannot render
    # (filters, turbulence, masks, text elements).
    count = 0
    for family, files in EXPECTED_TEMPLATES.items():
        for name in files:
            p = os.path.join(PHYS, family, name)
            assert os.path.isfile(p), "missing template asset: %s" % p
            try:
                ET.parse(p)
            except ET.ParseError as e:
                raise AssertionError("unparseable SVG %s: %s" % (p, e))
            low = read(p).lower()
            for banned in BANNED_SVG:
                assert banned not in low, \
                    "%s uses banned SVG feature %s" % (name, banned)
            count += 1
    print("ok - %d authored SVG templates (parse + QtSvg-safe)" % count)


def check_renderers_compose_templates():
    # Renderers must compose the authored templates — the visual method
    # forbids drawing cartridges/cases from QML rectangles. Proxy: each
    # renderer references its platform's template files, and template
    # asset paths referenced in QML resolve to real files.
    refs = {
        "GbaCartridge.qml": ("gba", ["shell-front.svg", "shell-back.svg",
                                     "label-frame.svg", "sheen.svg",
                                     "shadow.svg",
                                     "label-art-composition.svg",
                                     "label-art-vignette.svg"]),
        "Ps2Case.qml": ("ps2", ["case-front.svg", "case-back.svg",
                                "case-spine.svg", "case-open.svg",
                                "disc.svg", "case-shadow.svg",
                                "disc-mask.svg", "case-back-fallback.svg",
                                "case-interior.svg"]),
    }
    for qml, (family, files) in refs.items():
        src = read(os.path.join(PM, qml))
        for name in files:
            assert name in src, \
                "%s does not compose template %s" % (qml, name)
            assert os.path.isfile(os.path.join(PHYS, family, name)), \
                "%s references missing asset %s" % (qml, name)
    print("ok - renderers compose authored templates (no primitive-drawn objects)")


def check_disc_circular_mask():
    # U3.2 fix 1: disc artwork must be genuinely circular-masked
    # (OpacityMask over an authored disc-mask.svg) — the old rounded
    # Rectangle with clip:true does not guarantee circular clipping.
    src = read(os.path.join(PM, "Ps2Case.qml"))
    assert "QtGraphicalEffects" in src, "missing QtGraphicalEffects import"
    assert "OpacityMask" in src, "disc is not OpacityMask-masked"
    assert "disc-mask.svg" in src, "authored circular mask not used"
    # the old disc-art container (rounded rect + clip:true) is gone:
    # no clipping rect may remain inside the disc group
    disc_block = src[src.index("id: discGroup"):]
    assert "clip: true" not in disc_block, \
        "bare rounded-rect disc clipping path still present"
    # the authored rim/hub/sheen template stays layered above the art
    assert src.index("OpacityMask") < src.index('"disc.svg"'), \
        "disc.svg template must layer above the masked artwork"
    print("ok - PS2 disc uses a genuine circular OpacityMask")


def check_ps2_back_fallback():
    # U3.2 fix 2: BACK shows real back art, or a deliberate Crystal
    # back composition — the front cover must never reappear as back.
    src = read(os.path.join(PM, "Ps2Case.qml"))
    assert "backArt || root.frontArt" not in src, \
        "BACK still falls back to front art"
    assert "(root.backArt || root.frontArt)" not in src, \
        "BACK/interior still falls back to front art"
    assert "case-back-fallback.svg" in src, \
        "authored back-cover fallback layout not used"
    assert "backComposed" in src, "composed-back branch missing"
    print("ok - PS2 BACK never re-shows the front cover")


def check_ps2_interior_authored():
    # U3.2 fix 3: the open left panel is an authored case interior
    # (clips, moulding, debossed well) — exterior cover art is never
    # wallpapered inside the case.
    src = read(os.path.join(PM, "Ps2Case.qml"))
    assert "case-interior.svg" in src, "authored interior asset not used"
    open_block = src[src.index("OPEN: composed spread"):]
    assert "backArt" not in open_block, \
        "exterior back art still used in the OPEN view"
    print("ok - PS2 OPEN interior is authored, not wallpapered")


def check_gba_label_composition():
    # U3.2 fix 4: the "art" label path is a deliberate sticker
    # composition (authored layout + vignette + title zone), not a
    # blind crop with a UI bar pasted over it.
    src = read(os.path.join(PM, "GbaCartridge.qml"))
    assert "label-art-composition.svg" in src, \
        "authored sticker layout not used"
    assert "label-art-vignette.svg" in src, \
        "art-window vignette not used"
    # the old full-window blind crop (art Image filling the well via a
    # labelKind ternary) is gone — the "art" path is now a composed Item
    assert 'source: root.labelKind === "art" ? root.labelArt : ""' not in src, \
        "old blind-crop art fill still present"
    print("ok - GBA art label is a composed sticker, not a blind crop")


def check_tile_no_physical():
    # The 4x2 grid is pure production box-art again: no physical object
    # in tiles, selected or otherwise.
    src = read(os.path.join(REPO, "components", "GameTile.qml"))
    assert "PhysicalObject" not in src, \
        "GameTile still renders a physical object"
    assert "PhysicalMedia" not in src, \
        "GameTile still imports PhysicalMedia"
    print("ok - GameTile is pure box-art (no physical layer)")


def check_module_layout():
    actual = set(os.listdir(PM))
    assert EXPECTED_PM_FILES <= actual, \
        "missing PhysicalMedia files: %s" % (EXPECTED_PM_FILES - actual)
    print("ok - PhysicalMedia module layout (%d files)" % len(EXPECTED_PM_FILES))


def check_no_scattered_platform_checks():
    for p in NO_PLATFORM_LITERAL_FILES:
        src = read(p)
        # allow the import line itself; forbid string literals naming systems
        lines = [l for l in src.splitlines()
                 if "import" not in l and "MediaTemplates" not in l]
        body = "\n".join(lines)
        for lit in ('"gba"', "'gba'", '"ps2"', "'ps2'"):
            assert lit not in body, \
                "%s scatters platform literal %s" % (p, lit)
    print("ok - no platform literals outside MediaTemplates.js")


def check_theme_tokens_only():
    theme_src = read(os.path.join(REPO, "components", "CrystalTheme.js"))
    tokens = set(re.findall(r"^var\s+(\w+)", theme_src, re.M))
    tokens |= set(re.findall(r"^function\s+(\w+)", theme_src, re.M))
    checked = 0
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        for m in re.finditer(r"\bT\.(\w+)", src):
            assert m.group(1) in tokens, \
                "%s uses unknown theme token T.%s" % (name, m.group(1))
            checked += 1
    # modified shared files may also use T.* — they already did before
    print("ok - PhysicalMedia QML uses only existing CrystalTheme tokens "
          "(%d references)" % checked)


def check_no_true3d_no_socket():
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        low = src.lower()
        assert "qtquick3d" not in low and "qt3d" not in low, \
            "%s imports 3D modules" % name
        assert "socket" not in low, "%s references Socket" % name
    print("ok - no true-3D imports, no Socket references")


def check_no_new_audio():
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        assert "Audio" not in src and "SoundEffect" not in src, \
            "%s builds an audio subsystem" % name
    print("ok - no new audio subsystem (theme has no audio infra)")


def check_launch_path_untouched():
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        code = re.sub(r"//.*", "", src)  # comments may reference the path
        assert ".launch()" not in code, \
            "%s invokes launch directly (must go through GameLibrary)" % name
    lib = read(os.path.join(REPO, "screens", "GameLibrary.qml"))
    assert "game.launch()" in lib, "GameLibrary lost its game.launch() path"
    print("ok - launch still flows through GameLibrary.launchCurrent")


def check_braces():
    files = [os.path.join(PM, n) for n in EXPECTED_PM_FILES
             if n.endswith(".qml")]
    files += [os.path.join(REPO, "components", "GameTile.qml"),
              os.path.join(REPO, "components", "LibraryFooter.qml"),
              os.path.join(REPO, "screens", "GameLibrary.qml"),
              os.path.join(REPO, "theme.qml")]
    for p in files:
        src = read(p)
        # strip string literals to avoid brace false positives
        stripped = re.sub(r'"(?:[^"\\]|\\.)*"', '""', src)
        assert stripped.count("{") == stripped.count("}"), \
            "brace imbalance in %s" % p
    print("ok - brace balance on %d QML files" % len(files))


def check_qml_imports_sane():
    allowed_prefixes = ("QtQuick", "QtGraphicalEffects", '"', "'")
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        for m in re.finditer(r'^\s*import\s+([^\s;]+)', src, re.M):
            mod = m.group(1)
            ok = (mod.startswith("QtQuick") or mod.startswith("QtGraphicalEffects")
                  or mod.startswith('"') or mod.startswith("'"))
            assert ok, "%s has unexpected import %s" % (name, mod)
    print("ok - PhysicalMedia imports are QtQuick/QtGraphicalEffects/local only")


def check_js_import_alias_consistent():    # Regression guard for the 74b8868 Nova freeze: PhysicalInspect.qml
    # and PhysicalObject.qml imported MediaTemplates.js "as MT" but
    # referenced it as bare "MediaTemplates." — an undeclared identifier
    # under Pegasus Qt 5.15. Bindings threw ReferenceError (tile object
    # never activated) and open() threw after GameLibrary had already set
    # inspecting=true, permanently routing all keys into dead handlers.
    # Static logic tests never execute QML, so this alias mismatch is
    # asserted here instead.
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        for m in re.finditer(
                r'^\s*import\s+"([^"]+\.js)"\s+as\s+(\w+)', src, re.M):
            js_file, alias = m.group(1), m.group(2)
            base = js_file[:-3]  # "MediaTemplates.js" -> "MediaTemplates"
            for lm in re.finditer(r'(?<![\w])' + re.escape(base)
                                  + r'\.(?!js)', src):
                line = src[:lm.start()].count("\n") + 1
                # the import line itself and filename mentions in comments
                # are fine; any other bare-BaseName. reference is a bug
                context = src.split("\n")[line - 1]
                is_import = "import" in context and js_file in context
                assert is_import, \
                    "%s:%d uses '%s.' but the module is imported as '%s'" \
                    % (name, line, base, alias)
    print("ok - JS import aliases match their uses")


def check_inspect_input_safety():
    # Regression guard for the Nova Inspect freeze: entering Inspect must
    # never permanently trap input. The safety net is structural —
    # asserted statically here because no QML runtime exists in CI:
    #  - open() reports success/failure; GameLibrary only takes input
    #    ownership (inspecting=true) on success
    #  - a watchdog backs every transition; no animation-completion
    #    callback is the single point of failure for input recovery
    #  - beginClose() escapes even while busy/launching (B always exits)
    src = read(os.path.join(PM, "PhysicalInspect.qml"))
    assert "function open(game, shortName, fromRect)" in src
    assert "return false" in src and "return true" in src, \
        "open() must report success/failure"
    assert "busyWatchdog" in src, "transition watchdog missing"
    assert "hardClose()" in src, "jump-cut close path missing"
    m = re.search(r"function beginClose\(\) \{(.*?)\n    \}", src, re.S)
    assert m and "root.busy || root.launching" in m.group(1), \
        "beginClose must escape while busy/launching"
    lib = read(os.path.join(REPO, "screens", "GameLibrary.qml"))
    assert "if (inspectView.open(" in lib, \
        "GameLibrary must gate inspecting on open() success"
    print("ok - Inspect input safety net (watchdog + B escape + open() flag)")


def run_node_driver():
    node = shutil.which("node") or shutil.which("nodejs")
    if not node:
        print("SKIP: node not found; MediaTemplates driver not run")
        return
    p = subprocess.run([node, DRIVER], capture_output=True, text=True,
                       timeout=120, cwd=REPO)
    sys.stdout.write(p.stdout)
    if p.returncode != 0:
        sys.stderr.write(p.stderr)
        raise SystemExit("node driver failed (exit %d)" % p.returncode)


def main():
    check_module_layout()
    check_authored_templates()
    check_renderers_compose_templates()
    check_disc_circular_mask()
    check_ps2_back_fallback()
    check_ps2_interior_authored()
    check_gba_label_composition()
    check_tile_no_physical()
    check_no_scattered_platform_checks()
    check_theme_tokens_only()
    check_no_true3d_no_socket()
    check_no_new_audio()
    check_launch_path_untouched()
    check_braces()
    check_qml_imports_sane()
    check_js_import_alias_consistent()
    check_inspect_input_safety()
    run_node_driver()
    print("\nphysical-media tests passed")


if __name__ == "__main__":
    main()
