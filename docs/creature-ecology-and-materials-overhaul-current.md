# Creature ecology and creature-material overhaul — current

> **Superseded material-model boundary (3 September 2026):** the habitat, body-plan, deterministic
> species, and anatomy-derived-drop work in this document remains useful design input. Its six-band
> resource-wide quality, family-only stack key, generic family vocabulary, and property-gated recipe
> passages are not the final material authority. Aimee's later direction requires four creature-material
> qualities (Poor, Common, Rare, Exceptional), a category → type → subtype → quality → species-source
> hierarchy, default subtype+quality stacks, and recipes whose eligibility is expressed through
> physical names/categories rather than hidden property thresholds. Mined world resources remain simple
> exact-name quantity stacks with one normal/green presentation and no quality axis. Peerless remains finished gear
> only. Use `resource-crafting-world-ecology-cohesive-plan-v1.md` for the intended model. This file
> remains evidence of the current runtime and the ecology calculations that must be reconciled, not
> an instruction to preserve the obsolete inventory/recipe model.

**Status:** Game Design implementation input for habitat, body-derived material families and ordinary
reward provenance. The final ecology work is not yet implemented. `crafting-components-and-schematics-current.md`
records the currently implemented six-band migration lineage, but Aimee's later four-band hierarchy supersedes
it for final-product material, storage and recipe design. The pressure-budget creature generator remains useful
causal input.
**Priority:** after the early encounter-scaling **source checkpoint** and the opening causal field baseline;
phone combat-feel acceptance is nonblocking. Complete this before expanding creature-material crafting or
claiming creature/world visual diversity complete.
**Owner:** Game Design owns ecology, drop semantics and terminology; Engineering owns generation,
persistence, placement, movement, combat rewards and migration; Asset Design owns functional body/material
silhouette proofs; Aimee owns final creature and material art.
**Updated:** 21 August 2026

Machine authority and freshness gate:
`creature-habitat-authority.json`, `creature-material-projection-authority.json`,
`python3 scripts/validate_creature_habitat.py`, and
`python3 scripts/validate_creature_material_projection.py`.

## Player outcome

World pressures grow a small coherent ecosystem rather than recolouring generic land animals. A wet world
can generate fish that actually live in water; a windy vertical world can support feathered or membranous
fliers; a mineral-rich dry world can produce scaled or plated crawlers; an open predatory world can produce
a large furred quadruped with fangs and claws. Defeating one returns the parts that visibly composed that
creature—not an unrelated ore roll and not merely a quality-ranked generic Hide.

## Terminology and storage boundary

The following player-facing nouns are separate and must not be collapsed:

1. **World resources** — named materials generated as world nodes/sites/flora results: Rubble, Clay, Iron
   Ore, Copper, Silver, Gold, Quartz, Obsidian, Salt, Sulfur, Mercury, Adamant, Fibre, Timber, Pulp, Resin,
   Toxin, Spore, Reagent, Rift-glass, Raw Essence and Motes where appropriate. They are counted by
   `ResourceID` and never retain a creature source.
2. **Creature materials** — physical parts derived from a defeated creature's persisted morphology and
   capabilities. They use the closed family vocabulary below, stack by `creature.family + qualityBand`, and
   retain durable aggregate knowledge of contributing species/world sources in Bestiary/World History rather
   than pretending every merged unit has one exact specimen provenance.
3. **Items** — gear, consumables, curios and authored trophies. They remain exact catalogue instances and
   use item-capacity rules.

World resources and creature materials both consume zero Storehouse/satchel item slots, but appear in
separate Storehouse and expedition-recap groups. “World resource” is no longer an umbrella term for
animal parts.

## Live contradictions this change must remove

The reconciled source currently contains useful foundations but several incompatible behaviors:

- `CreatureTraits` already stores body plan, cranial feature, appendages, covering, armament, bone,
  colour, finish, senses, defence and emanation.
- pressure tendencies already increase finned appendages in standing/flowing-water worlds, feathered or
  membranous appendages in appropriate atmosphere/relief, fur/insulation in cold conditions and hard
  covering in mineral worlds.
- visual body plan is nevertheless derived from a pressure-independent trait hash; a piscine body can be
  assigned without aquatic habitat and the chosen body plan does not constrain placement.
- ordinary enemies are placed on any passable tile; aquatic-looking creatures can therefore stand and
  roam on ordinary ground.
- `ButcheryRules` already derives plate, quill, pelt, down, hide, chitin, fang, tusk, claw, bone and ichor,
  but presentation foregrounds `crude/fine/superb/monstrous` grades within a few common kinds.
- ordinary combat victory separately rolls a named **world resource** from the world's yield table,
  regardless of the creature's body.
- every ordinary creature may also randomly drop generic gear and curios. An animal therefore appears to
  carry a sword or key without any ecological or narrative source.

The new implementation removes those contradictions rather than layering another loot table on top.

## Versioned species identity

### Persisted fields

Every newly generated species stores a frozen `CreatureEcologyIdentity`:

```text
schemaVersion
habitat
bodyPlan
cranialFeature
appendageType
appendageCount
toxinPotency
materialProjectionVersion
materialProjection
materialProfileVersion
```

`habitat`, body/morphology fields and the existing gameplay trait vector are generated once and persisted.
Rendering, naming, placement, movement, combat and remains all consume that same identity. No consumer
re-derives a different fish/body/covering interpretation from colour or a display name.

`materialProjection` is the frozen species-level list of eligible material families, their exact
`partExpression` and deterministic per-specimen quantity. It is derived once from the species trait vector
under the exact rules below. Cosmetic specimen jitter never changes drops, quality or quantity. Encounter
danger may change the final quality band through the separately frozen 75/25 formula, but a later balance or
threshold edit cannot turn an existing saved species' Hide into Plate.

Generation uses its own deterministic species-identity salt and must not consume or reorder gameplay RNG.
Existing saved species/worlds retain their stored v1 traits/placements. New worlds use the new schema. A
legacy species that lacks ecology identity receives a deterministic compatibility identity only when it is
first loaded, frozen immediately, and never has an existing enemy relocated out from under a saved run.

### Habitat cases

The first live schema contains exactly four habitats:

| Habitat | Eligible spawn tiles | Eligible roaming tiles | Required visual tendency |
|---|---|---|---|
| `terrestrial` | passable non-water ground | passable non-water ground | no aquatic body requirement |
| `shore` | shallow water or passable non-water tile cardinally adjacent to water | same shoreline union | amphibious/finned/limbed forms allowed |
| `aquatic` | shallow or deep water | same connected shallow+deep-water component | piscine, serpentine, radial or amorphous; finned strongly preferred |
| `aerial` | any passable non-chasm tile except deep water | same current passable set | feathered or membrane appendages required |

Aquatic life may inhabit both shallow and deep water. Its connected habitat component includes cardinally
connected water of either depth. Because deep water is currently unsteppable, a creature occupying a deep
tile cannot begin ordinary direct-entry combat there and is not silently pulled onto land for the player's
convenience. It may become interactable if it naturally moves into connected shallow water. Deep-only fauna
remains visible ecology until a later fishing, boat or adjacent-contact rule legitimately reaches it.

An aquatic enemy never leaves its connected water component. Terrestrial enemies never enter water. Shore
species may cross only the defined shoreline union. Aerial enemies retain the current passable-tile movement
boundary in v1; this change does not let them cross chasms or deep water.

### Habitat resolution

Habitat is chosen from both resolved world facts and actual painted terrain availability:

1. Derive `CreatureHabitatAvailability` after terrain painting and entry-connectivity correction:
   count start-connected non-water tiles, connected shallow+deep-water components, shoreline union and
   aerial-eligible tiles.
2. Build habitat weights from resolved pressures:
   - standing/flowing Hydrology and real water area raise aquatic weight; shallow-water/land boundary raises
     shore weight;
   - Relief verticality plus Atmosphere motion raise aerial weight;
   - ordinary dry/open/enclosed ground retains terrestrial weight.
3. Any habitat with fewer than the minimum legal placement tiles has weight zero. The generator cannot
   create a species for which it has no legal home.
4. Sample habitat from the separate deterministic species-identity stream.
5. Shape body-plan/appendage weights inside the chosen habitat; never choose habitat by looking at a name.
6. Persist the result before roster/placement.

### Exact v1 availability and weights

`creature-habitat-authority.json` is the machine source for this section. Habitat weights are reversible
playtest tuning, but Engineering does not replace them with an intuitive guess.

Build four-way connected components after terrain painting, entry correction and start-connected reachability:

- **liquid water** is exactly Shallow Water + Deep Water; Ice is not liquid habitat in v1;
- **terrestrial** is start-connected passable non-water ground;
- **shore** is Shallow Water plus start-connected passable non-water ground cardinally adjacent to liquid
  water;
- **aquatic** is each connected Shallow+Deep Water component, including deep-only components; and
- **aerial** is the start-connected current passable component, excluding Deep Water and Chasm.

An eligible component has at least two tiles and one legal cardinal movement edge. Its stable component ID
is the minimum row-major tile index. A one-tile puddle cannot become an ecosystem. Content occupancy does
not change habitat identity; it is filtered later during specimen placement.

Inputs use the painted map and frozen readings:

```text
waterFraction   = 100 × liquidWaterTiles / nonChasmTiles
shoreFraction   = 100 × shoreUnionTiles / nonChasmTiles
liquidHydrology = Hydrology peak × clamp(standingShare + flowingShare, 0, 1)
verticality     = Relief.verticality
motion          = Atmosphere.motion
```

Raw weights are:

```text
terrestrial = 20 + 0.80 × (100 - waterFraction)
shore       = 0.60 × shoreFraction + 0.25 × liquidHydrology
aquatic     = 0.80 × waterFraction + 0.30 × liquidHydrology
aerial      = 0.35 × verticality + 0.35 × motion
```

An unavailable habitat has weight zero. The first species samples only among habitats with at least one
player-contact-eligible component: any terrestrial/aerial component; a Shore component containing a
start-connected passable tile; or an Aquatic component containing start-connected Shallow Water. This
guarantees the world has at least one species the player can actually encounter without boats/fishing.

For later species, multiply each habitat's raw weight by `0.65 ^ alreadySelectedCountForThatHabitat`, then
sample from a dedicated versioned ecology stream. This encourages a coherent mixed cast without forcing two
otherwise dry/flat worlds to invent specialized habitats. Record raw and adjusted weights in World Generator
Web diagnostics.

### Exact morphology constraints

Habitat changes visual morphology and legal placement, not the costly combat trait budget. Body plan is
sampled from these exact 100-point tables on the ecology stream:

| Habitat | Quadruped | Biped | Serpentine | Segmented | Radial | Piscine | Amorphous |
|---|---:|---:|---:|---:|---:|---:|---:|
| Terrestrial | 45 | 15 | 15 | 10 | 7 | 0 | 8 |
| Shore | 35 | 0 | 20 | 15 | 15 | 10 | 5 |
| Aquatic | 0 | 0 | 25 | 5 | 15 | 45 | 10 |
| Aerial | 35 | 20 | 25 | 10 | 5 | 0 | 5 |

Appendage choice starts from the existing pressure-derived appendage weights, then multiplies them:

| Habitat | None | Membrane | Feathered | Finned | Limbed |
|---|---:|---:|---:|---:|---:|
| Terrestrial | ×1 | ×1 | ×1 | ×0 | ×1 |
| Shore | ×0.75 | ×0.5 | ×0.5 | ×2 | ×1.5 |
| Aquatic | ×1.5 | ×0 | ×0 | ×5 | ×0.5 |
| Aerial | ×0 | ×1 | ×1 | ×0 | ×0 |

If Aerial's transformed Feathered and Membrane weights are both zero, use `1:1`; flight identity is
required. Existing pressure tendencies still decide whether one is favoured. Cranial feature remains the
current stable morphology distribution. Habitat/morphology use the new ecology stream and cannot consume or
reorder gameplay RNG.

### Spawn quota, guardians and movement

For an ordinary enemy count `N`, at least
`min(N, max(1, ceil(0.65 × N)))` placed specimens use a player-contact-eligible component. Remaining
placements may use deep-only Aquatic ecology. This lets inaccessible fish visibly inhabit deep water without
turning most of the world's combat population into unreachable decoration.

For each quota slot, choose equally among awake roster species with at least one free legal tile for that
quota, then choose a legal tile after the existing entry-distance and occupancy checks. If no candidate
exists, skip that placement; never put the creature in an illegal habitat or reroll the declared enemy count
with unrelated RNG. Diagnostics name the skipped slot/reason.

Each specimen freezes its habitat component ID. Pursuit pathfinding is restricted to that component:

- Terrestrial stays on its persisted terrestrial component;
- Shore stays inside its persisted shoreline union;
- Aquatic stays inside its persisted Shallow+Deep Water component;
- Aerial stays in the persisted current passable component in v1 and cannot cross Deep Water or Chasm.

No legal path means hold position; no teleport or nearest-land correction. Deep-water occupants cannot be
bumped until a later legitimate adjacent/fishing/boat rule exists. A site guardian is the highest-appetite
local species whose habitat can occupy the exact site tile, with stable Species ID as tie-breaker; it never
pulls an Aquatic species onto a ruin floor.

### Pressure-to-form tendencies

These are weights, not authored Earth-animal templates:

- aquatic habitat strongly favours piscine/serpentine forms and fins;
- shore habitat favours compact quadruped, serpentine and radial forms with limbs or fins;
- aerial habitat chooses feathered or membrane appendages and favours lower bone density;
- hard/mineral substrate raises scaled/plate/chitin/shell covering likelihood through the existing hard
  covering allocation;
- cold conditions raise insulating soft covering/down/fat likelihood without forcing every cold-world
  species into fur;
- open terrain plus predation may produce a large, sleek or muscular quadruped with fangs/claws—a
  lion-like result—without inserting a `lion` role into the generator;
- vertical/moving-air worlds may produce feathered fliers, while wet worlds may produce fish, but cast
  budget/trade-offs remain authoritative and no pressure guarantees one exact species.

The existing rule that Vitality changes cast size/population rather than individual power remains intact.

## Creature-material vocabulary

New creature materials use these stable families:

| Group | Stable families | Physical source |
|---|---|---|
| soft covering | `hide`, `pelt`, `down` | short bare skin; long dense fur; insulating feather underlayer |
| external hard covering | `scale`, `plate`, `chitin`, `shell`, `quill` | overlapping hide plates; dermal armour; segmented case; rigid radial case; long hard covering |
| appendage | `feather`, `fin` | feathered or finned appendages |
| weapon | `fang`, `tusk`, `horn`, `claw` | dominant pierce/crush/cranial/rend structures |
| structure | `bone` | a sufficiently mineralized internal frame |
| special | `oil`, `venom`, `ichor` | insulating aquatic tissue; toxic defence; emanating/reactive anatomy |

Do not add generic Meat/Flesh in this slice. Food, Tavern cooking and animal husbandry are separate future
systems and must not be smuggled in through remains.

### Material family leads; the settled six-band quality modifies it

Creature variety is led by the part itself and the anatomy that produced it, not by presenting every animal
as generic Hide/Bone with a continuous grade number. The settled discrete Rough / Standard / Fine / Superior /
Exceptional / Peerless band modifies value and contribution magnitude while family/material identity remains
authoritative. It never makes one material satisfy another material's physical socket.

Existing physical properties remain because they make materials function differently:

- hardness;
- density;
- insulation;
- flexibility;
- lustre;
- reactivity.

They are deterministic consequences of creature traits and feed the frozen band calculation in
`crafting-components-and-schematics-current.md`; they are not persisted as six independent player-facing bars
or treated as six competing universal quality scores. Presentation names the relevant contribution when
useful—**insulating pelt**, **hard scale**, **reactive ichor**. Recipes accept exact closed family aliases;
quality changes output band and named-effect magnitude after physical eligibility is established.

Creature-material presentation always links back to legitimately learned species/world sources. The collection
aggregates by exact `domain + family + qualityBand` (`Fine Feathers ×8`), and detail shows known source records;
it does not pretend a merged unit retains one exact source. Creature materials never consume item slots.

## Archived rejected pure-no-grade replacement (history only; skip for implementation)

> **Do not implement any passage in this section.** It preserves the rejected no-quality alternative and
> its consequences so the project's decision history remains readable. The current six-band model above,
> `crafting-components-and-schematics-current.md`, and the exact derivation below supersede it. Current
> readers should continue at **Exact frozen material projection**.

Removing `MaterialSample.grade` is not a copy change. The current value also controls construction tier,
Trading Post price, Distillery potency, Scent Mask eligibility, Recycler defaults and several automatic
pickers. Engineering must migrate those consumers in the same checkpoint sequence; it must not delete the
field while quietly substituting `max(properties)` as a new unnamed universal quality score.

### Shared unit and reserve shape

Use one value shape, `CraftMaterialUnit`, with these persisted fields:

```text
stableUnitID
domain                 // world or creature
familyID
properties             // hardness, density, insulation, flexibility, lustre, reactivity
sourceReceipt
schemaVersion
```

The value shape is shared only so recipes and property inspectors do not need two implementations. Storage
remains two explicit reserves:

- `WorldMaterialReserve` for provenance-bearing harvested world materials such as Timber, Fibre, Pulp and
  future flora products;
- `CreatureMaterialReserve` for Hide, Feather, Scale, Bone, Venom and the other families in this document.

Bulk counted ore, clay, salt, sulfur, Raw Essence and similar `ResourceID` holdings remain in the existing
world-resource ledger. The player sees both bulk holdings and provenance-bearing world materials under
**World resources**, but never sees creature parts there. A recipe may accept units from either reserve only
when its authored family requirement says so. Item capacity applies to neither reserve.

`domain` is not inferred from family at display time. It is frozen at collection/migration so a future family
shared by both domains cannot jump categories after a catalogue edit.

### Construction tier comes from the maker, not generic material quality

Recipe family and explicit property floors answer **can this material perform this job?** The maker's
available process answers **what construction tier can this recipe produce?** Once every selected unit meets
its authored requirements, excess property strength never raises the item's tier by itself.

| Maker state at commit | Exact output tier |
|---|---:|
| Blacksmith, effective tier 0 | 1 |
| Blacksmith, effective tier 1 or more | 2 |
| Tannery Wear root without `tannery_wear_tier_two` | 1 |
| Tannery with `tannery_wear_tier_two` | 2 |
| Bowyer, Weaponsmith or Armoury, effective tier 0 or 1 | 3 |
| Bowyer, Weaponsmith or Armoury, effective tier 2 or more | 4 |

Recipe-specific station caps still apply. The existing 12/24/48/80 Essence costs use this frozen output tier.
Remove `craftGrade`, `naturalTier`, `wastesGradeAboveCap`, below-headline-material warnings and their grade
labels from current previews. Keep construction tier, station cap, recipe property requirements, exact
selected units, insulation/reactivity receipts and specialist-profile trade-offs.

This makes Halloway and Corrin foundational Tier-1/2 makers and preserves Fen, Maud and Bracken as the
higher-tier ranged, melee and armour specialists already settled. Stronger-than-required material is still
valuable when it satisfies another recipe or provides a better frozen insulation/reactivity receipt; it is
not transmuted into a universally higher-tier sword.

### Candidate selection is requirement-specific

For one requirement, compute each eligible unit's **surplus** only from that requirement:

1. for every mandatory floor, add `max(0, property - floor)`;
2. for an OR group, use the smallest surplus among the alternatives that pass;
3. sort by total surplus ascending, then stable unit ID ascending;
4. never use an unrelated property, a price or an old grade as a tiebreaker.

The default therefore spends the least-overqualified valid unit. The player may replace any default with
another exact valid unit before confirming. One unit may satisfy only one requirement in a recipe.

Single-property consumers follow the same rule. Reforging and Instrument upgrades sort by the one authored
working property ascending, then stable unit ID; they do not consult price, family or another property after
eligibility. Storehouse sorting offers Family, Source and each named property, never “Best,” “Finest” or
Grade. Stable content hashes for new units omit grade; migrated units preserve their existing stable unit ID
rather than minting a new identity from the reduced field set.

### Trading Post values capability; it does not rank every part

Every creature family has a small authored base value and exactly two commercially relevant capabilities:

| Base | Families | Relevant capabilities |
|---:|---|---|
| 1 | Hide, Down, Feather, Fin, Bone | Hide: flexibility/hardness; Down: insulation/flexibility; Feather: flexibility/lustre; Fin: flexibility/insulation; Bone: density/hardness |
| 2 | Pelt, Scale, Quill, Fang, Claw, Oil | Pelt: insulation/flexibility; Scale: hardness/flexibility; Quill: hardness/flexibility; Fang: hardness/reactivity; Claw: hardness/flexibility; Oil: insulation/reactivity |
| 3 | Plate, Chitin, Shell, Tusk, Horn, Venom | Plate/Chitin/Shell: hardness/density; Tusk/Horn: density/hardness; Venom: reactivity/lustre |
| 4 | Ichor | reactivity/lustre |

`sale price = base + number of the two relevant capabilities that are at least 60`, producing 1–6 Gold.
The detail/preview names both contributing capabilities; it never shows a quality star or rarity colour.
When Vance adds that exact sold unit to stock, its repurchase price is `sale price + 1`. Generated merchant
material stock uses the same formula after its frozen family/properties are generated, so purchase and resale
cannot produce Gold. The Trading Post never averages multiple units into one quote.

### Distillery potency uses the attunement's actual job

Candidate eligibility keeps its existing explicit property floors. Potency becomes:

- Heat: `round(0.65 × reactivity + 0.35 × insulation)`;
- Caustic: `round(reactivity)`;
- Light: `round(0.65 × lustre + 0.35 × hardness)`.

Clamp to 0–100 after rounding. Sort the default candidate by potency ascending and stable unit ID so the
least potent valid unit is consumed first; show the projected potency before commit. The frozen distilled
core retains exact origin, attunement and potency. No grade term remains.

### Scent Mask accepts a material with the right physical fiction

Replace “one animal resource, grade 25+” with **one scent-bearing creature material**. Valid families are
Hide, Pelt, Down and Oil. No property floor is added: being one of these tissues is the relevant capability.
The existing exact-unit preview/commit remains atomic. Feather, Bone, Fang and other unrelated parts cannot
stand in merely because a hidden number is high.

### Recycler returns truth, not an invented best part

For constructed gear, the existing immutable construction receipt remains authoritative. Recovery capacity
is unchanged, but the initial checked units are the first recoverable receipt entries in frozen construction
order. The player may change the selection before confirming. Do not sort by grade, price, maximum property
or a synthetic score.

For catalogue gear without a construction receipt, never fabricate creature provenance. Replace the current
generic `reclaimedHide` salvage output with the authored bulk **Fibre** output already used by padded/boot
profiles. Exact creature materials are recoverable only when an exact creature-material unit exists in the
gear's receipt.

### Migration and compatibility

1. Decode legacy `MaterialSample.grade` only as migration input; do not persist it into a current unit.
2. Preserve every unit's stable identity, domain (derived once from the legacy family/source route), family,
   six properties and source receipt. Existing properties already carry the functional distinctions.
3. Existing crafted gear keeps its frozen construction tier, specialist profile, protection, insulation,
   reactivity and consumed-unit receipt. It is not rebuilt or weakened on load.
4. Legacy creature samples move to `CreatureMaterialReserve`; legacy Timber/Fibre/Pulp and other harvested
   world materials move to `WorldMaterialReserve`; bulk `ResourceID` balances remain untouched.
5. Recompute only future quotes, candidate order and future construction previews. A pending unsaved preview
   may be discarded on migration; no committed holding may be lost.
6. Once migration succeeds, current encode writes only the newest schema. If an old save cannot be migrated
   without loss, use the visible save-version incompatibility route rather than shipping two live material
   systems.
7. Flora/world harvesting derives family, properties and quantity without producing a grade. Predation and
   failure/return partitioning move exact units without ranking them. Any later Deep Works receipt freezes
   resource family, properties and pull count—not a universal grade.
8. Remove grade from current Storehouse, Trading Post, Recycler, Apothecary, Blacksmith, DEBUG receipt and
   accessibility copy. No hidden/debug surface remains the accidental public authority.

The version transition is accepted only when a fixture covering every old `MaterialKind` accounts for the
same number of units before and after migration and all grade-dependent live consumers have zero current
references.

## Exact frozen material projection

One defeated ordinary creature produces the material families frozen on its species ecology identity.
There is no catalogue drop roll. Teeming and multi-creature encounters aggregate the deterministic result
once per defeated creature, then present one row per `family + qualityBand` rather than nineteen `+1` rows.

All numeric inputs are clamped to `0...100` before comparison. Boundary comparisons below are inclusive
unless written as `<`. The v1 constants deliberately reuse the current live meaningful-part boundaries
where those already exist:

| Constant | Exact v1 value |
|---|---:|
| minimum covering coverage | `15` |
| minimum meaningful armament total | `30` |
| minimum structural bone density | `20` |
| minimum emanation strength | `25` |
| soft/scaleless hardness boundary | `25` |
| overlapping scale hardness boundary | `35` |
| hard covering boundary | `55` |
| plate hardness boundary | `70` |
| long covering boundary | `45` |
| dense covering boundary | `50` |
| Down insulation boundary | `25` |
| Oil insulation boundary | `45` |

Derived helper values are exact:

```text
armourValue       = covering.hardness × covering.coverage / 100
insulation        = covering.length × covering.coverage / 100
flexibility       = clamp((100 - covering.hardness) × (0.5 + covering.length / 200))
appendageExtent   = clamp(appendageCount / 8 × 100)
finishLustre      = clamp(finish.shine + finish.schiller)
toxinPotency      = isToxic
                     ? clamp(round(0.70 × coloration.patterning + 0.30 × ornament))
                     : 0
sizeBand          = clamp(1 + floor(size / 25), 1, 4)
appendageBand     = clamp(ceil(appendageCount / 2), 1, 4)
appendageQuantity = clamp(roundHalfUp(0.5 × sizeBand + 0.5 × appendageBand), 1, 4)
```

### 1. Primary covering and appendages

Resolve one primary covering family in this exact first-match order:

1. `appendageType == feathered` and `appendageCount > 0` → `feather`;
2. `(habitat == aquatic || bodyPlan == piscine)` and `covering.coverage >= 15` and
   `covering.hardness >= 25` → `scale`;
3. `(habitat == aquatic || bodyPlan == piscine)` and `covering.coverage >= 15` → `hide`;
4. `bodyPlan == segmented`, `coverage >= 15`, `hardness >= 55` → `chitin`;
5. `bodyPlan == radial`, `coverage >= 15`, `hardness >= 55` → `shell`;
6. `coverage >= 15`, `hardness >= 55`, `length >= 45` → `quill`;
7. `coverage >= 15`, `hardness >= 70` → `plate`;
8. `coverage >= 15`, `hardness >= 35` → `scale`;
9. `coverage >= 50`, `length >= 45` → `pelt`;
10. `coverage >= 15` → `hide`;
11. otherwise no primary covering material.

Then add these non-synonymous appendage materials independently:

- feathered primary + `insulation >= 25` → add `down`;
- `appendageType == finned` and `appendageCount > 0` → add `fin`.

The primary result does not also add another primary covering. A feathered hard-bodied species yields its
characteristic Feathers rather than a second guessed Plate family; its hardness still contributes to the
Feather quality only where the exact capability table says so.

### 2. Armament

When `armament.total >= 30`, add exactly one armament family:

- dominant Pierce → `fang`;
- dominant Rend → `claw`;
- dominant Crush + `cranialFeature == horns` → `horn`;
- other dominant Crush → `tusk`.

Below `30` yields no armament material. Equal damage values use the live stable dominance order already
owned by `CreatureTraits`: Pierce, then Crush, then Rend.

### 3. Structure

When `boneDensity >= 20` and `bodyPlan != amorphous`, add `bone`. Habitat does not decide whether a species
has bones: aquatic species may yield Bone, while a truly amorphous body never does.

### 4. Special materials

Add every independently true special family; these are distinct tissues, not synonyms:

- `isToxic == true` and `toxinPotency > 0` → `venom`;
- `habitat == aquatic` and `insulation >= 45` → `oil`;
- `emanation.strength >= 25` → `ichor`.

This may produce more than one special family on an unusual species. Venom and Ichor are Creature
materials, never ordinary World-resource nodes. The legacy `world.ichor` route is migration-only and never
merges with `creature.ichor`.

### 5. Exact part expression and quality input

Each projected family freezes the following two capabilities. `partExpression` is their arithmetic mean,
rounded half up. This is the missing ecology input consumed by the settled quality formula:

`qualityScore = round(0.75 × partExpression + 0.25 × encounterDanger)`.

Here `encounterDanger` means the bound world's frozen **source Danger band** mapped through the six values
in the crafting authority. It is captured before party-size/level encounter scaling. God mode, DEBUG tuning,
party growth, adaptive foe HP/slots and repeating the same anchored world cannot improve material quality.

| Family | Capability A | Capability B |
|---|---|---|
| Hide | covering coverage | flexibility |
| Pelt | insulation | covering coverage |
| Down | insulation | flexibility |
| Feather | appendage extent | finish lustre |
| Fin | appendage extent | flexibility |
| Bone | bone density | size |
| Scale | covering hardness | covering coverage |
| Quill | covering hardness | covering length |
| Fang | armament Pierce | bone density |
| Claw | armament Rend | bone density |
| Oil | insulation | size |
| Plate | covering hardness | armour value |
| Chitin | covering hardness | finish Schiller |
| Shell | covering hardness | armour value |
| Tusk | armament Crush | bone density |
| Horn | armament Crush | bone density |
| Venom | toxin potency | coloration patterning |
| Ichor | emanation strength | finish lustre |

The six resulting bands and encounter-danger values are exactly those in
`crafting-components-and-schematics-current.md`. No continuous bar, `max(properties)`, old rarity color or
catalogue tier becomes a second quality authority.

### 6. Exact quantity

The frozen per-defeated-specimen quantities are:

| Family group | Exact quantity |
|---|---|
| primary Hide/Pelt/Scale/Plate/Chitin/Shell/Quill | `sizeBand` (`1...4`) |
| Feather or Fin | `appendageQuantity` (`1...4`) |
| Down | `sizeBand` (`1...4`) |
| Fang/Claw/Tusk/Horn | `2` when `armament.total >= 65`, otherwise `1` |
| Bone | `clamp(1 + floor(size / 34), 1, 3)` |
| Oil | `2` when `insulation >= 70`, otherwise `1` |
| Venom | `2` when `toxinPotency >= 70`, otherwise `1` |
| Ichor | `2` when `emanation.strength >= 70`, otherwise `1` |

There is no `±1` loot RNG. Same saved species identity plus frozen source-Danger band produces the same family,
band and quantity receipts across relaunch. Specimen cosmetic jitter never changes the projection.

## Combat reward correction

For ordinary generated animals:

- remove the unrelated named-world-resource roll from combat victory;
- remove every generic per-creature gear/curio/key roll;
- award XP plus the exact morphology-derived Creature materials above; and
- keep the optional **one-roll-per-victorious-encounter** territory-find transaction completely separate.

`creature-territory-finds-current.md` is the sole authority for that optional transaction. Its current
recommendation is 3% eligible ordinary gear, 1.5% eligible consumable and 0.5% ordinary Cache Key, pending
Homework `territory-find-frequency`. It presents the object as **Found nearby** in a den, nest, wrack or
other persisted habitat-compatible trace. No territory-find implementation begins until that Homework
choice is saved. Teeming and number of defeated creatures never add rolls.

Named World resources come from resource nodes, flora, sites and authored rewards. Most gear and
consumables come from sites, Trading Post, crafting, travellers/guardians or another explicit provenance;
the rare territory roll is the only ordinary-animal exception. It can produce only the exact ordinary Cache
Key route, never a story key, quest object, Anchor Frame, authored unique or unidentified generic key.

Apex encounters retain their separately authored/generated apex trophy/weapon route, plus their actual
creature materials. A guardian or authored non-animal encounter may retain explicit reward rules, but must
not pass through ordinary animal butchery by accident.

This removal changes early loot volume. Before release, retune site/Trading Post/crafting availability if
ordinary gear becomes too scarce; do not restore animal-carried equipment to patch the economy.

## Player presentation

### Bestiary

Each species page shows:

- habitat;
- its 16px straight top-down world identity beside the 48px shallow-side encounter/detail identity,
  both derived from the same frozen morphology rather than redrawn as unrelated animals;
- covering/appendage/weapon identity;
- discovered likely material families only after the player has defeated or legitimately analyzed a
  specimen;
- remembered source worlds.

The Bestiary may say “likely leaves feathers and hollow bone” after legitimate knowledge. It cannot expose
exact hidden property values or undiscovered species through the Writing projection.

### Expedition and Return

- combat result groups creature materials by family with icon + quantity;
- Return has separate **World resources** and **Creature materials** groups;
- source detail can expand from aggregate family to exact species/world samples;
- no creature material consumes an item slot or appears in the Storehouse Items tab.

## Asset handoff

Asset Design receives two bounded proofs after the schema is frozen:

1. **Ecology contact sheet:** at least one aquatic fish-like, shore/amphibious, feathered aerial, membranous
   aerial, scaled/armoured terrestrial, large furred predator and unusual radial/amorphous species, each at
   world 16px and encounter/detail 48px in color/grayscale. The 16px explorable-map profile is straight
   top-down. The 48px encounter/detail profile uses the already accepted shallow-side combat camera. Both
   profiles share one persisted identity; camera changes may reveal structure but may not turn them into
   unrelated animals.
2. **Creature-material atlas:** every stable family above as a 32px inventory identity in six-across color
   and literal grayscale, including collisions among Feather/Down/Quill, Scale/Plate/Chitin/Shell,
   Fang/Tusk/Horn/Claw and Oil/Venom/Ichor.

Functional placeholders are sufficient for integration. Aimee retains final art ownership. No Asset proof
may add a new creature stat, habitat or drop family.

## Engineering checkpoints

1. Add persisted ecology identity and versioned legacy freeze without changing gameplay RNG or existing
   saved enemy positions.
2. Add habitat availability/resolution and exact spawn/movement eligibility.
3. Implement the exact stack/value/crafting model in `crafting-components-and-schematics-current.md` with
   separate world/creature domains. Do not implement the withdrawn pure-no-grade comparison.
4. Implement exact remains derivation and remove ordinary unrelated resource/curio drops. Add no rare
   territory-find category until Homework `territory-find-frequency` settles the complete transaction and
   eligibility authority in `creature-territory-finds-current.md`.
5. Migrate existing animal `MaterialSample` units losslessly into the settled creature-material stack shape;
   preserve or visibly version-gate saves according to the project's save-compatibility policy.
6. Split Storehouse/Field/Return presentation into World resources vs Creature materials.
7. Integrate functional ecology/material identities and run native phone acceptance.

Do not combine all seven into one unreviewable commit. Each checkpoint compiles and preserves old saves or
uses the explicit save-format version boundary approved for this early stage.

## Required diagnostics and tests

1. Wet/open-water worlds produce a higher aquatic/shore proportion than dry worlds; no aquatic species
   generates when the painted map has no legal water component.
2. Every aquatic spawn and move remains on its connected shallow+deep-water component; every terrestrial
   spawn and move remains off water. A deep-water occupant is not directly enterable until it reaches
   shallow water or a later legitimate deep-water interaction exists.
3. Same seed/readings/map/schema produce identical cast, ecology identity, placement and remains.
4. New morphology consumes no gameplay RNG and does not change existing combat trait budgets.
5. Feathered, fish-like, armoured/scaled, furred predator and radial/amorphous fixtures produce the exact
   expected material families.
6. No ordinary animal awards a named world resource or curio; at most one accepted territory find appears
   per encounter, never per creature, and Teeming cannot multiply it.
7. Apex and authored guardian reward routes remain explicit and do not double-award ordinary territory finds.
8. Creature-material stacks aggregate only by the settled family/quality key while collection-source records,
   crafting identity, failure partition, return and relaunch remain truthful.
9. Existing animal samples migrate without count loss; no old item slot remains occupied by them.
10. The settled quality model's score, six labels/frames, stack key, material aliases and consumer conversions
    match `crafting-components-and-schematics-current.md` and pass its validator.
11. No parallel legacy grade, catalogue rarity colour or synthetic unnamed quality score remains after that
    migration.
12. World Generator Web reports habitat counts, species ecology identities, legal placement count and
    material-family projections for rapid review.
13. Ordinary phone proof shows each reference ecosystem in world, combat, Bestiary, loot and Return
    contexts without text being the sole identity.

## Explicit exclusions

- no animal taming/husbandry expansion;
- no food/meat/cooking system;
- no deep-water fishing or boats;
- no item durability;
- no fixed authored Earth-species catalogue;
- no continuous hidden grade or quality-only ladder that erases material/family capability;
- no late-game station implementation merely because a material may eventually feed it.
