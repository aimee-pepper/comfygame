# Crafting components and physical schematics — current authority

**Status:** Game Design content authority for the six-band physical-crafting migration. This completes the
material-family `ComponentProfile`, physical schematic socket, modifier, migration and Pointed Blade tables
required by `crafting-intuition-and-quality-review-current.md`.
**Scope:** future crafts and refits at Blacksmith, Tannery, Armoury, Bowyer and Weaponsmith. Channelworks,
consumables, instruments, Distillery and singular Waystone/anchor recipes retain their own ingredient rules.
**Does not change live code yet:** current exact samples, crafting rules, saves, UI or item power remain intact
until Engineering starts the ordered migration.
**Updated:** 21 August 2026

Validation: `python3 scripts/validate_crafting_components.py`.

## 1. Player rule and persisted identity

A crafted physical item freezes:

- Schematic ID and version;
- output quality band;
- every component socket, selected `domain.family` and selected input band;
- material contribution/trade-off IDs actually applied;
- final power/protection, initiative and heat-ward receipt;
- visual component treatment IDs;
- legacy workmanship credit where migrated.

Material stacks use `domain + family + qualityBand`. World Resources and Creature Materials never merge,
even where an old raw ID matched. Gear does not retain six continuous material bars. Source histories remain
in Bestiary/World History rather than making fungible stacks pretend to share one specimen.

## 2. Quality and performance

| Rank | Band | Base effective power/protection |
|---:|---|---:|
| 0 | Rough | 0 |
| 1 | Standard | 1 |
| 2 | Fine | 2 |
| 3 | Superior | 3 |
| 4 | Exceptional | 4 |
| 5 | Peerless | 5 |

Output rank is `roundHalfUp(0.70 × primary average + 0.30 × secondary average)`. With no secondary socket,
primary owns 100%. Multiple primary sockets split the primary average; multiple secondary sockets split the
secondary average. Quantity does not change 70/30.

Schematic offsets are added after the band: ordinary Blacksmith/Tannery/Bowyer `0`; Weaponsmith physical
weapons `+0.5`; Armoury Rigid `+0.5 protection`, Balanced `0`, Insulated `−0.5 protection` plus its material
ward. These offsets express different construction, not quality caps. All-Peerless valid inputs always make
a Peerless item.

### Named material-effect scale

Input quality affects its named material consequence in three readable magnitudes:

| Input band | magnitude group | major power/protection | minor power/protection | initiative | heat ward | value | Channelworks conduction |
|---|---|---:|---:|---:|---:|---:|---:|
| Rough / Standard | ordinary | +0.25 | +0.10 | +0 | +5 points | +10% | +0.25 |
| Fine / Superior | fine | +0.50 | +0.20 | +1 | +10 points | +20% | +0.50 |
| Exceptional / Peerless | masterwork | +0.75 | +0.30 | +2 | +15 points | +30% | +0.75 |

Rules:

- `Keen` and `Forceful` use major weapon/tool power; `Reinforced` uses major protection.
- `Secure` and `Braced` use the minor value on the relevant power/protection axis.
- `Light` uses initiative; `Insulated` uses heat ward; `Valuable` uses sale value; `Conductive` affects only
  an eligible Channelworks/explicit magical consumer, never an ordinary physical weapon by implication.
- `Heavy` is always `−1 initiative`; improving material quality does not make Adamant or Plate weigh less.
- For each runtime axis, apply only the strongest positive contribution on the item once and the strongest
  penalty once. Two Adamant plates do not double `Reinforced`; the second plate still affects output quality.
- Heat ward from all equipped authored components sums to a 50-point cap. A Pelt grip may therefore ward heat;
  Gold in the same grip instead contributes value/conduction. This is a deliberate visible material choice.
- `Balanced` has no extra runtime number: it contributes its input band to output quality, broad fit,
  ordinary value and its visual treatment. Do not invent a hidden consolation bonus.
- No material adds durability, critical chance, accuracy, random affixes, status chance or repair chores.

## 3. Quality creation and migration tuning

### New world-resource units

Freeze one `qualityScore` when a node is generated:

`round(0.65 × resourceMatch + 0.25 × worldDanger + 0.10 × extractionCapability)`.

- `resourceMatch` is the normalized 0–100 strength already used to select that ResourceID from its
  `requires`/`favours`; freeze it on the node rather than recomputing after balance changes.
- `worldDanger` maps source danger bands 0–5 to `20, 35, 50, 65, 80, 95`.
- `extractionCapability` is `0` without the relevant capability, then `25/50/75/100` at its four authored
  tool/skill steps. A hard capability gate still decides whether Gold/Adamant can be harvested at all.
- Every unit from one pull shares its frozen band. No extra quality RNG occurs at pickup.

### New creature-material units

For each yielded family, `partExpression` is the average of its two relevant frozen morphology capabilities
in the ecology authority. Freeze:

`round(0.75 × partExpression + 0.25 × encounterDanger)`.

Encounter danger uses the same six values above. Quantity remains morphology-derived and deterministic; it
does not improve quality.

`encounterDanger` is the bound world's frozen source Danger band before party-size/level scaling. Adaptive
combat pressure, DEBUG profiles, God mode and later party growth never improve or reroll materials from the
same saved species/world.

### Score → band

| Score | Band |
|---:|---|
| 0–24 | Rough |
| 25–54 | Standard |
| 55–74 | Fine |
| 75–89 | Superior |
| 90–97 | Exceptional |
| 98–100 | Peerless |

Existing exact `MaterialSample.grade` maps through these thresholds once. Existing bulk World Resource units
without individual quality become Standard, count-for-count. Existing gear Tier 1/2/3/4 maps to
Standard/Fine/Superior/Exceptional while preserving exact effective power; paid reforge ranks remain frozen
workmanship credit. Peerless is new. Rough migrated gear is never invented.

## 4. Complete ComponentProfile table — World domain

`world.ore` is stored as Iron Ore but the installed component/preview says **Iron**; the owning maker smelts
it during the quoted craft without creating a second Iron inventory currency.

| Stable family | Legal roles | Named contribution by role | Restriction/trade-off | Visual treatment |
|---|---|---|---|---|
| `world.rubble` | Core, Fitting | Weighted Core | Heavy; Crush/projectile only | irregular grey/brown stone mass |
| `world.clay` | Core | Balanced | fired Sling projectile only; otherwise ingredient/building use | compact fired-earth shot |
| `world.ore` | Core, Body, Grip, Fitting | Balanced | no special bonus | forged blue-grey iron |
| `world.copper` | Core, Body, Grip, Binding, Fitting | Conductive; Braced in Body | no Point/Edge | warm red metal, green wear |
| `world.silver` | Grip, Binding, Fitting | Conductive + Valuable | secondary only | cool pale metal, dark tarnish |
| `world.gold` | Grip, Binding, Fitting | Conductive + Valuable | secondary only; never physical Core | warm gold plate/wire |
| `world.quartz` | Core, Fitting | Keen Point; Conductive Fitting | Point/Fitting only; no Crush/Body | clear pale crystal facets |
| `world.obsidian` | Core | Keen | Point/Edge only | black glass with pale edge |
| `world.salt` | ingredient only | none | no physical gear socket | granular white crystal |
| `world.sulfur` | ingredient only | none | no physical gear socket | yellow volatile mineral |
| `world.mercury` | ingredient only | none | liquid; no physical gear socket | silver liquid/reagent |
| `world.adamant` | Core, Body, Fitting | Forceful Core; Reinforced Body | Heavy | dense dark hex-metal |
| `world.fiber` | Body, Grip, Binding, Lining | Light | no rigid Core | woven cord/cloth |
| `world.timber` | Core, Body, Grip | Light | haft/limb/brace/face only; no Edge | visible grain and wrapped joins |
| `world.pulp` | ingredient only | none | paper/ink/build use; no gear | pressed paper fibre |
| `world.resin` | Binding, Fitting | Secure | joint/adhesive only | amber seam/join |
| `world.toxin` | ingredient only | none | coating/reagent only | dark botanical liquid |
| `world.spore` | ingredient only | none | reagent only | pale clustered dust |
| `world.reagent` | ingredient only | none | chemistry only | mineral/chemical granules |
| `world.ichor` | legacy only | none | new world-node generation retired; never merges with `creature.ichor` | preserved legacy liquid receipt |
| `world.rift_glass` | special recipe only | Conductive where explicitly authored | Waystone/anchor/singular recipes; no ordinary gear socket | fractured prismatic glass |

## 5. Complete ComponentProfile table — Creature domain

| Stable family | Legal roles | Named contribution by role | Restriction/trade-off | Visual treatment |
|---|---|---|---|---|
| `creature.hide` | Body, Grip, Binding, Lining | Balanced | no rigid Point/Edge | smooth leather wrap/panel |
| `creature.pelt` | Body, Grip, Lining | Insulated | no rigid Core | fur edge and soft wrap |
| `creature.down` | Lining | Insulated + Light | lining only | soft clustered underfeather |
| `creature.feather` | Binding, Lining, Fitting | Light | no rigid working Core | layered vane/fletching |
| `creature.fin` | Grip, Binding, Lining | Light | flexible secondary only | ribbed translucent wrap |
| `creature.bone` | Core, Body, Grip, Fitting | Balanced | no flexible Binding/Lining | pale carved structure |
| `creature.scale` | Body, Fitting | Braced + Light | no primary Point/Edge | overlapping small scales |
| `creature.quill` | Core, Body, Fitting | Keen Core; Braced + Light Body | Point/Edge/Body only | long dark tapered quills |
| `creature.fang` | Core, Fitting | Keen | Point only as Core | ivory curved point |
| `creature.claw` | Core, Fitting | Keen | Edge only as Core | hooked dark edge |
| `creature.oil` | ingredient only | none | scent/distillery/chemistry only | translucent fatty vial |
| `creature.plate` | Core, Body | Forceful Core; Reinforced Body | Heavy | broad segmented plate |
| `creature.chitin` | Core, Body, Fitting | Keen Core; Braced + Light Body | Point/Edge/Body only | faceted dark shell |
| `creature.shell` | Core, Body, Fitting | Weighted Core; Reinforced Body | Heavy | curved pale shell sections |
| `creature.tusk` | Core, Fitting | Forceful | Heavy | long dense ivory mass |
| `creature.horn` | Core, Grip, Fitting | Braced | no flexible Binding/Lining | ridged horn laminate |
| `creature.venom` | ingredient only | none | coating/chemistry only | marked sealed vial |
| `creature.ichor` | ingredient only | none | Distillery/Channelworks only when explicitly authored | luminous provenanced liquid |

## 6. Exact reusable socket sets

These aliases are closed lists. Adding a new family never makes it eligible until this authority changes.

- `POINT`: world.ore, world.adamant, world.obsidian, world.quartz, creature.fang, creature.quill,
  creature.bone, creature.tusk, creature.horn.
- `EDGE`: world.ore, world.adamant, world.obsidian, creature.claw, creature.chitin, creature.quill,
  creature.bone, creature.shell.
- `CRUSH_HEAD`: world.rubble, world.ore, world.copper, world.adamant, creature.bone, creature.tusk,
  creature.horn, creature.plate, creature.shell.
- `GRIP`: world.fiber, world.timber, world.copper, world.silver, world.gold, creature.hide,
  creature.pelt, creature.fin, creature.bone, creature.horn.
- `BINDING`: world.fiber, world.resin, world.copper, world.silver, world.gold, creature.hide,
  creature.fin.
- `HAFT`: world.timber, world.ore, world.adamant, creature.bone, creature.horn.
- `FITTING`: world.copper, world.silver, world.gold, world.quartz, world.adamant, creature.bone,
  creature.horn, creature.quill.
- `RIGID_BODY`: world.ore, world.copper, world.adamant, world.timber, creature.bone, creature.hide,
  creature.scale, creature.plate, creature.chitin, creature.shell.
- `HARD_SHELL`: world.ore, world.copper, world.adamant, creature.bone, creature.scale, creature.plate,
  creature.chitin, creature.shell, creature.quill.
- `LINING`: world.fiber, creature.hide, creature.pelt, creature.down, creature.feather, creature.fin.
- `FLEX_BODY`: world.fiber, creature.hide, creature.pelt, creature.fin, creature.scale.
- `FLEX_FACING`: creature.hide, creature.scale, creature.chitin, creature.quill, creature.bone.
- `SOLE`: world.timber, creature.hide, creature.bone, creature.scale, creature.chitin, creature.plate,
  creature.shell.
- `BOW_LIMB`: world.timber, creature.horn, creature.quill, creature.bone.
- `BOW_STRING`: world.fiber, creature.hide, creature.fin.
- `SLING_PROJECTILE`: world.rubble, world.clay, world.ore, world.copper, world.adamant, creature.bone,
  creature.tusk, creature.horn, creature.shell.

## 7. Complete physical schematic socket table

`P` = primary share; `S` = secondary share. Counts are exact units.

| Schematic ID · station | Fixed output | Exact sockets |
|---|---|---|
| `pointed_blade` · Blacksmith | Weapon · Pierce · Close · offset 0 | `point` ×1 P `POINT`; `grip` ×1 S `GRIP` |
| `cutting_blade` · Blacksmith | Weapon · Rend · Close · 0 | `edge` ×1 P `EDGE`; `grip` ×1 S `GRIP` |
| `hand_maul` · Blacksmith | Weapon · Crush · Close · 0 | `head` ×1 P `CRUSH_HEAD`; `haft` ×1 S `HAFT` |
| `long_spear` · Blacksmith | Weapon · Pierce · Mid · 0 | `point` ×1 P `POINT`; `haft` ×1 P `HAFT`; `binding` ×1 S `BINDING` |
| `shield` · Blacksmith | Offhand · 0 | `face` ×1 P `RIGID_BODY`; `brace` ×1 P `HAFT`; `binding` ×1 S `BINDING` |
| `helm` · Blacksmith | Head · 0 | `shell` ×1 P `HARD_SHELL`; `lining` ×1 S `LINING` |
| `rigid_guard` · Blacksmith | Body · 0 | `body` ×2 P `RIGID_BODY`; `binding` ×1 S `BINDING` |
| `field_pick` · Blacksmith | Tool · hard-node harvest · 0 | `pick` ×1 P `POINT` excluding world.quartz; `weight` ×1 P `CRUSH_HEAD`; `haft` ×1 S `HAFT` |
| `supple_coat` · Tannery | Body · 0 | `outer` ×1 P `FLEX_BODY`; `lining` ×1 S `LINING` |
| `working_gloves` · Tannery | Hands · 0 | `hand` ×1 P `FLEX_BODY`; `facing` ×1 S `FLEX_FACING` |
| `working_boots` · Tannery | Feet · 0 | `upper` ×1 P `FLEX_BODY`; `sole` ×1 P `SOLE`; `binding` ×1 S `BINDING` |
| `armoury_rigid_shell` · Armoury | eligible protective slot · +0.5 protection | `body` ×2 P `HARD_SHELL`; `binding` ×1 S `BINDING` |
| `armoury_insulated_layer` · Armoury | eligible protective slot · −0.5 protection | `lining` ×2 P `LINING`; `outer` ×1 S `RIGID_BODY` |
| `armoury_balanced_laminate` · Armoury | eligible protective slot · 0 | `body` ×1 P `RIGID_BODY`; `lining` ×1 P `LINING`; `binding` ×1 S `BINDING`; `fitting` ×1 S `FITTING` |
| `longbow` · Bowyer | Weapon · Pierce · Far · 0 | `limb` ×2 P `BOW_LIMB`; `string` ×1 S `BOW_STRING` |
| `sling` · Bowyer | Weapon · Crush · Far · 0 | `cord` ×1 P `BOW_STRING`; `projectile` ×1 P `SLING_PROJECTILE`; `pouch` ×1 S world.fiber/creature.hide/creature.pelt |
| `throwing_set` · Bowyer | Weapon · Rend · Far · 0 | `edge` ×2 P `EDGE`; `carrier` ×1 S world.fiber/creature.hide/creature.pelt/creature.fin |
| `weaponsmith_fitted_point` · Weaponsmith | Weapon · Pierce · Close · +0.5 | `point` ×1 P `POINT`; `grip` ×1 S `GRIP`; `fitting` ×1 S `FITTING` |
| `weaponsmith_fitted_edge` · Weaponsmith | Weapon · Rend · Close · +0.5 | `edge` ×1 P `EDGE`; `grip` ×1 S `GRIP`; `fitting` ×1 S `FITTING` |
| `weaponsmith_fitted_maul` · Weaponsmith | Weapon · Crush · Close · +0.5 | `head` ×1 P `CRUSH_HEAD`; `brace` ×1 P `HAFT`; `grip` ×1 S `GRIP` |
| `weaponsmith_fitted_polearm` · Weaponsmith | Weapon · selected Pierce/Rend/Crush · Mid · +0.5 | `head` ×1 P exact `POINT`/`EDGE`/`CRUSH_HEAD` list selected before materials; `haft` ×1 P `HAFT`; `binding` ×1 S `BINDING` |

The polearm damage choice is explicit before material selection. A family legal in two head lists does not
silently choose whichever damage performs best. Every preview names the selected triangle corner.

## 8. Pointed Blade reference fixture

This fixture is shared by rules, UI and multipart sprite assembly:

| Field | Exact value |
|---|---|
| Schematic | `pointed_blade` v1 |
| Primary | one `world.adamant`, Peerless, in `point` |
| Secondary | one `creature.pelt`, Fine, in `grip` |
| Quality score | `0.70 × 5 + 0.30 × 2 = 4.10` |
| Output band | Exceptional |
| Base power | 4.0 |
| Material result | Forceful masterwork `+0.75`; Heavy `−1 initiative`; Insulated fine `+10 heat-ward points` |
| Final receipt | power 4.75; initiative −1; heat ward +10; Pierce; Close |
| Player copy | `Exceptional Adamant Pointed Blade · pelt-wrapped` |
| Visual components | dark dense Adamant point; independently coloured/thick Pelt grip; Pointed Blade silhouette unchanged |

Control fixture: Standard `creature.fang` point + Standard `creature.hide` grip produces Standard rank 1,
Keen ordinary `+0.25`, no initiative/ward change, final power 1.25. The two fixtures prove that Schematic,
material and quality remain separate identities.

## 9. Refitting and quote behavior

- Refit replaces exactly one installed socket with one compatible family/band and recalculates output quality
  from the complete frozen component set.
- The preview shows which band may rise or fall, which strongest-once effect changes, appearance, sale value,
  final performance and whether the removed component is recoverable.
- Ordinary removal consumes the old component. A separate authored recovery rule may return it; quality alone
  never guarantees recovery.
- Refitting cannot change slot, damage kind or reach. Weaponsmith Rebuild may change Schematic only through an
  explicitly authored conversion.
- The commit freezes exact reserve IDs/quantities and is atomic. Stale/missing stock produces no mutation.

## 10. Content/implementation gates

Engineering may begin the ordered migration only when validators prove:

1. all 21 physical Schematics appear exactly once and every socket resolves a closed nonempty family list;
2. every eligible family has the socket role and treatment it is asked to render;
3. every current live World Resource/legacy `MaterialKind` has an explicit component, ingredient, special or
   migration-only disposition;
4. no ingredient-only/special/legacy family enters an ordinary physical socket;
5. every output band and 70/30 rounding edge is covered;
6. current Tier/reforge fixtures preserve effective power exactly;
7. Pointed Blade quote/commit/refit/recycle/save round-trip preserves the full receipt;
8. no consumer reads continuous grade/property floors after the final migration checkpoint.

Asset begins multipart gear only after the Pointed Blade rules fixture is source-complete. Its kit must keep
the Schematic silhouette stable while point/grip components change independently, and must demonstrate
Rough→Peerless framing redundantly in colour and shape. No bulk 21-family final-art batch begins from this
document alone.
