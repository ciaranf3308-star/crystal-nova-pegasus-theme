#!/usr/bin/env python3
"""Phase 1 test suite for the Crystal Nova Pegasus theme.

Two layers:
  1. Render tests — every scenario produces a valid 1280x960 screenshot.
  2. State tests  — QML state is asserted after scripted input:
       selected index after directional input, page after page navigation,
       screen after Accept / Cancel, restored selection via api.memory.

Usage:
    python3 tests/test_preview.py
    QML_PY=/path/to/python python3 tests/test_preview.py

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
                    os.path.expanduser("~/workspace/.venv-qml/bin/python"))
OUT = "/tmp/crystal-nova-tests"
W, H = 1280, 960

# (name, extra harness args) — render-only scenarios
RENDER_SCENARIOS = [
    ("home-9",            ["--n", "9"]),
    ("home-moved",        ["--n", "9", "--keys", "Right,Right,Down"]),
    ("home-wrap",         ["--n", "9", "--keys", "Left"]),
    ("home-page2",        ["--n", "11", "--keys",
                           "Right,Right,Right,Right,Right,Right,Right,Right,Right"]),
    ("system-enter",      ["--n", "9", "--keys", "Return"]),
    ("system-back",       ["--n", "9", "--keys", "Return,Escape"]),
    ("toast-recent",      ["--n", "9", "--keys", "PageUp"]),
    ("toast-favourites",  ["--n", "9", "--keys", "PageDown"]),
    ("battery-charging",  ["--charging"]),
    ("battery-low",       ["--battery", "0.12"]),
    ("battery-unknown",   ["--nobattery"]),
    ("empty",             ["--n", "0"]),
]

# (name, harness args, expected {state_key: value}) — state assertions
STATE_SCENARIOS = [
    ("state-nav-index",
     ["--n", "9", "--keys", "Right,Right,Down"],
     {"screen": "home", "selectedIndex": 5, "page": 0}),
    ("state-nav-wrap",
     ["--n", "9", "--keys", "Left"],
     {"screen": "home", "selectedIndex": 2, "page": 0}),
    ("state-page",
     ["--n", "11", "--keys",
      "Right,Right,Right,Right,Right,Right,Right,Right,Right"],
     {"screen": "home", "selectedIndex": 9, "page": 1}),
    ("state-accept",
     ["--n", "9", "--keys", "Return"],
     {"screen": "system"}),
    ("state-cancel",
     ["--n", "9", "--keys", "Return,Escape"],
     {"screen": "home", "selectedIndex": 0, "page": 0}),
    ("state-restore",
     ["--n", "9", "--restore", "PSP"],
     {"screen": "home", "selectedIndex": 5, "page": 0}),
]

failures = []


def check_png(path):
    try:
        from PIL import Image
        with Image.open(path) as im:
            return im.size == (W, H)
    except Exception:
        with open(path, "rb") as f:
            head = f.read(33)
        if head[:8] != b"\x89PNG\r\n\x1a\n":
            return False
        import struct
        w, h = struct.unpack(">II", head[16:24])
        return (w, h) == (W, H)


def run_harness(name, args, want_state=False):
    out = os.path.join(OUT, f"{name}.png")
    cmd = [PY, HARNESS, "--out", out] + args
    if want_state:
        cmd.append("--print-state")
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return None, None, "harness timed out"
    if r.returncode != 0 or not os.path.exists(out):
        last = r.stderr.strip().splitlines()
        return None, None, last[-1] if last else "no output"
    state = {}
    for m in re.finditer(r"^STATE (\w+)=(.*)$", r.stdout, re.M):
        v = m.group(2)
        state[m.group(1)] = int(v) if v.lstrip("-").isdigit() else v
    return out, state, None


def main():
    os.makedirs(OUT, exist_ok=True)

    print(f"Render tests — {len(RENDER_SCENARIOS)} scenarios")
    for name, args in RENDER_SCENARIOS:
        out, _, err = run_harness(name, args)
        if err or not check_png(out):
            failures.append((name, err or "bad png dimensions"))
            print(f"  FAIL {name}: {err or 'bad png'}")
        else:
            print(f"  PASS {name}")

    print(f"\nState tests — {len(STATE_SCENARIOS)} scenarios")
    for name, args, expected in STATE_SCENARIOS:
        out, state, err = run_harness(name, args, want_state=True)
        if err:
            failures.append((name, err))
            print(f"  FAIL {name}: {err}")
            continue
        if not check_png(out):
            failures.append((name, "bad png dimensions"))
            print(f"  FAIL {name}: bad png")
            continue
        bad = {k: (state.get(k), v) for k, v in expected.items()
               if state.get(k) != v}
        if bad:
            detail = ", ".join(f"{k}: got {g}, want {w}"
                               for k, (g, w) in bad.items())
            failures.append((name, detail))
            print(f"  FAIL {name}: {detail}")
        else:
            print(f"  PASS {name}")

    total = len(RENDER_SCENARIOS) + len(STATE_SCENARIOS)
    print()
    if failures:
        print(f"{len(failures)} FAILED:")
        for name, why in failures:
            print(f"  - {name}: {why}")
        sys.exit(1)
    print(f"All {total} tests passed ({len(RENDER_SCENARIOS)} render, "
          f"{len(STATE_SCENARIOS)} state) at {W}x{H}.")


if __name__ == "__main__":
    main()
