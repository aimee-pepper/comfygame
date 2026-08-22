# World terrain regions and resource hosting — current

**Status:** Game Design implementation authority; ready for Engineering after this authority checkpoint is
integrated and safe to implement while Asset completes the twelve-ground terrain pack
**Priority:** B1.7a; part of the current terrain/world-generation correction
**Owners:** Game Design owns pressure meaning and host legality; Engineering owns deterministic generation,
persistence and tests; Asset owns only the already-separated visual terrain/deposit grammar
**Machine authority:** `world-terrain-resource-host-authority.json`
**Updated:** 22 August 2026

## Player result

A world first reads as a small number of connected places rather than a shuffled bag of ground squares.
Standing water forms ponds and lakes; flowing water forms connected channels; frozen water forms ice fields;
airborne water remains in the air. Mineral seams occur in ground that can physically hold them. Flora yields
what its generated body can produce. Snow and settled Ash lie over existing terrain rather than replacing it.

This is a generation correction, not a new terrain vocabulary. The twelve live `GroundType` cases and the
twenty-three current World Resource catalogue IDs are sufficient for opening and midgame. Do not add another
ground or resource merely to make this checkpoint look broader.

## Frozen tile model

Newly generated tiles freeze four separate facts:

1. `baseGround`: the material before growth or surface deposits;
2. `ground`: the effective live ground used by current passability, movement and sight rules;
3. `surfaceDeposits`: independent persisted Snow and settled-Ash presence/coverage; and
4. `flora`: the exact generated plant identity where growth exists.

`baseGround` uses only existing ground IDs. Growth and Groundcover retain the substrate they covered. Snow and
settled Ash are not new GroundTypes. They do not change passability, movement cost, elevation, sight, content,
resource identity or collection. `GroundType.ash` remains terrain made primarily of Ash. Settled Ash is a
deposit over another ground. Airborne Ash remains transient atmosphere.

Snow and settled Ash are independent: a world may contain neither, either, or both. They share the accepted
accumulation-shape family but have distinct semantic palettes and contributor receipts. Each receipt's own
stable visual seed selects a deterministic variant/phase; a tile carrying both must visibly contain both, not
stack two identical masks so one hides the other. Composite them in frozen source-page order. Their combined
opaque coverage may never exceed 70% of a tile, so the underlying material remains identifiable before color.
Precipitating Snow does not automatically accumulate; only the exact resolved `snow` source contributes the
Snow deposit. Likewise only the resolved `ash` source contributes settled Ash. Authored and unwritten resolved
sources use the same rule. Each contribution freezes its stable source ID, source order, density and visual
seed at bind.

### Save compatibility

- New fields decode tolerantly.
- Legacy non-growth tiles adopt `baseGround = ground` and no deposits.
- Legacy Growth/Groundcover adopts `baseGround = soil` only as a compatibility display receipt; existing
  nodes and content remain frozen and no new host placement runs on a decoded world.
- A future incompatible terrain rewrite may use the agreed save-version boundary, but this correction does
  not require discarding current saves.

## Generation order

The production generator uses one deterministic terrain stream and these exact stages:

1. substrate material quotas and connected regions;
2. coherent elevation;
3. connected Chasms;
4. standing, flowing and frozen hydrology;
5. liquid-water Mud margins;
6. exact generated flora and Growth/Groundcover;
7. Snow and settled-Ash surface deposits;
8. entry selection and reachability repair;
9. resource candidate construction and host-aware placement;
10. writing, sites, creatures, travellers and other content in their existing order.

The current arrival counterfactual summary must call these same stages and salts. There is no alternate
preview generator.

## Connected substrate regions

The existing Stone/Sand/Soil/Rubble/Ash pressure weights remain the first tuning baseline. Only their spatial
allocation changes.

1. Convert normalized weights into exact integer tile quotas with largest-remainder rounding and the stable
   tie order Stone, Soil, Sand, Rubble, Ash.
2. Any material receiving fewer than four tiles is removed and its quota returns to the dominant material.
   This prevents one-tile material confetti without hiding a materially significant form.
3. For each retained material, desired region count is
   `1 + floor(substrate.dispersion / 25)`, capped at five and capped again so every region receives at least
   eight tiles unless the material's complete quota itself is smaller.
4. Seed regions by deterministic farthest-point selection. Equal candidates use the terrain RNG, never
   coordinate hash scatter.
5. Grow all frontiers round-robin until exact quotas are spent. Frontier score is eight points per same-family
   cardinal neighbour plus two per same-family diagonal neighbour. Equal scores use the terrain RNG.
6. A final one-tile-island pass reassigns any tile with zero same-material cardinal neighbours to its strongest
   cardinal neighbour, then compensates the quota from that neighbour's boundary. It may not change total
   per-material counts.

The output must preserve pressure-derived proportions while making connected regions readable before the
16-pixel tile grid. Similar pressure receipts produce similar material proportions; diversity is relative,
not a forced rule that every world must look different.

## Coherent elevation

The current ruggedness formula remains the tuning baseline:
`verticality / 100 × (1 - openness / 200)`.

- Its rounded tile count becomes the exact elevated quota rather than an independent chance on every tile.
- No elevated tiles means every tile remains elevation 0.
- Maximum height is 1 for verticality 0–33, 2 for 34–66 and 3 for 67–100.
- Peak count is one plus `floor((100 - openness) / 34)`, capped at four and at the elevated quota.
- Peaks use deterministic farthest-point placement. Elevation grows outward in connected rings until the
  quota is spent.
- A relaxation pass guarantees every cardinal neighbour differs by at most one elevation level.

Elevation remains exactly 0...3. Equal elevation creates no wall or shade. A genuine difference permits only
the separately accepted lower-tile contact shade; no generated data asks the renderer for sidewalls.

## Hydrology forms

Hydrology form now changes topology rather than only prose.

### Coverage

Surface coverage begins with `hydrology.peak / 100 × maximumWaterCoverage`. Multiply it by the combined
Standing + Flowing + Frozen form share. Airborne share creates zero ground tiles. Largest-remainder rounding
allocates the surface quota among Standing, Flowing and Frozen.

### Standing

- Generates connected basin bodies, preferring the lowest available elevation.
- Body count is `1 + round(dispersion / 100 × 6)`, capped at seven and at one body per eight allocated tiles.
- Bodies of at least nine tiles receive a connected DeepWater core of one-third their quota; smaller ponds are
  shallow Water.
- Standing water never becomes a repeated random walk with a step-order-defined deep end.

### Flowing

- Generates one to `1 + floor(dispersion / 34)` channels, capped at four.
- A channel begins in the highest available elevation quartile and ends at a lower boundary tile or an
  existing Standing body.
- Its pathfinder strongly penalizes uphill movement, mildly penalizes turns and rewards joining an existing
  channel. Every selected channel is cardinally connected from source to outlet.
- Channels are shallow Water by default. At hydrology peak 70 or above, a channel allocated at least sixteen
  tiles may have one connected DeepWater spine; it never scatters isolated deep cells.

### Frozen

- Generates connected Ice fields using the Standing body grammar.
- Ice is passable and remains a GroundType because it is frozen water, not Snow cover.
- Frozen allocation does not silently turn unrelated dry Stone/Soil/Sand into Ice.

### Mud

Mud is a one-tile connected fringe where liquid Water/DeepWater meets underlying Soil. Frozen fields do not
create Mud. Growth may later cover Mud while retaining `baseGround = mud` for presentation and host truth.

## Flora and organic resources

Growth placement remains generated from actual flora identities, habits and stature, but it retains the
underlying base ground. Organic resource nodes are no longer chosen from a generic resource ID and then
silently renamed to whatever plant happens to be nearby.

For each exact generated plant identity:

- chemosynthetic metabolism yields Reagent;
- chemical defence yields Toxin;
- fungal metabolism yields Spore;
- tall dominant Woody tissue yields Timber;
- short dominant Woody or dominant Fibrous tissue yields Fibre; and
- dominant Fleshy tissue yields Pulp.

Resin is a secondary yield, never a replacement primary: a photosynthetic, dominant-Woody, defended plant
adds one Resin to each successful harvest. This closes the current bug where Resin is in the catalogue and
yield table but no generated plant can actually return it.

A flora node freezes its exact plant ID, primary output and optional Resin output. Harvesting commits all
outputs atomically and the return receipt aggregates them as resources.

## Mineral and direct-pickup hosting

The machine authority lists every current Resource ID and is exhaustive. Mineral candidates exist only when
at least one reachable, passable, empty tile satisfies one of that resource's host clauses. Candidate weight
is catalogue abundance multiplied by eligible-host count. A selected candidate then chooses only among its
eligible hosts. A zero-host resource is omitted before sampling; it does not consume a placement attempt.

Key physical rules:

- Iron/Copper/Silver/Gold/Quartz use Stone or Rubble seams.
- Clay and Salt occur on wet low Soil/Sand margins.
- Obsidian and Sulfur require Ash ground or hard ground touching Ash/Chasm.
- Adamant requires high hard ground or a Chasm margin.
- Rift-glass occurs only on a passable Chasm rim.
- Raw Essence remains a direct reachable pickup and never needs a tool.
- Motes are direct Reality pickups on high or Chasm-adjacent hard/volatile ground, never ordinary mineral
  nodes and never Base resources.
- Ichor is excluded from the ordinary World Resource table at generation time; the creature-material
  overhaul owns real creature Ichor.

Mineral extraction rank remains governed by `resource-extraction-progression-current.md`; host legality does
not imply current extractability.

## Node-budget partition

Build eligible candidates before spending the existing node budget:

- each mineral candidate weight is `catalogue abundance × eligible host count`;
- each flora candidate weight is `catalogue abundance of its frozen primary output × covered host count`;
- secondary Resin never creates another node or doubles candidate weight; and
- direct pickups and creature-only materials are absent from the ordinary-node pool.

Sample candidates without replacement of occupied hosts until the budget or candidates are exhausted.
Resource richness still decides yield per harvest; this checkpoint changes physical placement, not the
economy multiplier.

## Engineering boundary and gates

Contained first implementation boundary:

- `WorldMap.swift`: tolerant base-ground and independent surface-deposit receipts;
- `TerrainRules.swift`: quotas, connected regions, elevation and hydrology topology;
- `FloraRules.swift`: exact primary plus secondary Resin result;
- `BookRules.swift`/`Worldgen.swift`: separated mineral/flora/direct candidate tables and host placement;
- World Arrival summary/History adapters only where new frozen terrain facts must be preserved;
- focused Terrain, World, Flora, Persistence and World Generator bridge tests.

Required executable gates:

1. Same seed/page returns byte-identical terrain, deposits, hosts and outputs across relaunch.
2. Substrate per-ground quotas match the pressure-derived target and no retained base material has a
   cardinally isolated single tile.
3. Elevation stays 0...3 with cardinal delta at most one.
4. Standing, Flowing, Frozen and Airborne controlled fixtures produce their exact distinct topology; Airborne
   produces no ground water.
5. DeepWater is connected to its owning liquid body; no isolated deep cell exists.
6. Snow and settled Ash can appear independently and together, never replace base ground and never inherit
   precipitation/airborne gameplay.
7. Every placed mineral satisfies its frozen host clause; a zero-host candidate consumes no attempt.
8. Every flora node output matches its exact plant traits; defended photosynthetic Woody flora yields its
   primary plus Resin.
9. Ichor never enters an ordinary world node; Motes bank directly into Reality.
10. Existing starter seeds are revalidated. Any intentional topology-driven seed replacement preserves the
    stable World Page definition/instance identity and goes through the existing starter receipt validator.
11. World Arrival actual/counterfactual summaries use production stages and remain deterministic.
12. World Generator Web exposes per-ground connected-component counts, hydrology topology, deposits, resource
    host clause and eligible/reachable/extractable counts for rapid review.

## Explicit exclusions

- no new GroundType or World Resource ID;
- no new weather damage, snow movement cost, ash hazard or erosion;
- no procedural Asset fallback or native terrain renderer in this rules checkpoint;
- no tool durability or hidden extraction XP;
- no creature-material implementation beyond excluding generic Ichor from ordinary nodes;
- no encounter, traveller, site or economy rebalance.
