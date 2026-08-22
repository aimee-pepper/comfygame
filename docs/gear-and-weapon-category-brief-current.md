# Weapon and gear categories + component brief — pre-implementation review

**Status:** awaiting Aimee review; blocks weapon/gear rules, migration and Asset production
**Owner:** Game Design; Engineering and Asset consume only after approval
**Updated:** 22 August 2026
**Detailed source:** `crafting-components-and-schematics-current.md`

## Purpose

This is the plain-language review surface that must be accepted before anyone implements the physical
weapon/gear system. It lists every currently proposed category, what the item does, and which independently
selectable physical components define it. The detailed component authority remains non-live until this brief
is reviewed.

Three identities must stay separate:

1. **Category/Schematic** determines the object, slot, damage kind, reach and component sockets.
2. **Material** fills a socket and determines its named contribution and visible treatment.
3. **Quality** is Rough, Standard, Fine, Superior, Exceptional or Peerless; it determines how exceptional
   this instance is without changing the underlying object category.

The first component-crafted weapon is an implementation proof, not a special feature called a “Pointed
Blade component slice” and not permission to build the whole art catalogue.

## Proposed category coverage

The live catalogue currently contains 75 gear identities across eight equipment slots. A category being live
does **not** mean it is craftable by the component system:

| Live slot | Live identities | Component-system disposition |
|---|---:|---|
| Weapon | 34 | covered mechanically by the eight weapon categories below, but every retained found identity still needs an explicit category mapping |
| Off-hand | 6 | Shield is craftable; other authored/unique found silhouettes remain exact found gear unless separately mapped |
| Head | 6 | Helm is craftable; Armoury profiles require the legality decision below |
| Body / Armor | 6 | Rigid Guard and Supple Coat are craftable; Armoury profiles require the legality decision below |
| Hands | 5 | Working Gloves are craftable; Armoury applicability is unresolved |
| Feet | 5 | Working Boots are craftable; Armoury applicability is unresolved |
| Tool | 5 | Field Pick is the only designed craftable tool family |
| Keepsake | 8 | no ordinary physical Schematic; these remain found/authored accessories and may later receive the separate inscription system |

The eight apex-only weapons and other authored uniques retain their exact named identity. Component crafting
must not make their silhouettes or special rules ordinary, and recycling one never teaches an apex Schematic.

### Weapons

| Player category | Proposed Schematics | Combat identity | Required physical components |
|---|---|---|---|
| Close piercing blade | Pointed Blade; later Fitted Point | Pierce · Close | point (primary), grip (secondary); Fitted Point also adds fitting (secondary) |
| Close cutting blade | Cutting Blade; later Fitted Edge | Rend · Close | edge (primary), grip (secondary); Fitted Edge also adds fitting (secondary) |
| Close crushing weapon | Hand Maul; later Fitted Maul | Crush · Close | head (primary), haft or brace (primary/secondary by Schematic), grip on Fitted Maul |
| Mid-reach spear | Long Spear | Pierce · Mid | point + haft (both primary), binding (secondary) |
| Mid-reach advanced polearm | Fitted Polearm | player selects Pierce, Rend or Crush · Mid before materials | matching point/edge/crush head + haft (primary), binding (secondary) |
| Far bow | Longbow | Pierce · Far | two limbs (primary), string (secondary) |
| Far sling | Sling | Crush · Far | **unsettled:** current table uses cord + projectile as primary and pouch as secondary |
| Far throwing set | Throwing Set | Rend · Far | two edges (primary), carrier (secondary) |

### Off-hand and protective gear

| Player category / slot | Proposed Schematic | Required physical components |
|---|---|---|
| Shield / Off-hand | Shield | face + brace (primary), binding (secondary) |
| Helm / Head | Helm | hard shell (primary), lining (secondary) |
| Rigid body armour / Body | Rigid Guard | two rigid body panels (primary), binding (secondary) |
| Flexible body armour / Body | Supple Coat | flexible outer (primary), lining (secondary) |
| Gloves / Hands | Working Gloves | flexible hand body (primary), facing (secondary) |
| Boots / Feet | Working Boots | flexible upper + sole (primary), binding (secondary) |

### Armoury construction profiles

These are currently written as construction/refit profiles for an eligible protective slot, not separate
equipment slots:

| Profile | Intended identity | Components |
|---|---|---|
| Rigid Shell | highest ordinary protection, heavier visual structure | two hard-shell body components (primary), binding (secondary) |
| Insulated Layer | lower direct protection, stronger heat ward | two linings (primary), rigid outer (secondary) |
| Balanced Laminate | mixed structure and lining | rigid body + lining (primary), binding + fitting (secondary) |

Before implementation, “eligible protective slot” must be closed explicitly for Head, Body, Hands and Feet;
the current authority does not say whether all three profiles are lawful in every protective slot.

### Tool

| Player category | Proposed Schematic | Function | Components |
|---|---|---|---|
| Mining pick / Tool | Field Pick | hard-node harvest capability | pick point + counterweight (primary), haft (secondary) |

No other harvest-tool category is currently specified.

## Component families

The player chooses an exact material within the compatible family for each socket. These lists are closed;
finding a new material does not silently make it legal everywhere.

| Component family | Used by | Compatible material families |
|---|---|---|
| Point | piercing blades, spears, picks | Iron, Adamant, Obsidian, Quartz; Fang, Quill, Bone, Tusk, Horn |
| Edge | cutting blades, throwing sets | Iron, Adamant, Obsidian; Claw, Chitin, Quill, Bone, Shell |
| Crush head | mauls and pick counterweight | Rubble, Iron, Copper, Adamant; Bone, Tusk, Horn, Plate, Shell |
| Grip | close weapons | Fiber, Timber, Copper, Silver, Gold; Hide, Pelt, Fin, Bone, Horn |
| Binding | joins on weapons/armour | Fiber, Resin, Copper, Silver, Gold; Hide, Fin |
| Haft / brace | mauls, spears, shields, picks, polearms | Timber, Iron, Adamant; Bone, Horn |
| Fitting | advanced Weaponsmith objects | Copper, Silver, Gold, Quartz, Adamant; Bone, Horn, Quill |
| Rigid body | shields and ordinary rigid armour | Iron, Copper, Adamant, Timber; Bone, Hide, Scale, Plate, Chitin, Shell |
| Hard shell | helms and Armoury rigid profiles | Iron, Copper, Adamant; Bone, Scale, Plate, Chitin, Shell, Quill |
| Flexible body | coats, gloves and boots | Fiber; Hide, Pelt, Fin, Scale |
| Flexible facing | glove/contact reinforcement | Hide, Scale, Chitin, Quill, Bone |
| Lining | helms, coats and Armoury profiles | Fiber; Hide, Pelt, Down, Feather, Fin |
| Sole | boots | Timber; Hide, Bone, Scale, Chitin, Plate, Shell |
| Bow limb | longbow | Timber; Horn, Quill, Bone |
| Bow string | longbow and current Sling cord | Fiber; Hide, Fin |
| Sling projectile | current Sling proposal only | Rubble, Clay, Iron, Copper, Adamant; Bone, Tusk, Horn, Shell |

Ingredient-only resources such as Salt, Sulfur, Mercury, Toxin, Spore, Reagent, Venom and Ichor are not
ordinary physical components. Rift Glass is reserved for explicitly magical/singular recipes.

## Material contribution shorthand

Material identity affects the object only through readable named contributions:

- Point/Edge may be **Keen**; dense weapon cores may be **Forceful**.
- Rigid bodies may be **Reinforced**; secondary structures may be **Braced** or **Secure**.
- Fiber, Feather, Fin and similar families may be **Light**.
- Pelt/Down and related linings may be **Insulated**.
- Silver/Gold may be **Valuable** and **Conductive**, but Conductive has no ordinary weapon effect unless a
  magical system explicitly consumes it.
- Heavy materials impose the explicit initiative trade-off; higher quality does not erase material weight.

There are no random affixes, durability chores, critical-chance rolls or hidden consolation bonuses in this
system.

## Unresolved decisions that block implementation

1. **Ranged ammunition:** the proposed Longbow abstracts arrows, while the Sling freezes one projectile as
   a permanent primary component. That is inconsistent. Recommended direction: no ordinary consumable-ammo
   inventory; define every ranged Schematic by the persistent weapon itself, and remove or reframe Sling's
   projectile socket before implementation.
2. **Protective-profile legality:** explicitly map Rigid Shell, Insulated Layer and Balanced Laminate to the
   Head/Body/Hands/Feet slots where each is sensible; do not allow a generic profile to generate nonsensical
   boots or gloves.
3. **Keepsakes/accessories:** the live equipment vocabulary includes Keepsake/accessory-like objects, but no
   physical crafting family here owns them. Seamlight enchanting belongs to a separate enchantment contract,
   not an improvised Blacksmith socket.
4. **Magical/Channelworks gear:** deliberately excluded here and still needs its own category/component brief
   before implementation.
5. **Hand occupancy:** the table does not yet state one-handed/two-handed use or how Shields interact with
   Longbows, Spears, Polearms and Mauls.
6. **Tool breadth:** only the Field Pick is specified. If resource progression later needs axes, knives,
   nets or gathering tools, those categories must be settled rather than inferred from the Pick.
7. **Found gear mapping:** the 75-ID catalogue disposition exists, but Aimee needs a readable mapping from
   each retained found identity to these categories or to authored-unique/legacy-only status before migration.
8. **Names:** Pointed Blade and the other Schematic names are working player-facing names, not immutable
   implementation terminology. Aimee may rename them without changing the component model.

## Approval gate

No weapon/gear migration, component-built item mutation, multipart sprite pack or catalogue-wide gear art is
authorized until Aimee reviews this brief and the eight unresolved decisions above are closed or explicitly
deferred. After approval, Engineering and Asset begin with one category chosen from the approved table and
prove its complete rules → preview → atomic craft → inventory → save/load → recycle → visual correspondence
loop before expanding breadth.
