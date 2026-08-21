# The Tannery — current design

**Status:** implementation-facing structural design. Costs and late capacity thresholds are
playtest values. This document resolves Corrin's station boundary against the Blacksmith, Storehouse,
Workshop and Bracken's Armoury.

## Identity

Corrin turns flexible living material into things that remain useful under repeated contact:
foundational light protection, carrying goods, linings, straps and fitted bindings. The Tannery is
not a generic leather shop and does not require Earth-animal hides by name; recipes use material
kinds and properties from any suitable world provenance.

Corrin owns **foundational flexible armour**. Halloway owns rigid and metal-adjacent foundational
construction. Bracken later rebuilds either origin into advanced defensive profiles.

## What moves from the Blacksmith catalogue

The physical launch catalogue remains twenty-one tactical families, but ownership is corrected:

- Halloway's Blacksmith: **8** foundational families;
- Corrin's Tannery: **3** foundational flexible-armour families;
- Bracken's Armoury: 3 profiles;
- Fen's Bowyer: 3 far physical families;
- Maud's Weaponsmith: 4 advanced melee families.

The three Tannery families are the existing **Supple coat**, **Working gloves** and **Working boots**.
Their requirements and tactical roles remain those in `gear-crafting-families-current.md`; only the
station/owner changes. This is an authority correction, not three additional recipes.

## Capacity progression

Basic Storehouse and satchel capacity must remain available before Corrin. The Tannery owns the
**advanced fitted expansions**, not the existence of storage:

- early shelving and Satchel stitching/reinforcement remain Workshop/Storehouse infrastructure;
- later satchel tiers beginning with **Satchel, deepened** require the Tannery and Corrin's Carry
  branch;
- later Storehouse expansions require a Tannery-made lining/strap capability alongside the existing
  Storehouse project;
- purchasing still occurs once in the existing capacity research/project flow and increments the
  existing `satchelTier` or `storehouseTier`. Do not add a second capacity stat.

The fiction is cooperation: Corrin makes a fitted expansion and the Storehouse/Workshop installs it.
The UI shows the responsible station and all prerequisites before purchase.

Exact node migration must preserve already-purchased capacity on old saves. A player never loses
slots because Corrin was added later.

## Bindings without intermediate clutter

“Bindings” are a Tannery **capability**, not a stackable crafting ingredient. A recipe that requires
a prepared flexible joint still consumes the selected provenance-bearing sample directly; when the
Tannery capability is available, its preview says Corrin will prepare it as part of construction.

Do not turn fibre → strap → fitted strap → armour into a recursive inventory chain. The final crafted
item records the consumed sample and preparation in its provenance. Other stations may require the
Tannery capability or effective tier, but they do not consume a generic anonymous binding token.

## Station branches

Use the ordinary station-owned research architecture:

### Wear

- its foundational root is granted with successful Tannery construction and unlocks Supple coat,
  Working gloves and Working boots immediately;
- later nodes improve preview/fit choices and permit tier-2 construction;
- does not enter Bracken's tier-3/4 rigid/insulated/balanced profile space.

### Carry

- unlocks advanced satchel projects after the two early general upgrades;
- each node produces a visible slot increase, not a percentage carrying bonus;
- no weight or encumbrance system is introduced.

### Keep

- unlocks advanced Storehouse fitting prerequisites and safe handling/grouping improvements;
- does not remove spillover safety or make overflow discard items;
- may improve sorting/grouping before adding raw slot count if phone usability needs it.

The first implementation needs only one root in each branch and the three armour families. The Wear
root is the building's included first capability, not a second fee after the 80-essence construction
bundle. Carry and Keep may appear as visible paid leads. It does not need twenty-four filler nodes
merely because the schema can hold deep trees.

## Materials and quality

> **Incoming correction:** `creature-ecology-and-materials-overhaul-current.md` replaces universal grade
> with family/property capability and makes the Tannery Wear process itself determine Tier 1 or Tier 2.
> The bullets below describe the currently implemented system only until that migration lands.

- Tannery recipes select exact samples using the shared property-driven crafting UI.
- Flexible organic kinds receive the most natural copy, but any material meeting every requirement
  is allowed unless its physical form makes the output nonsensical.
- Craft grade, station caps, immutable sample provenance and Recycler behavior use
  `gear-crafting-families-current.md` unchanged.
- Corrin does not improve raw sample grade, duplicate samples or erase their source identity.
- Chitin is Corrin's diary-exclusive **world focus**, not a free material recipe or guaranteed stock.

## Staffing

Home-posted Corrin applies the standard per-station Tannery discount and effective-tier rules from
`building-staffing-current.md`. Taking Corrin in the party earns ordinary XP toward keeper-earned
station tier. Neither benefit applies globally to Bracken or the Storehouse just because their
projects can depend on Tannery capability.

## Complexity boundary

No durability, repair loop, encumbrance, tanning timer, vats waiting in real time, pattern rarity,
intermediate straps, material mutation tree or bespoke fit stat is added. “Fit” is expressed by slot,
construction profile and material properties already used by combat.

## Implementation order

1. Add Corrin as `builtBy`, build cost and route owner for the Tannery station.
2. Move the three flexible foundational families from Blacksmith ownership without changing saved
   crafted items.
3. Grant the Wear root on build/migration and add exact crafting preview.
4. Gate only the later existing satchel/Storehouse capacity nodes through Carry/Keep, preserving all
   purchased tiers in migration.
5. Add cross-station capability display; do not create binding inventory items.
