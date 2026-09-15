#!/usr/bin/env python3
"""Phase 2 library tests: HOME -> SYSTEM library -> game launch.

Drives preview.py (PySide6 harness with the mock Pegasus api) and asserts
navigation, paging, edge cases, and the real game.launch() path.

Run:
    python3 tests/test_library.py
    QML_PY=/path/to/python python3 tests/test_library.py
Requires a PySide6 interpreter (see README).
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(REPO, "preview", "preview.py")
# Override with QML_PY env var if your PySide6 interpreter lives elsewhere.
PY = os.environ.get("QML_PY",
                    os.path.join(os.path.expanduser("~"), "workspace",
                                 ".venv-qml", "bin", "python"))
OUT = "/tmp/crystal-nova-lib-tests"
W, H = 1280, 960


def run_harness(args):
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, "t-%d.png" % (run_harness.n,))
    run_harness.n += 1
    cmd = [PY, HARNESS, "--out", out, "--clock", "12:34",
           "--print-state"] + args
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=120,
                       cwd=REPO)
    if p.returncode != 0:
        return None, "harness exit %d\n%s\n%s" % (
            p.returncode, p.stdout[-2000:], p.stderr[-2000:])
    state = {}
    for m in re.finditer(r"^STATE (\w+)=(.*)$", p.stdout, re.M):
        state[m.group(1)] = m.group(2)
    launches = re.findall(r"^LAUNCHED (.*)$", p.stdout, re.M)
    return (out, state, launches, p.stdout), None


run_harness.n = 0


def check_png(path):
    try:
        from PIL import Image
        with Image.open(path) as im:
            return im.size == (W, H)
    except Exception:
        return os.path.exists(path)


# (name, harness args, expected state subset, expected launches)
STATE_SCENARIOS = [
    # enter system from HOME, correct collection selected
    ("lib-enter",
     ["--enter"],
     {"screen": "system", "libShort": "gba",
      "gameIndex": "0", "gamePage": "0", "gameCount": "8",
      "gameTitle": "MARIO GOLF: ADVANCE TOUR"},
     []),
    # right navigation
    ("lib-right",
     ["--enter", "--keys", "Right,Right"],
     {"gameIndex": "2", "gamePage": "0",
      "gameTitle": "METROID FUSION"},
     []),
    # left at the left edge holds position
    ("lib-left-edge",
     ["--enter", "--keys", "Left"],
     {"gameIndex": "0", "gamePage": "0"},
     []),
    # row-edge: right from last column crosses to next row
    ("lib-row-edge-right",
     ["--enter", "--keys", "Right,Right,Right,Right"],
     {"gameIndex": "4", "gamePage": "0", "gameTitle": "GOLDEN SUN"},
     []),
    # row-edge: left from first column crosses to previous row end
    ("lib-row-edge-left",
     ["--enter", "--keys", "Right,Right,Right,Right,Left"],
     {"gameIndex": "3", "gamePage": "0", "gameTitle": "ADVANCE WARS"},
     []),
    # down moves between rows
    ("lib-down",
     ["--enter", "--keys", "Down"],
     {"gameIndex": "4", "gamePage": "0"},
     []),
    # up at the top row holds position
    ("lib-up-edge",
     ["--enter", "--keys", "Up"],
     {"gameIndex": "0", "gamePage": "0"},
     []),
    # down then up returns
    ("lib-down-up",
     ["--enter", "--keys", "Down,Up"],
     {"gameIndex": "0", "gamePage": "0"},
     []),
    # down on the last row holds position
    ("lib-down-edge",
     ["--enter", "--keys", "Down,Down"],
     {"gameIndex": "4", "gamePage": "0"},
     []),
    # next page: 10-game library, right across the page boundary
    ("lib-next-page",
     ["--gameset", "ten", "--enter", "--keys",
      "Right,Right,Right,Right,Right,Right,Right,Right"],
     {"gameIndex": "8", "gamePage": "1", "gameCount": "10"},
     []),
    # previous page: back across the boundary
    ("lib-prev-page",
     ["--gameset", "ten", "--enter", "--keys",
      "Right,Right,Right,Right,Right,Right,Right,Right,Left"],
     {"gameIndex": "7", "gamePage": "0"},
     []),
    # partial final page: down lands on the last two slots
    ("lib-partial-page",
     ["--gameset", "ten", "--enter", "--keys", "Down,Down"],
     {"gameIndex": "8", "gamePage": "1", "gameCount": "10"},
     []),
    # down past the end of a partial page holds position
    ("lib-partial-down-edge",
     ["--gameset", "ten", "--enter", "--keys",
      "Right,Right,Right,Right,Right,Right,Right,Down"],
     {"gameIndex": "7", "gamePage": "0"},
     []),
    # one-game collection: navigation holds
    ("lib-one-game",
     ["--gameset", "one", "--enter", "--keys", "Right,Down,Left,Up"],
     {"gameIndex": "0", "gamePage": "0", "gameCount": "1",
      "gameTitle": "MARIO GOLF: ADVANCE TOUR"},
     []),
    # empty collection: no crash, stays on the system screen
    ("lib-empty",
     ["--gameset", "empty", "--enter"],
     {"screen": "system", "gameIndex": "0",
      "gamePage": "0", "gameCount": "0"},
     []),
    # empty collection: B still returns home
    ("lib-empty-back",
     ["--gameset", "empty", "--enter", "--keys", "Escape"],
     {"screen": "home", "selectedIndex": "0"},
     []),
    # missing artwork: no crash, fallback card path exercised
    ("lib-noart",
     ["--gameset", "noart", "--enter", "--keys", "Right,Right,Right"],
     {"gameIndex": "3", "gamePage": "0", "gameTitle": "ADVANCE WARS"},
     []),
    # long title: renders, navigation unaffected
    ("lib-longtitle",
     ["--gameset", "longtitle", "--enter", "--keys",
      "Right,Right,Right,Right,Right,Right"],
     {"gameIndex": "6", "gamePage": "0"},
     []),
    # B returns home, home selection intact
    ("lib-back",
     ["--enter", "--keys", "Right,Escape"],
     {"screen": "home", "selectedIndex": "0", "page": "0"},
     []),
    # home selection restored across reloads
    ("lib-restore-home",
     ["--restore", "ps2"],
     {"screen": "home", "selectedIndex": "8", "page": "0"},
     []),
    # returning from a game: library re-entered, game index restored
    ("lib-restore-library",
     ["--restore", "gba", "--restore-screen", "system"],
     {"screen": "system", "libShort": "gba",
      "gameIndex": "0", "gamePage": "0"},
     []),
    # A invokes the real Pegasus launch path (game.launch())
    ("lib-launch",
     ["--enter", "--keys", "Return", "--print-launches"],
     {"screen": "system"},
     ["Mario Golf: Advance Tour"]),
    # A on a later game launches that game, not the first
    ("lib-launch-second",
     ["--enter", "--keys", "Right,Right,Return", "--print-launches"],
     {"gameIndex": "2"},
     ["Metroid Fusion"]),
    # PS2 library: correct collection, TOCA first
    ("lib-ps2",
     ["--restore", "ps2", "--enter"],
     {"screen": "system", "libShort": "ps2",
      "gameIndex": "0", "gameCount": "8",
      "gameTitle": "TOCA RACE DRIVER 3"},
     []),
]

# render-only scenarios (1280x960 PNG asserted)
RENDER_SCENARIOS = [
    ("shot-gba",      ["--enter"]),
    ("shot-selected", ["--enter", "--keys", "Right,Right,Down"]),
    ("shot-ps2",      ["--restore", "ps2", "--enter"]),
    ("shot-page2",    ["--gameset", "ten", "--enter", "--keys",
                       "Right,Right,Right,Right,Right,Right,Right,Right"]),
    ("shot-noart",    ["--gameset", "noart", "--enter", "--keys",
                       "Right,Right,Right"]),
    ("shot-empty",    ["--gameset", "empty", "--enter"]),
    ("shot-long",     ["--gameset", "longtitle", "--enter", "--keys",
                       "Right,Right,Right,Right,Right,Right"]),
]


def main():
    failures = []
    passed = 0

    for name, args, want, launches in STATE_SCENARIOS:
        res, err = run_harness(args)
        if err:
            failures.append("%s: %s" % (name, err))
            continue
        out, state, got_launches, _ = res
        bad = []
        for k, v in want.items():
            if state.get(k) != v:
                bad.append("%s: want %r got %r" % (k, v, state.get(k)))
        if got_launches != launches:
            bad.append("launches: want %r got %r" % (launches, got_launches))
        if not check_png(out):
            bad.append("render not 1280x960")
        if bad:
            failures.append("%s:\n  %s" % (name, "\n  ".join(bad)))
        else:
            passed += 1

    for name, args in RENDER_SCENARIOS:
        res, err = run_harness(args)
        if err:
            failures.append("%s: %s" % (name, err))
            continue
        out, _, _, _ = res
        if not check_png(out):
            failures.append("%s: render not 1280x960" % name)
        else:
            passed += 1

    total = len(STATE_SCENARIOS) + len(RENDER_SCENARIOS)
    print("library: %d/%d passed" % (passed, total))
    if failures:
        print("FAILURES:")
        for f in failures:
            print("-", f)
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
