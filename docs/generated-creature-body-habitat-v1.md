# Generated body plans and habitat compatibility — first implementation slice

**Status:** decided intended behavior, 5 September 2026; Design complete for this bounded slice, native implementation not assigned or delivered. This does not complete the wider creature rework or release the hold on Library Bestiary UI/integration.

**Authority:** Aimee's retained shallow/deep aquatic habitat and flying-over-ground-and-water decisions; PM's request to finish a concrete body-plan/habitat contract. The exact companion data is `creature-body-habitat-v1.json`. It supersedes the body/appendage and aerial-boundary portions of `creature-habitat-authority.json` and the older ecology overhaul document for newly opted-in worlds. Other creature-material families and combat balance are separate work.

## Current behavior and the actual gap

Inspected Engineering commit `3216debd135effb453b9c8853f656323e2e058df` in `early-material-regions-v1`. This is source evidence, not a new mounted or physical-phone acceptance claim.

- `CreatureTraits.swift` already stores seven body plans, five appendage types/count, five cranial features, build, costly axes, full Coloration, finish, senses, defence and emanation. `Species` stores traits, habitat and material projection; placed enemies store their exact habitat tile component.
- `LifeRules.applyVisualMorphology` hashes the existing trait vector into body/head identity. Its habitat-aware cast overload chooses habitat afterward but does not condition body or appendages on that habitat. The old habitat weight table is not presently applied to morphology.
- The implemented physical habitat adapter is in `LifeRules.swift`, not a separate EarlyCreatureHabitatRules file. With `earlyCreatureHabitatVersion == 1`, liquid needs saved submerged, unfrozen, liquid-region facts plus water/deep-water base ground. It uses the early passable graph. Ordinary placement reserves 65% of requested slots for contact-eligible components; component eligibility does not promise every chosen tile can be stepped onto.
- Terrestrial, shore and aquatic components already have their distinct movement boundaries. Aerial currently uses the entry-connected passable set, excluding deep water and chasms. That is narrower than the accepted intention that fliers cross water.
- Narrow typed Hide production and Leather consumption have their own retained native receipts. No new assertion that all old creature tests pass: the six previously documented legacy fixture failures remain separate.

## Decided intended generation order

1. Finish physical terrain, entry correction and material-source placement; retain their frozen physical facts. Compute habitat components under this policy.
2. Preserve the ordinary costly trait allocation, species IDs, cast size, nocturnal derivation, defence and gameplay RNG consumption. Select available habitats with the existing pressure weights and repeated-habitat factor 0.65. The first species must have a contact-eligible component. If none exists, produce no ordinary placed fauna; do not manufacture a terrestrial home.
3. Select a body plan using the companion habitat row. These weights are retained first-pass tuning. A zero is a deliberate exclusion for this slice, not a universal biological impossibility.
4. Select appendage type using the existing pressure-derived type weights times the companion habitat multipliers, then apply the body-specific restriction below. Use a separate versioned morphology stream, stable enum order, never dictionary iteration. A suitable concrete stream is world seed derived with `0xEC01_06_02`, then derived by stored species ID. Do not consume the existing habitat or gameplay streams.
5. Preserve the original sampled count where legal; none becomes zero, other types clamp to 1–8, aerial wings and shore-piscine limbs clamp to 2–8. Keep the existing cranial choice. No count reroll, new budget spend or costly-axis edit.
6. Persist final traits and habitat before computing the species material projection. No later visual-hash call may overwrite the new body/head. All placement, names, specimen identity and reward rules read the same frozen result.

Weights changing on this new policy may change future species and their body-derived parts. They never reproject an existing saved species or reward.

## Supported morphology and movement meaning

| Field | Supported values | Meaning in this slice |
|---|---|---|
| bodyPlan | quadruped, biped, serpentine, segmented, radial, piscine, amorphous | Axial shape; seven existing cases, no new animal catalogue |
| appendages.type | none, membrane, feathered, finned, limbed | Existing appendage description; positive count required unless none |
| appendages.count | integer 0–8 | Zero only with none; wings used for aerial movement and shore-piscine limbs need at least two |
| cranialFeature | none, longEars, horns, crest, sensoryFan | Identity, no habitat access granted |
| habitat | terrestrial, shore, aquatic, aerial | Frozen ecological movement mode, conditioned on compatible morphology |
| build, size, covering, bone, weapons, colour, finish, senses, defence, emanation | existing trait vector | Preserve; no new movement thresholds or combat tuning |

Body-plan names describe the axial form. An appendage count is not a complete anatomical inventory: a quadruped with membrane appendages still has its four supporting legs; a zero accessory count does not amputate them. This slice does not manufacture extra limb/wing/fin material quantities.

- **Terrestrial:** all existing plans except piscine; terrestrial locomotion can be walking, crawling, sliding or flowing. Wings on a terrestrial species do not automatically grant aerial movement. A fin-shaped appendage alone does not establish swimming or land support.
- **Shore:** land/water movement is supported by the selected shore identity. Quadruped, serpentine, segmented, radial and amorphous plans use the retained weights. A shore piscine form is allowed only with limbed appendages, count at least two: an explicitly land-capable fish form. A piscine form with fins or no appendages belongs in aquatic habitat, not on the dry bank. Biped remains zero-weight first-pass tuning.
- **Aquatic:** piscine, serpentine, segmented, radial and amorphous plans; the selected aquatic identity supplies swimming, including sinuous or flowing bodies without separate fins. Retain the current zero weight for quadruped/biped in this slice. No underwater-breath meter is added.
- **Aerial:** all plans except piscine; membrane or feathered appendages, at least two. Do not impose a mass/bone threshold, minimum perch count or forced landing timer. The accepted ability to fly does not depend on an Earth-animal template.

If all transformed appendage weights are zero, use the explicit fallback row. For shore piscine, force limbed before selection; never reroll body/habitat until it fits. Missing, negative or nonfinite weights are invalid authoring data, not an excuse to invent a random fallback. Finite all-zero pressure weights use the documented fallback.

## Exact terrain sets and encounter boundaries

Four-way components, minimum two unique tiles with one cardinal edge; component ID is minimum row-major tile index. Ground overlays and colour never establish water.

**L** is physically certified unfrozen liquid at water/deep-water base ground using the existing early adapter. **P** is the current passable tile set; **E** is the entry-connected subset using the early graph. Apply the legacy graph only for worlds without the existing early opt-in.

| Habitat | Legal tile set | Contact-eligible component |
|---|---|---|
| Terrestrial | E excluding water/deep-water base ground | any retained component |
| Shore | shallow tiles in L, plus non-water tiles in E cardinally adjacent to L | intersects E and P |
| Aquatic | L, shallow and deep together | contains an entry-connected passable shallow tile |
| Aerial | passable non-water ground in P, union L, excluding chasm and crumbled tiles; blocking trunks/deposits remain excluded | intersects E and P |

For aerial components, P includes otherwise isolated passable ground. A connected liquid crossing may therefore join two shores. This permits flight over deep water without allowing flight through a tree, mineral obstacle, a chasm or a crumbled gap. No perch is needed for an air-over-water component; a wholly remote component can exist without player contact. Chasm traversal is not added by the accepted ground/water decision.

Preserve pressure-weight formulas, but calculate fractions from the new physical sets: water fraction = 100 × |L| / max(1, non-chasm tile count); shore fraction uses the shore union. No liquid inferred from Hydrology pressure alone. Ice is never liquid; passable ice may support terrestrial or aerial movement as ground. This does not make ice a source of aquatic habitat or Hydrology teaching.

Placement preserves the existing entry exclusion, occupancy, awake-roster choice and slot budget. For N requested ordinary enemies, reserve min(N, max(1, ceil(0.65 × N))) slots for contact-eligible components. Skipped reserved slots remain skipped; they are not replaced with remote-only fauna. The 65% promise concerns components, not immediate encounter tiles or a guaranteed actual final count.

A creature moving over deep water does not make that tile walkable by the party. Preserve ordinary encounter admission and contact limits: the player must be able to make the existing legal contact at that moment. No adjacent attack, flight combat reach, fishing, boats, dragging fish ashore or teleporting fliers into a fight. Pursuit uses the creature's legal component and current remaining passability for its mode; a legal air path may cross liquid even though the player's path cannot. If no legal next step exists, hold position. This does not change move cadence, attack strength, detection, fog, damage or hazard immunities.

Freeze the component tile set on each specimen. Later blockers/crumbling may remove traversable tiles, never silently expand its original habitat. Roster replacement must match the habitat and the new morphology policy, and remain legal at the occupied tile; otherwise keep the existing specimen. Guardians still choose the highest-appetite eligible local species at the exact site tile, stable species-ID tie-break; never import an aquatic guardian to a dry ruin.

## Version and compatibility boundary

Add a distinct optional new-world body/habitat policy version, proposed field `creatureBodyHabitatVersion = 1`, and persist that version on species and placement receipts. Nil preserves all existing generation, visual compatibility, cast, movement, saved placements and material rules. `earlyCreatureHabitatVersion = 1` alone does not opt an existing book into this new contract.

New-policy saved records require the named fields, valid enums, finite existing numeric facts, legal body/habitat pairing and consistent count/type. An unknown or malformed new version refuses that operation atomically; it must not decode into a default quadruped or silently fall back to the old policy. Existing tolerant legacy decoding stays intact. No old-world regeneration, relocation, inventory rewrite or anchored-world cast change.

Keep the narrow Hide intersection: both the persisted species primary-Hide projection and the actual specimen body must qualify. Keep the 70% roll, subtype/quality math, frozen pre-party Danger, Anatomy bonus, exact source Coloration and parent history. No body-plan reinterpretation on reward, no extra covering reward, no species-colour backfill. Full CMY/Depth/Patterning remains functional colour identity; exact RGB artwork remains separate.

Apex generation, sessile plants, authored special creatures and already-saved legacy enemies retain their existing explicit paths. They are not ordinary-cast examples or evidence that this contract covers the entire creature rework. No new exception is created for ordinary fauna with contradictory morphology.

## Acceptance examples for eventual Engineering implementation

These are required expected results, not executed native receipts.

| Input or situation | Expected result |
|---|---|
| Terrestrial body draw | piscine has weight zero; other six retain listed weights |
| Shore piscine, pressure strongly favours fins, original count 0 | limbed count 2; can occupy its shore union, never deep water |
| Aquatic serpentine, appendages none | count 0; shallow/deep liquid legal, dry bank illegal |
| Aerial serpentine, both wing pressure weights 0, original count 0 | choose membrane/feathered at 1:1; count 2; no perch condition |
| Two passable shores separated by two deep-water tiles | same aerial component if cardinally connected; distinct terrestrial components; party still cannot step into deep water |
| Two physically liquid deep-water tiles with no contact shore | aquatic/aerial ecology possible, component not contact-eligible; never supplies first-species contact requirement |
| Rendered water but frozen/non-liquid physical receipt | not aquatic liquid; no invented thaw |
| Single isolated liquid tile | no one-tile aquatic component; may still be in a larger legitimate shore/aerial union |
| Tree, deposit, chasm or crumbled gap | no new aerial bypass through that tile |
| N=4 ordinary slots | three slots require contact-eligible components; no legal candidate means skipped slot, not illegal placement |
| Night roster lacks a compatible replacement | retain specimen; no land/water relocation |
| New world save/reopen | exact traits, policy, habitat component, source colour and projection persist; visual hashing cannot replace them |
| Old book with earlyCreatureHabitatVersion 1 but new policy nil | existing movement/morphology and Hide receipts unchanged |
| Same seed, new morphology stream enabled | original gameplay draw stream remains unchanged; new-policy morphology reproducible |
| Qualifying Hide source and a mismatched legacy source | existing typed-Hide intersection and legacy reward compatibility preserved, no duplicated Hide |

Eventual bounded mounted proof: an isolated new-policy native Field world at the actual target iPhone/default text should show one shore-capable form staying in its shore component and one flier crossing certified deep water, while party entry remains refused; save/reopen preserves them. No Library screen, new final art, paid natural campaign or broad seed corpus is required. Engineering schedules this only when assigned.

## Remaining work

This slice closes morphology/habitat compatibility. Full anatomical availability and canonical material production beyond the completed Hide path, broader ecology such as food/nesting/weather relationships, and the wider creature rework remain unfinished. No new Aimee homework is needed to implement these rules. Chasm flight, adjacent water combat and additional animal catalogues are outside this slice, not implied promises.
