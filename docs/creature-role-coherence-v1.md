# Creature role and movement coherence — first ecology slice

**5 September 2026 · Decided intended Design contract, awaiting implementation assignment.** This closes one bounded part of ecological coherence: the role and movement words used for newly generated ordinary creatures must agree with their actual supported facts. It does not finish diets, food webs, nesting, weather relationships, the full creature rework or Library Bestiary UI/integration.

Exact companion: `creature-role-coherence-v1.json`. Dependency: the body/habitat contract `b0c24016`, including habitat-conditioned appendages, legitimate movement components and legacy preservation. Bone and Hide keep their own source/material authority. No new species, combat ability, spawn chance or simulation is introduced.

## 1. Current source and concrete contradictions

Inspected native source `165a20e43f59a58baaa15f0c28ddd5b099b4ae7c` in `early-material-regions-v1`; this is source evidence, not a new native acceptance receipt.

- `CreatureIdentity.match` picks among eight identity regions by mean fit, threshold **0.78** and band tolerance **25**. This describes an existing sampled trait vector; it does not create a different brain.
- Averaging can override a defining trait. An otherwise perfect Ambusher gets **0.80** without crypsis, exceeding the current threshold. By contrast, an unarmed Pursuer fit of **0.80** is not automatically contradictory: current ordinary unarmed creatures really can pursue and strike with their mass.
- Grazer considers armament, covering and size, but receives no habitat, producer or diet facts. A world with no viable producers can therefore receive that label.
- The fallback noun looks only at appendage type: every membrane form becomes “glider,” every feathered form “flier,” even when its frozen habitat is terrestrial. A fin and low build can become “eel” without a species-specific anatomical authority.
- `Naming.Axis.bone` can choose “hollow” from relatively low boneDensity. That axis contains no cavity/solid-frame field; the Bone contract correctly does not infer Hollow Bone from it.
- Actual awareness, pursuit, crypsis, reach, delivery and nocturnal scheduling already have their own rules. Ordinary awake animals may pursue inside their legal component. Sessile plants and actual Apex encounters use separate paths.
- World constraints already cap trophic depth against `FloraRules.productivity × 1.2`. Productivity is resolved producer demand times viability; this is a pressure constraint, not proof of placed edible food, a diet or a running food web.

The correction acts on truthful interpretation of the existing result. It must not reroll a body until its old name becomes true.

## 2. Preserve the established causal order

1. Resolve world pressures and the existing producer-productivity/trophic-depth constraint.
2. Allocate the unchanged fixed ordinary individual budget. Vitality still governs cast/population size, not free extra individual strength.
3. Resolve physical habitat availability and final compatible body/appendages under the preceding body/habitat contract.
4. Freeze species traits and material-family authority from those actual facts.
5. Select a supported role label and a truthful movement noun under this contract.
6. Place, move, fight and produce rewards through their existing owners.

No role is selected first to force an Earth-animal template, extra weapon or particular drop. Naming must not change counts, weights, RNG consumption, traits, habitat, appetite, Danger, damage, rewards or teaching eligibility. No grazer → predator → Apex quota is added.

Existing producer constraints remain exactly as they are. Zero producer support does not authorize deleting all fauna, starving saved enemies, granting alternative metabolism or spawning emergency plants. In particular, absence of a confirmed plant diet does not mean a creature is harmless.

## 3. Supported role labels: hard eligibility before soft fit

Use the eight existing `IdentityRegion` cases and their existing fit formulas, order, threshold and tolerance. First remove ineligible candidates using the table below. Then select the highest-scoring eligible candidate; existing first-in-order tie handling stays deterministic. If no eligible score reaches 0.78, use a composed physical description. Never substitute an unsupported winning role or lower the threshold to fill a roster.

All rows require a valid new-policy body/habitat pair with an eligible component at generation. Temporary occupancy or a later blocked path does not rename a species.

| Existing label | Additional mandatory evidence | What the label may describe |
|---|---|---|
| Ambusher | armament total >=25; dominant Pierce; Close reach; defence is Crypsis | Existing concealed, close-range striking form; no new surprise attack |
| Pursuer | ordinary mobile creature, not sessile or Apex | Existing pursuit-capable form, confined to its habitat; limbs are a fit tendency, not a requirement for a flying pursuer |
| Tank | covering armourValue >0 | A robust protective build; existing size/covering fit decides strength of match |
| Grazer | **Unavailable for the new ordinary policy until plant-feeding identity is actually defined** | Weak weapons or nearby plants alone cannot certify diet |
| Swarmer | Delivery is Multi or Area | Existing small multi-strike/area form; not proof of a colony, pack size or new group behavior |
| Apex | **Unavailable in ordinary cast classification** | Only the separate actual Apex system establishes Apex status |
| Drifter | Aquatic or Aerial habitat | Existing light, sinuous fin/membrane form in a compatible medium; no wind-drift physics or immunity |
| Sentinel | Far reach | Existing armoured far-reaching form; not a promise of a nest, territory or permanent stationary behavior |

Use the current `Armament.isUnarmed` definition (total <25) and existing dominant-armament tie order, Pierce then Crush then Rend. Unarmed does not mean unable to fight: current combat retains mass-based damage, Delivery and Far first-strike behavior. Do not add a weapon requirement to Pursuer, Swarmer or Sentinel. Do not import the material-projection weapon threshold 30; that threshold answers a different question.

Crypsis already controls field concealment. Awareness/detection still decides when it breaks, and the current attack rules decide damage. A label never grants stealth, range, additional attacks or access across impassable terrain.

### Why Grazer remains unresolved

The model currently has no confirmed diet, edible-forage relationship or feeding behavior. The retained principle “if nothing grows, nothing grazes” rules out inventing a feeding claim from weak armament; positive producer potential alone does not prove a particular animal eats it either.

For this new policy, a former Grazer candidate receives another genuinely supported role or a physical description. Its body, ordinary existence and behavior remain unchanged. Diet is **unspecified**, not secretly carnivorous, photosynthetic or arcane-fed. Old Grazer records remain untouched.

This is the bounded Design resolution of an unsupported label, not a new feeding mechanic. A future plant-feeding design must establish its own actual body/food/habitat relation before enabling Grazer. That wider choice is not silently settled here, and this packet does not ask Aimee to approve a made-up food-chain simulation.

## 4. Movement nouns read habitat plus body

When a composed name is needed, retain existing size/descriptive-word selection except the bounded unsupported words below; replace the final noun with this explicit table.

| Frozen habitat / body | Noun |
|---|---|
| Aerial, valid membrane or feathered wings | flier |
| Aquatic, any valid aquatic body | swimmer |
| Terrestrial or Shore; quadruped or biped | walker |
| Shore piscine with the required supporting limbs | walker |
| Terrestrial or Shore; serpentine | coil |
| Terrestrial or Shore; segmented | creeper |
| Terrestrial or Shore; radial or amorphous | shape |

All nouns already exist in the current vocabulary. Do not use “eel” from build/fins alone, or “glider” from membranes alone: this slice has no specific eel identity or distinct gliding mode. Membrane wings in an Aerial creature justify “flier”; membranes on a land-bound body do not.

A flier can use only the flight component permitted by the body/habitat policy. The word does not let the player walk over deep water. A swimmer stays in its liquid component. A shore walker cannot cross arbitrary inland territory or deep water. These names convey supported movement, not extra permissions.

**Bone wording:** remove “hollow” from new-policy creature qualifier candidates because no actual hollowness field exists. Use another permitted existing qualifier, or the physical fallback; do not manufacture a Hole/Marrow/Hollow Bone subtype. Relatively low boneDensity may still support the existing “light” descriptor in its existing comparison context. This does not change material IDs or price.

This is not a full adjective-catalogue rewrite. Other literal anatomy/ornament words remain a later naming/anatomy review and may not be used as proof that a recipe ingredient exists. The authoritative source part, not its nickname, determines crafting relevance.

## 5. Stable interpretation and existing exceptions

Add a distinct optional policy, suggested name `creatureRoleCoherenceVersion = 1`, requiring the preceding body/habitat opt-in. New-policy role/name interpretation is frozen at species generation, before cosmetic specimen jitter.

A minimal species interpretation receipt stores the policy, source species ID and body/habitat policy, final role or composed status, supported display name, and the existing compatibility identity key. It references the exact frozen traits/habitat instead of reconstructing them from a name. Stable source IDs and existing discovery compatibility keys do not change because the displayed words change. No Library key migration or new Library consumer is part of this slice.

- Field, Look, encounter labels and new reward source descriptions for that species must use the same frozen name. Do not reclassify from a jittered individual, a changed roster, or current illumination.
- Current nocturnal scheduling remains vision <28 or existing emanation; no new feeding time, resting timer or weather calendar is introduced.
- Preserve deterministic qualifier selection/collision handling. “Hollow” must also be excluded in forced collision alternatives. Distinct stable species keys remain distinct even if no truthful unique display adjective is available; never invent an anatomical claim merely to avoid duplicate display words.
- Material eligibility/quantity/quality/colour remain independently derived from their approved exact source receipts. A new name cannot turn Hide into Bone, imply a new raw material, change a quality band, or reveal an unknown drop.
- Actual Apex entities, sessile flora and authored special creatures keep their explicit existing paths. A plant continues to use its flora name. This is not permission to rework or enable those systems.
- Legacy policy nil keeps old generated casts, names, discovery keys, materials and saves. No relabeling an existing anchored world or starting a fresh search to replace it.
- Missing/inconsistent required facts on a new-policy source refuse interpretation before publication/encounter admission. Do not fall back to a trait-only “glider” or invent habitat/diet. Unsupported labels on a valid body simply use the legal fallback; they do not destroy the creature.

## 6. Concrete acceptance examples

Expected results, not performed native tests:

| Input | Expected |
|---|---|
| Land quadruped with membrane appendages | May keep any supported role; composed noun walker, never glider/flier |
| Aerial membrane-winged serpentine, valid count2 | Composed noun flier, never an inferred eel or gliding specialist |
| Aquatic serpentine with no fins | Composed noun swimmer; valid aquatic identity supplies movement |
| Shore piscine, limbed count2 | Composed noun walker; remains within the shore union |
| Zero producer productivity; weakly armed candidate that formerly matched Grazer | No Grazer claim; truthful role/fallback, no population deletion or invented food |
| Productive forest with plants; identical candidate but no defined diet | Still no confirmed Grazer claim; plants alone do not prove diet |
| Build50, Close, Pierce40, no Crypsis | Legacy Ambusher fit0.80 can no longer authorize Ambusher |
| Build55, size50, Mid, limbed, armament0 | Pursuer fit0.80 remains eligible for an ordinary mobile body; pursuit does not prove a carnivorous diet |
| Same supported Ambusher with Crypsis | Eligible for the unchanged fit test; existing visibility rules alone control concealment |
| Terrestrial light sinuous membrane form | Drifter rejected because its movement mode is terrestrial |
| Aquatic light sinuous finned form | Drifter eligible for the unchanged fit test |
| Ordinary body with Apex fit above threshold | Not an actual Apex; no Apex label, budget, stationary behavior or special loot |
| Actual Apex flag or sessile predatory plant | Existing dedicated behavior/naming path preserved |
| Small single-strike creature | No Swarmer claim from size alone; no extra foes or strikes created |
| Far-reaching unarmed creature with suitable armour/size fit | Sentinel may fit; existing mass-based combat and Far behavior remain, with no new weapon or diet inferred |
| Low boneDensity | No “hollow” qualifier or Hollow Bone item inferred |
| Source specimen becomes a little smaller/paler through existing jitter | Same species role/name and compatibility key; actual material receipts retain their own source facts |
| Save/reopen after light, roster or occupancy changes | Same frozen interpretation; existing movement/schedule rules continue |
| Legacy anchored world with a Grazer/glider name | Name and saved behavior unchanged |

Eventual focused validation should exercise candidate eligibility and actual legacy scores, noun mapping, old/new version isolation, stable keys/names, and no RNG/stat/material changes. One bounded native Field → Look → encounter/source-label → reopen check can compare a land membrane body and a real aerial body at the actual target iPhone/default text/current appearance. No Library screen, new art, paid natural run or broad population census is required. Engineering implementation and this native check remain unassigned.

## 7. Completion boundary and proposals

**Closed:** role eligibility before soft matching, movement nouns from actual habitat/body, no unsupported feeding/hollowness/Apex claim, and versioned interpretation without new abilities or changed source materials.

**Still open:** actual diets and edible forage/prey relations; nesting and weather responses where useful; full anatomical/qualifier vocabulary; material-to-crafting connections; and the complete generated-creature experience. No new species list, food-chain simulation, spawn odds or ability proposal is adopted. Any later proposal introducing those mechanics requires its own explicit design decision.

Aimee Homework receives partial progress on ecological coherence, not a completed checkbox. All three larger creature goals remain open.

## 8. Aimee’s Bestiary organization direction

Aimee proposed **Sky, Water, Amphibious and Land**, in that order, as the primary divisions on 5 September. Adopt those player-facing chapters as the intended direction, mapping respectively to the existing aerial, aquatic, shore and terrestrial identities. Amphibious means capable of water/land movement under the shore contract; it is not the Earth taxonomic class or permission to cross every depth or terrain.

A creature’s saved supported habitat chooses its primary chapter. Wings alone do not place a land creature in Sky. Preserve one species identity; the chapter does not create another creature, ability, diet or material source. Future true multi-mode species would need an explicit classification/cross-reference decision; this slice adds none.

**Decided second layer, approved by Aimee on 5 September:** body shape. Existing values give Four-legged, Two-legged, Serpentine, Segmented, Radial, Fish-shaped and Amorphous. For example, Sky → Serpentine → species, or Water → Fish-shaped → species. Use the axial body plan rather than counting all wing/fin/accessory appendages. Only valid combinations are candidates; this proposal does not enable presently excluded body/habitat combinations. A recommended browsing treatment would show subcategories represented by recorded creatures, without a completion target for every theoretical combination.

Material, role and source details stay in the entry rather than becoming a third mandatory classification layer. No category grants discovery knowledge. **Aimee explicitly lifted the Bestiary work hold after approving this arrangement.** Bestiary implementation may now be coordinated by PM in the appropriate execution lane. The broader creature systems remain pending implementation; this approval does not claim a delivered screen or release unrelated Library work.
