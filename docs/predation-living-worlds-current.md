# Predation and living-world behavior — current design

**Status:** Current bounded v1 design; thresholds and salvage fraction are playtest values.  
**Supersedes:** Simulation-heavy or ambiguous choices in `living-worlds-spec.md`.

## Purpose

Predation makes the generated food web visible in play. It should create motion, warnings and an
occasional tactical opportunity—not a population simulation, waiting strategy or ecosystem the
player must maintain.

## Scope boundary

Creature-on-creature behavior runs only for creatures currently within the Binder party's active
line-of-sight/awareness calculation. Previously revealed fog is not enough. Nothing resolves in an
unobserved part of the map, while the app is closed, between expeditions or during an anchored
realm's dormancy.

There is no population count, reproduction, starvation, migration, food meter, off-screen attrition
or long-term ecological drift. A world's authored cast remains fixed; individual map encounters may
still be removed during the run.

## Predator/prey test

A non-apex creature treats another non-apex creature as prey when all are true:

1. they are different generated species;
2. the hunter can detect the target using its ordinary sensory/line-of-sight rules;
3. hunter armament total exceeds target armament total by at least **25**;
4. hunter size exceeds target size by at least **10**, or armament advantage is at least **40**;
5. the hunter is not already pursuing the Binder party.

These thresholds are debug-exposed. They derive roles from traits rather than assigning hidden
predator labels. Apexes remain deliberate encounters: they neither hunt nor are consumed. Sessile
predatory flora may threaten adjacent prey but never moves.

## One local decision per world turn

After the player's world action and before ordinary pursuit of the party:

1. Each aware prey gets one local flee opportunity from its nearest detected eligible hunter.
2. Each aware hunter without a party target chooses its nearest eligible prey, stable-ID breaking
   ties.
3. A mobile hunter moves at most one passable neighbouring tile that reduces distance. This is a
   local neighbour choice, not a full path search.
4. If hunter and prey are adjacent after movement, predation resolves immediately and removes the
   prey.

Fleeing similarly chooses one passable neighbour that maximizes distance without stepping closer to
a second known hunter. If no better tile exists, the prey stays. Initiative then stable ID controls
order so save/reload produces the same result.

Instant resolution is deliberate. Playing an invisible combat encounter over several rounds adds
state and latency while giving the player no meaningful combat controls. The visible approach is the
intervention window: step between them, engage the hunter, lure movement elsewhere, or let the kill
happen.

## Carcasses

A predation kill leaves a visible carcass on the prey's tile if that tile can hold one. Harvesting it
takes one world turn and yields **50% of the prey's ordinary material quantity, rounded down with a
minimum of one eligible sample**, preserving the prey's generated sample grades/properties.

Carcasses do not decay on a timer in v1 and do not attract scavengers. They disappear when harvested,
the tile crumbles or the disposable expedition ends. Anchored-run carcasses persist only as part of
that saved active expedition state; returning later does not simulate additional deaths.

The hunter gains no level, healing, permanent buff or “fed” state. Otherwise waiting for predators
to snowball would become an optimization loop and require another invisible status vocabulary.

## Group motion

Group motion is a small visual layer, not flock simulation:

- it runs only as a **lexicographic tie-break** among neighbouring tiles already tied for the
  creature's primary flee, hunt or party-pursuit movement score;
- an unarmed specimen (`armament.isUnarmed`) prefers a tied tile that leaves it within two tiles of
  its nearest visible same-species peer, then the smaller peer distance;
- an armed specimen prefers a tied tile that is not adjacent to a visible same-species peer, then
  the larger nearest-peer distance;
- no creature moves solely for grouping, changes target, accepts a worse primary movement score or
  searches beyond the already-enumerated local neighbours;
- stable tile order is the final tie-break, so save/reload and creature-array shuffle agree.

Expose one DEBUG on/off comparison. If the tie-break itself causes measurable phone-turn latency in
a dense visible food web, disable it without changing predation receipts or saves. Predation is the
gameplay-bearing behavior; grouping stores no independent state.

## Player interaction

The existing Lure remains party-directed and does not gain a special predator command. Nevertheless,
predation may emerge from ordinary positioning: drawing one creature through another's awareness can
change their local choices. No bespoke bait-placement UI is required.

The Bestiary records a witnessed predator/prey relation only after the player sees it resolve. This
is observational knowledge, not a guarantee that every member of that identity always hunts the
other.

## Legibility

- A hunter choosing prey shows a one-turn intent line/marker before or with its move.
- Fleeing uses a distinct brief movement cue.
- A kill produces one concise event: **“The iron-backed pursuer brought down the pale grazer.”**
- The carcass states reduced recovery before harvest.
- No off-screen combat log appears for events the player could not see.

## Implementation invariants

1. Predation never removes a traveller, page, site occupant, tamed companion or narrative entity.
2. Creature processing is deterministic from saved state and stable order; force-quit cannot reroll a
   kill or carcass.
3. At most one creature-on-creature move/action occurs per creature per world turn.
4. Unaware creatures remain exactly as generated.
5. Predator kills do not award party XP; harvesting the carcass awards materials only.
6. A barren/no-producer world still cannot generate an ordinary food web; this system does not
   backfill prey into it.
7. Group preference changes only an otherwise tied local step; it cannot alter target, movement
   count, path length, awareness or whether predation/contact resolves.
8. Unarmed cohesion and armed separation are deterministic under creature-array shuffle and add no
   saved group/flock identity.
