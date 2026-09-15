# Crystal Nova — Pegasus Theme (Phase 1)

Custom Pegasus Frontend theme for the **Retroid Pocket Nova**.

![Phase 1 home screen](preview/phase1-home-1280x960.png)

Visual source of truth: `reference/approved-crystal-nova-ui.png` — the approved
Crystal Nova handheld dashboard. That image is the contract; the theme matches
it, it does not reinterpret it.

Style: bespoke retro firmware / old-LCD feel. Muted icy blue and cream on a
dark blue-grey background, pixel-clean DejaVu Sans Mono typography, minimal
clutter. No neon gradients, no glassmorphism, no floating cards.

## Target

- **Device:** Retroid Pocket Nova (Android)
- **Resolution:** 1280×960, 4:3
- **Frontend:** Pegasus Frontend
- **Status:** Phase 1 — HOME / SYSTEM SELECTION screen only

## Layout

```
crystal-nova-pegasus-theme/
├── theme.cfg                  Pegasus theme manifest
├── theme.qml                  Root: screen state, key handling, layout
├── components/
│   ├── Header.qml             CRYSTAL title, live clock, battery, divider
│   ├── BatteryIndicator.qml   Real api.device battery rendering
│   ├── SystemGrid.qml         3×3 grid, D-pad nav, paging, row wrap
│   ├── SystemTile.qml         Tile: icon PNG or text fallback
│   ├── FooterHints.qml        L1 / RECENT · page indicator · R1 / FAVOURITES
│   └── Toast.qml              Brief overlay notice
├── screens/
│   └── SystemPlaceholder.qml  Temporary system screen (interaction proof)
├── assets/
│   ├── icons/                 Placeholder icon pairs (<name>.png + <name>_selected.png)
│   ├── fonts/                 DejaVu Sans Mono + Bold
│   └── backgrounds/           (reserved)
├── reference/
│   └── approved-crystal-nova-ui.png   Approved visual reference — do not redesign
├── preview/
│   ├── preview.py             PySide6 harness: mock Pegasus api, 1280×960 renders
│   └── phase1-home-1280x960.png       Current Phase 1 implementation screenshot
├── tests/
│   └── test_preview.py        12-scenario render test suite
├── LICENSES/
│   └── DejaVu-LICENCE.txt     Bitstream Vera licence for the bundled fonts
└── README.md
```

## Controls

| Input | Action |
|---|---|
| D-pad / arrows | Move selection (wraps within row, pages at grid edges) |
| A / Enter | Open system (placeholder screen in Phase 1) |
| B / Esc on system screen | Back to home |
| B / Esc on home | **Not consumed** — Pegasus opens its own menu |
| L1 / PageUp | RECENT toast (Phase 2 stub) |
| R1 / PageDown | FAVOURITES toast (Phase 2 stub) |

The last selected system persists across restarts via
`api.memory` key `crystalNova.lastSystem`.

## Pegasus APIs / properties used

- `api.collections` — `count`, `get(index)`; roles `name`, `shortName`. Drives the grid.
- `api.keys` — `isLeft`, `isRight`, `isUp`, `isDown`, `isAccept`, `isCancel`,
  `isPrevPage`, `isNextPage`. All navigation and screen flow.
- `api.device` — `batteryPercent` (0..1), `batteryCharging` (bool).
  Unknown/absent battery renders an empty outline; nothing is faked.
- `api.memory` — `get`, `has`, `set`, `unset`. Selection persistence.

QML imports are versioned (`QtQuick 2.12`) for the Qt 5.x builds Pegasus ships.
No Qt 6-only syntax is used.

## Installing on Android Pegasus

1. Copy the **entire `crystal-nova-pegasus-theme` folder** to the device.
2. Place it in Pegasus's themes directory. On Android this is typically:
   - `/storage/emulated/0/pegasus_frontend/themes/crystal-nova-pegasus-theme/`
   
   If that path does not exist on the Nova, check Pegasus's own settings /
   documentation for the themes location on your build — the folder name
   `crystal-nova-pegasus-theme` is what Pegasus should be pointed at.
3. In Pegasus, open Settings → Theme and select **Crystal Nova**.
4. On desktop builds, F5 reloads the theme after edits.

The theme reads `theme.cfg` at the folder root; `theme.qml` is the entry point.

## Per-system artwork

Drop real art into `assets/icons/` as:

```
<shortname>.png            unselected tile icon
<shortname>_selected.png   selected tile icon
```

`<shortname>` is the collection's `shortName` in lowercase (e.g. `gba.png`).
Missing files fall back to a text badge automatically — no config needed.

## What has been tested (PySide6 harness)

`python3 tests/test_preview.py` — 12 scenarios, all passing at 1280×960:

- Initial 3×3 home grid
- Moved selection (Right,Right,Down → correct tile)
- Row wrap (Left from first tile wraps to row end)
- 11-collection second page (D-pad paging, top-aligned partial page)
- System placeholder via Enter, return via Escape
- L1/R1 toasts
- Battery: charging, low (12%), unknown/absent
- Empty state (0 collections → "NO SYSTEMS FOUND")

The harness (`preview/preview.py`) mocks the verified Pegasus api surface
(ObjectListModel roles, `api.keys`, `api.device`, `api.memory`) and injects
scripted key sequences via QTest.

## What has NOT been validated yet

- **Real Pegasus runtime.** All verification so far is the PySide6/QML
  preview harness. On-device Pegasus validation on the Nova is the next step.
- Real collection data (names, shortNames, counts) from an actual library.
- Real battery/charging behavior on hardware.
- The exact Android themes directory path on the Nova (see install notes).
- Controller mapping on the Nova (D-pad/L1/R1/A/B → Pegasus key events).

## Known stubs (Phase 2)

- `screens/SystemPlaceholder.qml` — interaction proof only, not the real
  game-library view.
- L1/RECENT and R1/FAVOURITES show toast notices; no real functionality.
- Icons in `assets/icons/` are placeholders, not final art.
- No settings screen, no game grid, no detail views yet.

## Test harness setup

```sh
python3 -m venv ~/workspace/.venv-qml
~/workspace/.venv-qml/bin/pip install PySide6
~/workspace/.venv-qml/bin/python preview/preview.py --out shot.png \
    [--n 0|9|11] [--battery 0.73] [--charging] [--nobattery] \
    [--keys "Right,Right,Down,Return,Escape"]
```

`--keys` accepts: Up Down Left Right Return Escape PageUp PageDown.
