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
AssetLab rules, and fog remains literally empty even when a golden fixture would look more balanced
with decoration.

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
labels in the review legend. Fog remains literally empty; a revealed known minimap may identify a
resource, while an unrevealed tile may not.

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
