# Materials, Looting & Crafting (v1 spec)

**Status:** first full spec of the payoff end of the loop. **[PROPOSAL]** marks my calls; all numbers **[PLACEHOLDER]**.

> **Later ownership correction:** ordinary colored writing ink belongs to Isolde's Scriptorium /
> Penmaker progression under `authored-color-vocabulary-current.md`, using world resources directly.
> Older rows assigning generic “inks” to the Apothecary are historical proposal context only. Nessa
> retains consumables, coatings, cures and any future specifically authored reactive stains.

**The principle, already decided:** materials derive from the same trait vectors that produced the creature, flora, or substrate. **Recipes ask for properties, not item names** — so an exotic hide hoarded months ago can satisfy a recipe discovered later. That is the "held the bucket of drinks, found its perfect purpose" feeling, mechanised.

---

<details>
<summary><b>1. What a material is</b></summary>

Three parts. Keeping them separate is what makes materials both memorable and property-matchable.

| Part | What it is | Example |
|---|---|---|
| **Identity** | A *named region* of trait space. Authored, finite, recognisable. | Plate, Quill, Pelt, Down, Hide, Chitin, Fang, Tusk, Horn, Bone, Ingot, Ore, Fiber, Timber, Resin, Toxin, Salt, Shard |
| **Properties** | Continuous values inherited from the source. What recipes actually read. | hardness 0.81, density 0.62, insulation 0.15… |
| **Grade** | How extreme/pure/large the source was. One scalar. | fine, superb, monstrous |

**Why identity exists at all:** pure continuous values give you *Hide (0.31, 0.72, 0.55)*, which nobody treasures. A name plus a grade gives you *a monstrous ankylosaur plate* and *a fine prismatic pelt* — different treasures for different reasons. Identity is the memorability layer; properties are the mechanical layer.

**Identity resolution** works exactly like creature identity: authored named regions over a continuous space, computed at read time from stored properties. **The stored record is the property vector, never the name** — same durability rule as specimens, so identity definitions can change without breaking saves.

</details>

<details>
<summary><b>2. The property schema</b></summary>

**[PROPOSAL] Six properties.** Small enough to reason about, wide enough to express the material triangle plus organics. All 0–100.

| Property | Meaning | Sourced from |
|---|---|---|
| **Hardness** | Resists deformation | Covering hard-axis; substrate hard corner |
| **Density** | Mass per volume | Bone density; substrate; covering coverage |
| **Flexibility** | Bends without breaking | Covering soft-axis; ductile corner; flora fibrous tissue |
| **Insulation** | Holds heat | Covering length + coverage; flora fleshy tissue |
| **Reactivity** | Chemically/energetically active | Volatile corner; flora defense axis; emanation |
| **Lustre** | Optical character | Finish triangle (opacity/shine/schiller) |

**[PROPOSAL] Two flags** rather than properties, because they're categorical: **Organic / Mineral**, and **Toxic**.

</details>

<details>
<summary><b>3. Where materials come from</b></summary>

### 3.1 Creatures — drops derive from the trait vector

No authored per-creature loot table. The parts that composed the creature compose what it leaves.

| Trait axis | Yields | Property mapping |
|---|---|---|
| **Covering** (soft↔hard, short↔long, bare↔dense) | hard+short+dense → **Plate** · hard+long → **Quill** · soft+long+dense → **Pelt** · soft+long+sparse → **Down** · soft+short → **Hide** · hard+layered → **Chitin** | hardness, flexibility, insulation directly |
| **Armament** (pierce/crush/rend) | pierce → **Fang** · crush → **Tusk/Horn** · rend → **Claw** | hardness high, density from build |
| **Frame** (bone density) | **Bone** | density directly |
| **Finish** | Applied to whatever drops | lustre |
| **Coloration** | Carried through | cosmetic + recipe gating for dyes |
| **Emanation** (rare) | **Ichor** or similar | reactivity very high |

So a prismatic hide is *actually* prismatic because that creature was, and a monstrous plate is monstrous because that creature was huge. **Drop quantity scales with creature size**; drop *quality* scales with how extreme its traits were.

### 3.2 Flora — from the flora axes

| Axis position | Yields |
|---|---|
| Woody tissue | **Timber** — hardness mid, density mid |
| Fibrous tissue | **Fiber** — flexibility high |
| Fleshy tissue | **Pulp/Resin** — insulation, reactivity |
| Defended (thorned/toxic) | **Toxin** — reactivity high, Toxic flag |
| Canopy stature | Timber in quantity |

### 3.3 Substrate — from the composition mix

| Corner | Yields |
|---|---|
| Hard | **Stone**, **Shard** — hardness high, flexibility low |
| Ductile | **Ore** → smelted to **Ingot** — flexibility mid, density high, lustre |
| Volatile | **Salt**, **Sulfur**, **Reagent** — reactivity high |
| Inert | **Clay**, **Sand** — fill; cheap, useful in bulk |

### 3.4 Sites — the singular things

Landmarks give concentrated materials (the same identities, exceptional grades). **Ruins give knowledge and unique items, never currency** (Q17). Unique items are authored, property-matched, and singular — the artefact you keep because there isn't another.

</details>

<details>
<summary><b>4. Grade and rarity</b></summary>

**Grade** is a single scalar derived from how far the source sat from ordinary: trait extremity, purity of the identity region, and size.

**Displayed as dual percentiles** (decided earlier): against **nature** (a fixed global distribution — an ordinary hide is ordinary forever) *and* against **your own finds** ("finest pelt you've recovered"). Personal carries the early game; global keeps late finds objectively meaningful.

**Rarity is not a tag.** It's a consequence of how expensive the source world was to author — locked earlier and it holds here. Prismatic chitin isn't rare because it's flagged rare; it's rare because the world that grows it costs a great deal to write and hold.

</details>

<details>
<summary><b>5. Recipes ask for properties</b></summary>

A recipe names **requirements**, not items:

```
Reinforced Buckler
  ├─ 1× covering-type, hardness ≥ 60, density ≥ 40
  ├─ 2× any Mineral, hardness ≥ 50
  └─ 1× binding: flexibility ≥ 55
```

Anything qualifying works. Consequences, all intended:

- **Hoarding pays off later.** A material kept for months turns out to satisfy something new.
- **No combinatorial recipe authoring.** A handful of property-driven recipes covers an unbounded material space.
- **Substitution is discovery.** Realising a quill works where a plate was expected is a small delight and teaches the schema.
- **Overshoot improves output.** **[PROPOSAL]** result quality scales with how far inputs *exceed* requirements, so bringing a superb plate to a modest recipe makes a better buckler. That's what stops players from always using the cheapest qualifying junk.

**[PROPOSAL] Recipes are discovered, not bought** — found in ruins, taught by companions, or inferred at a building once you hold materials that would satisfy something. Consistent with the no-shopping-list stance.

</details>

<details>
<summary><b>6. The crafting buildings</b></summary>

**[PROPOSAL] Three, each keyed to a material family** — so which building you use is legible from what you're holding.

| Building | Consumes | Produces |
|---|---|---|
| **Blacksmith** | Mineral, high hardness/density — Ingot, Stone, Shard, Plate, Fang | Weapons, heavy armour, tools, **instruments** (the pens) |
| **Tannery** | Organic coverings — Hide, Pelt, Down, Chitin, Fiber | Light armour, **satchel and storehouse upgrades**, bindings, book covers |
| **Apothecary** | Reactive and floral — Toxin, Resin, Reagent, Salt, Ichor | Consumables, tethers, identification aids and specifically authored reactive stains; not ordinary writing ink |

Existing buildings keep their jobs: **Refinery** (essence), **Library** (knowledge), **Workshop** (research), **Menagerie** (animals).

**Historical proposal consequence:** this originally placed inks at the Apothecary. Current design
instead puts CMY+Depth pigment preparation at Isolde's Scriptorium; it is still materially funded by
world resources. Instruments and cover ownership follow their newer current station documents.

</details>

<details>
<summary><b>7. Gear</b></summary>

**[PROPOSAL] Four slots per party member:** Weapon, Armour, Tool, Keepsake.

- **Weapon** — damage profile inherited from material properties: a fang weapon pierces, a tusk weapon crushes. The armament triangle reappears in your own gear.
- **Armour** — hardness reduces damage, density costs speed/turn order, insulation resists thermal hazards. The defence–mobility trade-off from the biology research, applied to the player.
- **Tool** — harvesting speed, node access (hard substrate needs a harder tool), vision, tether capacity.
- **Keepsake** — a slot for the singular things. Unique site artefacts, a recovered diary, a companion's gift. **[PROPOSAL]** mostly small effects; emotionally the point is that treasured objects have somewhere to live.

**Upgrading over replacing:** **[PROPOSAL]** gear can be reforged with better materials rather than discarded, so a piece you like can grow. Fits hoarding, and avoids the loot-treadmill feeling.

</details>

<details>
<summary><b>8. Build order</b></summary>

1. **Property schema + material identities** — the data spine; everything else reads it.
2. **Creature drops from trait vectors** — the biggest single change to looting.
3. **Flora and substrate drops.**
4. **Grade + dual percentiles.**
5. **Property-based recipes + one building (Blacksmith).**
6. **Historical Tannery/Apothecary breadth** — later station authorities supersede the proposed
   instruments/inks/covers grouping.
7. **Gear slots + reforging.**
8. **Unique site artefacts + Keepsake slot.**

</details>

<details>
<summary><b>9. Open</b></summary>

1. **Resolved by `world-resource-reserve-current.md`:** presentation groups by material kind while
   the non-slot reserve retains every exact property-bearing sample. Materials do not consume item
   or Field Kit slots.
2. Is there a salvage/breakdown path for gear you don't want?
3. Does grade decay, or are materials eternal? (Leaning: eternal — decay fights hoarding.)
4. How many recipes ship, and how are they discovered in practice?
5. Can the player *see* a material's properties before crafting, or must they learn them? (Leaning: visible once identified — the identification system already exists for curios.)
</details>
