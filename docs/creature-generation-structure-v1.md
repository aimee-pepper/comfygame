# Creature generation — modular structure and coverage contract

6 September2026. **Intended structural draft; reference reconciliation and Engineering feasibility review pending. Not a completed generator or delivered runtime/final artwork.** Aimee requires coherent design for every intended family before dependent generation is implemented. This supersedes the proposed quadruped/serpentine-only fauna slice in `generated-3d-life-and-waterfalls-v1.md`. Generic interfaces and independent flora/water work may proceed; family/morphology generation waits for the feasibility review described below.

## 1. Current taxonomy inventory, not the limit of intended granularity

The currently recorded accepted taxonomy is **Sky / Water / Amphibious / Land**, subdivided by **Four-legged / Two-legged / Serpentine / Segmented / Radial / Fish-shaped / Amorphous**. These are seven axial structural families, not Earth animal classes. No separate mammal, bird, reptile or insect roster is invented. The existing eight IdentityRegion values—ambusher, pursuer, tank, grazer, swarmer, apex, drifter, sentinel—are derived role descriptions, not anatomy templates or mandatory species slots. Bestiary is already organized; this contract changes no Library layout.

| Family / bodyPlan | Land weight | Amphibious weight | Water weight | Sky weight | Required base structure |
| --- | ---: | ---: | ---: | ---: | --- |
| Four-legged / quadruped |45|35|0|35| Axial trunk, anterior cranial region, four intrinsic supporting legs |
| Two-legged / biped |15|0|0|20| Upright/leaning axial trunk, anterior cranial region, two intrinsic supporting legs; no unrecorded extra arms |
| Serpentine / serpentine |15|20|25|25| Continuous elongated axial body with anterior cranial region; no intrinsic legs |
| Segmented / segmented |10|15|5|10| Serial connected body sections, anterior cranial region; no automatic legs per segment |
| Radial / radial |7|15|15|5| Central body with radial contour, central cranial/sensory pole; contour lobes are not accessory limbs |
| Fish-shaped / piscine |0|10|45|0| Streamlined axial body, anterior cranial region and continuous tapering rear; no automatic discrete fins |
| Amorphous / amorphous |8|5|10|5| Connected deformable-looking mass with a stable polarity/cranial attachment region; no implied bones or limbs |

The table is the retained accepted habitat/body tuning in `creature-body-habitat-v1.json`, not a new probability promise. Its23 positive cells are the required compatibility coverage; zero cells are deliberate current-policy exclusions, not universal biological impossibility. Every family has a generation route. Not every world must contain each family or habitat. All five cranial values and all five appendage types are covered below; structural support must not stop at the convenient terrestrial rows.

**Current support:** saved trait axes, seven body enums, five cranial enums, appendage type/count, specimen variation, physical habitat components, colour/source custody and actual rewards exist. **Missing runtime integration:** habitat-conditioned body selection, coherent final anatomy receipt, all-family parameterized assembly and sanitized/remembered recipe projection. Earlier reward/food/naming proposal files do not establish this integration. **Excluded concepts:** new feeding/nesting/chemistry, creature fluids or reward families, limb damage, gait-driven gameplay, hunger, swimming for the party, chasm flight, new defense immunities and scripted named-species rosters. Sessile hostile flora belongs to flora; authored special actors/Apex retain their existing distinct generation owners rather than being silently replaced by an ordinary family roll.

## 2. Causal order: pressures to a viable body

Use the existing fixed ordinary ecological budget and costly-axis allocator in Engineering LifeRules/WorldTendencies. Vitality controls cast/population, not free individual power. Flora productivity retains its existing trophic-depth cap; no new food simulation or role quota. A rich world can produce more species, not unlimited size+armour on each species. Keep ordinary count, entry exclusion and contact-reservation owners.

| Resolved source condition | Retained influence before structural filtering | Capability boundary |
| --- | --- | --- |
| Cold lows / hot highs | Existing sequential size, covering, build, reach and colour tendencies under fixed budget | No fat/oil layer, immunity or new part from temperature alone |
| Dim/dark/bright light | Existing sensory allocation, depth/pattern, ornament and appendage tendencies; sourceless-light emanation gate | Sensory allocation does not invent eye count; emanation is not a new world illumination rule |
| Wetness / actual water | Existing darkening; actual standing/flowing contribution biases sinuous/finned forms | Physical unfrozen liquid/component remains mandatory for Water/Amphibious; rain or ice cannot supply it |
| Mineral/volatile substrate | Existing hardness/bone allocation, finish and allowed emanation | Numeric hardness does not invent a Shell, horn or metal plate anatomy |
| Open/closed relief | Existing build/covering/armament/crypsis tendencies | No new flight or passability permission |
| Atmospheric motion/vertical relief | Existing aerial habitat weight; density retains current allocation effect | A Sky candidate still needs its permitted component and at least two wings |
| Vitality/trophic depth/cycle | Existing count, bounded allocation weighting and cast-draw variation | No automatic grazer, Apex, new predator/prey system or per-turn mutation |

No copy of the pressure constants is forked into the renderer. `LifeRules` remains the single pressure/budget owner; the structural policy filters its tendencies into legal combinations. Names are interpreted after final structure, never selected first and used to force traits.

Ordered generation for each ordinary species:

1. Resolve physical terrain/liquid and legal habitat components before selecting habitat. Retain minimum2 connected tiles, stable row-major component ID, entry/contact eligibility and65% requested-slot reservation from the accepted body/habitat contract. If no eligible component exists, skip the ordinary placement/species according to its existing owner; never invent dry land or a contact bridge.
2. Retain habitat weights: Land20+0.8×(100−waterFraction); Amphibious0.6×shoreFraction+0.25×liquidHydrology; Water0.8×waterFraction+0.3×liquidHydrology; Sky0.35×verticality+0.35×motion. Fractions come from certified physical sets, and liquidHydrology uses the actual standing/flowing share. Mask unavailable habitats first; retain repeat multiplier0.65 and first-species contact rule. If all valid weights are finite zero, choose uniformly among eligible habitats in canonical order. Invalid/nonfinite/negative data is an authoring error, not a random fallback.
3. Allocate the existing costly/free traits without replacing gameplay RNG or budget. Select habitat with the separate versioned ecology stream, then body from its exact positive table row. Body receives the pressure effect through habitat; do not invent another direct heat→mammal or stone→insect rule.
4. Multiply existing pressure-derived appendage weights by the habitat row below. Apply the shore-piscine forced limbs rule before selection. A finite all-zero transformed vector uses that habitat multiplier row as its fallback weights, after identical compatibility filtering. Body-row invalidity is an error; never reroll habitats until a pretty body fits.
5. Finalize appendage count, cranial feature, structural anchors and source exterior fields. Apply the accepted cold-water correction here for the new coherent-generation policy: retain only its count bias for validated Shore/Aquatic components; preserve all other ordinary variation. Capture original count jitter rather than drawing again. No retroactive change to old policies. The exact formula/rounding in `creature-cold-water-appendages-v1.md` is incorporated; its old “not current fresh-start” instruction remains true for ordinary332 campaigns and does not forbid the new explicitly versioned generation scope.
6. Freeze the final species body/anatomy and version before names, material projection and specimens. Remove the later visual-hash overwrite for this new policy. Interpret supported role/name from final facts using the retained role-coherence gates; fallback to a truthful physical description. Preserve IDs/compatibility keys independently of display names.
7. Apply existing specimen variation once at spawn (actual saved colour, size and finish). Derive dimensions from the saved specimen value; do not add another visual size jitter. Structure, appendage count and habitat remain species-stable. Freeze appearance recipe at creation; render from it without RNG.

This order keeps existing budget/traits/placement connected; it is not two independent “generate a creature” and “choose a mesh” systems.

## 3. Complete appendage and cranial compatibility

| Habitat | none | membrane | feathered | finned | limbed | Hard condition |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Land |1|1|1|0|1| Wings may exist but do not make this a Sky animal |
| Amphibious |0.75|0.5|0.5|2|1.5| Fish-shaped requires limbed, count≥2 |
| Water |1.5|0|0|5|0.5| Axial swimming form may have no discrete fins |
| Sky |0|1|1|0|0| Membrane or feathered wings, count≥2 |

All positive types fit every body permitted in that habitat, except the explicit shore-piscine override. Sockets are generated parametrically from the body’s attachment zones; lack of a handmade mesh is not a biological incompatibility. No body is silently excluded because only a fixed pair of wing sockets was authored.

- `none` means0 accessory appendages. It does not remove the quadruped’s four or biped’s two intrinsic support legs.
- Other types have1–8; Sky wings and Amphibious piscine limbs have2–8. Preserve the sampled count with the accepted conditional correction/minimum, no count reroll. Odd counts are valid: floor(n/2) left/right pairs plus one midline attachment. Do not round to an even number or require Earth-animal proportions.
- Membrane/feathered attachments are continuous wing-like structures matching the actual type; individual decorative feathers/struts are not counted body parts. Finned means discrete fin-like accessories only where permitted. Limbed means distinct accessory/support appendages from the recorded count, in addition to intrinsic legs where present.
- For axial bodies, distribute paired slots along the trunk from anterior to posterior; odd slot on the dorsal midline. For radial bodies use evenly ordered sectors around the central body; for amorphous bodies use stable ordered surface zones around its polarity axis. Define a disjoint contact region for each attachment; no disconnected or inverted mesh. Support legs are separate sockets and cannot be consumed by accessory placement.
- Every base has one explicit cranial attachment region: anterior for axial forms, central pole for radial, stable polarity surface for amorphous. `none` adds no feature; `longEars` adds two ear-like forms; `horns` adds a paired cranial projection; `crest` adds one continuous ridge; `sensoryFan` adds one fan-like structure. These exact counts are **new Design first-pass visual topology**, not recoverable horn/ear quantities or an assertion of hearing organs. Use the actual cranial field, never armament or sensory numbers as a substitute.
- Cranial/accessory parts join the designated surface and share its deformation frame. Any narrow mouth/eye/teeth/claw detail without an explicit source owner is omitted from the first structural assembly. Unknown appearance is represented abstractly instead of manufacturing precise anatomy. Existing combat remains valid without drawing an invented weapon.

## 4. Dimensions, proportion and meaningful variation

**New Design first-pass display tuning, not new game statistics.** Let s=size/100 and b=build/100 after validating finite0–100 source values. Tile units are display units, not metres. Common length scale L=0.45+0.90s and breadth factor B=0.65+0.70b. Intrinsic core ranges below use the same inputs for all specimens; save the recipe version. Do not add random scaling at mount time.

| Family | Base envelope/proportions | Within-family structural variation |
| --- | --- | --- |
| Quadruped | lengthL, width0.45LB, shoulder height0.55L;4 legs | Build changes trunk breadth; saved size changes whole animal; stable trunk/head ratio0.18–0.28 ofL |
| Biped | height1.25L, width0.42LB, depth0.38L;2 legs | Stable torso lean0–15 degrees and head ratio0.18–0.25; breadth follows build |
| Serpentine | centerline length1.7L, diameter0.18LB | Stable3–5 control-point curve; radius/curvature varies within compact envelope, no extra vertebral claims |
| Segmented | length1.25L, width0.38LB;3–7 connected visible sections | Stable section count/proportion recipe; section repetition does not create legs or material portions |
| Radial | core diameter0.80LB, height0.30L;3–7 contour lobes | Stable rotational contour/lobe pattern, separate from counted accessory appendages |
| Piscine | length1.25L, width0.32LB, height0.45L | Stable taper ratio and body depth, no added tail-fin source; shore limbs remain recorded |
| Amorphous | core diameter0.80LB, height0.45L;single connected mass | Stable3–6 surface bulges within envelope; no per-frame biological remeshing |

Structural variations in the third column use the species-only presentation stream, stable order and bounded ranges. They are real shape variety within each existing family, not a named species prefab. Use actual covering length/coverage/hardness as bounded exterior thickness/distribution, without assigning a material family that the source projection does not support. Plain smooth/rough exterior volume covers unsupported texture semantics. Colour/Pattern and finish provide independent saved variation, not a substitute for body shape differences.

Head/features remain inside the declared component bounds. Intrinsic legs join the core and reach the resting plane. Wings/fins/limbs use base-normalized span0.25L–0.65L each, driven by their recipe’s shared bounded proportion; exact count is preserved. Cap assembled horizontal radius at1.5 tiles by a single uniform display scale of the entire assembly if necessary, keeping all proportions/counts. This is a visibility bound, not extra occupied cells or a size-stat change. Asset may refine shapes within these declared semantics after the interface exists; changing these ranges requires a versioned recipe, not reinterpreting a saved world.

All bodies remain attached to one existing logical position/occupied footprint. Ground stance uses actual support; allowed aquatic/aerial presentation uses its saved movement owner, not new flight physics or depth guesses. Unsupported measured swimming height uses the existing marker placement, not a invented bed offset. Facing may follow actual movement vector without changing the frozen body; idle pose changes are presentation only. No locomotion animation is required for structural readiness.

## 5. Stable source, rendering and compatibility contract

A generated structural recipe contains version, source world/species/instance IDs, explicit body/habitat policy, base family, intrinsic topology, accessory type/count/ordered anchors, cranial feature, normalized dimensions, bounded variation seed/results, source material channels and appearance status. Engineering owns exact types. Components declare unit axes, pivot/contact region, socket role/transform/capacity, valid scale range, material slots and maximum bounds; no raw renderer access to hidden traits.

The world transaction freezes source structure before material rewards/names. Species-level recipe plus actual saved specimen overrides avoids duplicating complete meshes. Same source+versions always gives the same structure across scene ordering, reopen and visibility changes; presentation RNG never advances gameplay RNG. Unsupported legacy/default anatomy keeps a neutral marker without relabeling it as a new valid family. All23 legal new-policy pairs must have a parameterized structural path; a missing final-art part may use a labelled functional component, not an unimplemented-family fallback presented as completion.

Renderer input remains the sanitized snapshot in `generated-3d-life-and-waterfalls-v1.md`: full-current living actors only, last-observed stationary flora/water only, no hidden anatomy, no remembered moving animals, no loot/encounter/Bestiary grant. Reuse canonical source CMY+Depth and stable Pattern/finish. Morphology is not a new reason to change harvested colours, material quality, reward count, combat or source IDs.

## 6. Required representative cases and counterexamples

These are a finite Design coverage set for existing tests and Engineering review, not a new framework or corpus:

1. All7 body rows have at least one positive habitat route and a complete base/attachment structure. Every one of23 positive habitat/body cells and each compatible appendage type can produce a connected bounded recipe; all zero cells are rejected. Tests may enumerate these finite rules without generating worlds or benchmarking seeds.
2. Land quadruped+none has4 intrinsic legs and0 accessories. Land biped+limbed3 has2 intrinsic legs and3 accessories. No phantom fourth accessory or loss of support legs.
3. Sky serpentine+membrane3 has3 wings and remains Sky; Water serpent+none swims with no discrete fins. Fish-shaped Sky and aquatic biped are rejected under this matrix.
4. Amphibious piscine+finned is rejected/filtered before draw; limbed2 passes with a real liquid/bank component. Dry rain-only or frozen-water “amphibious” components fail without manufacturing a habitat.
5. Segmented, radial and amorphous support accessory counts1 and8 plus all five cranial choices. Section/lobe/bulge counts never become loot counts or extra limb facts.
6. Dark dry world may influence appendages/senses; it does not gain the cold-water bias. Shore/Aquatic at lawful unfrozen floor25 may retain0.2 cold bias; no new liquid at floor0. Preserve original count jitter and one rounding.
7. Finite zero appendage weights use the declared compatible fallback; negative/nonfinite data rejects. No candidate habitat gives no forced terrestrial creature. No impossible morphology is repaired by moving its habitat after material projection.
8. Two species with the same habitat/body but different actual build/covering/size produce meaningful distinct proportions within bounds. Same species across specimens keeps family/parts and uses only its existing saved variation. Reopen repeats exactly; changing camera/disclosure consumes no RNG.
9. A low-armament creature does not become a grazer; a role-fit “apex” does not become actual Apex; a finned shape does not gain party water access. Crypsis and remembered-only actors stay hidden.
10. Actual source colour/Pattern remains consistent through the permitted visual recipe and existing harvested material owner; a displayed wing/horn does not mint an unimplemented material reward.

## 7. Functional completion and dependency order

**Design structural completion means:** the inventory above accounts for every intended family, all legal/illegal habitat-body combinations, all existing appendage/head cases, pressure→eligibility order, deterministic fallback, intrinsic versus accessory topology, dimensions/variation, source identity/disclosure and explicit unsupported legacy cases. No remaining family rule is delegated to an artist’s guess or an inferred loot table. This draft supplies those rules for the currently recorded inventory; its new topology/dimension details are Design-authored first-pass tuning, not individual decisions attributed to Aimee. Aimee has explicitly reaffirmed her Dragon DNA game as the granular inspiration/base. Its exact reference was not found in the bounded handoff/docs search; Design has asked her once for its location. Reconcile its intended independently varying features before freezing completeness. Seven axial forms and23 habitat pairs are not proof that all intended morphology is represented, and fixed cranial counts/proportions below remain revisable rather than replacing that reference.

**Engineering feasibility review before family generation:** confirm the single generation owner can preserve count jitter/policy order, represent all23 pairs/five cranial values/count0–8 with the proposed generic anchors, freeze source/recipe versions before material projection, and sanitize current/remembered representations. Resolve any concrete incompatibility by editing this same contract, not by implementing only easy families. Reference alignment and this feasibility review are the remaining readiness dependencies; no new recipe-by-recipe or family-by-family approval questionnaire is needed. Final art completeness and wider feeding/loot design are separate, not reasons to claim the structural generator complete early.

Functional implementation order: (1) stable recipe/socket/material/disclosure schema, no species-specific decisions; (2) reviewed pressure/habitat/body/appendage/count finalization and exact family coverage; (3) source/name/material consistency and frozen specimen/recipe persistence; (4) all-family functional assembly in the existing Settings3D consumer; (5) Asset replaces named functional components once Engineering names dimensions/format/consumer/state protocol. Runtime integration may be committed incrementally but cannot be advertised as complete on two representative families. The existing opening, ordinary world quotas and saved campaigns remain intact.

Only after those dependencies and bounded rules/native checks pass can the team call the **complete structural generator** functional. That statement still does not claim full ecology, final art, all animation, natural prevalence, performance acceptance or Aimee play acceptance. No broad native audit is assigned to Design.
