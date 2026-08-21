# Creature ecology and material assets — production packet

**Status:** Game Design production brief; do not begin until the orchestrator explicitly schedules this
checkpoint after the current atmosphere review. This packet removes visual discretion that would change
game semantics; Aimee still accepts or rejects the resulting art.
**Scope:** generated ordinary-creature identity across world/encounter/Bestiary plus the 18 Creature-material
inventory identities. No native integration, ecology rules or combat tuning are part of the Asset task.
**Updated:** 21 August 2026

Machine proof authority and freshness gate:
`creature-ecology-asset-fixtures.json` and
`python3 scripts/validate_creature_ecology_asset_fixtures.py`.

## Authorities Asset must consume

In descending order:

1. `creature-ecology-asset-fixtures.json` — exact proof descriptors, profiles, material IDs and expected
   projection sets;
2. `creature-habitat-authority.json` — four habitats, body-plan and appendage constraints;
3. `creature-material-projection-authority.json` — exact 18 families and morphology-to-material rules;
4. `creature-ecology-and-materials-overhaul-current.md` — player promise, disclosure and presentation;
5. `asset-production-output-contract-current.md` — actual lossless pixel deliverables;
6. accepted creature camera/stage dispositions in `asset-system-proposal.md`.

Asset may report a contradiction but may not resolve one by inventing a fifth habitat, another body part,
an Earth-species catalogue or a new gameplay stat.

## Exact output boundary

The first checkpoint produces only:

- seven reference species, each as one 16×16 straight-top-down world sprite and one 48×48 shallow-side
  encounter/detail sprite;
- one integrated world fixture using at least four of those species in their legal habitats;
- one quiet encounter-stage fixture proving the same identities at 48×48;
- eighteen separate 32×32 transparent Creature-material sprites;
- a quality-frame kit for Rough/Standard/Fine/Superior/Exceptional/Peerless that surrounds but never redraws
  those material sprites;
- native-scale, 400%-nearest-neighbour, literal-grayscale and collision/disclosure evidence.

No portrait, splash, combat animation, attack effect, blood, corpse, food, meat, building, territory-find,
final Bestiary layout or native Swift implementation belongs in this checkpoint.

## Cameras and dimensions

| Consumer | Logical output | Camera | Required read |
|---|---:|---|---|
| Explorable world | 16×16 RGBA | straight top-down | body mass, axial plan, dominant appendage and head feature |
| Encounter/detail | 48×48 RGBA | accepted shallow-side combat view | same body/head/appendage/covering identity with more structure |
| Creature material | 32×32 RGBA | object icon, no scene camera | the actual physical family without relying on text or frame colour |

The 48px sprite is not an enlarged 16px sprite, but it also is not a redesign. Species seed and frozen
morphology remain identical. A piscine body cannot become a generic quadruped in combat; a horned silhouette
cannot lose its horns; a membrane flier cannot acquire feathers merely because they read better.

## Seven closed reference identities

These are proof fixtures, not named Earth species and not a new authored bestiary. Asset renders the stated
facts and nothing more.

| Fixture ID | Habitat / body | Required visible structure | Required projected-material read |
|---|---|---|---|
| `ecology.furred_hunter` | terrestrial quadruped; limbed; no special head | low long-backed mass, four grounded limbs, visibly long/dense soft covering, strong jaw and foreclaws | Pelt, Claw, Bone |
| `ecology.plated_crawler` | terrestrial segmented; eight limbs; sensory fan | repeated axial cases, many short lateral limbs, hard overlapping case, blunt crushing mouthpart | Chitin, Tusk, Bone |
| `ecology.shore_runner` | shore quadruped; four finned appendages; long ears prohibited | compact amphibious mass, four splayed lateral fins, unmistakable tail/dorsal plane, soft continuous covering | Hide, Fin, Bone |
| `ecology.deepwater_biter` | aquatic piscine; finned; crest | continuous fish-like spindle, tail plane, paired fins, visible scaled body and piercing mouth | Scale, Fin, Fang, Bone, Oil |
| `ecology.feathered_glider` | aerial biped; feathered; crest | compact central body, paired feather fans with individual vane rhythm, two legs, crest | Feather, Down, Claw, Bone |
| `ecology.membrane_serpent` | aerial serpentine; membrane; sensory fan | long curved axial body, two broad taut membranes with visible supports, fan-shaped head feature | Hide, Fang, Bone |
| `ecology.tide_shell` | shore radial; no locomotor limb requirement; toxic and emanating | radial body with rigid shell sectors, asymmetric opening/tendrils, a contained internal emanation aperture | Shell, Venom, Ichor, Bone |

“Required projected-material read” means the anatomy plausibly owns those results. It does **not** mean
placing material icons, labels, loot badges or colored outlines on the creature. Exact material availability
is disclosed by combat/Bestiary rules, not by Asset decoration.

At least the following silhouette differences must survive literal grayscale and removal of labels:

- quadruped versus segmented versus piscine versus biped versus serpentine versus radial;
- feathered versus membrane versus finned appendages;
- soft long covering versus hard segmented case versus scales versus shell sectors;
- crest versus sensory fan versus no cranial feature.

Colour, patterning, shine and schiller support these reads but cannot be their only evidence.

### Frozen proof vectors

The sole machine source for these exact normalized inputs is
`creature-ecology-asset-fixtures.json`. The table below is its human-readable review mirror, not a second
editable fixture catalogue. They are fixed review fixtures, not a replacement for pressure-driven live
generation. Armament columns are Pierce/Crush/Rend; finish columns are Opacity/Shine/Schiller and sum to 100;
colour columns are Cyan/Magenta/Yellow, followed by Depth/Patterning.

| Fixture | Size | Cover H/L/C | Bone | Body / head | Appendages | Armament P/C/R | Ornament | CMY · depth/pattern | Finish O/S/Sch | Toxic | Emanation |
|---|---:|---|---:|---|---|---|---:|---|---|---|---|
| `furred_hunter` | 72 | 18/75/85 | 60 | quadruped / none | 4 limbed | 10/8/55 | 20 | 20/30/50 · 55/20 | 90/8/2 | no | none |
| `plated_crawler` | 60 | 80/15/90 | 75 | segmented / sensoryFan | 8 limbed | 10/55/15 | 15 | 45/20/35 · 65/40 | 35/10/55 | no | none |
| `shore_runner` | 45 | 15/35/70 | 40 | quadruped / none | 4 finned | 8/7/12 | 12 | 55/20/25 · 40/30 | 80/15/5 | no | none |
| `deepwater_biter` | 55 | 40/75/70 | 55 | piscine / crest | 4 finned | 55/10/10 | 18 | 60/15/25 · 55/45 | 55/30/15 | no | none |
| `feathered_glider` | 35 | 25/65/80 | 35 | biped / crest | 4 feathered | 10/5/45 | 45 | 15/45/40 · 45/65 | 30/25/45 | no | none |
| `membrane_serpent` | 50 | 20/20/65 | 30 | serpentine / sensoryFan | 2 membrane | 50/5/10 | 25 | 50/35/15 · 60/35 | 75/20/5 | no | none |
| `tide_shell` | 65 | 75/10/90 | 40 | radial / none | 0 none | 5/10/5 | 70 | 25/55/20 · 55/80 | 40/30/30 | yes | caustic 70 |

All unspecified values use the current neutral fixture defaults and must be written explicitly into the
Asset manifest before export. The material-projection validator or a proof adapter must assert the exact
expected family sets from the prior table; Asset may not manually label a sprite with a family its vector
does not produce.

## Habitat composition proof

Use one deterministic 15×15 top-down map fixture containing ordinary ground, a connected shoreline union,
connected shallow+deep water and an open aerial-eligible region. Place:

- `furred_hunter` and `plated_crawler` only on legal terrestrial ground;
- `shore_runner` and `tide_shell` only in the legal shore union;
- `deepwater_biter` in both shallow and deep parts of one connected water component;
- the two aerial fixtures only on current passable non-chasm/non-deep-water cells.

The proof must include at least one deep-water fish that is visible but not falsely reachable and at least
65% of ordinary enemy placements on player-contact-eligible components. Route, party, portal, flora,
resources and sites retain their accepted ownership and cannot be displaced to make creatures clearer.
Minimap keeps the generic disclosed encounter marker; it does not receive species portraits.

## Creature-material atlas

Every family is a separate stable sprite. These physical reads are mandatory:

| Stable family | 32px object identity | Must not collapse into |
|---|---|---|
| Hide | irregular folded skin sheet with one raw uneven edge | Pelt, generic cloth |
| Pelt | folded skin whose long fur fringe owns the outer contour | Hide, Down |
| Down | small soft clustered under-feather tufts | wool ball, Snow |
| Feather | one strong shaft with paired vane silhouette | Quill, leaf |
| Fin | fan-shaped tissue with visible radial supports | Feather, leaf |
| Bone | dense structural piece with expanded joint end | Fang, horn |
| Scale | three or more thin overlapping scales | Plate, coins |
| Quill | bundle of long straight/tapered defensive shafts | Feather, arrows |
| Fang | short curved tooth with broad root and sharp inner curve | Claw, tusk |
| Claw | hooked talon with attached base/sheath | Fang, horn |
| Oil | flattened translucent tissue sac with one broad glossy pool/read | water drop, Venom |
| Plate | one broad thick dermal armour slab with layered edge | Scale, metal ingot |
| Chitin | articulated segmented case fragment with joint seam | Plate, Shell |
| Shell | curved/radial rigid case fragment with concentric growth structure | Chitin, ordinary stone |
| Tusk | long heavy curved tooth with blunt broad root | Fang, Horn |
| Horn | ridged/concentric keratin cone with open cut base | Tusk, Quill |
| Venom | narrow biological gland/sac with a pinched outlet | Oil, potion bottle |
| Ichor | sealed reactive globule/sample with contained emanation rings | Venom, Raw Essence |

The atlas uses material bodies rather than eighteen unrelated UI glyphs. Containers are permitted only as
minor preservation structure for unstable liquids; Venom may not become a conventional potion bottle and
Ichor may not copy the Raw Essence sprite.

## Six-band quality treatment

Quality changes the surrounding inventory frame and stack label, not the physical family sprite:

| Band | Name | Colour convention |
|---:|---|---|
| 0 | Rough | grey |
| 1 | Standard | white/neutral |
| 2 | Fine | green |
| 3 | Superior | blue |
| 4 | Exceptional | purple |
| 5 | Peerless | orange |

One Scale sprite must remain recognizably Scale at every band. Do not add more spikes, a larger horn, extra
shine or a different silhouette to imply quality; that would falsely change the source anatomy. Provide a
literal-grayscale frame sheet as collision evidence, but colour remains the familiar player-facing quality
convention. Stack count appears as game-owned `×N` text outside the bitmap.

## Disclosure and semantic limits

- Ordinary world and encounter sprites expose visible body structure, not hidden numeric traits.
- No eye/sense/defence/status/material badges are baked into sprites.
- Bestiary may show discovered likely material families only after rules supply that knowledge.
- A creature behind fog is not rendered to an offscreen/hidden buffer that can affect adjacency, palette or
  boundary pixels.
- Deep-water placement does not imply fishing, adjacent combat or item recovery.
- Creature materials never appear in the World-resource atlas or consume item slots.
- Territory-find gear/keys/consumables are presented separately as **Found nearby** and never fused into a
  body-part sprite.

## Production output contract

Each sprite requires:

- an individual lossless sRGB RGBA PNG at exact logical dimensions;
- integer-command or exact logical-bitmap production source, binary or intentionally bounded alpha as the
  object requires, and nearest-neighbour display;
- stable visual key, schema/profile version, pivot and opaque bounding box;
- decoded-pixel hash, source hash and generator/exporter hash;
- no CSS/div pseudo-art, antialiased browser shape, screenshot crop as production source or upscaled AI
  image masquerading as logical pixel art;
- a `productionSource` receipt that distinguishes composition reference from shippable logical bitmap;
- `integrationReady: false` until Game Design and Aimee visually accept the exact candidate.

## Review evidence

Return one consolidated review packet, not a stream of per-sprite approvals:

1. all seven species at native 16px and 48px, color and literal grayscale;
2. 400% nearest-neighbour label-free crops;
3. the integrated habitat map in color/grayscale with legal-component overlay in a separate diagnostic copy;
4. the quiet encounter stage with the same seven identities across no more than two fixtures;
5. all 18 material sprites at native 32px in a six-across grid and at 400%;
6. the four hardest collision groups in color/grayscale: Feather/Down/Quill, Scale/Plate/Chitin/Shell,
   Fang/Claw/Tusk/Horn and Oil/Venom/Ichor;
7. one material across all six quality frames and all 18 at Standard;
8. an ordinary 368×800 loot/Storehouse mock composition using six icons across without list rows;
9. manifest plus deterministic, dimensions, alpha, bounds and input-order tests.

## Acceptance gates

The checkpoint is rejected if any of these are false:

1. Each species reads as the same individual identity in both camera profiles.
2. All explorable-map sprites are straight top-down and all encounter/detail sprites use the accepted
   shallow-side camera consistently.
3. Habitat placement is truthful, including shallow+deep aquatic continuity and inaccessible deep fauna.
4. The seven required body/appendage/covering differences survive literal grayscale at native scale.
5. Every one of the 18 material families is recognizable without its label and the named collision groups
   remain separable.
6. Quality frames do not mutate material identity or pretend that quality substitutes for family.
7. No hidden mechanic, remote content, material drop or minimap species identity leaks through the art.
8. Repeated export is byte-identical and every product is a real logical pixel asset in the required format.

Native promotion is a later Engineering checkpoint after the ecology/material schemas are live. Acceptance
of this packet authorizes freezing Asset outputs; it does not authorize Asset to edit game code.
