# World ground and resource coverage — current design audit

**Status:** Game Design audit complete; implementation corrections required
**Scope:** current generator, writable pressures, 12 `GroundType`s, 23 World Resources, harvest progression,
Creature habitats, physical crafting and visual-terrain production
**Updated:** 22 August 2026

## Verdict

The game has **enough ground categories and enough World Resource families for the opening and middle game**.
The principal problem is not a shortage of nouns. It is that the generator does not yet arrange or host them
coherently enough:

- five base grounds are chosen independently per cell, so worlds can become material confetti rather than
  connected places;
- water `form` is resolved in pressure data but ignored by terrain painting, so River, Pond, Lake and Sea do
  not receive distinct topologies;
- Snow promises a white covering but currently produces no ground covering, and settled Ash has no
  orthogonal deposit layer distinct from Ash ground or airborne ash;
- non-organic Resource nodes have no ground-host contract and can be placed on any passable tile, including
  implausible shallow-water hosts; and
- many existing Resource families need meaningful acquisition/sink progression before adding more.

Adding a large list of biome grounds or crafting resources now would make those problems worse. The next
implementation must fix spatial generation, surface state and resource hosting first. New ground/resource IDs
are justified only when they add a mechanic or a complete acquisition→use loop that the current vocabulary
cannot express.

## Current ground vocabulary

| Ground | Current generator cause | Player-facing rule | Audit disposition |
|---|---|---|---|
| Stone | Substrate hard share | ordinary passable hard ground | keep |
| Soil | ordinary non-scorching baseline | ordinary passable earth | keep |
| Sand | ductile Substrate and extreme heat | ordinary passable loose ground | keep |
| Ice | frozen Hydrology replaces shallow/deep water | passable frozen surface | keep |
| Ash | volatile Substrate | ordinary passable deposit | keep |
| Water | Hydrology body edge | passable shallow water | keep |
| Deep Water | Hydrology body interior | impassable depth | keep |
| Rubble | volatile/enclosed Substrate | passable, blocks sight | keep |
| Mud | Soil adjacent to liquid water | two-turn entry, does not block sight | keep |
| Growth | tall generated Flora | two-turn entry and blocks sight | keep |
| Groundcover | low generated Flora | ordinary passable low growth | keep |
| Chasm | written/rolled broken-ground deficit | impassable absence | keep |

Elevation remains orthogonal and must stay orthogonal. The live generator produces elevations `0...3`; the
accepted terrain-layer request currently validates only `0...2`. That schema mismatch must be corrected before
the production terrain pack freezes.

### Why twelve is enough for now

These grounds already cover the mechanical distinctions the player must read on the field:

- ordinary hard/earth/loose/deposit surfaces;
- shallow, deep and frozen water;
- sight-blocking broken terrain;
- movement-slowing wet terrain;
- low versus tall living cover; and
- missing ground.

Biome names should not automatically become `GroundType`s. Salt flat, silt bank, marsh floor, volcanic field,
fungal country and glacier can be composed from ground + elevation + Flora + atmosphere + resource/site + a
truthful visual surface treatment. A new ground enum is warranted only if movement, passability, sight,
harvest or adjacency rules differ.

### Missing orthogonal surface truth

Snow is the clearest current failure. The authored Snow source says it makes everything beneath it white, but
the generator only freezes water into Ice. Snow is a covering, not a replacement for Stone/Soil/Sand. Settled
Ash likewise needs to lie over an underlying material without being confused with either solid Ash ground or
transient airborne ash. Add two independent rules-owned frozen **surface-deposit receipts**, `snow` and
`ash`, that can alter presentation without erasing the underlying ground. Either deposit may be absent or
present, and a world that resolves both sources may carry both. Snow and settled Ash use the same
accumulation geometry; semantic palette roles resolve Snow white and Ash grey/charcoal. Their combined opaque
coverage must leave the underlying material legible. Do not turn either deposit into a thirteenth base ground.

Do not add Lava merely because Magma/Volcano exist. First decide whether exposed molten ground is actually
impassable/damaging and harvest-relevant. If yes, Lava deserves a new typed ground/hazard contract. If Magma
continues to mean heat below the surface, Stone/Ash/Rubble plus geothermal light/atmosphere is truthful and no
new ground is needed.

## Terrain-generation coherence gaps

### 1. Base terrain is cell noise, not geography

`TerrainRules.paint` currently picks Stone/Sand/Soil/Rubble/Ash independently for every tile from weighted
shares. Pressure affects the histogram but not coherent regions. Replace that first stage with a deterministic
region field or seeded patch-growth stage that:

- preserves the pressure-derived target shares within a tested tolerance;
- produces connected regions and deliberately rare single-cell inclusions;
- varies region size/fragmentation from the already-resolved Substrate dispersion and Relief openness;
- consumes only its existing terrain RNG stream; and
- leaves persisted existing maps unchanged.

The new pixel-art compositor cannot make a checkerboard generator feel like a place by itself.

### 2. Water form is not topology

Hydrology already resolves `standing`, `flowing` and `frozen`, but `paintWater` uses the same random-walk body
logic for every liquid source. Implement distinct deterministic topology:

- **standing:** one or more bodies from coverage + dispersion; Deep Water only in sufficiently thick interiors;
- **flowing:** a connected channel travelling from a high/edge origin toward a lower edge/body, with shallow
  banks and depth only where width permits;
- **frozen:** preserve the standing/flowing footprint as Ice and apply Snow separately when authored;
- **marsh:** shallow Water/Mud/Groundcover mosaics with no large unexplained Deep-Water core unless total
  Hydrology requires one.

Pond, Lake, Sea and River should differ because of their resolved form, amount, salinity and dispersion—not by
hardcoded source IDs.

### 3. Special sources need an observable causal owner

- Geyser needs a generated site/hazard/emitter route if it is meant to erupt; ordinary wet Stone is not enough.
- Wildfire can truthfully use Ash + suppressed Flora + Smoke, but its field messages/hazards must not claim fire
  unless a live fire state exists.
- Volcano can use elevation + Stone/Rubble/Ash + Smoke; exposed lava remains a separate decision.
- Salt/Brine needs a visible Salt node/crust relationship instead of generic mineral placement.

## Current World Resource coverage

There are 23 stackable World Resource IDs. Their current functional groups are:

| Group | Resources | Coverage verdict |
|---|---|---|
| Ordinary mineral/build | Rubble, Clay, Iron Ore, Copper | sufficient opening base |
| Valuable/advanced mineral | Silver, Gold, Quartz, Obsidian, Mercury, Adamant | sufficient progression breadth; capability gates/sinks matter more than more metals |
| Chemistry/mineral ingredient | Salt, Sulfur, Reagent | sufficient category count; Reagent is overly generic but currently has a Flora identity |
| Plant-derived | Fibre, Timber, Pulp, Resin, Toxin, Spore | sufficient breadth and already morphology-derived except Resin, which is currently never selected by `FloraRules.yield` |
| Strange/singular | legacy World Ichor, Rift-glass, Mote | enough for current strange-world hooks; do not merge World Ichor with Creature Ichor |
| Economy continuation | Raw Essence | separately guaranteed wild-drop economy |

### Resource-generation imbalance

Fifteen resource families are Substrate-driven, six are Vitality-driven, Raw Essence is Illumination-driven,
and Mote is Substrate-driven Reality currency. Hydrology, Thermal, Atmosphere, Relief and Cycle primarily
modify eligibility rather than owning independent Resource families. That distribution is not inherently
wrong—most physical minerals do come from Substrate—but every target still needs field consequences worth
writing. Use topology, Flora, atmosphere, sites, creatures and yield quality before inventing one Resource per
target.

### Host rules are the immediate resource defect

Add a closed host profile to every non-wild World Resource and make placement fail rather than float on an
implausible tile:

| Host profile | Resources |
|---|---|
| exposed hard ground: Stone/Rubble/Ash; optional elevated Soil where authored | Iron, Copper, Silver, Gold, Quartz, Mercury, Adamant |
| volcanic hard ground: Stone/Rubble/Ash with Thermal/geothermal condition | Obsidian, Sulfur |
| soft/wet bank: Soil/Mud/Sand adjacent to Water where possible | Clay |
| saline margin: Sand/Soil/Ash/Mud with high salinity or Brine truth | Salt |
| unstable/chasm margin: reachable Stone/Rubble/Ash adjacent to Chasm or unstable-ground truth | Rift-glass, Mote |
| exact generated Flora host | Fibre, Timber, Pulp, Toxin, Spore, Reagent; add a Resin-yielding Flora rule before Resin nodes are promised |
| any reachable passable tile as an explicit loose drop | Raw Essence only |

The host profile controls placement, not abundance. Pressure readings still decide whether/how much exists.

## Acquisition and sink audit

The catalogue is already broader than its live uses. Rubble, Obsidian, Toxin and Spore have little or no
current content consumption beyond generation/identity; several other advanced resources mostly serve future
authority. Therefore:

1. do not add new World Resource IDs merely for visual variety;
2. finish capability-gated mining and truthful host placement for the existing mineral ladder;
3. finish the component/recipe review so every retained material has at least one understandable use or an
   explicit sell-only/future disposition;
4. let aquatic Flora yield existing Fibre/Pulp/Reagent where biologically appropriate before adding Kelp as a
   new fungible family; and
5. add Fuel/Coal/Peat only if an approved forge/distillery loop actually consumes fuel—never as decorative
   inventory.

## Writable-source coverage

Current writable sources deliberately name Iron, Gold/Gold Ore, Crystal, Salt, Sulfur and Mercury. Copper,
Silver, Adamant, Obsidian and Clay are currently emergent pressure outcomes rather than directly named focus
runes.

That can support discovery, but reliable progression eventually needs a targetability ladder:

- keep Clay and Obsidian primarily emergent from Silt/Marsh and Magma/Volcano combinations;
- audit a mid-game Copper focus because Copper is required for cyan ink and common component work;
- consider a later Silver focus once Commerce/Channelworks consumes it reliably;
- reserve an Adamant focus or compound for late progression after the mining capability gate is live; and
- do not add a one-to-one rune for every Resource—pressure composition should remain meaningful.

The full 108-entry rune audit must use this ladder and prove that every added mark changes an obtainable world,
not merely dictionary size.

## Ordered implementation plan

1. **Asset now:** replace the rejected flat-fill v0.2 candidate with final-grade pixel-art source parts and
   semantic palette masks; prove identical forms recolored by exact pressure-derived `WorldVisualReceipt`s.
2. **Engineering terrain foundation:** replace independent base-cell selection with pressure-faithful coherent
   regions and close standing/flowing/frozen topology, without changing existing saved maps.
3. **Rules surface deposits:** add independent Snow and settled-Ash receipt/persistence/render inputs and
   correct terrain elevation request range to `0...3`.
4. **Resource placement:** add exact host profiles and Resin coverage; prove no mineral floats in Water and no
   organic node lacks its Flora owner.
5. **Asset production:** after style acceptance, expand all twelve grounds plus the orthogonal Snow/Ash cover and
   freeze the native pack against the corrected terrain request.
6. **Engineering native render:** replace the placeholder map renderer, then phone-review connected regions,
   relative color diversity, sidewalls, motion, visibility and performance.
7. **Resource sinks and targetability:** close the existing-resource use table, mining ladder and Copper/Silver/
   Adamant rune decisions before adding Resource IDs.

## Acceptance evidence

- controlled pressure fixtures produce expected ground shares and topology without isolated material noise;
- River is connected/flowing, Pond/Lake/Sea are standing bodies, Snow visibly covers rather than replaces
  ground, and Marsh reads as a mixed wetland;
- all twelve grounds and elevation `0...3` survive request/pack/native conformance;
- every placed Resource satisfies its exact host profile and remains reachable;
- every retained Resource has acquisition, inventory disposition and at least one current use/sell-only/future
  disposition;
- two similar worlds remain visual relatives, while materially opposed worlds separate proportionally; and
- starter World Page promises are revalidated against the changed generator before a new phone build ships.
