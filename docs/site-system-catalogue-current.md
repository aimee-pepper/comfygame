# Sites and catalogue expansion — current design

**Status:** current structural rules plus six implementation-ready content profiles. Conditions,
weights and yields are playtest values and require reachability/distribution fixtures.

## Current site contract

Sites are authored discrete places placed procedurally when a resolved world qualifies. Current
categories are:

- **recent ruin:** traces from people scattered by the sundering;
- **old ruin:** works of the people who practiced the Art before the current cast;
- **natural landmark:** concentrated geological/ecological character;
- **living site:** a dense place made or occupied by generated life;
- **hazard site:** a placed consequence such as a contradiction Tear;
- **Atlas Seam:** the natural anchoring route;
- **deep sign:** geological evidence governed by `deep-works-system-current.md`.

No third, older civilization layer is implied. If the story later needs one, it must be an explicit
narrative decision rather than a generic “mysterious precursor” texture.

## Placement, value and persistence

- Conditions are thresholds/ranges; a site never requires one exact world recipe.
- Ordinary site rarity comes from condition reachability plus weight, not an unrelated rarity tier.
- A world may contain multiple compatible sites up to category/definition caps. Atlas Seam and one
  deep sign use their own independent placement checks.
- A site's actual resources, items and other value contribute through the same world-value/greed
  accounting as everything else. **Site `stabilityDelta` does not separately charge the headline.**
  Existing authored deltas are retired data while logic remains disabled.
- Tears are produced by contradiction; they do not retroactively add a second contradiction charge.
- In anchored realms, site identity, search state, unique depletion, guardian outcome and extraction
  history persist. Ordinary renewable surroundings follow their own rules; unique site contents do
  not replenish.

## Writing is independent

Every generated world still contains at least one piece of writing. A page may be hosted by an
appropriate site when one exists, but page placement has a non-site fallback such as a dropped,
sheltered or caught fragment.

Therefore:

- the generator never creates a nonsensical ruin solely to satisfy the writing guarantee;
- a site cannot consume the world's only writing allocation and then fail to place it;
- diary pity/selection happens before choosing a compatible host;
- the host changes presentation, not which page became due.

## Discovery and deliberate hunting

- Before a site type is encountered, pre-bind preview may say only that the written conditions make
  **an unknown place** more or less plausible if the player's instruments support that inference.
- After encounter/recording, the Reliquary may show a named likelihood band—unlikely, possible,
  likely—derived from conditions and weight, never the already-rolled presence in the next world.
- Entry splashes and minimaps cannot reveal a rolled undiscovered site under fog.
- Edren's site tools organize known trigger evidence; they do not guarantee placement or solve a
  traveller signature.

## Six additional profiles

These expand the general catalogue from nine current entries to fifteen including special Atlas
Seam/Tear. IDs are stable recommendations.

### `salt_pan` — Salt Pan

- **Category:** natural landmark
- **Conditions:** Thermal peak ≥55; Hydrology available 10–45; Relief openness ≥55
- **Weight/cap:** 5 / 1
- **Placement:** interior or broad open ground; distance ≥4
- **Search:** 2 turns
- **Yield:** 8 Salt, 2 Quartz
- **Identity:** repeated evaporation has left a bright, load-bearing crust with shallow trapped films.

### `wind_carved_gallery` — Wind-carved Gallery

- **Category:** natural landmark
- **Conditions:** Atmosphere motion ≥55; Substrate hard form ≥35; Relief openness ≥45
- **Weight/cap:** 4 / 1
- **Placement:** edge/interior transition; distance ≥4
- **Search:** 2 turns
- **Yield:** 5 Rubble, 3 Quartz
- **Identity:** aligned openings and abraded faces make atmospheric motion physically readable.

### `rootbound_sink` — Rootbound Sink

- **Category:** living site
- **Conditions:** Vitality produced ≥45; Hydrology available ≥30; Relief openness ≤40
- **Weight/cap:** 4 / 1
- **Placement:** adjacent to growth and passable wet/low ground; distance ≥4
- **Search:** 3 turns
- **Yield:** 5 Timber, 5 Resin, 3 Reagent
- **Identity:** several flora have made one sheltered depression into shared structure; no fixed
  guardian is invented if the generated cast supplies none.

### `obsidian_vent` — Obsidian Vent

- **Category:** hazard
- **Conditions:** Thermal geothermal tag present; Substrate volatile form ≥45; Hydrology available ≤35
- **Weight/cap:** 3 / 1
- **Placement:** interior hard/ash ground; distance ≥5
- **Search:** 3 turns
- **Yield:** 5 Obsidian, 5 Sulfur, 3 Quartz
- **Identity:** cooled skin repeatedly opens over a reactive seam. Its ordinary tile/site interaction
  communicates hazard before confirmation; no hidden damage roll.

### `flooded_causeway` — Flooded Causeway

- **Category:** old ruin
- **Conditions:** Hydrology available ≥50; Substrate hard form ≥35
- **Weight/cap:** 3 / 1
- **Placement:** adjacent to water on a traversable route; distance ≥5
- **Search:** 3 turns
- **Yield:** 6 Clay, 2 Silver
- **Identity:** a constructed crossing survives below or between changing water levels. It may host
  ordinary old-ruin writing/curios through generic content selection, not a fixed diary page.

### `signal_cairn` — Signal Cairn

- **Category:** recent ruin
- **Conditions:** Atmosphere motion ≤35; Relief verticality ≥40; Illumination peak ≥35
- **Weight/cap:** 5 / 1
- **Placement:** high/open traversable ground; distance ≥3
- **Search:** 2 turns
- **Yield:** 3 Pulp, 4 Quartz
- **Identity:** stacked markers and protected scraps indicate somebody tried to make one visible fixed
  point after the sundering. It has elevated compatibility as a writing host, not a guaranteed page.

## Catalogue balance rules

- Landmark yields should be concentrated but narrower than a complete expedition haul.
- Generic fixed gear should not appear at every landmark merely to make it exciting; gear belongs
  primarily in authored ruins/caches whose fiction supports it.
- A site with a guardian uses a creature from the generated world cast wherever possible. Fixed
  catalogue guardians require explicit narrative reason and must pass ecological reachability.
- A site may be valuable without teaching a focus. Diary-exclusive teachings never enter generic
  site loot.
- Search duration is visible before starting and each spent turn saves atomically.
- Raw Essence is never a site yield. It has one settled world acquisition grammar: a dedicated
  removable wild drop. Site rewards use world resources, items or knowledge without fabricating a
  second Essence source.

## Live-catalogue audit

The current nine-entry JSON catalogue predates several settled boundaries. Treat these as migration
work before adding the six profiles, not as precedent for new entries:

- `essence_raw` still appears in several site-yield dictionaries. Remove it and replace value only
  with fictionally supported world resources; do not compensate with hidden direct Essence.
- `stabilityDelta` remains decoded and `SiteRules.stabilityDelta` remains callable, although the
  world correctly does not apply it. Deprecate/tolerantly ignore the field before deleting it from
  saved/content schema; no site is allowed to alter the undisclosed headline.
- Several ordinary landmarks carry fixed catalogue gear. Review those individually; preserve gear
  only where the place's fiction supports a left-behind object, and do not copy the pattern into
  every new landmark.
- Current `SitePlacement` can express anywhere/edge/interior plus entry distance, but not “beside
  water”, “on open ground”, “adjacent to growth”, elevation or route ownership. Add typed placement
  predicates evaluated against the final map rather than weakening the six identities into generic
  interior placement.
- Writing is currently placed before sites and has no host attachment. Add an optional saved host
  link/presentation pass after both selections; never reroll the selected writing, and retain the
  ordinary free-tile fallback.

These corrections preserve old looted/search state by stable site and instance IDs. They must not
reroll or relocate sites in an already bound world.

## Implementation order

1. Retire/ignore authored site `stabilityDelta`, remove stale Raw Essence yields and test both
   settled boundaries.
2. Add typed final-map placement predicates with deterministic fallback/omission behavior.
3. Add writing-host fallback and host-selection separation.
4. Add Salt Pan and Signal Cairn as one natural/one recent-ruin fixture.
5. Run condition reachability and full site-count distributions.
6. Add the other four through the same placement/content schema.
7. Add known-site likelihood bands only after instrument/preview disclosure tests are green.
