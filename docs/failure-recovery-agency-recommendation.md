# Failure Recovery Agency — Recommendation

**Status:** arithmetic correction is implementation-ready; player choice remains review-only under
DRQ-089. The configured 50% fraction remains playtest tuning. Safety categories in
`expedition-outcomes-current.md` are settled and do not depend on the choice.

**11 Aug sequencing decision:** complete and accept the typed return receipt plus outcome-wide
resource/item unit budgets first, retaining deterministic automatic item selection. The choice UI
in this document is not part of that Tier-A correctness checkpoint. Revisit it only after Aimee can
observe one trustworthy automatic Recovered/Lost receipt; otherwise agency, arithmetic and recap
defects cannot be distinguished during playtest.

## Recommendation

Replace automatic retention of discrete acquired items with a compact **What did you hold onto?**
choice at Base. Keep bulk world-resource quantities automatic. The proposed total-unit budget is a
small, explicit change from the live per-stack flooring rule; it must not be described as numerically
identical until Aimee approves that change.

This better fits Bookbinder because the player already made deliberate satchel, route and risk
decisions. Collapse/defeat should still cost unbanked opportunity, but the only lasting object-level
loss should not be a lottery over the thing the player cared about most.

## Exact first-slice rule

1. Resolve and permanently commit knowledge, XP, people/animals and protected finite narrative items.
2. Return all unused pre-departure property.
3. Apply the configured retained fraction automatically to bulk acquired world-resource quantities
   using the stack-independent apportionment below.
4. Expand newly acquired discrete gear, curios, keys and consumables into units. The recommended
   selection budget is `floor(total acquired discrete units × retained fraction)`, with a minimum of
   one when fraction >0 and at least one unit exists. Total-unit flooring prevents players changing
   the budget by splitting/merging stacks; the minimum-one mercy rule is deliberately more generous
   than live behavior for a one-item haul.
5. Preselect a deterministic set from a dedicated recovery seed frozen in the envelope, so the
   screen is never blank and a reproducible suggestion is the default. Do not consume or save the
   mutable world RNG merely because the player opened this choice. The player may swap
   selected/unselected units without changing the count, then confirm.
6. Bank selected units; name the rest under Lost. Value, rarity and player attachment do not change
   the numerical unit budget—the agency is precisely choosing which value to protect.

Do not count an entire stack as one slot. Ten identical consumables are ten discrete units; otherwise
stack merging becomes loss insurance. Property-bearing samples that behave as individual crafting
objects are discrete; fungible resource quantities remain bulk.

### Bulk resource arithmetic

The current `ResourcePool.scaled` floors each resource kind independently. It has the same
fragmentation defect as discrete items: at 50%, four different one-unit resources return zero while
four units of one resource return two. Resource variety must not increase the failure penalty.

Bulk remains automatic, but its total retained budget is:

`floor(total acquired resource units × retained fraction)`

Allocate it with deterministic largest-remainder apportionment:

1. give each resource `floor(its quantity × fraction)`;
2. rank remaining resource units by the fractional remainder of that exact share;
3. allocate the remaining budget one unit at a time to the largest remainders;
4. break equal remainders using a stable hash of `ExpeditionOutcomeID + ResourceID`, never mutable
   world RNG or catalogue order.

This preserves the intended total and approximates the original mix without a post-failure choice.
There is no separate minimum-one mercy for bulk: a one-unit total haul at 50% may be lost, while the
approved discrete-item correction retains its deliberate one-object mercy. Raw Essence and Motes
participate as ordinary bulk units; they are not secretly protected, but collecting other resource
types cannot make them change the total retention budget. The exact automatic allocation must be
frozen into the pending/return receipt so relaunch cannot reroll a tied remainder.

Candidate units preserve exact instance/build/provenance facts. Identical fungible consumables may
be grouped as a quantity control, but gear, curios, keys and property-bearing materials cannot be
collapsed into catalogue-ID counts for selection or recap. Stable candidate IDs are scoped to the
saved recovery envelope and survive UI reordering.

## Interruptibility

Failure writes a persisted `pendingRecovery` envelope before presenting Base. It contains frozen
outcome kind, acquired partition, automatic bulk result, discrete candidates, budget, deterministic
default selection and committed permanent rewards. Until confirmation, ordinary Base inventory must
not also contain those candidates.

The transition from active run to `pendingRecovery` is the expedition outcome commit: it clears the
active run only after the complete envelope and permanent rewards are durable. Anchorage settlement
may be prepared from the same outcome receipt but cannot advance twice if recovery confirmation is
replayed. The ordinary run recap is created only from the confirmed envelope, not recomputed from a
discarded run.

Force-quit resumes the same choice. Confirmation atomically banks selected items, records lost items,
clears the envelope and creates the recap. Reopening cannot reroll candidates/defaults or duplicate
the haul. If migration encounters an old already-resolved result, it never fabricates a pending choice.

## Presentation

- Title: **What did you hold onto?**
- Supporting copy states the exact count, e.g. “Choose 2 of the 4 things you found. Packed supplies,
  pages and knowledge are already safe.”
- Selected and Lost candidates remain visible together; tap swaps or toggles until the exact budget
  is selected.
- Group identical units for readability while exposing a stepper/quantity; never require ten rows for
  ten potions.
- `Keep suggested` confirms the deterministic default; `Reset suggested` restores it after edits.
- Confirm leads directly into the ordinary Recovered / Lost / Kept for good recap.

This is the only blocking post-failure decision. It contains no timer, premium spend, rescue payment
or second penalty.

## Why not weighted random or insurance

- Rarity-weighted retention remains a lottery and makes the rule harder to predict.
- An insurance consumable competes with the Waystone and punishes players for failing to predict
  failure before finding a beloved object.
- Automatically protecting the rarest item lets catalogue rarity—not the player—decide attachment.
- Unlimited “mark favourite” before an expedition cannot know what will be found and becomes another
  inventory setting.

## Comparison gate

Before settling, use the DEBUG outcome harness to show the same forced haul under:

1. current deterministic random selection;
2. player selection with deterministic default;
3. retained fractions 25%, 50% and 75%;
4. zero, one, mixed-stack and many-discrete-item hauls.

Track confirmation time, default accepted versus changed, which rarity/value was protected and
whether the recap was understood. The recommendation should be rejected if the choice routinely
feels like tedious inventory surgery rather than meaningful recovery.

Also report the live and proposed budgets side by side. Live code floors each exposed stack
independently, despite comments describing item selection as random; the proposed rule floors the
total unit count and then lets the player choose exact candidates. At least include fixtures where
the two differ: one item at 50%, two one-item stacks at 50%, one two-count stack at 50%, and mixed
property-bearing units. This prevents an agency test from accidentally testing a hidden generosity
increase instead.

### Exact live-versus-proposed arithmetic

The current `Inventory.randomlyKeeping` accepts an RNG but never reads it. It applies
`floor(stack.count × fraction)` to every stack and removes the lower-priority units inside that
stack. Therefore catalogue/bin boundaries—not randomness—change survival.

At the Recommended 50% fraction:

| Acquired discrete haul | Live per-stack result | Proposed total-unit budget |
|---|---:|---:|
| one one-off item | 0 | 1 *(mercy minimum)* |
| two different one-off items | 0 | 1 |
| four different one-off items | 0 | 2 |
| four identical items in one stack | 2 | 2 |
| two stacks of three | 2 total | 3 total |
| one one-off item + one two-count stack | 1 total | 1 total |

The fragmentation penalty grows at other configured fractions: at 75%, four different one-off items
still yield zero live survivors while a total-unit budget yields three. This is not a subtle UX
preference; it contradicts the stated “keep the configured fraction of acquired things” rule.

The identical defect exists for resources. At 50%, `[Ore: 1, Fibre: 1, Resin: 1, Raw Essence: 1]`
currently returns zero; stack-independent apportionment returns exactly two automatically. At 75%,
it returns three rather than zero. `[Ore: 4]` remains two/three respectively, so catalogue diversity
no longer changes the configured fraction.

Design recommendation is therefore two separable decisions:

1. **Arithmetic correctness:** compute one total-unit budget for all at-risk discrete acquisitions,
   independent of stack/bin boundaries, and a separate total-unit/apportioned budget for bulk
   resources independent of resource-kind boundaries. This should be corrected even if automatic
   selection is retained.
2. **Player agency:** let the player replace the deterministic suggested selection before confirming.
   This remains the meaningful review choice.

If Aimee prefers automatic recovery, use the same total-unit budget and a genuinely deterministic
outcome-ID-keyed selection over stable unit candidates. Do not retain the current per-stack flooring
and do not call it random.

## Required fixtures if approved

1. Budget and stack expansion cannot be changed by merging/splitting before failure.
2. Pending choice survives force-quit and resumes byte-equivalent.
3. Default selection is deterministic and cannot reroll.
4. Confirmation is atomic and idempotent; no candidate can be both banked and lost.
5. Bulk, pre-departure property and permanent rewards never enter the selectable pool.
6. Finite one-copy objects remain protected/recoverable under the existing completion boundary.
7. VoiceOver exposes selected count, candidate quantity and consequence without colour.
8. A no-discrete-item failure skips the choice and goes directly to recap.
9. Bulk resource fixtures at 25/50/75% preserve the exact total budget across one-kind and
   many-kind representations; equal remainders are outcome-ID deterministic and relaunch-stable.

## Live-code audit notes — 9 Aug 2026

- `endRunWithPartialHaul` currently banks everything and creates `lastExit` immediately; no pending
  recovery state exists.
- Bulk `ResourcePool.scaled` floors each resource kind independently, so varied one-unit hauls can
  lose everything at fractions that retain the same total quantity in one kind.
- `Inventory.randomlyKeeping` is deterministically per-stack, removes the lower-priority units and
  does not consume the RNG parameter at all; it does not choose randomly across the complete exposed
  haul.
- `protectedReturnCount` is the authoritative carried-property partition and must remain intact.
- The proposal remains review-only. These findings correct its implementation assumptions but do
  not authorize replacing the live rule.
