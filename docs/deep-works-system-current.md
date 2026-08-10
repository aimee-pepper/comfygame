# The Deep Works — current design

**Status:** implementation-facing structural design. Site frequency, yields and bracing thresholds
are playtest values. Grimmond's identity remains governed by
`traveller-identities-living-and-deep-materials.md`.

## Boundary

The Deep Works opens finite geological sites and deliberate extraction on the existing world map.
It does **not** add an underground navigation layer, mine-building simulation or passive “+20% ore”
bonus.

- Edren owns constructed ruins, their history and authored site rewards.
- Grimmond owns geological depth, load, buried flow and hard-resource recovery.
- Halloway and later makers transform recovered material.
- Auber separates and concentrates selected outputs afterward.

## Deep signs exist before Grimmond

Eligible worlds deterministically place at most one **deep sign** at bind from their saved seed and
resolved conditions. It is part of the map/site state even before the player understands it.

- Before the Deep Works, inspection describes a load-bearing crack, hollow response, buried seep or
  other physical evidence and records it in World History as **Unresolved depth**.
- After Grimmond/Deep Works, the same saved site becomes readable and workable; it is not replaced or
  rerolled.
- Anchored worlds discovered earlier retain their exact sign and can be revisited later.
- An unvisited sign under fog is not revealed retroactively merely because the station was built.

This lets late knowledge reinterpret an old place without spawning rewards into a previously empty
tile or pretending the site never existed.

## Eligibility and frequency

The first slice uses one site family, **Buried seam**. It requires hard substrate and meaningful
relief/pressure. **Placeholder appearance:** 20% of otherwise eligible worlds, capped at one deep
site per world and exposed in debug tuning.

Its mineral profile is derived from the world resources already resolved for that world. It never
invents Adamant, Mercury, Rift-glass or another rare resource absent from the world's own profile.
Writing a resource focus may make that resource eligible/abundant; it does not guarantee a deep sign.

Deep sites do not contain diary pages, traveller placement, gear caches or old-civilization lore by
default. A future authored overlap may combine geological and constructed evidence explicitly, but
the generic site does not steal Edren's reward identity.

## Field flow

Building the Deep Works unlocks **Sound depth**, a one-turn interaction at an adjacent deep sign.
It reveals:

- likely resource family in sensory terms appropriate to current instrument knowledge;
- number of safely recoverable pulls;
- material that must remain as support;
- turns per pull and any required Field pick/property threshold.

Extraction then uses the ordinary repeated-harvest interaction: one confirmed pull, one or more world
turns, one visible output. The player can leave after any pull. Collapse pressure supplies the risk;
there is no hidden cave-in roll.

**Placeholder Buried-seam profile:** 3–5 safe pulls, one world turn each with a Field pick, two turns
without one where the face is workable at all. Hardness beyond the party's current capability is
shown as inaccessible rather than consuming a failed turn.

## Support reserve

Every sounded site distinguishes **recoverable material** from a visible **support reserve** that
Grimmond will not casually remove. Ordinary harvesting stops when safe pulls reach zero.

A later Support branch capability, **Set a brace**, may convert exactly one reserve pull into
recoverable stock by consuming:

- one world resource with hardness ≥55;
- one with flexibility ≥45;
- 10 essence;
- one world turn at the site.

The selected resources and resulting extra pull are previewed. A site always retains at least one
support unit and can be braced at most once in the first slice. This creates a deliberate exchange of
known materials for scarce deep yield without permitting total strip-mining or a recursive brace
economy.

Numbers are debug tuning. The permanent invariant is that the operation is deterministic, visibly
changes saved site state and never risks a companion's life on a hidden roll.

## Yield and provenance

Each pull produces the site's authored bulk world resource and, where the source supports it, one
property-bearing mineral sample. Outputs record the realm/site provenance. Grade is derived from the
saved seam profile and is not rerolled per relaunch.

Unique deep sites are finite and never enter anchored-realm renewable production. A deep site that
has no safe pulls remains visible as an exhausted cavity with its extraction history. The Recycler,
Distillery and gear crafting consume its outputs under their own rules.

## The Deep Works station

The base station is a planning table, sample bench and support yard—not a mine entrance. Its first
card lists every discovered deep sign across active and dormant anchored realms, current safe pulls,
known output and revisit availability.

Use three short station-owned branches:

- **Read:** Sound depth; later clearer resource/grade preview from existing observations.
- **Reach:** Field-pick thresholds and access to harder seam profiles; does not create resources.
- **Support:** Set a brace and later authored support choices only when they produce a new decision.

Home-posted Grimmond uses the ordinary Deep Works discount; party XP contributes keeper-earned tier
under `building-staffing-current.md`. Grimmond need not occupy the party after the account has learned
Sound depth, though his field presence may reduce the brace cost through the standard Home/Party
trade-off only if that benefit is authored visibly later.

## Complexity boundary

No underground map, mining crew, lift, rail, fuel, cave-in chance, oxygen, permanent injury, ore
processing queue, respawning deep deposit or offline excavation is added. Deep sites do not become
anchored-world production nodes.

## Required fixtures

1. The same seed places the same inert sign before and after Grimmond; building the station changes
   interpretation/capability, not generation.
2. A seam never yields a resource absent from its saved world profile.
3. Safe pulls and brace state survive force-quit and anchored revisit exactly.
4. No failed interaction consumes a turn or material when hardness requirements are unmet.
5. Bracing consumes previewed weakest-qualifying resources, adds one pull and always leaves support.
6. Exhausted sites remain in World History and never replenish or feed passive realm production.
