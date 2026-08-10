# Apex System Audit — 8 Aug 2026

**Implementation update, 8 Aug:** the encounter and reward loop is now wired. Throughstroke,
Living Hook growth, Warded Haft protection, Two-Natured strike selection, the cache bonus lottery,
and explicit apex bestiary sightings are live. Authored hunting affinities are now specified in
`apex-hunting-affinities-current.md`; implementation and anchored-world persistence remain later work.

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
| Visible and never cryptic | ✅ Built, stronger than written | Its tile is force-revealed at generation and `isVisible` ignores crypsis, so its location is known immediately rather than only once naturally revealed |
| Never ambushes or hunts | ✅ Built | Detection radius zero; never wakes by proximity or moves |
| Approach is the commitment | ⚠️ Different detail | Combat begins when the player moves onto its tile, not when stepping adjacent as the prose spec states |
| Fleeing works at normal stability cost | ✅ Built generically | Flee always succeeds; no apex exception. Not covered in `ApexTests` |
| Guaranteed wild weapon on victory | ✅ Built | Every defeated apex rolls one of the eight |
| Ordinary-creature lottery | ✅ Built | 0.4% placeholder chance per defeated ordinary creature |
| Locked-cache lottery | ✅ Built | 3% world-weighted wild weapon bonus alongside the guaranteed cache reward |
| World-character weighting | ⚠️ Partial | Current code favours four IDs; complete eight-weapon profiles are now authored separately |
| Eight weapons, one unique rule each, not top-stat gear | ✅ As content | Eight mid-tier items and eight unique `WildRule` values; metadata tests pass |
| Two-Natured Blade | ✅ Wired | Actual strike resolution chooses the best damage matchup |
| Long Fang | ✅ Wired by data | Has far reach despite its short-haft fiction |
| **Barbed Edge** *(placeholder replacement for Rimed Edge)* | ⚠️ Rename/effect alignment required | Applies legacy bleed without consuming a coating; does not add freeze |
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

### 4. Keep immediate map revelation — approved

The implementation's stronger rule is good: an apex location is marked from world entry, including
on the minimap. Consent is clearest when the player can plan the whole route around it. The creature
itself can remain unidentified until seen or approached.

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
6. ✅ Keep apex locations revealed from world entry.
7. ✅ Add condition-favoured apex hunting later while retaining the current risk/value draw.
8. ✅ Named-place apexes are allowed only where they do not gate required content.
