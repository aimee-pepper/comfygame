# Combat Tree v2 — Distiller effect review

**Status:** Aimee review required; no live effect change authorized  
**Roadmap:** `combat-tree-v2`  
**Related:** DRQ-191; `apothecary-coating-identity-current.md`

## The conflict

Distiller currently promises: reduce each positive world-resource ingredient in a coating by 40%,
rounding up with minimum one. Every settled coating uses one unit of each named ingredient and one
selected qualifying world resource. Therefore every requirement remains one and the node does
nothing. Increasing recipe counts to justify a discount would make ordinary coatings compete harder
with writing/continuation and is not recommended.

## Recommendation — two successful self-coating hits

When the exact owner uses one coating item on their own eligible physical weapon, prepare two charges
instead of one. A successful eligible direct weapon hit spends one; misses, non-weapon techniques,
carried damage and status ticks spend none. Encounter end clears unused preparation under the same
boundary as ordinary coatings. The item itself is consumed once.

Why this is preferred:

- immediately functional with all four existing recipes;
- personal node ownership is visible at the moment of use;
- no new bound/nonstacking inventory subtype or Home beneficiary selector;
- reduces effective resource cost per landed coated hit without changing recipe affordability;
- creates a concrete combat-build payoff rather than another station percentage; and
- keeps Envenom distinct at three inventory-free Poison charges.

Prepared Venom remains visibly ineligible while Envenom is armed because it is weaker and redundant.
A two-charge Burn/Bleed/Dazzle coating may coexist with Envenom; each successful hit applies/spends
its own legitimate preparation once.

## Alternatives not recommended

1. **Bound discounted craft:** choose the trained beneficiary at the Apothecary and waive one named
   ingredient. This works numerically but requires nonstacking bound coating identity, beneficiary
   selection and awkward reassignment rules for a modest passive.
2. **Batch output:** produce two coating items from one recipe. This silently duplicates an inventory
   object, complicates capacity/Waiting and can be handed to anybody, erasing personal ownership.
3. **Raise all recipe counts:** preserves the old percentage but worsens the baseline economy for
   every player without Distiller merely to make one node function.
4. **Keep it dormant until later recipes:** violates the requirement that every purchasable Combat
   Tree v2 node have a real consumer at promotion.

## Acceptance if approved

All four coatings; exact owner self-use versus ally/other-owner use; two successful hits; misses and
ineligible event types; save/relaunch between charges; encounter-end expiry; Envenom compatibility;
Stonebark/status max refresh; no duplicated item; one inventory consumption; and disabled/empty-v2
parity.
