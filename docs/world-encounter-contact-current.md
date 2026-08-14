# World encounter contact — current

**Status:** settled interaction authority; native stationary-threat code requires correction  
**Owner:** Game Design; Engineering implements one rules-owned contact resolver  
**Related:** `field-awareness-avoidance-current.md`, `apex-system-audit.md`,
`world-look-and-control-occlusion-current.md`, `flora-system-spec.md`

## Core distinction

Detection, aggression and combat contact are separate facts:

- **detection** changes what an ordinary roaming creature knows about the party;
- **aggression/awareness** changes whether that creature pursues;
- **contact** begins an encounter when party and hostile occupant meet on one tile, except where an
  authored guardian declares another visible trigger.

“Stationary” only means the entity does not move. It does not imply that adjacency begins combat.

## Current contact matrix

| Threat | Remote detection | Entering adjacency | Entering occupied tile | Enemy movement into party |
|---|---|---|---|---|
| Ordinary roaming creature | Its disclosed sensory radius moves unaware → alert → pursuing | Immediately pursuing/awake; no combat yet | Combat | Combat |
| Apex | None; ordinary fog still controls disclosure | Safe; no awareness or encounter transition | Combat with deliberate party-approach opening | Never moves |
| Active-defence flora | None; visible/known state follows flora disclosure | Safe; no trigger | Combat with deliberate party-approach opening | Never moves |
| Noncombat physical/chemical flora | None | Safe | Apply the exact entry hazard; no creature encounter | Never moves |
| Authored guardian/site threat | Explicit per-content warning rule | Must be authored and disclosed | Must be authored and disclosed | Only if its authored rule permits movement |

Ordinary mobile creatures may therefore aggro from adjacency without combat beginning at that exact
moment: they wake and can pursue/move on subsequent world resolution. Apexes and active flora do not
have an awareness transition at all.

## Movement and inspection

- **Look** is read-only: no turn, movement, detection change, awakening, flora trigger or encounter.
- A direct cardinal step or direct tap onto a disclosed apex/active-flora tile is the deliberate
  commitment and begins combat. Do not add a redundant confirmation modal.
- A longer tap-to-walk path may route beside those disclosed hazards but stops adjacent rather than
  automatically consuming the final hazardous step. The player must explicitly move onto the tile.
- Hidden occupants never leak into route preview. If an ordinary hidden mobile creature legitimately
  contacts the party, its opening may still be an ambush under the frozen encounter-opening rules.
- If an apex or active flora is visible enough to occupy a disclosed tile, its inspection copy must
  make the contact consequence legible before entry without revealing unknown traits.
- Release copy must never say active flora “reacts when approached.” Look says **Entering will start
  an encounter**; physical/chemical flora instead state their entry-hazard class without presenting
  a creature fight.

## Current native defect

`WorldRules.preContactSnapshot` currently assigns `approachedEnemyID` when a destination becomes
adjacent to any apex or sessile enemy. Post-turn resolution then begins an encounter from that field,
grouping apex and active flora into the same obsolete adjacency trigger. `WorldEnemy.isApex` also
contains the superseded “stepping adjacent” comment.

Correction must not simply remove all uses of adjacency: ordinary roaming-creature awareness still
uses adjacency as an immediate wake boundary. Separate the typed trigger from the encounter-opening
classification and preserve the already-frozen party-approach opening once actual tile contact occurs.

## Acceptance

1. From distance two, moving beside a disclosed apex changes position/turn normally and starts no
   encounter; Look, wait and a noncontact interaction beside it also start none.
2. A subsequent explicit step onto that apex starts exactly one encounter with party-approach opening.
3. A multi-step route aimed beyond or through the apex stops beside it; it never auto-enters.
4. Repeat 1–3 for active-defence flora. Physical/chemical flora applies only its exact entry hazard.
5. Moving beside an ordinary unaware roaming creature wakes it immediately but does not fabricate
   same-tile contact; its later legitimate movement or party entry starts combat.
6. Quiet Step, Low Profile, Shadowed and Scent Mask never suppress direct ordinary adjacency, while
   none changes apex/flora contact.
7. Look produces byte-equivalent run/awareness/encounter state before and after every threat kind.
8. Save/relaunch between safe adjacency and final entry does not create, lose or duplicate contact.
