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

**Historical status:** the separation, ecological families and body-derived reward rule remain settled.
The pure removal of material quality described below is **withdrawn as implementation direction** by
Decision 292 while the hybrid family-plus-band proposal is under Aimee's review. Do not dispatch the
pure-no-grade migration from this historical entry.

World resources are named yields from ground, flora and sites. Creature materials are body-derived animal
parts. Both remain slot-free but have separate player-facing reserves and Return groups. Creatures must
support pressure-biased terrestrial, shore, aquatic and aerial ecologies; fishlike life is water-bound,
while feathered, furred, plated/scaled and chitinous forms produce causally corresponding materials.

Remove generic quality as the creature's **primary identity** and remove unrelated random world-resource and
curio drops from ordinary animals. Preserve exact functional properties and source knowledge. A later
correction permits one rare, explicitly territory-sourced gear roll per victorious ordinary encounter; it
does not make gear a body part. Full current schema, habitat and reward rules are in
`creature-ecology-and-materials-overhaul-current.md`.

The remainder of the original decision removed universal grade entirely and reassigned every consumer to
family/properties/maker state. That comparison is retained in the ecology authority for history, but it is
not current implementation authority while Decision 292 is open. World-material and Creature-material
reserves remain distinct under either outcome.

## 285. Known Gold before mining access is deliberate progression

**Date:** 21 August 2026

The game may teach Gold before the active party can extract it. A disclosed unavailable Gold seam/world gives
the player a reason to improve a Field Pick and deliberately write that world later; binding is not blocked.
Extraction is based on the best qualifying pick equipped by the departing party, not Binder level. Iron is
rank 0 to prevent a Blacksmith construction deadlock; Gold is rank 2. Under-equipped Use Tile costs no turn
and changes nothing. The old “three-resource experiment” is superseded: Iron/Gold/Adamant are first vertical
fixtures for the complete data-driven mineral table in `resource-extraction-progression-current.md`.

## 286. Base opens on the Binder House; revised to three village districts and no duplicate House

**Date:** 21 August 2026

The Base root is the Binder House/yard, not House/Village tabs. Its six hotspots are Writing Desk, Library,
Constellation, Workshop, Party and yard Essence Spring. Bestiary is inside Library. Storehouse is a separate
town-supplying building in The Commons. Left/right/down open Commerce Row, Makers' Row and The Commons; the
House is never duplicated as a district tile. Village buildings progress absent → known buildable → built →
improved and may carry temporary truthful attention. The town will never be damaged, defended, repaired or
rebuilt.

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
Current encounter scaling remains the sole source primary until its deterministic implementation/test gate
closes; Aimee's phone feel card is nonblocking and may remain `readyToTest`. Source-complete items are
accepted or corrected, not reimplemented. Tutorial remains dead last.

## 289. Encounter-scaling phone acceptance is not a queue gate

**Date:** 21 August 2026

Encounter scaling remains active until deterministic rules, receipts and automated/simulator matrices are
green with no known P0 intended-Normal defect. Aimee's subjective combat-feel card then remains
`readyToTest` and does not block Writing/arrival/field/Home implementation. Later phone evidence may reopen
scaling at its real severity.

## 290. Deep-water aquatic life and rare ordinary encounter gear are valid

**Date:** 21 August 2026

Aquatic species may spawn and roam through connected shallow and deep water. Deep-water occupants cannot be
entered under current movement and become ordinary combat targets only if they reach shallow water or a
later legitimate deep-water interaction exists. Ordinary animal victories receive one initial 3% eligible
gear roll per encounter—not per creature—framed as recovered territory gear. Body-derived materials remain
independent; keys, quest items, authored uniques and apex weapons are excluded.

## 291. Library owns Bestiary and grows from folded paper into books

**Date:** 21 August 2026

Bestiary moves under the Library. The Library root is a visual room/bookcase with Diaries, Bestiary,
Dictionary, Field Notes and World History shelves. Real collection counts derive paper/folio/softbound/
hardcover stages; each traveller diary grows from its own recovered-page count. Exact behavior is in
`library-shelves-current.md`.

## 292. Hybrid material identity + six-band quality is recommended, not yet settled

**Date:** 21 August 2026

Game Design recommends material/family identity for capability, six discrete grey/white/green/blue/purple/
orange bands for yield/object quality and value, and gear item level/output quality derived from recipe,
inputs and maker cap. Same domain+family+band resources stack. This remains an open Aimee decision under
`loot-quality-hybrid-review-current.md`; Engineering must not implement the pure-no-grade migration or the
hybrid until it is settled.
