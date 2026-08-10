# Current Design — Dagg's Recovery Teaching

**Status:** reversible implementation decision. The identity and teaching direction are current; the
exact display copy may change in combat UI review.

## Teaching

Dagg's diary teaches the exclusive gambit subject:

> **Self: recovery complete**

It matches only on the actor's first actionable turn after all owed skipped-turn recovery has been
paid. It can be composed with any owned action and, where useful, the ordinary
property/comparator grammar.

Examples:

- `Self: recovery complete → Attack`
- `Self: recovery complete → Skill`
- `Self: recovery complete · health below 30% → Heal`

This is knowledge about what to do after commitment, not a private skill or passive buff.

## Why it happens after recovery

Overbear currently adds one skipped turn. The combat engine consumes that debt before the actor is
allowed to act, so a gambit such as “Self: recovering” could never execute. Adding it would create a
component that reads well but is mechanically inert.

“Recovery complete” instead marks the first real decision after the lost turn. It lets the player
write a deliberate follow-up: steady pressure, use another ready technique, mend if the exchange went
badly, or fall through to later rules.

## Minimal state semantics

- When the actor's final owed skipped turn is consumed, mark that actor `recoveryComplete`.
- Earlier skipped turns in a stack do not mark completion while further debt remains.
- The flag survives until that actor completes one action.
- Clear it after the action, even if the action misses or has a disappointing result.
- Starting or ending an encounter clears all recovery-complete flags.
- The flag does not grant initiative, damage, armour or an extra turn.

This state may be derived or stored however engineering finds safest, but save migration defaults it
to false.

## Scope boundary

This teaching does not change Overbear's current cost. It adds no stamina, poise, recovery meter,
weapon-weight class or Hammer-only gambit subsystem. If future heavy skills also create skipped-turn
recovery, they naturally participate in the same general subject.

## Playtest question

Watch whether `→ Skill` produces a meaningful follow-up or merely selects an arbitrary ready skill.
If the general Skill action remains too broad, solve action selection for the whole gambit system;
do not patch Dagg with a private action picker.

