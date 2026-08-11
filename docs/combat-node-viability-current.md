# Combat-node viability — current design contract

**Status:** implementation-ready semantic correction; numerical values remain DEBUG/playtest tuning.
**Authority:** this file owns when the 72 existing node effects trigger and how they compose;
`combat-tree-true-graph-current.md` owns prerequisites and presentation.
**Reason:** the live build copies most passives into `CombatTreeRules.Loadout` but never reads them.
Changing a loadout field is not proof that a purchased node affects play.

## Release gate

The graph migration cannot become the default until every node has a scenario-level consumer test.
For passives, the test must compare an otherwise identical action/outcome with and without the stable
node ID. For active techniques it must prove target legality, action cost, cooldown/once limit and
the advertised consequence. Catalogue→Loadout-only tests are insufficient.

All effects use the acting character's owned nodes. Party effects say **party** explicitly and use
the strongest single applicable copy unless a row says otherwise; five copies never multiply a
formation rule. Random chances use the saved encounter RNG. Derived previews use the same rules.

## Offense

| Node | Exact semantic contract |
|---|---|
| Heavy Hand | A Crush weapon's ordinary/technique raw damage gains +2 before matchup and armour. No benefit to other damage kinds. |
| Follow Through | If the selected foe has at least 8 current armour before the hit, add +3 raw damage. Shatter can turn this off by lowering armour; that is intentional. |
| Overbear | Existing heavy Crush technique: one action, then one skipped personal turn. It does not also trigger a second hidden attack. |
| Bracing Stance | Add +3 raw damage when the actor has not changed rank since their previous completed action. Encounter entry counts as held; Fall Back clears the condition. |
| Stagger | A landed Crush hit has a 30% saved-RNG chance to move that foe one slot later in the next round only. This is tempo, not a persistent status icon. |
| Shatter | Existing targeted Crush technique permanently reduces current foe armour for this encounter; never below zero. |
| Momentum | Add `floor(0.4 × current initiative penalty)`, capped at +4. Penalty is the positive difference between unencumbered and current initiative; low base stats are not rewarded as missing equipment initiative. |
| Breaking Blow | The actor's landed Crush hits ignore armour. The first such landed hit per personal turn also applies Stagger automatically; no repeated delay from splash/carried damage. |
| Keen Eye | A Pierce weapon's raw damage gains +2 before matchup and armour. |
| Weak Point | Add +3 raw damage when the foe's covering density is at least 50. This reads covering, not armour. |
| Pry | Existing low-power targeted Pierce technique that ignores armour. |
| Steady Hand | Landed attacks have a 12% saved-RNG critical chance for ×1.5 post-matchup, pre-armour raw damage. Critical preview shows the range, never promises the roll. |
| Exploit | Add +4 raw damage if the target currently carries burn, poison, dazzle or legacy bleed. Emanation alone without an affliction is insufficient. |
| Finish | Existing targeted technique: full power at or below its advertised HP threshold, one-third power otherwise. The target preview states which case applies. |
| Anatomy | Butchery output gains 35%, rounded down after base yield with a minimum +1 when base yield is positive. Use the highest Anatomy bonus among expedition participants; do not stack party copies or require the trained person to land the kill. |
| Killing Stroke | After the actor lands damage, a surviving non-apex foe at or below 15% max HP is defeated. Apexes instead take +4 damage, preventing a percentage execute from trivialising apex conclusions. |
| Quick Step | +4 initiative in the encounter's authoritative order calculation. |
| Light Touch | Halve only negative initiative penalties contributed by equipped gear, rounding toward zero. It does not multiply positive initiative. |
| Quicken | Existing technique: the current action is followed by one extra action, then one skipped personal turn. Owed/skipped receipts survive relaunch. |
| Second Wind | When this actor defeats a foe, heal this actor 3; never revive from passed out. |
| Flurry | A landed direct attack carries 40% of damage actually dealt to one other living legal foe selected by stable foe order. Carried damage cannot proc on-hit effects or another Flurry. |
| First Strike | Usable only as this actor's first completed action of the encounter. It spends that action on one direct weapon attack with +4 raw damage; the target cannot retaliate/counter against that hit. It grants no extra action and remains available even when the party was ambushed. This distinguishes it from Shadow's conditional free Ambush attack. |
| Cascade | Each foe defeated by this actor grants +3 initiative for the rest of the encounter, capped at three stacks; order recomputes without stealing a currently acting turn. |
| Blur | Once per encounter, a zero-turn actor action grants two consecutive ordinary actions. It is explicit—not an automatic trigger—and cannot combine with Quicken in the same personal turn. |

## Defense

| Node | Exact semantic contract |
|---|---|
| Thick Hide | +6 maximum and starting expedition HP. Migration never damages a character by adding/removing this node; respec clamps current HP to the new maximum. |
| Iron Skin | +2 personal armour after equipment/sturdiness calculation. |
| Brace | Existing one-action technique reducing incoming damage through the actor's next enemy-action window; exact reduction remains current skill tuning. |
| Constitution | Burn, poison, dazzle and legacy bleed applied to the actor lose half their rounds, rounded up with minimum 1. It is deterministic, not a hidden resist roll. |
| Endurance | While current HP is at or below half maximum, reduce final incoming damage by 25%, rounding down but never below the global minimum damage. |
| Ward | Targeted technique must let the player choose one disclosed harm kind; gambits may use the rules-owned most-common incoming default. The player UI never silently chooses. |
| Unyielding | Once per encounter, damage that would pass the actor out leaves them at 1 HP. A distinct spent receipt prevents repeat/relaunch use; status ticks may trigger it. |
| Immovable | The actor's armour applies to Pierce and all three emanation harms. Matchup and Ward still matter; this does not grant immunity. |
| Footwork | +6 percentage points to the authoritative foe-to-actor miss chance, after unavoidable effects are excluded. |
| Light Frame | +3 initiative through the same order calculation as Quick Step. |
| Sidestep | Existing targeted-self technique: the next otherwise legal attack misses; affliction payload does not land. |
| Slippery | Reduce the party's ordinary encounter-ambush chance by 50%. Use the strongest Slippery/Watchful party modifier, not their sum; apex/scripted openings are unchanged. |
| Fall Back | Existing zero-turn rank change followed by the actor's ordinary action; it clears Bracing Stance. |
| Feint | After this actor completes a direct attack, gain +10 percentage-point evasion until their next completed action. Carried/splash damage does not refresh it. |
| Untouchable | At each round end in which the actor was targeted but not hit, gain +5 percentage-point evasion, capped at +20; any landed attack resets the bonus. |
| Ghost | The first otherwise legal attack targeting this actor each encounter misses. Environmental/status damage does not consume it. |
| Bulwark | While conscious, gain +1 personal armour and grant +2 armour to other party members in the same rank. Multiple ally bonuses use the strongest once; the owner's +1 does not multiply. This keeps the Protection root functional for the Binder alone without making it a stronger Iron Skin. |
| Watchful | When an ordinary encounter successfully ambushes the party, cancel only the ambush's forced enemy-opening order and resolve the first round by normal initiative. It does not reduce encounter or ambush probability. Scripted/apex openings may explicitly override it and must disclose that fact. Slippery instead reduces ordinary ambush probability, so owning both remains useful rather than one superseding the other. |
| Draw Off | Existing targeted-foe technique forces that foe to target the actor for its duration when legal. |
| Cover | When a conscious owner is in front, redirect 30% of final damage aimed at a back-rank ally to that owner. Choose the highest fraction, then stable party order; never chain Cover or Interpose recursively. |
| Shieldwall | While a conscious owner stands in front, all conscious front-rank party members gain +2 armour once. |
| Interpose | Existing technique marks the actor to receive the next legal hit meant for an ally; it expires after one hit or at encounter end. |
| Rally | When this actor defeats a foe, heal every other conscious party member 2. It never revives. |
| Guardian | While a conscious owner stands in front, foes cannot directly target back-rank allies if they have any legal front target. Area/environment/status effects remain valid. Multiple Guardians do not stack. |

## Craft

| Node | Exact semantic contract |
|---|---|
| Tainted Edge | A landed direct weapon hit applies weak poison (1 damage, 2 rounds) if no stronger poison is present. It does not consume a coating. |
| Apothecary's Hand | Beneficial consumables used by the actor gain +50% magnitude or duration, whichever the item owns; round down with minimum +1. It does not increase harmful thrown items or duplicate items. |
| Envenom | Existing technique applies its temporary poison coating to this actor's weapon attacks; encounter-scoped and no inventory fiction. |
| Virulence | Afflictions directly applied by this actor gain +2 rounds, after resistance. It does not extend pre-existing or ally-applied statuses. |
| Flense | Existing covering-scaled legacy-bleed technique; its distinct wound state remains valid even though player-facing emanation statuses stay burn/poison/dazzle. |
| Corrode | The first poison tick from this actor in each round reduces target armour by 1, minimum zero. Further poison ticks that round do not multiply it. |
| Distiller | Preparing a coating for this actor reduces each positive world-resource ingredient by 40%, rounded up and minimum 1. Essence costs and already-prepared coatings are unchanged. |
| Blight | When this actor newly applies or strengthens poison on a foe, copy half its damage/rounds (minimum 1 each) to one other living foe in stable order. The copy cannot spread again. |
| Quiet Step | Existing world rule reduces ordinary encounter trigger chance by 25% for the party; scripted/apex triggers remain. Strongest party copy only. |
| Low Profile | Existing world rule reduces detection radius by one tile. |
| Conceal | Existing self technique prevents direct targeting for its duration while another legal target exists; area/environmental effects remain. |
| Opportunist | The first direct hit made while concealed or immediately after concealment ends gains +5 raw damage and consumes the bonus. |
| Ambush | Available only before the actor's first completed encounter action when the party was not ambushed. It is one zero-turn free direct attack, consumes the shared opening-attack opportunity and cannot combine with another free opening attack. It is not a reusable five-round damage button. |
| Vanish | Once per expedition, Unbind from combat without Stability loss. The player confirms the same disclosed retreat consequences; a run receipt prevents relaunch reuse. |
| Shadowed | Existing party world rule reduces detection radius by two tiles, superseding rather than stacking with Low Profile. |
| Unseen | This actor begins ordinary encounters concealed for one round. Scripted/apex revelation may explicitly override it and must say so. |
| Sparkhand | A landed direct weapon hit applies weak burn (1 damage, 2 rounds) if no stronger burn is present. |
| Insulation | On learning, choose Heat, Caustic or Light. The actor takes 35% less matching emanation damage; choice changes only through respec and is accessible text, not color. |
| Emanation Strike | Player chooses Heat/Caustic/Light; learning this technique makes all three available without separate gear or research. The strike applies burn/poison/dazzle respectively. Gambits use the actor's saved preference, which manual use may change visibly. It never hardcodes burn while promising three choices. **Identity correction:** use stable skill ID `emanation_strike`; migrate the legacy internal ID `elemental_strike` one way rather than retaining a second name. |
| Attunement | +3 raw damage to Emanation Strike and Channelworks attacks; it does not increase ordinary physical attacks. |
| Snuff | Suppress one foe's active emanation for two rounds. The emanation returns afterward if the foe still lives; UI shows the suppression duration. |
| Quench | Remove one player-selected burn, poison or dazzle from one selected ally. It does not clear all conditions or legacy bleed; one eligible condition may resolve immediately only when visibly named. **Live correction required:** the node currently grants unrelated skill ID `steady`, whose cleanse implementation clears every status plus legacy bleed. Add stable skill ID `quench`; migrate any saved `steady` cooldown/selection originating from this sole node to `quench`, then retire `steady` rather than preserving a misleading internal alias. |
| Conduction | A direct emanation hit carries 50% of damage actually dealt and a half-duration matching affliction to one other living foe. It cannot chain recursively. |
| Emanant | On learning, choose Heat, Caustic or Light. Ordinary direct attacks carry weak burn/poison/dazzle of that kind and the actor visibly emanates in combat; the choice changes only through full Spring respec. It is not magic, does not damage allies/world tiles and does not reveal hidden information. |

## State required by these contracts

### Encounter opening authority

The field currently models `unaware` / `alert` / `pursuing`, but an encounter does not preserve how
contact happened. Combat therefore needs one frozen `EncounterOpening` value created from the
pre-contact world state, not reconstructed after the creature has been removed from the map:

- **partyApproach** — the creature was disclosed to the player before the action that caused contact,
  or the player deliberately entered an adjacent apex/sessile threat. Resolve ordinary initiative.
- **mutualContact** — both sides had disclosed one another but contact was forced by movement. Resolve
  ordinary initiative.
- **creatureAmbush** — a non-apex mobile creature was not disclosed before the action that caused
  contact and reached the party from cover. Its living foes take one opening action each, in their
  stored relative order, before ordinary initiative begins.
- **scripted(scriptID, overridesWatchful)** — an authored opening. It must name its exception in the
  encounter introduction; it never masquerades as an ordinary ambush.

“Disclosed” uses the exact pre-action map presentation rule, including fog and crypsis. Merely having
an `unaware` creature in the data is not enough to ambush the party, and merely having a `pursuing`
creature does not make a visible collision an ambush. Apexes never produce `creatureAmbush`.

Slippery makes one saved-RNG prevention roll when an otherwise valid `creatureAmbush` is frozen. On
success it converts the opening to `mutualContact`; it does not reroll encounter occurrence.
Watchful leaves the encounter classified as `creatureAmbush` but suppresses its foe-only opening
actions, then begins the stored ordinary order. This makes its narrative and DEBUG telemetry distinct
from Slippery. Ambush checks the frozen opening and is unavailable only for `creatureAmbush` or a
scripted opening that explicitly forbids it. Unseen applies after opening classification, so it cannot
retroactively prevent an ambush; it conceals the owner for the first ordinary round.

The opening value and any Slippery roll/result are saved in the encounter. Relaunch cannot reroll or
reclassify contact. DEBUG comparison exposes pre-contact disclosure, initial opening, contributing
node, roll and resolved opening without revealing undiscovered creature traits before contact.

Encounter/run receipts must cover first-turn availability, once-per-encounter/expedition uses,
Unyielding/Ghost consumption, Cascade/Untouchable stacks, actor-applied affliction provenance and
temporary Snuff suppression. Stable node choices store the selected emanation kind for Insulation
and Emanant; legacy ownership defaults to Heat only for migration, surfaced once in DEBUG for review.

Action-economy receipts are shared rather than skill-local loopholes: an actor has one opening-attack
opportunity and one action-expansion opportunity per personal turn. Ambush consumes the former;
Quicken or Blur consumes the latter and cannot chain into the other. First Strike is an ordinary
committed action and consumes neither because it grants no additional action. Carried/splash/status
damage never creates another opportunity.

No effect is inferred from node name, position or rendered icon. Stable node ID drives one typed
effect consumer. Removing/respeccing a node clears only its derived/temporary state and never rewrites
completed expedition outcomes, butchery receipts or spent item transactions.

Technique identity is likewise explicit per stable node. Offense's Fundamental-B/Mastery-A pattern
is not a schema rule: Fall Back, Flense and Ambush occupy Development B, while Quench is a targeted
ally technique. Graph placement cannot silently add or remove an action.

The graph migration is also the correction boundary for Quench→`steady` and Emanation Strike→
`elemental_strike`. Each legacy ID has one live granting source, so preserving two names would create
exactly the player/internal mismatch this project avoids. The new stable IDs are `quench` and
`emanation_strike`; legacy IDs are decode-only migration input. Mid-encounter cooldown and saved-
preference migration is tolerant and one-way; unknown future skills still round-trip normally.

Generated graph records may copy legacy effect payloads only as migration input. They are not the
semantic authority until reconciled to this file. In particular, the current generated payload is
known to be stale for Bulwark (missing the owner's +1 armour), Watchful (old probability modifier
rather than opening-order protection), Shadowed (must resolve to two tiles), Quench (`steady`) and
Emanation Strike (`elemental_strike`). A generated-file parity test is not a consumer test and cannot
promote those legacy meanings into v2.

## Acceptance matrix

1. Every one of 72 stable IDs has at least one scenario test that fails when its rules consumer is
   removed; a catalogue/loadout-difference assertion does not count.
2. All nine pure routes and the nine proven hybrid routes produce different observable outcomes in
   at least one authored fixture, without requiring unavailable gear/items to make every early point
   function.
3. Technique target/default UI follows `combat-action-palette-current.md`; no player action silently
   chooses an ally, harm kind, affliction or emanation kind.
4. Party-wide effects use strongest-once aggregation; stable party reorder cannot alter results
   except where stable order is the documented tie-break.
5. Trigger provenance prevents Flurry, Conduction, Blight and status ticks from recursively
   retriggering themselves.
6. Encounter/run receipts survive save/load and reset at exactly their stated boundary.
7. DEBUG comparison reports damage, mitigation, misses, status applications, turn movement, healing,
   encounter avoidance and external yields by contributing node ID.
8. Quench grants and performs `quench`, offers only eligible burn/poison/dazzle choices, preserves
   legacy bleed and any unchosen status, and migrates a legacy `steady` cooldown without granting a
   second action or resetting its timer.
9. Emanation Strike grants `emanation_strike`; legacy `elemental_strike` cooldown, gambit and saved
   preference migrate once without duplicate techniques or reset state.
