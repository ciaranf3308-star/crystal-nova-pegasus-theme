#!/usr/bin/env python3
"""User-colors acceptance tests: crystal-user-colors.json contract.

Extracts loadUserColors() VERBATIM from theme.qml (no reimplementation)
and runs it in a real QML engine against a colors file placed where the
Manager app writes it (themes root == repo parent here, simulated by a
temp subdir so "../crystal-user-colors.json" resolves inside the repo).

Checks the three acceptance cases:
  - no file        -> exact theme defaults, custom flags false
  - valid file     -> bases + derived ramp update, flags true
  - partial file   -> only present + valid keys applied
  - malformed file -> defaults kept, no crash (garbage, empty,
                      wrong version, bad hex, non-object JSON)

Theme defaults (NOT Manager defaults):
  background #0a1929, accent #7ba7d9, cream #f0ebdc, joystick #ffd23f

Usage:
    QML_PY=/path/to/python-with-PySide6 python3 tests/test_user_colors.py

Needs QML_XHR_ALLOW_FILE_READ=1 (set below): Qt 6.5+ disables XHR reads
of local files by default; the real Pegasus build (Qt 5, same as the
existing crystal-media-bridge.json XHR path) allows them.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import textwrap

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QML_XHR_ALLOW_FILE_READ", "1")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QML_PY = os.environ.get("QML_PY", sys.executable)
TMPDIR = os.path.join(REPO, ".tmp-colortest")
TEST_QML = os.path.join(TMPDIR, "__LoadTest.qml")
COLORS_FILE = os.path.join(REPO, "crystal-user-colors.json")

DEFAULTS = {"background": "#0a1929", "accent": "#7ba7d9",
            "cream": "#f0ebdc", "joystick": "#ffd23f"}


def extract_loader():
    src = open(os.path.join(REPO, "theme.qml")).read()
    start = src.index("function loadUserColors()")
    i = src.index("{", start)
    depth = 0
    for j in range(i, len(src)):
        depth += (src[j] == "{") - (src[j] == "}")
        if depth == 0:
            end = j + 1
            break
    fn = src[start:end]
    assert "crystal-user-colors.json" in fn and "CrystalColors" in fn, \
        "loadUserColors not found in theme.qml"
    return fn


def write_harness(fn):
    os.makedirs(TMPDIR, exist_ok=True)
    qml = textwrap.dedent('''\
        import QtQuick 2.12
        import "../components"
        QtObject {
        %s
            Component.onCompleted: {
                loadUserColors()
                // XHR is async; wait, then snapshot the singleton and quit.
                var t = Qt.createQmlObject(
                    'import QtQuick 2.12; Timer { interval: 800; repeat: false; running: true }', this)
                t.triggered.connect(function() {
                    var snap = {
                        background: "" + CrystalColors.background,
                        accent: "" + CrystalColors.accent,
                        cream: "" + CrystalColors.cream,
                        joystick: "" + CrystalColors.joystick,
                        tile: "" + CrystalColors.tile,
                        frame: "" + CrystalColors.frame,
                        creamInk: "" + CrystalColors.creamInk,
                        amber: "" + CrystalColors.amber,
                        backgroundCustom: CrystalColors.backgroundCustom,
                        accentCustom: CrystalColors.accentCustom,
                        creamCustom: CrystalColors.creamCustom,
                        joystickCustom: CrystalColors.joystickCustom
                    }
                    console.log("SNAPSHOT " + JSON.stringify(snap))
                    Qt.quit()
                })
            }
        }
        ''') % textwrap.indent(fn, "    ")
    open(TEST_QML, "w").write(qml)


def run_case(name, file_content):
    if file_content is None:
        if os.path.exists(COLORS_FILE):
            os.remove(COLORS_FILE)
    else:
        open(COLORS_FILE, "w").write(file_content)
    p = subprocess.run([QML_PY, "-c", """
import sys
from PySide6.QtCore import QUrl, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
app = QGuiApplication([])
eng = QQmlApplicationEngine()
eng.load(QUrl.fromLocalFile(%r))
if not eng.rootObjects():
    sys.exit(2)
QTimer.singleShot(10000, app.quit)  # safety: never hang
sys.exit(app.exec())
""" % TEST_QML], capture_output=True, text=True, timeout=60)
    out = (p.stdout or "") + (p.stderr or "")
    m = re.search(r"SNAPSHOT (\{.*\})", out)
    if not m:
        raise AssertionError("%s: engine produced no snapshot\n%s"
                             % (name, out[-1500:]))
    return json.loads(m.group(1))


def is_default(r):
    return all(r[k] == v for k, v in DEFAULTS.items()) and not any(
        r[k + "Custom"] for k in DEFAULTS)


def check(name, cond, detail=""):
    print(("  [ok] " if cond else "  [FAIL] ") + name)
    if not cond:
        raise AssertionError(name + " " + str(detail))


def main():
    print("user colors: crystal-user-colors.json contract")
    write_harness(extract_loader())
    try:
        # 1. no file -> exact theme defaults
        r = run_case("no-file", None)
        check("no file keeps exact theme defaults", is_default(r), r)
        check("no file: derived tile is default literal",
              r["tile"] == "#0e2236", r["tile"])

        # 2. valid four-color file -> bases + derived ramp update
        r = run_case("valid", json.dumps({
            "version": 1, "background": "#101418", "accent": "#ff0000",
            "cream": "#00ff00", "joystick": "#0000ff", "updated": 123}))
        check("valid: background applied", r["background"] == "#101418")
        check("valid: accent applied", r["accent"] == "#ff0000")
        check("valid: cream applied", r["cream"] == "#00ff00")
        check("valid: joystick applied", r["joystick"] == "#0000ff")
        check("valid: all custom flags set",
              all(r[k + "Custom"] for k in DEFAULTS))
        check("valid: derived tile follows background",
              r["tile"] != "#0e2236", r["tile"])
        check("valid: derived frame tracks accent",
              r["frame"] == "#ff0000", r["frame"])
        check("valid: derived creamInk follows cream",
              r["creamInk"] != "#1b2c4e", r["creamInk"])
        check("valid: derived amber follows joystick",
              r["amber"] != "#ff9a3c", r["amber"])

        # 3. partial file -> only present + valid keys applied
        r = run_case("partial", json.dumps(
            {"version": 1, "accent": "#112233"}))
        check("partial: accent applied", r["accent"] == "#112233")
        check("partial: other bases stay default",
              r["background"] == "#0a1929" and r["cream"] == "#f0ebdc"
              and r["joystick"] == "#ffd23f")
        check("partial: only accent flag set",
              r["accentCustom"] and not r["backgroundCustom"]
              and not r["creamCustom"] and not r["joystickCustom"])

        # 4. malformed / invalid -> defaults, no crash
        bad_cases = {
            "garbage text": "{not json",
            "empty file": "",
            "wrong version": json.dumps({"version": 2,
                                         "background": "#101418"}),
            "bad hex values": json.dumps({
                "version": 1, "background": "red", "accent": "#12345",
                "cream": "#gggggg", "joystick": 12345}),
            "non-object json": "[1,2,3]",
        }
        for label, content in bad_cases.items():
            r = run_case("bad-" + label, content)
            check("invalid (%s) keeps defaults, no crash" % label,
                  is_default(r), r)
    finally:
        if os.path.exists(COLORS_FILE):
            os.remove(COLORS_FILE)
        shutil.rmtree(TMPDIR, ignore_errors=True)

    print("\nall user-colors tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
