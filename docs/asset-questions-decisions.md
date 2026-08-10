# Asset Questions and Decisions

**Owner:** Asset lead  
**Started:** 9 Aug 2026  
**Authority:** Use alongside `current-design-index.md`. Settled asset direction and lead reviews
remain in `asset-system-proposal.md`; this file is the short operational ledger for active work.

## Labels

- **SETTLED** — approved by Aimee or inherited from a current authoritative design document.
- **PLACEHOLDER** — the asset lead's reversible working choice, made to keep tools progressing.
- **RECOMMENDATION** — advice from a lead, not an approved decision.
- **OPEN** — needs Aimee or the relevant lead before it becomes final.
- **RETIRED** — previously considered and no longer current.

## Settled

### AQD-001 — Ownership boundary

**Status:** SETTLED · 8 Aug 2026

- Asset tools and generators live in the isolated `AssetLab/` directory.
- The asset lead does not modify game code or Xcode integration.
- Engineering owns any eventual adapter and integration.

### AQD-002 — Primary environment cameras

**Status:** SETTLED · 8 Aug 2026

- The village/base is a 2D side view.
- Explorable generated worlds are top-down.
- This does not settle native resolutions or combat projection.

### AQD-003 — Splash disclosure boundary

**Status:** SETTLED · 9 Aug 2026

- Opening transitions are framed/page-like.
- They do not reveal generated surprises.
- They do not depict the cult, perpetrator, Tam, or a canonical player face.
- Reality-reset imagery remains off-limits until that system is settled.

### AQD-004 — Anchoring visual fiction

**Status:** SETTLED · 9 Aug 2026

- Born-anchored, natural-point, and placed Anchor Frame routes yield the same permanent realm.
- Dormancy preserves it.
- Tether imagery is retired.
- Unanchored departure and anchored continuity require different exit treatment.

## Active placeholders

### AQD-P00 — Dynamic coverage audit boundary

**Status:** PLACEHOLDER · 9 Aug 2026

The operational coverage inventory is `asset-dynamic-coverage-audit.md`. It treats live code as the
authority for implemented render states and current indexed documents as authority for approved
near-future profiles. Authored lore identities may receive procedural material/palette/state
variation, but are not generated from unconstrained parts.

### AQD-P01 — Native sprite resolutions

**Status:** PLACEHOLDER

- World creature/flora sprites: 16×16.
- Fight/detail sprites: 48×48.
- Top-down terrain tiles: 16×16.
- Rationale: smallest useful proof matching the current phone-map density.
- Revisit after native-device contact-sheet review; none are final production sizes.

### AQD-P02 — Creature combat projection

**Status:** PLACEHOLDER

- Shallow side view for the fight profile.
- Rationale: ranks, reach, front/back protection, and armament silhouette need horizontal space.

### AQD-P03 — Terrain transition model

**Status:** PLACEHOLDER

- Four-neighbour N/E/S/W bitmask with 16 variants per transitioned family.
- Rationale: matches orthogonal movement and is inspectable in contact sheets.
- Corners may later need an additional overlay grammar after device review.

### AQD-P04 — Existing identity remaster policy

**Status:** PLACEHOLDER

- Species identity is reproducible from immutable version tuple + descriptor.
- Existing identities remain on their recorded tuple; no silent visual remaster.
- A future approved migration/remaster flow may opt identities into a newer tuple.

### AQD-P05 — Source/export color handling

**Status:** PLACEHOLDER

- Authoring uses controlled HSL-derived ramps in the proof.
- Browser export is 8-bit RGBA PNG; manifests hash decoded RGBA bytes.
- Production source art is expected to move to authored indexed ramps before integration.

## Lead recommendations awaiting disposition

### AQD-R01 — Species versus specimen ownership

**Status:** RECOMMENDATION · Design Lead · 9 Aug 2026

- Species seed owns silhouette, anatomy, covering, armament, and core palette.
- Specimen seed owns only bounded markings, pose, proportions, and wear that cannot imply different
  mechanics.

**Working disposition:** Adopted in AssetLab schema v3; awaiting Aimee's final approval.

### AQD-R02 — Disclosure-neutral living art

**Status:** RECOMMENDATION · Design Lead · 9 Aug 2026

- Visible anatomy, translucency, and warning coloration may be honest.
- Exact sensory allocation, functional defence labels, toxicity, triggers, effects, and weaknesses
  remain behind analysis/disclosure policy.
- Detectable translucent creatures need a disclosure-neutral readability aid.

**Working disposition:** Direct sensory/defence badges removed. Readability aid remains open.

### AQD-R03 — Flora and terrain proof boundary

**Status:** RECOMMENDATION · Design Lead · 9 Aug 2026

- Flora pixels remain stable; placement supplies variation.
- Terrain derives from resolved tile facts, adjacency, and reveal state.
- Fog contains one invariant concealment fill and literally nothing informative or
  descriptor-dependent.
- Minimap communicates terrain/growth class, not individual plants.
- Validate integrated color and grayscale phone-size sheets before broadening.

**Working disposition:** Design review passed the semantic read. Follow-up corrections now derive the
route from passability, layer cracks last, asymmetrize the small woody form, turn the route along the
deep-water contour, and include portal/site/party symbol collisions. Golden-fixture promotion is
pending final visual confirmation.

### AQD-R04 — First combat-stage proof

**Status:** RECOMMENDATION · Design Lead · 9 Aug 2026

- Use a static portrait-phone sheet before animation.
- Prove worst-case 5 party versus 3 foes and a 2-versus-1 case.
- Include front/back, close/mid/far, selected, legal, cannot-reach, and protected reads.
- Include an ordinary creature, unknown creature, and triggered hostile flora against a restrained
  world-derived background, in color and grayscale.

**Working disposition:** Accepted as the next visual proof. Current proof uses a 216×336 stage,
48px sprites, five vertical lanes, shallow side projection, and independent 44×44 hit ownership.
All metrics remain placeholders until the sheet is reviewed.

**Review correction:** Column origins are now 4/48/120/164, giving every possible rank/lane
position a non-overlapping 44×44 ownership rectangle. The fixture deliberately combines multiple
compatible states; cannot-reach is target-side; the unknown identity mark remains unobscured; and
selected reach is drawn actor-relative with shape grammar.

**Pre-golden correction:** Legal and cannot-reach are now mutually exclusive and schema-fixture
validation rejects the contradiction. The unknown target carries unknown+cannot-reach+protected;
legal+protected is exercised separately. Protection uses an independent shield cap above other
selection geometry. The 2v1 selection now exercises far reach, alongside the 5v3 close example.

### AQD-R05 — World Lab golden proof

**Status:** RECOMMENDATION ACCEPTED · Design Lead · 9 Aug 2026

The corrected integrated World Lab sheet is accepted as the current golden proof boundary. This
does not authorize game integration or make the placeholder native sizes permanent.

### AQD-R06 — Static combat-stage golden proof

**Status:** RECOMMENDATION ACCEPTED · Design Lead · 9 Aug 2026

Combat stage v0.3 is accepted for ownership, ranks, close/mid/far grammar, independent protection,
compatible overlap states, disclosure, shared 5v3/2v1 camera, and grayscale. Golden promotion
includes the fixture validator and exhaustive 20-position pairwise hit-ownership test. Animation,
health/status/action UI remain outside this accepted boundary.

### AQD-R07 — Static player-facing combat UI proof

**Status:** RECOMMENDATION · Design Lead · 9 Aug 2026

Next proof covers HP and armour; burn, poison, dazzle, and Ground; current actor, action, and target
including a gambit turn; a passed-out ally; color, grayscale, large text, and VoiceOver ordering.
Animation and broader health/status/action behavior remain out of scope.

**Working disposition:** Implemented as a semantic DOM proof on the accepted stage. Placeholder
VoiceOver order is encounter, current actor, action, target, party, foes. The grayscale duplicate is
hidden from assistive technology; every actor control is at least 44px; large text reflows columns.

**Audit refinement:** Current actor and selected target are now redundantly marked on their roster
controls and announced through `aria-current` / pressed state. Passed-out actors remain inspectable
but announce unavailable. Condition names are normalized in speech and text. Browser inspection
confirmed 71–90px target heights, no large-text card overflow, and no runtime warnings.

## Open questions for Aimee

### AQD-Q01 — Overall pixel-art lineage

**Status:** OPEN · nonblocking

Which games, artists, moods, or palettes are positive references? Which should be explicitly
avoided? This can remain open while structural generators are tested.

### AQD-Q02 — Final native resolutions

**Status:** OPEN · nonblocking until device sheets exist

Do 16×16 world and 48×48 fight/detail sprites provide enough identity at the game's actual phone
viewport, or should one/both profiles move up a size?

### AQD-Q03 — Character portrait scope

**Status:** OPEN · later milestone

Should named travellers receive meeting/diary/roster portraits in addition to world and fight
sprites? Design recommends yes eventually, but not before the world/flora proof is stable.

### AQD-Q04 — Village traversal/composition

**Status:** OPEN · later milestone

Should the side-view village be one horizontally scrolling scene, several station scenes, or one
fixed composition that grows denser? Asset lead currently leans toward a scrollable village with
authored building plots.

### AQD-Q05 — Existing-identity visual upgrades

**Status:** OPEN · integration-era decision

Are encountered identities visually frozen forever, or may an approved art remaster migrate them?
AQD-P04 freezes them by default so progress is not blocked.

## Retired

### AQD-X01 — Shared three-quarter projection for base and world

**Status:** RETIRED · 8 Aug 2026

Superseded by the settled side-view village / top-down generated-world split.

### AQD-X02 — Tether-based anchoring imagery

**Status:** RETIRED · 9 Aug 2026

Superseded by the current anchoring system. Do not use tether visual language.

## Change log

- **9 Aug 2026:** Ledger created from the current asset proposal, design index, and recorded lead
  reviews. Existing placeholders are now explicit rather than implicit in tool code.
- **9 Aug 2026:** Recorded the integrated World Lab review, its five follow-up corrections, and the
  recommended combat-stage proof boundary.
- **9 Aug 2026:** Full AssetLab browser/runtime audit fixed a false three-change Golden Review report
  after combat promotion, added visible semantic-contract cards, strengthened combat-UI state
  semantics, and sanitized author-controlled export filenames while retaining original logical IDs
  in manifests.
# 9 Aug 2026 — exact live-descriptor adapter milestone

- **Placeholder decision (superseded by review):** AssetLab authoring descriptors remain a deliberately richer, versioned workspace format. Export manifest v3 is the proposed integration boundary and carries explicit `identityKind`, `authoringDescriptor`, exact `gameIdentity`, visual-only `renderHints`, structured `adapterDiagnostics`, and `pipelineVersions` separately. Creature and flora shapes are paired through schema conditionals.
- **Decision:** Creature body topology is a visual render hint, not a live mechanical identity field.
- **Decision:** Creature emanation is now authored as a linked light/heat/caustic allocation totaling 100. Version-3 dominant-kind descriptors migrate to a deterministic 70/15/15 triangle and emit a structured `assumed-emanation-allocation` warning because that deterministic migration remains lossy. The renderer may use the dominant component for its restrained glow hue, but export retains the complete allocation.
- **Decision:** A creature may have no defence branch; this exports as `null` rather than inventing a mechanic.
- **Decision:** Finish, sensory allocation, CMY coloration, armament mix, and flora tissue mix are normalized at the adapter boundary. Ordinary authored sprites must not disclose exact hidden allocations merely because the values exist in the manifest.
- **Verification:** adapter/unit/combat/UI/regression tests pass; all 36 accepted golden pixel fixtures remain unchanged.
- **Open engineering confirmation:** confirm the final live enum spellings and numeric units before any game integration. No integration is authorized or implemented here.

## Design-review disposition

- Adopted `gameIdentity` in place of ambiguous `liveIdentity`, explicit `identityKind`, paired creature/flora schema conditionals, structured adapter diagnostics, and `pipelineVersions` in manifest v3.
- Adopted a warning for assumed v3 emanation allocation; deterministic migration is not treated as lossless.
- The 1–4 flora-species world-set generator and stability/assignment tests are green. Its visual integrated-map presentation remains in progress and is not golden yet.

# 9 Aug 2026 — multi-species integrated-map review candidate

- World Lab now exposes a 1–4 flora-species control. The primary authored species remains first; deterministic companion identities fill the bounded set.
- Each flora placement resolves to a stable species descriptor. Flora is excluded from route, portal, site, and party collision cells in this proof so identity silhouettes are not accidentally obscured; content-collision coverage remains a separate upcoming fixture.
- The ordinary map displays species identity, while the minimap continues to encode only legitimate revealed growth class. It does not assign resource-like dots or species colors.
- Browser verification passed at four and two species; the four-species fixture reports five placements and its color/grayscale canvases update together. Automated 1–4 identity, assignment, bounds, and determinism tests pass; golden regression remains unchanged.
- Review artifact: `AssetLab/artifacts/multi-species-map-proof-v0.1.jpg`. This is a review candidate, not golden acceptance.

# 9 Aug 2026 — settled map-view flora camera correction

- **Settled by Aimee:** every explorable-map asset, including flora, uses a straight top-down view. The earlier 16px flora profile read as a side elevation and is superseded.
- All flora profiles are now top-down. The 16×16 map grammar and 48×48 neutral/hostile grammars share overhead crowns, rosettes, mats, radial tufts, clusters and central mass. Hostile state changes pose through outward radial activation without changing camera.
- This intentionally changes flora world-profile pixels; prior flora world fixtures must not be promoted unchanged merely to preserve hashes.

## Overhead evidence and tile-content progress

- Lossless workspace evidence is now exported directly from canvas bytes through a local AssetLab-only endpoint: `AssetLab/artifacts/flora-overhead-proof-v0.2.png` (384×168 RGBA PNG). It contains the same species at 16px world, 48px neutral and 48px triggered overhead profiles in color and grayscale, plus the live map proving terrain/route/marker ownership.
- The endpoint accepts only a safe PNG basename, validates the PNG signature, caps payloads at 5 MB and writes only into `AssetLab/artifacts/`.
- The ten tile-content families now have distinct ordinary-map and grayscale grammar, disclosure-gated minimap symbols, distinct entry/exit portals, and a mud/growth/rubble/chasm edge collision strip. Chasm carries no actionable content or route. Review artifact: `AssetLab/artifacts/tile-content-collision-proof-v0.1.png`.
- These are review candidates. The nine camera-correction hashes remain intentionally unpromoted.

# 9 Aug 2026 — promotion and authored-place milestone

- Design accepted tile-content v0.2 after the traveller silhouette correction. The regression baseline now covers 62 fixtures: the prior 36 plus all ten world symbols, disclosure-gated minimap results, both portal directions and four terrain/content collision tiles. Regression is 0/62.
- Design accepted the overhead flora evidence and the exact nine camera corrections were promoted; they are included in the same 0/62 result.
- Place Lab now inventories all 18 current stations as side-view village architecture and all 15 current/additional sites as top-down world assets. Identity is authored by ID/archetype/profile; procedural adaptation is limited to palette, tier, damage/wear and lifecycle state.
- First visual place pass was self-rejected because it read as generic houses/squares. v0.3 adds functional station silhouettes (chimney, spring, hearth, tower, awning, shrine and related structures), explicit top-down site forms (camp, causeway, vent, warren, cairn, seam and related profiles), warm/cold or warm/ash identity-persistence pairs, and station/site lifecycle rows.
- Design's v0.3 review accepted the camera/adaptation boundary and requested a smaller semantic
  correction rather than a redesign. v0.4 distinguishes the tower and store/forge/workshop station
  groups through functional mass and negative space, includes an unlabeled native-grayscale
  collision row, and exercises those stations across tier/damage states.
- Site search and exhaustion now physically alter the authored site center. A guarded site leaves
  site geometry unchanged and renders its guard as a separate visible content occupant; no generic
  searched corner, exhaustion bars, guarded stripe, or hidden guard disclosure remains.
- Corrected review candidate: `AssetLab/artifacts/place-identity-adaptation-proof-v0.4.png`
  (640×690 lossless RGBA PNG). Design's direct visual review accepted the correction. The stale
  public `siteCommands` state badges were removed so no future consumer can reintroduce the rejected
  searched corner, exhaustion bars, or guarded stripe. Guarded-state geometry and no-full-width-bar
  tests are explicit. The collision group now has a built/tier-3/damaged matrix and pairwise state
  assertions. Automated tests pass and the accepted regression remains 0/62.

# 9 Aug 2026 — character identity contract audit begins

- The live catalogue contains 28 named travellers. Their names, callings, authored order, campaign
  phase, worldwork and combat lean exist, but there is no canonical appearance descriptor in game
  data. AssetLab therefore treats named traveller appearance as authored art identity, not something
  inferred from stats or calling at runtime.
- The Binder remains a distinct player identity and must not acquire a canonical face from a splash
  or generator default. Generated companions use a persistent seed and bounded visual identity; they
  do not inherit named-cast silhouettes.
- Character identity is stable across a straight top-down 16×16 world profile and the accepted
  side-biased 48×48 combat profile. Palette is adaptation. Weapon, armour, rank/pose and passed-out
  state are overlays or render state, never a reroll of the person's anatomy.
- Added an isolated `character-kit` contract covering all 28 names, both camera profiles, palette
  identity stability, bounds, visible gear overlays, color-independent passed-out pose and generated
  seed determinism. This is infrastructure only; no visual character proof is claimed yet.
- Character proof v0.1 was self-rejected because the stable identities still collapsed into generic
  people with interior color bits. v0.2 moves identity-owning features into silhouette space and adds
  pairwise silhouette uniqueness assertions across all 28 names in both profiles. Review still needs
  to decide whether the bounded authored feature grammar reads as people rather than arbitrary coded
  appendages; mechanical calling/stat values remain prohibited as automatic anatomy inputs.
- Review candidate: `AssetLab/artifacts/character-identity-proof-v0.2.png` (640×620 RGBA PNG).

## Character audit gap — generated-person persistence

- Current design requires a generated person's name/pronouns, voice, visual descriptor, want,
  first-met level and three-branch build plan to persist from first encounter through world recurrence,
  Tavern visits, refusal and recruitment. The inspected live model currently exposes named-traveller
  identity and ordinary `CompanionState`, but no implemented generated-person visual descriptor or
  durable asset identity key was found.
- **Placeholder decision:** AssetLab uses `generatedSeed` only as proof infrastructure. Integration
  must receive a persisted generated-person identity ID plus a versioned visual descriptor; it must
  never derive appearance from array position, current world seed, Tavern refresh, combat build,
  want or calling. An old save lacking the descriptor needs a deterministic migration diagnostic,
  not a silent reroll.
- Animal companions are a separate authored/generated creature boundary and must never enter the
  human Character Lab generator merely because both can occupy party slots.

## Character proof v0.3 correction disposition

- Replaced numeric identity marks with named authored axes: build, hair/head treatment, garment,
  carried personal object, asymmetry and personal palette. These are authored descriptors and are
  never inferred from calling, stats, build plan, worldwork, rank or current equipment.
- Personal skin/clothing/accent colors now belong to identity. Environmental grade is demonstrated
  as surrounding world light/background and does not rewrite personal palette.
- Generated people deterministically select the same bounded structural axes from their persisted
  identity seed. Tests require meaningful multi-axis variation between sample seeds; named-person
  combinations remain authored catalogue entries.
- The Binder now uses a separate explicitly noncanonical template rather than rendering Tovin.
  Binder body, face treatment and purple palette remain placeholders for the future customization
  contract. Tovin is exclusively a named traveller identity.
- Representative overlays now cover close blade, mid melee spear, far bow, light protection and heavy
  protection. Passed-out sprites use an explicit prone-person grammar instead of rotating standing
  sprites into object-like piles.
- Review artifact: `AssetLab/artifacts/character-identity-proof-v0.3.png` (640×620 RGBA PNG).
  Full tests pass and accepted regression remains 0/62.

## Character proof v0.4 final semantic correction

- Corrected the settled reach vocabulary: ordinary Bowyer bow is **far**; melee spear/polearm is
  **mid**; blade is **close**. A future far spear must be a visibly distinct throwing set rather than
  reusing the melee-spear sprite. Vocabulary assertions now lock `blade→close`, `spear→mid`, and
  `bow→far`.
- Prone sprites now recompose the same authored build, hair, garment, carry and asymmetry instead of
  using a shared downed body. All 28 named combat-prone silhouettes are pairwise distinct, and a
  passed-out gear fixture proves equipment remains visible.
- Unknown named IDs now fail with a structured identity error instead of silently entering the
  generated-person path. Generated samples 0–511 are collision-free and reserve exact named
  descriptor combinations.
- Warm/cold environment grades now exercise bounded pixel-color transforms while preserving the
  personal palette identity and identical geometry.
- Corrected review artifact: `AssetLab/artifacts/character-identity-proof-v0.4.png` (640×620 RGBA).
  Full tests pass; accepted golden regression remains 0/62.

## Character golden promotion and full-cast expansion

- Design and Engineering accepted Character Lab v0.4 for visual golden promotion. The canonical
  character boundary adds 37 representative pixel fixtures: six named people across world/combat/
  prone, four generated people across world/combat, separate Binder world/combat/prone, warm/cold
  grade samples, all five representative gear overlays and a gear-preserving prone sample.
- Golden regression is now 0/99. The promotion does not add native integration authorization;
  persisted identity oneOf, schema versions/hashes, eight live equipment-slot mapping and Swift
  round trips remain later Engineering gates.
- Full-cast v0.1 renders all 28 named travellers in authored order with their 16×16 straight
  top-down world and 48×48 side-biased combat profiles in color and grayscale. It labels the
  authored hair/garment axes so collisions can be reviewed without treating different hashes as
  sufficient proof.
- Review candidate: `AssetLab/artifacts/full-cast-descriptor-proof-v0.1.png` (720×610 RGBA PNG).
  This is catalogue evidence, not yet a second golden promotion.

### Full-cast v0.2 collision correction

- Design accepted the catalogue/camera direction but identified four grayscale near-pairs. One large
  authored axis changed for the non-golden member of each pair: Orsa uses loose hair, Bracken a hood,
  Grimmond a mantle and Auber a robe. Halloway and the accepted v0.4 representative fixtures remain
  unchanged.
- Added an unlabeled native 16×16 grayscale collision strip containing Corrin, Bracken, Nessa,
  Auber, Halloway, Orsa, Vance, Grimmond, Talin and Dagg beside the accepted traveller and wild-drop
  tile-content grammar. Names/callings are separated into a key so labels cannot prime recognition.
- All 28 standing and prone pairwise assertions remain green; accepted regression stays 0/99.
- Corrected review candidate: `AssetLab/artifacts/full-cast-descriptor-proof-v0.2.png` (720×720 RGBA).
- Design accepted v0.2 for full-cast visual golden expansion. All 28 named world/combat/prone
  profiles are now included in the regression baseline; regression is 0/165. These hashes prevent
  accidental rerolls but do not turn provisional authored art v1 into immutable character canon.

## Resource Node milestone v0.1

- AssetLab now inventories all 23 live resource families. Each has an authored family ID/source/
  profile cue; mineral/exotic/energy nodes inherit bounded local substrate grading while organic
  nodes inherit flora grading. Remaining and exhausted states are physically different, unknown
  families fail, and fog/unrevealed or undiscovered minimaps contain no resource symbol.
- The integrated proof includes all families in color/grayscale/exhausted states, quartz across
  soil/ice/ash, fibre over two actual flora species, known/hidden/exhausted minimap states, and a
  native grayscale collision strip with ore/fibre/mote/drop/traveller/route/chasm. Chasm contains
  no resource node.
- Automated tests cover 23/23 catalogue uniqueness, bounds, environmental silhouette persistence,
  organic-versus-mineral inheritance, physical exhaustion and disclosure gating. Full suite passes;
  accepted regression remains 0/99.
- **Self-audit:** v0.1 is not golden. Several same-profile mineral families converge in grayscale;
  the two flora-context examples are
  overly covered by the node cue. Review should settle which distinctions must be visible on-map
  versus inventory/inspection before expanding decorative detail.
- Follow-up presentation now uses one common stone substrate for every non-organic family in the
  catalogue grid. Soil/ice/ash adaptation is isolated in the inheritance row, so environmental
  variation no longer confounds direct family comparison.
- Review candidate: `AssetLab/artifacts/resource-node-proof-v0.1.png` (720×720 RGBA PNG).

### Resource v0.2 acquisition and physical-state correction

- The catalogue now distinguishes acquisition kind from resource family. Mote is `realityCurrency`
  and has no harvest-node or minimap renderer. Raw Essence is `wildDrop`; collection removes it rather
  than leaving an exhausted node. Rift-glass remains an unstable-substrate node.
- Actual flora inheritance is restricted to the six live `FloraRules` links: Timber, Fibre, Pulp,
  Toxin, Spore and Reagent. All six use the same disclosure-neutral harvest cue over the resolved
  accepted flora species, so exact yield and toxicity are not leaked. Resin uses an authored exudate
  deposit and Ichor a pool/deposit; neither falsely asserts a flora source.
- The map obligation is profile/state/source readability, not encoding all 23 exact names. Minerals
  use the nine accepted physical profiles. Families sharing a nodule, seam or crystal profile may
  share a silhouette; the exact family name/properties live in disclosed interaction and inventory.
- Exhaustion is profile-derived: worked cavities/fragments for mineral masses, clipped/stump grammar
  for flora, residue for exudate/pool, disappearance for wild drops, and no state for Mote. The
  universal bottom-bar grammar is removed.
- Corrected proof includes identical-substrate profile comparisons, isolated quartz substrate
  inheritance, two real flora species with a neutral harvest cue, generic disclosed/spent minimap,
  native collision evidence, and an adjacent exact-name plus disabled VoiceOver example.
- Review artifact: `AssetLab/artifacts/resource-node-proof-v0.2.png` (720×720 RGBA PNG). Full tests
  pass; accepted regression remains 0/165.

### Resource v0.3 golden safeguards

- Removed the all-acquisition `resourceNodeCommands` alias. World and minimap rendering now resolve
  the exact resource ID and its acquisition kind; unknown IDs fail, and Mote/Raw Essence cannot be
  silently routed through the default node path.
- Raw Essence delegates its world appearance to the already accepted `tileContent.wildDrop`
  renderer. Rift-glass rejects ordinary substrate context and is proved on rubble/unstable ground.
- Exhausted flora keeps the exact accepted flora species sprite and removes only the neutral harvest
  cue. No generic replacement stump or invented species-specific harvested pose is introduced.
- The Quartz disclosure example is an enabled inspect action. Its reachable accessible name is
  generated by the same acquisition/profile/state resolver and browser-verified after activation.
- Corrected artifact: `AssetLab/artifacts/resource-node-proof-v0.3.png` (720×720 RGBA). Full tests
  pass. Design and Engineering accepted v0.3 for AssetLab visual-boundary promotion; 31 representative
  acquisition/profile/state/disclosure fixtures are now golden and regression is 0/196.

## Splash lifecycle proof v0.1

- Added a separate AssetLab lifecycle-splash renderer and proof page for entry, portal departure,
  waystone departure, defeat, collapse, abandon and anchored continuity. All use a framed/page-like
  composition and retain the same world identity rather than inventing a second landscape camera.
- Entry composition uses only legitimate known view state. Discovered-site identity requires an
  explicit known site profile; an apex may add only a generic disclosed location mark, never an
  undiscovered creature identity. Tests reject concealed site/apex leakage.
- Anchored continuity requires `anchored: true`, preserves the world, and contains no tether grammar.
  Defeat remains abstract and contains no canonical player face. Cult, perpetrator and Tam imagery
  are outside the renderer vocabulary.
- **Placeholder decision:** abandon uses a deliberately restrained departure treatment and is
  marked provisional until abandon/reset fiction is settled. It must not imply destruction or a
  reality reset merely to make the card more dramatic.
- Review candidate: `AssetLab/artifacts/splash-lifecycle-proof-v0.1.png`. The full AssetLab suite
  passes; splash fixtures are not golden pending visual/contract review.

### Splash lifecycle v0.2 correction

- Split `transition` from `continuity`: entry/portal/Waystone/defeat/collapse are transitions, while
  anchored is an independent continuity dimension. The proof demonstrates an anchored portal exit;
  collapsed plus anchored continuity is rejected as contradictory.
- Defeat now uses an abstract upward extraction/loss-of-agency mark and no prone or canonical body.
  Waystone is a tiny carried edge instrument, not an upright doorway or persistent map site.
- Abandon is removed from the promotable transition set. A reserved card is available only through
  explicit `allowNoncanonical` proof opt-in and is labelled noncanonical in both color and grayscale.
- The anchored mark is a stable bookmark/book-edge tab outside the world scene: no tether, shore or
  altered realm geometry. Automated prefix comparisons prove identical world geometry for every
  intact transition and both continuity modes; only actual collapse changes it.
- Removed proof-world defaults and permissive fallbacks from the public request. World and disclosure
  DTOs accept exact fields and enumerated values; site disclosure accepts only the six current site
  profiles, and apex identity is not part of the renderer input at all.
- Corrected review artifact: `AssetLab/artifacts/splash-lifecycle-proof-v0.2.png`. Full tests pass and
  resource golden regression remains 0/196; splash awaits final review before fixture promotion.

### Splash lifecycle v0.3 golden closure

- Corrected the final continuity rule: collapse and anchored continuity may coexist because collapse
  ends the run while the anchored realm snapshot persists. The combined request is now an explicit
  passing fixture rather than a contradiction.
- A disclosed site no longer produces a generic box. The compositor delegates the validated current
  site ID to the accepted authored site renderer; Signal Cairn and Salt Pan are pixel-distinct in an
  automated identity test. Apex remains a separate location-only disclosure mark.
- Top-level request fields and the noncanonical opt-in are strict. Abandon remains absent from the
  promotable transition array, regression fixtures and any proposed player lifecycle vocabulary.
- Final artifact: `AssetLab/artifacts/splash-lifecycle-proof-v0.3.png`. Seven golden fixtures cover
  the five settled transitions, independent anchored continuity and the gated disclosed-entry
  variant. Full suite passes; regression is 0/203.

## Native top-down map slice handoff v1

- Immediate integration contract: `docs/top-down-map-asset-integration-current.md`. Generated
  conformance pack: `AssetLab/integration/map-slice-v1/manifest.json`; schema:
  `AssetLab/schemas/map-slice-manifest.schema.json`.
- The pack contains 198 individual 16×16 sRGB RGBA PNG conformance fixtures: all 12 ground raw
  values, 16 adjacency masks for each edge-bearing family, elevation 1–3 and crumbled evidence for
  every ground, four overhead flora examples, accepted content examples, route/crack and literal
  transparent fog. Every output says `role: conformanceFixture` and has separate compressed-file
  and decoded-RGBA SHA-256 hashes. These are not an exhaustive runtime atlas.
- Exact native order follows Design: terrain → flora → crack/warning → content → route/action →
  party/selection. Visibility is not a drawable eraser: unrevealed tiles short-circuit before any
  ordinary tile layer. The former always-visible portal/writing/apex minimap promise is superseded:
  all POIs are now game-owned fog/discovery-gated by default, with only explicit invested knowledge
  effects permitted to reveal them early (`minimap-disclosure-current.md`).
- Added the closed Swift flora adapter `swiftFloraToDescriptor`: `Tile.flora` resolves an exact
  `WorldRun.flora` ID; logical identity and uint32 species seed derive from persisted UInt64 values;
  every trait field, unit, clamp, normalization, enum spelling and legacy behavior is documented.
  Two Swift-shaped fixtures carry expected rectangle and decoded-pixel hashes.
- **Engineering-owned decision still required and explicitly blocked from substitution:** native
  code must define/freeze/test the `terrainSeedUInt32` derivation from persisted `mapSeed`, tile
  coordinate and immutable pipeline versions. AssetLab requires the already-derived uint32; proof
  seed `404` is marked runtime-unsafe and cannot be used as fallback.
- **Uncovered for this slice:** an accepted straight-top-down party/character sprite. Mara was
  removed from the pack because the current Character Lab world figure reads upright. Engineering
  should retain the existing party overlay until a top-down character milestone is reviewed.
- That initial export hash is retained as history; the current hash is recorded under the v1.1
  closure below.
  Full AssetLab suite passes and golden regression remains 0/203.

### Top-down map handoff v1.1 closure

- Terrain placement identity is now named `terrainSeedUInt32` throughout the renderer and exporter.
  The old `speciesSeed` spelling is accepted only as a deprecated proof-page alias and is deleted by
  normalization, preventing native code from confusing flora identity with terrain placement.
- World-grade adapter v1 and its three exact reading/grade vectors are frozen in the immutable
  pipeline tuple. All 12 grounds now have four disclosure-neutral feature-template families; a
  forbidden-semantic test rejects names implying cracks, roots, reeds, tracks, embers, dunes, shelves,
  cold or other unowned facts.
- The manifest schema is recursively closed and validated with AJV in strict mode. Negative mutations
  inside pipeline versions, flora mapping, nested Swift flora vectors, world-grade vectors and output
  metadata all fail. The earlier hand-written partial validator is removed.
- Current pack: 198 conformance PNGs; manifest hash
  `f776ae97f252f462570014ca81d06df40e5a6de82aaa06c53671310e1912c28d`.
  Pipeline tuple: contract 1, terrain 1, flora 1, tile-content 1, world-grade
  `world-grade-1.0.0`, grammar `map-slice-1.1.0`, compositor `rect-compositor-0.2.0`, profile
  `top-down-map-16px-1.0.0`. Engineering accepted this as the integration-ready conformance handoff.
- Bounded wording correction: fog is one invariant compositor fill `#17171a`, with no informative
  pixels; the transparent output is only a conformance sentinel. Cardinal adjacency bits are set
  only for in-bounds neighbors whose exact `GroundType` raw value equals the center. Renderer pixels
  and the frozen tuple did not change; the former `05e23c…07a46` hash is superseded.

### Uniform minimap disclosure closure

- The machine contract now states that every POI family is game-owned and requires legitimate
  reveal/discovery state. Portal, writing and apex have no type exceptions; the entrance portal is
  visible because its starting tile is revealed.
- AssetLab may render future bounded knowledge only when the game explicitly supplies it. It never
  infers discovery from POI type, world descriptors or asset identity. Literal fog remains an early
  ordinary-tile composition short-circuit and is separate from the minimap overlay decision.
- The closed schema rejects unknown minimap exception fields, tile-content tests cover both hidden
  and undiscovered inputs, and the regenerated manifest contains no `always-visible` promise.
- Full AssetLab tests pass; regression is 0/203.

## App Launch proof v0.1

- Added a separate static App Launch Lab at `AssetLab/launch.html`; it is not a world lifecycle
  splash. It uses a phone-safe 390×844 page/Atlas frame in light and dark, with `Bookbinder` and the
  restrained `Opening the Atlas…` copy.
- The same tokens and composition are intended for the constrained iOS LaunchScreen surface and the
  first in-app loading frame, avoiding a cold-start visual jump. There is no authored Binder face,
  world/site/apex content, animation dependency or fake progress bar.
- Layout tokens are in `AssetLab/src/launch-kit.js`; proof artifact is
  `AssetLab/artifacts/app-launch-proof-v0.1.png`. Browser navigation/export has no console errors and
  the full AssetLab suite passes. Visual review is pending before promotion.

### App Launch proof v0.2 correction

- Replaced the ambiguous central I/sword-like mark with paired page masses, mirrored outer edges, a
  narrow spine and restrained asymmetric torn notches. Launch copy and lifecycle meaning are
  unchanged.
- Added assertions that the complete framed composition respects `safeTop`/`safeBottom` and that
  light and dark use identical geometry.
- Lossless proof: `AssetLab/artifacts/app-launch-proof-v0.2.png`. It contains light/dark color and
  literal grayscale evidence rendered at native 390×844 and nearest-neighbour 2×. Browser console
  is clean. Design accepted v0.2 for visual golden promotion; v0.1 is retired as current evidence.
- Light and dark launch command rasters are now protected by the golden regression catalogue. Full
  AssetLab tests pass; regression is 0/205.

## Straight-top-down map characters v0.1 — in progress

- **Placeholder decision:** preserve the accepted 16×16 compact-upright `world` renderer as
  historical/proof-only and add an explicit `mapTopDown` profile. Only `mapTopDown` may become the
  integration-facing explorable-map character camera; this avoids silently changing v0.4 evidence.
- The first renderer recomposes descriptor-owned build, hair, garment, carry, asymmetry and personal
  palette as a foreshortened overhead human footprint. It has a closed north/east/south/west facing
  axis; environment grade changes color but never geometry. Calling and stats remain absent.
- First automated boundary covers Mara, Halloway, Isolde, Tovin, Wren and Ashe as pairwise-distinct
  overhead silhouettes, deterministic generated people 41–44, all four facings, bounds and unknown
  profile/facing rejection. Full suite passes; regression remains 0/205.
- **Not promoted:** a native color/grayscale collision sheet still must prove these figures beside
  route, drop, resource node, overhead flora, hostile flora and generic traveller, with current and
  selection overlays remaining independently owned. Binder remains explicitly noncanonical.

### Integrated mapTopDown v0.1 review fixture

- Exported `AssetLab/artifacts/map-top-down-character-proof-v0.1.png`: a lossless sheet derived from
  native 16px tiles and scaled nearest-neighbour 2× in color and literal grayscale.
- It exercises Mara in N/E/S/W; six silhouette-diverse named people; generated seeds 41–43; a
  separate noncanonical Binder; real world-graded terrain; route; disclosed writing, drop, flora,
  site, portal and unjoined traveller; and separate current/selected/actionable overlays. It contains
  no hidden markers and no gear/POI-like equipment glyphs.
- Exact bounds are asserted for every first-proof named identity in every facing. Browser console is
  clean; full tests pass and regression remains 0/205. The fixture is review-only pending direct
  Design disposition and is not in the native map pack.

### Integrated mapTopDown v0.2 focused correction

- Design accepted v0.1's camera/disclosure direction but found its renderer still rotated an upright
  paper doll, including a skin face plane. Promotion remained blocked.
- v0.2 replaces that source geometry with true overhead occlusion: a stepped crown/headwear mass
  overlaps the neck and upper back; torso, limbs and boot tips are foreshortened; hood/brim no longer
  create hollow face boxes. Mara and mantle-heavy Tovin have four shape-distinct facings.
- `mapTopDownContract` explicitly marks the compact-upright `world` profile legacy/proof-only,
  `mapTopDown` as the sole integration-facing map profile, face plane false, ownership overlays
  game-owned, and bounds 16px.
- Revised artifact: `AssetLab/artifacts/map-top-down-character-proof-v0.2.png`. It retains the native
  2× color/grayscale collision evidence and adds a labelled literal-grayscale 8× inspection strip
  from the same 16px sprites for Mara and Tovin N/E/S/W, six named people, three generated seeds and
  noncanonical Binder. The native grayscale fixture combines selected + current overlays.
- Full tests pass; regression remains 0/205. v0.2 is still review-only pending direct Design
  disposition and is not exported to the native map pack.

### mapTopDown v0.3 golden promotion

- v0.3 replaces hood rings and paired mantle voids with a contiguous stepped crown and directional
  shoulder/back cap. Tovin and the narrower noncanonical Binder remain human and distinct in all
  four facings, and do not collide with portal, site or unknown-creature grammar in grayscale.
- Root Game Design accepted `AssetLab/artifacts/map-top-down-character-proof-v0.3.png` as the
  superseding visual authority. v0.1/v0.2 are retired as current evidence.
- Golden regression protects only reviewed scope: Mara and Tovin N/E/S/W; Halloway, Isolde, Wren
  and Ashe north; generated seeds 41–43 north; and Binder N/E/S/W. Regression is 0/224.

## Character-map adapter v1 — separate native handoff

- This is deliberately separate from frozen map-slice v1.1. Schema:
  `AssetLab/schemas/character-map-request.schema.json`; adapter:
  `AssetLab/src/character-map-contract.js`; tests:
  `AssetLab/tests/character-map-contract.test.js`.
- Immutable tuple: contract `1`, adapter `character-map-adapter-1.0.0`, descriptor
  `character-descriptor-1.0.0`, renderer `map-top-down-renderer-1.0.0`, world grade
  `world-grade-1.0.0`, profile `map-character-16px-1.0.0`.
- Closed request owns one identity kind, exact N/E/S/W facing, `mapTopDown`, and the signed world-grade
  offsets. Calling, stats, party color, selection/action overlays, gear and POI state are rejected or
  remain outside the character renderer.
- Named `TravellerID` maps to the 28 authored descriptors. Generated people require an explicit
  persisted `visualSeedUInt32`; missing seeds diagnose rather than reroll.
- **Current native blockers, never substituted:** Binder and Quill have no accepted persisted
  appearance model. Both return structured `missing-persisted-appearance` diagnostics and must keep
  the existing native fallback until game-owned identity exists. The noncanonical Binder proof
  template is not an adapter fallback.
- Exact world-grade input now changes personal colors without changing geometry. Rectangle/request
  hashes use the documented AssetLab 32-bit fixture hash; any packaged native conformance manifest
  must add canonical JSON and decoded-pixel SHA-256 separately.
- The public adapter now enforces the same recursive closure itself rather than trusting callers to
  run AJV first. Unknown top-level, identity and world-grade fields return structured `unknown-field`
  diagnostics with exact paths; direct tests cover `selected`, `identity.calling` and
  `worldGrade.temperature`. Full suite passes; regression remains 0/224.
