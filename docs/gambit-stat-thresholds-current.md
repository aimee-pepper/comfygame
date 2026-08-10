# Gambit stat thresholds — HP fractions and armour marks

**Status:** Current implementation boundary; armour marks are reversible playtest values.  
**Updated:** 9 Aug 2026

## Decision

Gambit thresholds are not one unitless number family.

- **HP thresholds** remain fractions of current HP over maximum HP and use the existing 10%, 30%,
  50% and 70% marks.
- **Armour thresholds** use absolute current armour points. Armour is flat damage soak and has no
  natural maximum or honest denominator, so expressing it as a percentage would invent a stat the
  combat model does not possess.

The editor must show the unit in player language and offer only marks compatible with the selected
subject/property. A percentage threshold must never silently compare against armour points.

## Talin's teaching

Talin retains the approved semantic teaching ID `subject_foe_armour_above`.

It means:

> Choose a relevant living foe whose current armour is above the selected armour mark.

This is a specialised subject with an armour-aware threshold slot. It fixes the measured property
and comparator—current armour, above—rather than granting a second hidden component bundle. Action
and rule priority remain independently player-authored.

Initial selectable marks:

| Stable ID | Player-facing mark | First-slice purpose |
|---|---:|---|
| `armour_mark_1` | Armour above 1 | Any meaningful plating |
| `armour_mark_3` | Armour above 3 | Clearly armoured foe |
| `armour_mark_5` | Armour above 5 | Extreme natural armour |

The values are debug-tunable. Their stable IDs should not encode a percentage, and saved rules store
the selected mark ID. If combat later gains temporary armour damage, “current armour” deliberately
means the post-modification value at the moment the gambit evaluates.

## Editor and evaluation guardrails

- Selecting Talin's subject reveals one control labelled **Armour mark**, not the generic HP
  percentage picker.
- Rule prose reads, for example, **Foe: armour above 3 → Skill**.
- The subject chooses the first relevant foe above the mark under the ordinary deterministic foe
  ordering. It does not secretly choose highest armour.
- Unknown or incompatible threshold IDs make the rule non-firing and visibly incomplete; they do
  not fall back to 50% or reinterpret units.
- Older saves are unaffected because no live saved rule can contain Talin's previously held subject.

## Why this stays small

This does not introduce a general numerical-stat query system. Add another stat family only when a
real teaching or progression reward needs it. Typed marks prevent the existing compact gambit editor
from becoming an engineering console while preserving the writing-system principle that learned
components multiply into useful choices.

## Verification

1. Foes at armour 0/1 do not match mark 1; armour 2 does.
2. Foes at armour 3 do not match mark 3; armour 4 does.
3. HP percentage thresholds still evaluate exactly as before.
4. The editor cannot pair an HP percentage with Talin's subject.
5. Save/load preserves the selected armour mark and rule ordering.
6. The diary teaching becomes immediately usable once the player owns at least one armour mark;
   grant `armour_mark_1` with the teaching if no earlier progression source owns armour marks.

