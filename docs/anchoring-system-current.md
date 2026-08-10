# Current Design — Anchoring

**Status:** implementation-facing current design. This document replaces the superseded tether model
in `companions-base-anchoring-spec.md`. Rules marked **Placeholder** are safe to implement reversibly;
they are not permanent narrative canon.

## Purpose

Anchoring is how a temporary written world becomes a permanent, revisitable realm and is literally
the act of binding that realm back into the Atlas. It should turn a memorable expedition into a
lasting place without turning the game into real-time upkeep or a punitive worker-management sim.

## Settled foundation: three routes, one result

The three-route decision in `archive/decisions-session-7.md` remains authoritative:

1. **Anchor at bind.** Pay a premium before generation; the world is born anchored. This is the
   deliberate route for a world the player is writing for a known purpose.
2. **Use a natural anchor point.** Some worlds generate a discoverable **Atlas Seam**. Reaching it and
   paying its lower binding cost anchors the world.
3. **Place a crafted anchor.** Carry an expensive crafted **Anchor Frame** (working name) and place it
   at a valid location. This preserves a world worth keeping even when it has no reachable natural
   anchor point.

All three routes produce exactly the same durable state. There is no lesser tether state, no hidden
grace list and no difference in the resulting world's quality.

Do not call the crafted object a Waystone: that name is already used by the Apothecary's return-home
consumable.

## Player-facing lifecycle

### Before an expedition

- The bind screen offers **Born anchored** as an explicit paid option.
- It previews the exact premium before confirmation.
- Choosing it is a commitment to keep the generated world; it must not secretly improve the roll.

### During an expedition

- A natural anchor point is a visible site, not an invisible world property.
- If the player brought an Anchor Frame, valid placement is clearly signalled.
- The player sees the exact cost and consequences before completing either action.
- Anchoring immediately banks the world's identity and persistent state. An ordinary expedition
  failure after that point does not erase the realm.

### Atlas Seam — natural route

- **Atlas Seam** is the current site name: a place where part of the old binding still catches.
- Working appearance rate is **25% of ordinary generated worlds**, exposed in debug tuning. It is not
  guaranteed and is not made more likely by writing a particular pressure.
- It may be discovered before Tovin as an inert, half-understood landmark, but cannot be used until
  the Anchorage is built.
- Reaching it never anchors automatically. The player inspects it, sees the exact cost and confirms.
- Working cost is `max(10 essence, 25% of that world's born-anchored premium)`, rounded up.
- Once used, the site remains part of the anchored realm's history and cannot be paid twice.

### Anchor Frame — crafted route

- **Anchor Frame** remains the working item name and is made through the Anchorage rather than
  pretending it is ordinary Blacksmith equipment.
- Its recipe is expensive, property-based and paid before departure: 2 world resources at hardness
  65, 2 at density 65, 1 at flexibility 55, 1 at reactivity 65, plus 60 essence. Six distinct pieces
  are consumed weakest-qualifying-first. Values remain debug tuning; see
  `adamant-demand-audit-current.md`.
- It occupies one field-kit/satchel slot and is consumed only after successful placement.
- Placement is allowed on a visited, traversable, non-hazard tile while not in combat. It cannot
  replace a portal, site, resource node, crack or void tile.
- Placement shows a confirmation and requires no second essence payment: the frame itself is the
  middle-cost route.
- A successfully placed frame becomes a persistent landmark in that realm.

### After anchoring

- The realm appears in Tovin's **Anchorage** and may be revisited.
- Its seed, layout, named discoveries, depleted unique finds and other persistent state remain.
- Ordinary renewable resources may replenish according to their own rules.
- A realm cannot collapse through passage of wall-clock time or while the app is closed.

## Cost and route balance

The exact formula is a **Placeholder**, but these relationships are current:

- Natural anchor point: cheapest route; payment comes after exploration and carries discovery risk.
- Crafted Anchor Frame: high material cost; buys certainty after the player has seen the world.
- Born anchored: highest direct binding premium; buys certainty before seeing the world and avoids
  consuming a carried item.
- Costs may respond to the world's instability and exceptional value, but the complete number must
  be shown before the player commits.

Natural anchor points should not be guaranteed in every world. Guaranteeing them would erase the
crafted route's purpose. Their appearance rate and the three relative costs are balance data for the
debug menu, not story rules.

## Sustain and dormancy

Sustain is a **calculated obligation, not a new inventory currency**.

- Settlement happens only when an expedition concludes and the player returns to base. It is never
  wall-clock based.
- A realm's own assigned production covers its obligation first. Any remaining shortfall is shown
  clearly in the Anchorage before the next settlement.
- **Placeholder:** the first anchored realm has no sustain obligation. Additional realms create a
  soft capacity limit through escalating obligations rather than a hard slot cap.
- If an obligation cannot be met, the realm becomes **dormant**, never deleted. A dormant realm does
  not produce and cannot be visited until the player pays a clearly previewed reactivation cost.
- Dormancy preserves the realm's saved state and its place in the player's history.

### Settlement interaction

- Remaining shortfall is paid in **essence**, the same currency used to bind worlds.
- Return brings the player to a short settlement summary before another departure. Nothing ticks
  while this summary is open.
- The player sees every realm's production, obligation and net shortfall, then chooses which
  shortfalls to cover. The game does not silently spend essence or choose a realm to lose access to.
- Any active realm left unpaid becomes dormant when the player confirms settlement.
- The free first realm has zero obligation and never needs a payment choice.
- Reactivation is a separate, previewed Anchorage action; it does not happen automatically when the
  player later has enough essence.

The first implementation does not need worker gambits or a simulation-heavy mission table. Visible
aptitudes and a legible production/obligation summary are sufficient. Deeper assignment behaviour can
be added only if play shows that it creates meaningful choices.

## Companion safety

Permanent companion or animal loss is not part of the current anchoring model.

- A dangerous assignment may reduce output, cause a temporary injury/setback or force a worker home.
- If a realm becomes dormant, assigned companions return safely to base.
- The UI must warn about expected setbacks before assignment.

This supersedes the proposed permanent-loss rows and the statement that unstable worlds can lose
workers in `companions-base-anchoring-spec.md`. Resource and expedition risk already supply stakes;
erasing a recovered character would work against the game's restoration arc.

## Tovin and the Anchorage

Tovin unlocks and runs the **Anchorage**, which is a portfolio and binding workspace rather than a
shop counter. Its first useful version shows:

- every anchored realm and whether it is active or dormant;
- route used to anchor it (history only; no mechanical caste);
- sustain obligation, production contribution and projected shortfall;
- assigned companions and relevant aptitudes;
- reactivation action and exact cost for dormant realms;
- revisit action.

Tovin's own arc should teach why restraint matters without suggesting that the game will erase a realm
for an imperfect choice.

## Atlas progress

Anchoring is literally re-binding realms into the Atlas. The Atlas measures progress in **realms
re-anchored**, not crafted components. However, this does not yet settle how a realm qualifies as a
meaningful unit of Great Work progress or how many the ending requires; `archive/decisions-session-9.md`
explicitly leaves the required count undecided.

**Placeholder for implementation:** track every anchored realm and its distinct signature/history,
but do not award an ending-facing score yet. This preserves the data needed for a later rule without
letting disposable low-cost worlds determine the story prematurely.

## Explicitly outside the first anchoring build

- Reality-layer reset and what survives it.
- Re-recruitment after reset.
- A final Atlas threshold or ending condition.
- Tam's unique act.
- Worker gambit authoring.
- Permanent loss.

None of these should block Tovin, the Anchorage, the three routes, revisiting, or dormancy.

## Debug controls

Expose these as design-tuning values where practical:

- natural anchor-point appearance rate;
- base cost and instability/value scaling for each route;
- Atlas Seam fraction of born-anchor premium;
- Anchor Frame recipe property thresholds and quantities;
- free-realm allowance;
- sustain escalation by active realm count;
- production contribution by aptitude;
- dormancy reactivation discount/cost.
