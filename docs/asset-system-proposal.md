# Asset System Proposal

**Status:** Proposal for review by Aimee, the game-design lead, and the engineering lead  
**Owner:** Asset lead  
**Started:** 8 Aug 2026  
**Scope boundary:** This document and the future standalone asset systems/tools are owned by the
asset lead. The asset lead does **not** change game code. The engineering lead owns integration into
the app.

## Purpose

Replace the current SF Symbol and flat-colour placeholders with a coherent 2D pixel-art system that
can represent the game's generated worlds without requiring a unique hand-drawn sprite for every
possible result.

The system must support:

- base-world architecture in different materials, colours, designs, and construction states;
- terrain and world features;
- generated flora;
- generated creatures and hostile flora;
- named and generated characters;
- small world-view sprites for creatures and characters;
- larger fight-view sprites for creatures and characters;
- world-entry and world-exit splash screens;
- standalone tools for authoring, testing, comparing, and exporting pixel art outside the game.

The intended result is **authored procedural art**: artists make deliberate parts, silhouettes,
palettes, masks, and composition rules; deterministic tools combine them. It is not runtime
text-to-image generation.

## Design principles

### The world should look like what the player wrote

Visual variation must derive from the same pressures and traits that drive terrain, ecology,
combat, naming, and loot. Art is another readable consequence of authorship, not a cosmetic roll
unrelated to the simulation.

### One identity, several views

A creature, plant, building, or character should have one stable visual identity expressed through
several render profiles. A creature's map sprite, combat sprite, bestiary image, and splash-screen
appearance should unmistakably depict the same being.

### Silhouette before surface detail

At world-map scale, appendages, stature, build, armament, and posture must carry identity. Colour
and texture support recognition but cannot be the only distinction, including for accessibility and
small-screen legibility.

### Deterministic and versioned

The same visual descriptor, seed, generator version, and asset-library version must produce the
same pixels. Generator changes must be explicit and reviewable. The game should never need to save
rendered images as canonical game state.

### Pixel art is a constrained medium

All output uses fixed native resolutions, integer coordinates, indexed palettes, nearest-neighbour
scaling, and no accidental anti-aliasing. Effects must be designed at pixel scale rather than added
as arbitrary high-resolution filters.

### Discovery remains meaningful

The visual system must respect the game's information rules. Unknown creatures can be represented
by silhouettes or incomplete readings where appropriate. Art must not reveal traits the player's
analysis level is intended to conceal.

## Proposed system architecture

```text
game data / authoring fixture
          |
          v
Visual Descriptor  -- stable, serializable handoff contract
          |
          v
Visual Grammar  -- trait-to-shape, palette, material, and composition rules
          |
          v
Pixel Compositor  -- deterministic layers, masks, sockets, and palette operations
          |
          +--> world sprite
          +--> fight sprite
          +--> portrait / bestiary sprite
          +--> splash-screen elements
          +--> architecture / terrain variants
          |
          v
exported atlas + manifest + contact sheets
```

### 1. Visual descriptors

Descriptors are the boundary between the game and the asset system. They should contain only the
visual facts needed to render an identity, expressed in an implementation-neutral data format such
as JSON.

Proposed descriptor families:

- `WorldVisualDescriptor`
- `TerrainVisualDescriptor`
- `FloraVisualDescriptor`
- `CreatureVisualDescriptor`
- `CharacterVisualDescriptor`
- `ArchitectureVisualDescriptor`
- `SplashVisualDescriptor`

Each descriptor includes a stable identity, seed, render profile, generator version, and the visual
attributes relevant to that family. The asset tools should also accept hand-authored fixture files,
so the asset lead does not require the running game to test designs.

The exact translation from Swift game models into these descriptors belongs to engineering. The
asset lead will specify and maintain the descriptor schema and supply fixtures and expected output.

### 2. Visual grammar

The visual grammar turns descriptive attributes into visible decisions. It should be data-driven
wherever practical, allowing the asset lead to tune mappings without editing the game.

Examples:

- creature `appendageType` and `appendageCount` select body sockets and silhouette modules;
- `build` changes torso proportions and stance;
- covering hardness, length, and coverage select edge language and texture masks;
- pierce, crush, and rend armament add visibly different anatomy;
- coloration chooses indexed palette ramps rather than applying a tint over finished art;
- finish changes authored highlight/dither patterns;
- emanation adds a controlled emissive layer and may influence the local palette;
- flora stature selects groundcover, shrub, or canopy construction;
- flora tissue changes trunk, fibre, or fleshy mass language;
- flora habit controls how multiple instances compose into a tile or splash layer;
- architecture station type determines function silhouette while world/base style and material
  determine its construction language.

Mappings need authored thresholds, exceptions, and incompatibility rules. Purely averaging every
attribute will produce visual mush, just as blending every ecological defence would.

### 3. Pixel compositor

The compositor combines authored assets using:

- named layers;
- attachment sockets;
- masks and cut-outs;
- indexed palette substitution;
- integer transforms approved per asset family;
- deterministic variant selection;
- authored overlap and occlusion rules;
- optional one- or two-frame idle/combat animation support;
- validation for canvas bounds, palette limits, missing sockets, and orphaned assets.

The first implementation should favour clarity and inspectability over sophisticated procedural
deformation. Modular pixel parts drawn for known sockets will preserve the medium better than
arbitrary scaling or warping.

### 4. Registry, export, and integration handoff

The standalone pipeline should export conventional assets the game can consume:

- PNG sprite sheets or atlases with transparent backgrounds;
- JSON manifests describing frames, pivots, sockets, logical identities, versions, and palettes;
- optional individual PNGs for debugging;
- contact sheets for human review;
- canonical fixture outputs for regression tests.

Whether the final game renders descriptors on demand, pre-bakes encountered identities, or consumes
a hybrid cache is an engineering decision to make after a prototype establishes generation cost and
package size. The descriptor and output formats should support all three approaches.

## Asset families

### Terrain and world features

The starting terrain vocabulary in the game is stone, soil, sand, ice, ash, water, deep water,
rubble, mud, tall growth, groundcover, and chasm. The terrain system additionally needs elevation,
fog, revealed/unrevealed treatment, hazards, portals, sites, resources, cracking, and crumble/void.

Terrain should use a small family of compatible tile grammars rather than isolated square icons.
Transitions and adjacency will matter, especially for water, shore, chasm, growth, paths, and built
structures. The authored-world pressures should influence palette, texture density, weathering, and
ambient treatment without making rules-critical terrain unreadable.

### Flora

Flora has especially strong generation inputs already: stature, tissue amount and mixture, defence,
defence type, habit, coloration, finish, and metabolism. These can form a visual genome directly.

Required views:

- tile-scale individual or patch;
- harvest/detail or bestiary-scale view;
- fight view for active-defence flora;
- splash-screen foreground and midground elements.

No per-tile genetic jitter is proposed. A world's flora cast should define recognizable species;
spatial arrangement supplies environmental variation.

### Creatures

Creature traits already describe size, build, covering, bone density, appendages, armament,
coloration, finish, senses, and emanation. These should determine anatomy and material appearance.

Required views:

- world silhouette/sprite;
- fight pose;
- bestiary/analysis presentation;
- optional splash-screen pose for prominent or apex creatures.

Individual specimen jitter should remain subordinate to species recognition. Apexes may use the
same grammar with exceptional scale, composition, or framing rather than becoming unrelated
one-off art.

### Characters

Named travellers need authored identity on top of a modular character system. Calling, personality,
body, hair, clothing, carried tools, equipment, and palette can be composed, but named characters
should receive deliberate art-direction passes and locked signature features.

Generated companions can use the same body/clothing/equipment grammar with deterministic seeds.
Equipment overlays should be designed only where they remain legible and do not erase character
identity.

Required views:

- world sprite;
- fight pose;
- meeting/roster portrait or bust, if approved by design;
- optional station-working pose or architecture vignette later.

### Base architecture

Architecture has two simultaneous jobs: communicate station function and make the base feel like a
place built from the player's history.

Proposed axes:

- station identity and function;
- construction tier/state;
- primary and secondary material;
- regional or authored-world architectural influence;
- palette;
- age, repair, and weathering;
- traveller-specific signature details;
- surrounding props and flora.

Function silhouette should remain stable across skins. A forge should read as a forge before its
material variant is inspected.

### World-entry and world-exit splashes

Splashes should be deterministic scene compositions made from the same world descriptor and asset
library, not separately invented illustrations.

An entry splash can communicate dominant terrain, light, atmosphere, characteristic flora, a site
or distant creature, and the world's initial stability. It should feel like opening the book into a
place.

An exit splash should reuse that world's identity while reflecting the outcome:

- ordinary return from an unanchored world: departure without implying that the realm persists;
- emergency/pass-out return: impaired retreat;
- collapse: the same scene breaking apart;
- anchored-world departure: continuity and an expected return.

The splash compositor may use more layers and larger assets than gameplay sprites, but must retain
the same palettes, silhouettes, and visual genome.

## Standalone Asset Lab

The Asset Lab should be a separate authoring and validation application or tool suite. It must not
depend on modifying or launching the game.

Minimum capabilities:

- open and save descriptor fixtures;
- browse all authored parts, palettes, and rule mappings;
- change every descriptor field with immediate preview;
- randomize unlocked fields while locking selected fields;
- reroll seeds;
- display world, fight, portrait, and splash profiles together;
- preview at native size and common integer scales;
- simulate light/dark UI surroundings and representative terrain backgrounds;
- compare variants side by side;
- show layer, socket, palette, and descriptor diagnostics;
- export PNGs, atlases, manifests, and contact sheets;
- batch-render canonical and random fixtures;
- flag clipped pixels, invalid colours, accidental alpha, missing parts, and nondeterministic output;
- preserve provenance: tool version, generator version, library version, descriptor, and seed.

Useful later capabilities:

- pixel editor for small corrections and new parts;
- palette-ramp editor;
- animation timeline;
- adjacency/tile-rule preview;
- simulated colour-vision checks;
- visual-difference review between generator versions;
- curated "keep/reject" boards for generated variants;
- promotion of a generated result into an authored exception.

The first vertical slice should prove the workflow with one terrain family, one flora species, and
one creature rendered consistently in world and fight views. It should export a manifest that the
engineering lead can inspect without integrating it.

## Quality and validation

Every generator release should produce:

- a canonical contact sheet from fixed descriptors and seeds;
- a diversity sheet from a fixed batch of varied seeds;
- native-scale legibility previews;
- deterministic hash checks;
- schema validation results;
- an output manifest recording all versions;
- a short visual-change note when canonical pixels change.

Review should ask both whether individual sprites look good and whether the population has the right
distribution. A generator can make attractive individuals while producing an ecosystem of near
duplicates or incoherent noise.

## Proposed phases

### Phase 0 — art-direction and technical proof

- Set native resolutions, viewpoints, palette constraints, outline rules, and animation ambitions.
- Define descriptor schema v0.
- Build the smallest compositor and Asset Lab shell.
- Prove terrain + one flora + one creature across world and fight views.

### Phase 1 — world visual foundation

- Terrain families and transitions.
- World palette derivation.
- Fog, elevation, hazards, portals, sites, cracking, and collapse.
- Initial entry/exit splash composition.

### Phase 2 — living generators

- Flora grammar and tissue/defence/metabolism families.
- Creature anatomy grammar and world/fight/bestiary profiles.
- Batch diversity and canonical regression suites.

### Phase 3 — people and base

- Modular generated companions.
- Authored named-traveller identities.
- Architecture grammar, station tiers, and material variants.
- Base composition studies.

### Phase 4 — breadth and polish

- Equipment overlays and animation expansion.
- Apex presentation.
- More splash compositions.
- Authored exceptions and rare visual events.
- Performance/package-size handoff tests with engineering.

## Proposed decisions for review

These are recommendations, not settled decisions.

1. Use deterministic authored procedural composition, not runtime generative AI.
2. Use a neutral JSON descriptor contract between game and asset pipeline.
3. Keep the Asset Lab independent of the game project.
4. Treat world, fight, portrait, and splash art as render profiles of one visual identity.
5. Use indexed palette substitution and authored pixel modules instead of arbitrary tinting,
   scaling, or deformation.
6. Store identity inputs and versions as canonical data; treat rendered PNGs as reproducible output
   or cache.
7. Begin with a deliberately tiny vertical slice before choosing a complete content-production
   architecture.

## Open questions

### For Aimee and game design

1. What camera language should each view use: top-down, three-quarter, side-on, or a deliberate mix?
2. What native resolutions feel right for world, fight, portrait, architecture, and splash assets?
3. How detailed and animated should combat be: static posed sprites, short idle/attack reactions, or
   fuller animation?
4. What is the desired overall visual mood and lineage? Which games or artists are useful positive
   references, and which should be avoided?
5. Should the base share one coherent architecture, visibly accumulate styles from authored worlds,
   or allow the player to choose a style?
6. Are world palettes allowed to become extremely strange, or should all generated palettes remain
   within a controlled cozy/readable envelope?
7. How much visual information should analysis unlock in the bestiary and previews?
8. Do named travellers need portraits/busts in addition to world and combat sprites?
9. Should splash screens be full-screen scenes, framed book illustrations, or page-like tableaux?
10. How visibly should procedural variation distinguish individual specimens within one species?

### For engineering

1. Which neutral descriptor and manifest formats are easiest to validate and consume from Swift?
2. Does the app ultimately prefer pre-baked atlases, generated-on-demand PNGs, or a hybrid cache?
3. What texture-size, memory, package-size, and render-time budgets should the tools target?
4. What stable identifiers and version fields are required so an in-progress save never changes
   appearance unexpectedly?
5. Which game properties should be translated into descriptors versus left as asset-system-derived
   secondary properties?
6. What atlas metadata does SwiftUI—or a possible later rendering layer—need for pivots, frames,
   animation, and nearest-neighbour presentation?
7. What accessibility and display-scale requirements must exported assets anticipate?
8. Can engineering supply sanitized JSON fixtures representing representative and extreme worlds,
   flora, creatures, characters, and stations without coupling the Asset Lab to Swift code?

## Decision log

### 8 Aug 2026 — ownership and integration boundary

- Aimee assigned a separate asset-lead role.
- The asset lead will not modify game code.
- Asset systems and authoring tools will be developed separately.
- The engineering lead will integrate approved outputs/contracts into the game.
- Asset questions and decisions will be maintained in this document in `docs/`.

### 8 Aug 2026 — primary environment camera split

- **The home village/base uses a 2D side view.** It is not top-down or isometric.
- **Explorable generated worlds use a top-down view.** Their square-grid navigation remains the
  primary spatial language.
- This settles the broad camera split, not the exact pixel projection, native resolutions, sprite
  proportions, layering rules, or whether world sprites use a slight illustrative bias to expose
  recognizable features.

## Review log

Feedback from Aimee, the game-design lead, and the engineering lead should be recorded here with the
date, reviewer, recommendation, and disposition. A proposal becomes settled only when Aimee or the
appropriate design authority approves it; implementation convenience alone does not settle visual
design.

### 8 Aug 2026 — game-design lead review

**Disposition:** recommendations unless explicitly labelled as an existing settled constraint. This
review does not approve native resolutions, final viewpoints, portrait scope or a complete visual
style; those need Aimee's review through contact sheets and camera studies.

#### Recommended visual language and camera

- Use the settled mixed camera language: navigable **worlds are top-down** and the **home base is a
  2D side view**. They should share palette and pixel-language principles without pretending to share
  projection. **Combat** should use a shallow side-on or side-biased three-quarter stage because
  ranks, reach, who can reach whom and front/back protection are rules-critical. Portraits may use
  authored three-quarter busts without pretending to share gameplay projection.
- Decide projection before native resolution. Phase 0 should compare a small number of fixed camera
  and pixel-density contact sheets at actual iPhone display sizes; an attractive enlarged sprite is
  not evidence that its native-scale silhouette works.
- Begin combat with restrained animation: readable idle, anticipation/attack and impact/reaction
  states, plus rules-critical conditions. Fuller locomotion and bespoke sequences should wait until
  the static combat composition proves that ranks and targets are immediately legible.
- Add a distinct **minimap render profile**. **Settled constraint:** the world screen is intended to
  have a minimap beneath navigation. The minimap should use stable symbolic terrain, route, portal,
  discovered-site and party markers—not scaled-down living sprites—and must obey fog/reveal state.

#### Recommended disclosure rules

- Do not render every unknown creature as an undifferentiated silhouette once it is plainly visible.
  Physical anatomy a player can see—size, posture, appendages, covering and obvious armament—should
  remain visible. Analysis should conceal names, numbers, inferred functions, internal traits,
  weaknesses and unobserved behaviours. Discovery is strengthened by looking and forming hypotheses,
  not by withholding the image itself.
- Apply the same distinction to flora. Visible stature, tissue, coloration and finish may be shown;
  metabolism and active defence remain unknown until observed, triggered or analysed. A harmless-
  looking defence may be authored deception, but the renderer must not reveal its rules label.
- Treat disclosure as a presentation policy, as engineering recommends, rather than changing the
  canonical identity. World sprites, combat presentation, bestiary art and text overlays may expose
  different subsets while depicting the same being.
- Before binding/entry, visual previews may show only authored inputs and consequences the existing
  generation UI intentionally predicts. They should not reveal rolled sites, resources, species,
  traveller presence or other generated surprises.
- **Settled constraint:** apex locations may be marked from world entry, but apex identity is learned
  through encounter. Entry splashes and distant silhouettes must therefore not make an unseen apex
  uniquely identifiable.
- Rules-critical information should never depend on palette alone. Hazard, impassability, current
  emanation, reach state and active defence need shape, motion, icon or contrast support consistent
  with the UI's eventual disclosure rules.

#### Recommended world and palette identity

- Interpret “the world should look like what the player wrote” as **the world should visibly follow
  the resolved simulation**. Written focuses establish pressures, while generated terrain, ecology,
  weather and creatures express their consequences. Avoid stamping literal rune motifs across the
  scenery or making every requested parameter visually dominant regardless of the resolved world.
- Keep navigable terrain inside a controlled readable envelope, with stable value separation for
  movement and hazards. Extreme worlds may become strange through localized palette accents,
  atmosphere, light, emanation and unusual material relationships; they should not make the entire
  playfield illegible or visually punishing merely to prove extremity.
- Reserve the strangest palette events for meaningful phenomena such as emanation, instability,
  apex presence or rare world structure. If everything in a high-value world glows or hue-shifts,
  none of those signals can carry information.
- Species identity should dominate specimen variation. Use bounded differences such as stature,
  minor markings, wear or scars only where they cannot imply generated mechanical traits the specimen
  does not possess. Apex variation may change framing and scale while preserving the underlying
  species grammar.

#### Recommended base identity

- Give the base one coherent, recognizable architectural substrate so it reads as home across a long
  campaign. Let the player's history accumulate through **materials, repairs, traveller-specific
  work areas, props, planted flora and selected accents** rather than turning every station into an
  unrelated imported architectural style.
- Station function must remain stable before surface variation, as the proposal states. Higher tiers
  and construction states should communicate actual player progress. Do not use abandoned, decayed
  or failing visuals that imply wall-clock deterioration or unpaid upkeep unless the settled base
  systems actually create those states.
- Do not add a full base-style selector in the first asset pass. Material choices already provide
  player expression and connect architecture to recovered world resources. A broader style-choice
  feature can be considered after one coherent base language is proven.
- Named travellers should leave small authored signatures at their stations without making those
  spaces inaccessible when the traveller is in the party. The building belongs to the base loop;
  personal detail communicates stewardship rather than requiring the person to be physically posted.

#### Recommended splash-screen fiction

- Use **framed book illustrations or page-like tableaux** rather than borderless cinematic shots.
  Entry should feel like a bound possibility becoming inhabitable, while retaining enough scene depth
  to establish atmosphere. The frame can open, fill or destabilize without implying that the world is
  merely a flat illustration.
- Build entry splashes only from information available at entry: dominant revealed terrain, light,
  weather and non-spoiling ecological shapes. Do not select an undiscovered site, resource, traveller
  or identifiable rare creature merely because the complete descriptor knows it exists.
- Exit splashes should depict the **world's actual lifecycle state**, not use “player left” as a
  synonym for “world survived” or “world ended.” Ordinary portal return, emergency retreat, expiry/
  collapse and eventual anchored departure need distinct compositions.
- Anchoring now has current lifecycle rules in `anchoring-system-current.md`: three routes create the
  same permanent realm, dormancy preserves it, and tether imagery is retired. The splash grammar may
  depict anchoring and continuity from those rules. Reality reset remains unsettled and must not be
  canonized visually.
- Emergency/pass-out return should communicate loss of control without visually punishing or
  humiliating the player. Collapse should reuse recognisable scene geometry so the loss concerns this
  particular world rather than becoming a generic explosion.

#### Recommended portraits and authored characters

- Named-traveller portraits are recommended for meeting, diary and roster presentation because the
  cast is authored and relationship-heavy. They are not required for the first vertical slice and
  should not block terrain/flora/creature proof work.
- Generated companions may use the modular portrait grammar. Named travellers need locked silhouette,
  face/hair, palette and calling details plus an art-direction pass; procedural composition should be
  a production base, not the final authority over their identity.
- Equipment overlays must not replace the character's locked signature features or cause a traveller
  to become visually unrecognizable when their build changes.

#### Conflicts and additions to resolve in the main proposal

- Add `MinimapVisualDescriptor` or, preferably under engineering's split-contract recommendation, a
  **minimap render request/profile** with its own symbolic grammar.
- Revise “unknown creatures can be represented by silhouettes” so it does not imply that analysis
  gates plainly visible anatomy.
- Revise the entry-splash example that includes “a site or distant creature” to require disclosure-
  safe selection.
- “Portal return: departure with the world intact” has been revised. Anchored continuity may now be
  asserted only when the world is actually anchored.
- Architecture's “regional or authored-world influence” should mean accumulated materials and
  selected accents by default, not wholesale style copying from generated worlds.

### 8 Aug 2026 — engineering lead review

**Disposition:** recommendations only. None of the points below are settled visual-design
decisions; the ownership boundary in the Decision log remains the only settled item from this
review.

#### Recommended contract boundaries

- Split the proposed descriptor into two contracts: a stable **identity descriptor** containing
  only game-derived visual facts and seed, and a **render request** containing profile, native
  resolution and requested output. A map sprite and portrait should not become separate canonical
  identities merely because they use different profiles.
- Do not put asset-part IDs, layer names, sockets, palette-ramp IDs or grammar-derived secondary
  choices into game-produced descriptors. Those belong to the asset library/grammar and may evolve
  without changing Swift game models. Authored exceptions may be a single optional stable override
  key, resolved entirely by the asset pipeline.
- Treat the export manifest—not compositor internals—as the app-facing boundary. Each output entry
  should minimally carry `logicalID`, profile, pixel dimensions, scale (normally 1), frame rect,
  pivot/anchor, frame duration where animated, content hash, and the complete version tuple.
- Publish JSON Schema files for descriptors and manifests. Use strings for IDs/enums and integers
  for seeds and pixel geometry; avoid unbounded JSON numbers for trait values. Specify ranges,
  defaults, unknown-field policy, enum-extension policy, coordinate origin and rectangle semantics.
  Engineering should generate/validate Swift fixtures against the schemas rather than duplicate
  the contract informally.

#### Recommended deterministic versioning

- Define reproducibility as the tuple `(descriptorSchemaVersion, identityDescriptor, seed,
  grammarVersion, compositorVersion, assetLibraryVersion, renderProfileVersion)`. A single
  `generatorVersion` is too coarse to diagnose why pixels changed.
- Version fields should be immutable content IDs or hashes, not mutable labels such as `latest`.
  Canonical JSON encoding must be specified before hashing (sorted keys, normalized numbers and no
  insignificant whitespace). Hash decoded pixel bytes plus dimensions/profile for output checks;
  do not hash PNG file bytes alone because encoder metadata can change without changing pixels.
- A save should eventually retain the identity descriptor (or sufficient game facts to recreate it)
  and the selected version tuple for encountered persistent identities. New discoveries may use a
  newer default; existing creatures/characters should not silently change appearance after an app
  update. The exact migration/re-render policy needs Aimee's approval before integration.

#### Recommended formats and Swift constraints

- Keep indexed source art in the Asset Lab, but export standard 8-bit sRGB RGBA PNGs with straight,
  well-defined alpha for iOS. Do not rely on iOS preserving indexed-palette data at runtime.
- Export integer pixel rectangles and pivots in top-left pixel coordinates. Avoid normalized floats.
  Require padding/extrusion around atlas frames to prevent neighbour bleeding.
- SwiftUI's `Image` is straightforward for individual PNGs but is not an atlas/sprite renderer.
  Cropping/animation will require Core Graphics, `Canvas`, SpriteKit, Metal, or generated individual
  frame images. The Phase-0 handoff should therefore include individual PNGs as the reference path;
  atlas adoption should wait for measured evidence that it is worthwhile.
- Export no `@2x`/`@3x` reinterpretation of native art unless the manifest explicitly distinguishes
  logical and native size. Integration must use nearest-neighbour interpolation, integer display
  scaling where practical, and pixel-aligned placement. Test both Retina scales because point-space
  layout can otherwise land pixels between device pixels.

#### Recommended cache/prebake approach

- Prototype a hybrid: bundle the small shared terrain/UI vocabulary and authored named-character
  assets; generate or download descriptor-specific living identities into a version-keyed cache.
  Do not choose runtime generation, full prebaking, or atlas-only packaging until the vertical slice
  measures cold render time, peak memory, decoded texture cost, install size and cache churn.
- Cache keys must include the full version tuple, profile and native dimensions. Writes should be
  atomic, generated off the main actor, bounded by an explicit byte/entry policy, and safely
  disposable because descriptors—not PNGs—are canonical. Failed generation needs a bundled
  deterministic placeholder rather than a missing image or blocked game screen.
- Consider a build-time/prewarm path for worlds about to be entered and combat profiles for the
  world's known cast. Generating synchronously while SwiftUI lays out a map or encounter is not an
  acceptable integration path even if individual renders appear fast in the Asset Lab.

#### Recommended fixtures and verification

- Asset lead owns schema-valid fixtures and golden outputs. Engineering should additionally export
  **sanitized descriptor fixtures** from real game models: ordinary, boundary-threshold and extreme
  values; old-save defaults; every enum case; one unknown/future enum fixture; and fixed seeds for
  world/flora/creature/character/station families.
- Keep three test layers: schema/manifest contract tests, deterministic decoded-pixel hashes, and
  human-reviewed contact sheets. Golden-image diffs should report changed-pixel count/bounds and
  provide an overlay; they should never auto-approve aesthetic changes.
- Add integration fixtures for malformed manifests, missing frames, duplicate logical IDs, wrong
  dimensions, unsupported versions and cache corruption. The game must fail soft to the placeholder
  while recording a diagnostic.

#### Principal engineering risks to prototype early

- Descriptor drift: game traits and asset schemas may evolve independently. An explicit adapter and
  schema compatibility matrix are safer than making Swift game models conform directly to an asset
  schema.
- Information leakage: one identity descriptor may contain facts the player has not learned. The
  renderer may use them for the world sprite, while analysis/bestiary presentation must be selected
  by a separate disclosure policy; do not redact the canonical identity differently per screen.
- Combinatorial holes: valid game trait combinations may have no compatible parts/sockets. The lab
  needs exhaustive boundary sampling plus deterministic fallbacks, not only random attractive
  examples.
- Texture cost: PNG install size understates decoded memory. Large portraits/splashes and many
  individual creature profiles can exceed memory long before the package looks large on disk.
- Colour and filtering variance: sRGB tagging, premultiplication, interpolation and non-integer
  SwiftUI transforms can alter reviewed pixels. The vertical slice must compare on-device captures
  at supported display scales, not only Asset Lab output.
- Asset-library upgrades can invalidate a large cache at once. Version-aware garbage collection and
  prewarming need to be included in performance measurements.

#### Items requiring design authority before becoming decisions

- Whether previously encountered identities are visually frozen forever or may opt into an
  approved remaster/migration.
- Native resolutions, viewpoints, palette limits, animation scope and whether portraits exist.
- Which visual traits may be visible before analysis unlocks them.
- Whether the base accumulates authored-world styles or uses one selected/coherent style.

### 9 Aug 2026 — AssetLab species/specimen milestone design review

**Disposition:** recommendations only. These constrain the next visual proof but do not settle
art direction, disclosure thresholds or production integration.

#### Species and specimen semantics

- The species/specimen split is framed correctly. `speciesSeed` should own the recognizable centre:
  silhouette, topology, appendage plan, covering family, armament grammar, core palette family and
  the visual form of any emanation. `specimenSeed` should produce bounded differences such as minor
  markings, pose, slight proportion variation, wear or scars. It must not change apparent locomotion,
  armament, defence branch, sense type or another generated mechanical fact.
- Use the ecosystem-diversity sheet to test separation between species centres and the
  species-consistency sheet to test recognition within one centre. Passing one does not substitute
  for passing the other. Include mixed silhouettes at native world scale, where accidental sameness
  is most costly.
- Avoid describing seeded colour drift as specimen coloration unless it is actually driven by
  `specimenSeed`; species-seeded palette drift belongs to species identity. Individual colour
  variation, if added, should remain inside a narrow authored species ramp.

#### Visible facts versus disclosure leakage

- Render plainly visible anatomy honestly: size, posture, appendages, covering, obvious armament,
  translucency and conspicuous coloration do not need to wait for analysis. What remains concealed
  is the system's name, exact allocation, inferred function, trigger, weakness and combat effect.
- True opacity is appropriate as material appearance, but it must not become a hidden accuracy or
  targeting rule. Once the simulation says a creature is detected and targetable, the combat/map
  presentation needs a disclosure-neutral readability aid such as grounding, outline or selection
  treatment. Do not expose a numeric opacity or label it as crypsis merely because it is visible.
- Sensory anatomy may be suggested without using one universal cyan mark that decodes the dominant
  normalized sense. Different species grammars can express eyes, antennae, pits, cilia or less
  terrestrial apparatus; the UI should not name their function or percentages before observation.
- Physical armour and warning colour may be visually apparent, but the renderer should not directly
  announce `armour`, `speed`, `crypsis`, `aposematism`, toxicity, resistance or an active defence.
  In particular, standardized stripes, motion marks and defence-specific icons risk becoming a
  mechanical legend. Treat them as species-specific appearance, and reserve rules labels and exact
  outcomes for the disclosure layer.
- Keep one canonical identity descriptor. A separate render/disclosure request should control which
  labels, annotations or UI affordances are permitted; do not mutate the creature's identity to make
  an undiscovered version.

#### Constraints for the flora/terrain descriptor milestone

- Flora species identity should be stable across a world. Let patch composition, pose and placement
  create local variety; do not introduce per-tile genetic jitter that changes stature, tissue,
  defence, colour family or other mechanical traits. If a specimen seed is retained for flora, limit
  it to non-semantic arrangement.
- A flora identity descriptor may carry game-derived facts such as stature, tissue mixture, growth
  habit, covering/defence amount, colour/finish and emanation. It should not carry asset-part IDs or
  disclose mechanical names in player-facing output. The grammar must distinguish groundcover, tall
  growth and combat-capable flora at native scale.
- A terrain render request should derive from resolved world and tile facts: terrain kind, elevation,
  adjacency, wetness/mud, growth or flora identity, hazards, reveal/fog state, light and atmosphere.
  Use world/terrain seed plus tile coordinates for deterministic surface variety while adjacency and
  value structure preserve a coherent world identity.
- Prioritize rule readability over palette novelty. Water/deep water, mud, rubble, tall growth,
  groundcover and chasm/void need redundant shape/value cues; resources, sites, portals, apexes and
  other discoveries appear only when game reveal state permits. The same symbolic distinctions need
  a dedicated minimap profile rather than a reduced decorative tile.
- The next proof should show one terrain family with edge/transition cases and one flora species
  across tile, detail and fight profiles where applicable. Review at native phone scale in revealed,
  unrevealed, selected and extreme-descriptor states, with deterministic contact sheets and bounds
  checks. This is a stronger milestone than broadening to many attractive but disconnected tiles.

### 9 Aug 2026 — flora/terrain proof visual-semantics review

**Disposition:** recommendations only. The proof was inspected at native map scale and across a
default woody/clustered species and a low, fleshy, spreading, active-defence extreme. No AssetLab or
game code was changed in this review.

#### What the proof now establishes

- Separate flora identity and terrain render inputs are the right boundary. Stable species pixels
  across placement inputs match the settled rule that a world's small flora cast supplies identity
  while spatial composition supplies environmental variation.
- The top-down world profile, larger detail/hostile profile, full cardinal adjacency sheet and
  symbolic minimap are all appropriate proof surfaces. Bounds and deterministic fuzz results are
  strong technical evidence; visual meaning still needs the semantic checks below.
- Removing direct creature sense/defence badges was correct. Visible anatomy can invite inference
  without the asset becoming a rules legend.

#### Flora grammar recommendations

- Strengthen **plant grounding**. The default 16×16 woody form currently risks reading as a small
  quadruped because several straight supports hang beneath a horizontal body; the 48×48 form risks
  reading as a palisade. Prefer rooted contact, branching from a shared base, irregular botanical
  mass and vertical overlap over bilateral “body plus legs” construction.
- Habit must govern **patch topology**, not only density or sprite width: spreading should form
  connected swathes, clustered should form thickets with gaps, and solitary should place separated
  individuals. This is rules-relevant because the live flora system uses habit to reshape
  navigability, while stature decides groundcover versus sight-blocking tall growth.
- Do not use one stable warning hue or appendage as a direct defence-type badge. Physical structures
  and conspicuous chemistry may be visible, but `active` must remain unknown until it triggers or is
  analysed. Split the current combined **detail / hostile fight** proof into a neutral detail pose
  and a triggered fight pose; only the latter may reveal active movement/attack anatomy.
- Metabolism may shape plausible visible relationships—leaf-like collection surfaces, fungal mass,
  mineral association—but should not become an exact photosynthetic/fungal/chemosynthetic colour
  code. The renderer may use canonical facts while disclosure policy withholds their names and exact
  functions.
- At 16×16, first prove three mechanically distinct reads: low groundcover, tall sight-blocking
  growth and triggered hostile flora. Tissue and finish variation can enrich those silhouettes but
  must not erase the movement/sightline distinction.

#### Terrain and minimap recommendations

- Distinct hashes for all sixteen masks do not by themselves prove readable adjacency. Several shore
  masks currently form tan bars and junctions that can read as walkable paths through water. Shore
  treatment should soften the water/ground boundary without implying an extra traversable strip;
  test inner/outer corners in composed maps, not only isolated mask cells.
- **Unrevealed means nothing there.** Remove decorative flecks from fog tiles; the settled minimap
  and world-map rule is explored, unexplored, and nothing. Fog must not imply terrain, contents or a
  point of interest.
- The minimap should encode revealed **terrain state**, not individual flora sprites. If growth
  affects movement or sight, show groundcover/tall-growth as terrain-class texture or symbol;
  otherwise omit it. Green per-plant dots risk reading as collectible resource/site markers. The
  eventual dedicated profile still needs stable party, route, portal and discovered-site symbols.
- Cracking is a next-turn structural warning, so it needs a redundant high-contrast shape/pattern
  that survives palette extremes and is never visible through fog. Elevation likewise needs a
  consistent edge/step grammar in a composed map; a light/dark wash alone can look like illumination.
- Keep deep water distinct from ordinary water before broadening decorative shoreline families.
  It is rules-critical terrain and belongs in the same readability proof.

#### Smallest next asset proof

Build one **native-scale integrated readability sheet**, not another content family:

1. the same water/shore map with ordinary water, deep water, soil and one elevation step;
2. low spreading groundcover, high clustered tall growth and separated solitary flora, each using
   one stable species identity and correct patch topology;
3. the same active-defence species in neutral world/detail state and triggered fight state;
4. revealed, fogged, cracking and selected/party-route overlays;
5. the corresponding minimap using terrain classes plus party/route/portal/discovered-site symbols.

Review it at actual phone size and in grayscale. This single sheet tests the most important remaining
claim: that generated beauty preserves navigation, sightline, hazard and disclosure semantics when
all layers coexist. Architecture, additional terrain families and broader flora casts should follow
only after this integrated sheet reads without labels.

### 9 Aug 2026 — integrated readability-sheet follow-up

**Disposition:** recommendations only. Reviewed in colour and true grayscale at the native 9×9 map
resolution, plus the active-defence neutral/triggered profile split. No AssetLab or game code edits.

#### Readability result

- The integrated sheet is a substantial semantic pass. Soil, ordinary water, deep water and empty
  fog remain distinguishable in grayscale; deep water has both value and contour support. Water-
  coloured transitions no longer create false tan corridors.
- Grounded flora reads more botanically, habit now changes patch topology, and neutral detail versus
  triggered hostile pose correctly separates visible identity from revealed behaviour. The profile
  hashes diverge only when active defence is applicable, which is the intended disclosure boundary.
- Party and route survive grayscale through size/shape differences, and minimap growth is now a
  terrain class rather than a field of resource-like plant dots. Elevation and cracks use redundant
  shape/value treatment rather than colour alone.

#### Corrections before treating the sheet as a golden fixture

- Build the demonstration route from actual passability. The current sample route and party marker
  cross/occupy the central deep-water region, while live `GroundType.deepWater` is impassable. A
  visual proof must not normalize an impossible route; use the same passability and movement-cost
  facts the game would provide.
- Keep cracks above flora and decorative surface layers, or reserve a tile-edge warning channel.
  Cracking is a next-turn structural warning and cannot be partially hidden by the plant occupying
  the tile. Party/selection may overlay it, but the warning must remain visible around them.
- At 16×16 the default woody form is now grounded but still has a slightly arch/stool-like centre.
  One asymmetrical branch/root break would improve the botanical read without increasing detail.
- Deep-water contour and route both use strong light geometry. They remain separable in this fixture,
  but include a route that runs alongside and turns at the deep-water boundary in the golden sheet;
  that is the collision most likely to expose ambiguity.
- Add the minimap's portal and discovered-site symbols to the same golden fixture before declaring
  its symbolic vocabulary complete. They were part of the settled minimap requirement and should be
  tested against route, party and both growth classes rather than added later in isolation.

#### Smallest next proof: static combat-stage composition

The next highest-risk unanswered visual is not another terrain family. Build one **static portrait-
phone combat composition sheet** using the existing creature and hostile-flora identities:

1. worst-case five-person party versus three foes, plus a sparse two-versus-one comparison;
2. unmistakable front/back ranks and close/mid/far reach relationships;
3. selected actor, legal target, cannot-reach target and protected-back-rank states using redundant
   shape/value cues;
4. one ordinary creature, one unknown creature and one triggered active-defence flora without
   analysis labels or direct trait badges;
5. a restrained world-derived background that carries palette/terrain identity without competing
   with combatants or status affordances;
6. colour and grayscale captures at actual portrait-phone size.

Use static poses first. This sheet should settle camera angle, sprite footprint, lane spacing and UI
contrast before idle/attack animation or additional asset families. The full 5v3 case is essential:
a composition that works only for attractive 2v1 screenshots does not prove the game's party size.

### 9 Aug 2026 — integrated-sheet correction disposition

**Disposition:** recommendations only; the integrated world-sheet milestone is accepted as the
current golden proof boundary. This review does not authorize AssetLab or game-code integration.

The five requested corrections resolve the prior semantic blockers:

- deriving the route by BFS from revealed passability prevents the proof from teaching an
  impossible deep-water move;
- turning beside the deep-water contour exercises the strongest route/terrain collision rather than
  avoiding it;
- cracks above flora/decor preserve the rules-critical structural warning;
- 16px woody asymmetry removes the most persistent stool/arch read without sacrificing species
  stability;
- portal, discovered site, party and route in one fixture complete the minimap collision vocabulary.

The versioned 33-output visible baseline, native/integer-zoom review page and zero-change regression
report are the right governance model. A matching hash establishes deterministic continuity, not
automatic art approval; baseline changes should continue to require an exported sheet review with a
short reason for each intentional semantic change.

No additional world-sheet content is required before the combat proof. Preserve two integration
guardrails for later: passability/overlay inputs must come from game facts rather than duplicated
AssetLab rules, and fog remains one invariant concealment fill with no informative pixels even when
a golden fixture would look more balanced with decoration.

#### Combat-stage proof review criteria

Proceed with the already requested static portrait-phone proof. Its smallest acceptance test is:

1. at actual phone scale, every one of five allies and three foes remains individually selectable
   without relying on labels;
2. front/back rank and close/mid/far reach read from position and connection shape before colour;
3. selected, legal, cannot-reach and protected states remain distinct in grayscale and when two
   states overlap;
4. the unknown creature reveals silhouette and present action only, while the triggered hostile
   flora may reveal its attack pose but not numeric defence/sense facts;
5. world identity remains a quiet stage cue and never resembles a legal-target, route or range
   overlay;
6. the sparse 2v1 composition uses the same camera, footprint and lane grammar as 5v3 rather than a
   separately beautified layout.

Do not add animation yet. If the full 5v3 state needs smaller sprites, prove touch target ownership
and overlap resolution first; visual sprite footprint may be smaller than the invisible 44pt hit
region, but selection regions may not ambiguously overlap.

### 9 Aug 2026 — static combat-stage visual review

**Disposition:** recommendations only. Reviewed at the native 216×336 composition in colour and
grayscale. The shallow-side camera, 48px identities and quiet stage are accepted as the current
combat direction; the state-overlap fixture and hit-region geometry need one correction pass before
this becomes a golden combat proof.

#### What reads successfully

- Party and foe ownership reads from facing and opposite sides before colour. Front/back rank also
  reads from inward/outward columns; the labels confirm a spatial relationship already visible.
- The same camera and lane grid work for 5v3 and 2v1 without restaging the duel as a separate beauty
  shot. Empty lanes remain quiet rather than collapsing the formation.
- Legal diamonds, the selected frame and cannot-reach cross survive grayscale. The unknown
  silhouette reveals no trait vocabulary, while the hostile flora is allowed a visibly triggered
  pose. The background carries world tone without competing with actors.
- Five allies and three foes remain individually visible. Vertical lane spacing is generous enough
  for 44pt targets at this fixture size.

#### Corrections before golden acceptance

1. **Put target states on targets.** The current 5v3 fixture places `cannotReach` on a party actor,
   which makes the cross read like incapacitation. Move the proof to a foe—ideally the protected
   unknown back-ranker—so it demonstrates the actual question: “I can see this target, but cannot
   legally reach it.”
2. **Actually prove overlapping states.** No current actor carries two actionable overlays. Add at
   least selected+protected and legal+protected or cannot-reach+protected cases in colour and
   grayscale. The selected full square and protected corner brackets share too much geometry when
   combined; give selection a distinct persistent footing/halo or header marker while protection
   keeps shield-like corners.
3. **Do not erase identity with cannot-reach.** The large X is unmistakable but covers most of the
   sprite. Prefer an edge-contained crossed reach/blocked badge plus a subdued actor treatment, or
   break the X around the silhouette. An unknown+protected+cannot-reach fixture should keep the `?`
   readable.
4. **Make reach actor-relative.** The tiny C/M/F ruler at the top centre reads as a decorative meter,
   not as what the selected actor can hit. Repeat or highlight the relevant close/mid/far boundary
   on the selected actor's lane, connecting it spatially toward the target side. It must remain
   legible without the letters at native scale; labels can confirm the shape.
5. **Prove independent hit geometry, not only actor bounds.** Party back/front columns are currently
   42px apart (`x=8` and `x=50`) while the promised hit regions are 44px wide, so same-lane targets
   can overlap by 2px. Separate every possible rank-column target rectangle by at least 44px and add
   a pairwise rectangle-intersection test across the full position grid, not only occupied fixture
   cells. Sprite pixels may overlap cosmetically; touch ownership may not.

The smallest next proof is the same sheet with those five corrections, including one deliberate
triple-state back-rank target. Do not add health bars, action menus, animation or status icons yet;
the current question is whether spatial combat state remains understandable under collision.

### 9 Aug 2026 — revised combat proof pre-golden disposition

**Disposition:** recommendations only. Native colour/grayscale review confirms the hit-region,
cannot-reach placement, unknown-silhouette and actor-relative reach corrections. Two semantic
collisions remain before golden acceptance; no broader composition change is requested.

The 44×44 full-position-grid proof is now sufficient: rank columns touch but do not overlap, and
every possible side/rank/lane target has independent ownership. The segmented X keeps the unknown
question mark readable. Close and mid reach now originate from the selected actor's lane and their
different bar counts survive grayscale.

#### Final corrections

1. **Legal and cannot-reach are mutually exclusive.** The current unknown back-ranker carries both
   `legal` and `cannotReach`, producing a gold diamond around a white blocked cross. That describes
   “you may choose this” and “you cannot choose this” at once. Use unknown+cannot-reach+protected for
   that collision. Put legal+protected on a different foe if that overlap needs proof, and add a
   fixture validator rejecting `legal && cannotReach`.
2. **Protected still disappears inside selected.** On the selected+protected actor, protected corner
   brackets share the selected square's exact edge language and read only as a slightly irregular
   selection frame. Move protection to an independent channel: preferably a small shield/guard cap
   above the hit region or a short rank-facing barrier on the protected side. It must remain visible
   when selected, legal or cannot-reach and must not cover the sprite.
3. **Include one far-reach example in the canonical evidence.** The revised stages visibly exercise
   close and mid only. Add a compact far example or a three-sample actor-relative reach legend so
   the one/two/three-bar grammar is visually reviewed rather than only implemented.

Once those three changes pass the same native/grayscale and fixture checks, promote the static
combat sheet to the golden baseline. Health/status/action UI and animation remain the next milestone,
not part of this acceptance gate.

### 9 Aug 2026 — combat-stage golden acceptance

**Disposition:** recommendations only. The static combat-stage proof v0.3 is accepted for promotion
to the AssetLab golden baseline. This accepts the visual/interaction grammar, not its current pixel
metrics as production authority and not any game-code integration.

Native colour and grayscale review now establishes:

- independent 44×44 target ownership across every possible side/rank/lane position;
- party/foe ownership and front/back rank before colour;
- actor-relative close and far reach in the canonical sheet, with the previously reviewed mid state
  completing the one/two/three-bar grammar;
- selected+protected and legal+protected combinations with protection in its own shield-cap channel;
- unknown+cannot-reach+protected without contradictory legal state or loss of the question mark;
- ordinary creature, unknown creature and triggered hostile flora disclosure boundaries;
- one camera and formation grammar across crowded 5v3 and sparse 2v1 compositions;
- a quiet world-derived background that survives grayscale without becoming an affordance.

Promote v0.3 together with its fixture validator and full-grid non-overlap test. Future changes to
camera, rank columns, target-state geometry, reach bars, disclosure silhouette or protection channel
must produce an intentional golden delta and visual review.

#### Smallest next combat proof

Add the player-facing combat UI as one static state matrix on this accepted stage:

1. HP and armour for all eight actors without shrinking the touch region;
2. one compact status treatment covering burn, poison and dazzle plus Ashe's protected Ground state;
3. current actor, action choice and target confirmation in ordinary and automated-gambit turns;
4. one passed-out ally that remains identifiable but is not targetable as active;
5. colour, grayscale, large-text and VoiceOver ordering notes at portrait-phone size.

Keep animation out for one more milestone. First prove that health, armour, status and action UI can
coexist with the accepted spatial grammar; motion should then reinforce those states rather than
solve their readability.

### 9 Aug 2026 — static combat-UI proof review

**Disposition:** recommendations only. The exported colour/grayscale sheet was inspected directly
from `AssetLab/artifacts/combat-ui-proof-v0.1.png`; no installed macOS app was invoked. The ledger,
condition and reading-order work is promising, but this is not yet an integrated proof on the
accepted combat stage.

#### What passes as a UI component proof

- HP and armour remain readable in grayscale and use text/icons in addition to bar length/colour.
- Current actor and selected target use opposite-edge emphasis plus explicit badges.
- Burn, poison and dazzle have redundant glyph/border shapes; passed-out state uses zero HP, text,
  contrast reduction and hatching rather than colour alone.
- The turn banner's encounter → current actor → action → target hierarchy is clear, and the declared
  VoiceOver party-before-foes order is appropriate.
- Five party and three foe ledger rows remain distinct; the unknown identity stays neutral.

#### Required integration corrections

1. **Restore the accepted stage.** The large “quiet stage” is currently four empty columns with no
   actors, sprites, selection/reach/protection overlays or 44px stage targets. The proof has replaced
   spatial combat with two roster lists rather than showing UI on the accepted stage. Render the
   v0.3 5v3 composition in that area unchanged, then let the ledger supplement it.
2. **Choose one semantic target set.** If the eight stage actors are the 44px controls, make ledger
   rows linked visual detail rather than eight duplicate VoiceOver stops. If ledger rows own
   selection temporarily, keep the stage visual but hide only its duplicate controls from assistive
   technology. Do not expose two buttons for each combatant.
3. **Ground is protection, not an affliction.** It should use the accepted shield-cap/protective
   channel and a beneficial `Ground` readout on the protected party member, separate from
   burn/poison/dazzle. The current fixture puts Ground on an unknown foe, which the live Ashe
   technique cannot do. Ground belongs only to the selected party member Ashe is protecting and is
   consumed by the next active Emanation event.
4. **Use a live-semantic gambit example.** “Brace and draw” has no established rules meaning. Use a
   real current action/target pair from the gambit catalogue, or label it explicitly as placeholder
   copy. The proof should demonstrate a gambit choosing a legal foe without inventing a combat verb.
5. **Prove the actual compact width and large-text result.** The current evidence panels use a
   minimum 390px column, not the accepted 216px stage width or a named production phone width.
   Export ordinary and large-text captures at a concrete portrait viewport. Scrolling vertically is
   acceptable; horizontal growth, truncation and a stage narrower than its target grid are not.
6. **Passed-out semantics need native disabling.** `aria-disabled` on a normal HTML button still
   permits activation. Use a genuinely disabled active-target control, while retaining a readable
   noninteractive identity/detail row if the player may still inspect them.

The smallest next proof is the same banner and ledgers wrapped around the unchanged v0.3 stage, with
Ground moved to one protected ally, a valid gambit action, one semantic control set and exported
ordinary/large-text phone captures. No animation or broader action menu is needed yet.

### 9 Aug 2026 — full terrain-catalogue design boundary

**Disposition:** recommendations only. The Asset lead's dynamic-coverage audit correctly identifies
full `GroundType` coverage as the next false-coverage risk. The twelve names are not twelve cosmetic
biomes; their smallest truthful visual grammar is defined by the rules the player must act on.

- **Deep water and chasm** must both read as impassable before colour, but not as the same absence:
  deep water is continuous depth with a shoreline/depth boundary, while chasm is missing ground with
  a hard rim. Neither may inherit route-like interior marks.
- **Shallow water** must read as traversable and **ice** as solid traversable ground. Ice should not
  look like merely pale deep water, and shallow water should not imply a hidden movement surcharge.
- **Mud and tall growth** share a two-turn entry cost but need different causes: drag/softness versus
  obstructing vegetation. Only tall growth also blocks sight.
- **Rubble and tall growth** share sight blocking but not movement cost. Rubble therefore needs a
  broken occluding profile without adopting mud/growth's slow-terrain signal.
- **Groundcover and tall growth** must retain the stable flora species layered on them. Groundcover
  stays visually permeable and non-occluding; tall growth may hide the far tile edge/occupant but
  must not conceal the tile's actionable content or route state.
- **Stone, soil, sand and ash** are ordinary passable substrates. Their material identity should
  survive grayscale, but none should acquire a hazard, richness or resource-node promise from
  texture alone.
- **Cracking is a Stability overlay, crumbled is a state change, and fog is no information.** Render
  cracks above terrain/flora as already accepted; an actually crumbled tile must no longer look
  safely occupiable; unrevealed fog must not silhouette the underlying ground class.

The contact sheet should group comparisons by shared rule rather than alphabetical name: passable
versus impassable, ordinary versus slow, clear versus sight-blocking, and revealed versus fogged.
Add one collision fixture where route, party and actionable tile content remain readable on mud,
tall growth, rubble and a chasm edge. Palette proliferation can follow only after those value/shape
distinctions survive native size and grayscale.

### 9 Aug 2026 — exact adapter schema review

**Disposition:** recommendations only. Manifest v2 now has the correct conceptual split: an editable
AssetLab workspace, a game-shaped identity, visual-only render hints and adapter diagnostics. Moving
topology out of mechanical identity, retaining exact emanation allocation, allowing null defence and
normalizing allocation families at the boundary all match current design. The 0/36 golden delta is
also the right result: contract repair should not silently restyle accepted art.

#### Naming and schema recommendations before integration

1. **Prefer `gameIdentity` over `liveIdentity` at the next manifest version.** “Live” can imply a
   mutable runtime instance or server state; this object is the immutable game-model identity the
   asset was derived from. If renaming now is not worth a v3 manifest, define `liveIdentity` exactly
   as “game-model-shaped identity snapshot” and reserve “runtime state” for awake/harvested/damaged
   facts.
2. **Keep `authoringDescriptor` and `renderHints`.** Those names correctly distinguish editable
   workspace controls from nonmechanical renderer inputs. Rename the broad `versions` bag to
   `pipelineVersions` when schema compatibility next changes; manifest/schema version remains a
   separate top-level contract.
3. **Make identity family explicit at manifest level.** Require `identityKind: creature | flora`
   (later character/site/etc.) and validate a paired `oneOf`: creature authoring + creature game
   identity, or flora authoring + flora game identity. The current shared export-manifest schema
   appears to reference the creature authoring/live schemas directly, while `worldManifest()` emits
   flora through the same field names. A flora export must not pass only because validation was not
   exercised against that manifest.
4. **Make adapter diagnostics structured and stable.** Use objects such as
   `{ code, severity, path, message, sourceVersion }`, not free strings. Integration can then reject
   errors, surface warnings and tolerate informational normalization without parsing prose.
5. **Record the v3 emanation migration as lossy.** A dominant old label cannot prove an original
   70/15/15 allocation. Deterministic is not the same as exact. Emit a warning such as
   `assumed-emanation-allocation` with the source version and assumed triangle; do not let the test
   expect an empty warning list for that migration. New v4 linked allocations should export cleanly.
6. **Keep normalized values out of visible disclosure.** The exact snapshot may carry them for game
   integration, but sprites and contact sheets continue to express only bounded visual tendencies;
   no badges, exact segment counts or colour keys should let art become a free analyzer.

Final Swift enum spelling and units remain an Engineering confirmation. Until that fixture compares
AssetLab output with a real decoded game identity in both directions, call this adapter structurally
accepted but not integration-golden. Continuing to the 1–4 flora map is appropriate; only the export
contract's golden status waits on these schema checks.

#### Manifest v3 disposition

**Structurally accepted, recommendations only.** Manifest v3 adopts `gameIdentity`, explicit
`identityKind`, paired creature/flora conditional validation, structured `adapterDiagnostics`,
`pipelineVersions` and a visible `assumed-emanation-allocation` diagnostic for legacy dominant-kind
migration. Unit/schema tests and all 36 existing golden fixtures pass unchanged. This closes the
AssetLab-side contract corrections above.

The remaining integration gate is external: Engineering must confirm Swift enum spellings/numeric
units with a real game-identity round-trip before game-code adoption. The new deterministic 1–4
flora species set is accepted as test infrastructure, not yet as a visual golden; wait for its native
colour/grayscale composed-map sheet before accepting species coexistence, patch readability or
content-overlay collisions.

### 9 Aug 2026 — multi-species integrated-map v0.1 review

**Disposition:** recommendations only; promising composition proof, not golden yet. The exported
workspace artifact was inspected directly with no installed app invocation.

#### What the colour panel proves

- Four flora silhouettes can coexist on one 9×9 native map without turning into a uniform green
  texture or obscuring the water contour.
- Five placements remain individually locatable at 16px, and palette inheritance produces distinct
  species character without making the minimap itself species-coloured.
- Flora remains grounded on tiles rather than floating as inventory-like dots; the quiet central
  water body and route retain first-read ownership.

#### Evidence still needed before golden acceptance

1. **Export the complete comparison sheet.** The current 874×720 JPEG clips the grayscale map below
   its upper portion and does not show the claimed minimap panel. Provide full uncropped colour,
   grayscale and minimap outputs, preferably lossless PNG with nearest-neighbour scaling for native
   pixel review.
2. **Identify the repeated species in review chrome.** Four species across five placements is the
   right fixture, but the screenshot does not say which two placements share identity. Add a
   review-only legend/coordinate list and a pixel-equality assertion proving the repeat is identical
   despite placement/patch context; do not put labels on the production map.
3. **Exercise both growth classes explicitly.** The sheet should name which placements occupy
   groundcover and tall growth and show that the terrain class remains readable under the species.
   At least one repeated species should appear across two valid patch contexts without changing its
   identity pixels.
4. **Prove silhouette separation before colour.** In the full grayscale panel, all four species need
   distinguishable stature/branching/mass at native size. The current visible colour panel suggests
   this is achievable, but green/blue hue carries too much of the evidence while the grayscale flora
   is clipped out.
5. **Keep route/action ownership explicit.** Add one deliberate near-collision where a flora
   placement sits beside—not over—the route and a semantic tile marker, verifying the route and
   marker retain their accepted shapes. The later full tile-content sheet still owns broader
   collision coverage.

No new flora mechanics or palette rules are requested. A corrected evidence export of the existing
fixture can close this gate; after that, proceed to the semantic tile-content/minimap catalogue.

### 9 Aug 2026 — settled overhead flora camera correction

**Decision, not recommendation:** Aimee has clarified that every flora rendering associated with an
explorable world remains straight top-down at every size and state. This includes the 16×16 map
sprite, 48×48 neutral flora view and 48×48 triggered-hostile view. The earlier larger side/detail
elevation is superseded. The home base remains the separate settled side-view environment, and the
shallow-side combat stage for creatures/party does not authorize a camera change for flora.

The shared overhead identity should survive between sizes through crown/rosette/mat/radial-tuft or
cluster structure. Triggered defence changes pose through radial unfurl, strike, opening or
contraction while preserving that camera; it must not become a side-on monster merely because it is
hostile. This is especially important for a plant first encountered on the map: recognition should
come from the same overhead anatomy, not palette alone.

The reported nine changed flora fixtures are therefore expected in scope. Promote them only after a
complete native-size colour/grayscale contact sheet confirms:

1. all three profiles read overhead without a horizon, side stem or ground line;
2. neutral and triggered states remain recognizably the same species;
3. triggered geometry communicates an active threat without revealing exact defence mechanics;
4. 48px added detail does not invent a different crown topology from the 16px identity;
5. ordinary map terrain, route and semantic markers retain first-read ownership.

This camera correction does not block the ten-family tile-content collision sheet. A corrected
workspace PNG should be retained as the promotion evidence; no installed-app capture is needed.

#### Overhead flora proof v0.2 disposition

**Accepted for camera-grammar promotion, recommendations only.** The lossless 384×168 RGBA sheet
demonstrates the same species as a 16px overhead crown, 48px neutral overhead rosette and 48px
triggered radial pose in colour and grayscale. None introduces a horizon, stem baseline or oblique
ground plane. The central holes/lobes survive the size change, while the triggered spikes read as an
active pose rather than an exact reach diagram. On the composed map, water contour, route, portal,
site and party marks retain ownership ahead of flora.

The nine intentional flora fixture changes may be promoted after the regression review page confirms
that those nine—and only those nine—are the all-overhead profiles described here. Keep this proof as
the decision artifact. Future species/habit sheets should continue checking identity across all
three profiles; they do not need to reopen the settled camera choice.

### 9 Aug 2026 — ten-family tile-content collision v0.1 review

**Disposition:** recommendations only; grammar substantially accepted, one correction before
golden. The sheet covers empty, node, drop, hazard, portal, cache, site, diary, anonymous writing and
traveller in ordinary colour, grayscale and disclosed-minimap rows. Portal versus exit uses distinct
closed/open geometry; diary versus anonymous writing retains page/book structure; the collision row
keeps hazard, traveller and site readable across mud, growth and rubble while route stops before the
chasm. The chasm correctly carries neither action nor route.

One native-size ambiguity remains: the ordinary **drop** and **traveller** both reduce to a small
light head/cap above a narrow coloured body, and their grayscale silhouettes are close enough to
read as two bottles. Give the traveller a wider shoulder/arm or two-foot top-down footprint while
keeping it within the tile and distinct from the party marker. Do not solve this only with teal
versus green.

After that correction, recheck three invariants and promote without another broad redesign:

1. drop and traveller remain distinct at native grayscale and through VoiceOver labels;
2. the disclosed minimap shows only the content its game rules permit—portal and writing under the
   current explicit disclosure decision, other landmarks/people only when known;
3. mud/growth/rubble retain terrain class beneath content, and no action/route leaks onto chasm.

The ten-family inventory is accepted; no eleventh generic content icon or palette expansion is
requested. The next smallest proof after correction is the authored-vs-generated site/station
identity sheet already ordered by the dynamic coverage audit.

#### Tile-content v0.2 disposition

**Accepted for golden promotion, recommendations only.** The corrected traveller uses broad lateral
arms/shoulders and separated feet, remaining distinct from the narrow wild-drop vessel in both
colour and grayscale. Portal/exit, diary/anonymous writing and every other accepted family remain
unchanged. The disclosure and chasm invariants pass, and the mixed mud/growth/rubble/chasm row still
preserves terrain and route ownership. Promote this corrected fixture; do not retain v0.1 as a
competing current golden.

The exact nine overhead-flora hashes have also been promoted with regression returning 0/36, which
closes the camera correction. The Asset Lead's self-rejection of the first place sheet is appropriate:
18 authored stations cannot collapse to generic houses, and 15 sites cannot collapse to generic
squares. Continue refining that sheet around authored silhouette/functional motifs before requesting
design review; procedural palette, wear and environmental adaptation may vary, but place identity
must survive without its label.

### 9 Aug 2026 — authored-place identity/adaptation v0.3 review

**Disposition:** recommendations only; camera/adaptation contract accepted, individual place and
lifecycle grammar not yet golden. The sheet correctly keeps all 18 Base stations in the settled
side-view village camera and all 15 world sites straight top-down. Warm→cold and warm→ash adaptation
preserves silhouette while changing palette/material atmosphere, which is the intended procedural
boundary. The second pass is materially better than generic houses/squares: forge chimneys, spring
basins, hearth openings, shop awnings, shrines, camps, warrens, vents, causeways and cairns now exist
as functional motifs.

#### Corrections before promotion

1. **Same-archetype stations need functional identity beyond emblem bits.** Constellation, Survey
   Post, Reliquary and Anchorage still converge on tower/box silhouettes; Storehouse, Blacksmith,
   Distillery and Channelworks also remain close once their labels are removed. Tiny binary accent
   squares are authored IDs but not memorable architecture. Give each collision group one larger
   functional mass/negative-space distinction: observing aperture versus survey mast, enclosed
   reliquary niche versus anchoring frame; storage bays versus forge stack, vessel train versus
   channel manifold. Palette and signs may support, not own, recognition.
2. **Prove recognition without labels.** Add an unlabeled collision strip for the two groups above
   at native size and grayscale. Tests should assert pairwise silhouette inequality within each
   archetype, but visual review must also confirm the differences are larger than one 2–3px emblem.
   The full labelled catalogue can remain the inventory sheet.
3. **Lifecycle is physical state, not a universal badge.** The current site `searched` corner square,
   `exhausted` frame bars and especially the cyan `guarded` stripe read as UI overlays and expose a
   mechanical enum directly. Search should open/disturb the authored centre; exhaustion should
   remove/collapse the usable interior while retaining the site's outline. A guard is a separate
   visible creature/content occupant using the accepted collision grammar, not a colour bar painted
   across every site. If the guard is not revealed, site art must not disclose it.
4. **Station damage/tier must preserve function.** The lifecycle example is directionally sound,
   but run the collision groups through built/tier-3/damaged states to prove a chimney, aperture,
   basin or frame never disappears behind the generic upgrade rail or damage patches.

The fifteen site base profiles may continue; their camp/causeway/vent/warren/cairn/seam distinctions
are suitable authored starting identities. Do not add decorative micro-detail until the state
overlays above become physical transformations. The smallest corrected proof is two unlabeled
station collision strips plus four lifecycle examples (built/searchable, searched, exhausted and a
site with a separately rendered visible guard), in colour and grayscale.

#### Authored-place v0.4 disposition

**Visually accepted pending one API cleanup, recommendations only.** The corrected lossless sheet
gives the tower and work/store/forge collision groups distinct functional mass and negative space at
unlabelled native grayscale. Tier/damage stress preserves those motifs. Search and exhaustion now
disturb/remove the authored site centre, while the guard is a separate person-shaped occupant; the
forbidden universal state bars are absent from the proof.

The implementation still exports the superseded `siteCommands(id, state:)` path containing the old
searched corner, exhausted frame bars and guarded cyan stripe, alongside the correct
`physicalSiteCommands` + `siteOccupantCommands` boundary. Remove/private that stale state API or make
the single public renderer delegate to physical site state plus a separate visible occupant. Add a
regression asserting guarded state leaves site geometry unchanged and no public renderer emits a
full-width accent bar for it. Once that rejected path is unreachable and tests are green, promote
v0.4 without another visual pass.

### 9 Aug 2026 — authored-place identity/adaptation v0.4 review

**Disposition:** recommendations only; the requested semantic corrections pass, with one fixture-
coverage refinement before place identity becomes golden. The lossless 640×570 proof was inspected
at native scale and in its supplied grayscale collision row.

#### Corrections now accepted

- **Functional mass and negative space:** the tower group no longer depends on tiny emblems. The
  Constellation dome/aperture, Survey Post's broad mast deck, Reliquary's enclosed central mass and
  Anchorage's open frame remain distinct without labels or hue. Storehouse bays, Workshop's offset
  working profile, Blacksmith's forge stack, Distillery's linked vessel line and Channelworks'
  manifold/frame likewise separate by whole-building structure in grayscale.
- **Physical site state:** the reviewed Signal Cairn example reads as an authored centre being
  disturbed and then hollowed/collapsed, rather than as a corner badge or status stripe. Continue
  deriving searched/exhausted geometry from each site's own usable centre; the shared helper must
  not become one universal rectangle stamped onto every site family.
- **Guard ownership and disclosure:** guarded leaves site silhouette geometry unchanged in the
  fixture/test and adds a visibly person-shaped guard as a separate content occupant. This replaces
  the rejected cyan stripe and preserves the rule that an unrevealed guard cannot leak through site
  art.
- **Camera/adaptation contract:** all prior side-view station, top-down site and palette-only
  adaptation conclusions remain intact.

#### Final fixture refinement before golden promotion

The unlabeled row applies tier/damage stress across the collision group, but each station appears in
only one chosen tier/state combination. That proves the stressed set remains readable, not yet that
each identity survives its own built → tier-3 → damaged path. Add a compact comparison fixture (it
may be generated/test-only rather than enlarging the catalogue sheet) that evaluates every member
of the two collision groups in those three states. Assert pairwise silhouette inequality within
each group at every state and visually spot-check that the identity-owning aperture, mast, niche,
frame, bay, stack, vessel train or manifold survives. The existing Workshop lifecycle row is a good
single-family example but does not cover that group-wide claim.

No architectural redesign, added station family or new state is requested. Once that matrix and
pairwise checks pass without changing the accepted v0.4 visual grammar, promote the place fixture
and proceed to the character identity boundary.

#### Authored-place v0.4 final disposition

**Accepted for golden promotion.** The stale state-bearing `siteCommands` path has been reduced to
base authored geometry; physical searched/exhausted changes remain in `physicalSiteCommands`, and a
visible guard remains a separate occupant. Regression now proves that guarded state cannot alter a
site silhouette or emit the rejected full-width accent bar. The strengthened collision fixture also
checks every tower/work-group station in built, tier-3 and damaged forms, with each identity retaining
distinct state silhouettes. The full AssetLab suite passes and the existing baseline remains 0/62
changed. No further place-grammar review is required before promoting this accepted fixture.

### 9 Aug 2026 — Character Lab v0.2 review

**Disposition: contract accepted; visual identities not golden, recommendations only.** The sheet
successfully establishes the required camera and state boundary: 16×16 explorable-map people are
straight top-down, 48×48 combat people use the accepted shallow side stage, gear/passed-out state is
layered over identity, named and generated people remain separate, and the Binder is explicitly a
replaceable faceless placeholder. Native grayscale confirms that the current marks are geometric
rather than hue-only.

#### Corrections before visual promotion

1. **Separate personal palette from environmental grading.** The current `palette` switch changes
   `skin` along with clothing. A cold/ash world may grade light and shadow, but must not reroll or
   homogenize a person's skin, hair, clothing identity or accessibility contrast. Persist a personal
   authored/generated palette with the identity descriptor; apply world lighting as a separate
   render transform. Add equality tests for identity colors before grading.
2. **Do not treat bitmask uniqueness as authored character design.** Pairwise hashes prove that all
   28 command lists differ, but many differences are arbitrary side/top/brow blocks and several
   silhouettes read as coded appendages rather than memorable people. Replace the numeric
   `identityMark` combination with named authored feature choices (overall mass, head/hair or
   headwear shape, shoulder/outerwear shape, carried-role prop and stance/asymmetry). These are art
   descriptors chosen for each person—not values inferred from calling, combat stats, gender or
   campaign phase. Calling may inspire a prop only after authored review; it cannot be the generator.
3. **Give generated companions bounded structural variation.** Seeds 41–44 remain nearly the same
   wide green body with one small mark. Their persisted versioned descriptor should select from the
   same neutral human grammar across multiple meaningful axes while reserving named-cast feature
   combinations. Tavern refresh, current level, want and gear must never reroll it.
4. **Gear must identify the item without erasing the person.** The proof's single pole and solid
   armour slab demonstrate layering but not the settled equipment families. The next fixture should
   show at least close weapon, far weapon, mid weapon and three protection weights on two contrasting
   bodies. Armour may alter outer contour, but face/head and one identity-owning mass or asymmetry
   must remain readable. Passed-out state must rotate/repose the combined person and carried gear
   without becoming an ordinary loot/drop icon.
5. **Keep the Binder genuinely provisional.** Purple clothing and the current body are lab defaults,
   not canon. The integration contract may reserve a recognizable party-role/selection treatment,
   but no splash, world or combat output should persist a canonical face, skin, body, hair or clothing
   until player customization or an explicit authored Binder decision exists. In particular,
   `binderCommands` currently derives that placeholder by rendering `tovin`; this couples the player
   body to a named traveller's build and identity marks even though the face pixels are hidden. Use a
   separate Binder placeholder/template and reserve only disclosure-safe role grammar such as a
   replaceable mantle/tool or party treatment. Tovin must remain solely Tovin.

The smallest next proof is not all 28 again. Use six deliberately contrasting named travellers
(Mara, Halloway, Isolde, Tovin, Wren and Ashe), four generated descriptors and the faceless Binder;
show personal palette stability under two environmental grades, world/combat correspondence,
representative gear and passed-out state in color and grayscale. Once that grammar reads as people
rather than binary IDs, propagate it to the remaining authored cast and run the 28-way collision
matrix.

#### Character Lab v0.3 disposition

**Accepted in principle pending one gear-vocabulary correction.** The narrowed sheet resolves the
v0.2 identity problems: personal skin/clothing/accent palettes persist across warm/cold environment
grades; named features are explicit authored axes rather than numeric bit combinations; four
generated descriptors differ by meaningful structure; Tovin and the noncanonical Binder are cleanly
separate; and explicit prone-person poses retain body identity rather than rotating into loot piles.
The six world/combat silhouettes also remain distinguishable in native grayscale.

Swap the representative reach examples before promotion. The sheet/log currently describes **far
spear** and **mid bow**, which reverses the settled equipment grammar: an ordinary Bowyer bow is
**far**, while a line-holding spear or Maud polearm is **mid**. A purpose-built thrown spear could be
far, but then it must read as a throwing set rather than the ordinary melee spear used here. Update
labels and geometry together, add a vocabulary assertion (`bow → far`, `melee spear/polearm → mid`),
and promote v0.3 without another broad character redesign once the corrected color/grayscale sheet
still reads. The heavy-protection overlay may alter the body contour, but the retained head/accent
identity in this proof is sufficient for the current scale.

#### Character Lab v0.4 final disposition

**Accepted for character-grammar golden promotion.** The corrected proof uses the settled reach
vocabulary—blade close, melee spear mid, bow far—and the geometry matches the labels. Authored
descriptor features and equipped gear now survive explicit prone poses; all 28 named prone
silhouettes remain pairwise distinct. Unknown named IDs fail rather than becoming plausible generated
people, the first 512 generated descriptors are collision-free and avoid exact named combinations,
and environmental grade changes rendered colour without changing identity geometry or ownership of
personal palette. The Binder remains visibly and textually noncanonical. Direct inspection of the
640×620 lossless proof passes in colour and grayscale; the full AssetLab suite passes and existing
regression remains 0/62. Promote this grammar, then expand authored descriptors to the full cast
without changing the accepted identity/render-state boundary.

#### Full-cast descriptor v0.1 disposition

**Accepted as complete catalogue/regression evidence; individual appearances remain provisional.**
All 28 named travellers are present in authored order, their world/combat identities correspond, and
the grayscale row shows meaningful shape distinctions rather than palette-only separation. The
approved descriptor grammar has propagated without reintroducing calling/stat-generated anatomy,
camera drift, Binder substitution or generated-person overlap. The remaining close families
(apron/work garments, mantles and brim/scarf shapes) retain enough mass/asymmetry separation at this
proof scale to proceed.

Golden coverage may protect the current full-cast fixture from accidental rerolls, but must not be
interpreted as Aimee having finalized every person's body, hair/headwear, skin, garment or personal
palette. Record those descriptor values as **provisional authored art v1** and keep changes deliberate
and reviewable. Callings shown on the sheet are review labels, never generator inputs; an apron or
carried trade object is an authored character choice that may later be revised without changing the
person's mechanical identity. No further correction blocks the next resource-node milestone.

**v0.2 follow-up accepted.** The four grayscale near-pairs now separate through large authored
features rather than hue or a one-pixel code, and the unlabeled native collision strip compares them
directly with the accepted traveller/drop grammar. All 28 standing and prone identities remain
distinct. This closes full-cast catalogue review under the same provisional-art governance above;
proceed to resource-node evidence.

### 9 Aug 2026 — Resource Node Lab v0.1 review

**Disposition: infrastructure passes; visual/acquisition semantics require a focused correction.**
The sheet covers current resource IDs, inherited environment, remaining/exhausted states, native
collision and disclosure-gated minimap behavior in colour/grayscale. It correctly keeps the route,
traveller, drop and chasm grammars distinct. Do not promote the current family sheet yet.

1. **Resource catalogue is not identical to node catalogue.** Mote is a Reality currency and the
   live ordinary node yield table excludes it; Raw Essence also owns the accepted wild-drop
   presentation. Keep all 23 resources in coverage, but label acquisition grammar explicitly and do
   not imply that every family is harvested from a node. A resource may have node, wild-drop,
   creature, site or other authored acquisition profiles without those profiles becoming aliases.
2. **Actual-flora inheritance belongs only to the six live linked yields:** Timber, Fibre, Pulp,
   Toxin, Spore and Reagent. Resin and Ichor are not classified as flora resources by live worldgen,
   so rendering both as a sprout falsely invents a plant source. Until their acquisition design/code
   changes, give them authored exudate/pool/deposit evidence or emit an adapter warning; never attach
   a fabricated flora identity. Rift-glass inherits unstable substrate.
3. **Exhaustion is physical, not a universal status bar.** Mineral extraction should leave a worked
   cavity, scattered tailings or a collapsed seam that retains family mass. Flora-linked harvesting
   should clip, strip or stump the same plant identity. Remove the near-universal bottom residue bar
   as the primary state read.
4. **Strengthen related minerals in grayscale.** Organize loose piles, seams/outcrops, crystals,
   fluid deposits and unstable/exotic material through larger mass and negative-space differences;
pattern/accent may support those forms but cannot own exact recognition.

The smallest correction is a native unlabeled collision strip for the similar mineral groups plus
one remaining→exhausted example from each acquisition grammar, with explicit family/acquisition
labels in the review legend. Fog retains only its invariant non-informative fill; a revealed known
minimap may identify a resource, while an unrevealed tile may not.

### 9 Aug 2026 — Character Lab identity proof v0.3 review

**Disposition:** recommendations only; the authored identity grammar is accepted, with one state-
preservation correction before golden promotion. The 640×620 lossless proof and its source/tests
were reviewed directly.

#### Corrections closed

- **Camera and cross-profile identity:** the 16×16 world figures retain the settled straight
  top-down footprint and introduce no side-view ground or background. Hair/headwear, outerwear,
  carried side and overall mass correspond coherently to the 48×48 side-biased combat figures.
- **Authored people rather than bit codes:** named `build`, `hair`, `garment`, `carry` and
  `asymmetry` axes replace the rejected `identityMark` bitmask. In the six-person colour/grayscale
  fixture these read as deliberate human features—brim, hood, wrap, mantle, robe, satchel and stance
  differences—rather than arbitrary status-like blocks. Calling remains metadata and is not read by
  the renderer; the authored descriptor owns appearance.
- **Personal palette boundary:** identical character pixels sit over warm and cold environmental
  fields. Skin/clothing identity is no longer rerolled as a world palette. Future lighting may grade
  the composed scene, but must preserve this descriptor-level personal colour source.
- **Generated companions:** seeds 41–44 show bounded but meaningful structural variety across body,
  hair/headwear, garment and carry axes, with one descriptor reused between world and combat. The
  deterministic descriptor and nearby-seed multi-axis test are suitable infrastructure; persist
  descriptor plus generator version at the app boundary rather than silently recomputing it after a
  grammar change.
- **Binder boundary:** the Binder now has a separate explicit descriptor and regression assertion
  against Tovin. Its hood/mantle mass communicates a provisional role while covering the face, and
  review text correctly marks body, face and purple palette as noncanonical. Keep this template out
  of authored named-cast identity and require customization/explicit design authority before it can
  become persistent player appearance.
- **Equipment:** blade/close, bow/mid, spear/far and light/heavy protection are visibly distinct
  appended geometry. Head/headwear and at least one identity-owning contour remain visible in the
  reviewed examples, including heavy protection. No stat, calling, rank or reach number is encoded
  into anatomy.

#### One correction before golden

**Passed-out must repose the same person, not replace them with a generic prone person.**
`passedOutCommands` currently constructs a new shared body and carries forward only personal colour
plus the left/right accent position. Build, hair/headwear, garment and carried feature are discarded.
That is visible in the proof: the six native grayscale prone figures converge on nearly the same
silhouette even though their standing identities differ. This passes the current weak `notEqual`
test but does not satisfy the overlay/state contract.

Recompose or transform the descriptor-driven identity into a prone pose so at least two
identity-owning features survive—normally head/hair or headwear plus outerwear/build/carry—and then
add tests proving each passed-out result is derived from its own descriptor and remains pairwise
distinct for the six review identities. Show carried equipment with one prone example as well, so a
passed-out ally remains a person with gear and cannot be mistaken for the accepted wild-drop/loot
grammar.

No broader character redesign, animation or facial canon is requested. A compact corrected prone
row in colour and grayscale can close this gate; the accepted standing/world/combat grammar need
not change.

### 9 Aug 2026 — Character Lab engineering boundary review

**Disposition:** recommendations only; no AssetLab or game code was changed for this review. The
authored named identity / seeded generated person / customizable Binder split is compatible with
later game integration. World, combat, gear and pose should remain separate render-request concerns.
The present `characterCommands(identity, options)` prototype is useful visual proof, but it is not
yet an application contract and should not be imported into the app.

#### Live-model mapping

- A named character maps cleanly by `TravellerID`. `TravellerDef` owns authored identity and
  `CompanionState.traveller` preserves that identity after recruitment. Do not use roster index,
  display name, calling, icon, campaign phase, combat lean, stats, rank or worldwork as visual
  identity. Roster index is mutable placement; the others are gameplay/content facts that may change
  or are insufficiently unique.
- Generated people do **not** yet have the required durable game identity. `CompanionState` has no
  generated-person ID, visual seed, first-met seed or persisted appearance descriptor; a nil
  `traveller` currently also describes Quill. Before integration, the game needs a stable generated
  identity record that survives Tavern revisits, delayed recruitment, roster ordering, save/load and
  content updates. It should own at least a stable ID, generation seed, identity-schema version and
  the persisted build-plan linkage described by `generated-companion-arrival-builds-current.md`.
  Never derive appearance from roster index, current Binder level or a fresh RNG call.
- The Binder likewise has progression and equipment but no persisted appearance/customization
  model. Give Binder appearance its own identity kind and versioned descriptor; do not overload a
  fake `TravellerID`, the `tovin` placeholder, `CharacterState` or `binderEquipped`. Quill also needs
  an explicit stable identity kind/key rather than relying on `traveller == nil` once generated
  people exist.

#### Recommended application boundary

Export a schema-validated character identity descriptor independently from a render request. A
minimum identity envelope should contain:

- `identityKind`: `namedTraveller`, `generatedPerson`, `binder`, or `startingCompanion`;
- `identityID`: namespaced stable identifier (`TravellerID` for named travellers; persisted IDs for
  the other kinds);
- authored or generated visual genome: build/proportions, locked silhouette modules, face/hair or
  head treatment, clothing base, signature features, core palette and bounded marking choices;
- `identitySeed` only where generation is legitimate, plus `identitySchemaVersion` and the full
  immutable pipeline-version tuple already required by the broader proposal.

The render request should separately carry a closed `profile` enum, native pixel dimensions,
facing/orientation, pose, equipped visual layers, environmental palette treatment and disclosure
state. `world` is 16×16 straight top-down and `combat` is currently 48×48 side-biased, but those
dimensions are pixel units, not SwiftUI points or hit-target sizes. Persist neither profile nor pose
as identity. Rank, current HP/passed-out state, selection/protection/reach UI and combat status are
live state or presentation overlays, never visual-genome inputs.

#### Exact gaps before adapter-golden status

1. **Replace open strings and silent defaults.** `profile`, `palette`, `gear`, `pose`, calling/build
   categories and identity kind need schema enums with explicit unknown-value diagnostics. The current
   fallback from an unknown identity to a generated wide body, unknown palette to ochre, and any
   non-`world` profile to combat can turn malformed app data into plausible but wrong art.
2. **Author named visual fields explicitly.** The current catalogue contains only `id`, a copied
   calling string, coarse build and numeric mark. Named production identity still needs locked
   silhouette, head/hair, clothing/signature feature and core-palette fields. Calling may inform an
   authored choice, but must not be copied as a second authority or automatically generate anatomy.
   Prefer a checked adapter keyed by the live `TravellerID` catalogue and report missing/extra IDs.
3. **Model all equipment slots without making gear identity.** The live enum has eight slots:
   weapon, offhand, head, armor (displayed as Body), hands, feet, tool and keepsake. The prototype's
   `none|weapon|armor` string is insufficient. Render layers should reference stable `ItemID` plus
   safe visual metadata (slot, visual family, handedness/anchor, tier/wear where approved), define
   deterministic layer order and clipping, and diagnose missing visual families. Damage kind, reach,
   wards, stats and upgrade power must not silently choose anatomy.
4. **Add facing and pose vocabulary.** A single neutral sprite is not enough for a moving top-down
   actor, and a rotated standing sprite is only a temporary passed-out proof. Define closed facing
   cases appropriate to each profile and a minimal pose enum (`neutral`, `passedOut`, and later only
   reviewed actions). Keep party/foe side orientation in the combat render request. Do not introduce
   animation timing until the static grammar is accepted.
5. **Version and hash canonical inputs.** Character exports need manifest/schema/generator/module/
   palette versions, canonical JSON hashing and pixel hashing, matching the accepted asset boundary.
   A generator update must not silently reroll an existing generated person or alter a named
   traveller. Record whether an identity is frozen to resolved modules or reproducible from a
   versioned seed; a seed alone is not stable across algorithm changes.
6. **Use structured diagnostics and one-of validation.** Report code, severity, JSON path, supplied
   value and fallback/repair action. Validate identity-kind-specific payloads as a `oneOf`: named must
   resolve to a complete authored entry; generated must have persisted ID/seed/version; Binder must
   have a valid customization descriptor; starting companion must resolve explicitly. Reject or use
   a clearly marked missing-asset sprite for malformed identity rather than inventing a believable
   stranger.
7. **Prevent bounded-seed collisions.** The current generated proof reduces variation to five mark
   bits (at most 31 nonzero combinations) on one fallback build. It proves determinism, not population
   capacity. Add independent bounded modules and collision diagnostics, then fixture a realistically
   sized persistent met pool for exact repeatability, acceptable duplicate policy and silhouette
   separation in both profiles.
8. **Round-trip exact Swift enums and units later.** Integration fixtures should encode/decode
   `TravellerID`, the four identity kinds, profile/facing/pose enums, all eight `GearSlot` raw values
   (including stored `armor` versus displayed “Body”), pixel dimensions and version tuple through
   Swift and the exported schema. This remains an Engineering integration gate; AssetLab tests alone
   cannot prove it.

The next Character Lab visual sheet may proceed without waiting for these game-model additions, as
long as it remains labelled authoring proof. Before its manifest is called integration-ready, add the
identity/render-request split, strict diagnostics and versioned identity kinds above. Portraits remain
an optional later profile; their absence should not block world/combat proof.

### 9 Aug 2026 — Character Lab v0.3 engineering follow-up

**Disposition:** recommendations only; source reviewed narrowly against the future identity-oneOf /
render-request boundary. No code was changed. The v0.3 direction remains compatible: named people
now own explicit authored descriptor axes (`build`, `hair`, `garment`, `carry`, `asymmetry`, personal
palette), generated descriptors resolve deterministically from a seed, the Binder has a genuinely
separate template, and gear/pose are supplied outside the descriptor. These close the earlier
conceptual coupling. The following are the only AssetLab-side blockers recommended before visual
golden status.

1. **Do not let the public resolver turn an unknown named ID into a plausible generated person.**
   `characterDescriptor(identity)` currently returns a named descriptor when found and otherwise
   silently calls `generatedCharacterDescriptor(generatedSeed ?? identity)`. That recreates the exact
   missing-identity failure the future `oneOf` is intended to prevent, and also lets callers render
   Binder through an arbitrary descriptor override. Split the AssetLab entry points now (named,
   generated, Binder), or require a closed `identityKind` and return a structured error/missing sprite
   for an unknown named ID. This is an AssetLab contract blocker, not a request to add native models.
2. **Passed-out rendering currently drops equipped gear.** `characterCommands` returns from
   `passedOutCommands` before applying the gear layer. The resulting fixture therefore proves an
   unequipped passed-out person, not the requested combined person-and-carried-gear pose, and risks
   an equipped actor becoming visually inconsistent precisely when down. Compose or repose the gear
   with the body and add assertions that each representative gear family remains present while the
   identity-owning head/mass remains readable and the result does not equal a loot/drop silhouette.
3. **The environmental-grade claim is not exercised.** The warm and cold panels change only the
   canvas rectangle behind byte-identical sprites; no separate grade render input or transform is
   applied. Either add a bounded environmental-grade render state that preserves every personal
   palette field before grading, with equality/contrast tests, or relabel this evidence as two
   background contexts and defer the grading claim. Personal palette must stay descriptor-owned;
   environment grade must stay request-owned.
4. **Make the gear evidence semantically and comparatively exact.** The current row labels blade as
   close, spear as far and bow as mid. The live catalogue normally uses spears as mid and physical
   ranged forms as far; visual proof should use reviewed visual-family names or correct reach labels,
   not imply a universal weapon-to-reach rule contradicted by items and wild exceptions. Exercise
   close/mid/far plus unarmoured/light/heavy protection on two contrasting bodies, as Design asked,
   and test the exact fixture assignments. Keep reach itself in render/game state rather than the
   identity descriptor.
5. **Strengthen the four generated-person fixture.** The source proves seed 42 repeats and differs
   from 43 across at least two descriptor axes, but does not prove seeds 41–44 are pairwise distinct
   in both native profiles or avoid the six reviewed named descriptors. Add those fixture assertions
   and an explicit duplicate diagnostic/policy. Population-scale collision and persisted-seed
   guarantees remain later integration work; this smaller check only substantiates the current
   sheet's visual claim.

Everything else from the earlier engineering review remains a **later native integration gate**, not
a reason to hold visual iteration: full immutable pipeline versions and canonical/pixel hashing;
persisted generated-person, Quill and Binder identity records; strict Swift `oneOf` decoding;
structured adapter diagnostics; exact `TravellerID`, `GearSlot` and pixel-unit round trips; all eight
live gear-slot mappings; and save migration/freeze policy. The Character Lab need not implement those
game-owned records to earn visual golden status.

### 9 Aug 2026 — Character Lab v0.4 engineering closure

**Accepted for AssetLab visual-golden review, recommendations only.** Source, focused tests and the
lossless 640×620 RGBA artifact were checked; `character-kit.test.js` passes. The five v0.3
AssetLab-side blockers are substantively closed:

- unknown catalogue identities now throw `unknown-character-identity` instead of becoming plausible
  generated people, while generated people require the explicit `generated_person` route and seed;
- the Binder uses its own frozen noncanonical template and is asserted unequal to Tovin;
- passed-out composition retains authored hair/garment/carry distinctions and supplied gear, with all
  28 named prone silhouettes pairwise distinct and an equipped-prone regression present;
- warm/cold `environmentGrade` changes pixel colors while silhouette geometry and the descriptor's
  personal-palette selection remain stable;
- `gearReach` and the proof now agree on blade = close, spear = mid and bow = far;
- generated descriptors 0–511 are pairwise unique and reserve exact named combinations. Seeds 41–44
  are shown in both profiles; their checked world hashes (`db0fc7e5`, `964085a6`, `8b20c9d4`,
  `84c6de35`) and combat hashes (`bd620b21`, `8a42768f`, `d3184ded`, `222a7f46`) are pairwise distinct.

The generic `descriptor` injection used by the isolated authoring renderer is acceptable for this
visual proof, but it is **not** the future application boundary. Native integration must still replace
that escape hatch with the previously recommended identity-kind `oneOf`, strict render-request enums,
structured diagnostics, immutable versions/hashes, persisted generated/Binder/Quill identities and
Swift enum/unit round trips. Those remain later integration gates and do not block v0.4 visual-golden
assessment.

### 9 Aug 2026 — Character Lab identity proof v0.4 final design disposition

**Accepted for visual golden promotion, recommendations only.** The lossless 640×620 proof and the
focused source/test assertions close the remaining v0.3 design gate. Full AssetLab tests are reported
green and the prior golden baseline remains 0/62 changed.

- Passed-out figures now recompose the same descriptor-owned person rather than substituting a
  shared prone body. Build length, hair/headwear, garment, carried feature and asymmetry survive the
  pose; all 28 named combat-prone silhouettes are pairwise distinct. The reviewed equipped prone
  example retains its blade and still reads as a person, not the wild-drop/loot grammar.
- The six grayscale examples retain individual identity through standing world/combat and prone
  evidence. No colour, label or status badge is required to tell them apart.
- Reviewed reach semantics are corrected and fixture-asserted: blade is close, the current melee
  spear family is mid, and bow is far. A future throwing/far spear remains a separate visual family;
  this proof does not silently generalise all spear shapes or encode reach into anatomy.
- Named IDs now reject unknown values instead of inventing plausible generated strangers. Generated
  descriptors are deterministic, collision-free across the exercised 0–511 pool and reserve exact
  named combinations. Persist descriptor plus generator version at the eventual app boundary; this
  visual acceptance does not replace that migration requirement.
- Warm/cold environmental grades now exercise bounded request-side colour transforms while personal
  palette remains descriptor-owned and silhouette-identical. The separate noncanonical Binder
  template and explicit never-Tovin assertion remain intact.
- Gear/protection remain render overlays, and no calling, stat, rank, reach or worldwork field selects
  a person's anatomy.

Promote v0.4 as the current Character Lab visual golden and retire v0.2/v0.3 as competing current
evidence. No further static character-grammar correction is required before continuing coverage.
The previously listed Engineering identity/render-request schema, eight-slot equipment mapping,
version/hash, structured-diagnostic and Swift round-trip items remain later integration gates, not
reasons to reopen this accepted visual milestone.

### 9 Aug 2026 — full-cast descriptor proof v0.1 design review

**Disposition:** recommendations only; the accepted Character Lab v0.4 boundary remains frozen and
the catalogue-wide direction passes, but make a small authored-descriptor collision pass before
promoting the 28-person expansion as golden. The lossless full-cast sheet was inspected in colour
and native grayscale.

#### Catalogue-wide findings that pass

- All 28 entries remain people within one coherent pixel vocabulary. The world figures retain the
  settled straight top-down footprint with no horizon, side-view ground or environmental patch; the
  combat figures consistently use the separate side-biased profile. No individual camera drift was
  found.
- World/combat correspondence survives across the full catalogue: dominant headwear/hair,
  shoulder/outerwear mass, carried side and stature recur in both views. Grayscale does not reveal a
  colour-only identity among the stronger examples.
- No exact duplicate appears, and the authored ordering matches the reviewed catalogue. The sheet
  does not expose stats, rank, reach or combat values in anatomy.
- Work may plausibly inform a deliberately authored coat, apron, robe or carried object, but the
  renderer still does not derive those features from `calling`. Preserve that one-way authorship
  boundary; a future calling change must not silently redress a person.

#### Descriptor corrections before full-cast golden expansion

Pairwise hash uniqueness is necessary but not sufficient at this density. Four pairs converge at
native grayscale because their shared hair/headwear and garment own most of the silhouette while
the remaining distinction is a small carry shape, palette or one-pixel build change:

1. **Corrin / Bracken** (`braid` + `apron`) is the strongest accidental duplicate. Change one large
   authored axis—head profile or outerwear mass—not merely palette, carried-kit side or width.
2. **Nessa / Auber** (`wrap` + `apron`, both round) needs the same treatment. Their kit-versus-satchel
   distinction is too peripheral to own identity at 16px.
3. **Halloway / Orsa** (`bun` + `apron`) remains separable on inspection but reads as a shared
   occupational uniform first. Give one a different head or shoulder/outerwear contour.
4. **Vance / Grimmond** (`brim` + `coat`) is a lesser collision: build and carry differ, but the broad
   brim dominates both views. Adjust one secondary large contour so recognition does not depend on
   the name or indigo-versus-green colour.

Also spot-check the narrow/no-carry world figures—especially Talin and Dagg—beside the accepted
wild-drop and traveller collision grammar. Their dark outline loses contrast against this sheet's
background, leaving a small head/body stack; require the existing shoulder/two-foot human read to
survive at native 16px without borrowing the adjacent combat portrait. This can be solved through
the accepted descriptor axes or review presentation contrast; do not reopen the camera or invent a
status marker.

The calling labels are useful catalogue metadata but prime the viewer to interpret apron, brim and
mantle as professions. For the correction proof, add an unlabeled native grayscale collision strip
for these eight near-collision people plus Talin and Dagg, identified only by review numbers beneath
the strip. Keep names/callings in a separate key. A reviewer should distinguish the pairs by whole-
person structure before consulting that key.

No new descriptor axis, palette, animation, face canon or renderer change is requested. Make only
the minimum authored descriptor substitutions needed to separate those pairs, rerun all 28 standing
and prone pairwise assertions, and retain the accepted v0.4 camera/palette/Binder/gear boundaries.

#### Full-cast descriptor proof v0.2 final disposition

**Accepted for full-cast visual golden expansion, recommendations only.** The corrected lossless
sheet and its unlabeled native 16px grayscale strip close the v0.1 catalogue-collision findings.
Standing and prone tests are reported green for the full cast, and the golden regression remains
0/99 changed.

- Orsa's loose hair separates her whole head/shoulder profile from Halloway's bun/apron structure.
- Bracken's hood creates a dominant head-and-upper-body mass distinct from Corrin's braid/apron.
- Auber's robe changes the lower-body contour and no longer relies on satchel versus kit to separate
  him from Nessa's wrap/apron.
- Grimmond's mantle changes the shoulder line beneath the brim, keeping him distinct from Vance in
  native grayscale rather than depending on palette or a peripheral carry mark.
- In the unlabeled collision strip, Talin and Dagg remain compact but retain head/shoulder/body
  structure. Both separate from the accepted single-object wild-drop silhouette; the broader
  traveller marker remains independently person-shaped. No map-camera drift is introduced.

The separate key correctly keeps names and callings out of the first-read collision evidence, and
the sheet reiterates that callings are reference labels only rather than anatomy generators. The
four substitutions stay within the accepted authored axes, so they do not reopen Character Lab
v0.4's renderer, personal-palette, Binder, generated-person, gear or pose boundaries.

Promote v0.2 as the current full-cast descriptor proof and retire v0.1 as competing evidence. These
authored features remain revisable art-direction choices, but no further descriptor correction is
required before continuing the dynamic-coverage sequence.

### 9 Aug 2026 — Resource Node proof v0.1 design boundary review

**Disposition:** recommendations only; catalogue coverage and disclosure direction are useful, but
the self-rejection is correct and the sheet is not golden. Do not solve it by forcing 23 arbitrary
unique 16px silhouettes.

#### Settled representation boundary for this proof

The ordinary top-down map must communicate, without colour alone:

1. a harvestable node is present and is not a wild drop, traveller, route, site or hazard;
2. whether it is remaining or physically exhausted;
3. whether the source is exposed mineral/material or an actual living flora instance; and
4. the honestly visible physical profile where applicable: heap, mound, vein, nodules, seam,
   crystal, shard, pool or core.

The map does **not** need every exact resource ID to have a mutually unique silhouette. Copper and
sulfur may share a nodule grammar; silver and gold may share a seam grammar; quartz and salt may
share a crystal grammar when their exact material is supplied by the disclosed interaction. Colour,
small inclusions and sparkle may support those families but cannot be the sole accessibility cue for
an interaction-critical distinction.

Exact resource name, quantity/yield, quality/properties and crafting meaning belong to the
interaction/accessibility label and inventory or inspection view once legitimately disclosed. If an
exact family has an unmistakable physical form—log, pool, shard, crystal—it may read earlier, but the
map should not invent a code merely to make all 23 IDs guessable at a distance. The minimap remains a
generic disclosed-node symbol plus spent state; it must not become a 23-icon material legend, and
fog reveals nothing.

For organic resources, the actual flora species is the map identity. A plant yielding fibre, timber,
pulp, resin, toxin, spore or reagent must retain its accepted species silhouette and straight
top-down camera. Before interaction, do not recolour or append a standardized organ that reveals a
hidden yield such as toxin. A disclosure-safe harvestable cue may indicate that the visible plant is
a node; the exact yield is named only when game knowledge/action state legitimately supplies it.

#### Smallest correction

1. **Normalize the mineral comparison.** Show every mineral family on one identical neutral
   substrate in colour and grayscale, grouped by physical profile. Then use a separate small
   inheritance row showing one representative profile across soil, stone, ice and ash. This isolates
   family/profile geometry from environmental adaptation.
2. **Make profile differences own the silhouette.** Heap versus mound, vein versus seam, nodules,
   crystal versus shard, pool and core should differ by whole mass and negative space at native size.
   Families intentionally sharing a profile need not be pairwise silhouette-unique; tests should
   instead assert profile-level separation and stable family accent/material fields.
3. **Keep exhaustion physical and profile-derived.** A depleted vein should become a scraped seam, a
   crystal a broken base and a pool a drained rim—not the same generic low bar with a family-index
   pebble. Exhausted state must retain enough of the original profile to explain what was worked,
   while no longer reading harvestable.
4. **Render organic nodes through the accepted flora renderer.** The current generic green substrate
   and resource body obscure the claimed plant context. Use at least two actual accepted flora
   species unchanged as the dominant sprite, with a small disclosure-neutral harvestable treatment.
   Show remaining/exhausted for one species and prove species identity survives the physical harvest
   change. Do not reuse triggered-hostile flora pose as resource state.
5. **Repeat the native collision fixture on controlled ground.** Include one mineral node, one flora
   node, wild drop, traveller, route/action marker and chasm/no-node, in colour and grayscale. Add an
   adjacent exact-name interaction/VoiceOver example to demonstrate where family identity is
   authoritatively disclosed rather than encoding it all into the tile.

The 23-entry catalogue may remain the inventory/inspection coverage ledger. The corrected map proof
only needs the nine mineral physical profiles, two real flora contexts, remaining/exhausted state and
the generic disclosed minimap symbol. No new resource families, mechanics or hidden-property reveal
are requested.

### 9 Aug 2026 — Resource Node Lab v0.2 engineering boundary audit

**Disposition:** recommendations only; no AssetLab or game code was changed. The lossless 720×720
RGBA artifact was inspected and the focused AssetLab test passes. The coverage ledger exactly matches
all 23 live `ResourceID`s (no missing or extra IDs), and the corrected acquisition distinctions are
directionally faithful:

- Mote is `realityCurrency` and renders no world body or minimap symbol; it must never enter the
  ordinary node renderer merely because it exists in `resources.json`.
- Raw Essence is assigned the accepted `wildDrop` grammar and disappears when collected rather than
  leaving an exhausted node. This matches the explicit worldgen comment and wild-drop placement/test.
- The flora link is exactly the live `FloraRules.floraResources` set: Timber, Fiber, Pulp, Toxin,
  Spore and Reagent. Resin remains a provisional exudate/deposit and Ichor a provisional pool/deposit;
  neither fabricates a flora identity. Rift-glass remains an unstable-substrate shard family.
- minimap output requires both revealed and discovered, hides wild drops and Reality currency, and
  shows a generic known/spent node rather than a 23-family legend. Unknown world resource IDs throw.

#### AssetLab-side blockers before boundary-golden status

1. **Remove the misleading `resourceNodeCommands = resourceWorldCommands` public alias.** It accepts
   every catalogue family, including Mote, Raw Essence and provisional deposits, under a name that
   promises a node. Keep a typed acquisition dispatcher or separate node, wild-drop, deposit and
   non-world entry points. The current implementation happens to return the intended pixels, but its
   API can silently teach a later consumer the wrong acquisition grammar.
2. **Make minimap dispatch resource-aware.** `resourceMinimapCommands` currently accepts a free
   `acquisitionKind` string with default `node`, but no `ResourceID`. A caller can therefore request
   Raw Essence or Mote, omit or misspell the kind, and receive a disclosed node symbol. Resolve the
   acquisition profile from a validated catalogue entry (or require a closed typed profile), reject
   unknown kinds/states, and test each non-node family through the public call.
3. **Require the resolved substrate contract for Rift-glass.** Its catalogue entry says
   `unstableSubstrate`, but the renderer still accepts arbitrary `environment` and the proof places
   it on ordinary soil in the collision row. Render the shard over the actual resolved
   unstable-ground/crack facts or emit a structured missing-context diagnostic; do not let the
   source-class label be the only evidence of instability.

These are API/semantic-routing corrections; the v0.2 family art, six-flora linkage and
Resin/Ichor placeholder silhouettes do not need redesign for Engineering.

#### Later native adapter gates, not visual blockers

- The live source currently contains a contradiction around Raw Essence: `Worldgen` explicitly
  places it as a wild drop and says that is its stated acquisition, but
  `BookRules.yieldTable(from:)` filters only Reality currency, so Raw Essence's ordinary
  `ResourceDef` can also enter the node table. Engineering/design must settle that native catalogue
  fact before an adapter derives acquisition automatically; AssetLab should retain the intended
  wild-drop profile meanwhile and diagnose a conflicting native classification.
- Native integration still needs a schema-validated acquisition enum, structured diagnostics,
  canonical manifest/version/hash tuple, exact `ResourceID` catalogue reconciliation, and Swift
  round-trip fixtures. Resin and Ichor should remain explicitly provisional until their ultimate
  acquisition path is settled; do not silently convert either to flora from older prose.
- Minimap requests must ultimately derive `revealed`, `discovered`, depletion and legitimate
  knowledge from live view state. AssetLab booleans prove the visual gate only; they are not an
  authorization model.

#### Resource Node proof v0.2 final disposition

**Accepted for golden promotion, recommendations only.** The corrected sheet closes the acquisition,
source-inheritance, exhaustion and grayscale findings without inventing new game rules. Mote is shown
as reality currency rather than a map node; Raw Essence is a removable wild drop; Rift-glass remains
an unstable-substrate node; and only Timber, Fibre, Pulp, Toxin, Spore and Reagent inherit actual
flora identity. Resin and Ichor now use neutral deposit/exudate grammar rather than falsely asserting
a plant source.

The physical profiles carry the useful first read in colour and grayscale, while exact material
identity remains in disclosed interaction text. Exhausted minerals leave worked cavities or fragments,
flora leaves a clipped physical remainder, deposits leave residue, and the wild drop disappears. The
minimap remains generic and disclosure-gated, including no symbol for Mote or Raw Essence. The native
collision row keeps resource, traveller, route and chasm ownership distinct. Promote v0.2 and retire
v0.1 as competing evidence; no further resource-family silhouette expansion is required.

### 9 Aug 2026 — Authored-place proof v0.3 design review

**Disposition:** accept as the current place-identity contract proof, recommendations only. The 18
village stations now have function-led silhouettes rather than a generic-house family, and the 15
world sites retain straight top-down camera and recognizable structural identities across warm/cold
or warm/ash palette adaptation. Palette and wear may adapt to a world; the authored silhouette and
interaction identity must not.

The lifecycle rows are useful state grammar, with two safeguards for subsequent fixtures:

- `tier3` is a visual stress case, not a promise that every station owns or can reach a third paid
  tier. Render only states the live station record actually supports, and let keeper-earned effective
  tiers share the same physical rung rather than fabricating a duplicate construction state.
- `guarded` must remain an independent occupation/encounter overlay on the unchanged site identity.
  Do not let the broad ground bar become the sole guarded cue, and do not imply that searching,
  exhausting or guarding changes the site's footprint or passability unless live rules explicitly do.

Search/exhaustion should continue to read as a local physical change—opened container, spent vent,
worked seam or disturbed surface—without erasing the site's recognizable form. Damage may change
parts and wear but must preserve station recognition and accessible interaction ownership. At native
size, status cannot depend on the environment palette alone. Station labels in the catalogue are
reference metadata; truncation in the contact sheet must not propagate to player-facing names or
accessibility labels.

With those boundaries recorded, v0.3 may become the place-kit reference. The smallest next proof is
the already-planned world-entry/return/outcome splash compositor using one place/world identity across
portal return, anchoring continuity, collapse, defeat and abandon, without visually revealing hidden
world parameters or promising persistence before the outcome is settled.

### 9 Aug 2026 — Resource Node proof v0.2 review

**Disposition:** recommendations only; acquisition taxonomy, mineral profile grammar and disclosure
boundary are accepted, with three small ownership/accessibility corrections before golden. The
lossless 720×720 sheet and focused source/tests were reviewed directly. The reported suite is green
and the pre-existing golden regression remains 0/165 changed.

#### Corrections closed

- Mote correctly has no world-node or minimap rendering; it remains a reality currency represented
  only in its legitimate UI/inventory surfaces. Raw Essence is classified as a wild drop and has no
  exhausted/minimap state. Rift-glass remains a harvestable unstable-substrate shard node.
- Timber, fibre, pulp, toxin, spore and reagent are the only resources inheriting actual flora.
  Resin is a separate exudate and ichor a pool/deposit, so neither falsely turns an ordinary plant
  into a standardized yield organ.
- The nine mineral physical profiles now compare on an identical substrate. Heap, mound, vein,
  nodules, seam, crystal, shard, pool and core are distinguishable by mass/negative space in native
  grayscale; families intentionally sharing a profile no longer pretend to be 23 unique map codes.
- Mineral substrate inheritance is isolated to the Quartz soil/ice/ash row, and the depleted mineral
  remnants are derived from their original profiles rather than one universal spent badge.
- The minimap remains generic and disclosure-gated, with fog/undiscovered empty and remaining/spent
  states distinct. The native collision row preserves node, drop, traveller, route and chasm
  ownership, and the exact Quartz name is correctly presented adjacent to interaction rather than
  encoded into the minimap.

#### Three corrections before golden

1. **An exhausted organic node must not replace its actual flora with a generic stump.** In
   `nodeTile`, flora is composed only while `state === "remaining"`; every exhausted flora-linked
   family therefore collapses to the same resource-kit remnant and loses the species that owns the
   tile. Keep the accepted flora sprite present and unchanged in camera/identity. Exhaustion should
   remove or physically alter only the disclosure-neutral harvest cue unless the game explicitly
   supplies a persisted species-specific harvested pose. Show one actual species remaining versus
   exhausted in colour/grayscale and prove that its flora identity pixels remain present.
2. **Delegate Raw Essence to the accepted wild-drop renderer.** Its catalogue card currently calls
   `resourceWorldCommands("essence_raw")`, creating a second drop silhouette while the collision row
   uses `tileContentCommands({type:"wildDrop"})`. The ordinary map must have one wild-drop grammar.
   Mark the Resource Lab entry as delegated and render the accepted tile-content wild drop (with its
   disclosed exact-name interaction), rather than letting resource profile `drop` compete with it.
3. **Use reachable accessibility evidence.** A disabled HTML button carrying the Quartz
   `aria-label` is not a sufficient VoiceOver/focus-order proof because disabled controls may be
   skipped as unavailable. Use an enabled inspect/harvest fixture when action is legal, or expose the
   exact name/state as ordinary accessible text associated with the disabled control. Keep the
   visible review line, but test the actual accessible name and disabled/enabled semantics rather
   than the attribute's presence alone.

No mineral redesign, new profile, family-specific minimap icon or hidden flora-yield cue is
requested. A compact correction showing organic context preservation, delegated Raw Essence and one
reachable Quartz accessibility example can close this gate; all accepted v0.2 mineral evidence may
remain unchanged.

#### Resource Node proof v0.3 final disposition

**Accepted for visual golden promotion, recommendations only.** The corrected 720×720 lossless proof
and source assertions close all remaining Resource v0.2 design gates. The full test suite is reported
green and the accepted regression remains 0/165 changed.

- Exhausted flora-linked nodes now preserve the exact accepted top-down flora species and remove
  only the disclosure-neutral harvest cue. The colour and grayscale evidence retains species
  identity instead of substituting a generic stump or revealing the exact yield.
- Raw Essence delegates ordinary-map rendering to the already accepted `wildDrop` tile-content
  grammar and disappears on collection. The resource renderer emits no competing drop silhouette;
  Mote likewise emits no map/minimap asset.
- Quartz inspection is an enabled, reachable action. Its accessible name is generated by the same
  resource interaction resolver that supplies family, acquisition kind, physical profile and state,
  rather than being an unreachable disabled-control annotation.
- Minimap resolution is resource-ID aware and rejects unknown IDs. Disclosure remains generic:
  unrevealed/undiscovered is empty, harvestable nodes use the known marker, spent nodes use the
  spent marker, and Raw Essence/Mote remain absent.
- Rift-glass now requires the explicit unstable-substrate context in the renderer and tests; the
  proof exercises that context rather than allowing an ordinary soil/stone adaptation to imply a
  legitimate rift deposit.
- Removing the legacy `resourceNodeCommands` alias leaves one explicit world-resource entry point
  and makes delegated acquisition ownership harder to bypass.

Promote v0.3 as the current Resource Node visual golden and retire v0.1/v0.2 as competing evidence.
The settled boundary remains: nine honest physical node profiles and actual flora identity on the
map; exact family meaning in disclosed interaction/inventory; generic minimap symbolism; fog reveals
nothing. No further resource-map correction is required before continuing dynamic asset coverage.

#### Resource Node v0.3 engineering closure

**Accepted for AssetLab boundary-golden promotion, recommendations only.** The 720×720 RGBA artifact,
source and focused test were checked; the test passes. All three v0.2 AssetLab routing blockers are
closed:

- the misleading `resourceNodeCommands` alias is absent; world rendering now routes through the
  acquisition-aware `resourceWorldCommands` entry point;
- minimap rendering requires a validated `ResourceID`, rejects unknown IDs, and derives suppression
  from the catalogue so Mote and Raw Essence cannot become node symbols through an omitted/free-form
  acquisition kind;
- Rift-glass rejects any context except `environment: unstable`, and both catalogue and collision
  evidence compose it over the rubble/unstable substrate rather than ordinary soil.

The supporting corrections also pass inspection: Raw Essence world-body commands are empty and its
proof delegates to the already accepted `tileContentCommands(type: wildDrop)` grammar; exhausted
flora removes only the harvestable resource cue while retaining the same accepted flora species
renderer; and the Quartz inspection control is enabled with an exact acquisition/profile/state
accessible label and click result. Mote remains intentionally blank in world and minimap evidence.

The previously recorded native Raw Essence node-table contradiction, schema/version/hash work,
structured adapter diagnostics, Swift `ResourceID`/acquisition enum round trips and live-view-state
authorization remain later integration gates. They do not block Resource v0.3 AssetLab promotion,
and no additional Engineering correction is requested for this visual boundary.

### 9 Aug 2026 — Splash lifecycle proof v0.1 design review

**Disposition:** recommendations only; accept the framed/page-like compositor, same-world reuse and
colour-independent value structure, but do not promote the outcome set yet. The sheet correctly
avoids an authored Binder face, undiscovered site identity and identifiable apex art, and it keeps
portal return, collapse and anchored continuity from becoming one generic “run ended” image.

#### Smallest semantic correction

1. **Defeat must not read as death or an abandoned body.** The current horizontal figure is the
   strongest object in the frame and reads as a corpse, while the actual outcome is involuntary
   return with carried-home/lost-haul resolution. Use loss of agency without a prone body: a closing
   page/frame pulling the party mark out, a disrupted return trace, or a fading/receding party symbol.
   Retain the world's intact geometry; defeat does not invent its fate.
2. **Waystone is a carried emergency instrument, not another world portal.** The upright violet
   doorway makes it look like a placed destination structure. Keep the same intact world and depict
   the small carried stone or its return mark at the frame/page edge, clearly distinct from the
   world's portal doorway. It must not imply the Waystone remains behind as a site.
3. **Do not canonize Abandon while its action/future fiction is unsettled.** Remove it from the
   promotable lifecycle golden or replace its picture with an explicitly noncanonical reserved-state
   card. A dark blank world currently implies erasure/cessation even though the action's world fate
   has not been decided.
4. **Make anchored continuity positive, not merely undamaged.** Preserve the intact scene and avoid
   tether imagery. A stable book-edge, bookmark, architectural brace or Atlas/anchoring mark may
   communicate that the realm remains addressable after departure. It must not look like an ordinary
   portal return with the doorway removed, nor imply that every anchored realm gains a literal shore.
   In the current fixture, the long gold baseline joining two end caps can read as either that literal
   shore or the retired tether; replace it rather than relying on the review caption to disambiguate.
5. Keep the entry-disclosed variant opt-in and data-gated. A disclosed site may use its exact authored
   top-down/site identity only when ordinary entry knowledge owns it; an apex remains a location-only
   mark until encounter, never the creature silhouette. The ordinary entry compositor receives no
   complete-world descriptor fields that could leak either accidentally.

Retain the same tree line, water/ground masses and frame proportions across lifecycle outcomes so
the player recognizes one particular world. Collapse alone may break that actual geometry. Outcome
names and descriptions remain accessible text; palette/frame colour cannot be the only distinction.

#### Splash lifecycle proof v0.2 final disposition

**Accepted for golden promotion with Abandon excluded, recommendations only.** Direct inspection of
the lossless colour/grayscale sheet confirms that the same tree line, water/ground masses, portal and
frame remain recognizable across every settled outcome; only genuine collapse breaks the world's
geometry. The AssetLab suite passes and regression reports 196/196 unchanged before promotion.

- Defeat now uses an abstract upward extraction trace with no body, death pose or invented world
  fate. The intact scene owns the first read.
- Waystone is a small carried edge-mark and no longer competes with the world's portal or implies a
  placed site. Preserve its outlined geometry at final phone size so it never depends on violet alone.
- Anchored departure keeps the ordinary exit available while an independent stable page-edge/frame
  treatment communicates continuing addressability. It introduces no tether and no universal shore.
- Abandon remains explicitly **reserved / noncanonical** and must be omitted from the golden manifest,
  exports consumed by the game and player-facing lifecycle enumeration until its action and world
  fate are settled. Its placeholder panel is review scaffolding only.
- The disclosed-entry variant remains a separate data-gated fixture. A site uses its authored
  identity without changing the settled camera contract, while the apex is a location-only mark.
  Neither field may be supplied to the ordinary entry compositor from hidden complete-world data.

Promote the six settled states plus the gated entry variant from v0.2 and retire v0.1 as competing
evidence. The next useful asset proof should return to uncovered dynamic families rather than add
more lifecycle outcomes or animation.

### 9 Aug 2026 — Splash lifecycle v0.1 engineering boundary audit

**Disposition:** recommendations only; no AssetLab or game code was changed. The 720×650 RGBA
artifact was inspected and the focused test passes. The renderer is currently pure and deterministic,
uses no installed-app/game coupling, rejects its tested concealed-site and apex-state contradictions,
and keeps the splash authoring surface inside AssetLab. It is a sound visual prototype, but the
following AssetLab contract issues should be corrected before boundary-golden promotion.

1. **Anchoring is continuity, not an exit outcome.** The live `RunExitSummary.Kind` cases are
   `portal`, `waystone`, `defeat`, `collapse` and `abandon`; `entry` is a transition direction and
   `anchored` is an independent world-continuity fact. The current seven-value `splashOutcomes` makes
   them mutually exclusive, so an anchored realm left by portal, Waystone, defeat or collapse cannot
   preserve both the actual exit cause and anchored continuity. Split the request into a transition
   (`entry` or `departure`), an optional validated exit kind for departure, and continuity
   (`unanchored` or `anchored`). Collapse may break current scene geometry while the anchored realm
   still remains addressable; the request must represent both truths.
2. **Remove permissive defaults from the public proof contract.** Calling `splashCommands()` silently
   invents an `entry` into `proof-world`, and unknown terrain falls back to soil; unknown light becomes
   the bright branch; unknown flora class silently removes flora. Require an explicit request and
   validate closed terrain/light/flora/continuity enums, booleans, nonempty world identity and known
   outcome/context combinations. Missing or malformed fields should return structured issues or a
   deliberate missing-proof card, never plausible scenery.
3. **Route disclosure through a sanitized view descriptor.** `siteProfile` accepts any nonempty value
   but the renderer draws one generic site, while `apexIdentityKnown` is accepted yet intentionally
   unused. That is safe from leakage today but creates false evidence that exact profile/identity
   routing works. Either delegate a validated disclosed site profile to the accepted site renderer,
   or accept only a generic `showDiscoveredSiteMarker` fact and stop carrying the profile. The splash
   render request should never receive apex identity at all for this profile; accept only the
   legitimate location-marker fact. This makes forbidden disclosure unrepresentable rather than
   relying on a field being ignored.
4. **Validate cross-field lifecycle semantics, not just isolated flags.** Departure requires one live
   exit kind; entry forbids one. Full-haul wording belongs to the live portal/Waystone summary rather
   than an AssetLab-authored assertion. An unanchored exit must not gain continuity marks, and every
   anchored exit kind must preserve the continuity channel. Abandon should remain excluded/reserved
   from promotable fixtures until its action fiction is settled, as Design requested.
5. **Strengthen determinism and input-ownership fixtures.** The current test repeats only one portal
   request. Repeat every promotable transition/context, including copied objects with different key
   insertion order, and assert that disclosure-forbidden fields cannot affect pixels because they are
   absent from the accepted request type. `worldID` is currently unused: either use a stable identity
   seed only for bounded composition choices or describe this as a world-facts composition rather
   than evidence of per-world identity. Remove other dead inputs such as `atmosphere` until they own a
   reviewed visual decision.

These contract corrections are compatible with the visual changes already requested by Design
(party-scale defeat, carried Waystone mark, reserved Abandon, positive anchored continuity and exact
opt-in site routing). They do not authorize changes to game lifecycle systems.

#### Later native integration gates, not current AssetLab blockers

- Build a schema-validated adapter from live entry context and `RunExitSummary.Kind`, plus a separate
  anchored-realm continuity fact. AssetLab strings must not become a second lifecycle authority.
- Add structured diagnostics (`code`, severity, JSON path, supplied value and repair/fallback), a
  canonical manifest, immutable schema/generator/module/palette versions, canonical-input and pixel
  hashes, and deterministic migration policy.
- Round-trip the exact Swift exit enum and units, verify disclosure fields are derived from legitimate
  entry knowledge, and ensure absent future enum cases fail visibly rather than defaulting to portal,
  collapse or entry.
- Native UI still owns accessibility reading order, outcome description, reduced-motion behavior and
  when a splash is presented. The PNG compositor owns imagery only.

### 9 Aug 2026 — Splash lifecycle proof v0.2 design disposition

**Disposition:** recommendations only; the requested visual corrections pass, but two request-
contract corrections remain before lifecycle golden promotion. The 720×650 lossless proof and
focused source/tests were reviewed directly.

#### Visual corrections accepted

- Defeat now uses an abstract rising/extraction trace over intact world geometry. It depicts no
  humanoid body, face, skin, clothing or dropped inventory and does not invent the world's fate.
- Waystone is a small carried instrument/return mark at the page edge, clearly distinct from the
  world's portal and not presented as a placed site left behind.
- Anchored continuity is demonstrated independently on the portal transition as an outside-scene
  book-edge tab. It preserves the same portal cause and intact scene, uses no tether/shore line and
  does not canonise one anchoring route's landmark for every anchored realm.
- Abandon rejects ordinary requests and appears only under explicit `allowNoncanonical` review
  opt-in. Exclude that reserved card from exported/promoted lifecycle assets until its fiction is
  settled; its black placeholder is not destruction, reset or void canon.
- Ordinary entry remains disclosure-safe. The apex input is location-only, and forbidden identity
  fields are rejected rather than ignored. Entry/portal/Waystone/defeat share an identical world-
  facts prefix; collapse alone breaks that geometry. Colour and grayscale preserve the distinctions.

#### Two final contract corrections

1. **Anchored continuity must remain independent for collapse too.** The v0.2 validator rejects
   `transition === "collapse" && continuity === "anchored"`. That re-couples the two channels the
   correction was meant to separate. An anchored realm can suffer the run's actual collapse outcome
   while its durable realm record remains addressable; the splash must be capable of showing broken
   current scene geometry and the outside-scene anchored continuity tab together. Remove the
   contradiction, fixture anchored+collapse, and assert both the collapse overlay and continuity
   channel are retained. This does not claim that an anchored realm collapses while the app is closed.
2. **Either render the accepted site profile or request only a generic marker.** `siteProfile` is
   now closed to six valid IDs, but `intactScene` still draws the same generic box for every value.
   This falsely suggests exact profile routing has been proven. Prefer delegating the legitimately
   disclosed ID to the accepted authored top-down site renderer and add a two-profile pixel-difference
   test. If this splash milestone intentionally wants only a generic discovered-site mass, replace
   `siteProfile` with a boolean marker fact so exact identity never enters the compositor. Do not
   accept exact data and silently discard it.

No further visual redesign is requested. A compact anchored-collapse panel plus exact-profile routing
(or the narrower generic-marker request) can close the gate while all accepted v0.2 panels remain
unchanged. Treat this as world-facts lifecycle composition until a later versioned visual seed proves
distinct per-world scene identity; that naming limitation does not block the corrected lifecycle
grammar.

#### Splash lifecycle v0.2 engineering re-audit

**Disposition:** recommendations only; four prior boundary areas close, two residual blockers remain
before Engineering boundary-golden acceptance. No AssetLab or game code was changed. The focused
test passes and the 720×650 RGBA artifact was inspected.

Accepted corrections:

- no render defaults or palette fallback remain; transition, continuity, terrain, light, flora and
  disclosure fields use closed allowlists, while extra world/disclosure fields and apex identity are
  rejected;
- portal/Waystone/defeat preserve the exact intact world-command prefix, continuity is independently
  composable for the exercised portal case, caller input is not mutated, and repeated entry rendering
  is deterministic;
- Abandon requires the explicit noncanonical escape and is clearly excluded from the promotable set;
- Waystone, defeat and anchored-continuity visuals now use the requested carried/party-scale/book-edge
  channels rather than portal, canonical-body or tether grammar.

Residual blockers:

1. **A disclosed site profile is validated but still not routed.** Every accepted `siteProfile`
   produces the same generic rectangle because `intactScene` tests only truthiness. Either delegate
   the selected accepted profile to the authored top-down site renderer, proving different accepted
   profiles change the site pixels, or replace `siteProfile` with a generic disclosed-site-marker
   boolean. Carrying an exact profile that has no effect still gives false contract evidence.
2. **Rejecting collapse × anchored contradicts the live lifecycle and the intended independent
   continuity model.** `endRunWithPartialHaul` saves the anchored realm snapshot for collapse just as
   it does for other exits; structural failure of the current expedition does not erase the permanent
   realm. The v0.1 review explicitly required representing both truths. Permit collapse geometry plus
   anchored continuity, or document and obtain a new settled design/game rule that collapse destroys
   an anchored realm before making this rejection golden.

One small strictness hardening may land with either correction: require `allowNoncanonical` to be a
Boolean and reject extra top-level request keys, since a truthy string and ignored top-level fields
currently bypass the otherwise exact-field posture. This is not a visual redesign.

The later native schema/version/hash, structured diagnostics, Swift round-trip and presentation gates
remain unchanged and separate from these two AssetLab blockers.

#### Splash lifecycle proof v0.3 final disposition

**Accepted for visual/boundary golden promotion, recommendations only.** Anchored continuity now
composes with collapse rather than contradicting it, preserving both structural failure of the
current expedition and the permanent realm's outside-scene continuity channel. Disclosed sites now
delegate to the accepted authored `siteCommands`; Signal Cairn and Salt Pan produce distinct pixels,
while apex disclosure remains location-only. Extra top-level fields and non-Boolean noncanonical
flags are rejected. Promote v0.3, retain Abandon only as excluded review evidence, and retire v0.1/
v0.2 as competing current proofs. The reported golden regression is 0/203 changed.

### 9 Aug 2026 — App Launch proof v0.1 design review

**Disposition:** recommendations only; the narrow launch/loading boundary and layout pass, but refine
the central mark before visual promotion. This is correctly a boot surface, not another world-
lifecycle splash.

- The 390×844 light/dark compositions keep all meaningful content comfortably inside the supplied
  portrait safe-area bounds. Frame, title and loading line occupy the same geometry in both themes,
  with value contrast surviving without hue.
- `Bookbinder` plus the restrained `Opening the Atlas…` line matches the current launch-loading
  decision. The ellipsis is static copy, not a percentage, filling bar or claim that bounded work is
  advancing.
- No Binder face/body, world, flora, site, resource, apex, portal or save-dependent art appears.
  Nothing in the composition says a new world is being generated on every app launch.
- The page frame can transition to Base honestly: the system surface and first in-app frame should be
  pixel-aligned; once actual initialization reaches Ready, reveal/crossfade directly to the existing
  Base. Do not fill the frame with generated scenery, animate pages into a world, cycle fake progress
  marks or delay a warm-ready launch merely to display the loader. Reduced Motion may use a direct cut.

#### One visual correction

The central gold mark does not yet read reliably as an abstract Atlas/book binding. Its long vertical
stem, short upper crossbar, broad foot and detached dark square can read as a capital `I`, sword,
cross, lectern or waypoint. Replace it with a small unmistakable binding/page silhouette: paired
page masses or mirrored page edges around a central spine, with one restrained separation/notch that
can suggest the torn Atlas without depicting a completed Atlas, literal world or portal. Keep it
abstract enough to avoid lore illustration, but make “book/binding” the first read in native
grayscale before the title is consulted.

Retain the current frame, copy, placement and light/dark palettes. The correction proof only needs
the revised mark at native and 2× scale in light, dark and grayscale. Add geometry assertions that
non-background launch content and both copy baselines remain between `safeTop` and
`canvasHeight - safeBottom`, and that light/dark themes share identical geometry. No animation,
progress UI, world content or game-launch implementation is requested from AssetLab.

#### App Launch proof v0.2 final disposition

**Accepted for visual golden promotion, recommendations only.** The lossless proof shows native-derived
2× light/dark colour and literal grayscale compositions. The revised central mark now reads as an
abstract open binding/book through paired page fields, central spine, mirrored outer edges and
restrained torn/worn notches; it no longer reads as an `I`, sword, cross, portal or generated-world
aperture. Frame/copy alignment and value hierarchy remain stable across themes, safe-area assertions
pass, and no face, world, site, apex, animation or progress claim has been introduced. Promote v0.2
as the App Launch visual reference and retire v0.1 as competing evidence. The reported regression
remains 0/203 changed.

### 9 Aug 2026 — explicit `mapTopDown` character-profile proposal review

**Disposition:** recommendations only; proceed with the additive profile. This is safer than changing
accepted `world` pixels in place, but `mapTopDown` must become the only integration-facing character
profile for explorable-map people. Mark the upright `world` profile legacy/proof-only in AssetLab so
two apparently valid map cameras cannot coexist at the eventual manifest boundary.

#### Camera and semantic criteria

1. Use an overhead, foreshortened **human** footprint with a clear facing axis: crown/hair mass,
   shoulders/upper back, body footprint and directional arms/feet. Avoid the proposed word/shape
   `radial`; radial symmetry is already flora and many-creature grammar and can make a person read as
   a rosette or spider.
2. No face, frontal chest plane, horizon, ground strip or soil/grass patch belongs inside the sprite.
   Terrain remains tile-owned. Hair/headwear should be read as crown shape from above, not a tiny hat
   pasted above an upright face.
3. Reuse the same resolved identity descriptor, not merely the same ID/palette. At native 16px each
   person should retain at least two correspondence anchors into side-biased combat—normally overall
   mass plus hair/headwear, garment shoulder shape, carried side or asymmetry. Not every fine descriptor
   needs a unique pixel at map scale, but named/generated pairwise silhouette tests must remain honest.
4. Keep authored `carry` distinct from equipped `gear`: carry may be a stable satchel/scroll/kit
   identity feature; blade/spear/bow/protection is a render overlay and cannot reroll anatomy. Overhead
   gear orientation follows facing and must not resemble route, crack, resource-node or site marks.
5. `worldGrade` may apply the accepted bounded request-side colour transform only. Personal palette
   remains descriptor-owned, geometry stays identical, and grayscale must preserve identity and
   human-versus-content distinctions.
6. Selected/current/targetability treatments remain tile/UI overlays with independent shape channels.
   Test base sprite equality with overlays removed, and do not spend identity pixels on selection.
   A selected/current person must still be recognisable where route and semantic content meet.
7. Do not imply that every party member occupies a separate world tile if the live map owns one party
   position. Exercise one solitary traveller/content occupant and one legitimate party/current marker
   composition; crowd layout is outside this sprite-profile proof.

#### Recommended first proof

The proposed six contrasting named people plus four generated descriptors and the separate
noncanonical Binder is a reasonable upper bound and need not be narrowed if the sheet remains legible.
Before propagating to all 28, give Mara, Isolde and Tovin at least two opposing facings; they cover
wide/coat/carry, slender/wrap/robe and hood/mantle extremes. Show the other identities in one settled
facing, then add a small overlay/collision row containing:

- ordinary terrain with one named traveller;
- route beside—not through—the person;
- accepted wild drop, resource node, flora, hostile creature and generic traveller marker;
- selected and current treatments separately and combined; and
- one close blade, mid melee spear and far bow footprint, with reach labels only in review chrome.

Review at native 16px and nearest-neighbour 2× in colour and grayscale. Require pairwise silhouette
separation for the fixture identities, deterministic generated descriptors across profiles/facings,
Binder never resolving through named-cast identity, overlay mutual-exclusion/combination assertions,
and zero face/stat/calling/rank/reach inputs in anatomy. Animation can wait until this static camera
grammar is accepted.

#### `mapTopDown` integrated proof v0.1 design review

**Disposition:** recommendations only; the additive profile boundary and integrated fixture are
useful, but the camera grammar is not accepted yet. Do not promote or integrate v0.1.

The source still constructs north as the familiar upright stack—head with a centered skin/face
rectangle above shoulders/chest, lateral arms and two feet below—and then rotates that complete paper
doll for east, south and west. The proof therefore reads as an upright person laid sideways/upside
down in several facings rather than one body observed from directly overhead. The caption's “no face/
front-elevation baseline” claim is contradicted by the visible `p.skin` face patch in
`mapTopDownIdentity`.

This is clearest in the native grayscale row: broad mantle/robe figures, including Tovin and the
Binder placeholder, become large rectangular furniture/site-like masses; narrower figures can read
as tools or dropped objects. Pairwise command hashes prove difference, not human readability.

#### Smallest correction

1. Recompose the neutral north identity around **occlusion from above**: crown/hair or headwear mass
   overlapping the upper-back/shoulder footprint, a foreshortened torso beneath it, and short
   directional limb/foot hints. Remove the centered face patch. A tiny nape/ear/hand skin cue may be
   visible only where the chosen facing honestly exposes it; no frontal face plane.
2. Once that north footprint reads overhead, rotating the whole footprint for four cardinal facings
   is acceptable. Re-prove Mara **and Tovin** in N/E/S/W so both an ordinary coat/carry and the worst-
   case hood/mantle mass survive rotation as people rather than tables or beds.
3. Keep the identity core away from a full rectangular tile fill. Mantle/robe may widen the shoulder/
   trailing contour, but preserve negative space around limbs and at least a small terrain read so
   site, flora and selected-frame grammar cannot own the same block silhouette.
4. Strengthen tests from pairwise uniqueness to semantic invariants: no face-plane command in this
   profile; base identity remains a strict subset/unchanged input beneath UI overlays; all six named
   and generated proof identities are pairwise distinct in every exercised facing; and the separate
   Binder descriptor never resolves through Tovin.
5. The fixture shows current, selected and actionable individually, but not selected+current together.
   Add that deliberate combined state and test both channels survive grayscale. Keep overlays in a
   shared map-overlay helper rather than allowing the review page to become a second game-state
   authority.

The terrain/content row, literal grayscale export, route-before-person layer order, disclosure-safe
content set, generated seeds and legacy `world: compact-upright-proof` labelling may remain. The next
proof need only replace the person pixels, add Tovin's facing row and one selected+current collision;
gear can continue to wait until the overhead human camera is accepted.

#### `mapTopDown` integrated proof v0.2 design review

**Disposition:** recommendations only; the true overhead camera grammar is accepted for the ordinary
build/garment examples, with one hood/mantle collision correction before visual golden promotion.

The v0.1 camera blocker is closed: crown/headwear now overlaps the nape/upper-back footprint, torso
and limbs are foreshortened with terrain-facing negative space, the centered face plane is absent,
and N/E/S/W rotate one overhead footprint rather than an upright paper doll. Mara, Halloway, Isolde,
Wren, Ashe, Orsa and the generated examples read as people from above in native colour and literal
grayscale. The legacy upright `world` profile remains explicitly non-integration-facing. Route,
terrain, disclosed content and current+selected/actionable overlays keep their separate ownership.

One native semantic collision remains: Tovin and the noncanonical Binder combine hood and mantle into
a broad hollow ring. In north/south the paired dark voids can read as eyes/mask openings; in east/west
the `C`-like mass approaches the accepted portal/site silhouette. At 8× this looks creature-like, and
at native grayscale the portal comparison in the same sheet confirms that colour is doing too much
of the separation.

#### Smallest final correction

- Keep the accepted overhead base and change only hood/mantle composition: make the crown a mostly
  contiguous stepped mass over a visibly directional upper back, avoid paired central voids, and
  preserve one asymmetric carry/arm plus separated boot/limb cues so the result cannot become a ring.
- Add a native grayscale collision strip containing Tovin N/E/S/W, Binder N/E/S/W, portal, site and
  one ordinary/unknown creature. Human identity must win by limb/back topology before labels or hue.
- Extend pairwise tests across every fixture identity at each shared facing, not only the default
  north silhouettes, and assert the hood/mantle result never matches the portal/site hollow-center
  topology.
- Treat the proof's locally drawn state marks as **review representations of game-owned state**, not
  as an AssetLab authority for final UI pixels. The combined current+selected evidence passes, but
  native integration will still own those overlays.

No change is requested to Mara or the accepted ordinary overhead anatomy, terrain/content rows,
generated descriptors, Binder's noncanonical status, palette grading or UI-state semantics. A small
hood/mantle correction sheet can close the profile; gear remains outside this milestone.

#### `mapTopDown` integrated proof v0.3 final disposition

**Accepted for AssetLab visual golden promotion, recommendations only.** The narrow hood/mantle
collision is closed without changing the accepted ordinary overhead anatomy. Tovin's contiguous
stepped crown, directional back mass, asymmetric limb/carry and boots remain human in N/E/S/W;
Binder retains a narrower separate noncanonical silhouette. Neither produces the rejected ring/eye
void, and both separate from portal, site and unknown-creature grammar in literal native-derived
grayscale. The original integrated colour/grayscale rows, current+selected evidence, bounds and
identity tests remain intact. Promote v0.3 as the current `mapTopDown` camera proof, retire v0.1/v0.2
as competing evidence, and keep the compact-upright `world` profile legacy/proof-only. The reported
regression remains 0/205. This authorizes AssetLab fixture promotion only, not game integration;
overhead gear/action animation remains a later milestone.

### 9 Aug 2026 — full-cast `mapTopDown` proof v0.1 disposition

**Accepted for AssetLab full-cast visual golden expansion, recommendations only.** All 28 authored
travellers retain the accepted overhead human grammar in N/E/S/W, with no individual camera drift or
blocking native grayscale collision found. The earlier large-axis descriptor corrections remain
effective after rotation; the closest pairs (notably Bryn/Dagg and Orsa/Sabine) still preserve visible
carry or apron/body distinctions rather than relying on hue. Hood, brim, wrap, loose hair,
mantle/robe mass, asymmetry and stature remain readable without creating new portal/site/creature
rings. Pairwise silhouette inequality in every facing supports the visual evidence. Promote this
full-cast proof within AssetLab; the compact-upright `world` sheet remains legacy/proof-only and no
game integration, gear, Binder/Quill persistence or renderer expansion is authorized. The reported
regression remains 0/224.

Nonblocking evidence note: the single-line key at the bottom clips the final names at the canvas
edge. Wrap or number that review key on the next routine export so every cell remains independently
auditable; this is review chrome and does not invalidate the accepted sprite pixels/order.

### 9 Aug 2026 — equipment visual-boundary proposal review

**Disposition:** recommendations only; proceed after the full-cast milestone with the following
boundary refinements.

- Treat the eight serialized slots as **coverage and attachment anchors**, not eight universal visual
  identities. The unlabeled grayscale row should contain one representative item assigned to each
  slot, with a separate key. Offhand, tool and keepsake can contain multiple honest visual families;
  a slot must not force every future item into one silhouette.
- Large silhouette may communicate a plainly visible functional family—blade, melee spear, bow,
  shield, helm, body protection, gloves/hand tool, boots, carried tool or keepsake—but exact stats,
  damage kind, ward, quality, reforge power, provenance and unique rule do not select shape. A visible
  authored construction may correlate with mechanics; the renderer must not reverse-engineer hidden
  mechanics into decorative codes.
- Keep the accepted reach examples exact rather than universal: current blade/close, melee
  spear/mid and bow/far are reviewed families. A throwing/far spear is a different visual/action
  family. Reach remains validated render/game state, never character anatomy or an inventory badge.
- Material may alter bounded colour, surface pattern, edge/inlay and wear where the material is
  honestly visible. Provenance belongs primarily to accessible inventory/inspection text. Reforge
  history and unique rules require explicit authored visible modules before changing pixels; no
  standardized glow, rune or colour may disclose an unknown unique effect.
- Resources and slotted items keep separate grammar. A resource pool/node uses the accepted resource
  boundary; a world item drop uses an item/loot footprint. At distance the map may reveal an honest
  broad family when visually obvious, but exact catalogue/unique identity appears only when
  disclosure state owns it. Include resource drop, item drop, node, writing and keepsake in one
  native grayscale collision row.
- One persisted item instance should reuse its resolved visual identity across world drop, inventory
  icon and character overlay. Those profiles may simplify detail but must retain the same dominant
  family/construction anchors. A crafted instance must persist resolved modules plus pipeline version;
  reopening, equipping or moving it cannot reroll appearance. A found authored catalogue item remains
  authored; a unique lore item is never procedurally invented from a rule string.
- Do not require every equipped slot to appear on a 16px map person. Inventory must represent all
  eight; map/combat profiles render only legitimately exposed layers. Head/body/hand/foot gear must
  preserve at least two character identity anchors, and tool/keepsake may be stowed. Layer order and
  clipping need explicit fixtures so armour does not erase the person and gear does not become route,
  crack, selection or protected-state UI.

The smallest proof can remain narrow: eight representative slot-covering inventory silhouettes;
close/mid/far and light/heavy families on two contrasting people; and one authored found item plus
one persisted crafted instance across disclosed world drop, inventory and character overlay. Show
native colour/grayscale, a separate review key, exact accessible item/slot labels and malformed/
undisclosed fallbacks. No crafting mechanics, stat formula, random unique item or native integration
is authorized by this asset proof.

#### Splash lifecycle v0.3 engineering closure

**Accepted for AssetLab boundary-golden promotion, recommendations only.** Source, focused tests and
the 720×650 RGBA artifact were checked; the focused test passes. The final blockers are closed:
collapse composes with anchored continuity and is explicitly tested; disclosed site profiles are
strictly allowlisted, delegate to the authored `siteCommands` renderer and produce pixel-distinct
Signal Cairn/Salt Pan evidence; extra top-level fields and non-Boolean `allowNoncanonical` values are
rejected. Abandon remains an explicit noncanonical fixture outside the promotable transition set.
No additional AssetLab contract correction is requested. Previously recorded native
adapter/schema/version/hash, Swift round-trip and presentation gates remain later integration work.

### 9 Aug 2026 — playable top-down map-slice export engineering review

**Disposition:** recommendations only; urgent native-consumption boundary review. No game or
AssetLab code was changed by Engineering. The pack correctly names all twelve live `GroundType` raw
values, uses four-way N/E/S/W adjacency bits 1/2/4/8, distinguishes passable `water` from impassable
`deepWater`, preserves straight-top-down flora, labels proof-only material clearly and exports
individual 16×16 sRGB RGBA PNGs. The following must be corrected or explicitly narrowed before the
pack is called integration-ready:

1. Preserve the latest Design-owned draw order: terrain → flora → crack/warning → content →
   route/action → party. Visibility is an early gate: unrevealed short-circuits every ordinary
   layer, because a transparent fog PNG cannot suppress pixels. Add an overlap fixture proving that
   the chosen content/party occlusion of the warning is deliberate; Engineering does not override
   this settled ordering in the adapter.
2. `elevation` and `isCrumbled` are listed as live inputs without matching assets/composition rules.
   Export their reviewed variants/overlays or declare them native-owned and remove the unsupported
   claim. Crumbled suppresses flora/content and owns the void result.
3. Fixed pre-rendered terrain PNGs all use proof seed 404, while the seed contract promises native
   hash-derived per-tile texture. Choose one contract: fixed lookup with no seed input, or a finite
   exported variant bank plus an exact cross-language variant-index algorithm. Native code must not
   reproduce the JavaScript command renderer.
4. Separate compressed-file SHA-256 from decoded RGBA pixel SHA-256. The current `sha256` is a PNG
   byte hash, not the canonical pixel hash required by the accepted asset boundary.
5. Close the nested JSON schema. Top-level `additionalProperties: false` is useful, but version,
   tile, input-contract and output objects currently accept arbitrary contents. Add required fields,
   enums/consts and `additionalProperties: false` recursively, including exact ground, adjacency,
   kind, owner, dimensions, colour space, alpha and filtering values.
6. The four exported flora descriptors are conformance examples, not a live flora atlas. Do not map
   arbitrary `Tile.flora` to them. Native resolves `Tile.flora: InstanceID?` through
   `WorldRun.flora` to `Flora(id, traits, worldSeed)`; a later adapter/cache must export that exact
   identity or use an explicitly labelled temporary fallback.

Proof-only outputs that native must not consume as runtime authority remain: sample maps and
placements, review route/party/site flags, minimap/grayscale/contact-sheet canvases, labels,
checkerboards, `floraDefaults`/presets and JavaScript command arrays. Content and party PNGs in this
pack are conformance fixtures unless their exact identity adapter says otherwise. Passability,
movement cost, sight blocking, reveal, crumble, content ownership and minimap promises remain game
rules; pixels never become those rules.

#### Corrected map-slice v1 engineering disposition

**Accepted as a native-adapter conformance contract, recommendations only.** The emitted canonical
manifest hash is `cd402df8c3733a73bc68e81f4fc776ce53e565584a4b695982f1a3b03c966fd7`;
both focused contract tests pass. All 138 PNG outputs are explicitly `conformanceFixture`, file and
decoded-pixel hashes are separate, terrain state coverage includes adjacency/elevation/crumble, fog
is an early composition short-circuit, and the closed live-flora mapping matches Swift's
`InstanceID(UInt64)`, `FloraTraits` and `worldSeed(UInt64)` fields with two checked vectors. No live
raw-value or unit mismatch was found.

Before a native renderer can claim deterministic parity, Engineering must define, freeze and fixture
the mandatory `terrainSeedUInt32` derivation from persisted `mapSeed`, tile coordinates and the full
immutable version tuple; proof seed 404 is forbidden. Top-down party/character art remains explicitly
uncovered, so the existing native party overlay stays in place for this slice. This acceptance does
not turn the conformance PNG set into an exhaustive runtime atlas or authorize consuming proof pages,
sample maps, JavaScript commands or placeholder flora identities.

### 9 Aug 2026 — terrain dynamic-depth correction

**Settled requirement from Aimee; game-design boundary for the revised AssetLab proof.** The playable
terrain system is not one canonical coloured sprite per `GroundType`. Each ground owns an assortment
of compatible feature templates, and every world applies a coherent world-conditioned visual grade.
Placement variation is deterministic from persisted world/coordinate/version inputs. The prior
single-output terrain fixtures remain useful conformance examples but cannot stand in for the live
generative range.

Keep three axes separate:

1. **Ground identity, adjacency and live state** own affordance: passability, shore/deep-water edge,
   elevation, crumble, cracking and other real interaction grammar.
2. **World grade** changes the shared palette/material atmosphere from real world readings. It may
   suggest the world's character, but must not disclose exact hidden values or written rune IDs.
3. **Placement template** selects mechanically neutral pebbles, grain, clumps, ripples, wear and
   compatible surface structure. It cannot invent a resource, hazard, route, crack, elevation, site,
   content marker or false passability cue.

Related ground families within one world share the grade so the map reads as one place rather than
individually recoloured noise. Across worlds, invariant silhouette/value/edge grammar must keep all
twelve grounds legible in grayscale, particularly ordinary versus deep water. Authored stations and
sites may adapt palette/material wear, but procedural variation never distorts their functional
silhouette identity.

The expanded dynamic-depth audit should evaluate every generated family across authored identity,
world adaptation, species/item identity, placement/specimen variation, lifecycle/state,
camera/profile, disclosure, accessibility and deterministic persisted inputs. Any family collapsed
to one canonical coloured output remains an explicit gap rather than being called complete.

**Template semantic correction:** feature variety remains mechanically neutral. The first catalogue
draft used names/forms such as rooted soil, duned sand, fractured ice, embered ash, reed-shadowed
water, tracked mud and shelved chasm. Those collide with separately owned flora, elevation, cracking,
heat, creature-presence and passability facts. Replace them with neutral microtexture families
(granular/clodded/layered, ripple/speckle, cloudy/bubbled/striated, fine/coarse/banded,
wave/dapple, mottled/glossy/ridged, mat/thread and broken-edge/stratified). A decorative template may
vary surface character; it never supplies evidence for a live layer that is absent.

#### Map-slice v1.1 final engineering verification

**Accepted as the explicit integration-ready terrain/flora conformance handoff, recommendations
only.** Canonical manifest hash
`7172f4687d41df2a10f9f99b028ca44c4ee3757907320fd5f0438a2adef172e6` and all 198
`conformanceFixture` outputs were verified through the focused AJV/export and live-contract tests.
The immutable tuple is contract 1, terrain 1, flora 1, tile-content 1,
`world-grade-1.0.0`, `map-slice-1.1.0`, `rect-compositor-0.2.0` and
`top-down-map-16px-1.0.0`. Strict negative mutations pass at pipeline, flora, vector, grade and output
levels. The deprecated terrain `speciesSeed` alias is removed by normalization and is not part of the
runtime request.

The world-grade vectors map cleanly from live readings: thermal/light midpoint means
`(peak + floor) / 2`, available water is Hydrology's `availableMagnitude`, and Vitality/Substrate use
`peak`. Geometry remains invariant under grade. No additional live raw-value, field or unit mismatch
was found. The remaining native obligation is unchanged: define, freeze and fixture the prederived
`terrainSeedUInt32` from persisted `mapSeed`, tile coordinate and the exact version tuple; runtime use
of proof seed 404 is forbidden. Top-down party/character rendering remains uncovered and retains the
existing native overlay for this slice.

#### Map-slice v1.1 minimap disclosure correction

**Verified; supersedes the immediately preceding manifest hash only.** The current canonical hash is
`05e23c9b233940a1141636cf225d63089c8a7eb8754ba1bf853a6bddefb07a46`; output count remains 198 and
the pipeline tuple is unchanged. Minimap visibility is now uniformly game-owned: every point of
interest requires legitimate reveal/discovery, the entrance portal is visible only because its
starting tile is revealed, and any future bounded knowledge must be explicitly supplied by the game.
AssetLab infers no exception. The closed schema rejects a `portalException` mutation and the focused
export test passes. Remaining native obligations are unchanged: freeze/fixture `terrainSeedUInt32`
with proof seed 404 forbidden, and retain the existing party overlay.

### 9 Aug 2026 — app-launch proof v0.1 disposition

**Recommended for native reproduction; behavior remains governed by
`app-launch-loading-current.md`.** The paired light/dark phone compositions establish the correct
fiction: Bookbinder opens an Atlas, rather than generating a particular world. The restrained page
frame, neutral binding mark and text disclose no Binder face, traveller, site, apex or save state;
the static composition remains intelligible in grayscale and does not depend on animation or a fake
progress claim.

Engineering should reproduce the same frame geometry and palette with LaunchScreen-safe native
constraints, then align the in-app loading view closely enough that the handoff does not jump. The
mark is decorative and hidden from accessibility; VoiceOver owns the one-time “Opening the Atlas”
announcement. Do not stretch the frame to chase every safe-area ratio: preserve its centered
proportions with generous breathing room. This visual acceptance does not accept startup latency;
cold/warm timing, failure recovery, malformed-save behavior and black-gap video evidence remain
separate release gates.

#### App-launch proof v0.2 superseding visual disposition

**Accepted for golden/native reproduction.** The revised centered mark reads as an open binding/book
rather than the ambiguous upright `I` in v0.1. The lossless proof covers light/dark and independent
grayscale at native 390×844 rendered nearest-neighbour to 2×. Frame, title and restrained copy remain
legible without a face, world disclosure, motion or progress fiction.

Engineering should reproduce the v0.2 open-book mark in both LaunchScreen storyboard and SwiftUI
loading surface; the plain `I` plus SwiftUI-only bottom bar is explicitly superseded. Match native
geometry, not the proof sheet's labels/background. Visual golden status still does not accept timing,
timeout/Retry serialization, save safety, diagnostics recovery or storyboard-to-first-frame evidence.

### 9 Aug 2026 — mapTopDown character proof v0.1 disposition

**Camera/disclosure direction accepted; golden/native promotion held for one focused readability
revision.** Direct inspection of
`AssetLab/artifacts/map-top-down-character-proof-v0.1.png` confirms a straight overhead camera,
16-pixel bounds, nearest-neighbour color/grayscale evidence, noncanonical Binder color, game-owned
interaction overlays and no hidden POI markers. Characters do not introduce a face/front-elevation
baseline or silently own party state.

At native scale, however, the unlabelled identity strip does not yet prove that all six named and
three generated silhouettes read as people rather than small decor/containers, and Mara's N/S axis
is too subtle to verify confidently before color. The smallest next proof keeps the integrated sheet
unchanged and adds a labelled nearest-neighbour inspection strip (derived from the same 16-pixel
sprites, not a new profile) at 8×: Mara N/E/S/W, the six named people, three generated people and the
Binder. Strengthen only the shared person grammar and N/S shape cue if that strip confirms the
ambiguity; preserve identity differences, overhead camera and POI ownership. Do not add faces,
canonical blue bodies, floating nameplates or equipment-shaped POI glyphs. Recheck the revised
silhouettes in the original native integrated row before golden promotion.

#### mapTopDown character proof v0.2 final disposition

**Accepted for golden promotion; native handoff remains a separate versioned contract.** Direct
inspection of `AssetLab/artifacts/map-top-down-character-proof-v0.2.png` confirms that the v0.1
ambiguity was a real source problem, not merely a labelling problem: its rotated upright paper doll
and skin-coloured face plane are gone. The revised sprites use overhead crown/headwear occlusion,
compact shoulders and foreshortened limb/garment geometry. Mara and mantle-heavy Tovin have
shape-readable N/E/S/W facings in literal grayscale; the six named people, three generated people
and noncanonical Binder retain a shared person grammar without collapsing their silhouettes.

The native integrated row remains busy by design, but characters read as occupants rather than
containers when paired with game-owned current/selected/actionable overlays. They do not borrow
writing, drop, flora, site or portal glyph grammar, and hidden markers remain absent. Promote the
reviewed fixtures and semantic/bounds tests. Then prepare an exact character adapter/version handoff
without modifying the already frozen map-slice v1.1 tuple. Engineering should finish terrain/flora
and disclosure integration first; adding characters is a subsequent bounded slice, not an excuse to
expand the current native-map checkpoint.

#### mapTopDown character proof v0.3 superseding golden disposition

**Accepted after direct Game Design Lead inspection; supersedes v0.2 for golden promotion.** The
focused hood/mantle correction removes the remaining hollow face-box topology from Tovin and the
noncanonical Binder. In literal grayscale their contiguous crown/mantle masses remain recognizably
people and are now structurally distinct from the nested-square portal, right-angle site and
multi-legged unknown-creature fixtures shown on the same sheet. Tovin's N/E/S/W axis remains
shape-readable without restoring a face plane or upright baseline, and the native integrated row
retains game-owned state overlays and POI clarity.

Promote only the reviewed identities/facings and their exact bounds/semantic fixtures. This is not a
blanket approval of unreviewed full-cast outputs. The separate character adapter must distinguish
named travellers, Quill, the player Binder and generated people from real persisted identity; it
must report missing identity rather than silently inventing a seed. The frozen terrain/flora
map-slice v1.1 tuple remains untouched.

### 9 Aug 2026 — character-map adapter v1 engineering audit

**Recommendations only; no AssetLab or game code changed.** The separate adapter is the right
boundary and does not disturb the frozen map-slice v1.1 contract. Its identity taxonomy covers the
currently relevant human map actors: exact authored `TravellerID`, persisted generated-person
`visualSeedUInt32`, Binder, and Quill. No fifth native human identity case was found; tamed animal
companions belong to a later creature-map contract. The exact pipeline tuple, signed world-grade
units, four cardinal facings, deterministic generated descriptors, and deliberate exclusion of
calling, statistics, gear, and game-owned overlays are appropriate. Unknown IDs, tuple drift,
invalid grades, and unavailable Binder/Quill appearances produce structured diagnostics without a
noncanonical visual fallback. The focused contract test passes.

One AssetLab-side blocker remains before this becomes a safe consumption boundary: the exported
adapter accepts unknown properties when called without prior JSON Schema validation. For example,
extra top-level `calling`, identity `stats`, or world-grade fields currently survive and return a
successful result even though the closed schema rejects them. Either make schema validation an
unavoidable part of `adaptCharacterMapRequest`, or accept only a branded/validated request through
the public API. Add direct public-adapter negative tests for excluded and nested extra fields; an
AJV-only test is insufficient because a native caller can otherwise bypass the intended closure.

Native integration gates are separate from that AssetLab blocker:

- Stationary named travellers have no persisted facing in the current live model. Engineering must
  freeze and test a canonical default or derivation (and persist it if direction becomes stateful)
  before constructing this required request field.
- Generated-person visual identity, Binder appearance, and Quill appearance are not yet persisted
  in the live model. The adapter correctly diagnoses those absences; native code must not substitute
  a proof seed or inferred appearance.
- Reconcile the schema's 28 authored IDs automatically against the live traveller catalogue so a
  future catalogue addition cannot silently lack a map identity.
- Treat the adapter's 32-bit request/rectangle/pixel hashes as local conformance diagnostics only.
  A production export/cache boundary needs canonical SHA-256 over the validated request including
  the complete immutable tuple; the packager and native verifier must agree on canonical bytes.

Subject to unavoidable schema validation, no additional AssetLab identity case or visual redesign
blocks the reviewed v0.3 character scope.

#### Character-map adapter v1 closure disposition

**AssetLab boundary blocker closed.** The public adapter now enforces the closed request contract
without relying on prior AJV execution. Unknown top-level, identity-nested, and world-grade-nested
fields return structured `unknown-field` diagnostics with exact paths; direct tests cover
`selected`, `identity.calling`, and `worldGrade.temperature`, and the focused adapter suite passes.
Exact tuple comparison continues to reject pipeline-version shape or value drift. Character-map v1
is therefore safe to promote for its reviewed AssetLab scope.

The previously listed native obligations remain integration gates, not AssetLab blockers: define
stationary-traveller facing, persist generated/Binder/Quill appearance where applicable, reconcile
the authored ID catalogue, and use canonical SHA-256 plus the immutable tuple for durable export and
cache identity. No proof seed or inferred appearance becomes canonical through this closure.

### 9 Aug 2026 — first native map visual diagnosis (engineering verification)

**Recommendations only; no game or AssetLab code changed.** Read-only inspection confirms both
reported causes. `WorldView.TileView` currently draws the same half-point grid stroke around every
tile after either renderer, which creates universal cell borders outside the accepted asset grammar.
Perimeter ownership should remain with the adjacency-aware water, deep-water, ice, and chasm
families; ordinary ground must not receive a separate universal grid outline.

`MapAssetRenderer.TerrainPixelGrammar` also mirrors the current proof elevation treatment as a
full-width dark brown bottom band plus a full-width highlight. That is the reported dirt bar and is
not a safe independent native convention. Engineering should hold this portion and mirror the next
accepted AssetLab contract/hash, where elevation becomes localized, interior, ground-derived height
cues. Do not change water adjacency while making that correction. This disposition identifies the
integration mismatch only and does not authorize Asset-side game edits.

#### Map-slice 1.2 terrain-correction handoff

**Engineering disposition; no AssetLab or game code changed.** The regenerated handoff closes the
elevation blocker. Consume grammar `map-slice-1.2.0` and canonical manifest SHA-256
`5b23f9e3eec4a424e99dc564c5a0080f280f284114997c350c76d7d2b89a3102`. The other tuple members and
198-output boundary remain unchanged. Elevation levels 1–3 now add paired, strictly inset contour
steps from the tile's graded ground palette; they contain neither a full-width/full-height cue nor
the legacy fixed brown. Water, deep-water, ice, and chasm adjacency edges are unchanged.

The exact Engineering-owned native change set is deliberately narrow:

1. Remove `TileView`'s unconditional `Rectangle().stroke(Palette.mapGrid...)`. Do not replace it
   with another universal tile border; adjacency-aware terrain commands own the permitted edges.
2. Pin `MapAssetContract.manifestSHA256` to the hash above and change only the grammar member of its
   tuple from `map-slice-1.1.0` to `map-slice-1.2.0` (including the stale 1.1 documentation label).
3. Replace only the native elevation-band block with the AssetLab loop: for each level below the
   tile elevation, place a five-pixel dark contour at `(2 + 3*level, 12 - 3*level)` and a three-pixel
   light contour one pixel right and one pixel above, using the already graded `palette[0]` and
   `palette[2]`. Preserve command ordering after adjacency edges and before later overlays.
4. Update the frozen terrain-seed vector expectations because the current derivation includes the
   complete tuple; the grammar-version bump intentionally changes its FNV payload. Do not retain
   old expected values or introduce proof seed 404. Then run the existing every-terrain-output
   SHA-256 conformance test, which should validate all elevation levels and unchanged adjacency
   families against the regenerated manifest.

This handoff does not authorize changes to ground facts, adjacency calculation, fog short-circuit,
flora, disclosure, overlays, minimap semantics, or output roles. One expected consequence should be
made explicit in Engineering notes: because terrain seed derivation includes the full tuple, this
grammar bump retextures deterministic noise on all native tiles, not only elevated tiles, while
remaining stable thereafter for the new tuple.

#### Map-slice 1.2 pre-golden chasm correction

**Hold native integration pending Design's integrated elevation-readability review.** Chasm is
missing ground and therefore cannot carry elevation. AssetLab now suppresses elevation commands for
chasm and omits the three impossible chasm-elevation conformance fixtures. The candidate remains
grammar `map-slice-1.2.0`, now with 195 outputs and manifest SHA-256
`6d0c21206a983d024a4b948fe7008a2be89676e5c934efa3f84bc8b194fd7996`. This candidate supersedes
the 198-output `5b23f9e3eec4a424e99dc564c5a0080f280f284114997c350c76d7d2b89a3102` pack, but must not yet be
pinned by native code. Full AssetLab tests pass with regression 0/224. Engineering should wait for
the reviewed golden hash; the previously specified universal-grid removal and native inset-contour
mirror remain the expected bounded change after approval.

### 10 Aug 2026 — true elevation extrusion native-boundary assessment

**Recommendations only; read-only review, with no game or AssetLab changes.** A true lifted surface
cannot be represented faithfully by the current 16×16 raster inside a fixed square `TileView` while
keeping flora, cracks, content and actors in separate unshifted SwiftUI overlays. The present raster
clips every command to 16×16, `MapTileArt` expands that image to the cell, and every overlay is
centred in the original cell. Simply moving terrain pixels upward would clip the surface and leave
game-owned objects apparently floating below it.

The smallest safe contract is one bottom-anchored tall terrain/composite sprite, not a larger map
cell. Freeze these geometry facts in the next contract tuple:

- logical footprint remains 16×16 and owns the unchanged tap/hit cell;
- one integer `riserPixelsPerLevel` and `maximumElevation = 3` define
  `maximumRiserPixels`; the raster canvas is exactly `16 × (16 + maximumRiserPixels)`;
- the cell/base pivot is the bottom 16×16 footprint. For elevation `e`, surface commands authored at
  `(x,y)` render at `y + maximumRiserPixels - e*riserPixelsPerLevel`; the exposed south face fills
  from the lifted surface's bottom edge down to the base footprint's bottom using that ground's
  already world-graded palette, never a fixed brown/material;
- chasm and unrevealed fog force elevation zero. Fog fills only the logical 16×16 footprint at the
  bottom of the tall transparent canvas, then short-circuits, so height cannot leak through fog;
- flora and every surface-owned warning/content/route/actor anchor use the same surface transform.
  Sidewall pixels render after the lifted ground surface but before surface occupants. Game-owned
  SwiftUI overlays must receive the resolved surface offset; keeping their present cell-centred
  placement is invalid;
- cache identity and conformance hashes include canvas dimensions, pivot, riser constant, elevation,
  full tuple and decoded pixels. Provide cross-language fixtures for every ground at elevations 0–3,
  fog/chasm suppression, and at least north/south neighbour height differences.

The existing per-tile `VStack`/`HStack` can support a bounded first implementation without replacing
the map with one monolithic canvas, but not unchanged. SwiftUI offsets do not affect stack layout and
stacks do not reserve overflow. Engineering must render each tall image bottom-aligned to its square
cell, reserve `maximumRiserPixels` of scaled headroom above the map (or the north row will be clipped
or overlap surrounding UI), and explicitly establish painter order by map row so southern rows draw
over northern rows. Do not rely on incidental `ForEach` sibling ordering; assign row `zIndex` from
world `y`. The map's outer container should clip only after including the reserved headroom, while
the individual cells must not clip their upward overflow. Hit testing remains on the square logical
cell through `contentShape`.

Overlay ownership is the largest current blocker. Terrain and flora are combined in
`MapPixelRaster`, but cracks, player, enemies, sites and other content are separate `TileView`
children. Each must either (a) be composed into a typed tall tile layer in the accepted semantic
order, or (b) share one exact pixel-to-point surface-offset transform and row painter order. The
latter is the smaller native change, but it requires moving all surface overlays together and
separating alert badges that intentionally float above an actor. A mixed policy will cause cracks,
routes or characters to sit on the riser/base instead of the lifted surface.

Before promotion, require an integrated native-scale fixture with elevation 0/1/2/3 north-south
neighbours, multiple ground materials, flora, crack, route, site, enemy and party; verify color,
grayscale, fog, top-row containment, tap ownership and row occlusion. The current 195-output inset-
contour candidate must remain unpinned: true extrusion changes renderer dimensions, pivot, hashes and
composition semantics and therefore requires a new grammar/profile version rather than a silent
replacement under `map-slice-1.2.0`.

#### Lifted extrusion candidate v0.1 engineering audit

**Recommendations only; no code changed.** The separate 16×19, bottom-pivoted candidate proves the
right basic native geometry: a complete 16×16 top surface shifts upward by one pixel per elevation
level, the exposed south face belongs to the elevated centre tile and uses its graded material
palette, and surface overlays can share the same translation. Keeping it outside the current map
handoff is correct. It is not yet a closed integration API.

Current AssetLab blockers before the integrated 5×4 proof:

- `southElevation` and caller-overridable `maxElevation` are permissive authoring options, not safe
  runtime facts. They clamp/round arbitrary values and allow callers to change canvas geometry. The
  renderer must own fixed geometry; native must supply one schema-validated resolved neighbour fact.
- Hidden ordinary ground retains its elevation, so the current candidate shifts the 16×16 fog fill
  upward and can leave transparent base pixels, disclosing height. Crumbled raised ground similarly
  produces a floating crumbled surface. Resolve rendered elevation to zero before geometry whenever
  visibility short-circuits or the ground state no longer supports a raised surface, as already done
  for water, deep water and chasm. Add pixel/bounds tests for unrevealed and crumbled inputs at all
  authored elevations.
- `liftedSurfaceLayerCommands` accepts arbitrary command arrays and silently shifts all of them. The
  eventual request/layer contract must enumerate surface-owned layers; badges or other screen-space
  overlays must be anchored relative to their actor after the actor shifts, not blindly treated as
  ground commands.

The smallest closed neighbour contract should expose a resolved south-face delta, not the south
tile's unconstrained elevation. Recommended exact field:

`southExposureLevels: 0 | 1 | 2 | 3`

Engineering derives it after ground-state and visibility resolution as
`max(0, renderedCentreElevation - renderedSouthElevation)`. The input schema is closed and fixes
`maximumElevation = 3`, `riserPixelsPerLevel = 1`, canvas 16×19 and bottom pivot `(8,18)` in the
immutable profile; none are request options. A concealed south neighbour must resolve through an
explicit visibility policy without reading hidden elevation—recommended `0` exposure until that
neighbour is revealed. Map boundary policy must likewise be explicit and fixture-backed rather than
masquerading as elevation zero; recommended boundary exposure is `0` for this first proof so the map
edge does not invent a cliff. If Design later wants an exposed world edge, add a distinct boundary
enum and version the contract.

Draw order for the integrated proof and native mirror should be contractual:

1. rows paint north to south, with explicit world-`y` z-order;
2. within a tile: lifted top surface, then its exposed south sidewall;
3. surface-owned flora and neutral decoration;
4. crack/warning;
5. content/site/route/action and actors in the already accepted semantic order, all translated by
   the same `surfaceOffsetY`;
6. actor-relative floating badges after their actor.

Later southern rows naturally occlude northern overflow and sidewalls. Hit ownership remains the
unshifted logical 16×16 cell. The 5×4 acceptance artifact should include north/south rises and drops,
equal terraces, a concealed neighbour, a boundary tile, a crumbled raised input, water/chasm, mixed
ground palettes, flora, route, crack, content and actors in color/grayscale. It should assert no
transparent hole in any logical footprint, no hidden-height pixel difference, and exact back-to-front
occlusion. Only after that proof passes should the candidate receive a new schema, tuple, manifest
hash and native-consumption role.

#### Lifted extrusion candidate API re-audit after closure fixes

**Recommendations only; no code changed.** The three previously reported implementation defects are
substantially closed. Geometry is frozen as `terrain-lifted-1.0.0` (16×19, pivot 8/18, logical
16×16, elevation maximum 3, one-pixel riser); hidden, crumbled, water, deep-water and chasm inputs
resolve to elevation zero; and the surface transform rejects a floating alert badge while accepting
only named surface-layer channels. Focused tests pass, including hidden/crumbled levels 1–3 and
invalid exposure bounds. Fog no longer moves according to hidden elevation or leaves the logical
base footprint uncovered.

Two strictness issues should close before this API becomes the native handoff rather than a proof
helper:

- `southExposureLevels` still defaults to zero when omitted. A production request must require the
  resolved neighbour fact; omission should produce a structured missing-field diagnostic rather than
  silently suppress a real wall.
- The renderer currently applies `min(resolvedCentreElevation, southExposureLevels)`. This prevents
  out-of-bounds pixels but silently accepts an impossible fact such as exposure 3 on elevation 1.
  Reject exposure greater than the resolved centre elevation (and require zero whenever centre
  elevation is forced to zero) so an adapter error cannot become plausible but incorrect art.

These checks belong in a closed request schema/public adapter with exact version tuple and structured
diagnostics; the existing permissive terrain normalizer remains appropriate for authoring previews,
not for native consumption. Add direct API negatives for omitted exposure, inconsistent exposure,
extra request fields and tuple/profile drift.

After those checks, the remaining gates are evidence/export gates rather than a geometry redesign:
the Design-requested integrated 5×4 neighbour/occlusion proof; explicit north-to-south row-order and
surface-layer-order assertions; and a conformance manifest containing canonical SHA-256, decoded
pixel hashes, fixed dimensions/pivot, closed layer enums, resolved-elevation/exposure vectors and
the same visibility/boundary policies. The proof caller must derive exposure from **resolved** centre
and south elevations, not authored raw elevation. Boundary and concealed-neighbour exposure zero is
acceptable for v1 when stated in that contract. Do not ask native Engineering to consume the helper
or artifact directly before these gates pass.

#### Map-slice v1.1 bounded contract correction

Engineering consumption must use canonical manifest hash
`f776ae97f252f462570014ca81d06df40e5a6de82aaa06c53671310e1912c28d`; it supersedes
`05e23c9b233940a1141636cf225d63089c8a7eb8754ba1bf853a6bddefb07a46`. The immutable pipeline
tuple, 198-output set, and renderer pixels are unchanged. Fog metadata now distinguishes the
transparent conformance sentinel from the compositor-owned invariant `#17171a` fill and confirms
that composition short-circuits after that fill. Cardinal adjacency is now exact: a bit is set only
when the in-bounds N/E/S/W neighbour has the same `GroundType` raw value as the centre; out-of-bounds
or different-ground neighbours clear it. Closed-schema and same-ground fixtures pass; regression
remains 0/224.

### 9 Aug 2026 — terrain border/elevation grammar 1.2.0 design review

**Disposition:** recommendations only; accept the user-reported border/bar correction, with one
semantic proof and one invalid-combination correction before treating elevation as a complete visual
golden.

The representative native exports confirm that ordinary soil, sand, stone, rubble, mud, ash, growth
and groundcover no longer receive a universal perimeter. Elevation no longer draws the rejected
full-width brown dirt bar: levels 1–3 add strictly inset paired contour steps using each ground's own
dark/light palette. Water, deep water, ice and chasm retain sole ownership of adjacency perimeter
edges, and those edge commands remain unchanged. This directly resolves the reported visual defect
without turning every tile into a bordered platform.

Two follow-ups remain:

1. **Prove relational height, not only command inequality.** On several native tiles—especially
   water/deep water, stone and growth—the small paired marks can read as ordinary ripples, cracks or
   texture when viewed alone. Add one compact integrated strip of adjacent elevation 0→1→2→3 tiles
   for a dry family and one wet/vegetated family, with the same seed/grade, in colour and literal
   grayscale. The contour staircase should read across tile relationships while no perimeter appears.
   Include one route/content overlay to prove the inset cue remains visible without taking semantic
   ownership from the occupant. Pairwise hashes remain useful but are not a perceptual height test.
2. **Do not draw a ground contour inside chasm.** Chasm's settled meaning is missing ground, not a
   low dark substrate. Requiring elevation 1–3 cues for all twelve grounds makes the void contain
   ledge-like interior marks and implies occupiable surface. Reject/suppress nonzero chasm elevation
   at the validated render boundary (or prove a distinct authored rim owned by neighboring tiles,
   not the chasm interior). Update the all-ground elevation assertion to reflect legitimate resolved
   combinations rather than celebrating mechanically distinct invalid states.

This does not request restoration of the brown bar, universal outlines or changed water/chasm
adjacency masks. The regenerated 198-output pack and reported manifest hash may remain the current
correction candidate; promote grammar 1.2.0 after the relational strip passes and chasm cannot emit an
interior elevation cue. The reported full-suite and 0/224 regression results are noted.

### 10 Aug 2026 — lifted-surface elevation contract recommendation

**Disposition:** recommendations only; adopt Aimee's lifted-complete-surface direction and supersede
the inset-contour candidate as the intended elevation grammar. Do not implement it as another band
inside a clipped 16×16 tile.

#### Camera and geometry contract

- Keep the map's straight top-down footprint and cardinal grid. Elevation adds only a consistent
  **downstage/south-facing low terrace face**; it does not introduce isometric x-offset, diagonal
  rhombi, perspective convergence or side-view terrain objects.
- One elevation unit should be a small fixed riser (start with 1 native pixel per level; levels 0–3
  therefore expose at most 3px). Current movement ignores elevation, so the result must read as a
  traversable terrace/grade rather than an impassable cliff. Do not increase wall height merely for
  drama without changing gameplay authority.
- Translate the complete 16×16 top surface upward by `elevation × riserHeight`. Terrain texture,
  adjacency-owned shoreline/ice/chasm edge pixels, crack, route and tile content all keep their
  top-surface relationship and anchor to the translated plane. Assert pixel equality against the
  elevation-0 top after translation; elevation must not repaint or crop the surface.
- Fill only the genuinely exposed gap with a wall derived from the **higher tile's resolved surface/
  substrate material** and world grade, normally a darker/lighter pair from that palette. No legacy
  brown, timber posts, universal outline, per-tile end stakes or full-width bar may appear. Adjacent
  equal-height, same-material wall spans should merge continuously rather than advertising 16px tile
  boundaries.

#### Adjacency ownership

1. Equal elevation: no elevation seam or wall. Same-ground surfaces join continuously; different
   grounds use only their existing terrain-transition grammar.
2. Different elevation north/south: the higher surface owns the exposed low riser facing the lower
   surface. Wall height equals the exact elevation delta; material comes from the higher surface.
3. Different elevation east/west: show only the silhouette/lip/end-cap necessary to close the terrace
   geometry. Do not draw a second full lateral wall or vertical stake line. An L-shaped plateau must
   remain watertight without making every east/west boundary a border.
4. A route crossing a height change must remain continuous across the translated top and short riser
   so the art does not falsely claim the legal move is blocked. The riser is not a new ramp/stair
   mechanic and cannot alter passability or movement cost.
5. Tile content, flora and people stand on the lifted top; selection/hit ownership follows the lifted
   visual while logical navigation remains on the original grid coordinate. No actor may appear
   embedded in the wall or on the unshifted baseline.

#### Invalid and deferred cases

- **Chasm:** no top surface and no elevation value. Reject/suppress nonzero chasm elevation. A visible
  rim or cliff face is owned by an adjacent solid higher tile, never painted inside the void.
- **Water/deep water:** do not extrude them as solid blue blocks in the first contract. Normalize them
  to surface elevation 0 until waterfalls, raised basins or water-level transitions have explicit
  gameplay/render facts. Deep water remains depth, not height.
- **Ice:** include one review case only if it is treated as a solid traversable shelf with an ice-
  material riser. Otherwise keep it at water-level elevation 0; do not silently choose between those
  meanings in the renderer.
- Growth/groundcover walls require the resolved underlying substrate/material. Vegetation remains on
  the lifted top and cannot turn the exposed wall into a green hedge unless the live tile facts
  explicitly describe one. If the substrate is unavailable, defer those combinations rather than
  falling back to generic dirt.

#### Rendering/export consequence

The current clipped per-cell `MapTileArt` cannot express this truthfully. Use a taller anchored asset
or map-wide compositor with top overflow of at least `maxElevation × riserHeight`, explicit top-plane/
logical-cell anchor metadata, and back-to-front row composition. Do not squeeze, crop or offset the
surface within 16×16. Terrain planes/walls render first; top-surface overlays and occupants then use
the translated anchor; UI overlays remain last. Native Engineering must later prove unclipped layout,
row ordering, hit testing and scroll/container behavior before consuming the profile.

#### Smallest proof

Build one native composed 6×4 terrace sheet, not isolated tile icons:

- a same-material soil plateau spanning several tiles at elevations 0/1/2/3, including one continuous
  front wall with no tile stakes;
- soil beside stone at equal and unequal elevations, proving the higher material owns the face;
- one L-shaped plateau exercising north/south and east/west joins;
- one route and one person/resource/site occupant crossing or standing beside a height change;
- chasm adjacent to solid height with no pixels inside the void;
- optional solid ice shelf, clearly labelled as that chosen meaning; and
- identical native colour and literal-grayscale panels at phone scale.

Acceptance requires: complete top-surface translation equality, no universal perimeter/brown band,
continuous same-material wall spans, exact delta-height faces, legal route readability, lifted content
anchors, no water/deep-water blocks, and no chasm interior elevation. This proof necessarily precedes
native integration; it is not a request to modify game passability, camera or elevation rules.

#### Lifted strictness closure and economy-station proof engineering recheck

**Recommendations only; file/artifact review only. No game, AssetLab, or Simulator changes.** The
lifted helper now requires an exact one-field exposure object, rejects omitted/extra/non-integer/
out-of-range exposure, rejects exposure greater than resolved centre elevation, and requires zero
for every forced-zero state. Focused tests pass. The two remaining API strictness blockers are
closed. Candidate golden still depends on Design's latest integrated terrace proof above; native
handoff still needs its closed schema, immutable tuple, canonical hashes and fixture vectors. This
does not authorize native consumption of the proof helper.

One source-level semantic dependency from the latest Design review remains unresolved by strictness:
`growth` and `groundcover` currently choose their green family palette for an exposed wall. If those
live ground values describe vegetation over substrate, the renderer needs a resolved underlying-wall
material input and must not invent a hedge-like green riser. Likewise, ice elevation remains a
design-owned solid-shelf decision. Exclude those combinations from golden/export until those facts
are settled or supplied; the strict exposure field alone cannot resolve material ownership.

The new authored `trading_post` and `recycler` built silhouettes are a sensible playability-roadmap
start. They use the settled Trading Post ID with no `exchange` alias; whole-mass grayscale tests and
the proof distinguish both from Storehouse, Workshop and Blacksmith; built/tier-3/damaged states are
shape-distinct; and staffing does not mutate station geometry. The artifact makes no live integration
claim, appropriately, because neither station exists in the current game catalogue.

One proof-coverage gap remains against the roadmap wording: the artifact shows built, tier stress and
damaged, but not foundation. Source currently returns the same generic foundation commands for both
new stations. Before calling their lifecycle evidence complete, either show that shared foundation
and record pre-identity construction grammar as intentional, or author functionally distinct
foundations and compare them in native color/grayscale. Keep tier additions physical as well: the
Trading Post horizontal accent and Recycler vertical accent should be reviewed at native scale as
structural additions, not generic colored state badges. These are AssetLab evidence questions only;
live station and economy-rule DTOs remain Engineering-owned.

### 10 Aug 2026 — Resource v0.5 native-handoff engineering audit

**Recommendations only; read-only review. No code or Simulator changes.** Design's timing and
composition boundary is coherent: version `resource-sheen-1.0.0`, 360 ms ticks, four moving frames
plus four quiet ticks, frame 0 under Reduce Motion, and placement after the resolved resource body
but before route/selection/party/UI. Pairwise silhouette tests cover all map resource families and
all 23 inventory identities, and focused tests prove moving sheen pixels remain inside the supplied
resource/cue footprint. Three integration blockers remain before native consumption.

1. **Freeze the native phase key and hash bytes.** Live `ResourceNode` has no instance ID; tile
   position is the available stable placement identity. Define one exact public ASCII key from the
   persisted run identity plus coordinate (for example `run:<decimal>/tile:<x>,<y>`), rather than
   coordinate alone, node fields, Swift `hashValue`, or an AssetLab proof string. Pin the FNV-1a
   algorithm/encoding with cross-language phase vectors, including negative coordinates if legal.
   The current JavaScript helper accepts any string/number and hashes JavaScript character units;
   native parity is not specified for arbitrary text. A canonical ASCII key removes that ambiguity.

2. **Make state/profile exclusions unavoidable.** `resourceSheenCommands` clips whatever command
   list a caller supplies. It does not itself reject Mote, exhausted bodies, fog/minimap commands or
   a zero/invalid public ID; Mote passes today only because its test supplies an empty list. Expose a
   closed public request/adapter that resolves a world body's eligibility from exact resource ID,
   revealed state, remaining state and world profile before producing sheen. It must return no sheen
   for Mote, exhausted, fog, minimap, absent body, and any disallowed acquisition profile, with
   direct negative tests. Raw Essence may animate only through its accepted revealed remaining
   `wildDrop` body, never through a fabricated node.

3. **Export a verifiable body+sheen contract.** The animation constant is frozen, but distinct
   `resourceWorldCommands` silhouettes currently have no closed schema/version tuple or native
   conformance vectors. Native cannot prove that its body mask—and therefore its clipped sheen—
   matches AssetLab from the test suite alone. Publish at least representative mineral, flora cue,
   unstable Rift-glass and Raw Essence vectors with canonical request, rectangle and decoded-pixel
   hashes, plus the 23-ID/raw-value reconciliation. Include remaining versus exhausted and the four
   active frames. Until then, Design acceptance is a visual golden, not an integration-safe renderer
   handoff.

For the native compositor, use one map-level tick source rather than a timer per tile, read the
system Reduce Motion environment, and retain the exact game-owned reveal/remaining checks before
requesting a frame. This avoids synchronized flashing, unnecessary full-grid timer ownership and
disclosure leakage while preserving the accepted layer order.

#### Resource sheen v1.1 closure re-audit

**Recommendations only; read-only review. No code or Simulator changes.** The phase-key, FNV-1a
UTF-8 encoding, UInt64 decimal transport, 23-ID fixture, exclusion routing and representative
command/decoded-RGBA hashes close the prior cross-language and evidence gaps. Phase vectors include
maximum UInt64 and negative coordinate transport; Ore, Fiber, Rift-glass and Raw Essence cover the
important body families, exhausted state and all four active frames. Focused tests pass.

One production-boundary blocker remains: `resourceMapSheenCommands` accepts an arbitrary
`bodyCommands` array from its caller. Checking `bodyKind` against the resource acquisition kind does
not prove that those commands are the accepted revealed remaining body for that resource. A caller
can label fog, minimap, exhausted, unrelated-resource or invented commands as `resourceCue` and the
adapter will sheen them, so the advertised exclusions and alpha clipping are not yet unavoidable.
The production API should either resolve body commands internally from the exact resource/context,
or accept only an opaque/branded output from the frozen resource-body renderer and verify its
resource ID, profile, state and hash. Add direct negatives for mismatched resource body, minimap/fog
commands and exhausted-body commands disguised as `state: remaining`. After that, no further
AssetLab-side resource-sheen blocker was found; native still owns the single map-level clock, Reduce
Motion environment and accepted compositor layer order.

#### Lifted terrain v1 contract and neutral-foundation final engineering disposition

**Recommendations only; read-only review. No code or Simulator changes.** The AssetLab lifted-
terrain boundary is ready for candidate-golden/native adapter work. The Draft 2020-12 schema is
closed at request, tuple and world-grade levels; the public adapter independently enforces closure,
exact live ground values, Boolean/unit ranges, immutable tuple, required resolved exposure and the
cross-field forced-zero/exposure rule with structured diagnostics. Ice, growth and groundcover now
join water, deep water and chasm as forced-zero pending explicit shelf/substrate facts. Focused
schema/adapter negatives pass.

The two fixed vectors correctly pin canonical-request, rectangle-command and 16×19 row-major pixel-
token SHA-256 values for distinct terrain/grade/elevation/crack cases. Their declared limitation is
truthful: `pixelTokenSha256` is conformance-only, not a decoded RGBA or PNG hash. Native Engineering
may use these vectors to build and cross-check the adapter, but production asset/export promotion
still requires the integrated Design-approved terrace proof and, if PNGs become the consumption
boundary, file plus decoded-RGBA SHA-256 fixtures. Do not substitute the helper's 32-bit hashes for
durable cache identity.

The economy-station artifact now explicitly shows the identical neutral pre-identity foundation and
states that station identity begins when built. That closes the earlier evidence ambiguity: the
shared foundation is intentional, visible, and not used to identify either station. Built Trading
Post and Recycler remain whole-mass distinct in native grayscale, staffing remains an independent
occupant, and tier/damage stress remains covered. This AssetLab proof is ready for its stated authored
station scope; it does not claim live catalogue, economy-rule or screen integration.

### 10 Aug 2026 — opening-economy station identity proof disposition

**Disposition: recommendations only.** Direct review of
`AssetLab/artifacts/economy-stations-proof-v0.1.png` and its source fixtures accepts this narrow proof
for golden promotion. The five unlabeled native-grayscale silhouettes are distinguishable by whole
mass and negative space: the Trading Post is an open, balanced canopy/counter with separated stock
masses; the Recycler is an asymmetric dismantling line with a tall intake and offset separation
bench; the Storehouse remains a broad enclosed storage body; the Workshop is a long workbench with a
raised tool/chimney mass; and the Blacksmith retains its heavy forge/chimney profile. Trading Post and
Storehouse share an architectural vocabulary appropriate to the village, but they do not collide at
native size: open counter versus enclosed central body is the dominant read before emblem or color.

The Trading Post built, tier-stress and damaged examples preserve the same merchant-workspace
identity without drawing coins, conversion arrows, or a generic exchange device. Its form therefore
promises a staffed counter and visible stock, but makes no hidden claim about exact eligibility,
prices, quantities, refresh timing, or resource-to-resource conversion. Player-facing and manifest
identity remains **Trading Post / `trading_post`**; the explicit rejection of `exchange` is correct.
The Recycler likewise remains a physical intake/separation workspace through tier and damage, not a
Blacksmith, Storehouse, or magical conversion badge. Its silhouette does not claim which item is
eligible or what recovered material will result; those facts remain disclosed by the transaction UI.

Tier additions and damage cuts are subordinate physical changes rather than replacement badges, and
both stations remain recognizable in grayscale across all three reviewed states. Staffing is
correctly outside station geometry: staffed and unstaffed hashes are identical, so Vance, Noll, or a
future valid keeper must be a separately rendered visible occupant/accent and cannot recolor or
reshape the building into a different station. Promotion should retain the existing collision,
state-inequality, bounds, palette-invariance, no-`exchange`, and staffing-equality fixtures. No
broader station redesign or additional economy symbol is requested.

### 10 Aug 2026 — equipment item-grid bridge v0.2 disposition

**Disposition: recommendations only.** Direct visual and source review accepts
`AssetLab/artifacts/equipment-grid-bridge-proof-v0.2.png` as the candidate proof for this narrow
sole-tester equipment-grid boundary. The default button, rendered heading, count, color tiles and
literal-grayscale tiles now agree on the exact Weapon filter. The resolver audits All and all eight
live serialized slot values, including player-facing **Body** for `armor` and **Off-hand** for
`offhand`; filtering remains navigation and does not mutate item ownership.

The Worn Mara Pointed Blade is a clear pinned comparison baseline. Stored, Worn, safe home Overflow
and current-world Carried each occupy the same independent badge channel but now combine full text
with a distinct small shape, so ownership survives grayscale without recoloring or rerolling the
item icon. Overflow reads as a safe waiting location under a full Storehouse, with no loss glyph;
Carried states that the item is in the current world and unavailable at home, and never implies
Worn. The one-column accessibility-large example preserves name, slot, owner/location and exact
comparison without clipping.

The four labelled location snapshots correctly represent review snapshots rather than four
simultaneous copies: one stable instance ID, one family and one icon hash persist while location
changes mutually exclusively. Tests also pin the Worn Mara baseline and exact signed comparison
strings (`current · 6 damage`, `−2 damage`, `+1 damage`, `+0 damage`), while rejecting a green/red or
generic “better” claim. This is truthful comparison evidence, not an assertion that reach,
availability or unknown properties can be collapsed into one quality rank. Unknown properties stay
unknown and provenance remains inspection text when legitimately known.

Promote with the focused resolver, slot-name, stable-identity, baseline and signed-string fixtures.
This acceptance covers AssetLab item/tile/location grammar only; live Storehouse actions, capacity,
transaction eligibility, VoiceOver implementation and native adaptive layout remain Engineering/UI
integration responsibilities. No additional icon family or grid redesign is requested.

### 10 Aug 2026 — six-across equipment and Pointed Blade checkpoint disposition

**Disposition: recommendations only.** Direct review accepts
`AssetLab/artifacts/equipment-six-across-proof-v0.3.png` as the current equipment-grid candidate and
retires the earlier two-column v0.2 card proof to history-only status. Exactly six compact icon cells
fit each 390pt phone row. Grid cells carry item shape, quantity, location, unknown state, rarity and
selection without names underneath; the tapped detail correctly owns full name, known provenance,
known stats, quantity, location and available actions. The All view and eight exact slot filters
remain resolver-backed.

Selection and rarity now remain independent in grayscale: an ordinary item is selected beside an
unselected fine item in the color proof, and the combined selected-plus-fine case preserves a strong
outer selection edge plus the separate inner fine border. Unknown and singular corner grammar do
not replace those channels. The selected Worn Mara Pointed Blade now offers **Take off** and
**Inspect**, never Equip. Resolver fixtures correctly give Stored **Equip**, safe Overflow **Store
first**, and current-world Carried **Unavailable**, each retaining Inspect. These actions express
location truth and do not mutate item identity.

Direct review also accepts
`AssetLab/artifacts/blacksmith-pointed-blade-checkpoint-proof-v0.1.png` for its narrow first-craft
checkpoint. Empty names the two missing sample requirements; Shortfall shows selected sample
identities, Essence `8 / 12`, and that nothing was consumed; Ready provides an exact Pointed Blade
preview and **Review craft**; Confirm alone names the destructive losses and uses **Confirm craft**;
Result records new instance `#9001`, Stored location, wallet `24 → 12`, removed inputs and **View
stored**. The sequence makes no reforge claim and does not expose hidden provenance.

Promote both proofs with the six-column, filter, orthogonal selection/rarity, location-action and
transaction-state fixtures. This accepts AssetLab visual/semantic grammar only; native action
availability, transactional atomicity, dynamic type, VoiceOver and save/reload persistence remain
Engineering integration gates. No additional visual correction is requested.

#### Resource sheen v1.1 final closure

**AssetLab integration blocker closed; read-only recheck, with no code or Simulator changes.** The
production adapter now derives the canonical remaining world-body silhouette from the exact resource
ID and required body kind before considering sheen. Rift-glass resolves through unstable context and
Raw Essence delegates to the accepted `wildDrop` body. Caller geometry must match that canonical
silhouette; a disguised full-tile/fog mask now rejects with `resource-sheen-mask-mismatch`, while
state/reveal/discovery exclusions still short-circuit to no sheen. The focused resource contract and
conformance tests pass. No remaining AssetLab-side resource-sheen handoff blocker was found. Native
Engineering retains the documented obligations for one map-level clock, Reduce Motion, persisted
phase facts, exact fixture parity and compositor layer order.

### 10 Aug 2026 — resource world-conditioning ownership recommendation

**Recommendation only.** World conditioning belongs to the map presentation, not persisted resource
identity. Resource family geometry, negative space, internal value ordering and canonical inventory
palette remain stable. Terrain and exact host flora continue to receive their existing `worldGrade`;
an on-map resource body or harvest cue may receive the same versioned, bounded environmental color
transform only as local lighting. The transform must preserve the family’s signature hue/value
relationships and minimum contrast against its resolved substrate or host. If a grade would collapse
that contrast, clamp the transform while retaining a family-stable outline/highlight rather than
changing silhouette or choosing a different semantic color.

`worldGrade` may derive only from legitimate world-level visual facts. It must never encode resource
rarity, grade, yield, eligibility, danger, provenance, exhaustion timing or other hidden properties.
The same resource rendered in two worlds may therefore look warm/cool/dimly lit while retaining
identical commands and grayscale silhouette; its neutral inventory/inspection icon remains the
canonical ungraded identity. Flora-linked cues grade independently as resource accents over the
already graded, unchanged host species. Exhausted remnants use the same bounded lighting rule but do
not sheen. Mote remains inventory-only; Raw Essence retains the accepted `wildDrop` geometry and
should receive map lighting only through that body’s shared presentation contract, not a special
resource-only recolor.

Sheen remains a disclosure-neutral luminance overlay after grading, clipped to canonical
resource/cue pixels. Its cadence, mask and relative brightness do not vary with `worldGrade` or any
resource property. A later proof should assert geometry equality across extreme accepted grades,
family separation in literal grayscale, contrast floors on representative substrates/hosts, and
canonical neutral inventory pixels. No new resource descriptor axis is required.

### 10 Aug 2026 — Trading Post/Vance semantic fixture engineering audit

**Recommendations only; read-only review. No code or Simulator changes.** This fixture must remain
non-integration-golden. Its broad interaction grammar is useful, but the current contract and artifact
make several claims that are not backed by live DTOs.

Current AssetLab contradictions/unsafe claims:

- `tradingPostContract` presents `persisted-snapshot`, `goldCoins`, confirm-only mutation and Vance
  ownership as a versioned contract. The artifact reinforces these as “stock snapshot #4”, wallet
  state and “saved atomically”. None exists in checked-in game source. Mark the entire fixture
  explicitly **proposed/noncanonical semantic data** on the sheet and in exports; do not call it a
  native resolver contract or persistence proof.
- `commitTradingPostPreview` does not commit anything, validate a revision/token, or mutate saved
  inventory/stock/wallet atomically. It accepts any object with `state: preview` and
  `mutationAllowed: false`, then returns text claiming success and flips `mutationAllowed` true.
  Rename/remove this pseudo-commit from evidence. A proof may render a hypothetical completed state,
  but must not assert “saved atomically” until a real rules-owned transaction result supplies it.
- The material row uses invented global identity `sample-301` and family `keepsake` for a Fang
  sample. Live samples have no global ID; the truthful handle is bin ID + sample index + full receipt,
  and Fang's material kind is `fang`. Its grade/receipt is also absent even though the four-gold
  value depends on the proposed material grade band.
- The bought Quartz result says “added to Stored”. Quartz is a stackable `ResourcePool` value, not a
  slot item in Stored inventory. Use a resource-specific hypothetical destination such as
  “Resource stockpile” and keep it labelled proposed until a live transaction DTO resolves wording.
- “Locked · Keep”, stock sequence/outcome, stock quantities, Gold Coin wallet, all prices, eligibility
  and Vance's station ownership are proposed design facts, not live facts. Vance's authored identity
  itself is valid, but live data still classifies him as mid-campaign and does not link him to a
  Trading Post station.

The source's exact-key checks are helpful for a static fixture but do not make the model safe: stock
row kind/resource identity/family/price consistency is not validated, holding identity branches are
not typed, integer arithmetic is not bounded to safe totals, and there is no revision or duplicate-
handle validation. Do not expand these proof helpers into an integration API. The eventual native
resolver must use the closed rules-owned DTO recommended in the dynamic coverage audit. AssetLab may
continue visual review of buy/sell tabs, preview/confirm/result separation, grayscale selection and
cannot-act rows only when every invented value is visibly labelled noncanonical and no mutation or
persistence claim is made.

#### Trading Post/Vance proposed semantic fixture correction disposition

**Accepted for its explicitly non-live semantic-fixture role; no code or Simulator changes.** The
contract now declares `evidenceRole: proposedSemanticFixture` and `integrationReady: false`; the
sheet visibly repeats “PROPOSED”, “NOT LIVE” and “NOT INTEGRATION-GOLDEN”; hypothetical results remain
nonmutating and are named result DTOs rather than commits. Quartz routes to `Resource Pool`; the Fang
sample uses a fixture bin/index handle and sample silhouette; Vance uses the accepted `baseSide`
identity unchanged at the counter; cannot-buy, cancel, reopen and cannot-act evidence are present in
color/grayscale and accessible text. The future rules-owned atomic boundary is stated rather than
claimed.

No remaining AssetLab blocker was found for this narrow proposed semantic proof. Its fixture prices,
wallet, snapshot, locking, eligibility, Vance ownership and refresh behavior remain intentionally
noncanonical and must never be promoted, hashed or consumed as a native resolver contract. Native
integration remains blocked on the missing live Trading Post DTO/rules identified in the coverage
audit; that is not an AssetLab correction request.

### 10 Aug 2026 — Trading Post and Vance semantic-fixture v0.1 disposition

**Disposition: recommendations only; semantic fixture remains pre-candidate.** Direct review of
`AssetLab/artifacts/trading-post-vance-proof-v0.1.png` accepts the core Buy/Sell transaction grammar.
Both 390pt color and literal-grayscale panels preserve six-across item identity, selected quantity,
Gold Coin unit/total arithmetic, wallet and holding/stock consequences, and a single confirm-only
mutation between frozen Preview and Result. The Quartz buy ends Stored with safe Overflow stated for
a full Storehouse; the Rubble sale remains available while stock awaits refresh. Worn, unidentified
and locked/Keep holdings remain visible, carry explicit reasons, show no tempting price and cannot
enter the sale. Gold Coins are named as wallet currency and are not confused with Gold Ore.

The accepted Trading Post silhouette and Vance are rendered separately, and Vance delegates to the
existing authored character descriptor rather than generating merchant anatomy, palette or a class
badge. That source boundary is correct. At the reviewed header size, however, the 16px legacy
`world` cameo is too close to a counter sign/prop to prove a person standing beside a side-view
village building. The smallest correction is a neutral authored side-view/base cameo derived from
Vance's same stable descriptor axes, shown once outside and once at the counter with pixel-identical
person geometry. Ledger, stock and weighing tools remain station-owned props. Do not borrow a combat
stance, weapon overlay or map-top-down body merely to close this fixture.

Two additional evidence gaps block candidate acceptance. First, rotating-stock ownership is only
asserted by `snapshot #4`; add open → close → reopen equality for the same line IDs, quantities and
prices, followed by a separately labelled post-expedition-resolved snapshot with a changed sequence.
This remains fixture evidence and must not imply a live DTO. Second, the canonical panel shows only
a successful Buy. Add one compact Buy cannot-act detail resolved from the existing fixture—such as
`Need 5 more Gold`, `Only 2 remaining`, or `Stock awaiting expedition return`—with no active confirm
and no mutation. Sell-side protection reasons already pass.

Retain the explicit **semantic fixture only** label: Engineering confirms there is no live economy
DTO, so fixture prices, stock and atomic results are not integration-golden. Also consider renaming
the result field `mutationAllowed: true` to an unambiguous committed/result fact in a future schema;
the resolver currently prevents recommitting a Result, but the field name reads as permission. No
new item family, price tuning or native economy implementation is requested.

### 10 Aug 2026 — Trading Post and Vance semantic-fixture v0.2 disposition

**Disposition: recommendations only.** Direct review of the corrected artifact retained at
`AssetLab/artifacts/trading-post-vance-proof-v0.1.png` accepts v0.2 for its explicitly proposed,
non-live semantic-fixture boundary. The sheet labels its wallet, snapshot, preview/confirm/result DTO
and completed result as proposed; it does not claim a live economy resolver or integration golden.

The accepted Trading Post remains station-owned architecture. Vance now uses the neutral authored
`baseSide` profile appropriate to the side-view village, and identical commands render him outside
and at the counter. His person geometry, descriptor axes and palette do not acquire merchant anatomy
or change with staffing position; stock, ledger and counter remain separate station props. The new
profile also avoids borrowing the legacy upright/map-top-down body or a combat stance.

Six-across Buy and Sell grids retain identity in color and literal grayscale. The Buy detail states
exact Quartz quantity, proposed Gold Coin unit/total arithmetic, wallet and stock consequences, and
correctly routes the purchased resource to the **Resource Pool**, not slot-limited Storehouse
inventory. The compact Copper example visibly rejects a request above remaining stock and states
that confirmation is inactive. Preview remains non-mutating, Confirm alone names the same frozen
line/quantity, and the Result DTO remains rules-owned rather than pretending AssetLab committed it.

Fixture tests now prove snapshot #4 survives open/close/reopen unchanged and that only separately
labelled expedition snapshot #5 changes refresh identity. Sell remains available while Buy stock
awaits that refresh. Rubble sale arithmetic and remaining holdings stay exact; Worn, unidentified and
locked/Keep items remain visible without a price or active sale. The property-bearing sample now has
its own sample icon rather than borrowing Keepsake identity. Gold Coins remain distinct from Gold Ore.

Promote this as a visual/semantic proposal with its proposed/not-live labels, snapshot hashes,
base-side identity equality, cannot-act, resource routing, sample identity and non-mutating result
fixtures. Live price eligibility, inventory revision, atomic commit, stale-preview handling,
VoiceOver and save/reload remain blocked on the future Engineering-owned economy DTO. No further
AssetLab visual correction is requested.

### 10 Aug 2026 — research-driven resource color v0.6 disposition

**Disposition: recommendations only.** Direct review of the v0.6 candidate temporarily exported at
`AssetLab/artifacts/resource-node-proof-v0.5.png` accepts the revised resource color/material grammar
for promotion under a new canonical filename. The 21 map families retain their previously accepted
whole-mass and negative-space separation in literal grayscale, while color now adds representative
material information rather than allowing the owning substrate palette to absorb every node.

Canonical accent pixels remain stable across the reviewed soil/stone, ice and ash contexts while
the surrounding body tones belong to the resolved environment. Clay reads warm and smooth; iron ore
reads rust-bearing rather than copper-like by its heavier vein mass; copper remains dendritic;
silver reads wire/branch-like; gold is a compact nugget group; quartz, obsidian, salt, sulfur,
adamant and Rift-glass retain distinct material families. Flora-linked cues preserve the exact host
flora and use representative accents without recoloring the host into a resource species.

Mercury now reads as a low, irregular reflective puddle with small bright beads/highlights. It
remains distinct from silver's branching mass, ichor's darker organic deposit and the vertical
crystal families in both color and grayscale. This is a legitimate disclosed material cue, not an
encoding of grade, quantity, danger or hidden provenance. Retain a future native collision fixture
against route, shallow water and ichor because all are low horizontal reads; this is a regression
recommendation, not a blocker in the reviewed catalogue.

The neutral sheen contract remains correctly downstream of material color, clipped to the revealed,
discovered, remaining resource/cue body. Canonical accents and sheen do not vary by rarity, yield or
other hidden properties; exhausted, fog, minimap and Mote exclusions remain intact, and Raw Essence
continues to delegate the accepted `wildDrop` body. Literal grayscale continues to prove that sheen
and hue are redundant to family identity.

Promote with the pairwise silhouettes, environment comparison, canonical-accent, grayscale and sheen
fixtures. Tighten `minimumIdentityPixels: 2` with a pixel-count assertion rather than only requiring
one stable command when the color contract is next versioned; the reviewed shapes visibly exceed
that floor, so this is test precision rather than a visual correction. No new descriptor axis or
disclosure change is requested.

### 10 Aug 2026 — DEBUG bug-reporting AssetLab boundary engineering audit

**Disposition: recommendations only.** The current design in
`docs/debug-bug-reporting-current.md` is internally coherent, but the live app does not yet contain a
bug-report DTO, screenshot service, durable report outbox, route-observation seam or submission
transport. AssetLab may therefore prove a clearly labelled proposed semantic fixture, not an
integration-ready reporter or evidence that capture, force-quit recovery or delivery works.

Several native facts are reusable without inventing new truth. `GameState.schemaVersion` and
`SaveMeta.mutationCount`, `lastAction`, `lastSavedAt` and `launchCount` are real persisted save
diagnostics. `AppRoute` is a closed string vocabulary. `WorldRun` owns the run index, bound book,
map seed, player position, stability and captured tuning snapshot; `EncounterState.id` and
`RunExitSummary.outcomeID` are real identifiers. `DebugTuningProfile` is Codable. `SaveFileIO`'s
atomic write and `GameStore`'s serialized writer are useful implementation patterns, but reports
must use a separate store so resetting or migrating the game save cannot erase diagnostic evidence.
Never serialize `SaveDiagnostics.saveURL`, raw save bytes, filesystem paths or `SeedSequence.rootSeed`.

The apparent near-matches must not be promoted into claims. `recentEvents` is an in-memory,
four-entry world narration buffer, not the required persisted 20-action semantic trail.
`SaveMeta.lastAction` is one mutation label, not that trail. The navigation stack is not bound to an
observable current route, so only world/encounter/base-level inference is presently possible; an
exact station/screen requires a native route-reporting seam. No stable campaign/report identity,
commit-build injection, screenshot attachment metadata/failure reason, consent/redaction model,
overlay-position persistence, remote destination, transport result or remote reference exists yet.
A world/map seed is not a safe substitute for campaign identity.

Use two closed records rather than mixing mutable delivery state into immutable evidence:

1. `BugReportEnvelopeV1` is immutable after atomic creation. It has an explicit contract version,
   `BugReportID`, creation timestamp and offset, bounded user description/expected text/tags,
   allowlisted app/save/run/world/encounter facts, an optional bounded semantic-action trail, and a
   screenshot union of `attached(relative leaf filename, pixel width, pixel height, scale)`,
   `removed`, or `captureFailed(sanitized reason code)`. Unknown or unavailable native facts are
   absent; they are never synthesized or defaulted.
2. `BugReportOutboxRecordV1` is the only mutable record and is keyed by the same report ID. Its exact
   UI states are `unsent`, `sending(attemptID, startedAt, attemptCount)`,
   `submitted(remoteReference, submittedAt)`, and
   `needsAttention(lastErrorCode, lastAttemptAt, retryable, attemptCount)`. Draft composition stays
   in memory. Retrying reuses the report ID as the transport idempotency key and creates a new
   attempt ID, never a new report. `submitted` is terminal and cannot change its remote reference.
   Invoking a system share/export sheet is not proof of receipt and must not set `submitted`.

The smallest durable package is one directory per report ID containing the immutable JSON and
optional PNG. Build it in a sibling temporary directory and rename only after every member is
flushed; enumerate complete packages to reconstruct the outbox instead of maintaining a second
fallible index. Persist every delivery transition before performing its side effect. On launch, a
stranded `sending` record must be reconciled or retried with the same idempotency key; it must never
be silently discarded or duplicated. The future transport seam should accept the immutable package
plus idempotency key and return `accepted`, `alreadyAccepted` with the same remote reference,
`retryableFailure`, or `terminalFailure` using sanitized codes.

AssetLab can truthfully fixture compose validation, attached/removed/capture-failed screenshot
states, an allowlisted context disclosure summary, local-only saved confirmation, all four outbox
rows, retry affordance and accessible reading order. Give that fixture fields such as
`evidenceRole: proposedSemanticFixture` and `integrationReady: false`; do not embed a fake save,
remote response, live screenshot or claimed current route.

Contract tests should reject unknown fields/enums, blank or over-limit required text, traversal or
non-leaf attachment names and unsanitized error data. Native acceptance must additionally prove:
capture occurs before presentation and excludes the reporter control; atomic-package kill points
never expose a partial report; duplicate creation with identical ID/content is idempotent while a
different payload conflicts; every illegal state transition rejects; transient failure preserves
the package; relaunch recovery and repeated submission use the same report ID; `alreadyAccepted`
converges to one submitted record; share cancellation never submits; context absence stays absent;
the semantic trail is ordered and capped at 20; reset-game does not clear the outbox; privacy
allowlisting excludes paths, raw saves, secrets and account identity; and release builds contain no
reporter entry point. These are later native gates, not AssetLab visual blockers.

### 10 Aug 2026 — DEBUG bug-reporter proposed-fixture v0.2 engineering review

**Disposition: recommendations only.** The source and artifact correctly declare
`evidenceRole: proposedSemanticFixture`, `integrationReady: false` and DEBUG-only scope, and the
focused test passes. Unknown top-level/context keys reject, submitted requires an acknowledgement
reference, non-submitted records cannot carry one, included screenshots require the asserted
pre-sheet ownership flag, and Release availability is false. The sheet has a useful 44-point
placement/readability proof in color, literal grayscale and large text. It is not yet accepted even
as the proposed semantic fixture because four AssetLab-side contradictions remain.

First, the artifact says `PRE-SHEET: exact app scene`, `Captured before this sheet` and `report
remains after relaunch` while its footer says there is no live capture or persistence claim. Those
are native acceptance results that the fixture cannot possess. Relabel them as proposed lifecycle
requirements or illustrative scene/attachment states, and say relaunch durability is **not tested**.

Second, placement is not actually closed. Validate `preferredEdge` and `preferredFraction`, every
required-action rectangle's finite non-negative geometry, safe-area ranges and that the 44-point
target fits the available screen. Currently an action containing `NaN` is treated as non-
intersecting, unknown edge strings silently behave as trailing, and a too-short screen can return a
target outside its bounds. Add negative tests for those cases plus a fully blocked layout returning
`no-safe-placement`.

Third, the resolver closes key names but not the values it displays as context: arbitrary types,
negative/unbounded `actionCount` and empty or path/secret-shaped strings pass. Give the semantic
fixture explicit bounded string/nullable unions and `actionCount: 0...20`; use conspicuously
illustrative values rather than plausible campaign/build identifiers. Closure must apply to the
result records too, not only the input report.

Fourth, `localSaveResult` and `transportResult` overwrite state without a legal transition check.
They can regress `submitted` to `unsent`/`needsAttention`, resubmit a terminal report, or send a
draft directly while `saving`/`sending` carry no attempt identity. For the proposed grammar, either
render immutable sample rows without transition helpers or implement the already recommended exact
state graph: draft → saving → unsent; unsent/retryable-needs-attention → sending with an attempt ID;
sending → submitted or needs-attention; submitted terminal. Retry preserves the same report ID.
Tests must enumerate every accepted and rejected transition. This remains a semantic-fixture check;
atomic storage, actual capture, force-quit recovery, transport idempotency and remote acknowledgement
remain later native gates.

### 10 Aug 2026 — DEBUG bug-reporter proposed-fixture v0.3 follow-up

**Disposition: recommendations only.** The corrected artifact is now honest about its boundary:
capture ownership, local saving, relaunch behavior and acknowledgement are consistently labelled
proposed/not native-tested, and the shared scene-command equality proves only the intended fixture
composition. Placement now rejects invalid screen/safe geometry, edge, fraction and non-finite or
non-positive action rectangles. Context keys and required strings are bounded, action count is
integer `0...20`, and the focused suite passes. Local save rejects non-drafts; transport rejects
draft and terminal input and accepts only unsent/retryable fixture rows. Color, literal grayscale,
44-point ownership, capture-unavailable text fallback and empty-required-text behavior all read.

Two small state-contract corrections remain before proposed-fixture acceptance. The screenshot DTO
still uses two Booleans, so `includeScreenshot: false` cannot distinguish the artifact's three
different truths: user removed the attachment, capture failed/unavailable, or no capture was
requested. Replace them with the previously specified closed union (`attached` with asserted
pre-sheet ownership, `removed`, or `captureFailed` with an allowlisted reason code), and test each
branch. This does not claim a native screenshot service; it merely makes the fixture match its own
visible states.

Also require a non-empty bounded `remoteReference` for submitted acknowledgement. The current
`typeof === "string"` check accepts `""`, allowing `transportResult(..., {acknowledged: true,
remoteReference: ""})` to produce `submitted` without a usable acknowledgement identity. Apply the
same non-empty/bounded rule to optional context identifiers when present so empty strings mean
absence rather than a second representation of missing data. Add direct negatives. Attempt leases,
atomic durability, relaunch reconciliation and server idempotency remain later native gates; the
proposed fixture need not simulate them.

### 10 Aug 2026 — DEBUG bug-reporter proposed-fixture final closure

**Disposition: recommendations only.** The two remaining AssetLab blockers are closed. The public
fixture now uses the exact closed screenshot-state union `attached | removed | captureFailed`;
`captureFailed` alone requires one of the allowlisted failure reasons, while attached/removed reject
that field. Both no-image states remain valid when the required text exists, so the visual fallback
does not imply a screenshot dependency.

Submitted acknowledgement now requires a non-empty destination reference bounded to 120
characters, and direct tests reject null and empty references. Optional campaign/run/world/position
identifiers likewise accept one non-empty bounded string representation or absence, not empty-string
sentinels. Focused tests pass, and the reported full suite/regression is green at 240/0.

Accept the DEBUG bug reporter v0.3 as the current **proposed semantic fixture**. It remains explicitly
non-integration-ready: native screenshot timing/exclusion, a real route/context DTO, atomic package
storage, force-quit recovery, transport idempotency/acknowledgement, privacy serialization and
Release exclusion still require native implementation and acceptance evidence. No further AssetLab
contract or visual correction is requested at this boundary.

### 10 Aug 2026 — provisional Noll identity engineering boundary audit

**Disposition: recommendations only.** The provisional boundary is safely isolated for review.
`provisionalNollDescriptor` is not a member of the accepted 28-person
`namedCharacterCatalogue`, and `characterDescriptor("noll")` therefore cannot resolve it as a live
named identity. Tests prove its silhouette does not collide with any accepted named traveller in
`baseSide`, combat, or each of the four straight-top-down map facings. Existing full-catalogue tests
separately retain pairwise uniqueness of the accepted 28. The focused character suite passes.

The artifact consistently labels Noll's name, pronouns and art as working/noncanonical. It renders
the provisional person through the already reviewed character profiles instead of inventing a
Recycler-specific body or integration adapter. Recycler commands are identical in the staffed and
unstaffed evidence; Noll is drawn as a separate occupant, and the place test independently proves
staffing cannot change station geometry. This is the correct ownership split.

There is no current AssetLab integration blocker because this proof must not be consumed by native
code. In particular, `characterCommands(..., descriptor:)` is an authoring escape hatch that bypasses
catalogue identity resolution; `"provisional_noll"` is only a lab call-site label, not an accepted
raw value, persisted identity or manifest `identityKind`. Engineering must not add either
`provisional_noll` or `noll` to a native enum/catalogue from this evidence.

If Aimee later accepts the identity, promotion requires an explicit canonical decision for stable
ID, display name, pronouns and descriptor, followed by one atomic catalogue/version change. At that
point add the named entry to the closed character identity schema/adapter, reserve its exact
descriptor combination from generated identities, regenerate named/map/combat hashes and full-cast
fixtures, and verify live persistence/migration and station-occupant mapping. Until then, exclude
Noll from accepted catalogue counts, native manifests, save migrations, generated-identity reserve
claims and Recycler staffing DTOs. No correction to the provisional visual proof is required for
this engineering boundary.

### 11 Aug 2026 — five-identity economy bridge v0.1 engineering audit

**Disposition: recommendations only.** The artifact correctly labels itself an asset-correspondence
fixture with `integrationReady: false`, keeps the five dominant icons pixel-identical across the four
contexts, and says eligibility/provenance/requirements remain external. Its exact-object comparison
rejects missing, extra, unknown and drifted fixture fields, the five icons remain distinct in color
and literal grayscale, and the focused test passes. It is not yet a truthful live-model bridge.

The live identity surfaces are heterogeneous and should not be flattened into the fixture's generic
`stableID` strings:

- Rubble is a `ResourceID(rawValue: "rubble")` entry in a quantity-valued `ResourcePool`; it has no
  per-stack instance ID. `resource-rubble` is therefore a fixture label, not a native stable ID.
- A `MaterialSample` has no identity field. A current selection is addressed by
  `PhysicalGearCraftingRules.Selection(binID: InstanceID, sampleIndex: Int, sample: MaterialSample)`.
  `binID + sampleIndex` is a selection handle, not durable sample identity: consuming/removing
  samples can change indices. Rename `sample-bin-4-index-2` away from `stableID`, preserve the
  structured UInt64 bin ID and integer index, and label it explicitly ephemeral/snapshot-scoped.
- Lesser Salve is an `ItemStack` with `InstanceID(UInt64)`, `catalogID: "salve_lesser"`, count and
  identified state. The invented string `item-801` does not round-trip the native ID type.
- A found Chipped Blade is also an `ItemStack` whose catalogue ID is `blade_chipped`; its initialized
  `GearInstanceProfile.stableInstanceID` matches the stack instance. The live model does not encode
  “found salvage” as provenance, and the same catalogue item may be acquired through more than one
  route. Call this an authored catalogue/found-gear **example**, not known salvage provenance.
- A crafted Pointed Blade still has catalogue fallback `blade_chipped`. Its distinct frozen identity
  is in `gearProfile`: `stableInstanceID`, `familyID: "pointed_blade"`, construction tier, damage,
  reach, consumed samples, `recipeVersion: 1`, specialist profile and display provenance. A key made
  only from `pointed_blade + 9001` omits the fallback catalogue and schema/version facts needed to
  distinguish and reconstruct it safely.

Before calling this an integration bridge, replace the six-field universal record with a closed
`oneOf`/tagged union whose fields match each native kind and whose UInt64 identifiers remain decimal
UInt64 values rather than prefixed display strings. Keep display name and provenance as resolver
output, not identity input. For crafted gear, require the frozen gear-profile version/family/recipe
facts; for found gear, do not synthesize an acquisition route; for material samples, name the
bin/index pair `selectionHandle` and scope it to an inventory revision or immutable preview.
Validation should reject cross-kind fields, overflow/negative IDs and indices, unknown resource/item/
recipe raw values, a Pointed Blade without the `blade_chipped` fallback, and a purported crafted
receipt whose selected samples do not match its frozen `consumedSamples`.

The five icons and cross-screen pixel correspondence can remain accepted visual fixture evidence.
Resource quantity, inventory revision, sample selection stability, identified/locked/favorite/worn
state, Trading Post eligibility, Recycler recovery, Blacksmith readiness/preview, atomic mutation
and post-save/reload identity remain rules/native DTO gates. In particular, no live Recycler
salvage/recovery result is represented here, so the artifact must not imply that Chipped Blade has a
currently implemented salvage receipt or yield.

### 11 Aug 2026 — five-identity economy bridge v0.2 re-audit

**Disposition: recommendations only.** v1.1 closes the generic-ID and player-language problems.
Records are tagged by kind; ResourceID/quantity, decimal UInt64 stack/bin fields, catalogue fallback,
sample index/kind and crafted profile facts are now structurally separated. “World resources” is the
player-facing category, the material is a valid `quill`, exact canonical objects reject drift, icons
remain pixel-identical across contexts and pairwise distinct in literal grayscale, and the focused
test passes. Three live-model contradictions still block the word **bridge**.

1. A live found Chipped Blade does not have `gearProfile: null`. Constructing any catalogue gear
   `ItemStack` initializes `GearInstanceProfile` with version, matching stable instance ID,
   construction tier, slot, damage and reach. Null is allowed only for transitional in-memory
   fixtures according to the model comment. The found record must carry the exact authored fallback
   profile (while leaving `familyID`, recipe receipt and display provenance absent), or be labelled a
   non-live legacy/transitional fixture.
2. `blade_chipped` already has an explicit Recycler authored-salvage route in live rules:
   `authoredSalvage(profileID: "forged_edge_v1")`. The artifact's “Recycler route unresolved” is
   false. This is not acquisition provenance and should not be placed in identity input, but a
   rules-resolved detail may truthfully name the route/profile when the Recycler DTO supplies it.
3. Pointed Blade cannot currently have `constructionTier: 3`. Its Blacksmith recipe has
   `stationCap: 2`; live preview may compute natural tier 3 but freezes `outputTier: 2`, and the
   crafting test proves that cap. Use a lawful tier 1–2 fixture. Also label
   `consumedMaterialCount` as a derived correspondence summary: the persisted native field is the
   exact ordered `[MaterialSample]` receipt, not a count.

One scoping clarification remains important. `inventoryRevision` exists on the Trading Post and
Recycler states, not as a universal inventory/sample identity field. The Blacksmith protects its
selection by recomputing and comparing the exact `Preview`, while Recycler uses its own revision.
Therefore the revision/bin/index tuple is a context-owned selection handle, not an identity shared
unchanged across all four screens. Keep the specimen's visual correspondence stable, but have each
future rules DTO supply its own opaque selection/preview handle and revision semantics.

After correcting the found profile wording/shape and Pointed Blade tier, this can be accepted as a
non-integration asset-correspondence fixture. Native DTOs must still own current location,
identified/favorite/locked/worn state, exact receipt samples, preview revision/token, eligibility,
recovery/crafting result and atomic mutation; AssetLab should not infer them from these records.

### 11 Aug 2026 — Essence-continuity proof native-input audit

**Disposition: recommendations only.** `RunExitSummary.EssenceEconomy` is a useful persisted return
snapshot, but its six integers do not yet support the whole requested continuity headline. Preserve
their exact units and meanings:

- `rawCollected` is **retained Raw Essence units banked at this exit**, after collapse/partial-haul
  retention. It is not generated/obtainable raw, and on a partial return it is not total raw picked
  up during the expedition. The current UI label “collected” is looser than the stored fact.
- `refinedEquivalent` is refined-Essence **potential** computed as
  `EconomyRules.refine(rawUnits: rawCollected)` at summary creation. Current return flow banks raw
  into the Base and does not refine it. This field is not an actual refinement receipt.
- `bindCostPaid` is the departed `BoundBook.essencePaid`: the actual total charged for that book,
  including page ink cost. It describes the expedition just completed, not the price of the next
  ordinary authored book.
- `springYield` is the actual per-return Spring dividend credited once for the minted
  `ExpeditionOutcomeID`; `lastSpringOutcomeID` is the idempotency guard. It is separate from aid.
- `antiLockSubsidy` is the exact post-return shortfall added only when spendable Essence remains
  below `minimumBindCost`. It is initially zero and is updated by
  `ensureDepartureIsPossible` after the summary is created.
- `netRunway` is refined-Essence **spending capacity**, not wallet balance:
  `base.essence + potential refinement of every Raw Essence unit currently held`. It is first
  captured after banking and Spring credit, then replaced with the post-subsidy value if aid fires.
  It may include raw retained from earlier expeditions as well as this return.

Thus the live summary can truthfully feed retained raw, its potential refined value, prior bind cost,
actual Spring dividend, exact exceptional subsidy and total spendable runway. It cannot feed actual
raw refined from this outcome, generated/obtainable/raw-picked-before-loss totals, final refined
wallet balance, raw balance composition of runway, or “ordinary authored binds available.” There is
no persisted refinement transaction tied to the outcome, no wallet-at-summary field, and no recent
median history/classification of non-blank ordinary authored bind costs. Reading current
`base.essence` later would be mutable current state, not the atomic exit snapshot. Dividing runway by
the just-finished `bindCostPaid` would not implement the settled recent-median rule.

The smallest truthful AssetLab fixture today should be a closed resolver-shaped **partial** DTO,
explicitly `integrationReady: false`, containing the summary/outcome identity and six native
integers, plus resolver-owned semantic labels rather than invented arithmetic:

```text
EssenceReturnSnapshotV1
  outcomeID, runIndex, outcomeKind
  retainedRawUnits
  retainedRawPotentialRefinedEssence
  previousBindPaidEssence
  springCreditEssence
  antiLockAidEssence
  spendableRunwayEssence
  ordinaryAuthoredRunway: unavailable(reason: missingBindBenchmark)
  refinedFromThisReturn: unavailable(reason: noOutcomeRefinementReceipt)
  finalWallet: unavailable(reason: noExitWalletSnapshot)
```

All counts are non-negative integers; `outcomeID` is required for new summaries, and unavailable
facts use closed reason enums rather than zero or placeholder values. The resolver must assert
`refinedEquivalent == EconomyRules.refine(rawCollected)` using the native active rate/version,
`antiLockSubsidy <= netRunway`, and must never merge Spring credit with anti-lock aid. AssetLab may
fixture zero/nonzero aid, zero/nonzero retained raw, full/partial exit wording, and the distinction
between potential refinement and actual credit. It must not show a completed raw→refined arrow or a
numeric authored-bind count from this DTO.

For the eventual complete native DTO, snapshot atomically at the settled post-return/post-aid point:
`walletRefinedEssence`, `rawHeldUnits`, `activeRefinementRate`, `spendableRunwayEssence`, and a
rules-owned `ordinaryAuthoredBindBenchmark` with exact cost, sample-window/count and benchmark
version. If auto-refining is later implemented, add an outcome-keyed receipt with raw consumed and
refined credited; do not reinterpret `refinedEquivalent`. Native tests should cover portal and
partial exits, pre-existing raw, zero/nonzero aid, one Spring credit per outcome, save/reload, and
wallet/runway arithmetic; median-window construction and bind classification require their own
rules tests. These are native telemetry gates, not AssetLab visual decisions.

### 11 Aug 2026 — five-identity economy bridge v0.3 final re-audit

**Disposition: recommendations only.** The found/crafted headline distinction is now correct.
Chipped Blade carries the initialized tier-1/rend/close fallback profile with no construction
family/receipt and names the live Recycler resolver route `forged_edge_v1`. Pointed Blade retains
catalogue fallback `blade_chipped`, freezes family `pointed_blade`, recipe/profile version 1,
Blacksmith specialist, tier 2, pierce/close and a two-entry ordered receipt. The material value is
separate from per-context handles, dominant icons remain identical across contexts and distinct in
literal grayscale, and the focused test passes. Three narrow correspondence claims remain to fix.

First, the crafted record calls `consumedMaterials` exact but omits each sample's six
`MaterialProperties`. Native `GearInstanceProfile.consumedSamples` persists the complete ordered
`MaterialSample` values: kind, all properties, grade, source and qualifier. Include the full values
or rename the current array to a lossy display summary and keep it outside identity/conformance
claims. The exact receipt cannot be reconstructed or equality-checked from the current record.

Second, `revision 12 · bin 4 · entry 2` is not a live Inventory handle. Base Inventory has stack
`InstanceID` plus material index but no general inventory revision. Revisions belong specifically to
Trading Post and Recycler preview state. The Inventory context should use `binID + sampleIndex` only
(and remain snapshot-scoped), or explicitly label a proposed UI snapshot token rather than a native
field.

Third, `stock line 404` is not a truthful Trading Post handle for this quill specimen. Live Trading
Post stock/sale tables do not classify the material-bin catalogue entry as transferable stock, and
a `TradingPostStockLine` is not a handle for an individual `MaterialSample`. The correspondence
sheet may show the specimen as visible-but-ineligible if a future resolver supplies that row, but it
must not claim a live stock line. Use an explicit unavailable/ineligible context row, or restrict
the cross-context proof to contexts that possess the specimen today. Recycler returned-receipt and
Blacksmith bin/index selection handles remain rules-owned preview facts rather than universal
identity.

After those corrections, accept v0.3's visual correspondence boundary. Integration still requires
closed native resolver DTOs for location, eligibility/protection, exact previews and atomic results;
AssetLab must not manufacture handles merely to make all five identities appear actionable in all
four contexts.

### 11 Aug 2026 — five-identity economy bridge v0.3 source closure / artifact re-export required

**Disposition: recommendations only.** The current source and focused tests close all three prior
contract blockers. Pointed Blade's ordered `consumedMaterials` now retain kind, all six
`MaterialProperties`, grade, source and qualifier for each entry. Inventory uses only the
snapshot-scoped bin/index handle, with no fictitious universal revision. Trading Post explicitly
states the individual quill is not individually transferable rather than assigning it a stock line.
Recycler and Blacksmith handles remain context-owned preview facts. The focused suite passes.

The retained PNG at `AssetLab/artifacts/economy-five-identity-bridge-proof-v0.3.png` is stale,
however. Its SHA-256 remains `76830c0b62cd051a65d150c55133a8207868a9ea0430aad993421cf4ea191333`
and direct inspection still shows the superseded quill labels `revision 12` in Inventory and
`stock line 40…` in Trading Post. That contradicts the corrected source and would preserve the exact
misrouting the contract now rejects.

Re-export the v0.3 artifact from the current `bridge-app.js`/contract and assert the PNG visibly says
`bin 4 · entry 2` and `not individually transferable` (or their deliberately shortened but
unambiguous equivalents). Pin its new hash or add an artifact text/evidence assertion so semantic
source changes cannot leave a stale canonical proof. After that mechanical re-export, accept the
five-identity AssetLab correspondence boundary; no additional source or visual redesign is needed.

### 11 Aug 2026 — five-identity economy bridge v0.3 final closure

**Disposition: recommendations only.** The mechanical artifact gate is closed. Direct inspection of
the regenerated 800×760 PNG confirms the Inventory specimen handle now reads `bin 4 · entry 2` and
the Trading Post row reads `not traded`; the latter is an accurate compact rendering of the source
contract's exact `not individually transferable` state. Neither superseded revision nor fake stock-
line wording remains. Color and literal-grayscale correspondence evidence is intact.

The artifact SHA-256 is
`a0c82b1c9f3de429e9b96943f238164b36e3af8f22e82147072a368dd4ee6d81`, and the focused
economy-identity test passes; the reported full AssetLab suite/regression is green at 240/0. Accept
v0.3 as the current five-identity **asset correspondence fixture** with
`integrationReady: false`. No further AssetLab correction is requested. Rules-owned context DTOs,
eligibility, previews and atomic mutations remain the later native integration boundary.

### 11 Aug 2026 — launch handoff alignment engineering recommendation

**Disposition: bounded native recommendation; no redesign.** Source inspection confirms the visible
jump is deterministic layout drift, not a Simulator/device anomaly. The static storyboard owns a
safe-area-centered 248×340 page with exact local coordinates: top rule `(18,22,212,2)`, mark
`(87,74,74,58)`, Georgia Bold title `(28,172,192,37)`, system-15 copy
`(28,225,192,21)`, and bottom rule `(18,316,212,2)`. SwiftUI `LaunchSurface` instead distributes the
same elements through two flexible `Spacer`s, nested `VStack(spacing: 18)`, 18-point padding and
dynamic/default text metrics. It cannot land on those coordinates consistently and its system
`.serif` title is not the storyboard's explicit Georgia Bold font.

Make only the idle/loading surface a fixed local-coordinate composition. Use a 248×340
`ZStack(alignment: .topLeading)` (or equivalent overlay) and position the six elements with those
exact storyboard rectangles. Use `Font.custom("Georgia-Bold", fixedSize: 30)` in a fixed 192×37
title frame and `Font.system(size: 15)` in a fixed 192×21 copy frame; constrain both to one line with
the storyboard alignment. Do not use flexible spacers, stack spacing, dynamic type or intrinsic text
height in this loading-only composition. Preserve `BookbindingMark` at exactly 74×58 and reuse its
existing internal rectangles.

Center the 248×340 page in the root view's safe-area proposal, while applying the system-background
fill separately through the full screen/unsafe regions. Do not calculate position from a hardcoded
393×852 device. Draw the 2-point page frame inward (`strokeBorder` or four exact edge rectangles) so
its outer extent remains 248×340; use the storyboard's fixed frame color rather than semantic
`.brown.opacity(0.75)` if pixel continuity is required. The internal rules remain semantic
secondary-label color, matching the storyboard. The loading view's accessibility remains one
combined “Bookbinder. Opening the Atlas.” element even though visual text size is fixed.

Do not force failure content into this static geometry. Split `LaunchSurface` into an exact
`LoadingLaunchSurface` and a separate adaptive `LaunchFailureSurface`. Failure messaging, retry and
copy-diagnostics controls may retain Dynamic Type, scrolling and accessible button layout; this
state has no static-launch continuity requirement. The coordinator phase/state machine and launch
timing behavior need no change.

Add a small shared geometry specification or tests that parse/compare the storyboard and SwiftUI
constants for page size, every local rectangle, title font name/size and copy size. Add a source or
render assertion that the loading composition contains no `Spacer`, and native visual acceptance
should compare the final storyboard frame to the first SwiftUI loading frame in light/dark and at
the supported phone safe areas. This fix is confined to the native launch view; it does not require
an AssetLab asset, new launch art, or any Simulator lifecycle/window manipulation.

### 11 Aug 2026 — native campaign checkpoint / AssetLab bookplate v0.1 recheck

**Disposition: recommendations only.** Read-only source inspection shows the five previously
reported native presentation issues are now closed in current source:

1. Cards expose Load plus More/Review; destructive delete is confined to the focused detail sheet
   and its confirmation.
2. DEBUG save-schema and full UUID text live in the focused Technical details section, not every
   ordinary card.
3. Both card and detail metadata rendering are guarded by `hasKnownMetadata`; corrupt/future slots
   no longer display the internal Level 0 / Unavailable / distant-past sentinels.
4. `CampaignBookplateMotif(id:)` supplies a UUID-owned, rename-stable neutral visual channel on card
   and detail, separate from health and progress text.
5. Confirmation title and destructive alert button both include the UUID prefix, so duplicate
   names have distinct destructive accessibility labels. `CampaignStartPresentationTests` now
   expects the same UUID-bearing title as source; the earlier source/test mismatch is gone.

Continue still selects the most recent loadable slot while invalid slots remain visible, and the
layout policy still changes the two-column compact grid to one column at accessibility sizes. These
are source/test findings only; no device-runtime claim is made.

AssetLab's `campaign-bookplate-proof-v0.1.png` is safe as explicitly proposed,
recommendations-only visual evidence. It clearly says it is not a native capture, preserves invalid
cards without fabricated metadata, demonstrates compact two-column, literal grayscale and large-
text single-column layouts, keeps destructive action in a focused confirmation, and derives
rename-stable bookplate geometry from UUID. Its closed resolver rejects unknown keys, malformed UUID,
valid-without-metadata and non-null unknown metadata; the focused test passes.

Do not promote v0.1 as a native contract or pixel fixture yet. Its illustrated 32px bookplate is an
alternative to the native eight-mark `CampaignBookplateMotif`, not proof of current SwiftUI pixels.
The AssetLab health copy `Made by a newer version` differs from native `From a newer version`, valid
cards omit the native More action, and unknown-slot display names are illustrative rather than
native descriptor output. Most importantly, AssetLab's destructive confirm label is only
`Delete “name”`; native deliberately includes the UUID prefix in that button as well as the title.
If the proposal is promoted beyond visual exploration, align those strings/actions and preserve the
UUID-bearing confirm label.

The proposed nullable unknown-metadata DTO is cleaner than native `CampaignSlotSummary`'s internal
sentinel Date/level/location fields, but current rendering correctly hides those sentinels. Treat a
future optional/union metadata refactor as contract hardening, not a visual checkpoint blocker.
Bookplate collision-freedom is not established by either implementation's small visual mark space;
the visible short UUID remains the disambiguating identity in focused detail. Native runtime,
VoiceOver focus/order, destructive callback ownership and save deletion remain native acceptance
gates.

### 11 Aug 2026 — native terrain grading / feature and flora-variety source audit

**Disposition: read-only engineering finding.** The ordinary native map renderer currently consumes
both world-conditioned terrain recoloring and deterministic per-tile feature variation. This is
live code, not merely AssetLab proof:

- `MapGrid` resolves one `WorldGrade` from the active book/readings and map seed, then supplies it
  to every `MapTileArtRequest`.
- Native `WorldGrade.from` matches the three published `world-grade-1.0.0` cross-language vectors.
  `TerrainPixelGrammar` applies its signed RGB plus value offsets to every ground palette and to
  water/deep-water/ice/chasm perimeter edges. Geometry and rule ownership do not change with grade.
- `MapAssetContract.terrainSeed` deterministically derives UInt32 variation from persisted map seed,
  coordinate and the frozen seed tuple. `featureVariant = seed & 3` selects one of four implemented
  patterns for all 12 ground families, while the same seed also controls bounded texture pixels.
  Redraw/cache hits do not reroll them.
- Live adjacency is derived N/E/S/W by exact `GroundType` equality, fog short-circuits to the
  invariant fill, and the 16×19 lifted terrain/south exposure compositor is active. Native tests
  pin seed examples, grade vectors, the corrected manifest and both lifted decoded-pixel fixtures.
  The DEBUG-only simple renderer can intentionally bypass this art, but Release uses the asset
  renderer.

Dynamic flora variety is also live. World generation creates a deterministic flora cast from world
readings and world seed, paints exact flora `InstanceID`s onto growth/groundcover tiles, and
`MapGrid` resolves each ID against `WorldRun.flora`. `FloraRenderDescriptor` maps the live species ID,
world seed and full stature/tissue/defence/habit/color/finish/metabolism facts into the published
top-down descriptor. `FloraPixelGrammar` changes patch topology, dominant-tissue structure,
species-owned hue/depth/opacity/finish, patterning and metabolic accents; its species seed controls
bounded detail. Native tests match both published flora pixel vectors and prove a trait change
changes both cache key and pixels.

The intended stability boundary is important: every placement of one flora species renders the same
16px species sprite. Variety among placements comes from which generated species owns the tile and
from worldgen's ground/patch placement, not a per-tile specimen reroll. This agrees with the accepted
flora contract. Flora is **not** post-tinted by `WorldGrade`; its world conditioning is upstream in
generated traits/coloration. The current AssetLab flora contract likewise has no world-grade input.
Do not add terrain grading to flora without a new design decision and version, because it could
erase stable species identity.

What remains proof-only or under-tested:

- The map-slice PNG catalogue is explicitly a conformance set, not an exhaustive runtime atlas;
  native code reimplements the command grammar rather than loading those PNGs.
- Native tests exercise only two lifted terrain raster fixtures and two flora species vectors. They
  do not yet prove all 12 grounds × four feature variants, all grade extremes, or a generated
  multi-species live map in color and grayscale.
- AssetLab's integrated multi-species/contact sheets are visual evidence, not a native screenshot.
  Native tests do not sample real generated casts for pairwise 16px separation, accidental
  silhouette collisions after integer normalization, or same-species pixel equality across many
  placements.
- No native test currently demonstrates that every feature variant remains semantically neutral in
  grayscale and cannot resemble crack, route, resource or passability grammar. The code is active;
  this is an acceptance-coverage gap, not a missing feature.
- Player/enemy/site overlays still use game-owned SwiftUI symbols; top-down character-map artwork
  is a separate remaining integration boundary and does not affect the terrain/flora answer.

Smallest safe checkpoints are test/evidence slices rather than another renderer rewrite:

1. Add a native raster matrix over every GroundType, variants 0–3 and neutral/warm/cool grades.
   Assert deterministic pixels, grade-only geometry equality, four distinct variants, fog
   invariance and grayscale separation of the key rule pairs.
2. Generate several real worlds with flora, resolve every painted flora ID, and assert identical
   pixels for repeated placements of one species plus distinct descriptor/cache/pixel evidence for
   meaningfully different species. Export one native-scale color/grayscale multi-species map for
   review without changing the contract.
3. Add one integrated cache/request test proving changing grade, terrain seed, ground or flora
   descriptor invalidates the image key while a redraw of identical facts reuses it.
4. Keep flora ungraded for this checkpoint. If playtesting later shows it visually detached from
   extreme worlds, first decide on a bounded identity-preserving adaptation, add `worldGrade` to a
   new flora render tuple, and publish cross-language vectors before porting it.

So the direct answer is **yes** for live terrain recoloring and feature variants, and **yes** for
live generated flora species variety. The main remaining work is breadth/integrated visual
acceptance, not wiring those facts into the current renderer.

### 11 Aug 2026 — campaign deletion identity design correction

**Disposition: settled design correction superseding the engineering inference immediately above.**
The UUID-bearing alert title/button in current native source is **not** an accepted resolution of
duplicate campaign names. Stable UUID owns storage and DEBUG Technical details, but must not appear
in ordinary player-facing card, detail, accessibility or destructive-confirmation copy.

Native campaign deletion therefore remains one open presentation issue: replace the UUID prefix in
the alert title and destructive button with a player-legible discriminator derived from known
metadata, such as last-played date/time and/or location. For unknown/corrupt metadata, use the
already player-visible recovery label/name treatment rather than exposing technical identity; the
focused selection still owns the exact UUID internally for callback correctness. Tests must cover
two same-name known campaigns with distinct player-facing confirmation/accessibility labels and
prove each invokes only its selected UUID, while release copy contains no UUID. DEBUG Technical
details may retain the full UUID.

Also align health-specific actions/copy: future-incompatible uses native wording `From a newer
version` and `Compatibility details`; corrupt uses recovery wording/action; valid cards retain
Load plus More. AssetLab v0.2 remains recommendations-only and its 32px motif remains proposed art,
not a native pixel fixture. This correction supersedes only the prior UUID-as-player-discriminator
approval; the focused destructive flow, metadata guards, DEBUG placement, neutral bookplate channel,
Continue filtering and accessibility column behavior remain sound.

### 11 Aug 2026 — catalogue item identity proof v0.1 visual review

**Disposition: recommendations only; the exact-ID direction passes, but hold golden promotion for
two small silhouette corrections and one disclosure adapter proof.** Direct inspection of
`AssetLab/artifacts/catalogue-item-identity-proof-v0.1.png` confirms the corrected 30-item scope:
eleven ordinary gear identities, seventeen consumables and two curios, plus a separate unknown
item. The native 32-pixel color and literal-grayscale rows are lossless and the separate key allows
the silhouettes to be judged without labels beneath the cells. Gear slots read as physical objects;
the three salves and wider draught/treatment set share a controlled vessel language without being
pixel-identical; Humming Shard and Bound Knot honestly read as a shard and tied object. The wrapped
unknown parcel is distinct from the known catalogue and does not preview either curio's result.

Two pairs remain too dependent on small detail at this scale:

1. `long_pick` and `bent_pick` retain nearly the same horizontal head plus central vertical shaft in
   native grayscale. They can coexist in an All-items grid even though their slots differ. Give the
   Bent Pick a strongly hooked, shortened or visibly crooked outer mass while retaining Long Pick's
   long balanced head; do not use color, rarity or a tool badge to separate them.
2. `draught_clearing` and `farsight_draught` have closely related medium bottle bodies with small
   lateral tabs. Preserve their shared draught ancestry, but change one large outer axis—shoulder,
   neck, base or a carried optical attachment—so the distinction survives an unlabelled glance.
   Do not turn the attachment into a standardized eye/effect glyph. Quenching Draught, the salves,
   Stonebark Tonic, Stillwater and the treatment bottles are sufficiently separated for this slice.

Waystone is recognizable as a tall carried object, but it currently sits near the bottle grammar.
This is not a blocker if its next revision strengthens the already settled tiny carried edge-
instrument fiction with paired frame/prong mass rather than a vial neck. It must not become a house,
portal or promise that a particular world is anchored.

The source exposes known-ID commands and one generic unknown command separately. Add one closed
resolution fixture proving both unidentified curios resolve to the **same** unknown commands before
identification, while their legitimately identified states resolve to their distinct authored
forms. Merely proving that the generic unknown hash differs from every known hash does not prove a
caller cannot select the known form from `catalogItemID` too early. The resolver must not inspect
`identifiesInto`, rarity, stats or eventual kind while unidentified.

Re-export the same compact proof after those focused changes, retaining the unlabelled native
grayscale row and separate key. Add an at-risk row containing Long Pick, Bent Pick, Clearing
Draught, Farsight Draught, Waystone, both known curios and the single unknown parcel. Keep the
existing exact-ID coverage, pairwise silhouette, bounds and deterministic tests, and add the paired
unidentified-curio equality assertion. No broader tier, apex weapon, key or progression-object
expansion is requested for v0.1 closure.

#### Catalogue item identity proof v0.2 closure

**Accepted for AssetLab golden promotion as the first exact-ID catalogue slice; recommendations
only, with no native integration authorization.** Direct inspection of
`AssetLab/artifacts/catalogue-item-identity-proof-v0.2.png` confirms all three v0.1 blockers are
closed at native 32-pixel scale in both color and literal grayscale.

- Long Pick retains a long balanced horizontal head, while Bent Pick now has a short crooked stepped
  hook and offset shaft. The pair no longer relies on color or a small surface mark.
- Clearing Draught is now a broad offset-neck canteen, clearly separated from Farsight Draught's
  round, symmetric vessel while preserving their related draught construction language.
- Waystone reads as a three-prong carried edge instrument rather than a bottle, house or portal. It
  makes no claim about a particular anchored world.

The remaining related families are controlled and readable: three salves share jar ancestry but
retain distinct mass; treatment bottles, Stillwater, Torch, the two known curios and all eleven
ordinary gear identities remain separable in the unlabelled grayscale row. Names are represented by
honest physical-object silhouettes rather than effect, stat, rarity or provenance badges.

The new closed `resolveCatalogueItemIcon` boundary accepts exactly `catalogItemID` plus
`identified`, rejects extra, unknown and unsupported requests, maps both unidentified curio IDs to
identical wrapped-parcel commands, and maps their identified states to distinct authored forms.
This closes the disclosure leak that a separate generic-unknown helper alone could not prevent.

Promote v0.2 with its focused resolver, exact-ID coverage, pairwise silhouette, bounds and
determinism tests. Keep rarity, tier, stats, provenance, quantity, location and selection outside the
identity pixels. Later tier lines, apex weapons, keys and unique progression objects remain separate
authored expansions; their absence does not block this 30-item golden boundary.

### 11 Aug 2026 — illumination/vitality source and adapter audit

Recommendations only; this is a read-only audit of the current native rules and frozen AssetLab
boundaries. No native or AssetLab implementation was changed, and Simulator was untouched.

#### Current illumination behavior

- `WorldGrade.from` consumes the resolved illumination **midpoint** `(peak + floor) / 2`, maps it
  through the signed centered scale, and contributes `16 * light` to the grade's value channel
  (bounded to `-20...20`). Substrate contributes the remaining value term. This grade recolors
  terrain pixels; it is not a light source, fog mask, current-visibility result or atmosphere
  sprite.
- Exploration sight is a separate rules path. Day sight is book base vision plus party sight plus
  the persisted run's `torchVisionBonus`; night subtracts the fixed night penalty. Whether a world
  has a day/night cycle is derived from illumination range and the `sourceless` tag, while the
  turn-driven world clock decides whether it is presently night. Illumination magnitude itself is
  not passed into `visionRadius`.
- `WorldRules.reveal` permanently sets `Tile.isRevealed` after line-of-sight/elevation/cover tests.
  Movement repeats that operation. There is no second per-turn `currentlyVisible` tile set and no
  re-darkening of already revealed tiles. The map compositor consequently receives persistent
  reveal, not current sight.
- Torch is an ordinary consumable whose `lightWorld` potency is `2`. Applying it takes the maximum
  of the existing and new run bonus, then immediately reveals from the current position using the
  enlarged radius. The bonus lasts for that run and does not stack additively. It does not modify
  WorldGrade, the world's illumination reading, atmosphere, clock, or tile pixels.
- Smoke is a pressure source, not a render fact: it lowers illumination peak/floor, adds a small
  thermal contribution, and raises atmosphere with `choking`. Atmosphere density separately alters
  thermal range. Those resolved consequences can indirectly affect grade, night/life constraints
  and generation, but there is no native smoke/haze/atmosphere map overlay request today.

#### Current vitality/flora behavior

- Resolved vitality peak directly sets flora cast capacity: viable worlds start at the configured
  lower bound and gain one species per `vitalityPerExtraSpecies`, clamped to the configured range.
  Zero vitality or no metabolism above the viability floor yields no flora.
- Vitality peak also increases each generated species' purchasable trait budget and gates whether
  active defence is affordable; vitality `trophicDepth` raises defence weighting and participates
  in that active-defence gate. It does **not** directly pick a species' stature, habit, or color.
- Placement uses resolved vitality peak again as productivity. `paintGrowth` multiplies it by mean
  cast stature and coverage tuning to obtain a tile budget. Species then take turns spending that
  budget. Each species' already-resolved habit determines patch walk length/topology, and its
  already-resolved `blocksSight`/stature outcome chooses groundcover versus sight-blocking growth.
  Thus vitality controls total quantity, but patch shape and tall/short classification belong to
  the resolved species.
- Stature tendencies are driven directly by illumination, water and thermal conditions; habit is
  influenced by darkness, drought and cold. Color depth is directly biased by illumination, with
  substrate/toxic-atmosphere affecting finish/defence-related tendencies. Vitality affects these
  only indirectly through the shared species budget and environmental constraints; it is not a
  second color/stature scalar.
- Illumination can cap resolved vitality through `WorldConstraints` when photosynthesis is required.
  Fungal/decaying or sufficiently chemosynthetic worlds relax that relationship. Consequently the
  final vitality used by cast and placement is already constraint-resolved and must not be
  recomputed by an asset adapter.

#### Exact integration boundary and gaps

- Keep `WorldGrade` as the closed terrain/character palette input. Its existing green channel also
  contains resolved vitality (`22 * life`) while actual growth placement separately represents
  vitality. This is a real double visual signal, especially on bare substrates; changing or
  removing it requires a new world-grade adapter version and conformance vectors, not an
  unversioned native tweak.
- Keep flora identity requests pressure-free. The live flora descriptor already carries stable
  resolved stature, tissue, defence, habit, coloration, finish, metabolism, species seed and ID.
  Asset renderers must not accept vitality/illumination and re-derive size, color, density or threat
  from them. Native world generation owns cast membership and each tile's flora ID; the renderer
  draws that resolved occupant.
- Persistent `isRevealed` remains the only safe fog input. If design wants illumination/Torch to
  affect the appearance of what is visible **now**, rules first need a game-owned current-visibility
  result with settled persistence/disclosure semantics. AssetLab should then accept that bounded
  fact, never recompute sight from pressure readings.
- A visible smoke, haze, choking-air or other atmosphere layer needs its own closed, versioned,
  game-owned overlay descriptor: resolved visual kind/intensity, reveal/current-visibility policy,
  seed/phase if animated, layer order, and Reduce Motion behavior. `WorldGrade` and the raw
  atmosphere reading are insufficient and should not silently trigger decorative smoke.
- Placement quantity and topology require no new asset field. Evidence sheets may fixture multiple
  resolved tile placements, but those are proof inputs rather than claims that AssetLab owns
  ecology. Likewise, illumination-driven stature/color differences should be proven by distinct
  resolved species descriptors, not by applying a world tint to one species identity.

#### Illumination correction — design disposition

**Aimee's direction supersedes only the illumination portion of the preceding audit:** illumination
must not recolor terrain. Remove the illumination midpoint from the next versioned world-grade
adapter. Thermal, Hydrology, Vitality and Substrate may retain their separately reviewed bounded
conditioning; the value channel may use a non-light material input or remain neutral. Do not alter
`world-grade-1.0.0` in place: publish a new immutable tuple, vectors, cache identity and native/
AssetLab conformance proof. Sun, moon, night and Torch then affect a separate visibility/light layer,
not the saved terrain or flora identity pixels.

Keep `Tile.isRevealed` as permanent, append-only knowledge and add a derived non-persisted
`currentlyVisible` result. Rendering needs three closed states: (1) unrevealed uniform fog with no
descriptor-dependent pixels; (2) revealed but presently unseen remembered terrain under a distinct
darkness treatment, without live/moving/transient bodies; and (3) currently visible terrain and
legitimately disclosed content. Newly current-visible tiles union into permanent reveal; nightfall,
movement and Torch expiry never erase it. Fog and remembered darkness must remain visibly and
accessibly distinct, and known water/chasm/passability shape must remain legible enough to navigate.

Game rules should resolve current visibility from party position, LOS blockers, current light
magnitude, party sight capacity, local light sources and Atmosphere. AssetLab receives only the
per-tile visibility state plus a bounded display-light/falloff value; it must not calculate sight
from raw pressure readings or inspect hidden content. For the first slice, current ambient light may
truthfully use illumination `peak` during the light interval and `floor` during the dark interval;
a continuous Cycle curve is later work. Torch remains a persisted run-local source with rules-owned
radius/intensity/duration, rather than adding brightness to terrain colors.

Atmosphere clarity and density may constrain radius/falloff and supply a static haze inside already
visible space. Smoke may be named or drawn as smoke only from an explicit resolved visual-atmosphere
kind; low clarity, density, mist, toxicity and smoke are not interchangeable. Use a binary threshold
for disclosure and a separate bounded gradient for presentation, so low alpha never leaks a hidden
silhouette. Creature detection remains separate: nonvisual creatures may detect the party without
becoming player-visible.

The safe remembered-state default retains known terrain, routes and legitimately discovered fixed
landmarks, while hiding moving creatures/travellers and transient/current-state bodies. A disclosed
apex may retain a knowledge marker, but its live sprite/location must not track through darkness
without an explicit last-known-position rule. The minimap continues to represent permanent
legitimate knowledge, not the current light pool.

Smallest proof: one native-phone map in daylight, true dark without Torch, true dark with Torch, and
low-clarity/explicit-smoke light, each in color and grayscale. Include fog, remembered terrain,
newly visible ground, ordinary/deep water, chasm, elevation, low/tall growth, route, party, a fixed
known site, transient drop and moving creature crossing the light boundary. Terrain/flora identity
geometry and base pixels must remain identical before the separate darkness/haze layer. VoiceOver
distinguishes “unrevealed” from remembered terrain and may announce “Dark beyond torchlight” without
naming hidden content; High Contrast preserves all three states without alpha alone and Reduce
Motion uses static haze.

Open tuning decisions may use nonblocking placeholders: keep `trueDarkFloor == 5` only as the
provisional no-usable-ambient-light boundary; let darkness cap ordinary visual sight at available
light reach; preserve Torch's current rest-of-journey duration; use generic haze for low clarity and
named smoke only for explicit smoke. Exact dim bands, Torch radius/intensity combination, remembered
content list and apex last-known behavior remain Game Design/rules decisions before freezing the
request schema.

#### World-grade v2 exploratory calibration v0.2 — Design disposition

**Accepted as a calibration foundation, not as a universal world-uniqueness rule.** Direct review of
the color, grayscale and light-sequence artifacts plus the machine-readable distance report confirms
that v0.2 now isolates the intended visual owners: material transform/family, Granite material color,
explicit smoke density/palette/color, Sun emitter color, Bloom flora color, resolved flora cast and
current visibility. It no longer uses arbitrary novelty as evidence of success.

The governing rule is proportional: visual distance must reflect relative meaningful authored and
resolved diversity. Worlds with very similar facts and construction should remain recognizably in
the same visual family; worlds separated across several strong material, atmospheric, ecological or
emitter facts should diverge correspondingly. Exact twins may look identical. Near neighbors must
not be pushed apart merely because they are two different world records, seeds or expedition slots.
Likewise, deterministic variation must not disguise genuinely opposed worlds as the same place.

Under that rule, the controlled material sequence is directionally sound: normalized input distances
`0.054 → 0.44 → 0.72` produce measured whole-frame ΔE `1.081 → 5.259 → 9.610`. The first pair reads
as siblings, not as a failed differentiation. Scoped Bloom color is appropriately strong on flora
while subtle over the whole frame (`18.763` on its eligible layer, `0.673` whole-frame); Granite is
similarly bounded. The opposed composed pair is strongly distinct without changing map geometry.
The grayscale sheet retains the established rule-bearing terrain/content hierarchy, and the light
sequence reads as one known world under changing visibility rather than three differently colored
world identities.

This disposition does **not** freeze palette catalogues, blend coefficients or universal numeric
thresholds. The next evidence should preserve intentionally similar controls, identify each
comparison's exact eligible input facts, and add phone-size unlabeled recognition checks. Acceptance
is based on truthful ordering and bounded ownership within each comparable layer; no single global
distance or requirement that “two worlds must differ” may be introduced into generation, selection,
tests or documentation.

#### Authored-color vocabulary proof v0.1 — Design disposition

**Accepted as an exploratory visual/accessibility foundation; not frozen content authority.** Direct
inspection of `authored-color-vocabulary-proof-v0.1-color.png`, its literal-grayscale companion and
the keyed JSON confirms that all twelve proposed marks retain a distinct redundant pattern when hue
is absent. The Sun/Smoke/Granite/Bloom examples preserve their four separate scopes rather than
reading as one global tint. Yellow, Orange and Ochre are visibly distinct; Ochre's relationship to
ordinary earth ramps is desirable rather than a collision, so this proof supplies no reason to add a
generic Brown word.

The exact OKLCH coordinates and pattern geometry remain Asset recommendations. The twelve IDs,
starter/common/later grouping and first-slice omission of Brown are reversible Game Design
recommendations in `authored-color-vocabulary-current.md`, **not Aimee-settled decisions**. The
artifact/report must not label them settled or migration authority. Settled structural authority is
narrower: color is a connected scoped authored declaration rather than a global theme, Flora and
Creature scopes remain separate, and visual distance follows relative meaningful diversity.

Before native integration, show the same keyed name/pattern/swatch grammar at actual Writing Desk
tile size and accessibility text sizes. Color-name text may live in a separate key or detail surface,
but the interactive palette cannot require memorizing an unlabeled contact sheet. Keep
`integrationReady: false` until Game schema, typed qualifier acquisition, bind persistence and the
versioned renderer contract are jointly accepted.

#### Authored-color correction — ink mixing progression

**Superseding Game Design direction.** The twelve-swatch proof remains useful only for gamut,
pattern and grayscale research. It is not a live vocabulary or acquisition catalogue. Color is now
authored through optional **CMY + Depth ink recipes** stored on eligible source marks; it consumes no
extra page cell. Starting **Ash** ink is nil/unspecified and leaves color open to a scope-valid
bind-time random roll. Explicit mixed black is a distinct non-nil recipe.

Isolde is the existing Penmaker progression owner. Her **Brush** is the first liquid-ink hand; the
Scriptorium tier-1 **Ink Mixing** upgrade is a direct adjacent Brush prerequisite and unlocks the
mixer and saved-mixture library at the Writing Desk. Asset UI proofs should therefore show Rough
charcoal, Brush with Ash/open, and Brush with unlocked CMY+Depth states rather than
a starter/common/later color-word catalogue. Preserve the accepted redundant-pattern work for mixed
recipes and presets, and prove that Ash/open versus explicit black never relies on matching dark
pixels alone. Do not begin native integration from the earlier fixed-swatch schema.

**Resource-economy correction:** the unlock teaches mixing but does not grant infinite colored
pigment. Cyan/Magenta/Yellow/Depth bases are prepared from provenance-honest world resources;
saved recipes become bounded vials, with twelve focus applications as the first DEBUG candidate.
Drafting/preview is free and applications are charged atomically at bind. Ash remains unlimited.
Asset proofs should therefore include base stock, exact consumed-resource provenance, vial remaining
applications and an Ash fallback, without making a generic resource's icon/color assert a pigment
profile it does not actually persist. Exact base recipes remain Game Design review candidates.

#### First-class authored color values — compositional grammar

**Historical/superseded schema exploration.** The following fixed `BookColorValue`/named-swatch
section predates the ink correction above. Retain it for scoped-composition and disclosure reasoning
only. It does not override CMY+Depth recipes, Ash=nil/open, Isolde's unlock or resource-derived base
stocks, and must not be used as native schema/acquisition authority.

**Aimee approves the stronger color directions together.** Color should be a first-class declared
book value that can attach to many legitimate written things—a Sun, smoke, water, substrate,
flora-producing source or other eligible referent—rather than a single global Atmosphere tint.
This extends, and does not undo, the illumination correction above: a colored Sun colors the light
it emits; it does not rewrite the stored albedo/identity of every terrain tile.

The first slice should expose an authored `BookColorValue` with a stable ID, player-facing name and
canonical color coordinates. Use a small reviewed named-swatch vocabulary initially; a freeform
picker can follow only when contrast, naming, save migration and cross-platform color-space behavior
are settled. Canonical numeric values and weights are provisional, but composition must use fixed,
versioned color-space math rather than platform `Color`, CSS parsing or page-order-dependent blends.

Every attachment resolves to one explicit scope:

| Scope | Eligible meaning | What color may change | What it must not change |
|---|---|---|---|
| **Emitter** | Sun, Moon, flame, luminous crystal/fungus or another actual light source | the hue/chroma of that source's current visible light contribution and source body | terrain/material identity, permanent reveal, visibility radius, heat, damage or source identity |
| **Atmosphere** | smoke, mist, cloud, airborne ash or another resolved visible medium | haze/scattering color inside currently visible space | inventing smoke from low clarity, tinting fog, toxicity/density/radius, hidden content |
| **Material** | substrate, sand, ice, water or another eligible physical material family | bounded base albedo/palette of the resolved material before lighting | passability, depth, cracks, adjacency, elevation, resource identity or rule-owned value separation |
| **Ecology** | a flora-producing/living source or explicit ecology-wide declaration | generation-time palette tendency of legitimately generated flora/creatures | species anatomy, stats, defence/toxicity, placement density, exact hidden species or a runtime global recolor |

An attachment is local to its referent. `Crimson → Sun` colors that Sun's emitted light; it does not
mean “make the world red.” `Ochre → Substrate` affects eligible material palettes; it does not color
water, people or sky unless separately attached. `Violet → Smoke` affects visible smoke scattering;
it does not imply poisonous air. `Blue → Flora` biases the resolved ecology palette but still
permits distinct species identities and value patterns.

##### Composition and precedence

Resolve color in physical/presentation order, never with one last-write-wins tint:

1. game facts choose terrain/material, atmosphere kind, emitter bodies, species descriptors and
   disclosure;
2. material-scoped declarations resolve bounded base albedo while preserving invariant
   affordance/value grammar;
3. ecology-scoped declarations participate once in species generation and persist in the resolved
   species descriptor;
4. current emitter contributions combine into the visible lighting field according to actual
   source presence/phase and the rules-resolved light amount;
5. atmosphere-scoped color scatters/filters that light according to the rules-resolved visible
   medium and density/falloff;
6. darkness, current-visibility and accessibility overlays compose above the scene; interaction,
   selection, crack and warning channels retain their independent invariant contrast.

More-specific valid attachment beats a broader declaration only for the same eligible referent:
source instance → source family → subject/world default. Equal-specificity declarations combine
deterministically by rules-resolved contribution weight, not array order. Multiple emitters add
their current light contributions; multiple pigments/material declarations mix as material color;
multiple ecology declarations produce a bounded palette tendency. These are different blend modes
and must not share one generic `mixColors` shortcut. Clamp chroma/value and preserve a stable
outline/highlight whenever the result would collapse grayscale or substrate contrast.

Two colors on one referent are not silently an error or an automatic contradiction. The closed
resolver should either produce a deterministic mixed/multiband declaration supported by that
referent, or reject the attachment with a visible authoring reason. It must not pick the last page,
reroll, alternate by frame or infer dominance from rarity. Complementary colors may legitimately
neutralize; the preview must show that outcome before binding. Exact mixing coefficients and the
initial attachment-eligibility table remain provisional tuning/content data, versioned separately
from renderer geometry.

Absent color means the existing neutral/authored default for that referent. Unsupported, orphaned,
cyclic or wrong-scope attachments reject at book validation; they never fall back to a global tint.
Legacy books with no color declarations remain visually stable under the new adapter's neutral
vectors. Changing a color declaration or attachment changes the bound world's descriptor; viewport
redraw, save/load and anchored revisit do not reroll it.

##### Disclosure boundary

The Writing Desk may preview exactly what the player attached: swatch name, target name and scope,
plus the bounded composed preview where all contributing declarations are already authored. It must
not reveal rolled companion colors, hidden species, undiscovered emitters, toxicity, resource family
or site identity. In-world appearance can show colored light or haze without naming its cause; later
earned analysis may explain the source relationship.

Unrevealed fog remains invariant and receives no emitter, material, ecology or atmosphere color.
Remembered terrain may retain legitimately known material color under the darkness grammar, but no
current colored light, haze body or moving content. The minimap remains symbolic and does not become
a color thumbnail. Color is never a unique mechanic code: water depth, chasm, hazards, growth
height, route, selection and warnings retain redundant shape/value/text channels in colorblind,
grayscale and High Contrast modes.

##### Smallest bookwriting and two-world proof

Use one native 390-point Writing Desk fixture with four declared swatches and explicit attachment
chips: one color attached to a Sun/emitter, one to visible smoke/atmosphere, one to Substrate/
material and one to Flora/ecology. Show a valid multi-color composition, one unsupported attachment
with its reason, neutral default behavior, and preview copy that names only authored facts. Include
large text, grayscale/colorblind evidence, 44-point ownership and VoiceOver order from color value →
attached referent → scope → composed preview/result.

Bind two deterministic comparison worlds from the same terrain/flora placement seed and mechanical
facts but different authored color attachments. Each world needs daylight, true dark and local Torch
panels. Prove that:

- material color persists as the same material identity while the colored Sun affects only present
  lit space and disappears from remembered darkness;
- explicit smoke colors only the resolved smoke/haze layer and changes neither light radius nor
  disclosure by itself;
- ecology color produces stable distinct species palettes at generation, with identical species
  geometry/placement under redraw and no universal runtime wash;
- terrain, flora and content geometry; current/permanent visibility; passability; minimap disclosure;
  and VoiceOver labels are identical between color variants;
- literal grayscale and colorblind simulations preserve every rule-bearing distinction; and
- canonical request/rectangle/pixel hashes remain deterministic across relaunch.

Open decisions before schema freeze are the initial named-color vocabulary, eligible source table,
whether one referent supports bands/patterned color or only a resolved mix, fixed color space and
blend coefficients, saturation/value clamps, and whether ecology-wide declarations affect flora,
creatures or require separate Living/Flora attachments. None should be inferred by AssetLab while
the rules contract is unsettled.

### 11 Aug 2026 — true combat graph v0.3 Design disposition

**Accepted as topology/presentation evidence after direct Game Design Lead inspection; not native
implementation approval.** Aimee rejected combat v0.2 because three vertical eight-node lanes with
occasional diagonal links remained ladders. That artifact is historical and `mustNotPromote`.

The replacement `AssetLab/artifacts/combat-tree-true-graph-proof-v0.3.png` is generated from the
hash-pinned `docs/combat-tree-v2-authority.json`, not a separately handwritten Offense graph. The
exact 776×850 export contains complete paired 368×800 color and literal-grayscale phones. All three
roots visibly fan into two fundamentals, two developments and two masteries before three capstones;
solid own-discipline and dashed authored-hybrid edges read independently. All capstones, selected
detail, exact parents, route gate, Learn/preview controls and legend remain onscreen without cropped
bounds or colliding node labels.

The validator rejects disconnected required mastery, premature capstone, unknown IDs, duplicate
nodes and manifest hash drift. Exhaustive manifest-derived enumeration reports 79 Offense, 67
Defense and 66 Craft legal connected eight-point capstone-route sets, exceeding the minimum 30 per
tree; all six named design routes validate. The compact `F/P/S + depth/branch` codes are proof
notation only. Final native nodes use authored glyphs and anchored full names, never these codes as
player vocabulary. Technique identity remains explicit per node and cannot be inferred from graph
role. Engineering promotion still requires all 72 scenario consumers, migration/point parity, typed
technique parameters, full native accessibility and device evidence in the current combat design
documents.

### 11 Aug 2026 — research graph v0.1 Design review

**Recommendations only; v0.1 is not yet accepted evidence.** The paired 368×800 color/grayscale
composition, Hold diamond coverage, selected detail region and topology-preserving Large Text split
are directionally correct. The proof also correctly keeps station/cost/keeper gates separate from
node ownership.

Small corrections are required before disposition:

- Field Instruments' eight nodes are independent station-gated roots. The continuous horizontal
  rail with vertical strokes currently uses connector geometry and reads as a shared hidden parent.
  Replace it with a labelled enclosure/root-band background or eight unconnected placements; gate
  membership must not resemble prerequisite edges.
- Large Text must translate internal gates such as `externalKeeperRequirement` and
  `springBranchCurrentLive` into authored player language. `gate none` should be omitted, not printed.
  Exactness means exact player-facing requirements, not exposing schema enums.
- The ordinary Hold proof's compact S/T/D codes may remain test notation only if selecting any node
  exposes its full authored name and the final native glyph plan is recorded. The player-facing graph
  cannot ship as numbered boxes.
- Add a direct invariant that independent roots have zero rendered prerequisite connectors, alongside
  the existing exact-edge-set check. Preserve a distinct non-edge grammar for keeper/station gates.

After those corrections, the smallest final evidence remains these same two fixtures plus anchored
edge-clamping and the already-generated Large Text rank outline; no broader art batch is needed.

### 11 Aug 2026 — research graph v0.1 final disposition

**Accepted as isolated presentation evidence after direct inspection; not native implementation
approval.** The corrected Field Instruments proof removes the false shared-parent rail and places all
eight station-gated studies inside a clearly labelled non-edge enclosure. Each root has zero rendered
prerequisite connectors and its full authored instrument name/glyph remains visible in color and
literal grayscale.

Hold now uses stable pictograms rather than S/T/D proof codes, preserves every ordinary and keeper
prerequisite edge, and keeps the selected full name/detail below the graph. Large Text replaces raw
schema enums and `gate none` with exact readable prerequisites, preserves the full two-part rank
outline and names keeper/Spring gates without inventing node edges. Native promotion still requires
rules-derived affordability/gate copy, edge-clamped detail at phone bounds, VoiceOver order and all-
branch exact-edge tests from `research-tree-graph-presentation-current.md`.

### 11 Aug 2026 — Constellation first-slice v0.1 disposition

**Accepted as isolated presentation evidence after direct inspection; not native implementation
approval.** The proof honestly renders the Constellation's one live node as one quiet centred star,
with no invented locked stars, branches or future-reset fiction. Affordable, shortfall and bought
states preserve the same position and use redundant outline/fill/check geometry in color and literal
grayscale. The bought state visibly reaches rank 1/1 and removes the purchase action; wallet, exact
three-Mote cost, rank and campaign-wide current/future-person effect remain legible.

The accessibility panel increases text without creating a catalogue/list or false graph. It also uses
the exact settled Reality sentence rather than promising permanence beyond the campaign. Native
promotion remains gated by atomic 0/1 purchase, current/future eligible-person Gambit consumers,
relaunch, VoiceOver and 368×800/large-text evidence in `constellation-first-slice-current.md`.

### 11 Aug 2026 — Consumable / Field Kit v0.1 Design review

**Recommendations only; v0.1 is rejected as state-consistency evidence pending a contained fixture
correction.** The three Apothecary families, six-across pictorial tray, selected persistent detail,
world-resource terminology, shortage copy and large-text reflow follow the intended screen grammar.

Two visible contradictions currently undermine the loadout proof:

- Apothecary's selected Lesser Salve tile shows a `0` quantity badge while its detail says
  **Owned 2**. One rules-owned quantity must feed both presentations; if the badge represents another
  fact, it needs a redundant glyph/accessible label and the selected fixture must make that fact
  intelligible.
- Field Kit shows positive desired counts on all six item tiles (`3, 1, 1, 1, 2, 1`) while the footer
  says **4 distinct bins selected / 4 available**. Desired count greater than zero defines a selected
  family, so this fixture has six selected bins. The UI may prevent adding a fifth family, or visibly
  show a saved over-cap migration state that must be resolved before departure; it cannot silently
  pack only the first four by saved order.

Corrected evidence should use exactly four positive desired families, show two zero-desired available
families, attempt/disable a fifth-family `+`, and prove that increasing quantity within an already
selected family does not consume another bin. Tile/detail owned and desired values must be generated
from the same fixture. No broader visual redesign is needed.

### 11 Aug 2026 — Consumable / Field Kit v0.1 corrected disposition

**Accepted as isolated presentation and state-consistency evidence after direct inspection; not
native implementation approval.** The regenerated proof now derives each selected tile and anchored
detail from the same fixture: Lesser Salve consistently reads stored 1 / wanted 3 in both places.
Exactly four families have positive desired quantities, two remain available at zero, and the footer
truthfully reports 4 selected / 4 bins. The selected-family `+` remains available without increasing
the distinct-bin count, while adding Torch as a fifth family is explicitly disabled at capacity.

The six-across tray, three recipe-family tabs, shortage disclosure, literal grayscale treatment and
Large Text reflow preserve the accepted player-facing grammar. Native promotion still requires one
rules-owned loadout resolver, an explicit unavailable fifth-family action, migrated over-cap repair,
atomic Bind/Revisit packing and return, and 368×800/VoiceOver evidence from
`consumable-economy-field-kit-current.md`. The Asset proof remains a proposed semantic fixture and
does not authorize native inventory mutation by itself.

### 11 Aug 2026 — World History archive / comparison v0.1 Design review

**Recommendations only; the ordinary archive and comparison semantics pass, but one promised
accessibility state still needs visual evidence before acceptance.** Direct inspection of
`AssetLab/artifacts/world-history-proof-v0.1.png` confirms that ordinary History is a compact
two-column cover collection rather than forty expanded prose cards. Selection order is visibly
numbered while chronology is record-owned: selecting World 12 then World 9 still compares Earlier
World 9 against Later World 12. The structured comparison truthfully renders the stable-key union
with added, removed and changed states, explicit **Not written**, and **Not measured in this record**.
Color and literal grayscale preserve selection, kept/chance-led state and cover separation.

The corrected adapter now keeps the settled `ecologyMarkID`, uses one neutral legacy cover without
rerolling, rejects unrestricted numeric measurement maps, and consumes only prepared disclosed
display values plus an earned relation. Keep that relation in the ephemeral comparison view; it is
not a new pair-dependent fact stored on either frozen world record.

The proof manifest asserts `accessibilityColumns: 1`, but the rendered sheet includes ordinary color,
ordinary literal grayscale, ordinary comparison and Large Text comparison only. It does not show the
required Large Text **archive** becoming one compact cover per row. Add the smallest separate 368×800
archive Large Text fixture with at least four covers, both selection orders, kept/chance-led/ordinary
states and the Compare footer. The cover must remain compact and must not expand full record prose.
No broader redesign or another comparison export is needed. Native implementation remains gated by
safe search/disclosure, erase/reconcile behavior, frozen-cover migration and VoiceOver tests in
`world-history-collection-comparison-current.md`.

The regenerated five-panel sheet closes the requested one-column Large Text archive, shows all four
request-difference states, and keeps measurement relation out of saved records. One last tiny visual
correction remains before final acceptance: the Large Text archive drops **Search** while the ordinary
archive shows it. Reflow Search onto its own toolbar row or a labelled 44-point control; accessibility
cannot make a settled browse function disappear. Preserve the current four covers, footer and all
other panels unchanged.

#### World History v0.1 final closure

**Accepted as isolated archive/comparison presentation evidence; not native implementation
approval.** The final 1864×850 lossless sheet restores a full-width labelled Search control above the
one-column Large Text archive without expanding any record into prose. Four compact covers preserve
kept, chance-led and ordinary states, both selected-order marks and the persistent comparison footer.
The ordinary color/grayscale archive, complete added/removed/changed/unchanged comparison, Large Text
comparison and disclosure-filtered measurement treatment remain unchanged. Native gates in
`world-history-collection-comparison-current.md` still apply in full.

### 11 Aug 2026 — world-grade-2 v0.2 resumed P0 Design review

**Recommendations only; v0.2 closes the v0.1 control/schema defects, but the required keyed visual
evidence is absent, so Design cannot honestly assign final calibration dispositions yet.** Direct
inspection of the lossless color, literal-grayscale and light-sequence exports confirms several
important boundaries: geometry and disclosure remain fixed; near/mid/far derived material changes
are gradual rather than novelty-driven; strong composed oppositions separate; grayscale keeps route,
water, chasm, growth and object structure; and dim/Torch presentation composes after inherent
material color. Similar fixtures visibly remain related, satisfying the inverse half of relative
diversity rather than forcing every world apart.

The JSON now separates resolver-produced transforms, palette-family threshold steps, categorical
authored colors, smoke density/family, explicit game-resolved flora geometry, opposed composition and
current visibility. It records controlled input facts and per-layer/whole-frame distance, excludes
Illumination and raw Vitality from inherent terrain grade, and does not runtime-optimize novelty.
Those corrections align with `world-color-differentiation-current.md`.

One manifest paragraph is historical and must not become integration schema:
`authoredInputBoundary` still describes a connected named **Color qualifier** projected into
`Sigil.color`, and the proof request calls its calibration swatch `colorID`. Decision 138 and
`authored-color-vocabulary-current.md` supersede that route: the player mixes CMY+Depth ink, the exact
`InkRecipe?` is stored on the placed source rune, and binding converts it through a versioned resolver
into a frozen game-owned scoped color. Named red/blue/etc. fixtures may remain useful gamut labels,
but they are calibration inputs—not the live authorship type, acquisition vocabulary or a reason to
reduce mixed colors to named swatches. The keyed proof/report should say this explicitly; any future
integration manifest must accept the resolved color representation and provenance/version, not the
obsolete qualifier field.

However, only the unlabeled 4×N map sheet is exported. The design brief explicitly requires a keyed
copy, and the current files give no lossless visual mapping from each 112×112 frame to fixture ID,
controlled layer, input-distance band and measured distance. JSON array order is not a usable visual
review surface and makes a mistaken row/column interpretation too easy. Export one same-order keyed
sheet (labels may sit outside map pixels) naming every fixture and annotate each comparison with its
layer, input band/value and whole-frame/layer distance. Keep the current unlabeled sheet unchanged
for unbiased gestalt review.

No new palette work is requested before that export. Once keyed, Game Design will label each
controlled comparison **too flat / proportionate / too divergent**, decide whether the categorical
Granite/Smoke/Sun/Bloom treatments are strong enough at phone scale, and either accept palette-family
breadth or request only named local adjustments. Native integration remains blocked until that
calibration disposition and Engineering's version/cache/migration review.

#### world-grade-2 v0.2 keyed calibration closure

**Accepted as the isolated palette/relative-diversity candidate; not native integration approval.**
Direct inspection of `world-grade-2-proof-v0.2-keyed.png` now maps every unchanged 112×112 frame to
its fixture, controlled input and whole/layer distance. The manifest also correctly replaces the
obsolete named-Color qualifier claim with exact optional CMY+Depth rune ink → versioned bind resolver
→ frozen scoped color/provenance; named hues are calibration labels only.

Game Design dispositions:

- base→derived-near (`ΔE 1.081`), mid (`5.259`) and far (`9.61`): **proportionate**. Near remains
  related, mid is perceptible and far is materially distinct without pretending to be unique;
- pale-neutral→warm-mineral threshold (`5.947`): **proportionate** as a categorical family step;
- red→blue Granite (`3.304`): **proportionate** because change remains local to eligible material;
- Smoke density (`6.951`) and neutral→cool Smoke (`4.27`): **proportionate**; density changes strength
  without inventing a medium and family changes hue without changing density;
- orange→violet Smoke (`7.757`): **proportionate** at this first breadth, visibly atmospheric rather
  than a material replacement;
- white→yellow Sun (`7.629`) and yellow→violet Sun (`14.536`): **proportionate but upper-bound**.
  Violet is deliberately strong; do not increase emitter blend strength before phone play;
- blue→magenta Bloom (`whole 0.673`, flora layer `18.763`): **proportionate and correctly local**;
- low→high resolved flora (`whole 3.699`, flora layer `37.697`): **proportionate**; the large local
  difference is legitimate game-owned cast/coverage geometry, not a Vitality tint;
- opposed composed warm/cool (`35.02`): **proportionate for an intentionally far pair**. It proves
  breadth, not a minimum distance every two worlds must meet;
- bright→dim (`16.095`) and dim→Torch (`11.94`): **proportionate as later-layer evidence** only.
  They do not authorize the current-visibility system in the material checkpoint.

The six candidate material palette families and three atmosphere families are sufficient breadth for
the first versioned native checkpoint. Exact coefficients/distances remain playtest tuning, not a
universal perceptual law. Engineering may now review the colorless world-grade-2 descriptor,
version/cache/migration boundary and native conformance vectors. Preserve the unlabeled sheet for
gestalt regression, the keyed sheet for diagnosis, similar-world relatedness, scoped identity accents,
fog invariance and the no-Illumination/no-raw-Vitality terrain rule.

#### Writing-tool progression correction — 11 August 2026

Aimee replaces Pencil with **Brush**. The current three-hand visual grammar is Rough charcoal
(4–6-cell irregular dry strokes) → Brush (2–3-cell controlled bristle-spread ink strokes) → Fountain
pen (1-cell fine ink). Ink Mixing is a direct adjacent node unavailable until Brush is owned. Brush
and Fountain pen both support Ash/open and, when separately unlocked, mixed colored inks; Rough
charcoal cannot carry liquid-ink recipes. Preserve `Hand.plain` geometry for old saves but never
present Pencil as a current tool. `writing-tool-progression-current.md` owns the exact migration and
interaction matrix.
### 11 August — 72-node combat placeholder disposition (Design)

**Recommendation accepted within a narrow boundary:**
`artifacts/combat-node-placeholder-proof-v0.1.png` is sufficient functional scaffolding for exact-ID
coverage, state/technique/capstone layering, grayscale and collision-set validation. It is not final
art and is not integration-ready as a learnable pictogram vocabulary. Hash-derived central marks may
support temporary wiring only while names, exact Effect copy and accessibility labels remain visible;
Aimee's handmade glyph system will replace their visual semantics. Do not spend further Asset time
polishing these placeholders.

### 11 August — combat-tree functional layout v0.4 disposition (Design)

**Accepted as functional layout and accessibility evidence; deliberately not an art or native-integration
approval.** Direct inspection of the 368×800 color/grayscale sheet, the five-position Large Text sheet,
the exported semantic fixture and both SHA-256-matched PNGs confirms that the corrected presentation
preserves the authoritative 24-node fan-and-fork topology for one tree. Roots, same-discipline forks,
cross-discipline alternative parents and depth-five capstones remain traceable; owned, available,
blocked, selected, technique and capstone states are redundant in geometry/mark/border rather than
color-only. The edge-clamped detail region does not cover the selected node or sever its visible
parents. DEBUG fixture, point and A/B controls are compact enough to support the route explorer
without turning the production tree into a testing dashboard.

At Large Text, replacing the impossible full-canvas overview with a depth-by-depth semantic traversal
is the correct accessibility adaptation, not a regression to a progression list: every card names its
discipline, depth, state, role, exact Effect and alternative prerequisites, while the position indicator
and selected-route summary preserve graph context. VoiceOver follows that same graph-derived order.
The ordinary-size graph remains the primary spatial presentation.

The square/hash marks remain explicitly temporary. Aimee owns the final combat-node glyphs; native
Engineering must consume `combat-tree-v2-authority.json` and generated Effect copy rather than treating
this AssetLab artifact as mechanics authority. Keep `integrationReady: false` until native graph
mechanics, purchase/respec behavior and the isolated DEBUG route explorer pass their own gates. No
further Asset iteration is requested before Engineering has a concrete native-layout integration
question.

#### Native `CombatTreeView` reconciliation — recommendations only

Read-only comparison confirms native `CombatTreeView` is a legacy semantic consumer, not merely an
older skin: it groups three branch cards, computes integer branch depth, and exposes `Learn next`.
It cannot represent the accepted fan/fork graph by restyling rows. The exact integration handoff is
now recorded in `combat-tree-true-graph-current.md` under `Native phone integration handoff — accepted
v0.4 functional layout`.

Engineering may extract the Research graph's `GeometryReader`/`ZStack`/`Canvas`, stable-ID positioned
buttons, selected-item popover→accessibility-sheet adaptation and accessible vertical-card patterns.
It must not reuse Research rank inference, three-per-row packing, 64pt/94pt geometry, required-AND
speech, keeper/stock states or Study/cost semantics. Combat positions are manifest-role owned;
alternative parents are OR; capstones add the connected-seven/five-discipline gate.

The accepted ordinary geometry is 44pt targets, x centres 70/184/298, sibling offsets −27/+27,
98pt depth spacing, connectors behind nodes, and a non-covering 352×178 detail below the graph. Large
Text uses depth-by-depth semantic graph traversal, never a scaled canvas or buy-next list. This is a
recommendations-only handoff: no native files, mechanics, handmade glyph art or new visual variant
changed. Exact installed-build phone and VoiceOver evidence remains the native acceptance gate.

#### Handmade-art ownership boundary — 11 August 2026

Aimee owns final handmade characters, buildings/stations, weapons, inventory/items, sigils and
combat-node glyph art. AssetLab work in these families is limited to deliberately basic functional
placeholders, layout/accessibility/conformance fixtures and replaceable integration wiring unless
Aimee explicitly authorizes aesthetic work. Design semantic referents and collision sets remain
useful requirements but are not assignments to generate competing pictograms. Asset's ordinary
autonomous work remains functional UI, accessibility, layout, conformance and world-color support.

### 11 August — world-grade-2 bind-adapter compatibility review (Asset)

**Disposition: schema-compatible in ordinary cases, but not yet a canonical native bind receipt.**
The adapter's material identities, five emitted material palette families, transform clamps,
none/smoke medium, neutral-Smoke density, 0–3 Flora forms, UInt64-derived species IDs, stature,
coverage, richness and resolved-color tuples all fit the frozen v1 request ranges. The material
transform stays inside the pack's accepted near/mid/far envelope; Smoke density is monotone and
separate from hue; Granite, Sun and Bloom remain scoped; Illumination and raw Vitality never enter
inherent material recoloring. No frozen Asset-pack change is required.

Four game-owned closure gates remain:

1. The contract specifies an isolated open-color seed but does not freeze scope-salt values, PRNG,
   draw order or sampling/rejection algorithm. The current Swift adapter deliberately requires an
   injected resolver for this reason. Freeze cross-language vectors before claiming byte-identical
   open-color receipts; renderer redraw must never resolve this randomness.
2. A legitimate nonempty Flora cast can still paint zero tiles when the integer growth budget is
   zero. The frozen schema requires coverage `0` iff the cast is empty, so that world currently
   fails binding. Resolve this in game generation/adapter truth—do not invent epsilon coverage or
   discard a persisted species merely to satisfy Asset schema.
3. `explicitColorsBySigilID` accepts any externally supplied `authoredMix` sRGB tuple and verifies
   eligibility, but does not prove it is the versioned conversion of that exact Sigil's persisted
   `InkRecipe`. The bind transaction must own that join/conversion so forged or stale color input
   cannot become an otherwise valid immutable receipt.
4. “Byte-identical receipt” needs a frozen canonical receipt encoding. The descriptor hash is
   canonical, but `selectedSourceByScope` is a Swift dictionary and ordinary Codable byte order is
   not itself the pack's canonical serialization contract. Pin canonical receipt bytes/hash or
   weaken the gate to semantic equality plus the already-canonical descriptor hash.

The broad open-color gamut is not a relative-diversity violation: an eligible source deliberately
left open is a meaningful authored fact and its persisted roll is part of the resolved input.
Similar worlds with identical selected source IDs/seeds still match; runtime performs no novelty
optimization. Native phone color/grayscale remains the final visual gate.

### 12 Aug 2026 — first consumable identity native-pack boundary

**Disposition: accepted as an immutable functional-placeholder conformance pack; integration-ready
only in that explicitly provisional role.** The exact remaining native consumable gap is not stable
identity transport: `ItemIconTile` already passes `catalogueID` through Storehouse, loot, equipment,
Trading Post and Recycler-facing grids. The gap is that `GeneratedCatalogueItemVisualRegistry` has
no provider, so `CatalogueItemVisualAdapter.live()` returns no pack and every item uses its SF Symbol
fallback. In addition, Apothecary recipe cards, the encounter remedy chooser and the in-world Field
Kit still bypass the shared pixel identity surface (or present names only), so installing a registry
alone would not close every consumable consumer.

The smallest frozen handoff is
`AssetLab/integration/catalogue-consumables-placeholder-v1/manifest.json`. It contains exactly the
17 live consumable IDs already accepted in the Field Kit proof, their existing 32×32 rectangle
commands, canonical command and decoded-RGBA hashes, and an exact 61-ID unsupported list. Together
those lists partition all 78 live catalogue IDs exactly once, matching native `Pack`'s fail-closed
coverage requirement. Unknown IDs, absent unidentified variants and every unsupported item retain
the native fallback rather than borrowing another identity.

Canonical manifest self-hash is
`70a6d7c6c71f93c9c8488969439aed051e35a47a3579d3c219d556c160fee4a9` under the omission rule;
the source Field Kit PNG remains hash-pinned at
`0af17200ab098258ee4e4460ece0dec11c891c7a451e467868818dd52bbf2b96`. The pack exporter and focused
pack, Field Kit and item-kit tests pass. The manifest is `integrationReady: true` only as a plainly
labelled `functionalPlaceholderConformancePack`, with `finalArt: false`; Aimee's later immutable
`catalogue-items-v1` pack remains replacement authority.

Engineering integration recommendations, without native edits in this checkpoint:

1. Generate the native registry from the manifest, translating each `#RRGGBB` rectangle to the
   runtime RGBA command while verifying every pinned hash and the exact 78-ID asset-or-unsupported
   partition.
2. Route Apothecary recipe tiles and the two carried-remedy/Field-Kit selectors through the same
   stable-ID pixel identity component. Quantity, price, readiness, target, rarity, location and
   effect remain separate UI facts and never alter the 32px commands.
3. Preserve the disclosure-neutral fallback for unidentified/absent variants. Do not manufacture a
   generic named consumable or infer identity from the catalogue's SF Symbol.
4. Treat the pack as inventory/economy identity only. It creates no map sprite; any later world-
   placed item must use a separately reviewed top-down profile. It does not alter world-color logic:
   visual similarity between worlds continues to reflect similarity in resolved underlying facts,
   never novelty optimization.

This closes the missing frozen placeholder-pack seam, not the handmade item-art milestone or native
phone acceptance. Final promotion still requires Aimee's pack plus installed-build six-across color,
literal-grayscale and same-ID cross-context evidence.

### 12 Aug 2026 — named-character compact/map placeholder pack boundary

**Disposition: immutable functional-placeholder conformance pack complete; final character art is
explicitly not claimed.** The live traveller catalogue now contains 29 stable IDs. AssetLab's
accepted full-cast evidence still owns 28 provisional authored descriptors, while Noll's separately
accepted v0.2 working placeholder remains outside that older catalogue. This checkpoint joins those
two existing sources without redesigning either: it does not turn calling, profession, recruitment,
equipment or array order into anatomy.

The frozen handoff is
`AssetLab/integration/named-character-placeholders-v1/manifest.json`, canonical self-hash
`e0bccbfa9a6637c0a0aee9e536e842b555b3b2c2866566db06d98189ce55447b`. It covers every live
TravellerID exactly once with one explicit 16×16 `compactCameo` and four 16×16 `mapTopDown`
facings, for 145 exact key/command/RGBA records. `compactCameo` is a named pack profile whose current
pixels come from the accepted compact-upright proof; Party, Library People and Library diary-author
tiles share it. The map profile remains straight top-down and may never silently substitute the
upright cameo.

The source catalogue and four accepted/working proof artifacts are SHA-pinned. The focused pack,
character-kit and character-map contract tests pass; each of the five profile/facing sets retains 29
distinct decoded rasters. The manifest is `integrationReady: true` only as a
`functionalPlaceholderConformancePack`, with `finalArt: false` and Aimee's handmade named-character
pack as replacement authority. Noll's stable live identity is included using the already reviewed
working descriptor, not promoted as finished appearance.

Native handoff gates, without Source edits here:

1. Generate one fail-closed stable-ID registry from this manifest and replace primary SF-symbol
   identity in Party and Library with `compactCameo`; action/status symbols remain allowed.
2. Route World traveller bodies through `mapTopDown` with the rules-owned facing. Do not reuse the
   cameo on the map, and do not derive body features from `TravellerDef.calling` or `icon`.
3. Preserve all command/RGBA hashes and reject unknown TravellerID/profile/facing to the existing
   fallback. Selection, health, recruitment and equipment remain independent overlays/details.
4. Keep Binder, Quill and generated-person persistence outside this pack. Their closed visual-origin
   schema remains a separate gate rather than being guessed from a named traveller.
5. Installed-phone acceptance must show the same stable person identity across map, Party and
   Library at ordinary and literal grayscale sizes. Any later handmade replacement may change pixels
   deliberately while retaining the stable keys and camera ownership.

This closes the smallest named-character transport/consumer seam. It does not reopen character
aesthetics, buildings/stations, weapons/items, sigils, combat mechanics or tutorials.

### 21 Aug 2026 — House/village/Library v0.1 visual disposition

**Disposition: rejected as production art; technical sprite/export foundation accepted only as
infrastructure.** Game Design inspected the lossless contact sheet, full 368×800 House, Library and
Commerce screens, plus individual station and room sprites. The candidate correctly replaced CSS/div
objects with deterministic integer-command RGBA outputs and a hashed manifest, but the visual result still
reads as placeholder geometry: tiny 48×32 props depend on labels for identity, districts are flat empty
fields, Binder House is a labelled box diagram, and Library collection stages are coloured rectangles inside
a shelf matrix rather than a beautiful inhabited room.

Keep the same checkpoint open. Do not commit/promote goldens, mark integration-ready or request native
integration. Correct it under `asset-production-output-contract-current.md` and
`home-village-library-asset-packet-current.md`: detail-bearing task-appropriate sprite/scene scale, recognizable
functional architecture without labels, intentional material/palette/light/value treatment, real
paper→folio→book forms, full native composites and 400% nearest-neighbour crops. Preserve the exact settled
topology and do not invent mechanics or destinations. Ordinary Chrome visual verification remains open even
though the HTTP route/MIME and standalone PNG fallback are valid.

#### 21 Aug 2026 — v0.1 second visual pass

**Disposition: still rejected as production art; do not commit, promote, golden or integrate.** Game
Design inspected the refreshed contact sheet, all three ordinary-phone composites, the five 400%
station crops, Binder House crop, Library crop and collection-growth crop. The revision is a real
structural improvement: district, house and Library now read as coherent scenes, the five opening
stations have distinct functional silhouettes, and the exported outputs are actual deterministic
RGBA sprites rather than HTML/CSS pseudo-art. Those facts satisfy the technical delivery contract,
not the aesthetic acceptance gate.

The pixels are still placeholder-quality. Large flat rectangles dominate every sprite; the Trading
Post is a shop counter, Recycler is a box-and-pipe, Storehouse is three dark rectangles, and Firepit
is a flame beneath a roof. Binder House contains little beyond a blank desk, shelves, a table and
three empty blocks, with no convincing domestic or bookbinding material detail. The Library remains
a labelled shelf matrix with sparse geometric books instead of an inviting, inhabited room whose
collections visibly grow. Labels continue to carry identity that the art itself should communicate.

The next pass must be an **aesthetic production pass**, not another geometry-density pass. Keep the
settled topology and stable output contract, but author finished pixel-art source sprites/scenes with
intentional silhouettes, texture clusters, construction materials, props, shadow and warm/cool light.
Use direct bitmap art generation and deliberate pixel cleanup where appropriate; do not treat
integer rectangle commands as the art style. Provide label-free crops as the primary review evidence,
then the ordinary 368x800 colour/grayscale composites. The Library destination must be a close-up of
one large bookcase (at most two adjoining cases only if required for native target geometry), with
recognizable paper, stitched folios, softbound and hardcover forms integrated into its five clickable
physical shelves. The wider Library area belongs only in the Binder House cutaway; do not make the
destination a second full-room scene. Binder House must read as a lived-in bookbinder's home and yard;
each opening station must remain identifiable with its label removed. Ordinary Chrome visual verification
remains open. No mechanics, destinations or navigation may be invented while correcting the art.

### 21 Aug 2026 — House/village/Library production restart boundary

**Disposition: resume only the Trading Post Tier-0 style gate; all other place art remains paused.** The
complete purpose, tier and physical-referent authority is now
`docs/village-progression-and-asset-matrix-current.md`. The active Asset packet requires one 96×80 logical
pixel, transparent, label-free `trading_post.built` sprite with 400% nearest-neighbour, literal grayscale and
368×800 Commerce placement evidence. The merchant counter, cloth awning, hanging balance, ledger, tagged
stock and coin drawer must carry the identity without text, giant iconography or exchange arrows.

Do not continue the interrupted whole-batch bitmap candidate and do not draw Recycler, opening-five, upgrade
tiers, House, Library, goldens or native assets before this one sprite receives visual acceptance. Existing
uncommitted files may remain as technical exporter infrastructure only; their previous pixels are not the
aesthetic source of truth.

#### Trading Post Tier-0 v0.1 disposition

**Rejected as the production pixel gate; composition reference retained.** The label-free merchant frontage
is materially stronger than the old placeholder work: awning, open counter, balance, ledger, tagged stock and
secured drawer read correctly in color and grayscale. However, the 96×80 output was sampled from a
1374×1145 antialiased render and contains 77 alpha values plus 4,891 distinct nontransparent RGBA values.
That is high-resolution rendered detail reduced into noise, not deliberately authored logical-pixel clusters.

Correct this same sprite at the actual 96×80 grid: binary alpha, deliberate bounded palette (target ≤64
opaque RGB colors), no gradient/antialias residue or arbitrary sampled speckle, and native/400%/grayscale
readability. Remove the chimney/domestic dormer so the commercial awning/frontage dominates in isolation.
Preserve the accepted composition and palette roles. No second building or later state begins before v0.2
passes.

#### Trading Post Tier-0 v0.2 disposition

**Logical-pixel contract passed; visual style gate still open.** V0.2 correctly moved production authority
to an exact 96×80 bitmap with binary alpha and 48 opaque colors, removed the domestic chimney/dormer, and
preserved the strong merchant frontage. The replacement roof, however, became three broad near-black
horizontal slabs. It reads like a kiosk cap or UI rectangle instead of constructed village architecture and
reintroduces the placeholder-mass problem the style gate exists to prevent. Dense background values also
weaken the balance and ledger in grayscale.

V0.3 must retain the exact logical-pixel contract and merchant composition while replacing the slab with a
low stepped/pitched slate-and-wood lean-to or shallow hipped roof: visible overhang, limited tile/value
clusters and support joinery, subordinate to the awning, with no domestic attic/chimney. Quiet the pixels
behind the balance and ledger enough for both appraiser anchors to read in grayscale. The flat Commerce Row
placement remains scale evidence only, not accepted district art.

#### Trading Post Tier-0 v0.3 disposition

**Accepted as the production visual style gate; preserve the exact logical sprite while the opening identity
set proceeds.** Game Design inspected the native 96×80 sprite, 400% nearest-neighbour crop, literal grayscale
and 368×800 Commerce placement. The shallow clustered slate roof now reads as constructed village architecture
rather than a domestic house, kiosk cap or UI slab. The open counter and ochre/cream awning remain the primary
merchant silhouette; the balance and open ledger read independently in both colour and grayscale; tagged mixed
stock remains useful secondary detail. The result is finished logical-grid pixel art rather than placeholder
web geometry or a downsampled antialiased render.

This acceptance covers `trading_post.built` only. It does not accept the flat district background as final art,
authorize later Trading Post states or promote native integration. Asset checkpoint 2 is now released exactly
as written in `village-progression-and-asset-matrix-current.md`: Recycler, Blacksmith, Storehouse and Firepit
Built/Tier-0 sprites, reviewed label-free beside the accepted Trading Post in colour and literal grayscale.
All four must retain their own functional silhouette and must not converge on a recoloured generic façade.

#### Opening Built/Tier-0 identity set v0.1 disposition

**Accepted by Game Design as the opening five production-visual identity set; native integration remains
unaccepted.** Game Design inspected the label-free five-building colour and literal-grayscale comparisons,
each 400% crop, and the Commerce/Makers/Commons 368×800 scale placements. Recycler reads as a low ordered
separation workshop rather than a forge, scrapyard or resource converter; Blacksmith is dominated by its tall
contained forge hood, hearth and anvil; Storehouse reads as a broad twin-bay warehouse rather than a shop or
house; Firepit remains a low open communal hearth with seating/kettle and no roof, shrine or damage fiction.
All four remain distinct from the accepted Trading Post and from each other in grayscale.

The exact logical sources are 96×80 RGBA with binary alpha, bounded palettes and pivot `(48,79)`. The
checkpoint manifest is `AssetLab/artifacts/opening-identities-built-v0.1/manifest.json`, SHA-256
`32bad6b6480e356d6c8483cec8f237aca95da6ef9bee2e77c07fa939f42b8245`; its four accepted candidate-source
hashes are recorded there. This accepts the sprites as **Game Design candidates only** while they remain
uncommitted/unpromoted and `integrationReady:false`. It does not accept the flat placement backgrounds as
district art, authorize native packaging, or imply later building states exist.

Asset checkpoint 3 is released exactly as written in the canonical matrix: Trading Post and Firepit
foundation/built/improved/mastered continuity rows plus independent attention overlays. The two accepted
Built sources must remain byte-identical while later forms add to the same structure and preserve their
protected anchors. Recycler, Blacksmith and Storehouse later forms remain held.
