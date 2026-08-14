# World-grade 2 bind adapter

**Status:** Settled, implementation-ready game-owned contract  
**Date:** 11 August 2026  
**Consumes:** accepted immutable `AssetLab/integration/world-grade-2-v1/` pack

This adapter converts facts the game genuinely owns when a page is bound into the exact visual
request consumed by the world-grade-2 renderer. It prevents appearance from being guessed from
convenient but semantically unrelated statistics.

## Frozen receipt and migration

Every newly bound world atomically persists:

```text
WorldVisualReceipt {
    adapterVersion
    request
    descriptor
    descriptorHash
    selectedSourceByScope
    canonicalReceiptSHA256
}
```

The receipt is immutable. Rendering and History read it rather than re-resolving mutable catalogue
content. Cache identity includes adapter, pipeline and renderer versions plus descriptor hash.
Existing worlds without a receipt remain world-grade 1 forever; they are not visually migrated. An
old unbound campaign page uses this adapter only when eventually bound.

## Scoped source selection

Only these non-negated, nonzero source/contribution pairs can own a visual scope:

| Scope | Qualifying source |
|---|---|
| Material | Granite → Substrate |
| Atmosphere | Smoke → Atmosphere |
| Emitter | Sun → Illumination |
| Flora tendency | Bloom → Vitality |

Select the greatest existing resolver amplitude:

```text
sigil.intensity.multiplier
× PressureRules.scaleMultiplier(sigil, target: selectedScopeTarget)
× PressureRules.countMultiplier(sigil)
```

Do not multiply encoded Scale/Count rung integers: zero and one both use the resolver's neutral
multiplier where appropriate. Selection order is exact: explicit ink before open/Ash, then greater
resolver amplitude, then lower stable Sigil ID. Deliberate color therefore wins over a stronger
undefined source in the same scope. Binding rejects two different explicit colors tied at the same
greatest explicit amplitude before costs are spent. No other contribution acquires color ownership
in v1.

## Open color resolution

Rough charcoal, Brush or Fountain-pen Ash, and undefined sigils carry `nil` color. `nil` means open,
not black, beige or absent. Resolve every selected open source from this exact independent stream:

```swift
let scoped = SeededRNG(seed: mapSeed).derived(scopeSalt)
var colorRNG = scoped.derived(selectedSigil.id.rawValue)
```

The four UInt64 domain salts are frozen:

| Scope | Salt | ASCII mnemonic |
|---|---:|---|
| Material | `0x4D41_5445_5249_414C` | `MATERIAL` |
| Atmosphere | `0x4154_4D4F_5350_4852` | `ATMOSPHR` |
| Emitter | `0x454D_4954_5445_5221` | `EMITTER!` |
| Flora tendency | `0x464C_4F52_4154_4E44` | `FLORATND` |

Use the existing SplitMix64 `SeededRNG` and raw draws in this exact order; do not use Swift's
`Int.random`/`Double.random`, because their range sampling is not part of this receipt version:

1. `hue = Int(colorRNG.next() % 360)`;
2. `band = Int(colorRNG.next() % 100)`;
3. choose saturation bounds from `band` (`0...19` achromatic, `20...69` muted, `70...99` vivid),
   then `lower + Int(colorRNG.next() % UInt64(upper-lower+1))`;
4. choose this scope's lightness bounds, then
   `lower + Int(colorRNG.next() % UInt64(upper-lower+1))`.

This stream consumes exactly four raw draws. It does not consume run-generation or rendering RNG.

- hue: uniform integer `0...359`;
- saturation: 20% achromatic `0...12`, 50% muted `25...55`, 30% vivid `60...85`;
- lightness: material `35...65`, atmosphere `45...75`, emitter `65...85`, flora tendency `35...65`.

Cross-language golden vector for `mapSeed = 1`, `selectedSigil.id.rawValue = 1`:

| Scope | Derived seed | HSL | Rounded sRGB |
|---|---:|---|---|
| Material | `13687280610363741021` | `237,72,39` | `[28,35,171]` |
| Atmosphere | `13593753515414985611` | `105,9,55` | `[135,151,130]` |
| Emitter | `14092530940132275359` | `218,54,81` | `[180,200,233]` |
| Flora tendency | `16000765205411828928` | `314,8,43` | `[118,101,114]` |

Native and any test-side implementation must reproduce all four seeds, HSL triples and sRGB triples
exactly before the resolver is accepted.

Use pinned native HSL→sRGB and nearest-UInt8 channel rounding. Persist
`resolutionVersion: resolved-color-1.0.0` and provenance `bindRandom`. Equal facts and seed match;
different open rolls may legitimately differ. The distribution must retain achromatic, muted, vivid
and broad-hue outcomes rather than forcing undefined worlds into neutral colors.

Explicit mixed black is non-nil authored color. Ink Mixing replaces a selected source's open roll
with its exact saved recipe; it changes no material identity, Smoke density, flora anatomy or emitter
intensity.

## Material

Inputs: resolved Substrate hard/ductile/volatile shares, Thermal centre
`(thermal.floor + thermal.peak) / 2`, usable Hydrology `hydrology.availableMagnitude`, and Substrate
peak. Illumination, Vitality, Danger, Relief, Cycle, hidden outcomes, previous worlds and run history
must not affect material.

Identity:

- selected qualifying Granite → `granite`;
- otherwise hard + volatile ≥ 0.55 → `mixedMineral`;
- otherwise → `mixedEarth`.

Palette:

- granite → `paleNeutral`;
- mixedMineral → `coolMineral` at Thermal ≤ 40, `warmMineral` at ≥ 60, otherwise `paleNeutral`;
- mixedEarth → `coolEarth` below 45, otherwise `warmEarth`.

With normalized substrate shares and 0–100 readings:

```text
t = (thermalCentre - 50) / 50
w = (availableHydrology - 50) / 50
hue = clamp(round(24*t + 10*(volatile - ductile)), -32, 32)
saturation = clamp(1 + .18*((substratePeak - 50)/50) + .12*volatile - .08*max(w, 0), .80, 1.30)
value = clamp(round(-8*w + 4*(ductile - hard)), -12, 12)
```

Only selected Granite supplies resolved material color in v1. Other material identities keep their
derived palette/transform with color `nil`.

## Atmosphere

No qualifying Smoke: medium `none`, density `0`, palette `clear`, color `nil`.

With Smoke: medium `smoke`, palette `neutralSmoke`. Each actual Smoke→Atmosphere contribution adds
`18 × effectiveAmplitude`; combine with the existing world-pressure diminishing-returns function,
then persist `clamp(round(combined / 50 × 100), 10, 100)`. The selected Smoke receives its explicit
or open color. Cold, wetness, toxicity and generic Atmosphere must not invent haze.

## Flora

First form the **realized cast**: persisted Flora members whose exact `InstanceID` occurs on at least
one persisted **non-chasm** map tile. A corrupt or legacy Flora reference on a chasm is not visible
growth and cannot realize a species. The request includes only this realized cast, in ascending
`id.rawValue` order. `WorldRun.flora` remains the historical generated cast; the visual request does
not pretend an unplaced species is visible. If no Flora ID occurs on any non-chasm tile, request
`coveragePercent = 0`, `paletteRichness = 0`, and `cast = []`, even when the generated source cast
was nonempty. This obeys the frozen schema's coverage/cast equivalence without mutating ecology.

For each realized cast member:

- species ID `flora-<InstanceID>`;
- stature: exact trait value, clamped only to renderer schema;
- form: fungal metabolism → `3`; otherwise `traits.tissue.dominant`: woody → `0`, fleshy → `1`,
  fibrous → `2`. This deliberately inherits the model's stable dominant-tissue tie order
  woody→fibrous→fleshy rather than reimplementing comparisons;
- coverage: `100 × valid realized-Flora-ID tiles / non-chasm tiles`, three decimals;
- palette richness: realized-cast mean of `max(C,M,Y) - min(C,M,Y)` after normalization/clamping, three
  decimals; empty cast → `0`.

Base species color:

```text
hue = ((C/total)*185 + (M/total)*322 + (Y/total)*74) mod 360
saturation = clamp(28 + Depth*.48, 0, 92)
lightness = 43
```

Use pinned native HSL→sRGB. A zero CMY total takes the stable achromatic branch. If Bloom owns flora
tendency, blend species color 80% with tendency color 20% per sRGB channel, nearest UInt8. Persist
each final distinct species color. Under the frozen v1 schema, species color provenance is
`authoredMix` only when an explicit mixed-ink Bloom contributes to that final blend; trait-derived,
no-Bloom and open-Bloom results use `bindRandom` (the schema's current label for non-authored
bind-resolved color, even when the trait conversion itself is deterministic). Creatures are
excluded.

## Emitter and writing-tool boundary

Selected Sun receives persisted explicit/open emitter color; it belongs to the emitter layer and
never recolors inherent terrain. Without Sun it is `nil`.

Rough charcoal cannot carry liquid ink. Brush and Fountain pen with Ash remain open; either tool
with an Ink-Mixing recipe carries non-nil authored color. Tool precision changes footprint, not
gamut. An explicit color is always regenerated from the exact persisted, normalized `InkRecipe`
using its registered `conversionVersion`; never trust or accept a separately supplied sRGB triple.
Unknown conversion versions, invalid channels, all-zero recipes and a recipe whose regenerated sRGB
does not match its frozen authored receipt fail binding atomically rather than falling back to Ash.

## Canonical receipt bytes

Use the frozen pack's canonical JSON grammar for the whole receipt: UTF-8; object keys sorted by
Unicode code-unit order; arrays retain authored order; no insignificant whitespace; finite numbers
serialized with the same canonical numeric rules as the pack. Compute `canonicalReceiptSHA256` over
the receipt with that self-hash field omitted. Do not hash `JSONEncoder` dictionary output or a Swift
`Dictionary` traversal. `descriptorHash` remains the pack's canonical descriptor hash; the receipt
hash additionally covers adapter version, request and selected source provenance.

## Atomicity

Create and validate the complete request, descriptor, receipt and hash before spending costs or
mutating the page. Schema failure, ambiguous explicit ownership or a non-finite derivation leaves all
game state unchanged and presents a recoverable error.

## Acceptance gates

1. Equal bind facts yield byte-identical receipts/hashes across relaunch.
2. Controlled material pairs prove only the named inputs affect material.
3. No/faint/moderate/great Smoke fixtures produce none and ordered density.
4. Granite stays material-scoped; Sun stays emitter-scoped.
5. Empty and 1–4-species casts validate IDs, form, coverage, richness and distinct colors.
6. The four mapSeed-1/Sigil-1 golden vectors match exact seed, HSL and sRGB bytes; a larger seeded
   corpus retains achromatic, muted, vivid and broad-hue outcomes.
7. Receipt-less worlds render unchanged through world-grade 1.
8. Failed binding is atomic; successful receipts survive save/relaunch.
9. Native phone evidence includes related similar-stat worlds and visibly opposed authored/open
   worlds, in color and literal grayscale.
10. A nonempty generated Flora cast with zero Flora on non-chasm tiles produces a schema-valid empty
    visual cast; a Flora ID found only on chasm remains unrealized, and a partially realized cast
    excludes absent species without changing `WorldRun.flora`.
11. Tampered/stale explicit sRGB is rejected or regenerated from its exact versioned `InkRecipe`,
    and canonical receipt hashing is invariant to in-memory dictionary order.
