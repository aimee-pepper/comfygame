# Creature food, habitat and shelter — bounded generation contract

**6 September2026 · Game Design first-pass proposal, not implemented.** Advances the existing ecological-coherence goal using accepted body/habitat, roles, flora sources and material ownership. It defines a small generation-consistency relation, not hunger, breeding, hunting AI, food consumption, population replacement, new player food items or a new asset family. Current shop implementation remains independent and higher priority.

Authorities: [body/habitat](generated-creature-body-habitat-v1.md), [role coherence](creature-role-coherence-v1.md), [cold-water appendages](creature-cold-water-appendages-v1.md), [actual parts](creature-body-material-rewards-production-v1.md), [disclosure journey](creature-disclosure-player-journey-v1.md), existing `FloraRules` metabolism/productivity, actual ordinary flora and the complete Apothecary/Scriptorium source profiles. Preserve existing delivered ecology until explicit versioned implementation.

## 1. What currently exists and what this proposal adds

The native flora model already distinguishes photosynthetic, fungal and chemosynthetic metabolism, physical tissue, stature, defended/active growth and saved colour/Pattern. `FloraRules` has real metabolism viability and producer productivity; dark worlds can support fungal or chemosynthetic producers. `CreatureTraits.appetite` is the existing trait-allocation cost, not calories or a runtime hunger meter. Current natural attack, covering, habitat and movement facts do not by themselves define diet, edible species or nest ownership.

Keep that abstract producer gate, fixed individual budget, current species/cast counts, pressure weights, placement and movement. This proposal adds **a declared feeding profile and real local support witnesses** where the existing final body and placed sources admit one. Unsupported relationships remain **diet not specified**, not proof of carnivory, magical feeding, starvation or an empty ecosystem. It does not reroll/delete creatures or add free flora to fill a missing link. Chemosynthetic-world life remains valid under the existing producer model even when this narrow diet pass cannot explain its particular intake mechanism.

A food relationship describes what the future species is capable of using and which actual source supported that claim **when the world was generated**. It is not evidence that an eating/hunting event occurred, that supply lasts forever, or that the generator has solved carrying capacity. Those are different claims and remain out of scope.

## 2. Closed first-pass forage sources

A source must be a real saved living flora placement/part in the new world, with its actual ID, species/body/metabolism, source region, physical host and positive original availability. A displayed grass tint, growth number, recipe ingredient name, potential metabolism weight or hidden catalogue definition is not a source. Use its actual region/path facts; a swamp label does not establish water and a currently frozen tile is not a liquid feeding site.

**Ecological food declarations below are explicit new profile assignments**, not claims that every similar existing plant was already edible. They concern the compatible generated animal, not safe human consumption. No food inventory, edible icon, player-eating action or recipe is added.

| Proposed food profile | Exact eligible actual source | Exclusions and meaning |
| --- | --- | --- |
| `ecology.food.living_leaf.v1` | An ordinary actual Leaf Rosette/leaf-bearing ground flora source, photosynthetic, stature<50, positive living leaf tissue, not defended or predatory, with an explicitly assigned soft-leaf forage part | The source must really bear leaves; generic Stem Fibre, dead stock, Logs, Cord, Cloth and Pulp are not edible substitutes. A Leaf Fibre harvest is its existing separate material use, not a food item |
| `ecology.food.soft_fungus.v1` | Ordinary actual fungal growth, stature<50, positive fleshy tissue, existing fungal viability>0, a supported damp/unfrozen local host, not defended or predatory, with an explicitly assigned soft fungal-body forage part | Fungal metabolism alone does not make every spore/wood-like growth food. Fungal support is not renamed photosynthesis and no sunlight floor is imposed |

For both, any actual toxic/chemical hazard or unresolved tissue chemistry excludes the assignment. A source's lack of contact damage is not positive edibility evidence by itself. The **new explicit food profile** is the additional positive declaration. It must match the actual source; it never overrides that source's hazardous or medicinal identity.

All six Apothecary named profiles and Scriptorium Dyer's Root are excluded from this first-pass food allowlist unless a later exact dual-use profile is authored. Aromatic/Soothing Leaf and Restorative Spore being useful in medicine does not prove a food relationship. Toxic Sap is not forage merely because its admitted harvesting route has no contact damage; Bitter Root, Bark and dye roots similarly gain no inferred edible use. Existing quantity, tools, source colour/Pattern and optional flora-placement budget remain unchanged.

No new food declaration is supplied for chemosynthetic biomass, aquatic submerged vegetation, carrion, nectar, pollen, fruit, seeds, raw minerals, creature fluids or detritus. Some may later support worthwhile creatures, but the current model lacks the necessary exact part/chemistry/access relation. Record the precise missing relation rather than pretending a generic Reagent, Ichor, vegetation count or atmospheric colour supplies it.

## 3. Three feeding profiles, with actual habitat access

The first pass limits active profile assignment to ordinary generated **Land or Amphibious** creatures with supported quadruped, biped, serpentine or segmented bodies and actual mobile ground access. These are bounds on which functional templates this pass authors, not a statement that other bodies cannot feed. Radial/amorphous uptake, fully aquatic feeding, aerial food handling and sessile plants keep their existing existence/behavior and remain unspecified in this contract.

A feeding profile is deliberately assigned as part of the new body/ecology interpretation; eligible body shape alone is not proof of the profile. It adds no tooth/claw/tusk material, new attack or hidden stat. Its ordinary low-growth access must be physically compatible with the actual body/ground movement. No reach up a canopy, diving, flight/landing, burrowing or movement through a blocked tile is invented to make a link pass.

| Proposed animal profile | Required food support at generation | What it establishes |
| --- | --- | --- |
| `ecology.feeding.low_leaf_browser.v1` | The assigned low soft-tissue browsing capability and at least one eligible living-leaf forage source in **each actual occupied habitat component**, reachable by that creature's existing movement | An explicit plant-feeding relationship. Strong horns or defensive attacks do not forbid browsing; weak weapons do not establish it |
| `ecology.feeding.ground_fungal_forager.v1` | Assigned low fungal-body feeding capability and an eligible soft-fungus source in every actual occupied component, under that same real movement/access rule | A fungal feeding relationship, including suitable dark damp worlds; no implied poison immunity or ability to eat named medicinal/toxic spores |
| `ecology.feeding.ground_hunter.v1` | Ordinary non-sessile mobile body, meaningful natural armament total≥25, and an actual eligible smaller ordinary prey species with supported food in each occupied component | A possible prey relationship using already supported attack/access; not proof of a successful hunt, new hunting AI or guaranteed combat victory |

The source must be on a tile the animal can actually use, not merely in the same broad 'Land' chapter. Unreachable vegetation across deep water, isolated ledges, sealed barriers or another disconnected shore component does not count. An Amphibious body may use its allowed bank/shallow route; that does not grant deep-water access. Tree canopy is not low forage, and a passable tile alone does not contain food.

**Prey bounds — first-pass tuning:** prey is an actually placed ordinary generated species, not an Apex, authored guardian, sessile hostile flora, tamed animal or party member. Its species size must be at least15 lower than the predator's on the existing0…100 scale. It must not have `isToxic` or an unresolved hazardous tissue/secretion profile: no new dietary toxin tolerance is inferred from the predator's combat Ward. Each witness prey has a compatible currently generated placement reachable within the predator's actual component and ordinary contact/attack capabilities. This is a potential food/access relationship; do not simulate a battle to certify it or turn minimum combat damage into proof of ecological dominance.

A prey species must already have a resolved supported feeding profile leading to an actual forage source. A hunter may therefore link to a smaller supported hunter, but cannot form a self/cyclic food chain or rely on an undefined prey diet as though it proved a complete basal chain. The strict size ordering gives an acyclic relation; no trophic-level currency or population quota is introduced.

## 4. Exact generation resolution and preserved state

Opt-in proposal: `creatureFoodSupportVersion = 1`, requiring the existing final body/habitat and actual flora source facts. Missing version preserves existing ecology. After actual species and their placements are final, process species by ascending saved species size, tie-breaking by stable species ID. This is a **post-generation consistency pass**; it cannot spend trait budget, change the generated cast, move specimens or insert a food patch.

For each eligible species, compute the profile set supported in **every** occupied component. Stable option order is leaf browser, fungal forager, ground hunter. If several are eligible, make one uniform selection using a separate versioned ecological stream derived from world seed and stable species ID; never use gameplay/loot RNG or dictionary ordering. If none is eligible, record diet unspecified with the missing-relation reason. This intentionally leaves existing creatures alive without inventing a source, rather than reclassifying unsupported diet as proven.

For the chosen profile, select one real witness per occupied component in stable source/species/placement ID order. Retain the eligible-profile decision, selected source/prey IDs, source-generation versions, component/access references and chosen feeding profile on the immutable species ecology receipt. A presence witness shows a supported relationship, not sufficient biomass for every animal. No witness reserve consumes or protects player harvest stock. The same plant may support several plausible relationships; this contract makes no caloric or population-capacity claim.

Species appearance, material projection, actual specimen jitter, anatomy and gameplay remain owned by their accepted contracts. Forage source IDs link to their original colours/Pattern; neither consumer adopts the other's colour, material grade or chemistry. A prey link is not a source receipt for a predator's inventory materials. Flesh, meat, bones or fluids are not newly awarded because a diet link exists.

A new source inconsistency is rejected before saving a claimed relationship; an otherwise valid creature may retain diet unspecified. Never repair a broken receipt with a nearby plant, a different habitat component, an invented prey species or a generic resource balance. Save the exact resolved link once. Loading, Look, creature movement, player harvesting, later kills, day/night changes and revisiting an anchored world do not reroll the profile or recalculate historical support. Retain original source references even if a plant is later harvested or prey defeated; label them generation-time support if surfaced. No replacement prey, starvation, respawn or forced migration occurs.

## 5. Roles and knowledge

**Grazer can become eligible only when the implemented new policy actually selects `low_leaf_browser` with complete local support.** Keep the existing role-fit score,0.78 threshold, stable order and other role constraints; positive diet is a hard prerequisite, not an instruction to force Grazer as the winner. A strong-horned browser may still receive a different truthful physical/behavioral name. A weakly armed creature with no chosen plant-feeding profile remains another valid role/description. Fungal foraging alone does not enable the specifically plant-feeding Grazer label in this slice.

Pursuer and Ambusher describe existing movement/attack, not automatically a predator diet. Tank does not mean herbivore. Swarmer does not prove a colony or shared nest; Sentinel does not prove territorial guardianship or a den. Actual Apex remains separate. New diet labels must not change hostility, pursuit, awareness, reach, defence, combat rewards or movement. A browser can still respond under the game's existing combat rules.

Keep the completed disclosure journey: first sight and Look reveal actually visible bodies and supported material possibilities, not hidden digestion, a precise food graph or every linked prey species. The recipe catalogue and an internal generation link do not themselves create learned biology. Previously earned encounter/Read measurements remain available, but are not automatically evidence of an observed feeding event. No new feeding observation, field-note reward or paid analysis action is added here.

When the future feeding-profile consumer is deliberately implemented, a supported profile may justify a concise qualitative capability description such as **“Can browse low leafy growth.”** It must not say **“Watched eating [undiscovered species]”**, show an unseen prey location, or claim a live hunting interaction. Exact named source/prey links stay internal until an existing or separately authored legitimate knowledge event supplies that particular relationship. This disclosure implementation is separate from generation consistency, and should not be inferred from ordinary numeric specimen storage.

## 6. Shelter opportunity versus a real den or nest

Existing terrain may provide cover; that is not automatically a built, occupied or owned structure. This contract adds no nest asset, den geometry, construction action, eggs, breeding season, shelter buff, patrol territory or predator home marker.

| Claim | Minimum actual evidence | Allowed scope |
| --- | --- | --- |
| Can use ground cover | Existing reachable growth/cover geometry in the animal's legal component and a body that fits the existing movement rules | Habitat opportunity; does not guarantee concealment beyond actual crypsis/visibility rules |
| Can shelter near a bank or rock | Actual reachable bank/rock geometry and a supported refuge space, not merely a substrate name | Potential shelter only; not a cave, waterproof refuge or occupied den |
| Nest / den exists | A real already-authored/persisted structure or site with that identity, valid physical location, support/entrance/access and current existence | Describe that structure only at its existing lawful disclosure; no generic tree/growth tile is upgraded into it |
| This creature uses or owns that nest/den | The structure evidence plus an explicit persisted link to the actual creature/species and an authored use relationship | Ownership/use claim only when that relationship really exists; habitat, nearby presence, role or a loot trace alone is insufficient |
| Occupied, breeding, guarding young, building or returning home | An actual authored state/event establishing that behavior | Unavailable in this first-pass contract; no simulated event is invented |

Fliers keep the accepted **no perch requirement** for movement and existence. Their habitat does not imply a high nest, ledge, branch or landing behavior. A tree mesh does not contain a nest because a bird-like creature is nearby. Water plus silt does not establish a nesting bed or accessible den. A rock face is not a cave entrance; sparse/dry/cold terrain is not evidence of burrowing or weather resistance.

If an existing authored site actually says **old nest** or **abandoned den**, retain that site's exact content and discovery, but do not assign its present owner from the nearest animal. The old territory-find proposal's `den_pack` and `high_nest` flavour rows require this actual structure evidence if ever enabled. Without it, that proposal must use another genuinely supported trace or neutral **Found nearby**; it cannot create a nest just to justify a loot roll. Its old habitat-only trace table is not a nest-generation contract. Previously saved authored prose is historical evidence and is not rewritten by this new policy. No territory-find implementation, frequency change or extra Aimee approval gate is introduced here.

## 7. Weather and concrete consistency examples

Keep existing photosynthetic/fungal/chemosynthetic viability, actual host chemistry, root moisture, frozen/submerged facts and weather-derived body tendencies. This proposal does not redefine the thermal thresholds, manufacture constant food through winter, grant resistance from diet or shelter, or replace the accepted cold-water appendage correction. A generation-time food link is not a promise of continuous feeding under future weather.

| Concrete case | Intended result |
| --- | --- |
| Ground browser body, actual ordinary nondefended low leaf source reachable in each occupied component | Leaf-browser is eligible; if selected, it may satisfy Grazer's diet gate without forcing the role |
| The same body has only a green map tint or a Leaf Fibre stack at Home | No forage witness; diet unspecified, no automatic Grazer |
| Horned, strongly armed land body with valid low-leaf food | Browsing remains eligible; horns are not proof of carnivory |
| Dark damp region with actual soft fungal growth and positive fungal viability | Fungal-forager may be supported without inventing sunlight or eating medicinal spores |
| Dark volatile region with only chemosynthetic growth | Existing producer gate/life remains valid; these three profiles do not invent chemical digestion, so specific diet remains unspecified |
| Toxic Sap placement is safe for the player to harvest | Still excluded from forage; safe contact is not edible chemistry |
| Low leaf food across an impassable river from a land animal | No link; no new swimming, teleported forage or forced food spawn |
| Amphibious body can actually reach a bank's low leaves via its admitted shallows | The real bank source may support browsing; deep water remains a separate access limit |
| Hunter size70, ordinary non-toxic prey size50 with a resolved local forage chain | Hunting profile can be eligible; no fight is simulated or guaranteed won |
| Size70 hunter with only prey size60, an Apex, toxic prey or prey beyond its connected access | No supported prey witness under the first-pass size/access rules |
| Two hunters proposed as each other's only food | Invalid; ascending size and a real basal forage chain forbid the cycle |
| Airborne Sentinel over a tree | No inferred nest, territory or perch requirement |
| A real discovered abandoned nest, no present-owner link | Describe the old structure; do not assign the nearby creature or claim eggs/young |
| Player later harvests the food patch or defeats linked prey | Original generation support remains historical; no hunger, replacement spawn or changed reward occurs |

## 8. Completion and remaining work

This bounded proposal defines the exact supported low-leaf, soft-fungal and smaller-prey relations, their source/body/access requirements, deterministic selection and truthful nest/den claims. **Implementation remains unassigned and current ecology is preserved.** It is not a claim of a complete food web or a simulation.

Remaining Design work: exact aquatic/aerial/radial/amorphous feeding and chemosynthetic intake; carrion/detritus and other food types if they gain real value; sufficient natural food prevalence and population support; actual shelter structures/ownership if a future native consumer needs them; useful weather response and player-visible learning of specific diets; remaining anatomy/recipe roles; natural play of the combined creature/exploration/crafting experience. These are named dependencies/proposals, not manufactured individual approval chores. No genuine owner choice is blocking the independent rules above, so this packet adds no new Aimee homework decision and leaves all three existing creature goals incomplete.

Eventual Engineering cases should directly cover the table, actual source references and component access, uniform eligible-profile selection on a separate stream, acyclic prey links, no material/XP/player-stock changes, legacy/reload preservation, Grazer prerequisite, and absent versus real nest evidence. No broad source audit, population simulator, evaluator framework, extra asset family, native Design check or duplicate phone verification is requested.
