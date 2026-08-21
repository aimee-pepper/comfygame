# Decisions — Session 19

This log continues the chronological record after Decision 282 on the reconciled main line. Detailed living
authorities named below govern implementation; this file preserves why the direction changed.

## 283. Field pickup feedback rises locally rather than flying to a counter

**Date:** 21 August 2026

On successful field collection, show the recovered icon at its source, raise it about 1.5 tile heights and
fade it locally. Authoritative quantity updates immediately and a compact counter may pulse, but the icon
does not travel across the screen. Same-family multi-yield aggregates as `×N`; animation remains nonblocking,
edge-clamped and transaction-independent. This preserves spatial causality and avoids trajectory clutter.
Exact timing/burst behavior is in `field-feedback-and-loot-presentation-current.md`.

## 284. Creature materials are distinct from world resources and derive from ecology/body

**Date:** 21 August 2026

World resources are named yields from ground, flora and sites. Creature materials are body-derived animal
parts. Both remain slot-free but have separate player-facing reserves and Return groups. Creatures must
support pressure-biased terrestrial, shore, aquatic and aerial ecologies; fishlike life is water-bound,
while feathered, furred, plated/scaled and chitinous forms produce causally corresponding materials.

Remove the generic material-quality ladder from primary identity and remove unrelated random world-resource,
gear and curio drops from ordinary animals. Preserve exact functional properties/provenance. Full schema,
habitat and reward rules are in `creature-ecology-and-materials-overhaul-current.md`.

## 285. Known Gold before mining access is deliberate progression

**Date:** 21 August 2026

The game may teach Gold before the active party can extract it. A disclosed unavailable Gold seam/world gives
the player a reason to improve a Field Pick and deliberately write that world later; binding is not blocked.
Extraction is based on the best qualifying pick equipped by the departing party, not Binder level. Iron is
rank 0 to prevent a Blacksmith construction deadlock; Gold is rank 2. Under-equipped Use Tile costs no turn
and changes nothing. The old “three-resource experiment” is superseded: Iron/Gold/Adamant are first vertical
fixtures for the complete data-driven mineral table in `resource-extraction-progression-current.md`.

## 286. Base opens on the Binder House; the village grows but is never damaged

**Date:** 21 August 2026

The Base root becomes House/Village. The House is a four-zone cutaway containing Writing Desk;
Library/Constellation/Bestiary; Workshop/Storehouse; and Party. Firepit and Essence Spring remain outside.
Village buildings progress absent → known buildable → built → improved and may carry temporary truthful
attention. The town will never be damaged, defended, repaired or rebuilt.

Obscure stations use functional silhouettes plus standardized pictogram/name signs. Construction,
contribution, stock-refresh and waiting events create a warm restrained glow that clears when the exact
content is checked. Details are in `home-house-and-village-current.md`.

## 287. Character detail is Stats / Gear / Skills / Gambit; Diary deep-links to Library

**Date:** 21 August 2026

Remove the invented generic Story tab. A Diary action opens the exact person's Library diary/dossier and
Back restores the character/tab. Rename the ambiguous Combat tab to Skills because it is the combat skill
tree. The production tree must be a real graph. Dashed alternate hybrid connections are OR parents: own the
solid parent or named dashed parent, then still spend one point. They are not extra AND requirements or free
nodes. Exact behavior is in `party-character-surface-current.md`.

## 288. Broad causal-presentation ideas require exact Gates A–G before cross-lead dispatch

**Date:** 21 August 2026

`first-three-worlds-execution-plan-current.md` replaces the broad phase sketch as cross-lead handoff
authority. Every Engineering/Asset packet states live status/hash, player outcome, exact included behavior,
dependencies, exclusions, rework risk, automated and phone acceptance, receipt language and displaced item.
Current encounter scaling remains the sole primary until it closes; source-complete items are accepted or
corrected, not reimplemented. Tutorial remains dead last.
