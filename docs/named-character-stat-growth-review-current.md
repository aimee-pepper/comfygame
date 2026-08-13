# Named character stat growth — review boundary

**Status:** design defect confirmed; recommendation awaiting Aimee review
**Priority:** P1 combat identity, after the active shared-armour checkpoint
**Does not authorize:** silently rewriting existing characters, retuning encounter coefficients or
displacing current playability work

## The live defect

`BaseState.seat` gives every named traveller the default all-equal `CharacterStats`. The authored
calling lean affects combat-tree branches but not stats. `CharacterRules.grow` then raises the two
currently highest stats; with an all-equal new character, the practical tie resolves from the shared
enum ordering rather than from the traveller's identity. The result is that distinct named people
can acquire the same stat line simply because they began from the same blank template.

This matters independently of the pending arrival-level decision. Bringing a late traveller up to
the Binder's level by replaying the current rule would make the sameness immediate; leaving them at
level 1 merely postpones it.

## Recommendation

Give every named traveller an authored, data-owned **primary and secondary growth stat**. A named
character gains one point in each at every earned level. Their calling combat-tree lean remains a
separate free starting investment: stats describe the body/practice they bring to a fight, while the
tree describes learned techniques and future player choice.

For the Binder, make primary/secondary growth an explicit new-game choice rather than deriving it
from enum order. Quill needs an authored pair. Generated companions need their pair frozen in their
generated identity receipt. No growth pair restricts equipment, rank or tree purchases.

This is preferable to “raise the current two highest” because that rule is only meaningfully
different after another system has already made stats unequal. It also makes late-arrival replay,
save migration and UI explanation deterministic.

### Provisional cast profile if the fixed-pair option is chosen

These pairs are recommendations, not settled data. Sharing a pair is allowed when two practices
genuinely exercise the same capacities; the rule is relative identity, not artificial uniqueness.
Combat-tree lean, equipment and player purchases still separate people who share stat growth.

| Traveller | Growth pair | Design reason |
|---|---|---|
| Mara | Perception + Wit | Reads worlds, then turns observations into usable models |
| Edren | Wit + Fortitude | Sustained interpretive work in physically compromised sites |
| Sela | Perception + Fortitude | Route judgment and long field endurance |
| Tovin | Wit + Fortitude | Maintains authored structures under accumulating pressure |
| Halloway | Might + Fortitude | Repeated force, heat and material resistance |
| Isolde | Finesse + Wit | Exact hand practice and compositional reasoning |
| Bryn | Fortitude + Might | Holds dangerous space and moves people through it |
| Orsa | Wit + Perception | Reads consent, exits and practical coexistence |
| Vance | Perception + Wit | Appraises condition, provenance and omitted value |
| Noll | Finesse + Fortitude | Separates failed objects without destroying recoverable joins |
| Talin | Finesse + Perception | Acts inside short, observed openings |
| Nessa | Wit + Perception | Distinguishes dose, body, route and timing |
| Corrin | Finesse + Fortitude | Reworks flexible material at repeated wear points |
| Dagg | Might + Fortitude | Prepares, delivers and recovers from controlled heavy force |
| Rook | Perception + Fortitude | Makes contested distance legible and holds the approach |
| Lys | Wit + Perception | Preserves records while noticing missing relation and sequence |
| Bracken | Fortitude + Wit | Understands where protection transfers force and heat |
| Fen | Finesse + Perception | Reads trajectory, obstruction and physical ranged tools |
| Wren | Finesse + Wit | Manages crowded tempo, exits and the next consequence |
| Kestrel | Perception + Finesse | Observes living behavior and acts without wasting motion |
| Maud | Might + Wit | Fits advanced force tools to bodies and chosen compromises |
| Marrick | Wit + Fortitude | Maintains formations while accounting for excluded people |
| Sabine | Perception + Wit | Reads animal refusal, distance and shared-space consequences |
| Grimmond | Fortitude + Perception | Reads deep load and survives the material answer |
| Oda | Wit + Finesse | Builds exact housings and controlled projected transformations |
| Auber | Wit + Perception | Distinguishes a useful transformation from an attractive result |
| Ashe | Fortitude + Wit | Endures an embodied capacity while controlling its use |
| Perren | Wit + Perception | Compares inherited frames and notices excluded alternatives |
| Nine | Wit + Fortitude | Maintains chosen continuities through sustained present practice |

Quill's provisional pair is **Wit + Fortitude**: dependable care and rule execution, not a generic
all-rounder. The Binder's choice should be framed as “which two capacities have carried you this
far?” and preview the mechanical effects; it must not be a class lock or a tutorial interruption.

## Review choices

1. **Authored fixed pair (recommended):** primary + secondary per named character; Binder chooses;
   generated companions freeze a generated pair.
2. **Authored weighted rotation:** each character owns a five-stat weight/order and distributes two
   points per level through it. More varied lines, but harder to read and balance.
3. **Player assigns every stat point:** strongest build control, but levelling 29 people becomes
   upkeep and newly recruited people still need an auto-build policy.
4. **Keep highest-two growth:** accept convergent defaults and fix only the tie-breaking order.

## Implementation and migration gates

- Growth identity belongs in traveller/generated-character data, never in a display-name switch.
- A fresh Mara, Bryn and Isolde at the same level must have intentionally different stat lines.
- Late-arrival replay and ordinary earned levelling must produce the same line at the same level.
- Existing saves keep every earned stat point. Migration may infer a growth pair for future levels
  but cannot rebuild historical stats unless Aimee separately authorizes a respec/reset.
- The roster UI names the two growth stats before recruitment/build decisions rely on them.
- Encounter scaling remains Binder-anchored and is measured again after representative stat
  identities exist; this decision does not itself change foe coefficients.
