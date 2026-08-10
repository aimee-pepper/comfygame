# Current Design — Building Staffing

**Status:** Implementation-facing correction of `building-staffing.md`. Formula values are reversible
debug tuning; assignment tension and non-stacking tier rule are current.

## Three assignments

A companion is in exactly one place:

| Assignment | Benefit |
|---|---|
| **Party** | Fights, gains ordinary XP; their persistent level may unlock earned tiers at their building |
| **Home** | If assigned to their own building, discounts its paid actions at its current effective tier |
| **Anchored realm** | Contributes through Worldwork; no building discount or building-specific XP bonus |

Use **assigned** in UI rather than “posted.” Assignment never taxes XP and never creates passive
wall-clock progression.

## Purchased and earned tiers

The old proposal wrote `paid tier + keeper tier`. That would let a player buy and level past the
authored station catalog, and it contradicts the intended “two routes to the same tier.” Use:

`effective tier = max(purchased tier, keeper-earned tier)`, capped at the station's `maxTier`.

- Purchased tier is permanent and immediate.
- Keeper-earned tier is derived from that companion's persistent level and remains available wherever
  they are currently assigned; taking them home is not required to remember what they learned.
- Buying a tier early is not refunded if the keeper later earns it. The player paid for earlier access.
- An earned tier satisfies the same station-tier gate and branch rung as its paid counterpart. The UI
  presents that rung as **supplied by the keeper**, not as an unpaid debt. A player may proceed to a
  genuinely higher paid rung without buying the now-redundant lower rung first.
- Do not insert the paid research ID or mutate purchased tier merely because a keeper earns it. Paid
  history remains truthful; availability and prerequisite resolution consult effective tier.
- Keeper level never generates a tier above authored station content.

Each owned station declares optional `keeperLevelForTier` milestones. Working defaults are levels
**8, 16 and 24** for tiers 1–3. A fourth or later tier is paid-only until authored otherwise. Explicit
station values override defaults so short and deep stations can pace differently.

## Home discount

Only a building's owning traveller assigned **Home to that building** grants its discount. The
station defines three tuning values:

- `homeDiscountBase`
- `homeDiscountPerKeeperLevel`
- `homeDiscountCap`

Working fallback: **10% base + 0.5 percentage points per level after 1, capped at 20%**. Balance may
vary by building, as Aimee requested.

The discount applies to essence and ordinary resource quantities for crafting, upgrades and paid
services. Positive resource requirements never fall below one; quantities round up after discount.
It does not discount:

- recruitment wants or narrative choices;
- anchoring/sustain obligations;
- another station's costs;
- inventory goods sold through the Exchange;
- actions with no price.

## Firepit and Tavern

- The Firepit has no owner and receives no discount or keeper-earned tier.
- Orsa upgrades the same station into the Tavern; she does not create a second building.
- Once the Tavern exists, Orsa follows ordinary owner assignment rules.

## Why the tension remains real

- Party creates long-term keeper level and gives access to that person's combat contribution now.
- Home creates immediate savings but no extra XP.
- World creates portfolio production.
- Purchased tiers ensure no party composition is mandatory for progression.

A high-level keeper eventually brings both a better station and a strong discount when brought home.
That is an earned late payoff, not simultaneous assignment: while home they are still absent from the
party and anchored work.

## Validation fixtures

1. Effective tier uses `max`, never sum, and cannot exceed `maxTier`.
2. Keeper milestones persist through reassignment and save/load.
3. Only the correct owner at Home applies a discount.
4. Discount rounding never makes a positive ingredient free.
5. Party and world assignments remove the home discount immediately.
6. Buying a tier and later earning it never refunds or duplicates it.
7. Firepit has no owner bonus; upgraded Tavern correctly recognizes Orsa.
8. Research/building gates use effective tier, so a keeper-earned tier never leaves a falsely locked
   station action.
9. A keeper-earned Tier 1 satisfies the matching branch rung and permits purchase of a real Tier 2
   upgrade without charging the redundant Tier 1 cost; paid-history flags remain unchanged.
