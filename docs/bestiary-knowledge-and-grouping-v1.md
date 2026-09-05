# Bestiary knowledge and grouping — implementation contract

**5 September 2026 · Decided intended clarification for the approved sorting UI; not yet implemented.** Preserve existing discovery events, records, combat, rewards and early-game balance. Aimee approved Sky, Water, Amphibious and Land with body-shape subcategories and lifted the Bestiary hold. This contract closes the disclosure and compatibility details required to implement that arrangement.

Source baseline inspected: Engineering `594cb61c23c198337b2c42ad4ccebc10023a1817`, tree `1c8501453bd2c360a3dced3f047e18dad95c8a55`. Source owners are `Discovery.swift`, `BestiaryRules.swift`, `BestiaryView.swift`, `WorldRules.swift`, `CombatRules.swift`, and the Library shelf adapter in `LibraryRules.swift`. This is source inspection, not a mounted sorting receipt.

## Current facts and the boundary

- Both the current entry adapter and habitat-volume adapter require a persisted species discovery record with `firstSeenRunIndex != nil`. A generated cast, habitat map entry or stored-looking trait vector alone is not an admitted entry.
- Ordinary encounter admission records the species and, when traits exist, an individual specimen. Victory is not required. The existing combat Read/remember path also records knowledge. Preserve those events and their existing counters.
- There is no separate persisted distant-sighting-only stage in the inspected code. Seeing a creature in the field and recording a specimen are not interchangeable operations.
- Habitat is separately frozen in `speciesHabitatByIdentity`. Missing legacy habitat deliberately remains unclassified.
- An identity can pool multiple specimens. The current featured appearance/name follows the latest retained specimen. Retained specimen history is capped; discovery identity knowledge is not that history's length.
- Missing legacy `bodyPlan` decodes as quadruped. That compatibility default is not evidence that a Four-legged shape was observed.
- The existing detail page already exposes recorded specimen comparisons, including personal peer count and the generated-reference comparison. Sorting does not add a defeat/analyze gate to those already-owned measurements.
- The current entry adapter reads generated `species` records. Preserve its existing legacy/authored rows. Do not add the separate legacy creature counter to the generated entry count: an authored encounter may already have been recorded in both registries.

The older shelf brief's Land/Shore/Water/Air labels are superseded by Aimee's new order. Its inherited 368×800/configuration instructions are also superseded: use the actual target iPhone viewport/default text/current appearance only. No excluded configuration or accessibility work is authorized here.

## Admission and revelation table

| Player/state situation | Sorting UI may show | It must not add |
|---|---|---|
| No admitted discovery record; creature exists only in a bound world, cast, preview or hidden terrain | No creature entry, search hit, count contribution, specimen or category volume | A silhouette slot, species total, body/habitat hint or material family derived from that hidden creature |
| Creature currently visible but never recorded by an existing discovery event | Existing field/Look presentation remains owned by its current rules; no automatic new Bestiary entry | A distant-sighting record, specimen, XP or inferred habitat/shape disclosure |
| Admitted identity, no retained specimen | Existing known identity, encounter history and any separately recorded habitat/shape; explicit “No individual record” where measurements would be | Invented measurements or a regenerated representative specimen |
| Admitted identity with legitimate stored specimen | Existing recorded appearance/measurements and comparisons; grouping only from supported recorded classification | A new claim that the creature was defeated, dissected or fully analyzed |
| Existing Read/remember transaction | Its current species/specimen knowledge; preserve existing persistence and counters | A second reward, encounter count or discovery event merely because classification metadata is attached |
| Victory or material acquisition | Existing combat/reward transaction remains authoritative | A complete material catalogue inferred from one victory, appearance, a role name or a habitat label |

**Remote sightings:** the older Library shelf direction intends legitimate remote sightings, including unreachable aquatic life, to be recordable without inventing a specimen. That remains an intended but unimplemented separate recording path. This sorting task does not implement it. Exact new sighting fields, reveal stages and an analysis/material-knowledge transaction are not supplied by current records; any new reveal behavior needs a separate proposal and implementation decision. Do not mark every existing encounter as analyzed to approximate it.

## Classification from knowledge, not the world

Primary order and exact saved habitat mapping:

| Chapter | Saved habitat |
|---|---|
| Sky | aerial |
| Water | aquatic |
| Amphibious | shore |
| Land | terrestrial |

Amphibious describes supported water-and-adjacent-land movement, not Earth taxonomy. Wings, fins, the latest occupied tile, a source world's climate and a creature name do not substitute for the saved habitat. The chapter grants no new movement or encounter access.

Within each chapter, use this display order: **Four-legged, Two-legged, Serpentine, Segmented, Radial, Fish-shaped, Amorphous**. These map respectively to quadruped, biped, serpentine, segmented, radial, piscine, amorphous. Accessory wings/legs/fins are not the axial body plan.

A known identity has exactly one primary placement and one current shape placement. Use its **latest legitimately recorded explicit body shape**, consistent with the existing latest-record presentation; do not split a pooled identity or manufacture a new species key. Show “Latest recorded shape” in the entry when explaining the grouping. If a later legitimate specimen of the same broad kind records a different shape, its grouping can move; sorting or loading a world alone cannot move it.

The saved habitat remains independently frozen. An apparent conflict in source habitat uses existing encounter compatibility/refusal rules, never a sorting-time reassignment. Do not force legacy records through the future body/habitat generator's permitted-combination table: preserve real recorded facts even when they would not be newly generated by that future policy.

## Explicit body-shape provenance

Small additive metadata is permitted at existing generation/discovery owners; it changes neither a reveal event nor the generator's result.

1. Suggested source marker: optional persisted `bodyPlanIsExplicit` alongside traits. Set true only when morphology is explicitly generated/assigned by an authoritative source. Default trait construction, missing fields and tolerant legacy decode must not set it true.
2. The decoder requires both a true marker and a valid explicit bodyPlan to treat shape as supported. Missing marker remains unknown, even when an older save now contains a quadruped field: an earlier decode/re-encode may already have materialized the fallback. Do not claim that field presence alone recovers lost provenance. Preserve existing tolerant decoding and data; this is classification, not a new whole-save quarantine.
3. Preserve source provenance when copying traits into existing specimen records. Cosmetic jitter does not create or remove it. Encoding an unknown/defaulted source must keep it unknown on the next decode.
4. Suggested discovery aggregate: optional `speciesBodyPlanByIdentity`. Update it only inside the existing successful species/specimen recording transaction, using a valid explicit source shape. This stores the latest legitimately recorded shape. An unknown legacy source does not overwrite an earlier known shape.
5. Missing legacy aggregate entries default to empty. Do not backfill from an active/anchored world, a generated-reference sample, a display name, an icon or an unmarked specimen. A later real encounter can supply it. If a future migration has independent trusted provenance, that migration needs an exact bounded source rule; this contract invents none.
6. The aggregate survives ordinary specimen-history pruning, just as known habitat does. It creates no extra encounter, specimen, XP, reward or attention event. Failed recording/save leaves all knowledge and counters unchanged.

When a category tile shows a creature shape, use a retained specimen whose explicit shape matches that known classification, preferring the latest such specimen. If none remains, use an existing neutral fallback icon with the known label. Do not draw an unmarked default quadruped as proof of classification. Keep all existing retained measurements accessible in detail; their availability does not establish shape provenance or material knowledge.

This is a compatibility resolution for old records, not a new requirement to defeat a creature or buy analysis. It does not depend on the unfinished body/habitat or weather generator policies being implemented.

## Missing classifications and counts

- Known habitat, no known shape: keep the entry in its true chapter under **Shape not recorded**. This is a fallback label, not an eighth body type.
- No known habitat: keep the existing entry accessible under **Unclassified**. This is a compatibility collection after the four habitat chapters, not a fifth ecological habitat. Any known shape can be described in its detail without inventing a chapter.
- No known habitat and no shape: retain the known identity and old individual records under Unclassified. Do not discard it or call it an undiscovered animal.
- Fixed chapter navigation labels may remain visible at zero. They are the approved browsing structure, not evidence that the current world contains a creature of that type.
- Actual habitat volumes and body-shape content groups appear only when they contain admitted known entries. This applies the existing nonempty-volume knowledge rule to the second layer and settles the earlier recommended browsing treatment as a bounded Design choice.
- Empty collection copy: **Nothing recorded yet.** Empty selected chapter: **No recorded creatures in this section.** Search miss: **No recorded creature kind matches your search.** No locked creature tiles, missing-species silhouettes, “0 of total,” completion percentages or theoretical body/habitat combinations.
- Counts are distinct admitted identity keys, not number of specimens, kills, Apex sightings, legacy-plus-generated totals, or the hidden cast. With a search/filter active, label the count as matching recorded kinds. Chapter counts and shape-group counts use that same filtered admitted set; each entry contributes once.
- An encountered Apex indicator requires the existing recorded Apex sighting. A large body, Apex-like name or generated world flag cannot create that indicator.

## Pure UI behavior

Build the presentation from admitted discovery knowledge first. Only then apply the saved classification and query. Do not scan active worlds, anchored casts, generated distributions, material projections or the content catalogue to complete the grid.

Keep current known-name search; no hidden-name autocomplete, undiscovered trait/material search or inferred synonym index. Stable IDs and tie-breaking use the existing identity key after visible name ordering. A deep link to a non-admitted key shows an unavailable/empty state; it must not resolve a full creature from a world by that key.

Opening, filtering and sorting are read-only. Preserve current Back/scroll/entry ownership and known-content attention semantics. A reorder is not a newly discovered species and does not create an unchecked-content event. Existing specimen/reference comparisons remain available for already-recorded specimens; the reference sample supplies a comparison, never a species census or discovery grid.

## Exact implementation examples

| Input | Required result |
|---|---|
| Empty discovery; active world secretly contains 12 creatures across all four habitats | No entries/volumes or creature total; static chapter labels are permitted |
| Habitat/shape aggregate contains a key but species has no firstSeen record | Ignore that orphan key for admission, search and counts |
| Ordinary encounter records a Water identity and an explicit piscine specimen before victory | Water → Fish-shaped; one kind, existing specimen detail available immediately |
| Same enemy later defeated; UI opened twice | No extra entry/specimen/count from opening or sorting; existing combat transaction owns any recording |
| Visible, unreachable swimmer with no recorded encounter | No new Bestiary row from sorting; remote-sighting implementation remains separate |
| Known Water identity; legacy specimen decodes missing shape as quadruped | Water → Shape not recorded, old measurements retained; never inferred Four-legged |
| Known identity has a trusted winged serpentine body but no saved habitat | Unclassified; do not infer Sky |
| Two trusted records of one Water identity, older serpentine then newer piscine | One Water → Fish-shaped entry; both retained specimens accessible; Latest recorded shape explains placement |
| Same known shape aggregate, all matching specimen rows later pruned | Same classification and one kind; neutral icon and no invented individual measurement |
| Legacy/unmarked record is later remembered after a trusted shape | Preserve trusted shape; the unknown sample cannot erase classification |
| Search names an undiscovered creature that exists in the current world | No match, no changed hidden count or category-volume hint |
| Previously known odd legacy body/habitat combination | Keep recorded habitat/shape; sorting does not regenerate or “repair” the animal |
| Specimen has strong armour or recorded Bone comparison | Existing comparison retained; no new likely-drop family or analyzed flag |
| Save/reopen, switch chapter, Back and reopen | Same admitted set, known classification and counts; no discovery mutation |

Focused verification should cover the admission filter, explicit-provenance decode/encode round trip, same-event knowledge recording, legacy fallback, pruning, distinct counts and hidden-cast invariance. One bounded mounted Library → Bestiary → chapter → body group → entry → Back/reopen check at the actual target iPhone/default text/current appearance is sufficient for this sorting slice. Reuse an isolated known-record fixture; do not spend Aimee's campaign, add a broad seed census, require final art or expand configuration testing.

## Remaining decisions

**Settled here:** known-record admission, saved-habitat grouping, explicit latest-recorded shape, safe legacy fallback, nonempty content groups, known-only counts/search and preserved measurement access.

**Unimplemented intended dependency:** a genuine distant-sighting record that does not become an individual specimen.

**Unsettled reveal proposals:** exact remote-sighting fields; a new analysis action or additional reveal tiers; when a future likely-material panel learns each family. Existing encounter and reward behavior does not authorize those additions.

The complete-player-experience Homework goal remains open pending implementation and playtesting. This contract is partial progress, not a claim that the Bestiary or whole creature rework is finished.
