# Flora generation — modular structure inspired by Dragon DNA

> **7 September accepted extension, internally verified; installation pending:** [Pressure-led life families v1](pressure-led-life-families-v1.md) adds a separately versioned family-selection policy. It preserves this packet's independent structure, current/legacy source authority and saved worlds. Its exact new-policy selection rules take precedence where explicitly stated; no change is delivered merely by this note.

6 September2026. **Aimee directly requests a similarly granular system for flora, insofar as relevant to plants. Decided intended direction; new structural choices below are Design first-pass tuning for Engineering review, not delivered.** A two-form tree/ground-growth implementation is not the completed flora design. Reusable support, branches, leaves, caps, reproductive/display parts and surface channels compose a generated kind; finished premade plant species are not the system.

Reference: Dragon DNA `dff9a9a00d3862b55829d46e6be7efc0f5861094` independent body/frame, horns/spines/tail and colour/finish systems. The adaptation is independently combining relevant plant axes with structural compatibility, not breeding genetics, animal anatomy or transferred stat bonuses. Existing `FloraTraits`, source/harvest owners and accepted flora ecology remain authoritative.

## 1. Retained foundations and complete structural coverage

Flora retains its separate budget and existing metabolism selection, stature, woody/fibrous/fleshy tissue mix, defence type/strength, habit, coloration and finish. Metabolism stays photosynthetic, fungal or chemosynthetic; no new botanical kingdom, oxygen/water simulation or flowering season is implied. Current identity regions bramble/canopyTree/succulent/mat/fungalBloom/reed/crust are descriptive trait matches, not a list of seven plant prefabs or compulsory cast slots.

No per-tile biological jitter: one world has a small generated flora cast, and each kind’s shared structure is frozen. Habit remains the current spatial patch/distribution owner. Exact source-owned variants, timber class/wood colour and actual medicine-part profiles remain their own saved facts. A partial tree model must not secretly make grass, fungi and mineral-fed growth into recoloured trees.

| Supported construction family | Actual eligibility | Connected support and compatible upper structure |
| --- | --- | --- |
| Woody branching growth | Photosynthetic + woody-dominant tissue | Rooted trunk/support, connected branches, compatible leaves and optional recorded reproductive/display structures |
| Fibrous/herbaceous growth | Photosynthetic + fibrous-dominant tissue | Stalks/stems, grass-like blades or broad/frond foliage, bounded flexible branches |
| Fleshy growth | Photosynthetic + fleshy-dominant tissue | Connected pads/rosette/swollen stems with optional foliage and reproductive structures; no wood skeleton inferred |
| Fungal growth | Fungal metabolism, independent of dominant tissue | Mycelial/root anchor plus cap/stipe, shelf or connected tuft; no photosynthetic leaves/flowers/fruit |
| Chemosynthetic growth | Chemosynthetic metabolism | Attached crust, plate, tube or branched chimney growth; no automatic leaf canopy or fungal cap |

Dominant-tissue ties use the existing stable Tissue.dominant rule, not a new random family roll. Each row has a complete parameterized path; no new biome/source is manufactured to supply it. Photosynthetic low-stature forms may spread as mats, while tall fibrous forms remain stems/reeds rather than being forced into trees. Fungal/chemical stature scales their own family. Existing role names are derived afterward from actual source traits, not assigned to pick a finished model.

**Current implementation dependencies:** Flora already has ID/worldSeed/traits. Some early timber producers have sourceID/woodColour but no explicit Flora link; an anchor’s nearby or coincident unrelated plant is not an identity join. Without a verified exact Flora/source link, keep the current tree representation. Add the explicit link at generation for future supported sources; never borrow nearby traits or rewrite older source history. Apothecary sources with already frozen flora provenance use that exact owner. No new harvested materials are required for structural representation.

## 2. Independent structure systems

All new structural choices are frozen source facts at world creation, not renderer guesses. Absent states are first-class and do not consume attachment/count draws. Decorative repetition counts are not resource units or species counts.

| System | Independent fields | Compatibility and first-pass selection |
| --- | --- | --- |
| Support | height, thickness, taper; single/multiple support form | Height from stature, strength/thickness from actual tissue. Woody gives connected trunk/bough support; fibrous stalks; fleshy connected pads/stems; fungi/chemical use their own family cores. No root extends into invented soil/water. |
| Branching | none/sparse/repeated/dense; angle and internode spacing | Woody weights1/2/2/1; fibrous3/2/1/0; fleshy3/1/1/0. Fungal/chemical use compatible connected shelf/tube branching with3/2/1/0. Branch shape never creates more map tiles or harvest nodes. |
| Foliage / external growth | absent/blade/broad/needle/frond; width/length/edge form | Photosynthetic only, absent1 and other shapes1 each after compatibility. Low fleshy cores may photosynthesize without leaves. Fungal shapes cap/shelf/tuft and chemical crust/plate/tube replace this system, equal supported weights; they never use leaf assets. |
| Arrangement | alternate/opposed/whorled/rosette; density | Photosynthetic shapes select equal compatible states; trunk branches attach at real support anchors, rosette only at a common support center. Fungus/chemical use radial/stacked/clustered arrangements of their own parts. Independent of map habit. |
| Surface defence/display | none / explicit thorn-like projections / rough surface; size/density | Only actual defended physical flora may choose thorn-like projections; at or above the current threshold use none1/rough1/thorn1. Chemical/active defence cannot receive invented thorns from toxicity alone. Current Dangerous growth warning/harm owner remains authoritative. |
| Reproductive/display structures | absent/blossom/fruiting structure; form/extent | Photosynthetic kinds only; initial absent4/blossom1/fruiting1. These are new saved morphological features, not flowering/fruiting lifecycle simulation or edible-food promises. Fungal uses absent2/spore-bearing surface1; chemical has no reproduction structure in this first version. |
| Colour / Pattern | independent material slots with source precedence | Foliage, actual wood/bark, supported flower/fruit/cap surfaces retain stable masks and canonical CMY+Depth+Pattern. Do not make every branch share the foliage tint or grant a colour/material absent from the saved source. |
| Finish | actual opacity/shine/schiller | Waxy/matte/glossy variations follow saved values through bounded surface rendering; transparency cannot reveal unknown contents or underground roots. |

Presence/branch/leaf choices combine independently after structural filtering. A branched woody plant can have narrow leaves, sparse blossoms, real physical spines and matte pale foliage together; a tall fibrous kind can have broad blades without being turned into a woody tree. Fungal shelves remain fungal even when glossy or towering. No fixed “one special feature per plant” rule.

**Reproductive colour guard:** until a distinct per-part colour is actually generated and saved, reproductive surfaces use the kind’s existing foliage/body colour and finish. Do not sample a new flower colour only during rendering. Later explicit source-part colour may override it through the same saved channel scheme. Blossoms/fruiting structures do not create a Fruit resource, food, seed item or medicinal use. Harvestability and the actual named part remain in existing source records. Reference-inspired visual granularity does not silently redesign the resource economy.

## 3. World conditions, selection and fallback

Existing world pressures determine the flora cast’s metabolism, budget and traits first. Photosynthetic support depends on the existing actual light/growing-source rules; fungal and chemosynthetic kinds retain their supported generation paths. Wetness, temperature, substrate and light do not get a separate competing renderer ecology. Under the same budget, stature and tissue remain real tradeoffs; structure reads them rather than demanding a large tree from a low-stature draw.

Generation order: existing actual ecology/traits → construction-family eligibility → independent compatible structural groups → explicit source link/material channels → frozen recipe/version → source placement and mandatory access validation. Draw each group from world seed + flora ID + group key/version in stable order using a separate structure stream. Finite zero weights use uniform already-compatible states; invalid data rejects before admission, not an unrelated leaf/wood fallback. Renderer mount/reopen consumes no random draws and never adds per-tile biology.

Habit controls where actual instances/patches grow. Render one source-owned trunk/crown for its real footprint, including its own known canopy; do not stamp a new tree on each canopy tile. Grass/low growth is represented only where the actual flora/growth owner permits it. Layout/branching affects silhouette within its declared envelope, not occupied cells, light blocking, movement cost, Root source membership or encounter admission.

A tree’s harvested state removes only that source’s live structure; partial work follows its current saved owner. Medicine/tree sources without a supported shared Flora recipe remain honest current representations until linked; this is an explicitly missing data route, not complete procedural-flora coverage.

## 4. Dimensions and attachments

**Proposed display tuning, not metres or tool thresholds.** Let t=stature/100 and q=max(woody,fibrous,fleshy)/100 after source validation. Main height H=0.12+2.38t tile units. Support radius R=0.025+0.075q; crown/external radius C=0.12+0.43t. Each family uses the same monotone stature without turning numeric height into a new collision rule.

Woody support rises to0.60H, with connected crown branches centered near0.75H; fibrous stems may reachH; fleshy mass heightH with body radius0.5C–C. Fungal stipes/shelves and chemical tubes/plates stay withinH andC. A low-stature tree-class source keeps its actual tool class even if its apparent size overlaps another class. Species-only variation sets branch angles20–65 degrees, leaf length0.15–0.50H bounded to0.05–0.35 tiles, and repetition3–8 per supported growth cluster. Blossom/fruit/cap extents are0.05–0.20 tiles within the main envelope. All are revisable literal tuning, frozen by recipe version.

Define root anchor, support joints, branch sockets, foliage/growth sockets and reproductive/display sockets as separate roles. Parts declare compatible metabolism/construction family, parent role, local pivot/contact surface, maximum span and material slots. A leaf cannot attach to empty air; a shelf joins its core; a fruiting structure hangs from an actual supporting joint. No fixed preassembled finished plant occupies the family slot. Reusable caps/blades/boughs and generic procedural functional components are allowed. Asset produces literal reusable components only after Engineering supplies their exact consumer/format/unit/pivot/socket/material protocol.

Underground root systems are not drawn or disclosed without actual permitted source geometry. The abstract root anchor is a transform/support contract, not proof of visible harvestable roots. Physical blocking and Axe/Scythe targets remain the existing root/source/occupied-cell owner; branch or leaf overhang does not add a target or remove access. Large display envelopes obey current foreground fading while keeping known bases clear.

## 5. Colour, memory and material continuity

Canonical Bookbinder CMY+Depth and saved Pattern remain separate. Source-assigned shades override the world/kind palette as already decided. Actual wood colour stays independent from foliage; source-part colours follow their own saved references. Pattern is local to stable part surfaces, not screen/world coordinate movement; strong patterning is not a rare material or danger label.

Harvested flora must retain the actual saved colour for supported crafting uses. A model may not reroll colour when chopped, stored, processed or reopened. Material quality and UI rarity colours do not recolour plants. No source-owned colour is averaged to simplify the mesh.

Currently visible stationary flora receives only its permitted recipe. Remembered scenery retains the last-observed recipe/version/source appearance and never reads hidden new depletion, growth or colour. Unknown roots, chemical properties and unearned harvest predictions stay out of snapshots. Existing harmful-growth warnings remain based on actual known current harm, not attractive thorns or colour. Generated appearance does not grant ecology or resource knowledge.

## 6. Functional coverage and Engineering gate

Representative finite cases: all five construction families at low/mid/high stature; every allowed support/branch/growth/reproductive state has a connected bounded recipe; forbidden fungal leaves/chemical flowers reject; woody narrow-leaf+blossom+physical defence coexist; fibrous broad leaves stay nonwoody; optional bare fleshy photosynthetic kind remains valid; same flora kind across tiles has no biological jitter; exact tree/Flora link absent stays current rather than borrowing nearby traits; remembered depleted tree does not update invisibly; actual harvested colour/Pattern remains source-owned without new yields. These are direct cases in existing generation/scene tests, not a corpus or new tools project.

The complete intended modular flora design consists of those families and independent systems, not merely two convenient implemented meshes. Engineering must confirm the exact source-link owner, budget/finalization order, supported per-part channels, and all-family component/attachment representation before calling the flora generator complete. New fields/recipes and their actual appearance must be implemented and delivered; final assets and wider ecology remain separate. Existing Settings3D consumer only; no new trial menu, per-tile save bloat, food/loot redesign or Design native checks.


## 7. Exact future timber-to-Flora selection

This closes Engineering review `9f4e949b`. It applies only at new-policy generation; existing sources are never reassigned. The actual producer/anchor/root suitability, source quota, mandatory reservation and harvest class are chosen by their current owner first. A Flora link does not become another requirement for obtaining existing Logs.

Eligible cast kinds for either smallSoftwood or smallHardwood must belong to this exact world, have finite validated traits, photosynthetic metabolism, woody-dominant tissue, stature≥70 and tissue.total≥45, and an already valid source root/site under the existing producer rules. These thresholds reuse the existing canopy-tree trait criteria as explicit first-pass biological linkage. A name match or coincident Tile.flora is not proof. Softwood/Hardwood class is the actual source producer, not inferred from colour, high wood amount, or a species adjective.

Process actual placed sources in stable order: smallSoftwood before smallHardwood, then sourceID. Maintain a per-kind frozen timber affinity for this new policy. A kind can acquire either Softwood or Hardwood affinity, never both; it stays the same kind across repeated source instances. Prefer already matching-affinity eligible kinds, then unassigned eligible kinds, stable world-seed+producer-class+FloraID rank (ID tie). Selecting an unassigned kind explicitly freezes that affinity from the actual producer; do not alter its numeric traits, metabolism, caste identity or create another species. A kind assigned the opposite affinity is ineligible for this source. Record exact FloraID/worldSeed/traits-version/affinity in the source link before appearance finalization.

If none qualifies, preserve the actual planned source, yield, tool level, wood colour, mandatory placement and existing tree representation with explicit **no eligible Flora link** status. Do not invent a new kind, force stature/woody values, change Hardwood to Softwood, remove Logs from the opening or borrow nearby growth. This is a defined incomplete-representation case, not evidence every timber source has generated3D biology. Full visible timber coverage must report any such unsupported sources honestly.

The exact source’s stored wood colour continues to override only its bark/wood material channel; the linked kind’s saved colour/Pattern owns foliage unless an already explicit source override exists. No per-tile random colour or biological jitter. Apothecary’s existing exact frozen Flora linkage remains its authority and is not reassigned by this timber rule. Engineering’s eligible-kind selection, repeated-source affinity, no-candidate and source-custody checks can use existing generation tests; no new world-search harness.

Engineering confirmed the exact timber affinity, eligible-kind selection and no-candidate preservation rules after reviewing checkpoint15740b49. Source-choice review is closed; runtime implementation and delivery remain pending.
