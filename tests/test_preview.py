#!/usr/bin/env python3
"""Phase 1 test suite for the Crystal Nova Pegasus theme.

Runs the PySide6 preview harness across every verified scenario and asserts
each render completes at the production 1280x960 resolution.

Usage:
    python3 tests/test_preview.py

Requires the preview venv (see README: ~/workspace/.venv-qml).
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(REPO, "preview", "preview.py")
# Override with QML_PY env var if your PySide6 interpreter lives elsewhere.
PY = os.environ.get("QML_PY",
                    os.path.expanduser("~/workspace/.venv-qml/bin/python"))
OUT = "/tmp/crystal-nova-tests"
W, H = 1280, 960

# (name, extra harness args)
SCENARIOS = [
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

failures = []


def check_png(path):
    try:
        from PIL import Image
        with Image.open(path) as im:
            return im.size == (W, H)
    except Exception:
        # fall back to PNG header parse (no Pillow)
        with open(path, "rb") as f:
            head = f.read(33)
        if head[:8] != b"\x89PNG\r\n\x1a\n":
            return False
        import struct
        w, h = struct.unpack(">II", head[16:24])
        return (w, h) == (W, H)


def main():
    os.makedirs(OUT, exist_ok=True)
    print(f"Crystal Nova Phase 1 tests — {len(SCENARIOS)} scenarios")
    for name, args in SCENARIOS:
        out = os.path.join(OUT, f"{name}.png")
        cmd = [PY, HARNESS, "--out", out] + args
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        except subprocess.TimeoutExpired:
            failures.append((name, "harness timed out"))
            print(f"  FAIL {name}: timeout")
            continue
        ok = r.returncode == 0 and os.path.exists(out) and check_png(out)
        # The harness prints known-benign QML binding warnings on stderr;
        # only hard failures (non-zero exit / missing output) count.
        if ok:
            print(f"  PASS {name}")
        else:
            failures.append((name, r.stderr.strip().splitlines()[-1]
                             if r.stderr.strip() else "no output"))
            print(f"  FAIL {name}")
    print()
    if failures:
        print(f"{len(failures)} FAILED:")
        for name, why in failures:
            print(f"  - {name}: {why}")
        sys.exit(1)
    print(f"All {len(SCENARIOS)} scenarios passed at {W}x{H}.")


if __name__ == "__main__":
    main()
