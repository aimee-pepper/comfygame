# Shatter effect review — current

**Status:** Aimee review required; do not implement either branch by inference.  
**Scope:** one combat-v2 action consequence, not graph topology or general encounter balance.

## Conflict

The current sources make three incompatible promises:

- live `CombatRules.sunder` reduces current foe armour by up to 4 and deals no damage;
- the player-facing Effect says **“Strike one foe and permanently reduce its armour”**; and
- the skill definition declares Crush damage while the Force tree expects landed-Crush interaction
  with Follow Through, Stagger, Breaking Blow and physical weapon payloads.

Leaving this unresolved would either ship a button that looks like an attack but is only a debuff,
or let implementation add an undocumented hit with arbitrary timing.

## Recommendation

Make Shatter a **weak direct Crush weapon hit followed by four armour damage**:

1. validate a legal target through the actor's frozen weapon reach;
2. resolve one authored raw-power-4 direct Crush hit through ordinary avoidance, pre-hit Follow
   Through/Bracing Stance/other components, the target's current armour and landed-hit payloads;
3. only after a landed hit resolves, reduce the surviving target's current encounter armour by 4,
   minimum zero; and
4. use the lower armour for subsequent hits only.

This makes the Effect sentence truthful, preserves the value of Shatter for allies after its owner
learns Breaking Blow, and gives the declared Crush identity real meaning. The current Shatter hit may
Stagger, carry a physical coating, trigger retaliation and contribute to ordinary direct-hit defeat
consequences. Follow Through reads pre-hit armour, so Shatter may benefit from it once and then turn it
off for later hits; that is the already-settled intentional interaction. A miss neither damages
armour nor consumes landed-hit payloads.

## Alternative

Preserve the live non-damaging debuff. If chosen, remove **Strike**, remove the declared Crush/direct-
weapon identity, and present **“Reduce one foe's current armour by 4 for this encounter.”** It would
not Stagger, carry coatings, retaliate or enter direct-hit consequences. This is simpler, but makes a
Force-tree technique feel less like an attack and weakens several authored connections.

## Acceptance after choice

Test armour 0/1/4/8+, miss/land/lethal, Follow Through before/after, Breaking Blow, Stagger, coating/
Envenom, retaliation, Flurry/Killing Stroke, preview=commit, target death/staleness, save/relaunch and
disabled/empty-v2 parity. Only the chosen branch belongs in release copy and the generated 72-node
artifact.
