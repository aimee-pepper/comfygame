# Party-member identity and progression — current design

**Status:** implementation-facing migration authority. This unifies the identity boundaries already
settled for generated people, animals, staffing and anchored production; it does not add a new
progression system.  
**Updated:** 9 Aug 2026

## Why this is required

The live roster identifies companions by array position and uses `traveller == nil` for Quill. That
cannot safely represent generated people (also not named travellers), tamed animals (not humans),
roster reordering, realm assignments or saved combatants. A name, optional Traveller ID and array
index are presentation/catalogue facts, not durable identity.

## Stable identity vocabulary

The Binder has a stable player identity but is not a roster record. Every other party-capable being
has one namespaced persistent companion identity:

- **Quill/founder identity** — unique, migration-stable, never inferred merely from nil traveller;
- **named traveller identity** — namespaced by exact `TravellerID`;
- **generated-person identity** — namespaced by exact `GeneratedPersonID` minted at first creation;
- **tamed-animal identity** — namespaced by exact `TamedAnimalID` minted by successful Join us.

Namespaces are part of equality. A generated ID string equal to a Traveller ID is not the same
person. Display name, roster order, icon, calling and current assignment never participate in
identity.

The shared combat/party identity is Binder or one of those persistent companion IDs. Encounter
actors, HP/status/rank/target references, equipment ownership, assignment and expedition progress
all key by it. Roster indices may survive only as transient UI offsets resolved at the boundary.

## Record shapes and capability truth

Use an explicit human-versus-animal record distinction (a tagged enum or equivalent schema), then an
explicit human origin. Do not make optional fields imply type.

| Kind | Human stats/level | Human trees/gambits | Gear/respec | Keeper | Worldwork | Animal kit |
|---|---|---|---|---|---|---|
| Binder | yes | yes | yes | no | no | no |
| Quill | yes | yes | yes | no | ordinary | no |
| Named traveller | yes | yes | yes | authored where applicable | authored | no |
| Generated person | yes | yes | yes | no by default | visible generated/default | no |
| Tamed animal | distinct saved level/XP | no human trees | no human gear/respec | no | no first slice | frozen trait-derived |

Interfaces ask capabilities from the record kind. They do not show a skill-tree button and hope an
animal/nil traveller fails safely, nor use presence of `traveller` to decide whether human systems
apply. A later authored exception adds a visible capability; it never changes identity kind.

## Lifecycle invariants

- Recruiting a named traveller is idempotent by namespaced identity. A second encounter cannot add a
  duplicate roster record or reset progression.
- Generated people persist in the met pool before recruitment and keep the same ID through visitor,
  world, roster and assignment references.
- Taming preserves the exact specimen receipt and creates exactly one animal record even across an
  interrupted success transition.
- Reordering/filtering the roster changes no equipment, HP, gambit, assignment, keeper benefit,
  dialogue relationship or progress.
- Removing a being from the travel party changes placement only. It never deletes or rebuilds their
  progression record.
- Save repair never fabricates a different named/generated/animal origin from a display name.

## Expedition and combat migration

The live run stores companion HP and combatant references by roster index. Migration proceeds in a
single compatibility boundary:

1. Decode the legacy roster in its saved order and mint/resolve persistent identities.
2. Convert active Party, realm assignment, equipped-owner, run HP, encounter actor/target and progress
   references using that frozen mapping.
3. If a reference is invalid, omit it from active placement/combat and preserve the underlying
   companion safely Home; do not point it at whoever now occupies that index.
4. Persist the converted schema before ordinary play continues. Never maintain both index and stable
   identity as writable authorities.

An in-progress encounter must resume with the same actors, HP, statuses, ranks and turn order. If an
unrecoverable legacy actor reference exists, use one explicit safe encounter-recovery path and log
it; silently substituting another companion is forbidden.

## Progression ownership

- Human XP/stat/tree progress belongs to stable identity, not the current Party slot.
- Tamed-animal XP and its frozen derived kit belong to its stable animal identity and never decode as
  human `CharacterState` merely for reuse.
- Expedition start snapshots and return recaps key stable identities and frozen display names; a
  later rename does not make the recap attach XP to somebody else.
- Gear ownership follows stable identity through Party/Home/realm movement. Realm assignment cannot
  unequip, duplicate or transfer it.
- Full human respec applies to Binder, Quill, named and generated people. Animals remain ineligible;
  the UI explains that their abilities come from the animal itself rather than showing a broken
  price/action.

## Migration acceptance

1. Reorder a mixed named/generated/animal roster during Home UI filtering; every record and reference
   remains attached to the same identity.
2. Decode a legacy save with Quill plus named travellers, active Party and realm workers; convert each
   index once and preserve placement/equipment/progression.
3. Save/load mid-combat with multiple companions and statuses; actor, target, HP and turn schedule are
   byte/semantic equivalent.
4. Repeated named recruitment, generated visitor refresh and interrupted taming cannot duplicate or
   reset a record.
5. Skill tree, gear, respec, keeper and Worldwork surfaces follow the capability matrix for every
   kind without nil-traveller branching.
6. Corrupt/invalid legacy indices cannot alias a valid but different companion; affected beings are
   recovered Home and a diagnostic names the dropped reference.

## Live-code audit notes

- `CompanionState.traveller` is optional and nil currently means Quill; no explicit origin or stable
  companion ID exists.
- `PartyMember.member(Int)`, `Combatant.companion(Int)`, `activeParty`, run HP, staffing and realm work
  all propagate roster indices.
- Existing generated-person and animal designs already require distinct stable IDs and state shapes.
  This document supplies the shared migration boundary so Engineering does not implement three
incompatible local identity fixes.

Visual persistence for the four human-origin cases is specified separately in
`binder-quill-generated-visual-identity-current.md`. That document adds no second person ID: visual
identity hangs from this record and cannot replace, infer or alias it.
