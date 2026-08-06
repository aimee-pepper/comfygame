# Resources & Skills — expanding the thin content

**Status:** Claude's design. Numbers and names **[PLACEHOLDER]**.

**Framing, corrected.** This is not a game about hauling materials. It's a game about **writing worlds and putting the Atlas back together**. Materials are a means to that end — they fund research, crafting, binding and anchoring.

But that's exactly why the resource list matters: **a resource is a reason to write one world rather than another.** With four of them, every world you can imagine hands you the same handful of things, so the authoring system — the actual game — has nothing to aim at. Four resources make a rich vocabulary pointless.

Same logic for skills. Two skills means every fight is the same two buttons no matter how varied the creature you're fighting.

---

<details open>
<summary><b>1. Resources — the design rule</b></summary>

**Every resource should make you want to write a particular kind of world.** If two resources come from the same conditions, one of them is redundant.

So resources are indexed by **what produces them**, and each maps to pressure states that a player must deliberately compose.

### Mineral — from Substrate

| Resource | Written by | Feeds |
|---|---|---|
| **Rubble** | any hard substrate | Bulk construction; cheap and everywhere |
| **Clay** | soft substrate + moisture | Vessels, base building |
| **Iron** | ductile, moderate richness | The workhorse metal |
| **Copper** | ductile + moderate volatile | Alloys, conductive work |
| **Silver** | ductile, high richness | Fine work, instruments |
| **Gold** | ductile, very high richness | Rare; instruments and ornament |
| **Quartz** | hard + high richness | Lenses — **the analysis instruments** |
| **Obsidian** | hard + volcanic thermal | Edges; piercing weapons |
| **Adamant** | hard, extreme richness, high instability | Endgame; the anchoring resource? |
| **Salt** | volatile + high salinity | Preservation, apothecary |
| **Sulfur** | volatile + thermal | Reagents, hazard crafting |
| **Mercury** | ductile + volatile, rare | Strange work; Aimee's own example |

### Organic — from Vitality and flora

| Resource | Written by | Feeds |
|---|---|---|
| **Fibre** | fibrous tissue | Bindings, book covers, light armour |
| **Timber** | woody tissue + stature | Structure, hafts |
| **Pulp** | fleshy tissue | Paper — **the pages you write on** |
| **Resin** | woody + warm | Sealing, adhesives, inks |
| **Toxin** | chemical defence | Apothecary, coated weapons |
| **Spore** | fungal metabolism | Dark-world exclusive; strange crafting |

### Strange — from conditions that are hard to write

| Resource | Written by | Feeds |
|---|---|---|
| **Reagent** | chemosynthetic flora / volatile substrate | Volatile crafting |
| **Ichor** | emanation-bearing creatures | Elemental work |
| **Rift-glass** | contradiction / hazard sites | The most expensive recipes |

### Essence family — unchanged, restated

**Raw essence** (wild drops) → **essence** (refined; buys research and crafting) → **crystals** (condensed from essence; binds books). Plus **[OPEN]** the separate anchoring resource — **Adamant** above is a candidate, since "only found in worlds too rich to be stable" means greed funds greed.

**Roughly 21 plus the essence family.** The point isn't the count — it's that **Pulp comes from fleshy flora, and pages are made of pulp, so a papermaking world is a thing you'd deliberately write.** That's the loop working.

</details>

<details>
<summary><b>2. Skills — the design rule</b></summary>

Two skills today. The combat-depth spec assumes many more, and skills are the player's answer to trait-derived foe variety.

**Every skill should answer a specific kind of creature.** If a skill is good against everything, it's just a bigger attack.

### Where skills come from **[PROPOSAL]**

Three sources, so acquisition ties into systems that already exist:

1. **Research** — the baseline ladder, one branch of the existing tree.
2. **Companions** — a recruited specialist brings their own. This gives recruitment a combat payoff and ties skills to the search loop.
3. **Gear and materials** — a weapon made of a particular material grants a technique. Ties the material chain to combat directly.

### A starter set

Each names the problem it solves.

| Skill | Effect | Answers |
|---|---|---|
| **Pry** | Ignores armour entirely, low damage | Heavily plated foes |
| **Overbear** | Heavy crush damage, you act last next turn | High-armour, low-initiative foes |
| **Flense** | Bleed over turns, scales with covering *length* | Shaggy, thick-pelted foes |
| **Sight** | Reveals a foe's traits and covering type | Anything you haven't met |
| **Ward** | Reduces incoming damage of one type for a turn | Emanation and elemental foes |
| **Draw Off** | Forces a foe to target you | Protecting a companion |
| **Fall Back** | Swap ranks without spending the turn | Positioning (needs the rank system) |
| **Snuff** | Removes a foe's light or emanation | Emanating and lit foes |
| **Quicken** | Act twice next turn, then skip one | Burst against a low-HP foe |
| **Steady** | Clears bleed/poison/burn on one ally | Status pressure |
| **Rout** | Guaranteed flee at no stability cost | The fight you shouldn't have started |
| **Read** | Learn a foe's species permanently — bestiary entry without a kill | Collection, and it's a non-violent option |

**Two things worth noting:** *Sight* and *Read* make combat a source of **knowledge**, not just loot — which fits a game whose progression is literacy. And *Rout* gives fleeing a skill-shaped answer rather than being a pure penalty.

### Cost model

Keep the existing **round-counted cooldown** (blessed in audit #5's rulings). **[PROPOSAL]** stronger skills carry longer cooldowns rather than a mana pool — a second resource to track in every fight is the wrong kind of overhead for this game.

</details>

<details>
<summary><b>3. Why this is the highest-value content work</b></summary>

The generative systems are in good shape. What's thin is what they draw on. Adding resources and skills doesn't require new systems — both slot into structures that already exist (`resources.json`, `skills.json`, the research tree, butchery, crafting).

And it's the difference between *the machine works* and *the game is worth playing*: with 21 resources, the pressure vocabulary finally has something to aim at, and with a dozen skills, trait-derived foe variety finally has something to answer it.

</details>

<details>
<summary><b>4. What I'd want challenged</b></summary>

1. **Whether resources should map this tightly to pressures.** It makes worlds legible and purposeful, but it risks "write the iron world" becoming a checklist rather than a composition.
2. **Pulp → paper → pages.** I like it a lot — the thing you write on is a thing you farm — but it means a papermaking world is *mandatory*, which is a soft gate.
3. **Adamant as the anchoring resource.** Elegant (only found in worlds too rich to be stable, so greed funds greed) but it makes anchoring gated behind late-game world-writing.
4. **Skills from companions** — good for the search loop, but it means combat power is gated behind finding people, which may frustrate.
5. **Twelve skills enough**, or does each party member need their own list?
</details>
