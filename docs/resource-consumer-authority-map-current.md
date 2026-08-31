# Resource consumer authority map V1

**Status:** Game Design production packet. The tables marked **IMPLEMENTED** describe the exact
resource/crafting source at `a93077f1a13871809d61baf5d6510436e8ad449a`; the current branch changes only
documentation after that checkpoint. Everything marked **PROPOSED** is non-runtime design awaiting the
named decision or implementation slice.

**Purpose:** give Engineering, PM and Player Wiki one bounded answer to “where does this resource come
from, and what is it for?” without collapsing scalar resources, exact material units, Essence or Motes
into one currency.

## Economic identities — IMPLEMENTED

| Identity | Durable owner | Acquisition | Consumers |
|---|---|---|---|
| Scalar world resource | Expedition haul, then `BaseState.resources` | mineral nodes, flora yields, direct pickups, authored site rewards, Trading and legacy Recycler profiles | station foundations, research, ordinary preparations, ink pigment conversion, trade and Raw Essence refinement |
| Exact world-material unit | active/anchored material reserve, then Base reserve | exact authored rewards, Trading and Recycler receipt recovery; the current extraction path does **not** generally mint these units | physical gear sockets, instrument improvement, distilled cores and Anchor Frame |
| Exact creature-material unit | active haul, then `CreatureMaterialReserve` | typed creature outcome and merchant stock | Scent Mask, selected alchemical/core requirements and physical making where the family is accepted |
| Essence Crystal | Base Essence wallet | Raw Essence refinement and authored continuation income | binding, construction, research, physical making, distillation and late preparations |
| Mote | `RealityState` | authored permanent awards, including current site/cache routes | Constellation and Waystone; never an ordinary Base resource spend |

The same displayed noun can therefore have two physical forms. A scalar count of Iron Ore cannot stand
in for an exact ore unit with provenance and properties, and an exact unit cannot silently pay a scalar
foundation cost. Any future bridge must be a named, quoted conversion rather than an implicit cast.

## Complete resource-to-consumer map — IMPLEMENTED

Trade notation is `sell/buy`. Staples are `1/3`, uncommons `2/6`, rares sell for `5`, and precious
resources sell for `12`. Rare and precious resources are not ordinary rotating merchant stock.

| Resource | Acquisition and gate | Building consumers | Recipe/process consumers | Research, service and other sinks | Diagnosis |
|---|---|---|---|---|---|
| Rubble (`rubble`) | Rank-0 mineral node; hard Substrate/Relief; staple trade | — | exact units may satisfy compatible physical sockets | scalar stock can only be sold | **Orphaned scalar resource.** Its existence is coherent; its stockpile has no making/building purpose. |
| Clay (`clay`) | Rank-0 wet, soft Substrate node; staple trade | Reliquary 8, Scriptorium 10, Armoury 12, Apothecary 16, Distillery 30 | compatible exact units in physical making | Armoury research totals 22 | Healthy opening/mid construction material. |
| Iron Ore (`ore`) | Rank-0 mineral node; current sites; staple trade; legacy Recycler | Blacksmith 12, Survey Post 8, Reliquary 12, Armoury 28, Weaponsmith 32, Channelworks 50, Anchorage 40 | compatible exact units across physical makers | Spring, Hold, Satchel, Bargain, instruction and permanence research | **Overburdened.** Opening workhorse status has spread into unrelated late knowledge and capstones. |
| Copper (`copper`) | Rank-1 ductile/volatile seam; uncommon trade | Armoury 8, Weaponsmith 12 | Cyan pigment; compatible fittings/bindings/grips | maker progression, Brush, Ink Mixing, Sunglass and Level | Healthy early specialist metal. |
| Silver (`silver`) | Rank-2 rich ductile seam; rare sale | Distillery 20, Channelworks 20 | Light Core catalyst 2; compatible fittings | Ruling Frame, Fountain Pen, four precision instruments and every Page Lens tier | Strong precision identity; partially crowded by Quartz. |
| Gold (`gold`) | Rank-2 very rich ductile seam; precious sale | Weaponsmith 4 | compatible fittings/bindings/grips | Weaponsmith broaden/masterwork 6 total | Coherent but **single-specialist** after Weaponsmith progression. |
| Quartz (`quartz`) | Rank-1 hard seam; clear air/high light; uncommon trade | Survey Post 2, Apothecary 6, Distillery 30, Channelworks 20, Anchorage 20 | Seamlight 1, Farsight 1, exact optical/Light Core selection | Spring 22, pen work 14, seven instruments, four Page Lens tiers | **Overburdened catch-all lens/structure material.** Preserve optics; stop adding generic late costs. |
| Obsidian (`obsidian`) | Rank-1 ash/geothermal seam; uncommon trade | — | Depth pigment; compatible exact edges/points | — | **Single scalar consumer.** Excellent pigment identity, but accumulated scalar stock lacks a second honest use. |
| Salt (`salt`) | Rank-0 saline/briny/low-water deposit; staple trade | Tannery 8 | Clearing Draught 1, Solvent 1 | Fitted Layers 4 | Healthy preservation/cleansing identity. |
| Sulfur (`sulfur`) | Rank-0 hot volatile/geothermal deposit; uncommon trade | — | Firebrand 1, Heat Core 2, Yellow pigment | — | Healthy combustion/pigment specialist. |
| Mercury (`mercury`) | Rank-3 rich ductile/volatile mineral; rare sale | — | Flashsalt 1, Stillwater 1 | Chaining 2, Thermoscope 2, Barometer 3, Silvered Back 2 | Healthy late motion/measurement identity; Flashsalt fiction is the outlier. |
| Adamant (`adamant`) | Rank-4 extreme hard/valuable unstable seam; precious sale | — | compatible high-grade exact stock | Chronometer 2, Fine Scale 2, Long Glass 4 | Coherent capstone material, but **narrow** once those studies finish. |
| Fibre (`fiber`) | fibrous/small woody flora; Wayfarer organic bonus; current sites; staple trade; legacy Recycler | Blacksmith 6, Tannery 20, Bowyer 18, Wayfarer's Table 12 | Seamlight 1, Venom 1, Briar Oil 1; compatible physical sockets | Tannery/Bowyer and many instruction, Focus, Bargain, Hold and Satchel nodes | **Overburdened.** Keep textile/haft/lining work; generic knowledge costs are shoehorned. |
| Timber (`timber`) | tall woody flora; Wayfarer organic bonus; staple trade; legacy Recycler | Tannery 12, Bowyer 24, Scriptorium 14, Survey Post 10, Wayfarer's Table 14 | Stonebark 1, Torch 2; compatible limbs/hafts/grips | Bowyer, Brush, Desk and Level research | Healthy broad physical material. |
| Pulp (`pulp`) | fleshy flora; Wayfarer organic bonus; staple trade; legacy Recycler | Wayfarer's Table 6, Anchorage 18 | Salve 2, Clearing 1, Lure 1; personal compound formalization | Continuous Settling 8, Compound Assembly 4 | Healthy absorbent/writing material; Lure fiction is weak. |
| Resin (`resin`) | secondary yield from qualifying woody defended flora; staple trade | Bowyer 8 | Seamlight; three Salves; Quenching; Stonebark; Briar Oil; Torch; every ink vial; compatible bindings | Bowyer, Ink Mixing, Compounds, Fountain Pen, Vivometer | **Overcentralized.** Binding/sealing uses fit; raw Resin in drinkable recipes needs correction or explanation. |
| Toxin (`toxin`) | chemically defended flora; uncommon trade | — | Venom 1, Lure 1, Caustic Core option 2; compatible specialist exact stock | — | Venom/Core fit; ordinary Lure is thematically contradictory unless explicitly predator bait. |
| Spore (`spore`) | fungal flora favoured by dark/decay; uncommon trade | — | Salve 1, Greater Salve 2, Broad Antidote 1 | — | Healthy medicinal specialist. |
| Reagent (`reagent`) | chemosynthetic flora in volatile substrate/toxic air; uncommon trade | Apothecary 12 | Scent Mask, Quenching, Broad Antidote, Firebrand, Flashsalt, Solvent; exact specialist stock | — | **Shoehorned catch-all.** Its current noun does not explain six chemically different jobs. |
| Ichor (`ichor`) | scalar definition is creature-only/no ordinary node; exact units come from creature outcomes/merchant; rare sale | — | Greater Salve, Broad Antidote, Farsight, Magenta pigment, Caustic Core option; compatible exact stock | Vivometer 2, Long Glass 4 | **Redundant custody vocabulary.** Scalar and exact Ichor present as one substance but obey different ownership. |
| Rift-glass (`rift_glass`) | Rank-3 seam beside chasms in unstable worlds; rare sale | — | Stillwater 1, Waystone 1 | Fine Scale 1 | Strong late signature material with three distinct consumers; do not broaden casually. |
| Raw Essence (`essence_raw`) | direct wild pickup; current site JSON also pays it; nontradeable | — | Essence Spring refinement at 2:1, then 3:1 after Second Pass; optional Continuous Settling | continuation precursor | Intentional single-use precursor. **Authority conflict:** newer site direction says sites should not award it, but executable JSON still does. |
| Mote (`mote`) | Reality-layer authored site/cache/permanent awards; nontradeable | — | Waystone 1 | Constellation | Intentional rare currency. **Defect:** `pen_chaining` names it as a Base resource cost even though that path cannot own it. |

## Implemented construction pattern

The opening and middle facilities generally express their fiction well: Blacksmith asks for Iron/Fibre;
Survey Post for Timber/Iron/Quartz; Scriptorium for Timber/Clay; Tannery for Timber/Fibre/Salt; Bowyer for
Timber/Fibre/Resin; Weaponsmith for Iron/Copper/Gold. Trading Post and Recycler intentionally cost only
Essence so their shortage-relief services cannot be locked by the materials they help manage.

The late trio does not yet express a later resource tier:

| Facility | Implemented foundation | Problem |
|---|---|---|
| Distillery | 200 Essence, Quartz 30, Silver 20, Clay 30 | precise vessel, but no strange/volatile proof material |
| Channelworks | 200 Essence, Iron 50, Quartz 20, Silver 20 | repeats general machinery stock and does not express restored heat/conduction |
| Anchorage | 200 Essence, Iron 40, Quartz 20, Pulp 18 | writing/binding elements fit; generic Iron weakens the capstone identity |

The catalogue's approximate late target of 150 raw materials is playtest guidance, not authority to inflate
these costs. Both quantity and identity remain design work.

## Recipe-material coherence findings

### Strong implemented pairings

- Torch: reactive fuel + Resin + Timber.
- Stillwater: lustrous source + Rift-glass + Mercury + Essence.
- Waystone: hard source + Rift-glass + Mote + Essence.
- Solvent: reactive source + Reagent + Salt, provided Reagent gains a precise chemical identity.
- Heat/Caustic/Light Cores: exact property-bearing source plus a named catalyst.
- Physical gear: family-constrained sockets and required properties make the object legible.
- Ink: Copper/Ichor/Sulfur/Obsidian become Cyan/Magenta/Yellow/Depth; Resin binds a twelve-use vial.
- Anchor Frame: six distinct high-property exact units create a consequential permanent object.

### Implemented mismatches requiring an authored correction

| Output | Mismatch | Missing role, not an invented resource |
|---|---|---|
| Lesser/ordinary Salves | flexibility/insulation alone does not imply healing | a visibly curative substrate or stronger poultice explanation |
| Clearing/Quenching Draughts | Pulp/Resin read as dressings rather than drinks | decide preparation form or carrier identity |
| Briar Oil | no Oil is consumed | exact Oil or a non-oil name |
| Flashsalt | no Salt is consumed; Mercury/Reagent do not by themselves promise a flash | Salt/flash-bearing ingredient or a different name |
| Lure | Toxin signals harm or repulsion | predator-bait authority or a scent-bearing creature material |
| Seamlight | no seam-bearing ingredient | stronger transformation fiction or a later seam-derived input |
| Farsight Draught | drinking Quartz/Ichor is unexplained | infusion/dissolution form copy or a different preparation form |

No new stable resource ID is authorized by these gaps. Existing Oil, Salt, creature materials and
Rift-glass may cover several roles, but Aimee must choose the exact substitutions before content changes.

## Portfolio classification

- **Genuinely orphaned scalar stock:** Rubble.
- **Single-consumer but intentional:** Raw Essence (refinement) and Motes (permanent progression plus
  Waystone) are currencies/precursors, not failures.
- **Single/narrow and worth one later physical sink:** Obsidian, Gold and Adamant.
- **Overburdened:** Iron Ore, Fibre, Quartz and Resin.
- **Shoehorned:** generic Reagent; Fibre in abstract knowledge; Resin in drinkable preparations; Toxin in
  an ordinary Lure.
- **Redundant/ambiguous identity:** scalar Ichor versus exact creature Ichor.
- **Missing output consumers rather than missing resources:** Caustic Core, Light Core and the stored
  Conduit Fixture do not yet lead to playable equipment/effects.
- **Strong narrow signatures to protect:** Rift-glass, Salt, Sulfur, Spore, Torch, Solvent, Stillwater,
  Waystone and Anchor Frame. A distinctive one-shot outcome does not need an artificial second recipe.

## PROPOSED design corrections — not implemented

1. Give scalar Rubble one bulk reclamation or foundation use; never put it into a potion merely to clear
   the orphan flag.
2. Graduate selected late generic Iron/Fibre/Quartz costs to already-authored late materials after Aimee
   chooses each station's signature.
3. Give Obsidian one heat/edge/structural use, Gold one late precision/ritual use, and Adamant one visible
   masterwork/capstone use only where the output fiction genuinely needs them.
4. Repair the executable Raw Essence site-yield conflict and the Mote-as-Base-resource defect before any
   economy tuning.
5. Decide whether scalar and exact Ichor are two named forms or whether recipes migrate to exact creature
   custody.
6. Resolve the seven recipe-fiction mismatches as one authored content decision set.
7. Keep Caustic/Light Cores hidden or explicitly future-facing until each has an exact playable consumer;
   do not fabricate generic sinks.

## Validation for future implementation

- Every referenced stable ID resolves once in the current resource catalogue.
- Every paid foundation and recipe references a resource owned by its transaction wallet/domain.
- The UI never claims scalar stock can satisfy an exact-unit requirement.
- An output is not advertised as progression until at least one reachable rules-owned consumer exists.
- Rare/precious acquisition remains exploration-led unless a separately approved contract changes Trading.
- Player Wiki states only implemented acquisition and uses; proposed consumers stay unpublished.

