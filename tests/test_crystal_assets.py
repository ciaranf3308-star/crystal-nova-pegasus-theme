#!/usr/bin/env python3
"""Crystal scraper-bridge tests: CrystalAssets.js contract + storage safety.

Runs the Node.js driver (tests/crystal_assets_driver.js), which asserts:
  - game-ID mapping matches the Manager U2 Kotlin fixtures byte-for-byte
  - platform shortName -> slug mapping
  - scraped front overrides Pegasus boxFront
  - unscraped games fall back to boxFront, then poster, then theme fallback
  - malformed scraper indexes never break resolution
  - missing asset files resolve to "" (fall back)
  - REAL/GENERATED/USER assets resolve identically for display
  - display-title renames do not orphan artwork (filename identity)
  - title fallback when the Pegasus files API is absent
  - details() exposes front/spine/back/media/logo/screenshot
  - unconfigured/missing crystal-nova-data degrades silently

Also asserts the theme tree contains no crystal-nova-data directory, so
theme updates and rollback can never touch scraper storage.

Run:
    python3 tests/test_crystal_assets.py
Requires: node (skipped with a warning when absent).
"""
import os
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRIVER = os.path.join(REPO, "tests", "crystal_assets_driver.js")


def check_no_scraper_data_in_theme():
    """No crystal-nova-data directory may exist in the theme tree."""
    offenders = []
    for dirpath, dirnames, filenames in os.walk(REPO):
        if ".git" in dirpath:
            continue
        for d in dirnames:
            if d == "crystal-nova-data":
                offenders.append(os.path.join(dirpath, d))
    assert not offenders, \
        "crystal-nova-data inside theme tree: %s" % offenders
    print("ok - theme tree contains no crystal-nova-data directory")


def run_node_driver():
    node = shutil.which("node") or shutil.which("nodejs")
    if not node:
        print("SKIP: node not found; CrystalAssets driver not run")
        return
    p = subprocess.run([node, DRIVER], capture_output=True, text=True,
                       timeout=120, cwd=REPO)
    sys.stdout.write(p.stdout)
    if p.returncode != 0:
        sys.stderr.write(p.stderr)
        raise SystemExit("node driver failed (exit %d)" % p.returncode)


def main():
    check_no_scraper_data_in_theme()
    run_node_driver()
    print("test_crystal_assets: PASS")


if __name__ == "__main__":
    main()
