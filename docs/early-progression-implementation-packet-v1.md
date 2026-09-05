# Early sources and first-maker recruitment — implementation packet V1

**4 September 2026 · Decided intended behavior; numbers are first-pass tuning, not measured pacing.**

This closes the outstanding minimum world-category, ordinary-source and early-recruitment decisions in
[the host/consumer contract](early-material-host-consumer-contract-v1.md). Import-ready authored rows are in
[early-progression-production-v1.json](early-progression-production-v1.json). They are design data, not a
runtime file to copy wholesale into `Content/Data`. Engineering owns the typed adapters and native delivery.
Current-source comparison: Apothecary delivery `e201718e5b530b140f8488ed9b4d5a4d0b889ba0`.
No full biome, flora, creature or twenty-nine-person narrative rewrite is a prerequisite for this slice.

**Three-quarter compatibility:** [the minimum height/liquid/visibility contract](three-quarter-world-semantics-v1.md)
now governs any later physical-edge version. It does not pause this early route. Its reachable action-site
checks must use the resolved ground-edge graph when that version is enabled; old worlds retain their rules.

## 1. Minimum resolved region model

A new-generation region stores identity, tile membership, bedrock, surface, formations, resolved liquid,
root-water category, root-temperature category, illumination and incompatible hazard facets. All systems
read these same saved facts. Existing `.stone` and `.soil` tiles are presentation, not proof of a named
bedrock or metal deposit. Do not reinterpret old maps into the new economy.

The JSON gives exact threshold boundaries. Pressure units are game scales, not real temperatures.
Thermal midpoint classifies ordinary cool/temperate/warm roots; an actual frozen root or floor below 25
excludes this cohort. Illumination peak at least 30 is above the existing photosynthesis floor of 8.
Water uses available liquid, plus 15 on a fresh shore within two passable steps. Salinity at most 25 is
fresh. Damp roots are 25–under 50; moist roots are 50–75 inclusive. Water above that range, submersion,
frozen roots, acid precipitation and corrosive air exclude this ordinary cohort. These are independent
facts: a green-looking tile or a water colour cannot certify them.

**Liquid identity and hazard adapter:** fresh roots require resolved ordinary water (including ordinary
water precipitation), not merely a low global salinity number. Saline water fails the fresh threshold;
Mercury and any other non-water root liquid are ineligible. A new unresolved liquid identity is ineligible
until resolved. The current pressure source catalogue has generic `toxic` tags but no acid/corrosive facet:
Miasma alone is toxic, not automatically acid rain; Mercury is non-water, not ordinary root moisture.
Set `acid_precipitation` or `corrosive_air` only from a saved explicitly named chemistry/transformation
result. If no such transform participates in this minimum slice, those two facets remain absent. Never
infer them from colour, and never invent an unapproved Rain-plus-Miasma reaction. Unknown new chemistry
is excluded from the ordinary cohort pending resolution. Existing disclosed toxic world hazards still
apply to the player independently of whether an ordinary plant can grow there.

**Pressure-only water adapter closure (Engineering question, 4 September):** the ordinary Hydrology
baseline is ordinary water even if only water-reducing sources speak. Chasm, Salt, Sand, Thin Air and
Wildfire modify its amount or derived state; they do not make the remaining baseline an unknown liquid.
Brine, Sea and Tide remain water with their actual salinity; they do not automatically pass the fresh-root
test. Frozen-water and all other ordinary-cohort exclusions remain.

Mercury is a separate substrate seam. Its +4 contaminated-seam Hydrology contribution is not root moisture.
Resolve ordinary-water Hydrology from the same baseline and actual authored/generated contributions while
omitting only that non-water contribution **before** the existing clamp and water-only frozen-availability
calculation. Keep the substrate contribution and all other world pressures/random outcomes. Do not subtract
4 after clamping or reroll the world. A Mercury source/tag does not exclude unrelated roots across the
whole world. Explicit Mercury/non-water root-contact positions are ineligible; explicitly unresolved local
contact is reported separately. If the minimum adapter has no such contact placement, do not invent one
or poison every region. This adds no Mercury pool producer, acid transformation, or global contamination
mechanic. JSON quantity fixtures check reduction, coexistence, clamping and frozen water; they precede the
remaining moisture/category tests and are not complete habitat fixtures.

**Sun consistency:** a baseline Thermal 50 plus current Sun produces peak 90/floor 58, midpoint 74:
ordinary warm roots, subject to the other resolved conditions. The old `TerrainRules.paint` rule turning
soil into sand solely above peak 75 must not run again after the new region has resolved ordinary roots.
For this new slice, heat-driven dry/sandy transformation reads midpoint **above 75**; frozen-root rules win
first. Existing worlds retain the old resolver. This is a bounded mapping replacement, not global retuning
of combat heat or a claim that a Sun-only Page guarantees a safe forest. Unwritten targets still roll.

After authored geology/ground guarantees and compatibility transformations, an otherwise unspecified
region draws Granite/Sandstone/Basalt at 40/40/20. Draw once per region using its stable identity; never per
harvest hit. An otherwise unspecified ordinary soil surface draws Loam/Clay soil at 70/30. Existing
explicit sand, ash, snow, liquid and broken ground remain those surfaces. Iron-bearing formation has a
60% independent chance on those three bedrocks; coal-bearing has a 60% independent chance on Sandstone
only. Mud has a 50% clay-bearing-deposit chance. Both formation flags may coexist. An explicit written
resource resolves its own compatible formation first, rather than relying on these rolls. A mineral
node still requires an exposed dry face; do not scatter ore under grass just because bedrock supports it.
A region that lacks a compatible face offers none unless a declared guarantee reserved one earlier.

This minimum default subcatalogue does not delete other already-authored terrain. Explicit other ground
families keep their approved facts and simply cannot host one of these producers unless its table says so.
Unspecified new-region geology uses this bounded pool until later land tables replace it deliberately.

## 2. Ordinary opportunities for all eight materials

Minerals retain the passable-area budget and 70/25/5 common/uncommon/rare lottery. Written sources spend
that budget first. In a world with an eligible host, reserve one ordinary Iron node and one Coal node;
written nodes count toward those minima. Unfilled reservations return their slots. All remaining slots
use eligible material candidates of the chosen rarity, equally weighted. If a rarity has no candidates,
renormalize the remaining eligible rarity weights; if none remain, leave the slot unused.

Loose-earth budget is at least two, scaling at one per 56 entry-connected passable land tiles. Reserve two
Clay gathers if compatible placements exist; other slots remain for their ordinary eligible candidates.
This does not turn every mud tile into Clay.

For at least twelve ordinary compatible root tiles, the flora budget starts at six and scales with that
root area and Vitality as specified in JSON. Reserve two Stem patches, one Leaf rosette, one Resin shrub
and two small Softwoods **only where each exact host exists**. Missing profiles free their reservation.
Remaining size groups are low/medium/tree at 35/30/35; candidates are equal within group. Thus small
Hardwood competes equally with small Softwood in tree slots. Hardwood is visible ordinary stock before
Axe 2, never a prerequisite for opening buildings. Existing nonordinary flora keeps its separate habitat
eligibility; this allowance must not be copied into incompatible worlds.

Counts are per world, allocated across eligible regions in stable seeded order, not per region. First
ordinary action positions aim for path distance 4–12; additional sources 6–24. These are route targets:
on small maps use the furthest legal position within range, then a shorter legal position, recording the
fallback. Never create unreachable matter or erase an authored feature to satisfy a number. Written
sources retain their existing 3–8 and second-node-within-4 contract and must be validated before promising
them. All reservations consume the same population budgets as ordinary placements.

Reserve routes and action positions before blocking trunks. A trunk cannot cut the only route to entry,
portal, required teaching, traveller or written source. Optional branches can require felling. Keep
exploration worthwhile outside the useful route; neither these counts nor a larger map imply a Stability
budget for clearing everything. Tree crowns, saved partial work, contact priority, tool tier and finite
yields remain exactly as in the host contract.

## 3. Actual early recruitment closure

| Priority | Traveller | Band | Blind discovery after prior recruits | New location rule |
|---:|---|---:|---:|---|
| 1 | Vance | 0 | 0 | Existing open-country condition |
| 2 | Nessa | 0 | 0 | Fresh growing land: compatible reachable roots with resin-shrub and softwood host sites |
| 3 | Halloway | 0 | 0 | Reachable workable Iron formation with a legal dry face |
| 4 | Bryn | 1 | 1 | Close, bending paths: existing openness at most 40; remove hard-ground/heavy-air demands |
| 5 | Corrin | 1 | 1 | Compatible reachable growth supporting both Stem and Leaf Fibre |
| 6 | Noll | 1 | 1 | Existing hard-ground and concentrated-material conditions |

This is authored priority, not a forced arrival sequence. Nessa and Halloway are both eligible in a fresh
campaign. No member of the old opening trio is required first. A known location clue can still reach ahead.
The full JSON roster shifts the remaining people into the remaining sort positions while preserving their
relative order, phases and bands. Their explicit blind minima preserve the current **default-window**
thresholds instead of accidentally delaying Isolde and everyone after the inserted makers.

**Remove the three-recruit floor.** Replace `max(3, order - window)` and the separate phase shortcut with
the authored `minimumRecruitsForBlindDiscovery`. This table replaces the default discovery-window knob;
do not apply both. A tuning override may explicitly replace the authored minima in a debug fixture, but
must never silently add a global floor in production. For missing fields in external/legacy content only,
retain its original-version selector; do not infer a new floor from a shifted sort index.

Keep single-traveller selection, earliest represented eligible story band, confidence and near-miss carry.
The current code's score is unique recovered clues plus **twice causally authored known conditions**;
it is not twice all authored conditions. Unread-but-recovered location clues retain their current discovery
credit. Fully authored conditions still affect confidence even if their clue has not been found. Failure
places no replacement person. A traveller only joins after the existing on-map conversation.

### Resolved facts are real predicates

Nessa, Halloway and Corrin use a typed `resolvedFact` signature branch; do not encode a pretend pressure
number or a source-name string in `PressureCondition`. Extend signature evaluation to accept a frozen
world-fact context alongside pressure readings. Existing pressure signatures remain decodable unchanged.
The facts in JSON are computed after region compatibility and reachable action sites, **before** traveller
selection. They certify habitat and possible sites, not that a particular finite plant survives harvesting.
Place the selected person beside the qualifying region where legal; otherwise use a reachable nearby
position with no additional hidden site prerequisite.

Counterfactual authorship evaluates the same fact predicates against the same seed with the authored
contribution removed. Keep independent region/formation salts and unrelated random targets. A guaranteed
Iron face counts as caused only when it would not exist in that counterfactual. If Iron would appear anyway,
its mere written name earns no extra causality. Do not reroll a whole second world or compare only the
pressures for the new fact branch. Store the fact/signature version in the arrival receipt.

## 4. Clues, learning and migration

The JSON supplies complete replacement location prose/IDs and old-page aliases. Nessa, Halloway, Bryn and
Corrin each now have one clear location fact. Vance and Noll retain their existing pages and conditions.
No toxic-air, volatile-ground, hot-forge or deep-food-chain clue remains required for an early maker.

New worlds draw the new clue IDs. Retire superseded old IDs from *new* random clue selection. Existing
owned pages and old-world loot remain recoverable under their original IDs; preserve frozen prose,
origin and read state. A separate current-location annotation shows the updated hint. Historical clues
map to the new index for discovery credit; multiple old pages credit that one condition only once.
Learning the new hint does not award another resource, recruit or duplicate teaching. Known people,
facilities, entitlements, Pages, materials and saved tool identities are never revoked. Old/anchored worlds
keep their frozen people, clues, resources and generation rules. Saved near-miss progress stays with the
person across the signature revision; no reset to make the new route longer.

The opening still grants no known runes before its introductory teaching. Illumination and Sun are
permanently recoverable there. The four JSON entries close the next minimum vocabulary: Hydrology,
River, Substrate and Iron. They use recovered teaching records, one reward each, not a second reward
hidden on a location page. Reuse the existing River teaching identity. New IDs are reserved, not permission
to create a duplicate of an equivalent canonical record: the integration adapter must alias if one exists.
A prerequisite target gets priority before its source focus; collected lessons are read in the Library
for zero Essence. No shop purchase or recruitment gate is added to learning them.

Use the existing one independent teaching opportunity, evidence, 45%/45%/third-eligible-world pity and
placement rules. The maker lessons get same-age priority while needed; existing due lessons still win.
Iron evidence can be a real ordinary Iron formation even when the old pressure-source receipt did not
contain the Iron word. River retains its exact-source evidence. This distinction is explicit, not a generic
claim that any water teaches River.

For location clues, use the existing ordinary diary slot and normalized target buckets. Until both makers
join, alternate eligible resolved worlds beginning with the first: reserve one missing Nessa/Halloway
clue, least known conditions first then Nessa. An already-due exact diary nominee takes precedence and
postpones the reservation. An eligible world has a legal writing placement and an ordinary diary slot;
worlds without one do not consume the alternation. Collection survives collapse, and already-owned IDs
cannot repeat. Other worlds and slots retain the existing ordinary page lottery. This is a finite early
teaching preference, not a full diary-distribution rewrite or an added stream of every character's clues.

## 5. Behavioral acceptance before delivery

Engineering should import these constants and run the following focused checks. Design has inspected
source and validated the authored tables; **no generated-seed, interactive campaign or phone pacing proof
is claimed here**.

1. Boundary fixtures cover every category endpoint, acid/corrosive/submerged/frozen exclusions, Sun's
   midpoint-74 example, soil overlays, both independent formations and invalid face occupancy. Reload
   reproduces saved facts, population and depletion. A granite tile without `iron_bearing` produces no Iron.
2. At zero recruits with both signatures matching, Nessa and Halloway are eligible; selection remains one.
   At one recruit Bryn/Corrin/Noll are eligible. Table-driven cases preserve each later character's prior
   default blind threshold, notably Isolde at three. A clue reaches ahead. An old Nessa clue still bypasses
   the gate but four old pages do not become four score points. A third selected near-miss reaches 100%.
3. New fact causality holds only when the same seeded counterfactual lacks that fact. Removing one written
   resource must not perturb other region draws, cause a second traveller, or expose random pre-Bind facts.
4. Run seeds 0–999 as an initial ordinary-world corpus. Report each eligible host, reserved/missing sources,
   reachable Iron/Coal/growing-land rates and the precise reasons for shortfalls. JSON review thresholds
   (40% Iron, 25% Coal, 25% growing land) are proposed lower bounds, **not measured predictions**. Missing
   reservations on a host with enough legal capacity must be zero. Report small-world capacity exceptions
   separately rather than counting them as successful placements. If incidence fails, return the actual
   dominant incompatible categories for a bounded tuning correction; don't force all materials into every world.
5. Replay the useful routes from empty new stock with the actual starting kit and normal knowledge: Nessa
   foundation plus one Salve (six harvest actions), and Halloway foundation plus Pick 2 (thirteen harvest
   actions across enough ordinary Iron hosts). Test survival/return, travel and encounters as well as counts.
   Aim for each useful out-and-back leg within 48 movement turns and at most 60% of a finite world's budget;
   this is a pacing target, not permission to truncate distant authored goals. Report observed legs and
   balances. Verify the 20-Essence foundation expense leaves the **actual cheapest legal next Bind quote**
   affordable using earned progression income. A flat base fee of 10 alone is not the quote. No purchase
   may be called affordable merely because the starting balance is 40. Do not silently add free money or a
   no-spend gate; if runway fails, return that bounded economy blocker for a specific cost correction.
6. Existing-world migration, first collection, two-hit harvest, Return, craft and tool-upgrade save failures
   must preserve exact-once custody. Materials stay outside item/supply capacity. The same Pick instance
   becomes tier 2; no duplicate grant. Old knowledge, known Pages and self-automation entitlements survive.

## 6. Ready versus dependencies

**Ready now:** registry/Legacy integration can consume the eight-material host contract; region adapter,
ordinary reservation rules, first-six metadata/signatures, clue aliases and teaching rows are closed design.
Engineering can implement these in bounded slices from its current delivered native parent. This design
branch is a documentation parent only; do not replace the native tree with it.

**Required implementation dependencies:** typed material registry and source receipts; new resolved region
context; durable finite producer/Return custody; current teaching-record integration; new signature adapter.
These are explicit engineering work, not unanswered Aimee questions. Behavioral verification and actual
campaign pacing remain delivery gates. No full creature catalogue, later world catalogue, T2 shop, asset
family or Peerless decision is required to deliver the first Salve/Pick path.

**Next bounded design packet:** T2 smelting cost and useful specialist consumers, then only the additional
land/flora and creature rows those consumers actually need. T3, later people and broader balance remain
separate. The partial-Mote-spend question stays in Aimee Homework and does not block these ordinary paths.

## Mineral lottery adapter — 4 September closure

The current ResourceDef has no geological rarity field. Author these occurrence classes explicitly; do not infer them from trade prices, item quality or extraction rank.

| Current resource IDs | Occurrence class |
| --- | --- |
| `ore` / `iron` (one Iron identity), `coal`, `quartz` | common |
| `copper`, `silver`, `obsidian`, `sulfur` | uncommon |
| `gold`, `mercury`, `adamant`, `rift_glass` | rare |

`clay` and `salt` are excluded from this mineral-node lottery because the closed loose-earth and dry-crust producers own them. `rubble` is excluded from the bounded new early pool until its actual producer/consumer route is integrated. This is not removal of owned stock, legacy trade or already-generated worlds.

Preserve each candidate’s existing explicit compatible-host eligibility. These rows do not invent new rock formations, guarantee late minerals, make higher-rank resources harvestable, or add extra placements. Iron’s old and new spellings enter as one candidate, never twice. After written placements and eligible ordinary reservations spend the shared budget, remaining slots use 70/25/5 weights, equally weighted eligible candidates within each bucket. An empty bucket is omitted and the other weights renormalize; no candidates means the slot remains unused. The selected occurrence class changes no material quality, trade price, source colour, chemistry or tool requirement.

This closure supplies the exact candidate-rarity input requested by Engineering’s placement adapter. It is authored tuning, not measured seed-corpus or mounted-play evidence.
