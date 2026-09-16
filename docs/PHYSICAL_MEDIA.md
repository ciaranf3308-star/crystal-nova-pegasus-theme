# Physical media (game library, GBA/PS2)

A 2.5D physical-media layer inside the existing game library view.
Crystal UI + physical game object — never a second design system.

## Where it lives

`CRYSTAL HOME / SYSTEM GRID` → system → `GAME LIBRARY` → (Y) Inspect →
(A) launch. The home screen is untouched. The 4×2 grid stays the primary
navigation skeleton; other systems keep the production flat library.

## Module layout (`components/PhysicalMedia/`)

| File | Role |
|---|---|
| `MediaTemplates.js` | Pure logic: the ONLY place that names platforms. `familyFor()` / `supportsPhysical()` (exactly `gba`, `ps2`), inspect view cycles, artwork slot chains, generated-face helpers, template geometry. Runs under QML and node. |
| `PhysicalObject.qml` | Single entry point the library uses. Resolves artwork through `CrystalAssets` (same `artEpoch` chain as tiles), picks `GbaCartridge` / `Ps2Case`, scales to fit. Callers only ask `active`. |
| `GbaCartridge.qml` | Crystal-owned cartridge shell (300×320 units) + game label texture. Front (label) / back (embossed moulding). `inserting` drives the launch slide. |
| `Ps2Case.qml` | Crystal-owned keep-case template (300×420; 600×420 open). Views: front (+spine sliver) / spine / back / open. The open state is a 2.5D hinge: the cover rotates around its spine edge (`openAmount`, auto-animated) while an interior panel crossfades in. The disc is a `Canvas` so art is truly circular; `lifting` drives the launch transition. |
| `PhysicalInspect.qml` | The Inspect overlay: navy dim over the live library, `tileFill` panel in the open-corner frame language, Departure Mono, keycap prompt language. Animates the object from the selected tile's rect into the panel ("brought forward"); closing reverses it. Emits `launchRequested` — the actual launch stays in `GameLibrary.launchCurrent()`. |

No true 3D: layered planes, Y-axis `Rotation` tilts, offset shadow slabs,
native gradients. No `QtGraphicalEffects` (unavailable in Pegasus).

## Wiring

- `screens/GameLibrary.qml` — `inspectAvailable` (non-empty GBA/PS2 library
  + Pegasus exposes `api.keys.isDetails`), `openInspect` / `closeInspect` /
  `inspectLeft` / `inspectRight` / `inspectLaunch`, and the `PhysicalInspect`
  overlay. The grid selection never moves while inspecting, so B returns to
  the exact tile; `launchCurrent()` (with `api.memory` persistence) is
  unchanged.
- `theme.qml` — routes keys to the inspect view while open; `Y` (Details)
  opens inspect on GBA/PS2 libraries. `LibraryFooter` gains a `[Y] INSPECT`
  prompt (`showInspect`), using the existing keycap geometry.
- `components/GameTile.qml` — the selected GBA/PS2 tile renders the 2.5D
  object (static pose, cream frame + viewfinder marks intact) instead of the
  flat cover. No animation on browse: the tile contract stays colour-only.

## Controller mapping (Nova)

| Context | Input | Action |
|---|---|---|
| Library (GBA/PS2) | D-pad | move through the 4×2 grid |
| Library (GBA/PS2) | Y | open Inspect |
| Library | A / B | PLAY (launch) / BACK (leave system) |
| Inspect | D-pad ←/→ | cycle views (GBA: FRONT/BACK · PS2: FRONT/SPINE/BACK/OPEN) |
| Inspect | A | launch: GBA cart slides into the Crystal slot; PS2 case opens (if needed) then the disc lifts toward camera — then `game.launch()` |
| Inspect | B | back to the same grid tile |

(Y = the Pegasus Details key; `inspectAvailable` hides the prompt and
disables the key if `api.keys.isDetails` is absent.)

## Artwork resolution (existing bridge, no new asset system)

`CrystalAssets.details()` → per-slot URLs. GBA label: `media` → `front` →
tile chain (Pegasus `boxFront`/`poster`) → generated Crystal label. PS2
faces: crystal slot → (front only) tile chain → generated Crystal faces
(spine: vertical title; disc: silver Canvas with data rings + abbr). Every
missing asset degrades to a generated face; unscraped games render normally.

## Crystal styling reuse

Panel, typography, prompts, and frames use only existing `CrystalTheme.js`
tokens (`background`, `tileFill`, `tileBorder`, `tileInk`, `cream`,
`creamInk`, `primaryInk`, `divider`, `keycapFill`, `keycapInk`,
`footerDividerH`, `fontFooterPx`, `libTitlePx`, letter-spacings) and the
shared `TileFrame` / `Keycap` components. `test_physical_media.py` asserts
every `T.*` reference in the new QML names a real token. Richer treatment
(plastic gradients, disc silver, shell grays) is confined to the physical
objects themselves.

## Performance (Nova, 1280×960)

- One physical object on screen at a time (selected tile *or* inspect).
- No per-frame work: static poses, short one-shot animations only.
- No effects modules; shadows are plain translucent rects.
- Artwork resolves through the cached `artEpoch` chain — no JSON parsing
  during rendering, no synchronous work on selection changes.
- Images are `asynchronous`; the Canvas disc repaints only when its art
  loads.

## Tests

`python3 tests/test_physical_media.py` — node driver (60 logic assertions:
families, view cycles, slot chains, generated faces, geometry) + static
architecture guards (no scattered platform literals, token-only styling,
no 3D imports, no Socket references, no audio subsystem, launch path
intact, brace balance).

## Requires real-Nova verification

QML-runtime behaviours (no QML runtime in this environment): the Y-tilt
poses, hinge animation smoothness, Canvas disc rendering, the
bring-forward transition, `api.keys.isDetails` mapping on the Nova
controller, 1280×960 performance, and the missing-PNG fallback chain in
the real Pegasus runtime.
