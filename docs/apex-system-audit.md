# Apex System Audit — 8 Aug 2026

**Implementation update, 8 Aug:** the encounter and reward loop is now wired. Throughstroke,
Living Hook growth, Warded Haft protection, Two-Natured strike selection, the cache bonus lottery,
and explicit apex bestiary sightings are live. Authored hunting affinities are now specified in
`apex-hunting-affinities-current.md`; implementation and anchored-world persistence remain later work.

**Current-authority correction, 11 Aug:** `minimap-disclosure-current.md` supersedes this audit's
earlier immediate-revelation recommendation. Apexes are optional and stationary, but their marker does
not bypass fog. They become visible through ordinary legitimate reveal/discovery or an explicit paid
knowledge effect. The earlier reveal-from-entry decision is retained below only as evolution history.

**Challenge disposition, 11 Aug:** apex difficulty is now **ready for deliberate phone testing, not
design-complete**. Recommended additive scaling gives an equal-level five-person party a +2 level
floor, 2.4× HP, 1.4× offence and three interleaved action slots. Do not add bespoke phases, immunity
cycles or inflated rewards before that exact fixture is played. The acceptance target is 3–6 rounds
with 1–3 meaningful defensive/target/resource decisions—not merely a longer health bar. If it dies
in two rounds without a decision, tune action tempo first, then durability, then offence, following
`encounter-scaling-phone-test-card-current.md`.

Source design: `apex-encounters.md`. Open implementation referral: Q49 in
`questions-for-design.md`.

## Clause-level status

| Design clause | Status | Evidence / deviation |
|---|---|---|
| An apex uses the normal creature model with an unaffordable budget | ✅ Built | Same trait allocator, lifted budget and stronger size/armament weighting |
| At most one per world | ✅ Built | One sample attempt; tested across generated worlds |
| Drawn by greed, instability, danger writing and sites | ✅ Built | All four contribute; greed is the strongest term |
| Never guaranteed | ✅ Built | Chance is capped at 55% |
| Deep in the map, never at entry | ✅ Built | Minimum distance 8; tested |
| Visible once legitimately discovered; never a hidden-contact ambush | ⚠️ Current disclosure correction | Its tile/marker must not bypass fog. Once legitimately revealed, its apex warning is explicit and approach remains voluntary; see `minimap-disclosure-current.md` |
| Never ambushes or hunts | ✅ Built | Detection radius zero; never wakes by proximity or moves |
| Contact is the commitment | ✅ Settled current rule | Adjacency never aggros an apex. Combat begins only when the player deliberately moves onto its occupied tile; this supersedes the older adjacent-contact prose |
| Materially harder for developed parties | 🧪 Ready to test | Additive party-power scaling is integrated; Recommended must be selected before a new bind until promotion. Five-person target is +2 level floor, 2.4× HP, 1.4× offence and three interleaved actions |
| Fleeing works at normal stability cost | ✅ Built generically | Flee always succeeds; no apex exception. Not covered in `ApexTests` |
| Guaranteed wild weapon on victory | ✅ Built | Every defeated apex rolls one of the eight |
| Ordinary-creature lottery | ✅ Built | 0.4% placeholder chance per defeated ordinary creature |
| Locked-cache lottery | ✅ Built | 3% world-weighted wild weapon bonus alongside the guaranteed cache reward |
| World-character weighting | ⚠️ Partial | Current code favours four IDs; complete eight-weapon profiles are now authored separately |
| Eight weapons, one unique rule each, not top-stat gear | ✅ As content | Eight mid-tier items and eight unique `WildRule` values; metadata tests pass |
| Two-Natured Blade | ✅ Wired | Actual strike resolution chooses the best damage matchup |
| Long Fang | ✅ Wired by data | Has far reach despite its short-haft fiction |
| **Barbed Edge** | ⚠️ Canonical affliction correction queued | Final identity is settled. Replace the current ordinary-Rend + separate-legacy double tick with one 3-damage/3-round max-refresh Bleed under `barbed-edge-apex-identity-current.md`; no freeze |
| Quiet Knife | ✅ Wired | Attacking preserves concealment |
| Bloodletter | ✅ Wired | Rend bleed receives a sentinel-duration value |
| Ranked Spear | ✅ Wired | Throughstroke carries half the landed damage into one additional foe |
| Living Hook | ✅ Wired | Per-instance encounter-win growth, separate from reforging and capped at +2 tiers |
| Warded Haft | ✅ Wired | 20% passive authored-type reduction, multiplicative with Ward |
| Exceptional butchery from exceptional traits | ✅ By inheritance | Normal butchery reads the apex's extreme vector |
| Distinct apex bestiary species | ✅ Built | Derived species retains its identity and gains an apex badge plus deduplicated sighting collection |
| Apex remains dead in an anchored world | ⏸ Blocked downstream | Defeated enemies leave the current run; anchored-world persistence is not implemented |
| Apex may guard named places | Open | Named-place/anchoring layer is not built |
| Pre-bind projection does not reveal apex presence | ✅ Current behavior | No apex-specific prediction is displayed |
| Strongest apexes require writable conditions | ✅ Design resolved | Conditions bias the awarded weapon, never guarantee appearance; implementation remains |

## Completion design

### 1. Finish the three inert weapons without creating perverse incentives — approved

- **Ranked Spear:** revise the rule from literal enemy ranks, which do not exist, to **Throughstroke**:
  the selected foe takes the full hit and one additional foe takes half damage. This preserves “it
  goes through and keeps going” without adding a complete enemy-rank system solely for one item.
- **Living Hook:** gain growth credit for an encounter won while equipped, not per hit or killing
  blow. Hits invite farming; kills create last-hit bookkeeping. Use milestone counts and cap its
  growth at two additional tiers so it remains a trade rather than becoming the best weapon.
- **Warded Haft:** reduce its authored harm type continuously while held and allow Ward to stack
  multiplicatively. The passive should be modest; the temporary skill remains the stronger answer.

### 2. Restore the cache route as a bonus, not a replacement — approved

At the placeholder 3% chance, a locked cache should add a world-weighted wild weapon **alongside**
its normal guaranteed knowledge/mote reward. Replacing that reward would make the exciting weapon
feel as though it consumed progression the player was promised.

### 3. Make apex identity explicit in the bestiary — approved

Record an apex badge/variant on its derived species entry and a separate apex-sighting collection.
Do not force every generated apex into one species called “apex”; what it physically is should still
come from its traits. This preserves the specimen model while making apex discovery completable.

### 4. Immediate map revelation — historical; superseded

This audit originally approved marking the apex from world entry. Aimee later settled the broader
explore-first rule after seeing minimap leakage in play: apexes, portals, writing and other POIs do
not appear through fog by default. Consent is instead protected when the apex enters legitimate view:
the warning is unmistakable, the creature remains stationary, contact is not automatic, and Unbind
remains available. An explicit invested scouting effect may reveal it earlier within the same
disclosure contract.

### 5. Add authored hunting signatures later — approved

Keep the current risk/value draw for ordinary apex encounters. Later, give each wild weapon an
environmental affinity or condition signature that greatly favours its apex/drop. This turns hunting
into a writing goal without making an exact condition combination guarantee the encounter.

### 6. Keep named-place apexes optional — approved

An apex may inhabit a named place, but must never block its required traveller, core clue or only
route. It can guard optional treasure or a side area. Consent outranks spectacle.

## Decisions — Aimee, 8 Aug 2026

1. ✅ Ranked Spear uses **Throughstroke**, not enemy ranks.
2. ✅ Living Hook grows from encounters won while equipped, capped at +2 tiers.
3. ✅ Warded Haft gives modest passive reduction and stacks multiplicatively with Ward.
4. ✅ At the 3% cache chance, the wild weapon is a bonus alongside the normal cache reward.
5. ✅ Add the apex badge/collection; underlying species remains trait-derived.
6. ↪️ **Superseded 9 Aug:** apex locations obey fog/discovery by default; the old immediate marker is
   historical only. Once revealed, the warning and opt-in approach remain explicit.
7. ✅ Add condition-favoured apex hunting later while retaining the current risk/value draw.
8. ✅ Named-place apexes are allowed only where they do not gate required content.

## Contact correction — Aimee, 11 Aug 2026

An apex does **not** aggro merely because the party becomes adjacent. The adjacent position remains a
safe last opportunity to inspect the disclosed tile, change equipment or route away. Combat begins
only when the player deliberately attempts to move onto the apex's occupied tile. The apex remains
stationary and does not step into the party.

This rule does not reveal an apex through fog: normal disclosure or an explicit invested scouting
effect must expose the tile first. Once disclosed, the tile must communicate that entering it begins
an apex encounter. Pathfinding may route beside a disclosed apex but must never auto-route through
its occupied tile. A direct one-step move/tap onto the disclosed apex is already deliberate and
begins combat immediately; a longer auto-path stops adjacent and requires that final explicit step.

Required fixtures distinguish `adjacent` from `entered occupied tile`, prove that waiting/looking/
interacting beside the apex spends no combat-opening state, and prove that the final direct step
freezes the deliberate-contact opening receipt.

## Composition boundary — affinities, scaling and rewards

The three apex layers resolve in this order and never multiply one another implicitly:

1. **Appearance:** the existing risk/value draw decides whether an apex exists. Party size, level and
   weapon affinity do not increase this chance.
2. **Encounter:** the generated apex keeps its trait/species identity, then
   `encounter-scaling-playtest-current.md` applies the frozen party-power level floor, apex-only HP,
   apex-only offence and saved action slots. Affinity conditions do not modify those stats.
3. **Reward:** only after a route actually awards a wild weapon do the satisfied conditions in
   `apex-hunting-affinities-current.md` modify the eight-way weapon weight. They do not reroll the
   apex, strengthen it or guarantee a result.

In a mixed apex/ordinary encounter, apply the apex multipliers only to the apex body. Any legitimately
present ordinary creatures retain their ordinary world-resolved stats and actions. They receive no
ordinary pressure HP or lighter follow-ups, and they are not swept into the apex HP/offence
multiplier. Real ordinary bodies still grant their own normal XP/loot if defeated. This prevents a
nearby animal from being inflated once as a party-size participant and again as part of an apex
encounter.

Required cross-system fixtures:

- the same apex seed/party/tuning has identical combat stats across neutral and affinity-matching
  worlds when ordinary world-derived inputs are held constant;
- affinity matching changes only the post-award weapon weights;
- a five-person mixed encounter gives the apex its frozen 3-slot profile, leaves ordinary companions
  at their resolved stats, and creates zero `ordinaryPressureFollowUp` slots;
- revealing the apex through an invested effect changes discovery/marker state only, not appearance,
  initiative, scaling or weapon weights;
- no pre-bind or fogged minimap view exposes apex presence merely because an affinity condition is
  satisfied.

## Challenge acceptance boundary — 11 Aug 2026

The first playable apex does not need a separate scripted-boss subsystem. Its identity should come
from the same extreme generated traits the player can inspect: armour/matchup, reach/initiative,
evasion, retaliation, delivery and emanation. Party-power scaling gives that identity enough time
and tempo to matter.

For the first comparison:

- a developed five-person party should face 3–6 rounds and make 1–3 meaningful choices involving
  target, defence, healing/resource use or retreat;
- no healthy on-level baseline member is removed before acting unless a clearly disclosed
  exceptional trait explains it;
- after the apex's pattern is understood, the fight should not routinely exceed seven rounds or
  spend more than 65% aggregate starting party HP;
- the extra action slots must remain interleaved and visibly lighter, never three consecutive full
  attacks;
- one build may counter a particular apex strongly, but no single item or node may be mandatory for
  every apex.

Tune in this order so evidence remains interpretable: action-slot placement/strength, HP
coefficient/cap, then offence coefficient/cap. Do not change apex appearance chance, wild-weapon
odds, XP, gear power or world traits to disguise a combat-scaling miss.

Only if several trait-distinct Recommended apex fixtures meet duration targets yet still produce no
meaningful decision should Design add a new apex behavior layer. That later layer must be derived
from visible traits and offer counterplay; it cannot be an arbitrary phase script shared by every
apex.
