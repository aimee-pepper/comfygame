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
| Stagger | A landed direct Crush hit has a 30% saved-RNG chance to move each of that foe's saved scheduled slots one living slot later in the next round only. Repeated hits refresh one pending receipt rather than stacking; apex/pressure follow-ups preserve their lighter payload and interleaving. |
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
| Quicken | At the start of a fresh scheduled personal turn, a zero-turn technique grants exactly two consecutive normal-cost actions now, then skips that actor's next scheduled personal turn. This delivers “twice now, nothing after” instead of spending one action merely to move a single action earlier. Expanded actions cannot use Quicken, Blur or another zero-turn setup; credits/debt survive relaunch. |
| Second Wind | When this actor defeats a foe, heal this actor 3; never revive from passed out. |
| Flurry | A landed direct attack carries 40% of damage actually dealt to one other living legal foe selected by stable foe order. Carried damage cannot proc on-hit effects or another Flurry. |
| First Strike | Usable only as this actor's first normal-cost action of the encounter. It spends that credit on one direct weapon attack with +4 raw damage; the target cannot retaliate/counter against that hit. It grants no extra action, remains available after a zero-turn Ambush and when the party was ambushed, and may spend the first Quicken/Blur credit. This distinguishes it from Shadow's conditional free opening attack. |
| Cascade | Each foe defeated by this actor grants +3 initiative for the rest of the encounter, capped at three stacks; order recomputes without stealing a currently acting turn. |
| Blur | Once per encounter, at the start of a fresh scheduled personal turn, a zero-turn actor action grants exactly two consecutive normal-cost actions with no skipped-turn debt. It is explicit, not automatic. Expanded actions cannot use Quicken, Blur or another zero-turn setup, and the shared expansion receipt prevents combining it with Quicken. |

## Defense

| Node | Exact semantic contract |
|---|---|
| Thick Hide | +6 maximum and starting expedition HP. Migration never damages a character by adding/removing this node; respec clamps current HP to the new maximum. |
| Iron Skin | +2 personal armour after equipment/sturdiness calculation. |
| Brace | One action arms a saved Brace receipt for the next hostile action slot that lands direct damage on this actor. Reduce every direct-damage event to them from that one slot by 35%, then consume at slot end. A miss, illegal/other target or zero-damage non-hit does not consume it; status/environment boundaries do not benefit or consume it. |
| Constitution | Burn, Poison, Dazzle and Bleed applied to the actor lose half their final authored ticks, rounded up with minimum 1. Apply producer duration bonuses first, then Constitution; it is deterministic, not a hidden resist roll. |
| Endurance | While current HP is at or below half maximum, reduce final incoming damage by 25%, rounding down but never below the global minimum damage. |
| Ward | Choose one harm kind and reduce matching incoming direct harm for the activation round and the following global round. A new Ward replaces kind/duration rather than stacking. Existing status ticks are not retroactively warded. |
| Unyielding | Once per encounter, the first final damage event that would pass out a conscious owner instead leaves them at 1 HP. It may answer direct, status or environmental damage; later events in the same action can still pass them out. A saved spent receipt prevents replay. |
| Immovable | The actor's armour applies to Pierce and all three emanation harms. Matchup and Ward still matter; this does not grant immunity. |
| Footwork | +6 percentage points to the authoritative foe-to-actor miss chance, after unavoidable effects are excluded. |
| Light Frame | +3 initiative through the same order calculation as Quick Step. |
| Sidestep | Existing targeted-self technique: the next otherwise legal single-target direct attack against this actor misses; affliction payload does not land. Consume Sidestep before the passive Ghost charge because the deliberate short-lived preparation should not expire unused behind an automatic reserve. Area, environmental and status damage do not consume it. |
| Slippery | Reduce the party's ordinary encounter-ambush chance by 50%. Use the strongest Slippery/Watchful party modifier, not their sum; apex/scripted openings are unchanged. |
| Fall Back | Existing zero-turn rank change followed by the actor's ordinary action; it clears Bracing Stance. |
| Feint | After this actor completes a direct attack, gain +10 percentage-point evasion until their next normal-cost action completes. Carried/splash damage and zero-turn setup do not refresh or expire it. |
| Untouchable | At round end, gain +5 percentage-point evasion (cap +20) if at least one direct attack resolved against this actor and no direct attack hit them that round. Any landed direct attack resets the stack immediately; status/environment harm does not. |
| Ghost | The first otherwise legal single-target direct attack targeting this actor each encounter misses after any active Sidestep has been consumed. Area, environmental and status damage do not consume it. |
| Bulwark | While conscious, gain +1 personal armour and grant +2 armour to other party members in the same rank. Multiple ally bonuses use the strongest once; the owner's +1 does not multiply. This keeps the Protection root functional for the Binder alone without making it a stronger Iron Skin. |
| Watchful | When an ordinary encounter successfully ambushes the party, cancel only the ambush's forced enemy-opening order and resolve the first round by normal initiative. It does not reduce encounter or ambush probability. Scripted/apex openings may explicitly override it and must disclose that fact. Slippery instead reduces ordinary ambush probability, so owning both remains useful rather than one superseding the other. |
| Draw Off | Target one foe for two rounds. Its saved receipt names this actor; while they remain conscious, disclosed and legal under reach/rank/Guardian, that foe uses them as the primary target for every action slot. Activating Draw Off ends this actor's Conceal. A newer valid Draw Off on the same foe visibly replaces the prior owner; it never defaults to the Binder. |
| Cover | When a conscious owner is in front, redirect 30% of a landed single-target direct hit's final damage from a back-rank ally to that owner. Resolve the ally's ordinary mitigation once, then split the resulting integer damage by largest remainder; the Cover share is not armoured/reduced again. Choose the highest fraction, then stable party order. Area/multi/environment/status damage and an already Interposed hit do not trigger Cover. |
| Shieldwall | While a conscious owner stands in front, all conscious front-rank party members gain +2 armour once. |
| Interpose | Existing technique queues the actor to receive the next legal single-target direct hit meant for another ally. Choose the oldest valid activation, then stable actor ID; multiple actors may queue without overwriting one another. Replace the target before miss/avoidance and mitigation, so the interposer's Sidestep/Ghost/evasion/Ward/armour applies and the original target's does not. Consume only the chosen entry. Area/multi/environment/status damage cannot consume it; it expires at encounter end. |
| Rally | When this actor defeats a foe, heal every other conscious party member 2. It never revives. |
| Guardian | While a conscious owner stands in front, foes cannot directly target back-rank allies if they have any legal front target. Area/environment/status effects remain valid. Multiple Guardians do not stack. |

## Craft

| Node | Exact semantic contract |
|---|---|
| Tainted Edge | A landed direct weapon hit applies weak poison (1 damage, 2 rounds) if no stronger poison is present. It does not consume a coating. |
| Apothecary's Hand | Beneficial consumables used by the actor gain +50% magnitude or duration, whichever the item owns; round down with minimum +1. It does not increase harmful thrown items or duplicate items. |
| Envenom | One action arms three successful direct weapon hits this encounter. Each armed hit applies strong Poison at 2 damage for 3 authored ticks through canonical max refresh, then spends one charge. Misses/non-weapon/carried hits spend nothing. Reactivation resets, never adds, to three charges. It uses no inventory and may coexist with one prepared non-Poison coating; a prepared Venom would be strictly weaker and is visibly ineligible while Envenom is armed. |
| Virulence | Afflictions directly applied by this actor gain +2 authored ticks before the target's Constitution reduction and before same-kind max refresh. It does not extend a pre-existing affliction merely because that actor later acts, and copied afflictions do not gain the bonus a second time. |
| Flense | Existing covering-scaled technique applies canonical Bleed with covering-derived damage and three ticks. It uses the same max-refresh, Stonebark, cure and source-provenance rules as every Bleed; no distinct legacy wound state remains. |
| Corrode | The first Poison tick owned by this actor against each target in each round reduces that target's armour by 1, minimum zero. Receipt key is actor + target + round. Further Poison representations or refreshes cannot multiply it; migrated source-unknown Poison grants no Corrode credit. |
| Distiller | Preparing a coating for this actor reduces each positive world-resource ingredient by 40%, rounded up and minimum 1. Essence costs and already-prepared coatings are unchanged. |
| Blight | When this actor newly applies or strengthens Poison on a foe, apply a copied payload with half its damage/ticks (minimum 1 each) to one other living foe in stable order. The copied application retains this actor as tick source, passes through the second target's Stonebark and Constitution, and may support Corrode on that target. Its `copied` provenance prevents Blight or Virulence from expanding it again. |
| Quiet Step | The first time an unaware ordinary roaming creature would pursue solely from party movement, it enters one visible alert/hesitation turn instead when distance is greater than adjacency. The party may disengage; remaining exposed lets pursuit begin normally. Strongest party copy only, and one persisted per-creature use cannot be refreshed by stepping away/relaunch. It does not affect direct contact, attacks, sessile hazards, apexes or scripted triggers. This is the current deterministic awareness rule from `field-awareness-avoidance-current.md`, not the legacy opaque −25% encounter-chance interpretation retained in the loadout payload. |
| Low Profile | Existing world rule reduces ordinary detection radius by one tile. In combat, this actor also gains +6 percentage-point evasion during frozen foe-only `creatureAmbush` opening actions, through the ordinary authoritative 85% miss cap. This personal opening benefit remains when Shadowed later supplies the stronger party field reduction. |
| Conceal | Existing self technique prevents direct targeting for its duration while another legal target exists; area/environmental effects remain. |
| Opportunist | The first direct hit made while concealed or immediately after concealment ends gains +5 raw damage and consumes the bonus. |
| Ambush | Available only before the actor's first completed encounter action when the party was not ambushed. It is one zero-turn free direct attack, consumes the shared opening-attack opportunity and cannot combine with another free opening attack. It is not a reusable five-round damage button. |
| Vanish | Once per expedition, Unbind from combat without Stability loss. The player confirms the same disclosed retreat consequences; a run receipt prevents relaunch reuse. |
| Shadowed | Existing party world rule reduces ordinary detection radius by two tiles, superseding rather than stacking with Low Profile's one-tile field reduction. It does not remove Low Profile's personal evasion during foe-only ambush-opening actions. |
| Unseen | After opening classification, this actor begins ordinary encounters concealed through the end of the first ordinary round. The concealment already governs target legality during any preceding foe-only ambush actions, but it does not cancel or reclassify the ambush. Scripted/apex revelation may explicitly override it and must say so. |
| Sparkhand | A landed direct weapon hit applies weak burn (1 damage, 2 rounds) if no stronger burn is present. |
| Insulation | On learning, choose Heat, Caustic or Light. The actor takes 35% less matching emanation damage; choice changes only through respec and is accessible text, not color. |
| Emanation Strike | Player chooses Heat/Caustic/Light; learning this technique makes all three available without separate gear or research. The strike applies burn/poison/dazzle respectively. Gambits use the actor's saved preference, which manual use may change visibly. It never hardcodes burn while promising three choices. **Identity correction:** use stable skill ID `emanation_strike`; migrate the legacy internal ID `elemental_strike` one way rather than retaining a second name. |
| Attunement | +3 raw damage to Emanation Strike and Channelworks attacks; it does not increase ordinary physical attacks. |
| Snuff | Suppress one foe's active emanation for its next two scheduled hostile turns. Every primary/follow-up slot belonging to one such turn uses the suppressed physical profile; consume once after that foe finishes the turn, not once per hit. Existing afflictions keep ticking. |
| Quench | Remove one player-selected burn, poison or dazzle from one selected ally. It does not clear all conditions or legacy bleed; one eligible condition may resolve immediately only when visibly named. **Live correction required:** the node currently grants unrelated skill ID `steady`, whose cleanse implementation clears every status plus legacy bleed. Add stable skill ID `quench`; migrate any saved `steady` cooldown/selection originating from this sole node to `quench`, then retire `steady` rather than preserving a misleading internal alias. |
| Conduction | A direct emanation hit carries 50% of damage actually dealt and a half-duration matching affliction to one other living foe. It cannot chain recursively. |
| Emanant | On learning, choose Heat, Caustic or Light. Ordinary direct attacks carry weak burn/poison/dazzle of that kind and the actor visibly emanates in combat; the choice changes only through full Spring respec. A matching earlier root is strengthened rather than erased: Heat + Sparkhand or Caustic + Tainted Edge applies 2 damage for 2 rounds instead of the ordinary weak 1-for-2 application. A nonmatching root remains a separate weak affliction (for example Caustic Emanant + Sparkhand may apply poison and burn), subject to ordinary stronger-status replacement. Light has no duplicate root and keeps weak dazzle. This is not magic, does not damage allies/world tiles and reveals no hidden information. |

## State required by these contracts

### One direct-damage arithmetic order

The live `CombatDamageRules` resolver is already used by a landed committed strike, but no
production preview calls it and it has no typed v2 contribution slots. Extend that resolver rather
than calculating node damage around it in each technique. For one direct hit, resolve exactly:

1. roll the actor/action's base power through the saved encounter RNG;
2. sum all legal **pre-matchup integer bonuses** once: matching Heavy Hand/Keen Eye, Momentum,
   Follow Through, Bracing Stance, Exploit, First Strike, Opportunist and applicable Attunement;
3. multiply that sum by covering matchup and the existing reach/rank multiplier, then round once to
   the matched integer;
4. if Steady Hand's saved-RNG critical succeeds, multiply that matched integer by 1.5 and round once;
5. resolve Pierce partial ignore or full armour ignore, never both additively, and subtract the one
   resulting effective-armour integer;
6. apply the global minimum direct damage; then commit HP loss; and
7. only after actual damage is known, enqueue survival/defeat, Killing Stroke and non-recursive
   carried/on-hit consequences.

`rawDamage` in receipts means the post-matchup/post-critical, pre-armour integer. Preview calls the
same pure path with the base-roll range and a displayed critical branch; it never rolls or promises
Steady Hand. Diagnostic component fields are provenance explaining the one summed bonus. They are
not values a caller may add again to a returned total. Preview and commit must agree exactly when
given the same roll/critical fact.

### Defeat credit and bounded defeat triggers

Every damage consequence retains its source actor for logs, attribution and later telemetry, but
source credit alone does not mean “the actor just completed a defeating action.” Use two explicit
facts:

- **credited source** — who owns direct, carried, copied or status damage; and
- **active-action defeat** — the foe became defeated while resolving that source actor's currently
  committed normal/opening action and its finite consequence queue.

Second Wind, Rally and Cascade trigger once for each foe defeated by the active action, including a
foe defeated by that action's one non-recursive Flurry or Conduction damage consequence. Those
bounded non-damaging rewards do not re-enter the hit queue. A later round-boundary Burn, Poison or
Bleed defeat retains source credit but does not retroactively heal, Rally or move initiative as if
the actor had just acted. Environmental damage and source-unknown migrated afflictions likewise
grant no actor defeat trigger. Killing Stroke remains direct-hit-only and cannot execute a carried
target. One foe can emit at most one defeat receipt even if execute and HP loss meet in the same
resolution. A passed-out actor can retain historical kill credit but Second Wind never revives them;
Rally requires its owner to remain conscious when the bounded reward resolves.

### Incoming reduction arithmetic and Brace consumption

Live native currently stores/ticks `encounter.braced` but never reads it while resolving damage;
Brace is therefore inert despite appearing as an action. Replace the duration-shaped flag with a
saved activation receipt, not another round counter that can silently expire.

For the actor who actually receives a legal hit after Interpose/target replacement and avoidance:

1. apply matching Ward, worn insulation and exact authored continuous harm multipliers to raw harm;
2. apply the actor's one legal armour calculation where that harm permits armour;
3. combine Brace's 35% and Endurance's 25% reductions multiplicatively against that post-armour
   integer, round down once, and preserve the global minimum direct damage; and
4. perform Cover's final split only if Interpose did not replace the target, without reducing either
   share a second time.

Brace keys to one hostile action-slot receipt. If that slot lands several direct events on the
braced actor, including a legitimate multi-hit/area share, all those events receive Brace and the
receipt is consumed once when the slot finishes. A miss, attack against somebody else or an action
with no landed direct damage leaves it armed. Later Burn/Poison/Bleed ticks and environmental damage
neither benefit nor consume it. It expires at encounter end. Ward remains the stronger selected-harm
commitment; Endurance remains the always-on low-HP fallback. DEBUG names each multiplier and the
single final rounded result.

The same live-code audit found two more duration-shaped flags with no consumer:
`encounter.interposing` and `encounter.envenomed` are written and ticked, but no target or strike
path reads them. Interpose must use the queued one-hit target-replacement contract above. Envenom
must use persisted remaining-hit charges rather than a round clock: three successful direct weapon
hits, strong Poison 2×3, decrement after canonical application. Virulence modifies the authored
three ticks before Constitution; it never increases the three-hit charge count. Envenom and an
inventory coating keep independent exact receipts, but applying prepared Venom while stronger
Envenom is armed is rejected rather than silently wasting the item.

Sidestep and Ghost have the opposite live defect: they are consumed too broadly. Native
`evades(...)` returns true whenever the `dodging` round clock is positive without removing it, and
returns true for every round-one attack when the owner has Ghost. Replace both with exact saved
one-hit receipts. After target replacement and before the ordinary evasion roll, consume an armed
Sidestep on the actual receiver and make that one otherwise legal single-target direct attack miss;
if none is armed, consume unspent Ghost and miss that one attack. Ordinary RNG evasion runs only
when neither guarantee handled the hit. A guaranteed miss prevents the affliction payload and does
not also roll/claim natural evasion. Area, multi-target, environmental and status events cannot see
or consume either receipt. Conceal remains target legality and is not another miss charge.

Do not reinterpret an already-active legacy encounter under v2 halfway through its round: it lacks
enough receipt history to know which repeated legacy miss should have consumed Ghost/Sidestep.
Freeze its legacy rules version until that encounter ends. New v2 encounters initialize exactly one
Ghost unspent receipt per owner and no Sidestep receipt until its action commits.

Draw Off has a separate live ownership fossil. Native `taunts` stores only foe → rounds and the foe
turn path hard-codes `.binder` as the forced target. V2 stores foe → `{owner, rounds,
activationSequence}`. Activation removes Conceal from the owner because “become the obvious problem”
and “cannot be directly targeted” cannot coexist. The receipt overrides random/diverse target
preference, including an apex's preferred-unused-target choice, but never invents reach or bypasses
Guardian/rank legality. If its owner is currently illegal or passed out, that action chooses another
legal target without consuming the Draw Off duration; the round-boundary duration still advances.
A new activation on the same foe replaces the old receipt and names the change in the log/preview.
Area delivery may still include additional legal targets after the forced primary; Draw Off is not
party-wide immunity.

Snuff is currently permanent by accident: native state stores only `snuffed: Set<InstanceID>` and
never removes a living foe from it. V2 replaces membership with a saved receipt keyed by foe:
`{remainingScheduledTurns: 2, activationSequence}`. At the beginning of that foe's next scheduled
hostile turn, freeze whether the receipt applies; it suppresses the emanation for the primary slot
and every apex/ordinary follow-up slot belonging to that same turn. Decrement exactly once after all
of those slots resolve. Relaunch between slots cannot restore the count or mix suppressed and
unsuppressed delivery inside one turn. Activating Snuff again replaces the remaining count with two;
it never stacks above two.

Suppression removes only the foe's active Heat/Caustic/Light delivery and its new affliction payload.
The underlying Crush/Pierce/Rend blow still resolves normally, including ordinary armour and Rend's
physical Bleed where applicable. Burn, Poison or Dazzle already carried by a combatant continues to
tick because Snuff does not reach backward into an affliction already caused. A foe with no active
emanation is illegal; an already-suppressed foe may be refreshed only when fewer than two turns
remain, and the preview must name the replacement rather than imply additive duration. Defeat and
encounter end discard the receipt.

Stagger uses one saved pending receipt per foe, `{appliesToRound, sourceActor,
activationSequence}`. Each eligible landed direct Crush hit rolls once through the encounter RNG;
carried/splash/status damage cannot roll it. Breaking Blow's first eligible landed Crush hit in a
personal turn writes the same receipt automatically and does not also roll for a second copy. A
later success before the affected round may update attribution for the log but cannot add another
position of delay or push the receipt into a later round.

When the next round's ordinary living schedule has been calculated, process pending Staggers by
descending current primary position, stable foe ID as the diagnostic tiebreak. For each selected foe,
swap its saved slots with the next living slot owned by another actor, from last index to first. Each
owned slot moves at most
once and keeps its exact kind, strength, affliction suppression and relative order; apex/pressure
follow-ups remain interleaved rather than becoming a consecutive burst. If no owned slot can move,
the receipt is still consumed and the preview/log says there is no later opening; Stagger never rolls
forward indefinitely. A foe defeated before that round simply drops the receipt. Dynamic initiative
changes later in the round cannot steal or replay the already-scheduled slots.

Feint and Untouchable share the ordinary evasion roll but keep separate saved provenance. Feint arms
only after this actor's direct attack action finishes; a carried Flurry/Conduction consequence is
not another activation. It remains through skipped-turn debt and zero-turn Quicken/Blur/Fall Back,
then expires after the actor's next normal-cost action completes, including a non-attack action. A
new eligible direct attack refreshes the same +10 receipt rather than stacking another copy.

For Untouchable, `targetedThisRound` means a legal direct attack event reached this actor as its
actual receiver after Draw Off/Guardian and Interpose replacement. Being concealed and therefore
excluded, supplying Cover after another ally was hit, or merely standing inside an environmental
effect does not count as targeted. Single-, multi- and area-delivered **direct attacks** do count for
each actual receiver. Sidestep, Ghost or ordinary evasion makes that event a targeted miss; a landed
direct event sets `hitThisRound` and resets the saved Untouchable stack immediately. At round end,
at least one target event and zero hit events grants exactly one +5 step, no matter how many attacks
missed. Burn/Poison/Bleed ticks and non-attack environment harm neither build nor reset it.

The authoritative ordinary miss chance is the additive sum of character evasion, Footwork, active
Feint, saved Untouchable steps and any eligible Low Profile opening bonus, clamped once to 85%.
Sidestep/Ghost guaranteed-miss receipts resolve before this probability and do not consume an RNG
roll. DEBUG and preview name each additive contributor and the final clamp.

Unyielding resolves after target replacement, Ward/armour/reduction and any Cover split, against the
one actor who would actually receive that final integer damage event. If the owner is conscious,
the receipt is unspent and `currentHP - finalDamage <= 0`, consume it atomically and set HP to exactly
1 instead. Record the source event and prevented amount in the encounter log/DEBUG receipt. The
event still counts as a landed hit for Untouchable, Brace consumption and legal on-hit consequences;
Unyielding changes survival, not whether the hit occurred.

Each damage event resolves in authoritative queue order. A later direct event from the same
multi-hit/action slot, a carried consequence, or a later status tick can pass the now-1-HP actor out;
the receipt never protects a whole action or round. Burn, Poison, Bleed and environmental harm may
legitimately spend it, while an actor already at 0 HP cannot consume it to revive. Healing, round
transition, relaunch and encounter re-entry never refresh the spent fact; only a new encounter mints
one unspent receipt for an owner. A legacy active encounter with the node but no receipt initializes
unspent because the old implementation had no consumer capable of spending it.

Ward stores `{harm, activationRound, expiresBeforeRound: activationRound + 2}` for its owner. It is
active immediately through the remainder of the activation round and all of the following global
round, then expires before any slot in the next round. Skipped turns, Quicken/Blur expansion and
relaunch do not alter that boundary. Reactivating Ward—whether for the same or a different harm—
atomically replaces the receipt and restarts that exact window; multiple Wards never multiply.

The selected harm applies to each matching **incoming direct damage event** actually received after
target replacement: Crush/Pierce/Rend or active Heat/Caustic/Light as chosen. It does not reduce a
Burn, Poison, Dazzle or Bleed tick already carried, because those are afflictions rather than a new
matching delivery. If the Ward reduces the direct emanation event, its affliction payload may still
land unless another rule prevents it; Ward is damage preparation, not a cure or immunity. Manual use
has no hidden default, while a gambit records the rules-owned disclosed most-common choice in the
action receipt and battle log. Preview names selected harm, reduction and exact expiry round.

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
- **scripted(scriptID, overridesWatchful, allowsPartyOpeningAttack)** — an authored opening. Both
  exception policies are explicit saved facts; neither is inferred from the script name or from the
  other policy. It must name any exception in the encounter introduction and never masquerades as an
  ordinary ambush.

“Disclosed” uses the exact pre-action map presentation rule, including fog and crypsis. Merely having
an `unaware` creature in the data is not enough to ambush the party, and merely having a `pursuing`
creature does not make a visible collision an ambush. Apexes never produce `creatureAmbush`.

Slippery makes one saved-RNG prevention roll when an otherwise valid `creatureAmbush` is frozen. On
success it converts the opening to `mutualContact`; it does not reroll encounter occurrence.
Watchful leaves the encounter classified as `creatureAmbush` but suppresses its foe-only opening
actions, then begins the stored ordinary order. This makes its narrative and DEBUG telemetry distinct
from Slippery. Ambush checks the frozen opening and is unavailable only for `creatureAmbush` or a
scripted opening whose saved `allowsPartyOpeningAttack` is false. Unseen applies after opening
classification, so it cannot
retroactively prevent an ambush; its concealment is active for target selection during foe-only
opening actions and remains through the end of the first ordinary round. Concealment cannot erase the
enemy's entire target set: if every otherwise legal conscious party member is concealed, those
members remain targetable and ordinary rank/reach rules decide among them. This is the same
“while another legal target exists” boundary as Conceal, not an all-party invulnerability exploit.

The opening value and any Slippery roll/result are saved in the encounter. Relaunch cannot reroll or
reclassify contact. DEBUG comparison exposes pre-contact disclosure, initial opening, contributing
node, roll and resolved opening without revealing undiscovered creature traits before contact.

Encounter/run receipts must cover first-turn availability, once-per-encounter/expedition uses,
Unyielding/Ghost consumption, Cascade/Untouchable stacks, actor-applied affliction provenance and
temporary Snuff suppression. Stable node choices store the selected emanation kind for Insulation
and Emanant; legacy ownership defaults to Heat only for migration, surfaced once in DEBUG for review.

Action-economy receipts are shared rather than skill-local loopholes. A **scheduled personal turn**
mints one fresh expansion opportunity before the actor has committed any normal-cost action or
zero-turn setup. Quicken or Blur consumes it and replaces that turn's one normal-action credit with
two; each committed normal-cost action spends one credit. Quicken adds one skipped scheduled-turn
debt only after both credits are resolved or the encounter ends. Blur adds no debt but is once per
encounter. Expanded credits cannot select Quicken, Blur, Fall Back or another zero-turn setup.

The opening-attack opportunity is separate: Ambush may precede an expansion because it has its own
once-per-encounter receipt, but it does not create or spend a normal-action credit. First Strike is a
normal-cost action and may consume the first expanded credit if it is still the actor's first
completed action. Carried, splash and status damage never create either opportunity. Save/relaunch
between the two credits preserves the remaining credit and any future Quicken debt exactly.

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
10. Emanant Heat strengthens rather than duplicates Sparkhand, Emanant Caustic strengthens rather
    than duplicates Tainted Edge, and nonmatching roots retain their distinct affliction without
    recursive on-hit triggers.
11. Shadowed replaces only Low Profile's smaller field-radius reduction; Low Profile's owner still
    receives exactly +6 evasion during ordinary foe-only ambush-opening actions, with no benefit to
    scripted/apex openings and no bypass of the authoritative miss cap.
