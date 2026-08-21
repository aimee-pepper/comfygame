# Creature ecology and creature-material overhaul — current

**Status:** Game Design implementation authority for a versioned creature/ecology correction. Not yet
implemented. This supersedes the player-facing treatment of animal `MaterialSample.grade` and the current
ordinary-creature random world-resource/gear/curio drop behavior; it preserves the pressure-budget creature
generator as the underlying causal model.
**Priority:** after early encounter-scaling acceptance and before expanding creature-material crafting or
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
creature—not an unrelated ore roll and not a quality-ranked generic Hide.

## Terminology and storage boundary

The following player-facing nouns are separate and must not be collapsed:

1. **World resources** — named materials generated as world nodes/sites/flora results: Rubble, Clay, Iron
   Ore, Copper, Silver, Gold, Quartz, Obsidian, Salt, Sulfur, Mercury, Adamant, Fibre, Timber, Pulp, Resin,
   Toxin, Spore, Reagent, Rift-glass, Raw Essence and Motes where appropriate. They are counted by
   `ResourceID` and never retain a creature source.
2. **Creature materials** — physical parts derived from a defeated creature's persisted morphology and
   capabilities. They use the closed family vocabulary below and retain species/world provenance.
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
| `aquatic` | shallow `water` only | same connected shallow-water component | piscine, serpentine, radial or amorphous; finned strongly preferred |
| `aerial` | any passable non-chasm tile except deep water | same current passable set | feathered or membrane appendages required |

Deep-water fauna is intentionally outside the first interactive slice. Deep water is currently
unsteppable, while encounters begin through deliberate occupied-tile entry; placing combatant fish there
would make them visible but mechanically unreachable. A later fishing/boat/adjacent-contact feature may
add a `deepAquatic` interaction, but v1 aquatic creatures live in traversable shallow water.

An aquatic enemy never leaves its connected shallow-water component. Terrestrial enemies never enter
water. Shore species may cross only the defined shoreline union. Aerial enemies retain the current
passable-tile movement boundary in v1; this change does not let them cross chasms or deep water.

### Habitat resolution

Habitat is chosen from both resolved world facts and actual painted terrain availability:

1. Derive `CreatureHabitatAvailability` after terrain painting and entry-connectivity correction:
   count start-connected non-water tiles, shallow-water tiles, shoreline union and aerial-eligible tiles.
2. Build habitat weights from resolved pressures:
   - standing/flowing Hydrology and real shallow-water area raise aquatic/shore weight;
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

### No universal quality ladder

Creature materials do **not** display `crude`, `fine`, `superb`, `monstrous`, rarity colour or a generic
grade number. Variety is led by the part itself and the animal that produced it.

Existing physical properties remain because they make materials function differently:

- hardness;
- density;
- insulation;
- flexibility;
- lustre;
- reactivity.

They are deterministic consequences of the creature traits, not random quality rolls. Presentation names
the relevant capability when useful—**insulating pelt**, **hard scale**, **reactive ichor**—rather than
claiming one pelt is universally “better.” Recipes require family plus explicit physical capability; they
never require `grade >= N` after migration.

Creature-material details retain source species, source world/run and the relevant property bars/tags. The
collection surface aggregates by family (`Feathers ×8`), while the detail surface can filter/select exact
units for crafting without making each provenance sample consume a slot.

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
- remove the generic random gear drop;
- remove the generic random curio/key drop;
- award only XP plus morphology-derived creature materials.

Named world resources come from resource nodes, flora, sites and authored rewards. Gear and curios come
from sites, Trading Post, crafting, travellers/guardians or another explicit provenance. An ordinary animal
does not carry a Bent Pick or unidentified key.

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
3. Add the new creature-material family/receipt/reserve and no-grade capability projection.
4. Implement exact remains derivation and remove ordinary unrelated resource/item drops.
5. Migrate existing animal `MaterialSample` units losslessly into creature-material units; convert old
   grade-based recipe gates to family/property requirements before deleting their consumer.
6. Split Storehouse/Field/Return presentation into World resources vs Creature materials.
7. Integrate functional ecology/material identities and run native phone acceptance.

Do not combine all seven into one unreviewable commit. Each checkpoint compiles and preserves old saves or
uses the explicit save-format version boundary approved for this early stage.

## Required diagnostics and tests

1. Wet/open-water worlds produce a higher aquatic/shore proportion than dry worlds; no aquatic species
   generates when the painted map has no legal shallow-water component.
2. Every aquatic spawn and move remains on its connected shallow-water component; every terrestrial spawn
   and move remains off water.
3. Same seed/readings/map/schema produce identical cast, ecology identity, placement and remains.
4. New morphology consumes no gameplay RNG and does not change existing combat trait budgets.
5. Feathered, fish-like, armoured/scaled, furred predator and radial/amorphous fixtures produce the exact
   expected material families.
6. No ordinary animal awards a named world resource, generic gear or curio.
7. Apex and authored guardian reward routes remain explicit and do not double-award ordinary gear.
8. Creature-material families aggregate visually while exact properties/provenance survive crafting,
   failure partition, return and relaunch.
9. Existing animal samples migrate without count loss; no old item slot remains occupied by them.
10. No player-facing `crude/fine/superb/monstrous` or material-grade requirement remains in current content.
11. World Generator Web reports habitat counts, species ecology identities, legal placement count and
    material-family projections for rapid review.
12. Ordinary phone proof shows each reference ecosystem in world, combat, Bestiary, loot and Return
    contexts without text being the sole identity.

## Explicit exclusions

- no animal taming/husbandry expansion;
- no food/meat/cooking system;
- no deep-water fishing or boats;
- no item durability;
- no fixed authored Earth-species catalogue;
- no creature-quality rarity ladder under another name;
- no late-game station implementation merely because a material may eventually feed it.
