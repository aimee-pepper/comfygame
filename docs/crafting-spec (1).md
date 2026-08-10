# Crafting — Instruments, Gear, Consumables, and the Material Audit

**Nothing is craftable today.** 44 gear pieces exist and every one is *found*; there are no recipes anywhere. This specs what gets made, and audits whether the materials to make it can actually be obtained.

---

# PART ONE — What exists

## Materials, from two sources

**Resources (23)** — harvested from nodes. Every one has real spawn conditions (`requires` / `favours` against pressures), so they're properly world-driven:

| Family | Resources |
|---|---|
| **Stone** | rubble · clay |
| **Metal** | ore *(iron)* · copper · silver · gold · mercury · adamant |
| **Mineral** | quartz · obsidian · salt · sulfur |
| **Organic** | fiber · timber · pulp · resin · toxin · spore |
| **Strange** | reagent · ichor · rift-glass |
| **Currency** | essence_raw · mote |

**Creature materials (11)** — from butchery, derived from trait vectors:

`plate · quill · pelt · down · hide · chitin` *(covering)* · `fang · tusk · claw` *(armament)* · `bone` · `ichor` *(emanation)*

**Both carry grade and a property vector**, so a *superb monstrous plate* is a different input from a *crude plate*.

## Gear (44 found pieces)

| Slot | Count |
|---|---|
| weapon | 16 |
| offhand · head · armor · hands · feet · tool · keepsake | 4 each |

Eleven at each of common / uncommon / rare / mythic. Weapons carry **damage type** and **reach**.

## The gaps

| | |
|---|---|
| **Consumables** | **1** — `salve_lesser` |
| **Recipes** | **0** |
| **Instruments** | **0** — and the analysis progression has no way in (`clause-audit.md` F2) |
| **Crafting stations** | Blacksmith and Scriptorium exist as buildings; neither crafts |

---

# PART TWO — Instruments

**Implementation status, 8 Aug 2026:** acquisition content is built; the fieldwork behavior and
later lens outputs remain. Session 18 resolves the completion design in
`instrument-system-audit.md`: one-turn Survey, permanent observations, crude/good/fine precision,
and distinct tier 3–5 outputs.

**The most valuable thing in this document**, because it closes a progression axis that is fully implemented and completely unreachable: five analysis tiers, `analysisTier` written only by a debug harness.

## How analysis rises

**Two instrument families, and the second is fed by the first** (session 8):

- **Field instruments** measure the world you're *standing in*. Carried, used on arrival.
- **The page lens** predicts before you spend — and **only shows you what you have already measured.**

**So field readings are the currency the lens spends.** Measuring is how you earn prediction.

## Field instruments — one per subject

Made at **Mara's Survey Post**. Each raises what you can read about **one subject**, and readings are **permanent knowledge** stored in Reality.

| Instrument | Reads | Materials | Tier |
|---|---|---|---|
| **Sunglass** | Illumination | quartz · copper | 1 |
| **Thermoscope** | Thermal | quartz · mercury | 2 |
| **Hygrometer** | Hydrology | fibre · silver | 2 |
| **Loupe** | Substrate | quartz · silver | 2 |
| **Level** | Relief | timber · copper | 1 |
| **Vivometer** | Vitality | quartz · resin · ichor | 3 |
| **Barometer** | Atmosphere | mercury · silver · quartz | 3 |
| **Chronometer** | Cycle | silver · adamant · quartz | 4 |

**Quartz is in six of eight** — it's the lens material, and that's what `sigil-vocabulary.md` gave it a job for. **Mercury and adamant gate the late two**, which is right: reading time should be the hardest thing to learn.

## The page lens — four tiers

Made at the **Scriptorium** *(Isolde's)*, because reading your own page is writing's other half.

| Tier | Shows | Requires | Materials |
|---|---|---|---|
| **1** | Qualitative only — *"Frozen over. Little light."* | — | *(you start here)* |
| **2** | **Target values** for subjects you own the field instrument for | 2 field instruments | quartz · silver · glass-grade quartz |
| **3** | **Attribution** — which sigils did what, **including secondaries** | 4 field instruments | + mercury · adamant |
| **4** | **Instability broken out** — greed vs contradiction, red/green underlining | 6 field instruments | + rift-glass |
| **5** | **The living layer** — trait distributions, predicted spawns | all 8 + a Vivometer | + ichor · adamant |

**Tier 2 reads only what you've measured**, so the lens grows subject by subject as your field kit does. **That's the "readings feed the lens" rule, made concrete.**

## What this fixes

- **F2 closed** — a real acquisition path for all five tiers.
- **Quartz, mercury, silver and adamant get purposes** that aren't "expensive metal."
- **Mara's Survey Post has a reason to exist**, and she stops being a companion who unlocks nothing.
- **Sight and Read**, the two skills that fit no combat branch (`combat-trees-full.md` §7), belong here — **knowledge as equipment**, not as a combat option.

---

# PART THREE — Weapons and armour

## The principle

**Recipes ask for properties, not item names** — decided in `materials-crafting-spec.md`. So a shield wants *"covering-type, hardness ≥ 60"*, and any qualifying material works. That's what makes a hoarded exotic hide pay off in a recipe you hadn't discovered when you found it.

## Weapons — the damage triangle from what you killed

| Damage | Made from | Beats | Blunted by |
|---|---|---|---|
| **Pierce** | **fang** · obsidian · quartz | hard coverings | thick, long coverings |
| **Crush** | **tusk** · rubble · iron · adamant | hard coverings | padding |
| **Rend** | **claw** · chitin · obsidian | soft, long coverings | plate |

**Plus a haft** — timber or bone — and **a binding** — fibre or silk.

**Reach** comes from the haft's length, so a spear is *timber (long) + fang*, and that's a real recipe rather than a named item.

**[PROPOSAL] Four weapon tiers**, matching found gear: crude · plain · fine · superb, set by **input grade** rather than by recipe. The same recipe with a monstrous fang makes a better spear.

## Armour — by slot, by property

| Slot | Reads | Wants |
|---|---|---|
| **armor** | hardness × coverage | plate · chitin · iron |
| **head** | hardness | plate · bone · iron |
| **hands · feet** | flexibility | hide · pelt · fibre |
| **offhand** | hardness, density | plate · timber · iron |

**Secondary properties matter** (Q36): **insulation** on anything worn turns aside heat emanation; **reactivity** on a weapon leaves something in the wound. So a *pelt* coat isn't just soft armour — it's what you wear into a cold world.

## Tools

| Tool | Does | Wants |
|---|---|---|
| **Pick** | Harvest hard substrate; faster nodes | iron · adamant · timber |
| **Blade-tool** | Butchery yields | fang · obsidian |
| **Lantern** | Vision in dark worlds | quartz · resin · ichor |
| **Anchor Frame** | Place an anchor on a valid world tile | 2 hard 65 · 2 dense 65 · 1 flexible 55 · 1 reactive 65 · 60 essence |

---

# PART FOUR — Consumables

**Implementation status (9 Aug):** seventeen are authored and implemented: all healing and cures,
four one-hit coatings, all world-facing items, Solvent and Lure. Recipes infer from qualifying
natural stock plus named reagents, remain learned after the suggesting stock is gone, and consume
the weakest qualifying sample first. Traveller's Token remains held on Q47. The Apothecary engine
and debug route exist; production access waits on Nessa's final authored diary prose.

This proposes **eighteen**, all made at the **Apothecary** *(Nessa's)* except where noted.

## Healing — 3

| Item | Wants |
|---|---|
| **Lesser Salve** ✅ | resin · fibre |
| **Salve** | resin · pulp · spore |
| **Greater Salve** | resin · ichor · spore |

## Status cures — 4

*Five statuses exist and only the Steady skill can clear any.*

| Item | Clears | Wants |
|---|---|---|
| **Draught of Clearing** | bleed · poison | pulp · salt |
| **Quenching Draught** | burn · dazzle | reagent · resin |
| **Broad Antidote** | any one status | ichor · reagent · spore |
| **Stonebark Tonic** | selected party member prevents exactly the next affliction, including bleed; then expires | timber · resin |

## Weapon coatings — 4

*The player-side half of the status system, and the Apothecary's obvious output.*

| Coating | Applies | Wants |
|---|---|---|
| **Venom** | poison | toxin · fibre |
| **Firebrand** | burn | reagent · sulfur |
| **Briar Oil** *(placeholder name; replaces Rimeoil)* | bleed | thorn · fibre |
| **Flashsalt** *(placeholder name; replaces Stormsalt)* | dazzle | reagent · mercury |

**Design-lead decision, 9 Aug 2026:** coatings do not add freeze or shock. The settled combat
taxonomy has three `StatusKind` cases because each has an actual producer: burn, poison and dazzle.
Bleed remains a separately implemented legacy affliction with real producers. The four coatings use
those four existing outcomes rather than expanding the taxonomy to preserve old item names.

Rimeoil and Stormsalt are superseded because their names promise freeze and shock. **Briar Oil** and
**Flashsalt** are unblocker names and recipe directions, not final prose: keep their effects stable
while names and exact ingredients remain available for playtest revision.

Stonebark prevention is a one-use guard on the **selected party member**. The next attempted
affliction—burn, poison, dazzle or bleed—is prevented and the guard expires immediately. It does not
prevent damage from the triggering attack, block multiple simultaneous afflictions, or remain until
the end of combat after firing. If it is never triggered, it expires when the current encounter ends;
it is not a persistent pre-buff carried between combats.

## World-facing — 4

*The only consumables that act on the **world** rather than the party.*

| Item | Does | Wants |
|---|---|---|
| **Stillwater** | **Restores stability** — buys turns in a collapsing world | rift-glass · mercury |
| **Waystone** | **Forces an immediate return home, full haul** *(the escape item, session 17 §5)* | adamant · mote |
| **Torch** | Raises vision in a dark world | resin · timber |
| **Farsight Draught** | Reveals part of the map, or the nearest site | quartz · ichor |

## Utility — 3

| Item | Does | Wants |
|---|---|---|
| **Solvent** | Identifies a curio without the Storehouse | reagent · salt |
| **Lure** | Draws a creature to you | toxin · pulp |
| **Traveller's Token** | Raises the chance a traveller stands in the next world written | mote · ichor |

**Every one needs a matching curio**, unidentified, named to hint without telling — *Humming Shard* and *Bound Knot* are the right voice.

---

# PART FIVE — Material audit

## Can everything above actually be obtained?

| Material | Obtainable? | Notes |
|---|---|---|
| rubble · clay · ore · copper | ✅ | Common substrate |
| silver · quartz · obsidian | ✅ | Mid substrate |
| gold · mercury · adamant | ✅ | Late substrate |
| salt · sulfur | ✅ | Volatile |
| fiber · timber · pulp · resin · toxin · spore | ⚠️ | **All flora-driven, and flora doesn't exist.** Currently they must be spawning off Vitality alone |
| reagent | ⚠️ | Needs chemosynthetic flora |
| ichor | ✅ | Emanation creatures |
| rift-glass | ✅ | Contradiction / hazard sites |
| plate · quill · pelt · down · hide · chitin · fang · tusk · claw · bone | ✅ | Butchery, live |

## Findings

**1. Six organic resources depend on a system that doesn't exist.** `fiber · timber · pulp · resin · toxin · spore` are flora products, and **flora is specced and unbuilt**. They presumably spawn off Vitality, which means *a world with herds and no plants still yields timber.* **Flora is now a material-economy blocker**, not just a terrain feature.

**2. `MaterialKind` already declares the flora materials** — `timber, fibre, pulp, toxin, reagent` — with a comment saying they're declared early *"so the material economy has one vocabulary rather than two."* Good foresight; nothing produces them yet.

**3. No material makes glass**, and three recipes want it. **[PROPOSAL]** either add **Glass** as a resource *(it's already proposed as a Strange focus)*, or let quartz serve.

**4. Pulp's only uses are consumables** — which is fine, and it's the answer to whether Pulp should exist. **It shouldn't be backfilled into a paper system; it's an alchemical input.** That resolves the question `cast-roster.md` §4 left open.

**5. Nothing consumes `gold` except currency.** Every other metal has a craft use. **[PROPOSAL]** gold belongs in **keepsakes and instrument fittings** — ornamental, high-value, deliberately not structural. Which is true of gold.

**6. Adamant remains a late permanent-progression material, but it is not the anchoring material.**
Anchor Frames use property-matched world resources instead. Repeatable Waystone demand remains a
separate review item; see `adamant-demand-audit-current.md`.

---

# PART SIX — Where crafting happens

| Building | Makes | Whose |
|---|---|---|
| **Blacksmith** | Ordinary weapons · armour · tools · **reforging · salvage**; foundation for the two advanced equipment shops | Halloway |
| **Apothecary** | Consumables · coatings · **inks** | Nessa |
| **Tannery** | Soft armour · **satchel and storehouse capacity** · bindings | Corrin |
| **Survey Post** | **Field instruments** | Mara |
| **Scriptorium** | **The page lens** · pens · **compounds** | Isolde |
| **Armoury** | **Higher-tier armour upgrades and recipes** · heavy armour · resistances | Bracken |
| **Weaponsmith** | Higher-tier **non-magical melee weapon** upgrades, recipes and fitted trade-offs | **Maud** |
| **Bowyer** | Higher-tier **non-magical ranged weapon** upgrades and recipes: bows, mechanical launchers and thrown families | **Fen** |
| **The Channelworks** | **All magical weapon families**—contained or projected emanation implements at close, mid and far reach—and their upgrades | **Oda** |
| **Exchange → Recycler** | **Breaks gear back into materials** | Vance |

**Every crafting building belongs to someone**, which is session 12 working: *you don't research a smithy, you find a smith.*

The Blacksmith is the ordinary equipment foundation. Advanced equipment then separates by what the
player is making: the **Armoury** owns armour, the **Weaponsmith** owns physical melee weapons, the
**Bowyer** owns physical ranged weapons, and **The Channelworks** owns magical weapons at every
reach. These are specialisations, not replacements for basic forge work.

---

# PART SEVEN — Open

1. **Recipe count.** ~18 consumables, ~30 gear recipes, 12 instruments. **Sixty recipes** is a lot to author — worth checking property-based recipes let one recipe cover several outputs.
2. **Does found gear stay?** 44 pieces exist. **[PROPOSAL] yes** — found gear tides you over before crafting, and sites should carry the best of it.
3. **Glass** — new resource, or quartz serves.
4. **Gold's craft use** — keepsakes and fittings, or none at all.
5. **Waystone's Adamant** — review replacing its repeatable Adamant with Rift-glass; Anchor Frames no
   longer use Adamant.
6. **Flora blocks six resources.** Worth raising its priority — it's no longer just terrain.
