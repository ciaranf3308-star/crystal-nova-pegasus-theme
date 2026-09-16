# Crystal game-identity contract (Manager U2 ↔ Pegasus theme)

This document is the single source of truth for how the Crystal Nova
theme resolves scraper assets for a Pegasus game. Both sides implement
this contract; neither side may change its half without updating this
file and the cross-repo fixture tests.

## Canonical game key

```
<platformSlug>/<gameId>
```

Example: `gba/mario-golf-advance-tour`

- `platformSlug` — the Manager's `PlatformTable` slug (e.g. `gba`,
  `psx`, `ps2`, `snes`, `gamecube`). Derived from the ROM folder name
  on the Manager side; from the Pegasus collection `shortName` on the
  theme side (see mapping below).
- `gameId` — `slugify(romFileName)`: the ROM **file name** (not the
  display title), run through the normalizer below. File names are
  stable when users retitle games, so artwork is never orphaned by a
  rename.

## slugify (exact algorithm — ported 1:1 from `TitleNormalizer`)

Given a ROM file name (or any string):

1. Take the basename: strip everything up to the last `/` or `\`.
2. Strip the extension: cut at the last `.` (only when the dot is not
   the first character).
3. Replace every `[...]` / `(...)` tag group with a single space.
4. Lowercase.
5. Replace `_` with a space.
6. Replace every character that is not `a-z`, `0-9`, or space with a
   space.
7. Collapse runs of whitespace to one space; trim both ends.
8. Trailing `, the` / `, a` / `, an` moves to the front
   (`"zelda, the"` → `"the zelda"`).
9. Replace every run of non-`[a-z0-9]` with `-`; trim leading/trailing
   `-`. Empty result becomes `"game"`.

Reference fixtures generated from the real Kotlin implementation live
in `tests/fixtures/u2_gameid_fixtures.json`. The theme's
`components/CrystalAssets.js` ports this algorithm; `tests/test_crystal_assets.py`
asserts byte-identical output for every fixture.

## Platform mapping (theme side)

The theme maps `collection.shortName` (lowercased/trimmed) to the
Manager slug. Exact slug matches win; known aliases cover the common
Pegasus short names:

| shortName | slug |
|---|---|
| gc | gamecube |
| md, megadrive | genesis |
| sms | mastersystem |
| gg | gamegear |
| megacd | segacd |
| ps1, psone | psx |
| 3ds | n3ds |
| tg16, turbografx | pcengine |
| a2600 / a7800 | atari2600 / atari7800 |
| ws, wsc | wonderswan |
| vboy | virtualboy |
| neogeo, mame, fba | arcade |

An unmapped short name resolves to nothing — the game silently falls
back to stock Pegasus artwork. Never guess.

## ROM file name source (theme side)

Primary: `game.files[0].name` (Pegasus "Game files" API — `name` is the
file's name). Defensive: also accepts list-like `files` with `count` /
`get(0)`, and falls back to the basename of `files[0].path`.

Fallback: when the files API is absent, `slugify(game.title)` is used
for the identity lookup instead. Display-title renames can orphan this
fallback path — the filename path is the stable one.

## Asset layout (Manager writes, theme reads)

```
crystal-nova-data/
  games/<platformSlug>/<gameId>/
    front.png  spine.png  back.png  media.png
    logo.png   screenshot.png  fullcover.png
    manifest.json
  index.json
  cache/
```

The theme builds asset URLs as

```
<dataUrl>games/<platformSlug>/<gameId>/<slot>.png
```

where `<dataUrl>` is the `crystal-nova-data/` directory URL passed to
`CrystalAssets.configure()` (in production:
`Qt.resolvedUrl("../crystal-nova-data/")` from the theme root — a
sibling of the installed theme directory, never inside it).

## index.json (written by the Manager, read by the theme)

```json
{
  "version": 1,
  "games": {
    "gba/mario-golf-advance-tour": {
      "title": "Mario Golf: Advance Tour",
      "platform": "gba",
      "gameId": "mario-golf-advance-tour",
      "fileName": "Mario Golf - Advance Tour (E).gba",
      "romRelativePath": "gba/Mario Golf - Advance Tour (E).gba",
      "fileSize": 123456,
      "lastModified": 1726400000000,
      "completeness": "COMPLETE_CASE",
      "assets": ["back", "front", "spine"],
      "real": 1, "generated": 2,
      "region": "EUROPE",
      "provider": "libretro"
    }
  }
}
```

The theme re-reads this file on **every library entry**
(`theme.qml` `enterSystem()` calls `CrystalAssets.refresh()`), so games
scraped in the Manager while Pegasus is open appear without a theme
restart. The fetch is asynchronous: the grid paints immediately with
Pegasus fallback art and tiles upgrade when the parse completes (the
theme observes completion through an index-epoch counter —
`GameLibrary.artEpoch` — that tile art bindings depend on). A re-read
whose text length matches the last installed index skips the re-parse
entirely, so entering a system is cheap when nothing was scraped. The
previously installed index is kept until a request completes; a failed
or deleted `index.json` clears it (tiles fall back) rather than
resurrecting stale art.

The theme builds two in-memory maps:

- `byId`: `"<platform>/<gameId>"` → entry (filename-derived; primary)
- `byTitle`: `"<platform>/<slugify(title)>"` → entry (title fallback)

Duplicate policy: **last-wins in both maps**, matching the `JSON.parse`
key semantics the Manager already applies when writing `index.json`.

Never trust the writer: the platform field is normalized through the
theme's `platformSlug()` mapping and any entry whose platform or
`gameId` is not a clean `[a-z0-9-]+` slug is skipped. A malformed entry
drops just that entry — never the whole index, and never verbatim into
a lookup key or `file://` URL.

Per-tile lookups are hash hits — the JSON is never parsed per tile.

## Theme resolution order (per game)

1. Compute `platformSlug` from `collection.shortName`.
2. Filename identity: `slugify(game.files[0].name)` → `byId` hit?
3. Title fallback: `slugify(game.title)` → `byTitle` hit?
4. No hit → game was never scraped → stock Pegasus artwork.

`assetUrl(game, shortName, slot)` returns the crystal URL only when the
index entry lists that slot; otherwise `""` and the caller falls back.

Tile front-art chain (`CrystalAssets.tileFront`):

```
crystal front → game.assets.boxFront → game.assets.poster → "" (theme fallback art)
```

## Provenance

The theme never reads asset provenance. REAL, GENERATED, and USER
assets resolve identically for display; provenance is Manager-only
information. The resolver test suite asserts this.

## Failure behaviour

- `crystal-nova-data/` missing, `index.json` malformed or a newer
  unknown version, game never scraped, slot not stored → resolver
  returns `""`; the library falls back to existing Pegasus artwork.
- A scraper failure can never break the library screen: every resolver
  entry point is exception-guarded.
- No network access from the theme. Ever. All downloading stays in
  Crystal Nova Manager.

## Storage safety

Theme updates and rollback must never modify `crystal-nova-data/`.
The Manager updater touches only `crystal-nova-pegasus-theme`,
`crystal-nova-pegasus-theme.new`, and `crystal-nova-pegasus-theme.backup`.
No scraper data is ever bundled into the theme release ZIP
(`tests/test_crystal_assets.py` asserts the repo contains no
`crystal-nova-data` directory).

## Known limitations

- Multi-disc games: the Manager keys on the descriptor/play-list file
  (`.cue`/`.m3u`/`.gdi`); if Pegasus exposes a raw track file instead,
  the filename lookup misses and the title fallback is used.
- The Pegasus "Game files" API is marked experimental upstream; if it
  is ever removed, resolution degrades to the title-fallback path.
- The theme reads a snapshot of `index.json`; games scraped while
  Pegasus is open appear the next time a system library is entered
  (`enterSystem()` re-reads the file asynchronously). If the library is
  already open, leave and re-enter the system.
