# Combat-tree node effect copy — current

**Status:** implementation-ready player-facing copy authority.  
**Authority boundary:** `combat-node-viability-current.md` owns mechanics and numbers;
`combat-tree-true-graph-current.md` owns topology. This file owns the concise **Effect** line shown in
selected-node detail. It supersedes the older poetic `blurb` whenever the two disagree.

`combat-tree-v2-effect-copy.generated.json` is the machine-readable 72-node mirror consumed by
implementation. `npm test` checks its source and combat-authority hashes; after editing this table,
run `npm run generate:combat-copy` in AssetLab. Release/native code consumes the generated artifact,
not Markdown at runtime.

## Presentation rule

Every selected node shows, in this order:

1. node name and pictogram;
2. the exact Effect line below;
3. **Technique · spends an action**, **Technique · zero-turn**, or no action badge as appropriate;
4. prerequisites and point state; and
5. for Crush/Pierce weapon nodes, the current-loadout applicability line from
   `combat-tree-progression-experience-current.md`.

Short flavour may remain beneath the Effect line, but never replaces it. A player must not infer a
number, target, duration, once limit, party scope or equipment requirement from flavour. Mutable
values come from the same tuning source as the mechanic, not unrelated view constants.

## Offense

### Force

| Node | Exact Effect line |
|---|---|
| Heavy Hand | Your Crush attacks deal +2 raw damage. |
| Follow Through | Deal +3 raw damage to a foe with 8 or more armour before the hit. |
| Overbear | Make a heavy Crush attack now, then skip your next personal turn. |
| Bracing Stance | Deal +3 raw damage while you have held the same rank since your previous action. |
| Stagger | Landed Crush hits have a 30% chance to move the foe one place later next round. |
| Shatter | Strike one foe and permanently reduce its armour for this encounter, to a minimum of 0. |
| Momentum | Gain raw damage from gear initiative penalty: 40% of the penalty, rounded down, maximum +4. |
| Breaking Blow | Crush hits ignore armour; the first landed Crush hit each personal turn also Staggers. |

### Precision

| Node | Exact Effect line |
|---|---|
| Keen Eye | Your Pierce attacks deal +2 raw damage. |
| Weak Point | Deal +3 raw damage when the foe's covering density is 50 or more. |
| Pry | Make a lower-power Pierce attack that ignores armour. |
| Steady Hand | Landed attacks have a 12% chance to deal ×1.5 raw damage before armour. |
| Exploit | Deal +4 raw damage to a foe with Burn, Poison, Dazzle or Bleed. |
| Finish | Strike one foe at full power below the shown HP threshold, or one-third power above it. |
| Anatomy | The party gains 35% more butchery output while you took part in the expedition; copies do not stack. |
| Killing Stroke | Defeat a surviving non-apex foe at 15% HP or less after your hit; apexes take +4 damage instead. |

### Swiftness

| Node | Exact Effect line |
|---|---|
| Quick Step | Gain +4 initiative. |
| Light Touch | Halve initiative penalties from equipped gear, rounding toward 0. |
| Quicken | Take one extra action now, then skip your next personal turn; cannot combine with Blur this turn. |
| Second Wind | When you defeat a foe, recover 3 HP if still conscious. |
| Flurry | A landed direct attack carries 40% of damage dealt to one other legal foe; it cannot chain. |
| First Strike | On your first completed action, attack for +4 raw damage without allowing retaliation. |
| Cascade | Each foe you defeat grants +3 initiative for this encounter, up to three times. |
| Blur | Once per encounter, take two ordinary actions without spending this action; cannot combine with Quicken this turn. |

## Defense

### Fortitude

| Node | Exact Effect line |
|---|---|
| Thick Hide | Gain +6 maximum and starting expedition HP. |
| Iron Skin | Gain +2 armour after equipment and sturdiness. |
| Brace | Reduce incoming damage through your next enemy-action window. |
| Constitution | Burn, Poison, Dazzle and Bleed on you last half as many rounds, rounded up. |
| Endurance | At half HP or less, reduce final incoming damage by 25%, without passing the global minimum. |
| Ward | Choose one disclosed harm kind; reduce matching harm until the Ward expires. |
| Unyielding | Once per encounter, harm that would pass you out leaves you at 1 HP. |
| Immovable | Your armour also applies against Pierce, Heat, Caustic and Light damage. |

### Protection

| Node | Exact Effect line |
|---|---|
| Bulwark | Gain +1 armour; allies in your rank gain +2 armour while you are conscious. Copies use only the strongest bonus. |
| Watchful | If an ordinary creature ambushes the party, cancel its free opening actions and use normal initiative. |
| Draw Off | Choose one foe; while Draw Off lasts, it targets you whenever legally able. |
| Cover | While conscious in front, take 30% of final damage aimed at a back-rank ally; Cover cannot chain. |
| Shieldwall | While conscious in front, every conscious front-rank party member gains +2 armour. |
| Interpose | Receive the next legal hit meant for an ally, then the effect ends. |
| Rally | When you defeat a foe, every other conscious party member recovers 2 HP. |
| Guardian | While conscious in front, foes cannot directly target the back rank when a legal front target exists. |

### Evasion

| Node | Exact Effect line |
|---|---|
| Footwork | Foes are 6 percentage points more likely to miss you. |
| Light Frame | Gain +3 initiative. |
| Sidestep | The next otherwise legal attack against you misses; its affliction also fails. |
| Slippery | Halve the chance that an ordinary encounter begins as an ambush; party copies do not stack. |
| Fall Back | Change your rank without spending your action; this ends Bracing Stance. |
| Feint | After your direct attack, gain +10 percentage-point evasion until your next completed action. |
| Untouchable | At round end, gain +5 percentage-point evasion if targeted but not hit, up to +20; a hit resets it. |
| Ghost | The first otherwise legal attack against you each encounter misses. |

## Craft

### Venom

| Node | Exact Effect line |
|---|---|
| Tainted Edge | Landed direct weapon hits apply weak Poison: 1 damage for 2 rounds, unless stronger Poison is present. |
| Apothecary's Hand | Beneficial items you use gain +50% magnitude or duration; harmful thrown items are unchanged. |
| Envenom | Temporarily coat your weapon with Poison for this encounter without using an inventory coating. |
| Virulence | Afflictions you directly apply last +2 rounds after resistance. |
| Flense | Wound one foe; denser covering makes the hit stronger and the Bleed keeps opening. |
| Corrode | The first tick each round from Poison you applied reduces that foe's armour by 1. |
| Distiller | Coatings prepared for you use 40% fewer positive world-resource ingredients, rounded up; Essence is unchanged. |
| Blight | New or strengthened Poison you apply copies at half strength and duration to one other foe; it cannot spread again. |

### Emanation

| Node | Exact Effect line |
|---|---|
| Sparkhand | Landed direct weapon hits apply weak Burn: 1 damage for 2 rounds, unless stronger Burn is present. |
| Insulation | Choose Heat, Caustic or Light when learned; take 35% less matching emanation damage. |
| Emanation Strike | Strike with chosen Heat, Caustic or Light, applying Burn, Poison or Dazzle respectively. |
| Attunement | Emanation Strike and Channelworks attacks deal +3 raw damage. |
| Snuff | Suppress one foe's active emanation for 2 rounds. |
| Quench | Choose one ally and remove one selected Burn, Poison or Dazzle; Bleed and unchosen conditions remain. |
| Conduction | A direct emanation hit carries 50% damage and half-duration affliction to one other foe; it cannot chain. |
| Emanant | Choose Heat, Caustic or Light when learned. Ordinary direct attacks carry its weak matching affliction; matching Sparkhand or Tainted Edge strengthens that application, while a nonmatching root remains separate. |

### Shadow

| Node | Exact Effect line |
|---|---|
| Quiet Step | Once per ordinary roaming creature, turn its first distant movement detection into one visible alert turn instead of immediate pursuit. |
| Low Profile | Reduce the party's detection radius by 1 tile. This actor also gains +6 evasion during an ordinary creature ambush's foe-only opening actions. |
| Conceal | Prevent direct targeting while another legal target exists for the effect's duration. |
| Opportunist | Your first direct hit while concealed or immediately after emerging deals +5 raw damage. |
| Ambush | Before your first completed action when the party was not ambushed, make one free direct attack; only one free opening attack is allowed. |
| Vanish | Once per expedition, the confirmed ordinary combat retreat costs no Stability. |
| Shadowed | Reduce the party's detection radius by 2 tiles, replacing Low Profile's field reduction but not its personal ambush-opening evasion. |
| Unseen | Begin ordinary encounters concealed through the end of the first ordinary round; this does not cancel an ambush. |

## Copy migration and verification

- Stable node IDs do not change. Existing saves keep ownership and points.
- `kindling` remains decode-only and displays **Emanation**.
- `steady` and `elemental_strike` are migration inputs only; player copy uses **Quench** and
  **Emanation Strike**.
- Values shown here must be generated from rules-owned tuning where a DEBUG coefficient is mutable.
- VoiceOver reads name → Effect → action badge → applicability → prerequisites → purchase state.
- A release string scan rejects the known inaccurate phrases “fewer things notice you at all,” “the
  fight starts with your turn,” “strike through a ward,” and any suggestion that Quench removes every
  condition.
