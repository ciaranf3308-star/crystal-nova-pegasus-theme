#!/usr/bin/env python3
"""Physical-media milestone tests: MediaTemplates logic + architecture guards.

Runs the Node.js driver (tests/media_templates_driver.js), which asserts:
  - exactly two platform families (gba, ps2); everything else unsupported
  - inspect view cycles (gba: front/back; ps2: front/spine/back/open)
  - artwork slot fallback chains (label/disc/case faces)
  - generated-face helpers (spine text, abbreviations)
  - template geometry sanity (label inside shell, disc inside tray)

Plus static architecture guards (no QML runtime needed):
  - platform checks live only in MediaTemplates.js (no "gba"/"ps2"
    literals scattered through GameLibrary.qml, GameTile.qml, theme.qml)
  - new QML uses only existing CrystalTheme.js tokens (no invented colors)
  - no true-3D imports, no Socket references, no new audio subsystem
  - launch still flows through GameLibrary.launchCurrent (no game.launch()
    in the PhysicalMedia layer)
  - QML brace balance on new/modified files
  - JS import aliases match their uses (regression: the 74b8868 Nova
    freeze was a MediaTemplates-vs-MT alias mismatch)

Run:
    python3 tests/test_physical_media.py
Requires: node for the driver (skipped with a warning when absent).
"""
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRIVER = os.path.join(REPO, "tests", "media_templates_driver.js")
PM = os.path.join(REPO, "components", "PhysicalMedia")

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
    allowed_prefixes = ("QtQuick", '"', "'")
    for name in sorted(EXPECTED_PM_FILES):
        if not name.endswith(".qml"):
            continue
        src = read(os.path.join(PM, name))
        for m in re.finditer(r'^\s*import\s+([^\s;]+)', src, re.M):
            mod = m.group(1)
            ok = (mod.startswith("QtQuick") or mod.startswith('"')
                  or mod.startswith("'"))
            assert ok, "%s has unexpected import %s" % (name, mod)
    print("ok - PhysicalMedia imports are QtQuick/local only")


def check_js_import_alias_consistent():
    # Regression guard for the 74b8868 Nova freeze: PhysicalInspect.qml
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
    check_no_scattered_platform_checks()
    check_theme_tokens_only()
    check_no_true3d_no_socket()
    check_no_new_audio()
    check_launch_path_untouched()
    check_braces()
    check_qml_imports_sane()
    check_js_import_alias_consistent()
    run_node_driver()
    print("\nphysical-media tests passed")


if __name__ == "__main__":
    main()
