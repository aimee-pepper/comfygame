# Station First-Use and Reachability Audit — Current

**Status:** complete 23-station live-catalogue pass; one P1 orphan/dead end and one P2 receipt/copy defect found  
**Date:** 11 August 2026

## Method

The live station catalogue, route switch, build-site rules, keeper roster and first-use rules were
compared by stable ID. A station is reachable only if it is opening infrastructure or has a valid
keeper/build path; having a Swift view or DEBUG route is not player access.

## Finding — Apothecary is unreachable

The Apothecary is the only live station with all three of these facts:

- `unlockedAtStart: false`;
- no `builtBy` keeper;
- no `buildCost`.

`GameStore.buildableStations` deliberately requires an undiscovered station to name a recruited
`builtBy` traveller. Therefore ordinary play can never offer the Apothecary construction site even
though:

- Nessa is a live mid-campaign traveller (`nessa`, authored order 11);
- `ApothecaryView` and the preparation engine exist;
- the current design assigns the station to Nessa; and
- dependency-safe recipes are already authored.

The older note that production waits for Nessa's “final diary prose” is stale. Her live identity,
signature, diary ownership and station assignment are sufficient for mechanical reachability;
future prose review cannot remain a hidden feature flag.

## Exact correction

At the next safe content checkpoint:

1. Set Apothecary `builtBy` to stable traveller ID `nessa`.
2. Add the current reversible build bundle from the station matrix: **85 Essence, 16 Clay, 6 Quartz,
   12 Reagent**.
3. Recruiting Nessa makes the persistent build site visible; it never auto-builds the station.
4. A legacy save that already recruited Nessa and has a locked Apothecary receives the same build
   site. An already unlocked Apothecary remains exact and is not charged retroactively.
5. Tier 0 immediately exposes the dependency-safe preparation catalogue. It does not require a
   second research purchase merely to make the paid building useful.
6. Preserve ordinary CMY+Depth writing ink at Isolde's Scriptorium. “Reactive stains” in old Nessa
   prose do not move the authored ink system.
7. Scent Mask remains a later additive recipe under its own accepted first-slice contract; it does
   not block ordinary Apothecary access.

## First-use correction — a paid station cannot open empty

The current screen shows only `knownConsumableRecipes`. A recipe becomes known only when the player
opens the station while already holding both a qualifying property sample and at least one of that
recipe's named resources. A player can therefore pay the full construction bundle, enter the new
station and see **Nothing understood yet** with no visible recipe or actionable route. That is not a
discovery loop; it hides the vocabulary needed to pursue the discovery.

Use this tier-0 contract:

1. Completing the Apothecary permanently teaches **Lesser Salve**. It grants no item and consumes no
   ingredients. Its visible shortfall teaches the station's property-qualified world-resource plus
   named-reagent grammar.
2. All other current recipes retain permanent stock inference. Inference may reveal a recipe from a
   suggestive partial holding, while its detail states every exact missing ingredient; the player
   does not need to possess a complete recipe before learning what to seek.
3. The empty state is legal only before construction or in a corrupt/migration failure. An unlocked
   Apothecary always has at least Lesser Salve in its known set after load reconciliation.
4. Apply the already-settled Recommended playtest costs from
   `consumable-economy-field-kit-current.md` at the same contained checkpoint: ordinary salves,
   cures, coatings and field tools cost **0 Essence**; Stillwater costs **6 Essence**; Waystone costs
   **12 Essence + 1 mote**. The current 4–20 Essence tax on ordinary preparations and 20/30 values
   for Stillwater/Waystone are stale implementation values.
5. Construction does not grant Scent Mask, Stillwater, Waystone or the whole catalogue. Those remain
   inferred/additive capabilities with their own ingredients and gates.

This is a first-use guarantee, not a tutorial. The recipe tile, exact shortfall and preparation
result are the explanation.

## Other roster dispositions

- The 23 current catalogue stations all have a route/view mapping.
- All other locked current stations name a keeper and build cost.
- Recycler/Noll, Menagerie/Sabine and Deep Works/Grimmond are not silent orphans in the current
  catalogue; their catalogue promotion is separately queued/held. Tavern is intentionally a
  Firepit upgrade rather than a duplicate station.
- A future station addition must fail catalogue validation when it is neither opening infrastructure,
  an explicit existing-room keeper integration, nor a keeper-owned build with a reachable cost.

### Channelworks copy/receipt correction

The Channelworks is reachable and its build already grants Oda's one authored Heat Conduit, so it is
not another inert station. Its screen nevertheless says that fixture is restored when the station is
raised and then labels the repeatable Heat-core action **Construct Heat Conduit fixture**, making one
completed event look pending. Follow `channelworks-system-current.md`: persist/adopt one restoration
receipt, confirm Oda's restored fixture, and label the separate core-consuming action **Build another
conduit**. This is a contained truthfulness/migration correction, not another feature.

## Closed live-catalogue matrix

“Immediate use” means either an honest player action or a passive benefit already operating in the
field. It does not require every informational or collection station to manufacture a button.

| Place | First-use disposition |
|---|---|
| Writing Desk | Compose/bind is the opening core action. |
| Storehouse | Inspect, identify and manage returned holdings; an empty new-game collection is honest. |
| Workshop | Opening writing research/refining route; later keeper branches remain in their own places. |
| Party | Opening loadout, rank and gambit management; no building lifecycle. |
| Essence Spring | Return yield/respec surface; queued refining correction is separately owned. |
| Constellation | One honest Reality node; no fake future tree. |
| Library | Opening recovered-writing archive; an empty collection truthfully points back to exploration. |
| Trading Post | Vance-owned build; selling and rotating ordinary stock are live first verbs. |
| Blacksmith | Halloway-owned build; reforge known gear. No owned gear is a legitimate stock condition. |
| Tannery | Corrin-owned build grants the free Wear root and exposes constructions immediately. |
| Bowyer | Fen-owned build exposes physical ranged constructions immediately. |
| Armoury | Bracken-owned build exposes rebuild profiles over owned protective gear; no target is an honest stock condition. |
| Weaponsmith | Maud-owned build grants its free point root and exposes close forms; her diary adds the polearm form later. |
| Scriptorium | Isolde-owned build exposes Penmanship; topology/name migration and price review remain separately queued. |
| Firepit | Opening community/party surface; Tavern is a later upgrade rather than another catalogue station. |
| Bestiary | Opening encounter collection; no encountered species is an honest collection state. |
| Survey Post | Mara-owned build exposes instrument research/loadout and later improvement. |
| Apothecary | **Defect:** no owner/cost and can open recipe-empty; corrected by Decisions177–178. |
| Reliquary | Edren-owned build immediately applies site reveal/yield interpretation; its screen confirms the passive field effect. |
| Wayfarer's Table | Sela-owned build immediately applies capacity/organic-yield fieldcraft; flora recognition is the one queued promised extension. |
| Distillery | Auber-owned build immediately exposes blank crystallisation and three attunements; missing stock is an honest recipe shortfall. |
| Channelworks | First fixture is granted on build; **P2 defect:** distinguish that receipt from repeatable core conversion per Decision179. |
| Anchorage | Tovin-owned build exposes Anchor Frame crafting and the realm portfolio; no anchored realms is an honest collection state. |

No third live station is currently a paid empty room. Deep Works, Menagerie and Recycler remain
explicit promotion work rather than hidden members of this 23-station catalogue, so they must receive
the same lifecycle/first-use validation when promoted.

## Acceptance

1. Fresh and Nessa-already-recruited saves expose exactly one Apothecary build site after recruitment.
2. Before recruitment it remains unavailable; DEBUG routing does not count as reachability.
3. Build preview and atomic purchase use the same catalogue cost and state the tier-0 preparation
   capability.
4. Cancel, stale funds, interruption and repeated construction lose nothing and never duplicate the
   station.
5. Existing unlocked saves remain unlocked with unchanged tier/research/inventory.
6. Every `unlockedAtStart:false` live station validates one explicit lifecycle and reachable owner.
7. Phone proof reaches Make → Apothecary build → tier-0 recipe without a hidden debug action.
8. A just-built and a migrated unlocked station both know Lesser Salve exactly once, even with no
   qualifying stock; no item or resource is granted.
9. Partial suggestive stock can permanently reveal another recipe, whose detail exposes its full
   shortfall; reopening/relaunching neither forgets nor duplicates it.
10. Recipe costs match the Recommended continuation profile: every ordinary preparation 0 Essence,
    Stillwater 6, Waystone 12 plus one mote.
