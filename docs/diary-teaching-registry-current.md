# Current Design — Diary Teaching Registry

**Status:** Authoritative ownership and singular-reward registry for all 28 designed travellers. Tam
remains unassigned. This document controls IDs and reward kinds; packet documents control prose.

## Reward schema

A diary page may set **at most one** of:

- `teachesFocus: PressureSourceID`
- `teachesGambit: GambitComponentID`
- `teachesPattern: RecipeOrPatternID`
- `teachesSchematic: SchematicID`

Relationship, site, research and world-observation fields are mutually exclusive with these teaching
fields on the same page. Unknown IDs fail content validation. Acquiring the page permanently grants
the named reward through its ordinary system; re-acquisition is idempotent.

## World-writing focuses

| Traveller | Stable reward ID | Profile authority |
|---|---|---|
| Mara | `scarp` | `diary-focus-mechanical-profiles-current.md` |
| Edren | `ruin` | same |
| Halloway | `gold_ore` | same |
| Isolde | `hush` | same |
| Sela | `pond` | same |
| Tovin | `drift` | same |
| Orsa | `hive` | `diary-focus-profiles-later-current.md` |
| Vance | `amber` | same |
| Corrin | `chitin` | same |
| Nessa | `thorn` | same |
| Bracken | `bone` | same |
| Fen | `silk` | same |
| Sabine | `coral` | same |
| Grimmond | `mercury` | same |
| Auber | `brine` | same |
| Lys | `echo` | same |
| Perren | `mirror` | same |
| Nine | `dream` | same |

Every listed focus is diary-exclusive. Remove or suppress ordinary research/world-drop acquisition for
the same ID. Existing saves that already know a moved focus retain it; migration does not revoke
knowledge.

## Gambit components

| Traveller | Stable semantic ID | Exact truth condition |
|---|---|---|
| Bryn | `subject_ally_back_rank` | The relevant ally occupies the back rank |
| Talin | `subject_foe_armour_above` | The relevant foe's current armour is above the player-configured threshold |
| Dagg | `subject_self_recovery_complete` | The actor has reached their first actionable turn after completing recovery |
| Rook | `subject_foe_cannot_reach_self` | The relevant foe cannot target/reach the actor with any currently usable hostile action |
| Wren | `subject_foes_present_at_least_3` | At least three living hostile foes are present |
| Kestrel | `subject_foe_unrecorded_species` | The relevant foe's species has no completed bestiary record in this save |
| Marrick | `subject_ally_hp_below_any` | At least one living ally is below the player-configured HP percentage |
| Ashe | `subject_foe_emanating` | The relevant foe has a currently active emanation producer/state |

### Gambit boundaries

- A subject answers true/false. It does not secretly choose an action, target, threshold or priority.
- “Relevant foe/ally” means the target candidate evaluated by the existing gambit composer. Marrick's
  any-ally condition is the exception only in scope of the check, not in automatic retargeting.
- Rook's subject considers current usable hostile actions after range/rank restrictions. A foe that
  could move or recover into reach later still qualifies now.
- Kestrel uses completed bestiary knowledge, not whether the creature has appeared before. Read or
  partial observations do not make the species recorded unless the bestiary already defines that state.
- Dagg's transient recovery-complete flag follows `dagg-recovery-teaching-current.md`.
- Ashe requires live mechanics, not an elemental-looking name, art tag or species category.

If Engineering retains different internal IDs, it must record a one-to-one mapping here or in a
linked implementation note. Similar wording is not enough if the truth condition differs.

## Pattern and schematic

| Traveller | Field | Stable reward ID | Scope |
|---|---|---|---|
| Maud | `teachesPattern` | `maud_fitting_pattern` | One authored advanced physical-melee fitting pattern; no persistent fitted-item state |
| Oda | `teachesSchematic` | `emanation_housing` | Unlocks the Channelworks housing route; no Arc focus, weapon grant or recipe bundle |

## Travellers without a private diary teaching

- All 28 designed travellers have exactly one registered teaching above.
- Tam has none by design while the endgame hold is active. Do not reserve Glass or a placeholder ID.

## Validation fixture

For each registered page, automated content validation should prove:

1. the reward ID exists in the correct registry;
2. no second teaching/reveal field is populated;
3. acquisition changes unknown -> known exactly once;
4. save/load preserves knowledge;
5. already-known acquisition is harmless;
6. removed ordinary acquisition routes do not leak exclusives;
7. the owner's signature can be satisfied without the reward.

