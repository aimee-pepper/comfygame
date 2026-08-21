# Gear crafting families — current

**Status:** current structural authority for the 21 physical Schematics and their maker ownership. Exact
socket eligibility, quality arithmetic, material effects and migration fixtures live in
`crafting-components-and-schematics-current.md`; current catalogue-item disposition lives in
`gear-catalogue-disposition-current.md` and its JSON authority.
**Scope:** Blacksmith, Tannery, Armoury, Bowyer, Weaponsmith and physical gear instance identity.
**Updated:** 21 August 2026.

## Player model

The player chooses an object **Schematic**, then a material for each pictured component. The Schematic owns
slot, damage kind, reach and core silhouette. Materials own the visible treatment and one concise named
consequence in the role where they are installed. Input quality owns the six-band output quality.

Twenty-one physical Schematics are enough for the first complete catalogue because material and quality
create meaningful variants without multiplying names. Found catalogue gear remains a separate authored
source of exact objects; it is not a second recipe list.

No physical gear system adds durability, repair chores, ammunition, random affixes, hidden critical rolls,
encumbrance, soulbinding or crafting failure.

## Exact family register

| Station | Stable Schematic | Output | Tactical identity |
|---|---|---|---|
| Blacksmith | `pointed_blade` | Weapon · Pierce · Close | straightforward anti-hard close weapon |
| Blacksmith | `cutting_blade` | Weapon · Rend · Close | straightforward anti-padding close weapon |
| Blacksmith | `hand_maul` | Weapon · Crush · Close | Might-oriented close impact |
| Blacksmith | `long_spear` | Weapon · Pierce · Mid | front-line reach |
| Blacksmith | `shield` | Offhand | foundational protection |
| Blacksmith | `helm` | Head | ordinary head protection with lining choice |
| Blacksmith | `rigid_guard` | Body | ordinary rigid body protection |
| Blacksmith | `field_pick` | Tool | hard-mineral extraction capability |
| Tannery | `supple_coat` | Body | flexible protection and stronger heat-ward potential |
| Tannery | `working_gloves` | Hands | fitted hand protection |
| Tannery | `working_boots` | Feet | fitted field footwear |
| Armoury | `armoury_rigid_shell` | eligible protective slot | +0.5 protection; low ward emphasis |
| Armoury | `armoury_insulated_layer` | eligible protective slot | −0.5 protection; strong lining/ward emphasis |
| Armoury | `armoury_balanced_laminate` | eligible protective slot | balanced body/lining/fitting construction |
| Bowyer | `longbow` | Weapon · Pierce · Far | Finesse far reach |
| Bowyer | `sling` | Weapon · Crush · Far | Might-compatible far reach |
| Bowyer | `throwing_set` | Weapon · Rend · Far | rending far reach without ammunition inventory |
| Weaponsmith | `weaponsmith_fitted_point` | Weapon · Pierce · Close | advanced fitted close point; +0.5 base power |
| Weaponsmith | `weaponsmith_fitted_edge` | Weapon · Rend · Close | advanced fitted close edge; +0.5 base power |
| Weaponsmith | `weaponsmith_fitted_maul` | Weapon · Crush · Close | advanced fitted close impact; +0.5 base power |
| Weaponsmith | `weaponsmith_fitted_polearm` | Weapon · chosen physical kind · Mid | explicit Pierce/Rend/Crush head choice; +0.5 base power |

The polearm's damage kind is chosen before materials. A family legal for multiple head roles never silently
selects the strongest result.

## Quality and station progression

There are no station quality caps. All-Peerless valid inputs always produce a Peerless item. Halloway can
therefore make a Peerless Pointed Blade, but it remains the simple Pointed Blade rather than becoming an
advanced Weaponsmith object.

Station progression controls:

- which Schematics and protective slot/profile variants are available;
- exact apparatus-bound specialist choices;
- Refitting or Rebuild access;
- ordinary material efficiency only where separately authored.

It never discards input quality. The exact 70% primary / 30% secondary calculation, output performance,
named material effects and strongest-once rules are not repeated here; the component authority is the sole
source.

## Maker roles

### Halloway · Blacksmith

The Blacksmith establishes the physical grammar: the three close damage corners, one mid spear, ordinary
shield/head/body protection and the Field Pick. Halloway also performs Refitting on eligible physical gear.
Refitting replaces one component and cannot change slot, damage or reach.

### Corrin · Tannery

The Tannery owns flexible body construction and all ordinary Hands/Feet crafting. It also owns field-pack
construction through its separate Carry track. It does not become a generic animal-resource shop, and it
does not teach Party plans.

### Bracken · Armoury

The Armoury applies one of three protective construction profiles to a physically sensible Offhand, Head,
Body, Hands or Feet output. Rigid, Insulated and Balanced are trade-offs, not quality rungs. Rebuilding an
existing item preserves exact identity/provenance while replacing its profile and frozen components through
one atomic quote.

### Fen · Bowyer

The Bowyer owns all nonmagical far weapons. Maintained ammunition is part of the weapon fiction; the game
does not create arrows, stones, quivers or ammunition capacity. All three damage corners reach Far.

### Maud · Weaponsmith

The Weaponsmith owns advanced physical melee construction. Fitted means built around an explicit tactical
profile, not soulbound. The polearm variant is the only first-slice Schematic that selects its physical
damage corner before material selection.

### Oda · Channelworks

Channelworks remains separate. Its three housing families and retunable emanation attunements follow
`channelworks-system-current.md`; they are not added to this physical 21 and cannot inherit coatings by
analogy.

## Crafted-instance authority

Every new physical item freezes:

- Schematic ID/version and output slot/damage/reach;
- quality band;
- exact component socket → family → input-band receipt;
- final power/protection, initiative and heat-ward receipt;
- applied strongest-once material consequence IDs;
- visual component treatment IDs;
- stable instance ID, refit history and any preserved legacy workmanship credit.

The catalogue fallback is not player-facing identity. It may supply only a decode-safe base icon until the
Schematic adapter exists. Equipping, recycling, selling, saving and loading must preserve the complete exact
instance.

## Acquisition

- Halloway teaches the three foundational close weapon Schematics, Shield, Rigid Guard and Field Pick with
  the Blacksmith's opening use. Long Spear and Helm become visible inference leads when the player holds one
  compatible primary material; viewing the lead never consumes it.
- Corrin's three flexible Schematics arrive with the Tannery's Wear instruction.
- A specialist's root Schematics arrive with that specialist. Later profile breadth and Maud's polearm come
  from exact station/traveller teachings, never a generic Workshop research list.
- Once learned, a Schematic stays known even when the suggesting material is spent.
- No found catalogue item automatically teaches its nearest Schematic.

## Implementation order

1. Land family+quality material stacks and the component calculator beside current saves without changing
   live craft mutations.
2. Migrate old Tier/reforge power losslessly and remove old rarity copy.
3. Implement the exact Pointed Blade quote/commit/save/Recycler and multipart-visual fixture.
4. Complete the remaining seven Blacksmith families.
5. Complete Tannery's three and its exact legacy ownership migration.
6. Complete Armoury's three profiles and rebuild flow.
7. Complete Bowyer's three far families.
8. Complete Weaponsmith's four advanced families.
9. Integrate Channelworks only through its own first complete housing fixture.

Each step requires rules, persistence, six-across Schematic UI, one ordinary-phone receipt and exact asset
adapter evidence. No bulk 21-family final-art batch begins before the Pointed Blade fixture proves that
Schematic silhouette, material components and quality frame remain independent.
