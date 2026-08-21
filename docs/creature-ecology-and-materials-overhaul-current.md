# Creature ecology and creature-material overhaul — current

**Status:** Game Design implementation authority for habitat, body-derived material families and ordinary
reward provenance. Not yet implemented. The final six-band material identity, storage, capability and physical
Schematic rules are settled in `crafting-components-and-schematics-current.md`, which supersedes every open-choice,
pure-no-grade or continuous-property crafting passage retained below for historical comparison. The pressure-budget
creature generator remains the underlying causal model.
**Priority:** after the early encounter-scaling **source checkpoint** and the opening causal field baseline;
phone combat-feel acceptance is nonblocking. Complete this before expanding creature-material crafting or
claiming creature/world visual diversity complete.
**Owner:** Game Design owns ecology, drop semantics and terminology; Engineering owns generation,
persistence, placement, movement, combat rewards and migration; Asset Design owns functional body/material
silhouette proofs; Aimee owns final creature and material art.
**Updated:** 21 August 2026

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
coveringFamily
materialProfileVersion
```

`habitat`, body/morphology fields and the existing gameplay trait vector are generated once and persisted.
Rendering, naming, placement, movement, combat and remains all consume that same identity. No consumer
re-derives a different fish/body/covering interpretation from colour or a display name.

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

Minimum legal area is a tuning value exposed in World Generator Web diagnostics, but the default must allow
at least one spawn plus one legal neighbouring move. A one-tile puddle cannot become an aquatic ecosystem.

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

## Withdrawn pure-no-grade replacement (comparison only; do not implement)

> This section records the fully traced consequences of deleting grade, which is useful when comparing the
> hybrid candidate. It is no longer current implementation authority. The hybrid review owns the open
> decision; history remains here until that decision is settled and this section can move to the archive.

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

## Exact remains derivation

One defeated ordinary creature produces at most four semantic groups. Every group is derived, never rolled
from a catalogue drop table.

### 1. Covering/appendage group

Choose the characteristic external material in this order:

1. feathered appendages → `feather`; also add `down` only when insulation clears the configured threshold;
2. aquatic habitat or piscine body with sufficient covering → `scale`; a soft/scaleless result may yield
   `hide` instead;
3. segmented hard-covered body → `chitin`;
4. radial hard-covered body → `shell`;
5. other long hard covering → `quill`;
6. other very hard/dense covering → `plate`;
7. other moderately hard overlapping covering → `scale`;
8. other long dense soft covering → `pelt`;
9. other sufficient soft covering → `hide`;
10. insufficient covering → none.

Finned appendages add `fin` when present. A creature may therefore yield Scale + Fin, or Feather + Down,
but never five near-synonymous covering kinds.

### 2. Armament group

If armament clears the existing meaningful-part threshold:

- dominant pierce → `fang`;
- dominant rend → `claw`;
- dominant crush with horn cranial feature → `horn`;
- other dominant crush → `tusk`.

### 3. Structural group

Add `bone` when bone density clears the structural threshold and the body is not a genuinely unsupported
amorphous form. Aquatic creatures may still yield bone; being a fish does not imply a boneless skeleton.

### 4. Special group

- toxic/aposematic creature → `venom`;
- aquatic creature with high insulation/body investment → `oil`;
- emanation above the existing meaningful-part threshold → `ichor`.

Venom and Ichor are creature materials, not ordinary named world-resource nodes. Migrate/retire any
ordinary world-node path that produces generic Ichor without a creature source.

### Quantity

Quantity is a deterministic size/part bucket, not a quality roll:

- covering/appendage bundles: 1–4 from body size and appendage count;
- armament parts: 1–2 from the relevant anatomy/count;
- bone bundles: 1–3 from body size and bone density;
- oil/venom/ichor: 1–2 from the producing trait strength.

The exact integer curves are tuning data, but identical frozen specimen traits must produce identical
families/quantities across save/load. No `±1` loot RNG remains.

## Combat reward correction

For ordinary generated animals:

- remove the unrelated named-world-resource roll from combat victory;
- remove the generic random curio/key drop;
- award XP plus morphology-derived creature materials;
- make one isolated **3% gear roll per victorious encounter**, never per defeated creature.

On a successful gear roll, award at most one eligible ordinary gear item from the encounter's current
campaign/danger band. Present it as equipment recovered from the creature's territory, nest or traces—not as
a body part and not as something every animal literally carried. It cannot generate a key, quest object,
authored unique, apex weapon or item above the source cap. Teeming/multi-creature encounters still receive
one roll. The first slice has no pity timer; DEBUG receipts expose the roll and chosen table.

Named world resources come from resource nodes, flora, sites and authored rewards. Most gear comes from
sites, Trading Post, crafting, travellers/guardians or another explicit provenance; the rare territory roll
is the only ordinary-animal exception. An ordinary animal never drops an unidentified key.

Apex encounters retain their separately authored/generated apex trophy/weapon route, plus their actual
creature materials. A guardian or authored non-animal encounter may retain explicit reward rules, but must
not pass through ordinary animal butchery by accident.

This removal changes early loot volume. Before release, retune site/Trading Post/crafting availability if
ordinary gear becomes too scarce; do not restore animal-carried equipment to patch the economy.

## Player presentation

### Bestiary

Each species page shows:

- habitat;
- straight top-down world/combat morphology;
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
   world 16px and encounter 48px in color/grayscale. Every profile stays top-down and shares one persisted
   identity.
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
