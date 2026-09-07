# Creature generation — modular structure and coverage contract

6 September2026. **Intended structural draft; Dragon DNA reference reconciliation complete, Engineering feasibility review pending. Not a completed generator or delivered runtime/final artwork.** Aimee requires coherent design for every intended family before dependent generation is implemented. This supersedes the proposed quadruped/serpentine-only fauna slice in `generated-3d-life-and-waterfalls-v1.md`. Generic interfaces and independent flora/water work may proceed; family/morphology generation waits for the feasibility review described below.

## 1. Dragon DNA reference and scope correction

Reference inspected: Aimee’s `https://github.com/aimee-pepper/dragon_game` commit `dff9a9a00d3862b55829d46e6be7efc0f5861094`, especially `js/gene-config.js`, `js/phenotype-resolver.js`, `js/sprite-config.js` and `GENETICS.md`. The executable gene definitions establish23 genes grouped into independent body/frame, horns, spines, tail and triangle systems; some overview prose is older than executable finish names. This is Bookbinder’s modular inspiration, not authorization to transplant breeding, Mendelian inheritance, lethal alleles, elemental types, stat bonuses or Dragon’s exact colour conversion.

**Important correction:** Bookbinder’s old single `appendages.type/count` and exclusive `cranialFeature` cannot express the reference’s independent wings+limbs+horns+spines+tail. The earlier seven-form/23-habitat-pair inventory describes current accepted classification, not complete intended morphology. It must not become a cap or a finished-species asset list. All dependent creature generation remains gated on Engineering review of the independent structure below.

| Dragon DNA system | Bookbinder retained basis | Required modular extension / boundary |
| --- | --- | --- |
| Size, body type, scales | Existing size/build/covering axes and fixed budget | Vary proportions and exterior independently; no whole-species prefab |
| Independent wing and limb counts | Actual habitat, body layout and movement owner | Separate locomotor limbs, wings and fins; groups coexist and have separate counts |
| Bone density | Existing source bone axis and rewards | No visible cavity or new flight-weight threshold inferred |
| Horn style + direction | Explicit cranial features | Separate horn subsystem from ears/crest/fan and axial spines; source-owned style/direction |
| Spine style + height | Existing covering plus explicit generated structure | Store ridge/spike/sail form and extent; no spines inferred solely from high damage |
| Tail shape + length | Existing axial body layout | Independent supported tail proportions, not just scaling the entire animal |
| CMY colour / finish triangles | Bookbinder CMY+Depth+Pattern and finish owners | Stable component channels, canonical Bookbinder conversion; do not replace with Dragon’s discrete0–3 pigment math |
| Breath shape/range/element | Bookbinder armament reach/delivery and actual emanation | Preserve existing effects; no new fire/ice/lightning system or mouth/teeth inferred from damage |

Aimee also explicitly requests analogous relevant modularity for flora; see `flora-generation-structure-v1.md`. Final pixels/meshes follow source structure, not the other way around.

## 2. Complete structural inventory and classification

Keep Sky, Water, Amphibious and Land as habitat chapters. For generation, separate **axial layout** from **locomotor limb count**: an axial trunk is not intrinsically a four-legged finished body. The old quadruped/biped rows collapse into one axial selection row, with their ordinary leg preferences retained below. The other five layouts remain elongated/serpentine, segmented, radial, piscine and amorphous. These six layout families cover every old body form while permitting independently varied limbs and wings.

| Structural layout | Land base weight | Amphibious | Water | Sky | Core anatomy and limb constraint |
| --- | ---: | ---: | ---: | ---: | --- |
| Axial trunk |60|35|0|55| Trunk plus anterior cranial region;2–8 locomotor limbs |
| Elongated / serpentine |15|20|25|25| Continuous elongated body;0 locomotor limbs; wings/fins independent |
| Segmented |10|15|5|10| Serial connected core;0–8 locomotor limbs, no automatic legs per section |
| Radial |7|15|15|5| Central body/pole;0–8 radial locomotor limbs, contour lobes separate |
| Piscine |0|10|45|0| Streamlined body and taper;0–8 locomotor limbs in Water,2–8 on Amphibious bank |
| Amorphous |8|5|10|5| One connected mass/polarity region;0–8 explicit locomotor extensions, no inferred skeleton |

These weights retain the old habitat/body totals; separating independent limbs is **new Design first-pass intended behavior**, not old implementation. Each positive cell requires a full structural path. Do not call a legal species unsupported because only a few artist parts exist. Functional parameterized components may fill a missing art slot honestly, labelled non-final.

**Proposed classification extension required by the reference:** keep existing shape labels when accurate; add **Many-legged** for axial animals with3 or5–8 locomotor limbs. Exactly2 and4 remain Two-legged/Four-legged. Elongated, Segmented, Radial, Fish-shaped and Amorphous retain their structural labels; wings/fins do not replace them. This adds one warranted subgroup rather than mislabeling a six-legged animal Four-legged or inventing an Earth taxonomic catalogue. Preserve existing saved classifications; generated new-policy structure owns its new truthful grouping. The seven legacy labels and23 compatibility pairs are historical coverage, not a combinatorial maximum.

The eight IdentityRegion roles remain post-generation descriptions, not families: ambusher, pursuer, tank, grazer, swarmer, apex, drifter, sentinel. Existing role-coherence gates apply. No plant-feeding profile means no Grazer label; an ordinary role fit never becomes actual Apex. Sessile hostile flora and authored special actors retain their distinct owners.

## 3. Pressure, capability and deterministic selection

Retain `LifeRules/WorldTendencies` as the single current pressure/fixed-budget owner. Vitality changes cast/population, not free individual power; flora productivity keeps its current trophic-depth cap. Keep thermal, light, substrate, relief, atmosphere, cycle, sensory, covering, armament, ornament and emanation effects under that budget. Cold/hardness/damage do not themselves grant fur/fat/horns/teeth or an ability. Names come after final anatomy. No food/chemistry/late-shop redesign is included.

Order for the new version:

1. Resolve physical liquid/terrain, eligible habitat components and ordinary population/placement requirements. Reuse accepted habitat weights and65% requested-slot contact reservation; no component means no forced animal. Land20+0.8×(100−waterFraction), Amphibious0.6×shoreFraction+0.25×liquidHydrology, Water0.8×waterFraction+0.3×liquidHydrology, Sky0.35×verticality+0.35×motion; repeat multiplier0.65. Fractions use certified physical tiles, never colours or pressure alone.
2. Sample current costly/free axes and supported habitat, then structural layout under the table. Use stable separate ecology/structure streams and explicit ordered keys. New policy changes are versioned; old policies retain their exact RNG order and saved forms.
3. Independently resolve locomotor limbs, wings, fins, horns, axial spines and tail through their own role-keyed stream. Mask impossible choices before drawing. Count jitter occurs once only after that group’s final non-none type is selected. **Engineering correction:** do not try to reconstruct jitter discarded by legacy `applyFreeAxes` or preserve its original none/non-none branch in a different new-policy type. Each new group owns its one conditional count draw; no hidden reroll. Generic interfaces may precede this new selection logic, but old single-appendage code is not the new anatomy owner.
4. Reuse existing free-axis tendency/pressure weights where semantically applicable: wing type uses membrane/feathered weights; fins use finned tendency only in lawful water-connected habitats; locomotor count uses ordinary count tendency with habitat/layout minima. Darkness contribution remains; the cold-water contribution applies only to lawful Amphibious/Water fins or limb counts, never to Sky wings or dry-land structures. Use the existing unrounded cold formula before one rounding; no frozen habitat is created to realize a bias.
5. Freeze complete explicit structure before source-material projection, names, specimens and appearance recipes. A later visual hash may not overwrite it. Keep the ordinary cost budget and combat owners; adding decorative or multiple structural groups does not multiply statistics, rewards or occupied cells.
6. Sample ordinary specimen variation once using the current saved colour/size/finish rules. Family and part-group counts remain species-stable. Appearance consumes actual specimen values without a second size or colour jitter. A world-writing transaction freezes versioned recipe/component decisions; lazy mesh construction later is pure reconstruction.

Finite all-zero weights fall back uniformly among already legal candidates (or the retained compatible base weights where listed). Negative/nonfinite/missing required data is an authoring error, not permission to bypass capability gates. If no legal candidate exists, report the generation inconsistency before admission; do not move a completed animal into a new habitat after rewards were projected. No renderer/world-reopen RNG.

## 4. Independent systems and compatibility

All numeric/choice tuning below is **Design first pass**, adapted to Bookbinder rather than copied as Dragon gameplay. Counts/shape fields are explicit new saved source structure; a mesh cannot create them after the fact.

| Group | States and independent parameters | Compatibility / initial selection |
| --- | --- | --- |
| Locomotor limbs | count0–8, length and thickness proportions; equal-role repeated appendages | Axial and Amphibious piscine minimum2; others may be0. For optional-limb layouts select absent1/present3 first; forced-limb layouts always select present. Absent gives0 without a jitter draw. Present count follows existing free count tendency+jitter, rounded once then clamped to at least1 and the layout minimum/maximum. Default axial tendency preserves typical4, while2/3/5+ remain possible. This replaces intrinsic-leg plus ambiguous accessory counting. |
| Wings | absent / vestigial / functional; membrane or feathered; count1–8, span/chord | Sky requires functional count≥2. Water excludes wings in this first policy. Land/Amphibious may have wings but retain actual ground/shore movement. Sky does not add mass/perch restrictions. For non-Sky allowed habitats, starting weights absent4/vestigial1/functional1; type uses existing filtered pressure weights; count uses ordinary tendency. Vestigial means a visible underdeveloped wing form, not a flight grant. |
| Fins | absent / present; count1–8, profile and extent | Water/Amphibious only, independently of legs/wings; initial absent1/present2 in Water,2/1 in Amphibious. No fins does not stop an accepted sinuous/amorphous swimmer. No new swimming permission from a mesh. |
| Horns | absent / sleek / gnarled / knobbed; forward / swept-back / upward | Independent of ears/fans/crest/spines. Initial absent3, each style1; directions equal legal weights. Source declares paired cranial projections when present. Count is visual anatomy, not the loot portion count. |
| Cranial additions | none / long ears / crest / sensory fan | Retain existing stable choice conditional on a cranial region; Horns moves into its independent group. Ears use paired forms, crest one ridge, fan one structure. These do not invent sensory organs from numeric senses. |
| Axial spines | absent / ridge / spikes / sail; height and distribution | Independent of horns and tail. Initial absent3, each form1; all layouts provide a dorsal/polar attachment zone. Spike repetitions are explicit source exterior but not extra harvest rolls. No material reward/stat inferred solely from appearance. |
| Tail | absent / slender / ordinary / heavy; length | Axial/elongated/segmented/piscine support a continuous rear extension; initial absent1, other shapes1 each. Radial/amorphous exclude directional tails in this first policy. Length0.2–0.8 core length when present. No discrete tail fin/stinger/club without a separately supported source feature. |
| Exterior | existing covering values plus supported explicit surface forms | Thickness/coverage/finish vary continuously. A named pelt/scale/chitin shell must agree with the actual source projection, not a hardness-to-art guess. New chemistry/teeth/down/reward extensions remain separate. |
| Colour / Pattern / finish | actual CMY+Depth, Pattern, opacity/shine/schiller | Separate body, wing membrane/exterior and actual source-marked component slots; stable masks and canonical conversion. No quality-border tint or invented material hue. |

**No exclusive horns-versus-wings-versus-legs switch.** A valid Land axial animal can have four limbs, two vestigial wings, swept-back horns, a low sail and a long slender tail together. A Water piscine can have fins and explicit limbs together. Compatibility limits make the combinatorics coherent without flattening them to named species templates.

For odd appendage counts, place floor(n/2) pairs and one distinct midline attachment. Radial bases distribute ordered attachment zones around the core. Every base has a cranial/polar zone, dorsal zone and disjoint role-specific anchors; actual support limbs reach its rest plane. A horn never consumes a wing/leg socket. Missing optional art uses a functional component with the same role/count, never silently drops a valid group. No mouth/teeth/claws or skeleton detail is invented from attack values.

## 5. All-layout geometry and variation

Validate finite source values. Set s=size/100, b=build/100, L=0.45+0.90s tile units, B=0.65+0.70b. These are display units, not metres or new statistics. Shared display scaling caps the assembled horizontal radius at1.5 tiles without dropping components or changing logical occupancy. Source size remains intact.

| Layout | Initial core envelope | Species-stable shape variation |
| --- | --- | --- |
| Axial | lengthL,width0.45LB,height0.55L; biped stance may raise core to1.25L total | Head ratio0.18–0.28L; posture depends on actual support arrangement, trunk breadth on build |
| Elongated | centerline1.7L,diameter0.18LB |3–5 connected control points, bounded resting coil; tail extends the same axis |
| Segmented | length1.25L,width0.38LB |3–7 connected visible sections; no automatic limb per section |
| Radial | diameter0.80LB,height0.30L |3–7 contour lobes, distinct from actual limb/fin/wing groups |
| Piscine | length1.25L,width0.32LB,height0.45L | Stable taper/body-depth proportions, independent actual fins and optional tail |
| Amorphous | diameter0.80LB,height0.45L | Single connected mass with3–6 stable bulges and explicit attachment/polar zones |

Limb length0.25–0.65L, wing span0.25–0.85L each, fin extent0.10–0.40L, horn extent0.10–0.30L, spine height0.05–0.35L; proportions are independent bounded species choices, frozen once. Tail length/shape is independent as above. Covering thickness/coverage and Pattern provide additional trait-backed variety. Cosmetic section/lobe counts never become body-material portions. No secondary per-instance biological jitter beyond the existing actual saved specimen variation.

Logical position, occupied cells, pursuit, terrain eligibility, interaction reach, harvest and encounter owners stay unchanged. Grounded limbs meet actual permitted support; aerial/aquatic placement follows existing position authority and uses neutral placement when measured water depth is unavailable. No animation, mass-driven flight or physics simulation is required for structural readiness.

Recipe fields: version/source IDs, layout, actual habitat/component policy, complete independent part groups/type/count/parameters, ordered role anchors, bounded transforms, component versions, exact colour/Pattern/finish source references and unsupported/legacy status. Store compact recipe plus specimen overrides; instantiate meshes lazily only after disclosure. Same saved source/version reconstructs identically independent of camera, visit order and content-default changes.

## 6. Disclosure, materials and finite completion cases

Full current tile sight plus actual creature visibility admits the sanitized visual recipe. Hidden/fringe/remembered-only creatures retain current limited markers; no remembered moving mesh remains behind. No full-run or raw hidden-trait access from the renderer. Seeing a horn/wing does not grant a specimen, recipe, chemical fact, reward or new Bestiary entry. Actual harvested materials retain their current source colour and quantity owners. Older worlds preserve their saved/default representation without retroactively inventing independent parts.

Required bounded rules cases before claiming functional structural coverage:

- Every positive layout/habitat pair has a connected bounded assembly path; every excluded pair rejects. Existing Two-legged/Four-legged and all other recorded forms remain representable, plus truthful Many-legged new-policy classification.
- Wings and limbs vary independently:0-limb winged serpent;2/4/6-limb axial forms with0/2/4 wings; fins+limbs on a shore piscine; horns+crest+spines+tail coexist without socket conflicts. Include odd counts and count8.
- All six cores support every allowed cranial/wing/fin/limb combination through parameterized anchors, without requiring a finished-species prefab. Radial/amorphous tail exclusion is explicit, not an unimplemented accident.
- No Sky vestigial/wingless candidate; no Water winged candidate in this policy; no Amphibious piscine without supporting limbs or certified liquid/bank component. Land wings do not alter movement.
- Dark dry cold retains ordinary variation but not cold-water bias. Nonfinite data rejects; zero weights use only legal fallback. Type choice precedes its one conditional jitter draw; old policies unchanged.
- Same species across specimens preserves groups/counts, using actual saved variation; different proportion/ornament/colour axes create independent visible variation. Reopen is identical and consumes no gameplay RNG.
- Names and existing material projections consume final explicit source structure. No new reward from a visual part; hidden actors, old unknown anatomy and missing water depths remain honest.

**Design completeness gate:** all reference-derived relevant axes are mapped above, every allowed structural group has eligibility/count/attachment/dimension/variation/fallback, and no existing family is left to an artist’s inference. The only omitted Dragon systems are explicitly irrelevant inheritance/breeding gameplay, its separate combat/element math and planned expansion concepts not accepted for Bookbinder. This is a full modular structural specification, not a claim of broader ecology or delivered code.

**Remaining readiness dependency:** Engineering reviews feasibility of new multiple-group schema, pressure/type-before-count order, finalization before material projection, truthful Many-legged classification and all-layout anchor coverage. Any concrete incompatibility is resolved in this same document before family-specific generation. Generic interfaces, flora and raw water topology can continue. Implementation stages: schema → reviewed generation/finalization → persisted source/name/material consistency → all-layout functional assembly in existing3D consumer → Asset parts for named exact interfaces. Incremental commits are fine; incomplete family coverage is not called complete. No broad corpus, new trial menu, Design native audit or owner questionnaire.
