# Remaining creature feeding support — finite disposition

**6 September2026 · Bounded Design proposal, not implemented.** Completes the assigned support/unsupported disposition for aquatic, aerial, radial, amorphous and chemical cases. It does not add a fourth feeding profile, reinterpret body shapes as diets, invent anatomical organs/food sources, start a hunger simulation or enable Engineering rollout. Ordinary makers/services remain independent.

Authority: [existing food/habitat/shelter proposal](creature-food-habitat-shelter-v1.md), [actual bodies and movement](generated-creature-body-habitat-v1.md), [anatomy/material extensions](creature-anatomy-material-extensions-v1.md), [climate observations](creature-climate-observation-v1.md). Source boundaries checked against existing `CreatureTraits`, `FloraTraits` and `FloraRules` in Engineering's persistent `early-material-regions-v1` worktree; source inspection is not a native or delivery receipt. Existing source-defined photosynthetic/fungal/chemosynthetic viability remains current source behavior; the specific animal feeding links below are first-pass proposals.

## 1. What “supported” means here

A supported animal link requires all four existing proposal facts: **an explicitly assigned compatible feeding capability, an actual suitable food part/prey, actual component/contact access, and a supported basal chain**. Body shape, mouth-like art, weapons, movement, sensory allocation, metabolism potential and stock names are not replacements. A condition in this table means the earlier proposed profile can be assigned when all its evidence is real; it does not claim a feeding event has occurred.

The approved habitat/body arrangement remains independent: Sky/Water/Amphibious/Land with seven shape groups. Radial does not mean filter feeder, amorphous does not mean absorber, piscine does not mean carnivore, feathered does not mean seed eater, and many legs do not mean scavenger. `sensory.chemo` measures smell/taste; `appetite` is trait-budget cost. Neither defines what the animal can digest. Animal traits do not carry flora's `Metabolism` field.

## 2. Finite supported-case table

The first three rows reuse the existing proposal unchanged, including its size gap, source allowlist, fixed generation state and separate ecological selection stream. The final three retain actual flora producer support; they do **not** extend the animal diet allowlist.

| Supported case | Required positive evidence | Boundary |
| --- | --- | --- |
| Low-leaf browser, ordinary mobile Land/Amphibious quadruped/biped/serpentine/segmented | Explicit assigned low-leaf browsing capability; actual ordinary low living-leaf forage profile; reachable suitable source in every occupied component; no excluded hazardous/medicinal identity | Leaf-bearing body alone is insufficient. No canopy, submerged-forage or player-edibility claim |
| Ground fungal forager with those same allowed bodies/modes | Assigned fungal-body intake capability; actual fleshy soft-fungus forage profile, positive fungal viability and suitable damp/unfrozen host; same per-component access | Includes supported dark worlds without a sunlight requirement. Named medicinal Spore is not automatically food |
| Ground hunter with those same allowed bodies/modes | Explicit existing proposed hunter capability, natural armament total≥25; actual ordinary non-toxic/non-hazardous prey at least15 lower in species size; valid contact in every occupied component; prey's already-supported chain reaches real forage | No simulated win, prey replacement, carcass stock, diet-derived attack, new status or population quota |
| Actual photosynthetic flora | Actual saved photosynthetic metabolism and its existing positive light-derived viability/productivity, plus its own admitted physical host | Establishes a producer; only a separately eligible actual leaf food profile establishes forage |
| Actual fungal flora | Actual saved fungal metabolism and existing damp/darkness/decay-conditioned viability/productivity, plus its own physical host | Existing abstract producer support, not a new placed-detritus resource or proof the animal eats it |
| Actual chemosynthetic flora | Actual saved chemosynthetic metabolism, existing volatile-substrate share AND substrate magnitude viability/productivity, plus its own host | Valid dark-world production. It does not establish animal chemical intake, edible biomass or consumption of an inventory ore stack |

A land-bound creature with membrane or feathered accessories may still satisfy one of the first three rows if it has the actual allowed body, ground movement and declared feeding profile. Appendage appearance neither excludes it nor makes it aerial. A horned browser remains possible; weapons do not force predation. A Shore/Amphibious creature uses only its real bank/shallow access and gains no deep-water feeding or diving.

Existing fungal viability remains an abstract model of producer support. Do not fabricate an actual corpse/detritus placement merely to explain its existing metabolism. Existing chemosynthetic producers remain valid even where these three animal profiles cannot explain how nearby fauna obtain energy. An unresolved animal diet does not invalidate the world's existing life gate.

## 3. Unsupported cases and exact missing evidence

**Disposition for every row: diet unspecified under this first pass.** These creatures remain valid under their existing body/habitat rules. Missing data is a boundary on a claim, not proof that the creature does not eat or should be removed. This table identifies requirements for a future useful proposal; it does not author those missing parts or assign them automatically.

| Case the current fields might tempt us to infer | Existing facts that are insufficient | Exact evidence absent from this supported model |
| --- | --- | --- |
| Fully aquatic herbivore | Aquatic habitat, fins and a nearby green/submerged-looking tile | An actual submerged edible food-part profile with admitted host/chemistry, an explicitly supported in-water intake capability, and reachable feeding/contact geometry in each occupied liquid component |
| Fully aquatic predator | Water movement, meaningful Pierce/Rend/Crush and a smaller nearby swimmer | An assigned in-water prey-handling/ingestion relation for the actual body, valid feeding contact, and a resolved prey-to-basal-source chain. Attack capability alone is not feeding capability |
| Fish-shaped Amphibious browser/hunter | Real supporting limbs≥2 and legal bank/shallow access | An explicit feeding-capability assignment for the piscine body; it is outside the first three profiles' closed body allowlist. Walking does not fill that missing intake relation |
| Aerial low-leaf/fungal feeder | Wings, legal air traversal above a ground food patch | An actual supported way to obtain/handle that food at its site. Traversal does not supply landing, perching, hovering intake, grasping or reach into a canopy |
| Aerial predator | Sky movement, reach and an actual smaller airborne/ground animal | Assigned airborne prey handling/ingestion and actual feeding contact; prey must also have a supported basal chain. Do not add a swoop, remote attack or guaranteed hunt to validate the link |
| Radial animal feeding | Radial body, shell/appendages and nearby particles/plants/prey | A specific intake/handling capability for that body, an actual compatible food part or prey profile, and usable feeding-site geometry. No filter, mouth, suction or tentacle function is recorded by radial shape |
| Amorphous animal feeding | Amorphous shape, movement, chemical senses or an apparent contact attack | A specified intake/processing mechanism, compatible food chemistry and actual contact/access. No absorption, engulfing or dissolution follows from shape |
| Chemical-energy animal | `sensory.chemo`, emanation, toxic defence, mineral-rich surroundings or neighbouring chemosynthetic flora | Animal metabolic/intake capability plus the exact chemical energy/food source and compatible access. Flora metabolism cannot be copied onto fauna |
| Animal feeding on chemosynthetic biomass | Actual viable chemosynthetic flora | A declared edible biomass part/chemistry for the animal and compatible intake. Producer viability alone does not certify a food source |
| Filter feeding, detritus/carrion uptake | Water, decay tag, dead enemy history or sediment | Actual usable food resource/part and its condition/chemistry, intake/handling capability and feeding access. Neither history nor a pressure word creates stock or a carcass |
| Nectar, pollen, seed or fruit feeding | Flight, a flower-like picture, leafy growth or bright colour | Actual corresponding reproductive food part and availability plus a compatible intake relation. No new flora catalogue entries are implied |
| Eating defended plants or toxic/venom-bearing prey | Harvest is safe, predator has combat resistance, or a hazard is not triggered | Explicit edible tissue/chemistry and applicable digestive compatibility. No dietary detoxification from safe contact, warning Pattern or combat Ward |

No simple damage/hardness/colour threshold closes any row. The newly specified tooth/claw/gland material records do not by themselves close ingestion/digestion. A Fang can be a useful recovered point without proving what the living animal eats. The later anatomy producer may supply relevant physical facts, but a diet relation still needs its actual food and access.

**Cross-component rule:** a relation supported in only one of a species' occupied components cannot stand for all of them. Keep the earlier intersection requirement. Never relocate creatures, add flora, teleport prey, infer a remote source from the Bestiary or reinterpret an undefined prey diet as a completed food chain to make the row pass.

## 4. Result and disclosure contract

There are only the earlier three eligible animal profiles. This disposition changes neither their uniform selection nor species-size ordering, supported source list, habitat/body weighting, RNG consumption, cast count, trait budget, placement or material quantities. If none is supported, retain the existing proposed **diet unspecified** outcome with a specific missing-relation reason in the generation record. Do not create a fourth “chemical” or “generalist” fallback.

The player-facing result is **“Diet not recorded”** when a diet is shown without earned supporting knowledge; it is not “doesn't eat,” “starving,” or “ecologically invalid.” An internal supported link is not automatically a learned Bestiary fact. Keep the existing discovery contract: actual full sight, encounter/Read and committed material reward reveal only their own permitted facts. Do not expose hidden prey IDs, source coordinates, chemistry or an unseen cast through a diet explanation.

If a future actual learning route establishes a food relationship, it may use the appropriate capability wording from the food contract, such as “Can browse low leafy growth,” with its real evidence. It still may not claim an observed eating event without one. This packet adds no new analysis action, collectible diet slot, research gate, owner homework choice, fishing, feeding, taming or cooking mechanic.

## 5. Concrete dispositions

- Land serpentine with non-flying feathers, assigned low-leaf capability and a reachable valid leaf source in every component: browser candidate. Appearance does not force the Sky chapter or a seed diet.
- Amphibious quadruped can reach actual bank fungus using its existing shallow/ground route: fungal-forager candidate if every other first-pass condition holds. The same witness across inaccessible deep water does not qualify.
- Amorphous body beside that same fungus: unspecified; no absorption capability is invented. The plant remains valid fungal flora.
- Aquatic serpent can attack a smaller aquatic creature: unspecified until its actual intake relation and the prey's basal chain are supported. The attack and legal swimming remain intact.
- Winged radial creature above low leaves: unspecified; neither radial uptake nor aerial handling is defined. Preserve accepted flight without adding a perch requirement.
- Dark volatile world with chemosynthetic growth and a high-chemo-sense animal: preserve the world and its population; animal diet stays unspecified, no ore consumption or fluid reward is fabricated.
- Ground hunter's only candidate has unresolved hazardous tissue or an unspecified diet: no supported hunter link. Do not remove it or silently turn it into a browser.

**Closed bounded deliverable:** a finite supported/unsupported disposition and exact missing evidence for all requested cases. **Still genuinely unresolved:** particular new intake/food relations only if selected for a later concrete creature experience; natural prevalence of the actually implemented first-pass sources; and the combined learning/exploration/crafting experience. See [natural-prevalence acceptance](creature-natural-prevalence-acceptance-v1.md). These are not new ordinary-shop blockers or requests for Aimee to invent diets or price recipes. No native rollout or new simulation is authorized.
