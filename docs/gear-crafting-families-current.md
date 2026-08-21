# Gear crafting families — current design

> **Quality migration hold (21 August 2026):** Recipe families, property requirements, station ownership,
> receipts and specialist trade-offs remain authoritative. Continuous grade/output presentation is under
> review in `crafting-intuition-and-quality-review-current.md`. Keep the implemented formula only as a
> compatibility baseline until Aimee settles the replacement; do not expand it or implement the withdrawn
> pure-no-grade maker table.

**Status:** Current structural design; thresholds, costs and within-tier bonuses are playtest values.  
**Scope:** Blacksmith, Tannery, Armoury, Bowyer, Weaponsmith and physical gear instance data.
Channelworks remains governed by `channelworks-system-current.md`.

## Audit conclusion

The older target of roughly sixty recipes mistakes item-name volume for crafting depth. Because
recipes ask for material properties and materials carry their own provenance, one good recipe
already produces many memorable objects. The physical launch catalogue should contain **21 recipe
families**, each changing slot, damage type, reach or defensive material strategy.

Do not mirror every found catalogue item with a recipe. Found gear remains a distinct source of
authored names and delayed-payoff objects; crafting is how the player deliberately fills a tactical
need from the worlds they have harvested.

## Construction tier versus reforging

These are separate progression axes:

- **Construction tier (1–4):** the item's fundamental quality band. Blacksmith recipes are capped at
  tier 2. Armoury, Bowyer and Weaponsmith are the only physical shops whose station progression can
  preserve Tier 3–4 stock in their domains; poor qualifying stock still produces its honest lower
  tier behind the settled below-headline confirmation.
- **Reforge rank:** Halloway's repeatable work within an item's existing construction tier. It
  improves the piece modestly but never changes its tier or unlocks a specialist recipe family.

Current code adds `upgradeLevel` directly to `gear.tier`, allowing the Blacksmith to bypass every
advanced shop. That behavior conflicts with Aimee's settled shop hierarchy and should migrate to a
within-tier bonus. Placeholder reforge ranks provide 0.2 of one tier-step each, capped at three
ranks; even a fully reforged tier-2 piece remains below tier 3. Halloway may reforge specialist and
found gear too, so the foundational Blacksmith remains useful throughout the campaign.

## Crafted-instance data

Crafted gear cannot be represented only by a catalog definition. Each instance stores:

- recipe family ID;
- slot, damage kind and reach produced by that family;
- construction tier and reforge rank;
- derived insulation and reactivity;
- immutable consumed-sample provenance for honest Recycler output;
- display provenance/qualifier used to name the piece;
- any specialist construction profile.

Catalog IDs provide a fallback icon/base noun. Instance facts control combat and survive recipe or
catalogue retuning. Equipped pieces must preserve the same profile rather than collapsing back to an
ID plus upgrade integer.

## Quality calculation

Every sample must meet its requirement. For qualifying selected samples:

`craftGrade = 0.6 × lowest sample grade + 0.4 × average sample grade`

The weakest input matters enough that one crude binding cannot hide inside monstrous stock, while
the whole selection still contributes.

| Craft grade | Natural tier |
|---:|---:|
| 0–39 | 1 |
| 40–64 | 2 |
| 65–84 | 3 |
| 85–100 | 4 |

The station/recipe cap applies after natural tier. If selected stock exceeds that cap, preview the
wasted potential and require explicit confirmation; never auto-consume the player's finest samples.
Named world resources and essence are structural costs and do not enter grade.

### Construction-cost placeholder

Construction pays essence by the **actual output tier after the station cap**, not by recipe name:

| Output tier | Essence |
|---:|---:|
| 1 | 12 |
| 2 | 24 |
| 3 | 48 |
| 4 | 80 |

These are DRQ-111 playtest values. The owning keeper's Home discount applies through the shared
staffing rule. Rebuilds pay the same output-tier essence because the old piece preserves identity,
not a second hidden pool of reusable ingredients.

A specialist station **permits** tier 3/4 construction; it does not guarantee it despite poor
stock. Construction tier remains `min(natural tier, station cap)`. If the chosen samples yield less
than the specialist's headline tier, preview **This stock yields Tier N; this station can do better**
and require ordinary confirmation. If selected stock exceeds the cap, show the existing wasted-grade
warning. Never raise grade to make the shop look successful and never fail or roll after payment.

Craft one persistent piece per confirmation. There is no batch gear crafting, timer or crafting
failure. Named-resource hardware should be added only where a family's identity genuinely needs it;
the 21 first-slice families already express their construction through distinct property-bearing
samples and do not receive generic Iron/Timber taxes merely for being gear.

## Requirement vocabulary

A sample requirement may specify allowed kinds plus one or two minimum properties. “Any sample” is
valid only when the property itself explains the use. Named world resources may provide ordinary
hardware, fuel or fittings, but never replace the property-bearing samples that make this individual
piece memorable.

The crafting screen selects the weakest qualifying samples by default and permits exact replacement.
It previews the resulting tier, insulation, reactivity, provenance name and every consumed input.

## Halloway's Blacksmith — 8 foundational families

Blacksmith outputs cap at tier 2.

| Family | Output | Core requirements | Tactical purpose |
|---|---|---|---|
| **Pointed blade** | weapon · pierce · close | 1 fang/quill/bone, hardness 35; 1 grip, flexibility 30 | Basic anti-hard option |
| **Cutting blade** | weapon · rend · close | 1 claw/chitin/quill, hardness 35; 1 grip, flexibility 30 | Basic anti-padding option |
| **Hand maul** | weapon · crush · close | 1 tusk/bone/plate, density 40; 1 haft | Might-oriented anti-hard option |
| **Long spear** | weapon · pierce · mid | 1 hard point 40; 1 timber/bone haft, density 30; 1 flexible binding 35 | Front-line reach |
| **Shield** | offhand | 1 hard face 40; 1 dense brace 30; 1 flexible binding 30 | Foundational extra armour |
| **Helm** | head | 1 hard shell 35; 1 flexible/insulating lining 25 | Head protection with inherited warmth |
| **Rigid guard** | body | 2 hard samples 40; 1 flexible binding 35 | Highest ordinary physical protection |
| **Field pick** | tool | 1 hard sample 45; 1 dense sample 35; 1 timber/bone haft | Hard-node harvesting tool |

The field pick's harvesting effect remains the tool-slot effect already intended by the material
spec. Do not add a second generic tool recipe until another tool has a live downstream consumer.
Crafted keepsakes are likewise deferred: the slot is for singular things, and mass-producing empty
sentimental objects would work against it.

## Corrin's Tannery — 3 foundational flexible families

Tannery outputs cap at tier 2. Corrin prepares flexible joints, linings and fitted contact surfaces;
this corrects the earlier temporary placement of these recipes at Halloway's Blacksmith.

| Family | Output | Core requirements | Tactical purpose |
|---|---|---|---|
| **Supple coat** | body | 2 hide/pelt/down/fibre, flexibility 40; insulation 25 | Lower physical tier, stronger heat ward |
| **Working gloves** | hands | 1 flexible sample 40; 1 hard sample 25 | Ordinary hand protection |
| **Working boots** | feet | 1 flexible sample 35; 1 dense/hard sole 30 | Ordinary foot protection |

They use the same crafted-instance and grade rules as all physical gear. Advanced fitted capacity and
the non-inventory binding capability are specified in `tannery-system-current.md`.

## Bracken's Armoury — 3 construction profiles

Armoury profiles may produce offhand, head, body, hands or feet variants where physically sensible.
A newly built specialist station at effective tier 0 permits its one foundational Tier-3
family/profile root, so the building is useful immediately. Effective tier 1 broadens the authored
profile/fitting choices but remains capped at Tier 3; effective tier 2 permits Tier 4. Rebuilding an
existing physical protective item preserves its name/provenance and replaces its construction
profile; preview shows the consumed old piece and new materials.

Exact base eligibility, tier/profile availability, physical-protection offsets, cumulative Recycler
receipt and atomic legacy-safe commit are specified in
`armoury-rebuild-implementation-current.md`.

| Profile | Requirements | Output identity |
|---|---|---|
| **Rigid shell** | 2 hard 65; 1 dense 55; 1 flexible joint 45 | Highest physical tier, little added insulation |
| **Insulated layer** | 2 insulation 65; 1 flexibility 55; 1 hard outer 45 | One tier-step less physical protection, strong heat ward |
| **Balanced laminate** | 1 hard 60; 1 insulation 55; 1 flexibility 55; 1 dense 45 | Middle physical protection and warding; broader material burden |

These are choices, not a linear ladder. Tier-4 insulated gear is not “better rigid shell”; it is the
piece taken into a different world. Reactivity on protective materials does not create a reflected
status in v1.

## Fen's Bowyer — 3 physical ranged families

No ammunition inventory, quiver capacity or projectile crafting is added. A crafted ranged weapon
represents its maintained set of ordinary ammunition; coatings still apply to the next successful
attack as normal.

| Family | Output | Requirements | Tactical purpose |
|---|---|---|---|
| **Longbow** | weapon · pierce · far | 2 timber/quill/fibre, flexibility 60; 1 hard point 50 | Finesse, anti-hard, back-rank safety |
| **Sling** | weapon · crush · far | 1 flexible cord 60; 1 dense projectile 60 | Might-compatible ranged answer |
| **Throwing set** | weapon · rend · far | 2 claw/quill/chitin, hardness 55; 1 flexible carrier 45 | Ranged anti-padding answer |

All three reach far because that is Fen's shop's distinct combat contribution. They cover the damage
triangle without three ammunition subsystems. Tier 3/4 caps follow the specialist tier-0/1/2
rule above. Crossbows,
javelins and additional historical forms wait until they create behavior not already expressed by
these three combinations.

## Maud's Weaponsmith — 4 advanced melee families

The implementation-exact lifecycle, unlock and commit contract is in
`weaponsmith-implementation-current.md`.

| Family | Output | Requirements | Tactical purpose |
|---|---|---|---|
| **Fitted point** | weapon · pierce · close | 1 hard point 65; 1 flexible grip 55; 1 lustrous/dense fitting 40 | Advanced close pierce |
| **Fitted edge** | weapon · rend · close | 1 hard edge 65; 1 flexible grip 55; 1 reactive or lustrous fitting 40 | Advanced close rend |
| **Fitted maul** | weapon · crush · close | 1 dense head 70; 1 hard brace 55; 1 flexible grip 45 | Advanced Might weapon |
| **Fitted polearm** | weapon · chosen physical kind · mid | qualifying head 65; long timber/bone haft 55; binding 55 | Advanced front-line reach; head decides triangle corner |

“Fitted” means selected for a wielder at craft time. It does not soulbind the item: anyone may equip
it, but the preview names the stat lean it best complements. Maud's exclusive diary pattern unlocks
the polearm family's chosen-head variant; it does not create a new fitting subsystem.

## Oda and Channelworks

Oda's three housing families × three retunable attunements remain nine configurations from three
housing recipes, not nine unrelated recipes. They use the ordinary weapon slot and separate
emanation defensive axis exactly as `channelworks-system-current.md` specifies. They cannot accept
coatings or use apex weapons as bases.

## Recipe discovery

- Halloway teaches the first three weapon families, Shield, Rigid Guard and Field Pick on station
  construction; the remaining ordinary slot families appear as visible inference leads once the
  player holds one qualifying sample.
- Specialist roots arrive with their owner. Tier-4 nodes and the polearm variant are learned through
  station branches/diary knowledge, not random cache drops.
- Holding qualifying material may reveal an ordinary recipe lead, never auto-craft or consume it.
- A recipe learned remains learned after the suggesting material is gone.

## Complexity boundary

This design adds crafted-instance provenance and separates construction tier from reforge rank. It
does **not** add durability, repair failure, ammunition, elemental physical weapons, random affixes,
socketing, crafting critical failures, gear binding, encumbrance or material-identification chores.

## Implementation order

1. Migrate reforge rank away from additive construction tier using
   `crafted-gear-migration-current.md`; preserve old saves' effective power and full equipped state.
2. Add crafted gear instance profile/provenance and one Pointed Blade fixture.
3. Add the remaining Blacksmith families and exact preview/sample selection.
4. Add the Tannery's three flexible families and migrate ownership without altering existing items.
5. Add Armoury profiles and rebuild flow.
6. Add Bowyer triangle.
7. Add Weaponsmith families/pattern.
8. Integrate Channelworks only after its one-family prototype validates the separate defensive axis.
