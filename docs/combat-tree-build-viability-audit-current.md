# Combat-tree build viability audit — current

**Status:** Design pass complete; implementation and DEBUG playtest remain  
**Date:** 11 August 2026  
**Topology authority:** `combat-tree-true-graph-current.md`  
**Effect authority:** `combat-node-viability-current.md`

This audit asks whether the corrected graph creates different playable characters, not merely many
legal routes. Exhaustive enumeration proves 212 legal eight-point capstone routes; this pass checks
that early forks, techniques, automatic effects and capstones create different decisions.

## Nine discipline identities

| Discipline | First meaningful fork | Midgame play | Capstone change | Viability disposition |
|---|---|---|---|---|
| Force | reliable heavy damage vs active Overbear commitment | hold position, delay or break armour | armour-ignoring Crush plus controlled Stagger | viable bruiser/control route; Shatter still helps the party after personal armour ignore |
| Precision | dense-cover damage vs armour-ignoring Pry | critical reliability vs afflicted-target payoff | low-HP execute with apex fallback | viable hunter/finisher route; Finish remains useful above Killing Stroke's threshold |
| Swiftness | gear-tempo mitigation vs borrowed-action Quicken | self sustain vs carried multi-target damage | explicit once-per-encounter two-action Blur | viable tempo route; Quicken is repeatable debt while Blur is scarce debt-free burst |
| Fortitude | armour vs timed Brace | deterministic affliction shortening vs low-HP reduction | armour applies to Pierce/emanations | viable personal-tank route; Ward/Insulation reduce harms rather than duplicating armour |
| Protection | encounter-order knowledge vs targeted Draw Off | automatic Cover vs formation Shieldwall | front rank controls legal direct targeting | viable party-tank route; Interpose remains a chosen one-hit answer |
| Evasion | constant initiative vs guaranteed Sidestep | ambush prevention, repositioning and attack-fed evasion | automatic first-attack miss | viable mobile-survivor route; Ghost does not replace reusable Sidestep/Untouchable |
| Venom | coating/item mastery vs active Envenom | duration, bleed and armour corrosion | bounded one-step poison spread | viable attrition/material route; stronger Envenom replaces weak root poison |
| Emanation | matching resistance vs selectable Emanation Strike | damage, suppression and selected cleanse | persistent chosen carried affliction | viable harm-control route after matching-root synergy correction |
| Shadow | field avoidance vs active Conceal | opening damage, retreat and party concealment | first-round concealment | viable avoidance/opener route after Low Profile retains personal ambush-opening evasion |

## Cross-tree proof archetypes

These are proof builds, not named classes or presets:

| Build | Disciplines | Different decision it creates |
|---|---|---|
| Breaker | Force + Fortitude | accepts heavy equipment and stays planted while surviving retaliation |
| Duelist | Precision + Evasion | seeks dense/armoured priority targets and converts attacks into avoidance |
| Rogue | Swiftness + Evasion + Shadow | controls contact, opening and action timing rather than winning a damage race |
| Hunter | Precision + Evasion + Venom | reads covering, survives pursuit and extracts more from deliberate prey |
| Warden | Fortitude + Protection | chooses when to absorb, redirect or forbid attacks on fragile allies |
| Saboteur | Venom + Emanation | applies, lengthens, spreads and suppresses typed afflictions/emanations |
| Vanguard | Force + Protection | breaks a front line while making their own front rank the legal fight |
| Nightflame | Shadow + Emanation | approaches unseen, opens deliberately and chooses a carried harm identity |
| Field alchemist | Venom + Shadow | avoids poor fights, prepares coatings and commits to valuable attrition targets |

Characters may combine any legal nodes. The table proves shared trees can express recognizable
builds without introducing fixed classes.

## Dominance corrections

1. **Emanant / Sparkhand / Tainted Edge:** matching Heat or Caustic strengthens the earlier root to
   2 damage for 2 rounds. Nonmatching roots remain separate afflictions.
2. **Shadowed / Low Profile:** Shadowed replaces the smaller field-radius number, but Low Profile
   retains +6 personal evasion during ordinary foe-only ambush-opening actions. Stacking radius
   reductions would usually disappear into the adjacency clamp and was not a real solution.

No other strict domination was found under current contracts:

- Breaking Blow ignores armour personally; Shatter still lowers it for everyone;
- Killing Stroke concludes at 15%; Finish retains its broader threshold and direct timing;
- Ghost is once per encounter; Sidestep is a deliberate reusable cooldown action;
- Guardian controls direct target legality; Cover and Interpose answer damage that remains legal;
- Blur and Quicken differ in scarcity, debt and repeatability.

## Playtest risks—not reasons to linearize

- Retain the existing 85% evasion ceiling.
- Protection redirects must never recurse or mitigate already-final damage twice.
- Free/opening/carried damage must not recursively trigger Flurry, Conduction, Blight, Stagger or
  another opening attack.
- Status-strength replacement must make Emanant/root synergy visible rather than appear to lose a
  status.
- Apex fallbacks must keep capstones live without erasing apex challenge.
- Economy/field nodes need encounter-adjacent feedback; damage fixtures alone cannot judge them.

## Acceptance

1. All nine pure and nine authored hybrid routes change an observable action, target, outcome, field
   decision or reward in at least one fixture.
2. Every depth-2 A/B pair has one fixture favoring A and another favoring B.
3. The cross-tree proof builds require no hidden class/equipment gate.
4. Capstones preserve or explicitly strengthen already-owned roots/developments.
5. DEBUG attributes action economy, mitigation, evasion, affliction, awareness and yields to stable
   node IDs.
6. Phone play compares one pure, one hybrid and one broad route at equal level/gear before tuning is
   frozen.

