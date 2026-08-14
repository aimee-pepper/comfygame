# Station integration matrix — current design

**Status:** implementation-facing ownership/dependency authority. Existing live costs remain current;
new cost bundles are reversible economy placeholders exposed in debug tuning.

## Station lifecycle types

Every Base destination belongs to one of three explicit lifecycles:

1. **Opening infrastructure:** visible at new game because a core verb or record depends on it.
2. **Found then built:** recruiting its practitioner reveals a build site; paying the cost constructs
   it. Recruitment and construction are separate saved facts.
3. **Existing room, later keeper:** essential early function remains available; recruiting the
   practitioner attaches deeper research/staffing without reconstructing it.

Do not infer lifecycle solely from whether a traveller has a trade. `builtBy` is correct only for
type 2. Type 3 needs separate keeper/deepener metadata.

## Opening infrastructure

| Station | Opening necessity | Later ownership |
|---|---|---|
| Writing Desk | Bind worlds | Binder practice; no keeper |
| Storehouse | Safe persistent inventory | Cross-station projects; no exclusive keeper |
| Workshop | General/self-taught infrastructure | No exclusive keeper |
| Party | Stats, gear, rank and gambits | Interface, not a staffed building |
| Essence Spring | Refine/recover/respec economy | No exclusive keeper |
| Constellation | Reality progression | No ordinary keeper |
| Library | Read the pages used to find people | Lys becomes keeper; see `library-lys-progression-current.md` |
| Firepit | Hold the first recruited people | Orsa later upgrades it into the Tavern |
| Bestiary | Record visible creatures | Kestrel deepens field practice through character abilities, not ownership |

## Found-then-built and keeper integrations

Existing live costs for Mara through Tovin are not silently replaced here. New bundles follow the
settled early/mid/late ladder and use resources reachable before each authored order.

| Keeper | Station/lifecycle | Max purchased tier | First useful capability | Placeholder build/upgrade bundle |
|---|---|---:|---|---|
| Mara | Survey Post · build | 1 | instruments and loadout | live catalogue cost |
| Edren | Reliquary · build | 1 | site record/recovery | live catalogue cost |
| Halloway | Blacksmith · build | 1 | 8 rigid foundational families + reforge | live catalogue cost |
| Isolde | Scriptorium · build | 2 | hands, chaining, compounds | live catalogue cost |
| Sela | Wayfarer's Table · build | 1 | routes/provisions/field practice | live catalogue cost |
| Orsa | Firepit → Tavern · upgrade | 1 | rotating visitors | 80 essence · 18 Timber · 16 Fibre · 10 Clay |
| Vance | Trading Post · build (`trading_post`) | 1 | rotating merchant stock, buy/sell identified goods and appraisal | 10 essence (opening placeholder) |
| Noll *(working)* | Recycler · build | 2 | previewed found/crafted material recovery | 15 essence (opening placeholder) |
| Corrin | Tannery · build | 1 | 3 flexible families; advanced capacity leads | 80 essence · 12 Timber · 20 Fibre · 8 Salt |
| Nessa | Apothecary · build | 1 | currently authored remedies/coatings | 85 essence · 16 Clay · 6 Quartz · 12 Reagent |
| Bracken | Armoury · build | 2 | tier-3 defensive profiles | 120 essence · 28 Iron Ore · 12 Clay · 8 Copper |
| Fen | Bowyer · build | 2 | tier-3 physical far-reach triangle | 110 essence · 24 Timber · 18 Fibre · 8 Resin |
| Maud | Weaponsmith · build | 2 | tier-3 advanced melee families | 150 essence · 32 Iron Ore · 12 Copper · 4 Gold |
| Sabine | Menagerie · build | 2 | Attend/taming, housing and assignment | 180 essence · 28 Timber · 22 Fibre · 18 Clay |
| Grimmond | Deep Works · build | 2 | Sound depth and discovered-sign ledger | 180 essence · 24 Timber · 20 Iron Ore · 8 Quartz |
| Oda | Channelworks · build | 2 | restore/use one carried Heat Conduit fixture | 220 essence · 18 Quartz · 10 Silver · 12 Copper |
| Auber | Distillery · build | 2 | blank crystals and repeatable Heat cores | 220 essence · 24 Clay · 16 Quartz · 8 Silver · 12 Salt |
| Tovin | Anchorage · build | 1 initially | three-route realm portfolio | live catalogue cost |
| Lys | Library · existing/keeper | 1 initially | search/cross-reference/study | no construction charge |

All values are tuning, not story. The identity of the required materials should change only if
reachability fixtures show a keeper can arrive before the player can deliberately obtain one.

## Dependency-safe first usefulness

A built station must do one honest thing immediately. Do not make the player pay for an inert card.

- **Orsa:** Tavern shows visitors immediately after upgrade; no separate research purchase for the
  basic three seats.
- **Vance:** safe selling and rotating merchant stock exist at Trading Post tier 0.
- **Noll:** Recycler tier 0 previews and recovers eligible found/crafted material honestly; baseline
  provenance and transaction safety do not wait for the held diary teaching.
- **Corrin:** at least Supple coat and one capacity lead appear at tier 0.
- **Nessa:** the dependency-safe recipe catalogue becomes craftable when the station is built.
- **Bracken/Fen/Maud:** one tier-3 family/profile root is usable with qualifying stock; tier 4 waits
  for effective tier 2. Effective tier 1 broadens the shop's authored profiles/fitting choices while
  preserving the Tier-3 cap; it is not an empty numerical upgrade.
- **Sabine:** Attend unlocks account-wide and the Menagerie can safely hold one accepted animal;
  combat depth may follow.
- **Grimmond:** Sound depth works on already-discovered signs immediately.
- **Oda:** because Oda precedes Auber, she arrives with one damaged but recoverable **Heat Conduit**
  and its intact core. Building the Channelworks restores this single fixture without requiring a
  repeatable Distillery recipe. It proves the weapon axis and makes her station useful. The fixture
  cannot be dismantled to duplicate its core.
- **Auber:** building the Distillery unlocks blank crystallisation and a repeatable Heat-core root,
  converting Oda's one fixture into an expandable system.
- **Tovin:** the portfolio and any already-discovered inert Atlas Seams become legible at tier 0.
- **Lys:** basic Library never waited; keeper attachment immediately unlocks Catalogue roots.

Oda's carried fixture is an authored possession, not a random cache or free recipe. It should retain
her repair history and remain one ordinary equippable item after restoration.

## Build-site presentation

- Recruiting a type-2 keeper adds one Base construction card with their authored build blurb and the
  complete cost.
- The site persists until built; assigning or removing the keeper from the party cannot hide it.
- A missing resource names its source category/known acquisition route when that information is
  already discovered; it never spoils an unknown focus.
- Confirmation states the first capability the building will provide now—not an aspirational full
  branch list.
- Construction resolves immediately at Base and is interruption-safe. No real-time build timer.

For Orsa, the existing Firepit card changes to an upgrade state rather than adding a second Tavern
building. For Lys, no construction card appears.

## Tier and staffing rules

- `maxTier` is the maximum purchased tier currently authored, not a promise that every station needs
  the same depth.
- Effective tier remains `max(purchased, keeper-earned)`; never sum them.
- Tier 0 means built and useful. Tier 1/2 gates deeper choices.
- Home discounts are station-local. Cross-station dependencies do not spread one keeper's discount.
- Existing saves decode missing station entries from the catalogue and missing keeper links from
  roster state without relocking a built room.

## Required validation

1. Every trade-capable traveller resolves to exactly one lifecycle and station/upgrade destination.
2. Every found-then-built station has a reachable cost and one immediate useful action.
3. No station depends for first usefulness on a later traveller, except Oda's dependency resolved by
   her single carried fixture.
4. Library and Firepit migrations preserve opening access and existing records/roster.
5. Purchased tiers and crafted outputs survive keeper/lifecycle schema migration.
6. Build sites cannot disappear through party, Home or realm reassignment.
