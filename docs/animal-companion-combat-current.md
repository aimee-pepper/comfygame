# Current Design — Animal Companion Combat

**Status:** Implementation-facing v1 identity and state contract. Numerical level curves and action
coefficients remain reversible playtest values. This resolves the old “human trees or a smaller
tree?” question by using **no animal skill tree**. Generated traits remain the animal's build.

## Core decision

An animal companion occupies one normal party slot and participates as a normal combatant, but:

- has no class, skill points or human combat-tree screen;
- cannot equip human weapons or armour;
- keeps the generated traits/species identity of the creature that was tamed;
- gains ordinary levels for health, action and damage scaling;
- receives a small fixed action kit derived from its traits;
- may use the account's known gambit subjects with only actions the animal actually knows.

This preserves the reason to seek an unusual animal in an unusual world. Giving every animal the same
three human trees would gradually erase the trait vector that made it worth taming; authoring a fourth
animal-only tree would add another progression interface before taming itself is proven fun.

## Party and handling

- Party cap remains five. An animal uses a slot; it is not a free sixth body.
- Sabine is not required to place an already-tamed animal in the party. Pairing her with one should
  create authored synergy later, not a mandatory tax on two slots.
- Animals pass out and recover by the same safety rules as people. No permanent death.
- An animal may be posted to the Menagerie or an anchored realm when not in the party.
- No breeding, fusion, rerolling or trait respec in v1.

## Trait-derived action kit

Every animal has:

1. **Instinctive attack** — damage kind and reach derive from its generated armament/body.
2. **One dominant technique** — derived deterministically from its saved defence branch, with an
   armament fallback only when no defence branch exists.
3. **One defensive/withdrawal action** — **Hold** for sturdy bodies or **Withdraw** for mobile bodies.

Dominant-technique families:

| Saved expression | Technique role | Boundary |
|---|---|---|
| `defence == armour` | **Interpose** — receive the next ordinary direct hit aimed at one chosen adjacent-rank ally | Does not intercept emanation; Ashe owns that space |
| `defence == speed` | **Harrier** — make the instinctive attack, then move one legal rank step | No extra attack, full turn or movement outside rank legality |
| `defence == crypsis` | **Slip Away** — move one legal rank step and become a lower-priority ordinary direct target until its next action | Does not become untargetable, erase revealed information or prevent area attacks |
| `defence == aposematism` | **Warning Display** — raise its ordinary hostile-target priority for one round and prime its existing trait-derived retaliation | No new aggro meter and no invented toxin when `isToxic` is false |
| no defence branch | **Commit** — a stronger instinctive attack followed by ordinary recovery debt | Uses existing armament, kind, reach and recovery state; unarmed animals body-check with Crush |

There is no cross-axis score, threshold contest or tie-break. `DefenceBranch` is already the
generator's single chosen answer to predation and is saved on the exact specimen. Sensory values are
allocations summing to 100, not investment amounts; they cannot honestly select a generic **Mark**
technique. “Conspicuousness” is not a stored trait. Those two earlier candidates are cut rather than
inventing hidden stats. The Menagerie names the resulting technique before party assignment.

## Level progression

- At taming, persist the exact specimen traits plus the level-1 `CombatStats.derived` result and the
  wild individual's resolved encounter level. Current max HP, attack and armour use the same
  `CharacterRules.scaled(baseValue, toLevel:)` curve already used for ordinary foes. Initiative,
  evasion, retaliation, damage kind, reach, delivery and emanation remain trait identity and do not
  inflate with level.
- The animal starts at that saved encounter level, clamped 1–25, with XP exactly at
  `experienceForLevel(level)`. It never copies the Binder's level or rerolls when assigned.
- Dominant technique is available immediately after taming.
- Defensive/withdrawal action unlocks at working level **5**.
- No further bespoke unlocks in v1. Higher levels improve ordinary numbers only.

Level 5 is a debug-tunable placeholder. This is intentionally shallow: the strategic choice is which
generated animal joins the party and how its actions enter gambits, not filling another board.

## Gambits and control

- Animals can be commanded manually on their turn.
- Their gambit editor uses the normal ordered rule system and account-known subjects.
- Invalid human-only actions never appear in the animal action picker.
- A default gambit set is generated from the kit and can be edited out of combat.
- Animals receive the shared account-wide gambit capacity (base + Research + Constellation) but no
  personal Wit term. They have no human stats, so synthesizing Wit merely to call the existing slot
  formula would create a hidden obedience stat by another name. Do not add bond or command points.

## State and combat integration

Do not disguise a tamed animal as a `CompanionState` with `traveller == nil`; that already collides
with Quill and generated people, and would accidentally expose human gear/tree routes. Persist a
`TamedAnimalState` keyed by stable `TamedAnimalID` with the exact trait/species/visual receipt,
origin, level/XP, derived kit version, gambits and posting.

The animal begins at the level of that exact world individual when tamed, clamped to the ordinary
1–25 range, with experience set to the threshold for that level. It does not rescale when first put
in the party. Future XP uses the ordinary award curve. Its base combat numbers are frozen from the
saved traits through one versioned derivation; levelling applies the disclosed animal level curve
without granting human stats or tree points.

Party selection stores stable member references (person or animal), not an assumption that every
member is an index into the human roster. Combat receives a distinct animal combatant identity and
resolves its action kit directly. Shared systems—rank, HP, initiative, target legality, pass-out,
experience, gambit ordering and the five-member cap—operate through a common party-member interface;
human-only equipment, skills and respec return visibly ineligible rather than falling back to Quill.

Kit derivation is performed and saved when taming completes. Later balance/content versions may
offer an explicit recompute migration, but merely relaunching or reordering traits in code cannot
change a companion's technique. No stable tie priority is needed: the saved defence branch is
singular, and a missing branch maps to Commit.

## Menagerie responsibilities

The Menagerie shows:

- derived species and originating realm;
- the traits that affect combat in sensory/player-facing language;
- instinctive attack, dominant technique and later Hold/Withdraw;
- current party/world/home posting;
- taming history and any observed preferences relevant to care.

It does not sell animal skill points, mutate traits or turn care into a relationship meter.

## Required fixtures

1. Armour/speed/crypsis/aposematism/no-branch animals produce Interpose/Harrier/Slip Away/Warning
   Display/Commit respectively, independent of trait field or catalogue ordering.
2. No animal can equip human gear or learn a human tree node.
3. Account-known gambit subjects persist and only valid animal actions appear.
4. A five-member party including animals respects the same cap and turn order.
5. Pass-out, return, dormancy and reassignment cannot delete an animal.
6. Trait-derived damage/reach shown in the Menagerie matches combat.
7. A tamed level-1/5/25 animal has threshold-correct XP; only max HP/attack/armour follow the shared
   saved-base scaling curve, and it has no human branch/free-point budget.
8. Quill, a generated person and two animals remain distinct through party reorder and save reload.
9. A catalogue/derivation-version change cannot silently alter an existing animal's saved kit.
10. Sensory allocation and visual conspicuousness never create a hidden combat-stat comparison or
    grant bestiary knowledge.
11. Account-wide gambit-slot unlocks affect animals once; human Wit bonuses do not, and no surrogate
    animal Wit is stored or displayed.
