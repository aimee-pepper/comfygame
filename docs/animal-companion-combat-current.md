# Current Design Placeholder — Animal Companion Combat

**Status:** Reversible v1 scope. This resolves the old “human trees or a smaller tree?” question by
using **no animal skill tree**. Generated traits remain the animal's build.

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
2. **One dominant technique** — selected deterministically from its strongest qualifying trait family.
3. **One defensive/withdrawal action** — **Hold** for sturdy bodies or **Withdraw** for mobile bodies.

Working dominant-technique families:

| Trait expression | Technique role | Boundary |
|---|---|---|
| High armour/covering | **Interpose** — receive the next ordinary direct hit aimed at one chosen adjacent-rank ally | Does not intercept emanation; Ashe owns that space |
| High mobility | **Harrier** — attack, then change rank if a legal space exists | No free extra full turn |
| High armament | **Commit** — stronger attack followed by ordinary recovery debt | Uses existing recovery state |
| High conspicuousness | **Draw Notice** — raise the user's priority for hostile targeting for one round | No new aggro meter; use a temporary targeting modifier |
| High sensory investment | **Mark** — reveal one foe's ordinary readable combat information for the encounter | Does not complete a bestiary entry or replace Read |

If several qualify equally, use stable trait-family priority recorded in content—not randomness at
recruitment. The animal preview at the Menagerie names the resulting technique before party assignment.

## Level progression

- Level scaling uses the same broad encounter curve as people so an old companion remains viable.
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
- Focus still governs available gambit slots if animals use the shared stat model; do not add a
  separate obedience, bond or command-point currency.

## Menagerie responsibilities

The Menagerie shows:

- derived species and originating realm;
- the traits that affect combat in sensory/player-facing language;
- instinctive attack, dominant technique and later Hold/Withdraw;
- current party/world/home posting;
- taming history and any observed preferences relevant to care.

It does not sell animal skill points, mutate traits or turn care into a relationship meter.

## Required fixtures

1. One animal for each dominant-technique family produces the expected deterministic kit.
2. No animal can equip human gear or learn a human tree node.
3. Account-known gambit subjects persist and only valid animal actions appear.
4. A five-member party including animals respects the same cap and turn order.
5. Pass-out, return, dormancy and reassignment cannot delete an animal.
6. Trait-derived damage/reach shown in the Menagerie matches combat.

