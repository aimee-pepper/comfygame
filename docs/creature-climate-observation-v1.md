# Creature climate relationships and observed-weather notes

**6 September2026 · Bounded Design proposal, not implemented.** Continues the assigned weather/ecological-coherence work after food/shelter and remaining anatomy. This specifies climate/body/flora relationships that the current model can support, closes false weather-derived anatomy/survival claims, and authors one small player-facing observation extension. It does not select a dynamic survival simulation.

Authorities: [cold-water correction](creature-cold-water-appendages-v1.md), [food/habitat/shelter](creature-food-habitat-shelter-v1.md), [anatomical materials](creature-anatomy-material-extensions-v1.md), [discovery journey](creature-disclosure-player-journey-v1.md), actual `LifeRules.WorldTendencies`, `FloraRules`, and the typed `WorldAtmospherePresentationReceiptV1` in Engineering source. Source inspection is not a new delivery receipt. Older atmospheric presentation documents retain historical implementation status; this packet does not assert their old status is current.

## 1. What the model actually supports

Creature generation currently weights a fixed individual trait budget using resolved world pressures. Rain/snow/air presentation has a separate typed, saved world receipt. These are distinct from moment-to-moment bodily exposure. The inspected creature model has no wet-coat state, thermal tolerance range, body-temperature meter, hydration, seasonal anatomy, weather-driven nesting or shelter-seeking behavior. A body found in a world establishes presence, not immunity, continuous food availability or observed adaptation behavior.

The climate relationships below **retain current allocation rules**, including their thresholds and order. The only previously decided count correction remains the separate cold-water opt-in. This new packet does not change generation weights, spend free additional trait budget or guarantee a particular species/material in a climate.

| Actual resolved generation condition | Existing relationship retained | Forbidden extra inference |
| --- | --- | --- |
| Thermal floor below30 | Cold weight favours size, covering and close reach, with less ornament allocation | Every creature must be furry, cold-proof or a guaranteed Pelt/Down source |
| That cold condition and Hydrology available magnitude above45 | Existing wetter branch favours bulk and increases covering less than the drier branch | The individual is wet, carries fat/Oil, swims or has an oil gland |
| Thermal peak above70 | Heat weight favours smaller bodies, reduced covering coverage, farther reach and paler coloration | Guaranteed heat resistance, radiator organs, Heat emanation or pale harvested parts that override actual colour |
| Both cold lows and hot highs | Apply the existing cold branch followed by heat branch under the same fixed budget | Pick only the dominant season, reroll an inconvenient body, or change its coat during the excursion |
| Actual Shore/Aquatic habitat with certified liquid, plus cold | Apply the already-specified narrow cold-water appendage policy when opted in | Rain, snow, wet roots, a blue tile or merely flying over water supplies a liquid habitat |
| High available water and the existing standing/flowing share condition | Existing fin/build/bone tendencies before accepted actual habitat/body admission | Every wet world creature is aquatic, Hollow Bone, scaled, or a source of Oil |
| Atmosphere peak above60; motion above55 | Existing size multiplier and feathered-appendage bias respectively | Air density or wind grants flight, storm immunity, a nest or Down. Actual supported wings/habitat still own flight |
| Flora in cold conditions | Existing lower-stature, woodier, clustered tendency | An actual plant is edible, dormant, frost-proof or a shelter just because it is low/woody |
| Flora in hot/arid conditions | Existing smaller/fleshier, physically defended and shinier tendency | Fleshy means edible or a new usable liquid; finish is not an Oil/pigment producer |

“Wetter cold favours bulk” is the supported generated shape statement. Older comments such as “fat, not fur” are not an independent tissue/reservoir definition. Keep that distinction explicit in descriptions and material authoring. Appearance, physiology, habitat access and harvestable anatomy are not interchangeable claims.

## 2. Food and shelter under weather — exact consistency boundary

Evaluate generation food witnesses against the **actual source's existing physical host and metabolism viability**, not a weather picture. Use the food contract's real placed source, original availability, complete part profile and per-component access. The existing root/freeze/submerged/chemistry exclusions remain authoritative. Do not create a second generic “rain means food” or “snow means every source dies” rule.

- Visible rain does not certify standing water, root moisture, a freshwater bank, aquatic access or an edible plant.
- Visible snow does not by itself prove that an actual water component is frozen. Certified liquid/frozen terrain remains the habitat owner. The accepted ordinary physical-root freeze boundary remains unchanged; no source is thawed to satisfy a recipe or food link.
- Mist, smoke, ash and miasma are separate existing atmosphere facts. Neither their tint nor a source's presence certifies respiration, detoxification, edible chemistry or harvest danger. Existing real hazard/visibility owners remain authoritative.
- Dark fungal support still requires its actual source/host and positive viability, without an invented sunlight gate. Chemosynthetic producers remain valid even where the first food-profile pass cannot yet describe an animal's intake.
- A discovered growth patch or bank can be cover without being a waterproof roof, den or warm refuge. The shelter contract still requires a real structure/use link for stronger claims. No cold/wet material bonus follows from standing beside a tree.
- Later harvesting, changing light, an animation phase or revisiting the world does not mutate frozen anatomy, food support history or recorded material quality. No automatic hunger, despawn, migration, replacement food or seasonal regrowth is added.

This closes which existing weather-related inputs may support a food/body claim. It deliberately leaves dynamic physiology absent rather than inventing rules to fill missing data.

## 3. Proposed player feature: observed-weather notes

**Exact consumer:** the existing creature Seen/encounter knowledge and Library/Bestiary detail route specified by the discovery contract. Extend that future knowledge record with a small list of actual observed world-weather contexts. No new screen, tool, research unlock, paid analysis, slot, stat, art family or map completion counter.

At the same authoritative action/visibility event that earns full current sight of a creature, the rules owner may capture the **current bound world's valid saved atmosphere-presentation receipt** when that atmosphere is also actually presented to the player. Reuse the discovery contract's party-aware full-visibility/crypsis guard. Opening Look, sorting, rendering frames and reading catalogue data never create knowledge.

Required evidence: actual run/world identity, canonical observed species identity, observation event identity, validated saved receipt/resolver version, relevant atmosphere facts and their exact contributing source IDs where the schema supplies them. Use the currently bound world's receipt, not a World History/arrival illustration from another visit or mutable catalogue. A receipt only proves world conditions; it does not prove the animal was exposed outside cover or physically reacting. If implementation cannot establish actual presentation at that observation, omit the note. Never substitute a generated climate guess.

| Actually presented saved condition | Exact proposed note |
| --- | --- |
| Rain with positive density and real recorded source | Seen in a world with rain. |
| Snow with positive density and real recorded source | Seen in a world with snow. |
| Mixed rain/snow with positive density and real recorded sources | Seen in a world with rain and snow. |
| Mist with positive density and real recorded source | Seen in a world with mist. |
| Smoke with positive density and real recorded source | Seen in a world with smoke. |
| Airborne ash with positive density and real recorded source | Seen in a world with airborne ash. |
| Miasma with positive density and real recorded source | Seen in a world with miasma. |
| Actually presented strong motion from a valid current receipt | Seen in a world with strong moving air. |

The wording records the **world in which it was seen**, not “thrives in rain,” “hunts in storms,” “immune to miasma,” “safe in cold,” or a habitat restriction. No cold/hot note is inferred from white scenery or a hidden Thermal reading. Exact temperatures remain under existing Survey knowledge; no additional survey measurement is granted here.

**Selection and persistence:** a future optional `creatureWeatherKnowledgeVersion=1` extends the separate sighting knowledge ledger. At most one note per category/world/species is earned, idempotently, on actual observation. When several conditions are visible at once, stable category order is precipitation, suspended medium, strong air. Display up to the three most recently earned distinct condition categories per species, preserving each note's source-world reference and known name. Repeated same-condition sightings are a no-op, not a frame counter or extra XP. Keep the full existing specimen record separate; an observed condition cannot create specimen measurements, inventory, material knowledge or a read teaching.

The note remains a past observation after Return or later visits. Keep actual occurrence provenance with its stored text/category; world renaming may use the existing known-world display name without changing the underlying identity. Old records begin with no weather note: absence is unknown, not evidence of clear weather or an unobserved creature. Legacy synthetic clear/calm fallback receipts do not establish a historical observation. Mixed rain/snow is one condition, not fabricated separate rain-only and snow-only encounters.

This uses the already-proposed Seen record and currently typed atmosphere identity. It does not require a new weather simulation before it can be implemented. It remains a future extension; no live creature batch is enabled by this document.

## 4. Concrete cases

- A bulky cold-world animal has no oil reservoir: its shape can be described from the actual body, but Oil remains unavailable. A world-level cold/wet allocation cannot supply missing anatomy.
- A rainy world has no certified liquid at a land animal's component: rain may be an observed-weather note; it grants no aquatic habitat, cold-water count bonus or food witness.
- A fully visible feathered flier in a snow-presenting world: record “Seen in a world with snow.” Preserve actual wings and movement; infer neither storm-flight success, Down nor cold immunity.
- A hidden creature or remote Apex marker behind mist: no creature-weather note. Knowing the world's weather does not reveal its unseen cast.
- Real rain and smoke in the presented receipt: the same sighting can add the two respective distinct notes, within the three-category display limit. No second encounter/XP event.
- A source's old world has only synthetic clear/calm compatibility data: add nothing. Reopening the Library cannot populate retrospective weather observations.
- An unfrozen actual fungus host with positive viability in a dark, rainy world: fungal food support uses the real host/profile. Rain alone neither establishes fungal food nor removes its lack of sunlight requirement.
- A warm appearance in a cold/hot variable world: both generation branches remain in effect; the finished saved body is unchanged. Neither a source material nor an observed weather category retunes it.

## 5. Three-goal progress and remaining production

**Body → materials:** climate is now explicitly prevented from creating oil/fat/Down/feathers or recolouring parts; actual anatomical producers and narrow consumers remain the source authority. **Ecological coherence:** the cold/hot/wet/air/flora relationships and real food/shelter admission rules are reconciled, including variable climates and rain versus liquid water. **Player experience:** a concrete, disclosure-safe set of weather notes lets players retain where they encountered creatures without false survival claims or a separate analysis action.

These are bounded design completions, not a finished ecosystem. Remaining production is implementation of the named anatomy, food and disclosure groups; natural prevalence and ordinary source-to-craft play; additional useful solid-material equipment roles; and supported feeding mechanisms beyond the first three profiles. Wetting, thermal damage/tolerance, shelter-seeking, migration and seasonal breeding remain **unselected simulation proposals**, not silently approved tasks or necessary promises for this first pass. Select one only if a concrete player experience needs it. All three broad creature goals remain open without a new owner decision.

When Engineering implements this slice, extend the existing focused knowledge tests with actual/missing receipt, full/hidden sight, old save, repeated event, two simultaneous conditions and source provenance cases. One normal implementation route is sufficient; no new evaluator, configuration matrix, Design native recheck, weather delivery poll or speculative art request.
