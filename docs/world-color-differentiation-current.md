# World color differentiation — current design

**Status:** Current design boundary and priority · 11 August 2026  
**Owners:** Game Design defines meaning and acceptance; Asset proves the visual grammar in
AssetLab; Engineering integrates only a reviewed, versioned contract.  
**Why now:** Repeated worlds that share nearly the same overall color impression materially weaken
the authored-world fantasy and make playtesting feel repetitive.

## Player-facing goal

A newly entered world should have a recognizable material and atmospheric identity at phone size.
Its visual relationship to other worlds must reflect their relative authored and resolved diversity:
worlds with similar builds and relevant readings should look related, while worlds with meaningfully
different material, ecological, atmospheric or emitted-light facts should separate proportionally.
Difference must come from coherent relationships among ground, water, living color, atmosphere and
emitted light—not from washing every pixel with one tint or randomly recoloring individual tiles.

This is a **world identity system**, not a hidden-stat visualization. Color may express facts the
world legitimately resolved or the player explicitly authored, but it must not reveal undiscovered
content, exact pressure readings, hazards, rarity, passability or creature mechanics.

## Settled responsibility split

- **Material identity:** Thermal, Hydrology, Substrate/material facts and explicit material-color
  declarations select and adjust coherent terrain/water palette families.
- **Ecological identity:** Vitality affects legitimate species count, placement coverage, patch
  density, bounded stature and bounded saturation/richness within resolved flora colors. It never
  acts as a universal green channel.
- **Illumination:** Illumination controls current light, darkness, usable sight and light-source
  behavior. It is not stored terrain brightness and is removed from inherent world recoloring.
- **Emitter color:** A declared color on a Sun, Moon or other real emitter colors that emitter's
  visible light contribution without changing its intensity, radius, heat or danger.
- **Atmosphere color:** A declared color on a resolved visible medium colors scattering/haze. Color
  alone never invents smoke, opacity, toxicity or reduced sight.
- **Species and resource identity:** Flora keep stable species anatomy and palette relationships;
  canonical resources remain recognizable. World light may affect their presentation but cannot
  replace their identity colors.
- **Disclosure:** Unrevealed fog is invariant. The minimap remains symbolic and undiscovered POIs
  remain absent. Every rule-bearing distinction survives literal grayscale.

## World-grade-2 candidate

`world-grade-1.0.0` remains an immutable historical contract. The replacement must use a new
versioned descriptor, resolver and renderer tuple rather than silently changing anchored worlds.

The candidate combines three complementary mechanisms:

1. A stronger bounded transform derived only from eligible resolved material facts.
2. Deterministic selection among authored atmosphere/material palette families, so difference can
   change color relationships and saturation rather than only adding small RGB offsets.
3. Persisted, scoped named-color declarations attached to eligible written referents.

### Game-owned resolved inputs

Asset code does not invent a material or atmosphere family from mood. The versioned render request
consumes facts resolved and persisted by game rules:

- the actual ground/material family for each tile and the world's resolved material-palette recipe;
- eligible authored material sources and color qualifiers with stable Sigil identity;
- an explicit visible-atmosphere medium, if one exists, with its game-resolved density/clarity;
- actual current emitters and light contribution;
- the persisted flora cast with each species' exact traits/stature plus game-resolved coverage,
  patch topology and species placement; and
- permanent reveal/current visibility/disclosure fields.

Thermal, usable Hydrology and Substrate may help the **game resolver** select/adjust a coherent
material recipe. The renderer receives that recipe; it does not independently reinterpret pressure
readings into fictional matter or weather. Authored source identity may legitimately distinguish two
otherwise similar numeric profiles—for example Granite and Iron are different written material
facts—even when their aggregate Substrate reading is close.

The recipe distinguishes actual `materialIdentity` from a presentation `paletteFamilyID`.
Palette-family names must not assert nonexistent matter: a warm mineral relationship may be called
`warmMineral`, but not `emberstone` unless Emberstone is a real resolved material. An authored
Granite color applies to legitimate granite/substrate surfaces, not indiscriminately to water,
growth, people and every ground family. Cross-world coherence comes from compatible palette ramps
and later light/atmosphere composition, not pretending the entire map is one substance.

Atmosphere is stricter. Warm/dry facts do not create `dry haze`, and wet facts do not create
`marine haze`. Haze, mist, smoke, cloud, miasma or airborne ash requires an explicit resolved medium
owned by game rules. Without one, atmosphere is Clear/None. A future procedural weather system may
generate and persist such a medium, but AssetLab cannot add it as palette flavor.

Atmosphere medium, density/opacity and palette are separate fields. A palette-family ID does not
encode `dense`; game-resolved density owns scattering strength and current visibility/falloff, while
the palette/color declaration owns hue/chroma. Selecting Violet Smoke cannot make the smoke thicker.
Likewise multiple declarations are not fed through a generic RGB average. The first proof supports
at most one contribution per technical scope; later multiple emitters/material referents retain
separate contributions and use scope-specific composition rather than one whole-world mean.

Flora rendering never consumes a world-level `statureMedian` that resizes every species, and a
separate `speciesCount` does not mirror the cast. Count derives from the persisted cast; every
placement references one stable species whose own traits own stature, anatomy and base palette.
Vitality may legitimately lead game generation to a richer/larger cast and greater coverage, but
the renderer does not apply Vitality or a median as a post-generation scale multiplier.

The first proof should use a small reviewed named-swatch vocabulary. A freeform picker is deferred
until color naming, contrast, migration and color-space behavior are settled. Attachments resolve by
scope and specificity, never page order or an undisclosed random winner.

### Writing-model handoff candidate

The smallest live-compatible authorship shape adds a `color` qualifier ladder to the existing
`QualifierDef`/page grammar and projects its one selected stable color ID into an optional field on
the resolved `Sigil`. The color mark occupies its authored page footprint and connects to a source
like Intensity, Scale and Count; it is not a free no-space settings control. The existing one-rung-
per-ladder rule naturally permits at most one color on that source. A sigil already owns one specific
authored source, subject, intensity, scale and count, so color qualifies that thing rather than
becoming a page-global tint. Legacy decode uses `nil`, preserving neutral/default behavior.

The player does **not** select a technical `Emitter/Atmosphere/Material/Flora/Creature` enum. A closed,
versioned eligibility table derives the presentation scope from the authored referent and its valid
source/subject relationship, then the Writing Desk displays that derived scope in plain language.
Examples: Crimson Sun legitimately resolves emitted-light color; Violet Smoke resolves visible
atmosphere scattering; Ochre Granite/Substrate resolves material tendency; Blue Bloom/Flora resolves
an ecology tendency. A wrong or unsupported relationship is visibly rejected before placement/bind,
not accepted and silently treated as a global tint.

`Sigil.id` supplies stable authored-instance identity. Two separately placed colored Sun sigils are
two authored emitter contributions; Count produces several of the same qualified source. The first
slice permits at most one color qualifier per sigil. It therefore does not need an arbitrary
attachment graph, page-order precedence or same-referent multicolor mixing. Multiband/patterned
color remains a later explicit grammar if it proves worth its page and UI cost.

The first slice may qualify ordinary connected source marks. Existing self-contained compounds do
not silently inherit or ignore an adjacent color: compound-color eligibility requires a later
explicit rule for whether the qualifier applies to the compound's whole meaning or one expanded
source. Until that exists, the Desk rejects that attachment visibly. Whether basic color marks are
starter vocabulary, discovered pages or a mixed progression remains an open pacing decision; the
Asset proof does not decide acquisition.

The bound-world visual descriptor freezes resolved referents and their scoped color contributions,
including resolver/palette versions. Runtime rendering consumes that descriptor and does not reread
mutable catalogue ordering, reroll color, or infer scope from pixels. Writing preview and binding use
the same resolver result.

### First eligibility boundary

Eligibility is an authored semantic allowlist keyed by stable source ID, not a rule such as “anything
attached to Illumination is an emitter.” A source's incidental secondary contributions do not grant
color scope: Mirror affects illumination by reflection but is not a light emitter; Thin Air changes
visibility but is not a visible colored medium; Hush changes motion but is not a colored object.

The smallest proof allowlist exercises one unmistakable source per scope:

| Source | Derived scope | Plain-language preview |
|---|---|---|
| Sun | Emitter | “The Sun gives [color] light.” |
| Smoke | Atmosphere | “[Color] smoke scatters the light.” |
| Granite | Material | “The granite tends toward [color].” |
| Bloom | Flora ecology | “Blooms grow in [color] families.” |

The next review group is likely legitimate but must be checked source by source before live content:

- **Emitter:** Moon, Stars, Aurora, Magma, Wildfire and Meteor. Crystal needs an explicit decision
  between luminous emitter and colored material; its present illumination contribution alone is
  insufficient.
- **Atmosphere:** Mist, Cloud, Miasma and airborne Ash. Color describes the actual visible medium,
  never its danger. Thin Air, Wind, Hush, Stillness, Drift and Echo are not colored media.
- **Material:** Sand, Silt, Salt, Sulfur, Iron, Ice, Snow, Mercury, Amber, Chitin, Bone, Silk, Coral,
  Ruin and other concrete substances/forms. Canonical resource recognition and the distinction
  between “material color” and “colored light on material” require paired proof before Gold/Gold ore
  or other iconic resources are enabled.
- **Flora ecology:** Canopy, Fungus, Root, Thorn and Coral are plausible flora referents.
- **Creature ecology:** Swarm and Herd are plausible creature referents. Hive describes a
  structure/community and does not recolor every inhabitant by assumption.

**Current reversible recommendation:** keep Flora and Creature as distinct technical scopes beneath
the player-facing idea of living/ecological color. A colored Bloom influences generated flora
families only; it does not silently recolor animals. The first slice implements/proves Flora only.
Creature-scoped color waits for its own referent and species-identity proof rather than blocking
world-color progress.

Abstract or purely relational sources are rejected in the first slice. The rejection names the
reason (“Hush changes air movement; it is not a visible material to color”) and suggests no hidden
substitute. This table can expand as authored content, but an unknown source always rejects rather
than receiving a scope from target, contribution tags or catalogue order.

## Anti-repetition acceptance gates

Use at least twelve deterministic comparison worlds, including intentionally similar near-neighbor
pairs as well as neutral/unwritten, warm-dry, cool-wet, mineral-heavy, low-vitality, high-vitality,
and explicitly colored examples. Reuse map seeds where necessary to isolate palette differences.

The candidate passes only if:

1. **Relative visual distance:** in a blind, unlabeled native-phone contact sheet, deliberately
   opposed pairs are readily distinguishable by overall material/atmospheric impression, while
   intentionally similar near-neighbor pairs visibly belong to the same family. Difference in one
   accent tile alone is insufficient evidence for an opposed pair.
2. **Calibrated diversity:** compare a documented distance over the eligible authored/resolved input
   facts with a documented perceptual-distance metric over the rendered worlds. Greater meaningful
   input distance should generally produce greater visual distance; close inputs should not be
   forced apart for novelty. Two records with effectively identical meaningful visual facts may
   render identically; a different seed, world ID or expedition slot is not itself a visual fact.
   Design reviews the pairs because metrics are evidence, not authority.
3. **Coherence:** every world reads as a palette family. Adjacent ground types, water, flora and
   lighting belong to the same place without collapsing into a monochrome wash.
4. **Truth:** color changes do not alter geometry, placement, passability, depth, adjacency,
   elevation, content, fog, POI disclosure, species identity or game-rule outcomes.
5. **Recognition:** Gold, Copper, Raw Essence and other canonical identity accents remain
   recognizable across the most extreme accepted palettes.
6. **Accessibility:** ordinary, literal-grayscale and color-vision-deficiency evidence preserve
   water/deep-water, chasm, mud, growth height, route, selection, cracks and warnings.
7. **Persistence:** bind, save/load, anchored revisit and redraw reproduce identical resolved
   palette recipes and pixels. Legacy worlds use their recorded renderer tuple and do not drift.
8. **Neutral worlds remain truthful:** absence of explicit color declarations does not itself force
   sameness or variety. Worlds with similar resolved neutral facts may look similar; neutral worlds
   with meaningfully different material and atmosphere facts must not collapse into the same stable
   beige presentation. Any generated variation is deterministic, bounded and subordinate to facts.

## How to measure relative diversity

Do not collapse all eight pressure targets into one Euclidean number. Several pressures do not own
inherent color, and equal numeric changes can cross a categorical material threshold in one case but
remain within one family in another. Calibration uses **controlled pairs by visual layer**:

| Layer | Compare these resolved facts | Do not count as inherent-color distance |
|---|---|---|
| Material | Thermal centre and range where they legitimately affect material; usable Hydrology plus standing/flowing/frozen/airborne shares; Substrate magnitude, hard/ductile/volatile shares and explicit material declarations | Illumination, Vitality, Danger, Relief, Cycle, hidden sites/resources |
| Flora ecology | Persisted flora cast, resolved species color tendencies, coverage/patch budget, growth-height class and explicit flora declarations | Vitality as a green value; creature colors; undiscovered species mechanics; per-placement rerolls |
| Creature ecology | Persisted creature species color tendencies and explicit creature-producing declarations | Flora colors; encounter danger/stats; undiscovered exact species; per-specimen identity rerolls |
| Atmosphere | Explicit resolved visible medium, its density/clarity and scoped atmosphere color | Generic low clarity renamed as smoke; toxicity inferred from hue |
| Emitted light | Actual current emitters, phase/presence and their scoped colors | Stored terrain albedo; heat/danger inferred from color; illumination used as a palette offset |
| Current visibility | Rules-resolved ambient reach/falloff, obscuring medium and party light sources | Permanent reveal, minimap discovery or inherent world-color identity |

For each layer, construct ordered near/mid/far pairs while holding the other layers and map seed
fixed. Expected visual distance is monotonic **within that controlled family**, allowing deliberate
plateaus where several nearby inputs resolve to the same authored palette band. Crossing a legitimate
family/phase threshold may create a clear step. Do not demand a total ordering between incomparable
changes—for example, a large ecology change and a large substrate change can both be visually strong
without one being universally “more different.”

Then test several composed worlds to catch cancellation, muddy mixtures and one layer overwhelming
all others. The evidence report records:

- exact resolved facts used by each controlled pair;
- selected palette family and bounded adjustments;
- per-layer and whole-frame perceptual distances;
- whether Design judged the pair **too flat**, **proportionate**, or **too divergent**; and
- any plateau or threshold step, with the authored reason it exists.

This measurement is a calibration tool, not runtime behavior and not a player-visible analysis
screen. The renderer never computes novelty relative to prior campaign worlds and never changes a
world merely because another saved world looks similar.

## Smallest review proof

AssetLab should provide:

- an unlabeled native-phone map sheet for the twelve-world set, plus a keyed copy;
- color and literal-grayscale versions;
- the resolved recipe for each world (material family, derived adjustments, ecology tendency,
  emitters and atmosphere layers) without exposing that recipe in ordinary play;
- paired authored/resolved input distances alongside measured perceptual distances, including both
  near-neighbor and deliberately opposed pairs;
- paired worlds that change only one scoped declaration, proving local ownership;
- one daylight/dim/Torch sequence proving illumination composes after material color; and
- invariant hashes or structured comparisons for all rule-owned geometry and disclosure fields.

This proof is exploratory and does not authorize native integration. After visual review, Game
Design selects the palette-family breadth and acceptable strength; Engineering then reviews schema,
migration, cache and performance boundaries before implementation.

## Recommended implementation checkpoints after proof acceptance

These are separate review/install checkpoints, not one mega-change:

1. **Resolved visual descriptor + colorless world-grade-2:** game rules freeze actual material
   recipes, explicit atmosphere medium/none, flora outputs and renderer versions. The native map
   consumes the accepted relative-diversity palette families with no Illumination/Vitality terrain
   tint. Optional authored-color arrays exist but are empty. This is the first phone comparison.
2. **Colored-ink grammar:** add optional versioned CMY+Depth recipes on eligible source marks,
   Isolde's Scriptorium **Ink mixing** unlock, Desk preview/rejection and saved mixtures. Ash/nil
   invokes the bind-time random color resolver; explicit mixed black remains non-nil. Existing v2
   worlds remain pixel-stable; newly bound books freeze scoped contributions into their descriptor.
3. **Current light/visibility layer:** add rules-owned ambient reach/falloff, explicit obscuring
   media and Torch composition over permanent reveal. This layer does not revise material palette
   identity and can be tested independently in daylight/dim/true-dark states.

Legacy worlds that record world-grade-1 continue through its immutable compatibility renderer.
A page/book that has not yet been bound is not a persisted world and uses the current accepted
resolver when it is next bound, including in an older campaign. An already bound/anchored world's
visual tuple never silently upgrades. Cache keys include descriptor, palette resolver, renderer and
light-layer versions rather than relying on current app version.

## Still open for review

- Exact CMY+Depth conversion coefficients, readable patterns and ordinary preset recipes. Named
  swatches from the older proof remain gamut/accessibility fixtures, not learned game vocabulary.
- Exact authored material/atmosphere palette families.
- Fixed color space, blend modes, coefficients and perceptual-distance threshold.
- Creature-scoped color vocabulary and proof; the first slice uses the current reversible
  Flora/Creature split and implements/proves Flora only.
- Whether two colors on one referent resolve as a previewed mixture, an authored band/pattern, or
  are rejected until that referent supports multiple colors.

## Proof review log

### AssetLab world-grade-2 v0.1 — corrections required, 11 August 2026

The first exploratory sheet proves that stronger coherent material families and composed warm/cool
worlds can separate without destroying grayscale terrain grammar. The daylight/dim/Torch sequence
also supports keeping illumination as a later layer. It is not yet an accepted calibration proof:

- several “far” comparisons change numeric readings, palette family and authored color together;
  split derived adjustment, family threshold and authored declaration into separate controlled rows;
- atmosphere/emitter measurement rows are incorrectly labelled Material;
- White, Yellow and Violet emitter colors are categorical variants, not an ordinal near/mid/far
  ladder;
- authoritative scoped fixtures use Sun, Smoke, Granite and Bloom; Mist remains later-review only;
- raw Vitality must not be reinterpreted by Asset. Low/high ecology fixtures consume explicit
  game-resolved species count, coverage/patch budget, bounded stature distribution and richness;
- authored ecology color holds geometry constant, while legitimately different resolved ecology is
  expected to change flora coverage/placement geometry; and
- the evidence needs explicit controlled input-distance values alongside output perceptual distance.

Material near/mid separation is provisionally proportionate; the opposed composed pair is clearly
distinct; literal grayscale remains readable. Violet atmospheric/emitter strength stays undecided
until isolated-layer fixtures show whether it reads as colored light/haze rather than a global wash.
