# Physical media (game library, GBA/PS2)

Authored-template physical media inside the existing game library view.
Crystal UI + physical game object — never a second design system.

## Visual method (binding)

**Authored SVG templates + game textures + QML composition.** The
cartridge/case artwork lives in `assets/physical/` as original
Crystal-owned SVG illustration (QtSvg-safe: gradients and patterns
only — no filters, no turbulence, no masks, no text elements). QML
positions game artwork into the templates' transparent windows,
masks by layering (art *under* an opaque template with a real window),
and animates — it never draws cartridges/cases from rectangles.

| Asset | ViewBox | Contents |
|---|---|---|
| `gba/shell-front.svg` | 580×600 | Stepped-top cartridge silhouette, transparent label window (70,150 440×300), recess groove + lip, edge light/shade, mould marks, contact shadows, subtle dither |
| `gba/shell-back.svg` | 580×600 | Moulded panel, screw heads, grip ribs, embossed mark |
| `gba/shadow.svg` | 700×240 | Soft radial shadow |
| `gba/label-frame.svg` | 580×600 | Crisp ring at the art/shell boundary |
| `gba/sheen.svg` | 580×600 | Animated sheen bands (parallax hint) |
| `ps2/case-front.svg` / `case-back.svg` | 680×950 | Keep-case frame, transparent cover window (26,26 628×898), sleeve groove + catchlight, thickness hint |
| `ps2/case-spine.svg` | 150×950 | Spine strip, transparent spine window, recede shading (front/back faces falling away) |
| `ps2/case-open.svg` | 1400×950 | Composed spread: interior panel + 3-barrel hinge + tray with disc recess and hub post |
| `ps2/disc.svg` | 560×560 | Transparent face, hub rings, sheen arcs, edge light |
| `ps2/case-shadow.svg` | 1500×300 | Soft radial shadow |

## Where it lives

`CRYSTAL HOME / SYSTEM GRID` → system → `GAME LIBRARY` → (Y) Inspect →
(A) launch. The home screen is untouched. The 4×2 grid is pure
production box-art — the physical object appears ONLY in Inspect.

## Module layout (`components/PhysicalMedia/`)

| File | Role |
|---|---|
| `MediaTemplates.js` | Pure logic: the ONLY place that names platforms. `familyFor()` / `supportsPhysical()` (exactly `gba`, `ps2`), inspect view cycles, artwork slot chains, `labelKind()` / `discKind()` render classification, template geometry (matches the SVGs). Runs under QML and node. |
| `PhysicalObject.qml` | Thin Inspect entry point. Resolves artwork through `CrystalAssets` (same `artEpoch` chain as tiles), hands game-owned textures to the platform-owned renderers. Draws nothing itself. Callers only ask `active` and set `view`. |
| `GbaCartridge.qml` | Compositor: shadow + label art (clipped to the well) + `shell-front.svg` + `label-frame.svg` + sheen; back view is `shell-back.svg`. `inserting` slides the cart into the launch slot. |
| `Ps2Case.qml` | Compositor: closed views layer face art under the matching case template; OPEN composes `case-open.svg` + interior art + the disc (art under `disc.svg`). FRONT/SPINE/BACK share one plastic language and one art set — views of the same object. `lifting` raises the disc off the hub. |
| `PhysicalInspect.qml` | The Inspect overlay: navy dim, hero object on a large centered stage, title, understated view indicator, minimal keycap hints. Tile-rect → hero-slot "brought forward" transition; closing reverses it. Emits `launchRequested` — the actual launch stays in `GameLibrary.launchCurrent()`. |

No true 3D, no `QtGraphicalEffects` (unavailable in Pegasus).

## Wiring

- `screens/GameLibrary.qml` — `inspectAvailable`, `openInspect` /
  `closeInspect` / `inspectLeft` / `inspectRight` / `inspectLaunch`, and
  the `PhysicalInspect` overlay. `open()` reports success; `inspecting`
  is set only on success, so a failed open can never trap input. The
  grid selection never moves while inspecting, so B returns to the
  exact tile; `launchCurrent()` (with `api.memory` persistence) is
  unchanged.
- `theme.qml` — routes keys to the inspect view while open; `Y`
  (Details) opens inspect on GBA/PS2 libraries. `LibraryFooter` gains a
  `[Y] INSPECT` prompt (`showInspect`), using the existing keycap
  geometry.
- `components/GameTile.qml` — pure production box-art. No physical
  layer in tiles.

## Input safety (regression: the Nova freeze)

`open()` never throws and returns bool; every transition arms a 900ms
`busyWatchdog` (`forceSettleOpen` / `hardClose`); `beginClose()`
jump-cuts out of busy/launching so B always escapes; no
animation-completion callback is the single point of failure for input
recovery. `test_physical_media.py` asserts this structurally
(`check_inspect_input_safety`).

## Controller mapping (Nova)

| Context | Input | Action |
|---|---|---|
| Library (GBA/PS2) | D-pad | move through the 4×2 grid |
| Library (GBA/PS2) | Y | open Inspect |
| Library | A / B | PLAY (launch) / BACK (leave system) |
| Inspect | D-pad ←/→ | cycle views (GBA: FRONT/BACK · PS2: FRONT/SPINE/BACK/OPEN) |
| Inspect | A | launch: GBA cart slides into the Crystal slot; PS2 opens (if needed) then the disc lifts — then `game.launch()` |
| Inspect | B | back to the same grid tile (always escapes, even mid-transition) |

(Y = the Pegasus Details key; `inspectAvailable` hides the prompt and
disables the key if `api.keys.isDetails` is absent.)

## Artwork resolution (existing bridge, no new asset system)

`CrystalAssets.details()` → per-slot URLs.

- GBA label: `media` (real cart art → shown as-is) → `front` (cover art
  → deliberate Crystal sticker composition: treated art + brand pill +
  title band) → tile chain → designed fallback sticker. Never a blind
  crop, never a placeholder card.
- PS2 faces: crystal slot → (front only) tile chain → designed fallback
  cover (title hierarchy + Crystal frame); spine fallback is a vertical
  title band; back falls back through front art.
- PS2 disc: `media` → cover art under the disc template → designed
  fallback disc face (tonal, ringed, titled — never text on a silver
  circle).

Every missing asset degrades to a designed face; unscraped games render
normally. Platform templates never contain game artwork.

## Crystal styling reuse

Chrome (title, indicator, hints, slot) uses only existing
`CrystalTheme.js` tokens and the shared `Keycap` component.
`test_physical_media.py` asserts every `T.*` reference in the new QML
names a real token. Richer treatment is confined to the authored
template artwork itself.

## Performance (Nova, 1280×960)

- One physical object on screen at a time (Inspect only).
- ~6 image layers per view, simple transforms, short finite
  animations; detail is pre-authored in the templates.
- No per-frame work, no effects modules, no Canvas repainting.
- Artwork resolves through the cached `artEpoch` chain — no JSON
  parsing during rendering, no heavy work on selection changes.
- Images are `asynchronous`.

## Tests

`python3 tests/test_physical_media.py` — node driver (families, view
cycles, slot chains, label/disc kind classification, generated faces,
geometry) + static architecture guards (template inventory present /
parse / QtSvg-safe, renderers compose templates, tile has no physical
layer, no scattered platform literals, token-only styling, no 3D
imports, no Socket references, no audio subsystem, launch path intact,
brace balance, JS import-alias consistency, Inspect input safety net).

## Requires real-Nova verification

QML-runtime behaviours (no QML runtime in this environment): SVG
rendering fidelity in QtSvg (gradients, patterns, transparency),
template/game-art alignment, the bring-forward transition, disc-lift
and cart-insertion motion, `api.keys.isDetails` mapping, 1280×960
performance, and the missing-PNG fallback chain in the real Pegasus
runtime.
