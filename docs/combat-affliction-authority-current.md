# Combat affliction authority — current

**Status:** settled taxonomy; P1 correctness migration ready alongside combat-v2 consumers  
**Owner:** Game Design  
**Roadmap ID:** `combat-affliction-authority`  
**Review queue:** DRQ-177  
**Updated:** 11 August 2026

## One small vocabulary

The current player-facing afflictions are exactly four:

| Stable ID | Name | Mechanical shape | Current producers | Ordinary removal |
|---|---|---|---|---|
| `burn` | Burn | short, high damage each round | Heat emanation, Firebrand, Heat Channelworks, graph effects | Quenching Draught; Quench |
| `poison` | Poison | longer, lower damage each round | Caustic/toxic life, Venom, Caustic Channelworks, graph effects | Draught of Clearing; Quench |
| `dazzle` | Dazzle | timed accuracy impairment, no tick damage | Light emanation, Flashsalt, Light Channelworks, graph effects | Quenching Draught; Quench |
| `bleed` | Bleed | wound damage each round; severity may vary by producer | Rend, Flense, Briar Oil, Barbed Edge/Bloodletter | Draught of Clearing |

Do not add Freeze or Shock to complete a familiar elemental quartet. No current producer needs them,
and the four coatings already map honestly to these four outcomes.

**Ground is not an affliction.** It is Ashe's beneficial protective stance and uses the protection
channel. Conceal, Brace, coating preparation, Stonebark's pending guard and other timed combat facts
are also not afflictions merely because they have durations.

## Typed definition boundary

One typed `AfflictionDefinition` registry should own, for every stable ID:

- display name and redundant glyph/border identity;
- mechanical family (`damageOverTime` or `accuracy`), default damage and default duration;
- whether producer-supplied severity/duration may override those defaults;
- cure families (`clearing`, `quenching`, `broad`) and Quench eligibility;
- Stonebark eligibility (all four are eligible);
- encounter persistence (all four end with the encounter);
- stable ordering for presentation and deterministic selection.

Each persisted affliction instance also stores the exact target, tick-damage source actor when known,
application provenance (`direct`, `coating`, `copied`, `retaliation`, `environment` or migrated
unknown), damage, ticks remaining and an application receipt. Source is gameplay authority for
actor-owned nodes such as Corrode; it is not inferred later from party position or whoever most
recently touched the target.

Producers remain explicit gameplay code/content and reference a stable affliction ID. The registry
does not make every effect generic or allow content to invent an unimplemented status by spelling a
string. Validation must prove that each producible ID has tuning, presentation and at least one
intended prevention/removal boundary.

Recommended stable presentation order is **Burn, Poison, Dazzle, Bleed**. This is display and
tie-break order, never a hidden instruction for Broad Antidote to remove the first one.

## Application semantics

- Resolve the prospective same-kind max refresh first. If it would add a new affliction, raise its
  damage or extend its remaining ticks, a one-use Stonebark guard is consumed and that one change is
  prevented. A strictly weaker/no-op reapplication does not waste Stonebark. Attack damage and
  other outcomes still resolve.
- Reapplying the same affliction does not create another row. Keep the greater current damage and
  greater remaining duration. A producer explicitly marked endless may preserve its sentinel
  duration without making ordinary Bleed endless.
- Max refresh preserves provenance component-wise. A duration-only extension does not steal the
  existing tick-damage source. A strictly higher damage payload becomes the tick source; equal
  damage keeps the existing source, preventing an equal weak refresh from stealing Corrode credit.
  Migrated unknown provenance never invents a trained actor.
- Ordinary Rend and Briar Oil apply default Bleed at 2 damage/3 rounds. Barbed Edge applies the same
  stable Bleed at 3/3; it replaces the ordinary Rend payload through max semantics rather than
  creating a second wound. Bloodletter alone supplies default-severity non-expiring Bleed. Exact
  boundary and legacy adoption are in `barbed-edge-apex-identity-current.md`.
- Different afflictions coexist. A target may burn, be poisoned, dazzled and bleed at once.
- Each affliction belongs to an exact combatant. No party-wide or foe-family scalar may stand in for
  individual ownership.
- Tick, decrement and defeat happen once at the rules-owned round boundary and remain resumable
  without double application.
- All afflictions clear when the encounter ends. Stonebark also expires unused at that boundary.

### Exact duration and defeat timing

Authoring and UI may say “rounds,” but canonical state means **ticks remaining**. A 3-round Burn,
Poison or Bleed deals exactly three boundary ticks if it is neither cured nor its target defeated.
Application during a round never deals an immediate extra tick; the first consequence occurs at the
next completed round boundary, regardless of whether the afflicting actor happened to act first or
last. Dazzle similarly impairs the target until three boundaries have completed but deals zero tick
damage.

One persisted round-advance receipt owns the boundary. Save/relaunch between the final actor and the
tick cannot skip or repeat it. Reapplication before a boundary may raise severity and/or remaining
ticks through max semantics, but never grants an immediate tick.

If the triggering hit passes the target out or defeats it, the hit still consumes a prepared
one-strike coating, but no new affliction instance or Stonebark consumption is recorded on the
non-standing target. Existing afflictions on a passed-out combatant stop producing consequences and
clear with the encounter. This avoids status rows on actors who can no longer participate without
refunding a coating whose successful strike already occurred.

## Cure semantics

- **Draught of Clearing:** clears every Bleed and Poison instance on the selected ally.
- **Quenching Draught:** clears every Burn and Dazzle instance on the selected ally.
- **Broad Antidote:** when the selected ally has exactly one affliction, may visibly preselect it;
  when several exist, the player selects exactly one before confirmation. It never removes an
  arbitrary array-first condition.
- **Quench technique:** selects exactly one Burn, Poison or Dazzle on a conscious ally/self. It
  deliberately cannot clear Bleed; wound treatment remains Apothecary territory.
- A cure with no eligible affliction is not consumable and does not spend an action/item.

## Live correctness defects this migration must close

Bleed currently has four parallel representations: `binderBleedRounds`, one shared
`companionBleedRounds`, `FoeState.bleedRounds` and `foeBleeds`. The shared companion counter causes
one companion's wound tick to damage every living companion. Multiple foe representations also make
cure, refresh, UI and exact producer severity disagree.

Barbed Edge currently triggers ordinary Rend's `bleedRounds` and its own `foeBleeds` entry, so one
landed hit can tick twice. Migration adopts their maximum severity/duration into one Bleed; it never
sums them.

Broad Antidote's current `clearAnyStatus` removes the first Burn/Poison/Dazzle entry if any exists and
only tries Bleed otherwise. That contradicts the authored item and hides the choice from the player.

The v2 migration should therefore normalize every new affliction into an exact-combatant collection.
Historical encounter saves remain tolerant:

1. decode the modern collection if present;
2. adopt each legacy exact-foe wound into Bleed without duplicating the same producer state;
3. adopt Binder Bleed exactly;
4. legacy shared companion Bleed cannot honestly identify its original target—apply it only to the
   historical encounter's recorded/active companion slot when unambiguous; otherwise diagnose and
   clear the ambiguous compatibility scalar rather than damaging the whole party;
5. encode only the canonical collection after migration while retaining decode aliases.

## Contained implementation order

1. Add the typed definition registry, canonical exact-target collection and tolerant decoder while
   leaving old fields decode-only. No UI promotion yet.
2. Route the one `afflict`/max-refresh/Stonebark transaction through that collection, then migrate
   all existing direct and coating producers. A producer cannot keep writing a legacy scalar.
3. Replace the round-boundary tick with one idempotent persisted boundary over canonical instances;
   delete double foe/party tick consumers only after migration fixtures pass.
4. Route Clearing, Quenching, Broad Antidote and Quench through typed eligible selections. Broad
   Antidote requires a real selected stable affliction ID when more than one is eligible.
5. Move combat rows, logs and DEBUG evidence to the registry and stop encoding legacy Bleed/status
   mirrors. Only then may later combat-tree affliction producers begin.

Do not split this into “Bleed now, the other three later.” Exact target, max refresh, source
provenance, Stonebark and round-boundary timing are the shared correctness value of the migration.

## Acceptance fixtures

1. Every producer applies only its mapped stable ID; no Freeze/Shock path exists.
2. One companion's Rend wound damages only that exact companion across tick, relaunch and cure.
3. Two allies with different Bleeds preserve independent severity and duration.
4. Same-kind reapplication keeps max damage/max duration; different kinds coexist.
5. Stonebark blocks exactly one attempted Burn, Poison, Dazzle or Bleed and then expires; the
   triggering attack's damage remains.
6. Clearing removes Bleed+Poison; Quenching removes Burn+Dazzle; neither touches other conditions.
7. Broad Antidote requires exact selection when multiple afflictions exist, removes one, and is not
   spent on stale/ineligible confirmation.
8. Quench exposes only Burn/Poison/Dazzle and preserves Bleed.
9. Status UI, VoiceOver, combat log and grayscale treatment all use the same definitions.
10. Legacy mid-encounter saves decode without crashes, party-wide Bleed or duplicate ticks; new saves
    round-trip only canonical exact-combatant instances.
11. Barbed Edge produces one 3/3 max-refresh Bleed, ordinary Rend/Briar stay 2/3, Bloodletter alone
    remains endless, and an old dual-representation Barbed wound migrates without summing.
