# Barbed Edge apex identity

**Status:** settled name/identity; canonical severe-Bleed correction queued with affliction authority

**Updated:** 11 Aug 2026

**Authority:** DRQ-013; `apex-system-audit.md`; `combat-affliction-authority-current.md`

## Finding

**Barbed Edge** is the final player-facing name. Its internal `rimed_edge` ID remains decode/save
compatibility and never appears to the player. The accepted repeated backward-thorn silhouette and
defended-flora affinity already support the identity; no cold, rime or freeze fiction remains.

The old mechanical sentence—“applies Bleed without a coating”—is insufficient. Every ordinary Rend
weapon already applies Bleed on a landed hit. Barbed Edge is itself a Rend weapon, so that promise
does not break a rule.

Native currently writes ordinary Rend into `foe.bleedRounds` and the Barbed rule into a separate
`foeBleeds` entry. Both tick, accidentally making the weapon stronger through duplicate legacy state
rather than one authored affliction. The combat-affliction consolidation must not preserve that
implementation accident as two simultaneous Bleeds.

## Settled apex rule

On a successful landed weapon hit, Barbed Edge applies or refreshes **Severe Bleed: 3 damage for 3
rounds**.

- It is the same stable `bleed` affliction, not a fifth status or a “Severe Bleed” status ID.
- Same-kind max severity/max duration composition means it replaces the ordinary Rend payload rather
  than stacking beside it.
- Another hit refreshes to max(3 damage, current damage) and max(3 rounds, current rounds); it does
  not add another instance or grow without bound.
- Armour/effectiveness still decides the landed direct damage normally.
- A miss, protected affliction or defeated target does not create a wound.
- Draught of Clearing, Stonebark and an explicitly selected Broad Antidote interact through the one
  canonical Bleed rule.

Ordinary Rend and Briar Oil remain ordinary Bleed at the shared default 2 damage/3 rounds. Barbed
Edge therefore adds one point of recurring severity, not an extra clock. **Bloodletter** remains the
separate apex rule: default-severity Bleed does not expire naturally. Barbed is stronger per round;
Bloodletter persists. Neither is a strict replacement for the other in short and long fights.

## Coating interaction

Barbed Edge may accept Venom, Firebrand or Flashsalt because different affliction kinds coexist.
Briar Oil is disabled for this weapon with **Already leaves a stronger wound**; do not consume it or
pretend it stacks. This is a target-legality rule, not an inventory special case based on display
name: it checks the weapon's stable innate-affliction profile.

## Presentation

Use final copy:

> Its backward thorns resist every attempt to withdraw them. A landed strike leaves a severe wound
> without preparation.

Identified detail states **Landed hits: Severe Bleed · 3 damage · 3 rounds**. Ordinary loot tiles do
not need a Bleed badge baked into the weapon silhouette; anchored detail owns the rule text.

## Acceptance gates

1. One landed Barbed hit creates exactly one canonical Bleed instance at 3 damage/3 rounds.
2. The ordinary Rend path does not create a second Bleed or double-tick.
3. Repeated hits refresh max severity/duration and never stack same-kind instances.
4. Ordinary Rend and Briar Oil remain 2/3; Bloodletter remains default severity with non-expiring
   duration under its existing sentinel/migration boundary.
5. Stonebark prevents Barbed Bleed once without preventing direct damage; Clearing removes it; Broad
   removes it only when selected under the shared rule.
6. Briar Oil is visibly ineligible on Barbed Edge without consumption; the other three coatings may
   coexist and are consumed normally.
7. Old mid-encounter saves containing both Barbed legacy bleed representations adopt one max
   canonical Bleed without summing damage or losing the greater remaining duration.
8. Player-facing copy/art/reward logs never expose `rimed_edge`, Rimed Edge, frost or Freeze.
9. The accepted Barbed silhouette remains distinct from Raking Edge, Living Hook and Bloodletter in
   color, grayscale and shared loot/equipment/Storehouse surfaces.
