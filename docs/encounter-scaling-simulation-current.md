# Encounter Difficulty Scaling — Simulation Profile

**Status:** approved direction, reversible DEBUG/simulation profile rather than final shipped
coefficients. Prompted by playtest: ordinary encounters and especially apexes are too easy for a
developed five-person party.

## Design goals

- A larger, more developed active travel party faces materially more pressure.
- Scaling preserves creature identity and visible world causality.
- Ordinary fights remain phone-readable; apexes feel like optional deliberate bosses.
- Difficulty comes first from composition and tempo, not inflated health alone.
- No foe appears from nowhere when combat opens.

## Correct party reference

The current encounter path compares only Binder with the legacy single `companion` accessor. Replace
that input with every valid active travel-party member: Binder plus all selected `activeParty`
travellers. Sort their current levels and use the **upper median** (for an even count, the higher of
the two middle entries).

Throughout this document, `partyCount` means that complete combat party including the Binder. It is
therefore 1–5, never the number of selected companions alone. Upper-median examples are
`[4] → 4`, `[4,9] → 9`, `[4,5,12] → 5`, `[2,4,7,15] → 7` and `[2,4,6,8,20] → 6`.

This makes three developed companions count without letting one veteran punish a mostly new party.
Diagnostics show the full input list and selected reference.

## Ordinary encounter budget

Start simulation with:

`foe equivalents = 1.0 + 0.5 × (activePartyCount - 1)`

Spend whole equivalents on additional actual visible foes up to the existing three-foe combat cap.
The half-equivalent remainder alternates deterministically between no upgrade and one stronger
specimen/level step. Use the low bit of a stable FNV-1a payload containing encounter-scaling version,
persisted map seed and triggering `WorldEnemy.id`; never use Swift `Hasher`, redraw RNG or current
turn count. The result is computed once when combat opens and saved in encounter diagnostics, so
relaunching cannot reroll difficulty.

Crucial causality rule: budget cannot synthesize an off-map combatant. It may be spent only through
one of these explicit routes:

1. world generation places an appropriately sized local group whose members are ordinary map
   entities and obey ecology/visibility;
2. encounter collection activates additional already-visible/awake nearby entities within the
   settled grouping radius; or
3. unspent budget becomes a bounded level/specimen-strength adjustment on the actual participants.

For the first simulator, convert each whole equivalent that could not be represented by a visible
local foe into +1 shared foe level, then add the deterministic half-equivalent upgrade when it fires;
cap this conversion at +2. This is a reversible comparison rule, not a settled balance value. It is
applied once after the ordinary Stability/greed level result and is reported separately. Never clone
the triggering foe, change its traits or create a map ID to satisfy a budget.

Choose and fixture the smallest route that preserves existing ecology. Never append a hidden foe in
`beginEncounter` merely because the budget has room. Entering combat must account one-to-one for the
visible world entities that entered it.

World Stability and greed retain their existing foe-level contribution once. Do not multiply that
danger again by party size.

## Apex profile

Apexes stay visible, stationary and opt-in; Unbind remains available. Begin testing:

- level floor: `max(ordinary world-derived foe level, upper-median party level + 2)`;
- HP multiplier: `min(2.4, 1 + 0.35 × (partyCount - 1))`;
- offence multiplier: `min(1.4, 1 + 0.10 × (partyCount - 1))`;
- action slots: one for party 1–2, two for 3–4, three for 5.

Multiple apex actions are genuine turns in an explicit round schedule, not an opaque damage
multiplier. Prefer distinct legal targets/actions; the same high-damage action cannot repeat three
times without a telegraphed creature rule. Conditions, protection, passed-out members, target reach
and gambits all resolve through the ordinary combat engine.

For the first reversible comparison, use one explicit generic apex rule, shown before the first
action as **Relentless — N actions each round; follow-up strikes are lighter**:

- slot 1 is the creature's ordinary full derived action, including its delivery and eligible
  affliction;
- slots 2–3 are single-target follow-up strikes at 60% raw output, still respecting reach, evasion,
  armour/Ward/insulation and Ground, but they neither add nor refresh bleed/burn/poison/dazzle;
- follow-ups prefer a standing legal target not already targeted by this apex during the round, then
  fall back to any legal target; taunt/interpose/protection still override preference normally;
- distribute the saved apex slots through the round rather than placing all of them consecutively:
  retain its initiative slot, then insert each follow-up after the next approximately equal block of
  living party turns. The resolved `TurnSlot` schedule is frozen in the encounter so force-quit and
  pass-outs cannot reorder the current round.

The 60% follow-up and distribution rule are DEBUG/playtest values. The structural requirement is a
telegraphed, saved, interleaved schedule whose extra tempo is not disguised as one damage multiplier
or three full repeated area/status attacks.

## DEBUG tuning and telemetry

The encounter preview shows:

- active party IDs/levels/count and chosen upper median;
- Stability and greed level contributions separately;
- actual visible candidate foes, grouping radius and inclusion reason;
- ordinary budget, whole/remainder spend and any unspent conversion;
- final foe levels/stats and map entity IDs;
- apex floor, HP/offence multipliers and action-slot schedule;
- projected opening-round incoming damage range against the actual party;
- expected rounds-to-defeat in a simple neutral-attack baseline, labelled as simulation.

Sliders: ordinary per-extra-member budget, foe cap (DEBUG comparison only), grouping radius, remainder
upgrade, apex level offset, HP/offence per member and action-slot thresholds. Reset restores this
profile. Export the exact tuning values and deterministic fixture result. The first comparison set is
defined in `encounter-scaling-candidate-profiles.md`; selecting a named profile changes only DEBUG
tuning, never the persisted global campaign difficulty.

## Acceptance before shipping numbers

1. Solo, 2-, 3- and 5-person fixtures at low/mid/high levels produce monotonic pressure without
   violating the three-foe cap.
2. One over-levelled member beside low-level allies does not dominate the level reference.
3. Every combat foe maps to one visible persisted `WorldEnemy`; defeat/removal updates that entity.
4. Same save/seed/party/tuning produces the same group and remainder spend after relaunch.
5. Ordinary five-person fights do not become apex-length HP slogs.
6. Apex five-person fixtures exercise three-action tempo without unavoidable one-round party defeat.
7. Unbind, detection/approach and accessibility remain unchanged by scaling.
8. Device playtests compare at least three candidate profiles before these numbers become settled.
