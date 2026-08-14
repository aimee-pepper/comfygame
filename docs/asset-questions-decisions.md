# Asset Questions and Decisions

## Simulator-window handling — settled 10 Aug 2026

- Do not close, reopen, boot, recreate, reposition or otherwise alter Aimee's existing iPhone
  Simulator suites/windows. Reuse the already-running simulator only with non-lifecycle commands.
- If no suitable simulator is already available, pause simulator QA rather than launching one.
- AssetLab browser/unit work does not require Simulator and should leave it untouched.

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

### 10 Aug 2026 — App Launch v0.2 frozen by Aimee

- Aimee identified the preferred simple composition as the stark boxed page with two long horizontal
  rules, matching the existing v0.2 lossless proof rather than v0.1's vertical I-like mark.
- `AssetLab/artifacts/app-launch-proof-v0.2.png` remains the visual authority. No new launch variant
  or revision is authorized.
- **Freeze:** do not revise, review, expand or schedule App Launch work again unless Aimee explicitly
  requests it. App Launch is removed from the active asset roadmap; higher-priority playable economy
  and map work proceeds instead.

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

### Full-cast mapTopDown v0.1 — accepted AssetLab catalogue expansion

- Exported `AssetLab/artifacts/map-top-down-full-cast-proof-v0.1.png`. All 28 authored traveller
  descriptors appear in the accepted authored order in north/east/south/west panels, each rendered
  at native 112×64 and scaled nearest-neighbour 2× in color and literal grayscale under the exact
  cool-living `worldGrade` vector.
- Tests now require pairwise silhouette inequality across all 28 named people independently in each
  of the four facings. The browser console is clean; full tests pass and regression remains 0/224.
- Corrected the older full-cast proof caption: its 16px `world` figures are compact-upright
  legacy/proof-only, not straight top-down. `mapTopDown` remains the sole integration-facing map
  camera.
- Game Design accepted all 28×4 facings as the catalogue expansion. Bryn/Dagg and Orsa/Sabine are
  the closest native-scale pairs but remain distinct through carry/apron/body mass. This does not
  authorize native integration, add gear/animation, or resolve the persisted
  Binder/Quill/generated/facing gates. The next review-key export should wrap or number the final
  clipped labels; that presentation cleanup does not alter sprite acceptance.

## Terrain border/elevation correction — 9 Aug 2026

- **Observed native issue:** every tile was outlined by an app-owned debug grid, while the shared
  elevation grammar added a full-width brown bottom band. Together these made ordinary terrain read
  as bordered blocks or side-view dirt ledges.
- **Asset decision:** ordinary ground has no perimeter border. Only water, deep water, ice and chasm
  own adjacency edges. Elevation remains a real readable tile fact, but is now shown with one to
  three strictly inset paired contour steps derived from that ground family's own graded palette.
  The cue never reaches the tile perimeter and cannot become a horizon or baseline.
- Chasm is missing ground, so nonzero elevation is suppressed and impossible chasm-elevation
  fixtures are not exported.
- Map grammar advances from `map-slice-1.1.0` to `map-slice-1.2.0`; other tuple members are
  unchanged. The regenerated conformance pack contains 195 outputs and canonical manifest SHA-256
  `6d0c21206a983d024a4b948fe7008a2be89676e5c934efa3f84bc8b194fd7996`.
- Tests cover all 12 grounds at elevations 0–3, strictly inset geometry, removal of legacy brown,
  and exclusive adjacency ownership by the four edge-bearing families. Full tests pass; golden
  regression is 0/224.
- **Engineering-owned follow-up:** remove the universal native tile stroke and mirror the accepted
  AssetLab 1.2.0 elevation commands/hash. AssetLab does not modify the game implementation.
- **Design disposition:** the border/bar correction and inset contour direction pass. Before golden
  promotion, provide one integrated adjacent 0→1→2→3 dry plus wet/vegetated color/grayscale strip
  with route/content overlays, proving the marks read as elevation rather than incidental texture.
  Retain 1.1.0 in native until that focused artifact is accepted.

### 10 Aug 2026 — elevation extrusion correction requested by Aimee

- Aimee rejects generic elevation sidewalls that read as dirt or wooden stakes under unrelated
  surfaces. Any exposed riser must be derived from the owning ground family's world-graded palette
  and material texture.
- Preferred direction: lift the complete surface composition upward by the resolved riser height and
  fill only the newly exposed screen-south wall beneath it. Terrain detail, flora, crack, content,
  route/action and party/selection remain surface-owned and shift together; hit ownership and logical
  tile coordinates do not move.
- A true lift cannot be faked as another strip inside a clipped 16×16 tile. Candidate contract uses a
  16×`(16 + riserHeight)` render surface with a bottom/base-cell anchor and controlled upward
  overflow. Native requires explicit overlap order and must not clip the raised surface back to the
  logical cell.
- Sidewall visibility must derive from neighboring elevation, not merely ground adjacency: an equal
  or higher screen-south neighbor occludes the wall; a lower neighbor exposes only the positive
  height difference. Chasm never receives a raised top. Fog still short-circuits all informative
  pixels.
- **Placeholder pending focused proof/review:** use one pixel of riser per elevation level, preserving
  the current compact map scale. Prove adjacent 0→1→2→3 dry ground, mixed-material equal heights,
  a drop back to zero, wet/vegetated surfaces, route/content/party surface alignment, map-edge
  clipping, color/grayscale and native phone scale before replacing the current candidate grammar.

#### Lifted extrusion candidate v0.1

- Added a separate review-only `liftedTerrainSprite` contract rather than mutating the current native
  pack. It returns a 16×19 bottom-anchored sprite, fixed logical 16×16 hit footprint, one pixel per
  elevation level, intact translated top plane and a screen-south wall only for the positive delta to
  the southern neighbour.
- `liftedSurfaceLayerCommands` applies the exact surface offset to flora, crack, content, route and
  actor layers. Tests cover fixed dimensions/pivot, complete-plane translation, same-height seam
  suppression, positive-delta walls, removal of generic dirt/stake colors, overlay alignment and
  water/deep-water/chasm normalization to elevation zero.
- Lossless review artifact: `AssetLab/artifacts/terrain-lifted-extrusion-proof-v0.1.png`, showing a
  5×4 color/grayscale composition with soil 0→3, stone, groundcover/flora, route/traveller and
  water/chasm boundaries. Full tests pass; existing golden regression remains 0/224 because the
  candidate has not replaced the current handoff or entered golden.

#### Integrated review and closed-API corrections

- Design accepted the revised native 5×4 back-to-front artifact for candidate/golden promotion:
  equal heights have no seam; soil 0→3 and mixed soil/stone joins read as low owning-material
  terraces; the turning route, flora and upper actor remain seated; the immediately southern actor
  is not clipped; raised land remains distinct beside flat water/chasm in color and grayscale.
- Engineering's source review found and closed three pre-handoff issues. The geometry is now frozen as
  profile `terrain-lifted-1.0.0` (16×19, pivot 8/18, logical 16×16, max elevation 3, one pixel per
  level). Fog, crumble, water, deep water and chasm resolve to rendered elevation zero. The renderer
  accepts only exact `southExposureLevels` 0…3 rather than arbitrary neighbor height/geometry, and
  surface translation is restricted to flora/decor, crack/warning, content, route/action/target and
  actor/selection layers; floating alert badges are rejected.
- Native derives exposure from one validated map snapshot after normalization:
  `max(0, renderedCenterElevation - renderedSouthElevation)`. Concealed neighbors and map boundaries
  expose zero levels in v1. Rows render north-to-south; logical hit ownership remains square and
  unchanged. Tests cover hidden/crumbled levels 1–3, invalid exposure values and unsupported floating
  layers.

#### Lifted terrain candidate contract closure

- The integration-facing lifted profile has its own immutable tuple rather than silently changing
  map-slice v1.1: `lifted-terrain-adapter-1.0.0`, `terrain-lifted-1.0.0`,
  `world-grade-1.0.0`, and `terrain-16x19-bottom-anchored-1.0.0`.
- `southExposureLevels` is required and exact. Missing, extra, out-of-range, or greater-than-resolved
  center elevation facts are diagnosed; unrevealed, crumbled, or forced-flat ground must pass zero.
- Pending explicit substrate/shelf/basin facts, water, deep water, chasm, ice, growth and groundcover
  resolve to elevation zero. This prevents green vegetation walls, invented ice shelves and implicit
  waterfalls. Dry solid substrates retain same-material lifted faces.
- The machine request is closed in `AssetLab/schemas/lifted-terrain-request.schema.json`; the public
  adapter independently enforces closure and cross-field semantics. Two fixed SHA-256 rectangle and
  pixel-token vectors live in `AssetLab/integration/lifted-terrain-v1/conformance-vectors.json`.
- Verification: full AssetLab suite passes and regression is 0/224. Simulator was not used.

#### Lifted terrain frozen native conformance pack

- Engineering may claim the bounded native map renderer/compositor files. AssetLab remains walled and
  does not edit them.
- Frozen manifest: `AssetLab/integration/lifted-terrain-v1/manifest.json`; canonical SHA-256
  `fdfe2744af523628dc7aacac3c5a901d2fbd499a02cdb205a76d21e9f3d3f399`.
- The pack contains two 16×19 sRGB RGBA PNG conformance fixtures with file and independently decoded
  RGBA SHA-256 hashes. Tests also pin recursive-canonical request and rectangle-command hashes.
- The manifest fixes logical hit ownership, bottom pivot, north-to-south row order, sprite origin,
  exact exposure derivation, shifted surface-owned layers and unshifted floating badges. This is the
  native checkpoint that removes false sidewalls without flattening supported dry-land elevation.

### 10 Aug 2026 — playability-first economy station identities

- Added authored `trading_post` and `recycler` station identities. There is deliberately no
  `exchange` alias: Trading Post means a merchant with rotating stock who buys eligible goods for gold.
- Native grayscale evidence separates Trading Post, Recycler, Storehouse, Workshop and Blacksmith
  through whole mass and negative space; built/tier-stress/damaged states preserve identity.
- Staffing remains a separate occupant and does not mutate station geometry. Prices, eligibility,
  recovery yield, refresh timing and transaction rules are not encoded in station art.
- Placeholder decision: both stations share a lawful neutral pre-identity foundation slab. An
  unfinished foundation does not reveal its future station kind; authored identity begins when built.
- Design accepted `AssetLab/artifacts/economy-stations-proof-v0.1.png` for AssetLab golden promotion.

### 10 Aug 2026 — equipment-grid bridge candidate

- Added a narrow Equipment Grid Lab reachable from Resource Lab. It covers the exact eight live
  `GearSlot` raw values (`armor` is displayed as Body) and keeps item-family identity independent
  from location and comparison state.
- The Weapon fixture pins Mara's worn Pointed Blade as baseline, then shows Stored, Worn, safe home
  Overflow and current-world Carried ownership. Overflow never uses loss language; Carried remains
  unavailable at home and is never presented as Worn.
- Four location channels use full text plus separate shelf/person/open-tray/satchel shapes that
  survive literal grayscale. Filter buttons are at least 44pt; a one-column accessibility-large
  example and an ordered hidden semantic list are included.
- The exported resolver tests All plus every exact slot, `armor`→Body and `offhand`→Off-hand labels,
  stable instance ID/icon across four explicitly labelled snapshots, mutually distinct locations,
  the pinned baseline and signed `current/−2/+1/+0` comparison strings.
- Current review artifact: `AssetLab/artifacts/equipment-grid-bridge-proof-v0.2.png`. This is visual
  and semantic evidence only; it does not authorize or invent merchant/recycler transaction rules.

#### Six-across inventory direction supersedes the two-column bridge

- Aimee rejected two-column prose cards as a reformatted list. The current phone grammar is six
  square item icons per row; item names and descriptive prose appear only after tapping an icon.
- `AssetLab/artifacts/equipment-six-across-proof-v0.3.png` proves six 54px cells across a 390pt
  phone canvas, literal grayscale, quantity, unknown, location, rarity and selection without names
  under icons. Location changes neither the central item identity nor its persisted instance.
- Selection and rarity are independent channels: the fixture includes selected ordinary,
  unselected fine and selected-plus-fine cases. A worn baseline offers Take off/Inspect; Stored may
  Equip, Overflow must be stored/made accessible first, and Carried remains unavailable at home.
- Item-family collision assertions now also hash occupied pixels rather than rectangle decomposition,
  matching the strengthened resource test boundary.
- The tapped detail owns the full name, known provenance/stats, quantity, location and truthful
  actions. Slot filtering remains navigation only and covers all eight exact live slot values.
- The prior v0.2 two-column artifact remains historical evidence only and is not a current UI
  recommendation.

#### Blacksmith Pointed Blade checkpoint

- `AssetLab/artifacts/blacksmith-pointed-blade-checkpoint-proof-v0.1.png` shows five truthful states:
  missing samples, samples ready but Essence short, exact preview, destructive confirmation, and a
  newly persisted Stored output.
- READY uses `Review craft`; only CONFIRM uses `Confirm craft`. RESULT offers `View stored` and does
  not imply another mutation. No input is removed before confirmation, and the fixture separately
  states wallet 24→12, exact consumed sample identities and new item instance #9001.

### 10 Aug 2026 — resource readability and neutral sheen v0.5

- The earlier reuse of shared node-profile silhouettes is retired. Each on-map resource family now
  owns a pairwise-distinct dominant mass/negative-space profile at native grayscale; hue, label,
  substrate and animation are not permitted to rescue a silhouette collision.
- Pairwise automation hashes the union of occupied pixels, not the renderer's rectangle-command
  decomposition, so two command lists that fill the same visible shape cannot falsely pass.
- The highest-risk mineral groups are explicitly separated: cross-vein ore, broken-diagonal copper,
  compact gold nuggets; single-prism quartz, multi-blade obsidian and split unstable Rift-glass.
- The six actual flora-linked families preserve the exact host flora sprite while adding a distinct
  disclosed harvest cue: fibre lattice, timber log, pulp sheets, toxin vessel, spore burst and
  reagent steps. Cue-only and same-host comparisons are fixture-tested.
- Revealed, remaining resources receive a restrained luminance sheen clipped strictly to occupied
  resource/cue pixels. The eight-tick 360ms cycle has four rest ticks and uses only the public
  persisted tile/instance identity for stable phase staggering. It never encodes rarity, grade,
  yield, danger, eligibility, provenance or hidden properties.
- The reusable constants are frozen as `resource-sheen-1.1.0`: 360ms tick, eight ticks, four active
  plus four resting, static frame 0 under Reduce Motion, and composition after the resource body but
  before route, selection, party and UI overlays.
- Reduce Motion/static frame, literal grayscale silhouette and paused screenshots retain identity.
  Fog, minimap, exhausted remnants and Mote do not sheen. Raw Essence keeps the accepted wildDrop
  body; Rift-glass keeps its separately truthful unstable substrate.
- Design accepted `AssetLab/artifacts/resource-node-proof-v0.5.png` for the revised candidate
  boundary. Full AssetLab tests pass and the intentional resource golden update returns regression
  to 0/224. Native must supply the actual public persisted identity rather than the Lab fixture key.

#### Resource sheen native contract closure

- The stable phase payload is ASCII/UTF-8
  `resource-sheen-1.1.0|mapSeedUInt64Decimal|runIndex|x|y`, hashed with FNV-1a-32. It uses only
  persisted public world/tile identity and never Swift `hashValue`, hidden properties or resource ID.
- The closed map adapter rejects unknown/missing fields, Mote map rendering, a Raw Essence body that
  is not the accepted wildDrop, and resource/body-kind mismatches. Legal unrevealed, undiscovered or
  exhausted states return no sheen; Reduce Motion returns the static frame-zero glint.
- `AssetLab/schemas/resource-sheen-request.schema.json` mirrors that closed machine request with
  recursive phase/rectangle closure and strict types/ranges; AJV negative fixtures cover nested
  extras and invalid ticks, while the public adapter independently enforces semantic cross-fields.
- Before producing pixels, the adapter derives the accepted remaining body for the requested family
  and requires exact silhouette-command equality. A caller cannot relabel fog, minimap, an exhausted
  remnant, terrain or unrelated commands as a resource mask and receive a sheen.
- `AssetLab/fixtures/resource-sheen-v1.1-conformance.json` reconciles all 23 IDs, pins two UInt64/
  coordinate phase vectors, and supplies command plus decoded 16×16 RGBA SHA-256 hashes for ore,
  fibre, Rift-glass and Raw Essence bodies, exhausted states and all four active frames.
- Current fixture file SHA-256 is
  `9e348ebb73a470452d2b80b4fb965d6c7786b347746c123c94e8a7c619476946`; the reviewed lossless
  v0.5 contact sheet SHA-256 is
  `c2570833dd13d777d5deea6be5155cd07ff349cebd00ae1282f5d3cf4a150601`.
- Native should use one map-level 360ms clock, not one timer per tile. The game supplies the current
  persisted run/map facts and composes route, selection, party and UI above the sheen.

#### Placeholder boundary for later resource world conditioning

- `worldGrade` is bounded shared map lighting, not a resource-property encoder. Resource geometry,
  value order and canonical inventory palette remain family-stable; graded map bodies/cues require a
  versioned clamped transform with a contrast floor and stable outline/highlight.
- Terrain and exact host flora retain their own accepted grade ownership. A resource cue may share
  the visible world's lighting but cannot encode rarity, material grade, yield, eligibility, danger,
  provenance or hidden properties.
- Sheen is applied after grading as the same neutral luminance treatment and never varies by world
  grade or item property. Exhausted remnants may share visible lighting but never sheen. Mote stays
  inventory-only; Raw Essence continues exclusively through the shared wildDrop presentation.
- This is a recommendation for the next depth proof, not an authorization to change the accepted v0.5
  pixels or native renderer during the current playtest checkpoint.

### 10 Aug 2026 — web-tool functional audit follow-up

- Every one of the eleven shared navigation buttons was clicked in sequence, and the linked
  Equipment Lab was exercised separately. Every destination retained the complete eleven-link shared
  navigation bar and reported no browser diagnostics. Narrow phone widths use the same horizontally
  scrollable navigation rather than hiding or conditionally removing destinations.
- Resource→Equipment navigation was exercised directly. The Equipment Lab retained the shared bar,
  exact slot filters and semantic item list after navigation. All nine filter buttons were clicked;
  their live counts matched the resolver, and the discovered `1 items` copy defect was corrected to
  `1 item` with 0/1/many unit coverage.
- That interaction pass also caught metadata being derived from filtered cell index. Quantity,
  rarity, provenance and identified/unknown state now belong to stable fixture identity: filtering
  Keepsake preserves `Unknown item · singular`, and filtering Head no longer gives the first hood the
  Pointed Blade's crafted provenance. Cross-filter identity and unknown-state negatives are tested.
- Two resource frames captured more than one 360ms tick apart produced different rendered hashes,
  confirming that the live proof animates. Static ownership, cadence, clipping, rest and stagger
  properties remain covered by deterministic source tests rather than screenshot timing alone.
- The disclosed Quartz interaction control was clicked directly and returned the exact resolver-owned
  `quartz · node · crystal profile · remaining` description; it does not infer a hidden family or
  state from animation.
- The audit found and corrected a stale Golden Review failure: the browser sheet initially rendered 36
  representative outputs but compared itself against all 224 baseline keys, falsely reporting 188
  deletions. It now compares only the outputs it actually renders, states its representative scope,
  includes 31 resource remaining/exhausted/minimap/Raw Essence/Mote fixtures, reports
  `67 visible checked · 224 canonical`, and points to the complete CLI regression gate. The corrected
  live page reports `Visible sheet matches`; its PNG/report export controls were exercised without
  browser diagnostics, and the complete gate remains 0/224.

### 10 Aug 2026 — two-hour AssetLab checkpoint closure

- The material-matched lifted-terrain contract is frozen and handed off separately from the older
  16×16 contour candidate. Its native-consumption boundary is the 16×19 bottom-anchored pack at
  `AssetLab/integration/lifted-terrain-v1/manifest.json`, canonical manifest SHA-256
  `fdfe2744af523628dc7aacac3c5a901d2fbd499a02cdb205a76d21e9f3d3f399`, with two decoded-RGBA
  conformance vectors. Native integration is authorized; AssetLab does not own the game renderer.
- Resource v0.5 and resource-sheen v1.1 close the reported same-looking-node problem in the Lab:
  every applicable map family owns an at-a-glance silhouette/cue, while a slow, staggered,
  disclosure-neutral sheen distinguishes revealed remaining resources from background map art.
  Animation is clipped to the accepted resource body and is never required for identity.
- Equipment v0.3 replaces the rejected two-column prose-card direction with six icons per 390pt row
  and tapped detail. Stable fixture identity owns quantity, rarity, provenance and unknown state, so
  filtering cannot silently identify or rewrite an item. Blacksmith v0.1 proves the first truthful
  Pointed Blade transaction without claiming reforge or salvage.
- The complete web navigation was exercised without disappearing destinations or browser diagnostics.
  Golden Review now reports only the representative outputs it renders instead of false deletions;
  the authoritative CLI gate remains the complete comparison.
- Final verification at the checkpoint: `npm test` passes, `npm run regression` reports 224 checked /
  0 changed, and `git diff --check` reports no whitespace errors in the owned scope. Simulator was not
  opened, closed, booted, repositioned or otherwise touched.
- Next playability-first asset work is deliberately narrow: provisional reviewed Noll identity, the
  five-identity economy bridge, then resolver-backed Trading Post and Recycler states. Broad combat,
  splash animation, portraits and extra procedural breadth remain paused.

### 10 Aug 2026 — Trading Post and Vance blocker proof

- Placeholder decision: AssetLab may prove the compact transaction grammar from the current economy
  design, but it must label every wallet, price, stock, eligibility and result value as a proposed
  semantic fixture. The checked-in game currently has no Trading Post state, Gold Coins wallet,
  stock refresh, preview token, revision guard or atomic transaction DTO, so this evidence is not
  integration-golden and does not pretend to mutate a save.
- Trading Post uses stable identity `trading_post`; there is no `exchange` alias. The accepted authored
  open-counter station mass remains unchanged. Vance is a separate occupant using his authored
  descriptor through the new neutral `baseSide` village cameo; identical commands are shown outside
  and at the counter. Merchant meaning belongs to station placement and UI, never Vance's anatomy,
  palette or a class badge.
- The proposed phone grammar uses peer Buy/Sell tabs, exactly six icons per row, tapped detail, aligned
  Gold Coin arithmetic, and separate Preview → Confirm → Result DTO evidence. Protected sell rows
  remain visible without a tempting price and state their reason: Worn, unidentified, or Locked/Keep.
- Stock snapshot #4 is fixture-tested as identical across open/close/reopen. A separately labelled
  post-expedition snapshot #5 changes refresh identity. View opening, clocks and animation never
  reroll it. Selling is shown as proposed to remain available while stock awaits refresh.
- Buy evidence includes an affordable Quartz line and an inactive cannot-buy request for four Copper
  when only two remain. Quartz routes to the Resource Pool, not Stored. The material sample uses a
  fixture-local bin/index handle and its own sample icon rather than inventing a global item ID.
- `proposedTradingPostResult` is intentionally non-mutating. A future rules-owned DTO must provide
  wallet/stock/inventory revisions, opaque preview token, exact eligibility/reasons, and atomic result
  before native integration can call the grammar truthful.
- Accepted proposed-scope artifact: `AssetLab/artifacts/trading-post-vance-proof-v0.2.png` (800×1040).
  v0.1 is superseded review history. Full AssetLab tests pass; regression remains 0/224. Simulator
  was untouched.

### 10 Aug 2026 — research-driven Resource v0.6 correction

- Aimee rejected hash-distinct-but-abstract resources and settled a stronger requirement: each family
  must resemble the physical material at a glance. Research references and the 23-family form grammar
  are recorded in `docs/resource-visual-reference-current.md`.
- Mineral and organic cues now use material-specific mass: broken rubble, smooth clay, rusty iron
  rock, dendritic copper, wire silver, gold nuggets, quartz prisms, obsidian blades, salt cubes,
  sulfur crystals, cut timber, gathered fibre, torn pulp, amber resin, dispersed spores and so on.
  Fictional resources follow current game semantics rather than fabricated real-world geology.
- Aimee specifically settled Mercury as a shiny liquid-silver puddle. It has a low irregular pool,
  detached/specular bead pixels and the existing neutral sheen; it is not rendered as cinnabar ore.
- World conditioning may recolor the host substrate or exact host flora, but identity-bearing material
  pixels remain canonical and static. Gold stays gold in every world. `resource-color-1.0.0` forbids
  whole-resource world recoloring and tests the occupied canonical-pixel floor across substrates.
- The accepted sheen is retained unchanged and operates after static color. The conformance exporter
  now regenerates ore, fibre, Mercury, Rift-glass and Raw Essence decoded-RGBA/frame vectors after a
  reviewed body change.
- Design accepted v0.6. The proof adds color/grayscale Mercury collisions against Ichor, shallow
  water and route. Golden coverage now includes every remaining/exhausted map-renderable family rather
  than a 13-family sample: full regression is 0/240.
- Current lossless artifact: `AssetLab/artifacts/resource-node-proof-v0.6.png`, 720×960, SHA-256
  `fdcb946561725a4a50c11dcbff6290625515339500f5cf632743133805157e5c`. Current sheen fixture SHA-256
  is `6782990207e8c1e38179a72a9e6b4a34872d867a502fd8eaeea5bc158d28269d`.

### 10 Aug 2026 — proposed DEBUG bug-reporter v0.3 fixture

- Added an AssetLab-only visual/semantic proposal for the queued floating screenshot/text reporter.
  It is explicitly `integrationReady: false` and makes no claim that native screenshot capture,
  atomic persistence, keyboard/VoiceOver behavior or remote delivery currently exists.
- A closed placement resolver proves a 44×44 reporter target can re-clamp around representative Base,
  world and combat action rectangles. Invalid safe geometry, edge/fraction values and non-finite or
  non-positive action rectangles reject. DEBUG exposes the control; Release removes it both visually
  and accessibly.
- One shared scene-command source owns the proposed Captured frame, Ready is exactly Captured plus the
  reporter overlay, and the form thumbnail derives from Captured. Tests prove Ready-minus-overlay
  command equality. Native pixel capture remains a later Engineering gate.
- Screenshot state is a closed union: `attached`, `removed`, or `captureFailed`; failure uses only an
  allowlisted reason. Both removed and failed screenshots preserve a valid text submission, while
  blank required text owns an inline explanation and disabled Save.
- Local Unsent owns `Share / export`; only Needs attention owns Retry; Submitted requires a nonempty
  bounded remote acknowledgement. Illegal state regressions and direct draft transport reject.
  Context fields are closed and bounded, with the semantic action count limited to 0…20.
- Design accepted the v0.3 proposed fixture boundary. Current lossless artifact:
  `AssetLab/artifacts/debug-bug-reporter-proof-v0.3.png`, color plus literal grayscale and a clearly
  labelled large-text reflow sample. Full tests pass and regression remains 0/240. Simulator was
  untouched.

### 10 Aug 2026 — provisional Noll identity v0.2

- The next playability-facing asset gap was Noll, the intended Recycler keeper after Vance. A working
  descriptor is now available for review, but Noll remains deliberately outside the accepted
  28-person catalogue. `noll` and `provisional_noll` are not native identity values.
- Working axes are light build, wrapped crown, coat, free hands, right asymmetry and ochre personal
  palette. A Noll-only authored headwear variant makes the wrap a compact layered crown with a small
  right knot; it does not alter any accepted character pixels or derive anatomy from calling/stats.
- Evidence covers straight-top-down N/E/S/W, village side view, side-biased combat, literal grayscale
  collision against Vance/Halloway, and an unlabeled map row against traveller, wildDrop, portal,
  site and block-like resource cues. Recycler geometry remains command-identical staffed/unstaffed;
  Noll is always a separate occupant.
- Design accepted v0.2 as the current working/provisional identity. Working name, they/them pronouns
  and art remain reviewable by Aimee. Native promotion later requires one atomic canonical identity,
  descriptor/catalogue/schema versioning, generated-reservation regeneration, persistence/staffing
  mapping and new hashes; the authoring escape hatch must never become a saved identity.
- Current lossless artifact: `AssetLab/artifacts/provisional-noll-identity-proof-v0.2.png`, 800×840.
  Full tests pass and accepted regression remains 0/240. Simulator was untouched.
## 11 Aug 2026 — native compact-surface identity QA

Read-only QA of the `de2b71b` phone UI checkpoint found that the new spatial layouts are structurally sound, but several compact surfaces still substitute generic SF Symbols for accepted asset identities.

- Resource tiles in Storehouse and Trading Post must reuse the canonical static Resource v0.6 body. Quantity and selection remain independent overlays; inventory art does not need map sheen. Engineering owned and installed this correction in `4d8da72`.
- Party and Library People/diary-author tiles currently use `TravellerDef.icon` as the primary identity. Replace that with one shared descriptor-derived compact person cameo; never derive anatomy from calling or profession. The accepted `mapTopDown` profile remains map-only, so the later compact cameo needs an explicitly named profile rather than silently reusing the legacy upright world sprite.
- The Base destination board currently uses station SF Symbols. This is materially misleading for `trading_post`, whose `arrow.left.arrow.right` icon resurrects the rejected Exchange fantasy, and it collapses Blacksmith/Weaponsmith onto the same hammer. Later native presentation should reuse the accepted authored base-side place identity; the unbuilt state uses the shared neutral foundation.
- The six-across item grid exposes a real remaining asset gap: multiple distinct equipment families and progressions share the same SF Symbol. Rarity, quantity, location, and selection cannot substitute for item identity. Author a compact item-family icon contract before calling the inventory/equipment/merchant grid visually complete.
- Bestiary and encounter collection tiles likewise use generic symbols rather than deterministic species identity. Queue the creature identity bridge after the item/place/person compact bridges; do not alter disclosure or percentile rules to compensate.
- Phone-size check still required: Party remains three columns through `.xxxLarge` Dynamic Type while several labels are single-line. If a 390-point proof clips or scales identity text excessively, reflow to two or one columns earlier. Library's current two-to-one accessibility reflow has no source-level blocker.

Settled cross-surface rule: spatial layout determines *where* an identity is shown; authored/generated asset grammar determines *what* the identity looks like. System symbols may support actions and state, but must not become the primary identity for tangible items, people, places, or generated species.

## 11 Aug 2026 — P0 save-slot/start-screen visual recommendation

Recommendations only; Engineering owns implementation and Game Design owns behavior. This surface begins only after truthful loading finishes. It does not make the static launch screen interactive and does not redesign the accepted launch art.

### Smallest phone grammar

- Treat campaigns as a compact **bookplate board**, not a settings list and not a six-across tangible-object tray. Ordinary phone layout uses two columns; accessibility text uses one column.
- The start screen has three spatially distinct actions: a prominent `Continue · <campaign name>` bookplate when a valid recent slot exists, a `New Game` blank-bookplate tile, and `Load Game` leading to the complete campaign board. On an empty installation, omit Continue entirely and make New Game primary.
- Each slot card owns a stable, disclosure-neutral cover/bookplate motif derived only from its stable slot UUID. Shape and value, not color alone, distinguish adjacent campaigns. The motif encodes no Binder face, world/site/apex content, difficulty, health, danger, rarity, or hidden progress.
- Visible card facts are campaign name, last played, Binder level, and truthful current state/location. Use short labelled rows/chips within the tile rather than prose. Optional progression context must come from frozen slot metadata and remain broad (`At Base`, `In a world`, `In combat`, `Returning`); assets never infer it from payload contents.
- A healthy card's primary 44-point action is `Load`. Secondary actions live behind a clearly labelled `More` control. Delete is never the entire card, never swipe-only, and never adjacent to Load without separation.
- Corrupt and future-incompatible slots remain full members of the board with the same stable bookplate identity. Replace Load with a non-color warning shape plus exact text (`Needs recovery` or `Made by a newer version`) and expose `Export save`/recovery detail. Do not visually erase or silently skip them; Continue alone ignores them.

### Delete and state evidence

- Deletion opens a focused confirmation sheet repeating the exact campaign name and bookplate. Copy states that only this campaign will be removed. `Cancel` is the initial/safe action; the destructive action is text plus shape and requires an explicit tap. No typed-name ceremony is needed for the first slice unless testing shows accidental deletion remains likely.
- After confirmed deletion, return to the board with a truthful completion announcement and the remaining cards in stable order. Cancel changes nothing. Deleting the active/final slot must land on a usable start screen, with New Game primary when none remain.
- DEBUG-only metadata (build and save-schema version, slot UUID, export) belongs in card detail, never the ordinary card face. Duplicate Save remains absent until separately implemented.

### Smallest acceptance artifact

One lossless 390×844 contact sheet at native scale, with literal-grayscale partners and one accessibility-large column sample:

1. empty installation: New Game primary, no Continue;
2. one healthy migrated campaign: Continue names it and New/Load remain separate;
3. four-card Load board: recent healthy, older healthy test campaign, corrupt, future-incompatible;
4. named delete confirmation plus cancelled state and exact-one-slot removed result;
5. DEBUG detail showing schema/export without polluting the ordinary card;
6. 390-point large-text board proving every label/action remains reachable and each target is at least 44 points.

Required fixture assertions: UUID—not name/index—owns bookplate identity; rename leaves identity pixels unchanged; card order does not change identity; invalid slots never become Continue; empty state contains no phantom slot; cancel is pixel/state stable; confirmed deletion removes only the exact UUID; ordinary Release cards contain no DEBUG metadata; light/dark and grayscale preserve selected/healthy/unavailable/destructive channels; VoiceOver order is campaign name → last played → level → state/location → Load or exact unavailable reason → More.

Placeholder decisions to avoid blocking: use two columns at ordinary phone text, one at accessibility sizes; use deterministic nonsemantic bookplate motifs rather than screenshots; keep slot naming in New Game/detail rather than on the launch surface; preserve current app background/page-edge language with a direct reveal or short crossfade, and use a direct cut under Reduce Motion.

## 11 Aug 2026 — exact catalogue item identity v0.2

- Promoted the first compact catalogue slice: 30 exact live catalogue IDs plus one shared disclosure-neutral unknown-item presentation. Identity is mapped explicitly from `catalogItemID`; no visual is inferred from SF Symbol name, rarity, tier, stats, price, profession, provenance, or catalogue order.
- The native 32-pixel proof uses six-across color and literal-grayscale rows with no item names beneath cells. Long Pick/Bent Pick and Clearing/Farsight now differ by large occupied mass and negative space. Waystone reads as a three-prong carried instrument rather than another bottle.
- Both unidentified curios resolve to exactly the same opaque unknown commands until legitimate identification. Unsupported IDs, extra fields, and unsupported unidentified states reject instead of silently borrowing a known silhouette.
- Design directly accepted v0.2 for AssetLab golden promotion. Native integration remains a later adapter/UI task; this promotion does not authorize replacing game code from the asset wall.
- Current lossless artifact: `AssetLab/artifacts/catalogue-item-identity-proof-v0.2.png`, SHA-256 `93f79d302f5ff0608949ec686cd323982701d1b8f5463a4ea168529e3c0ab315`. Full tests pass. Golden regression now covers 271 outputs with 0 changes (30 known item icons + one unknown added to the prior 240).
## 11 Aug 2026 — world palette differentiation audit

Current native terrain recoloring is live and uses `WorldGrade.from(PressureReadings)` in
`Sources/Screens/MapAssetRenderer.swift`. It reads exactly five resolved, post-constraint facts:

- Thermal midpoint `(peak + floor) / 2` → warmth;
- Hydrology `availableMagnitude` → wetness;
- Vitality `peak` → life;
- Illumination midpoint `(peak + floor) / 2` → light;
- Substrate `peak` → mineral character.

Each value is centered as `clamp((x - 50) / 50, -1, 1)`. The frozen v1 grade is:

```text
red   = round(clamp(24*warmth + 8*mineral, -32, 32))
green = round(clamp(22*life + 8*wetness, -32, 32))
blue  = round(clamp(20*wetness - 8*warmth, -32, 32))
value = round(clamp(16*light + 4*mineral, -20, 20))
```

Native then applies the grade to every terrain palette color as:

```text
displayRed   = clamp(baseRed   + red   + value, 0, 255)
displayGreen = clamp(baseGreen + green + value, 0, 255)
displayBlue  = clamp(baseBlue  + blue  + value, 0, 255)
```

So `value` is added to all three channels. The transform does not currently rotate hue, change
saturation, select a different authored palette bank, or recolor flora/resources/actors. Terrain
geometry and four placement templates vary independently from color.

Likely reasons worlds can still look too similar:

1. Coefficients are intentionally bounded: channel offsets are at most ±32 and common brightness is
   at most ±20. Base ground palettes remain dominant.
2. Thermal and Illumination use midpoints, which compress broad peak/floor readings toward 50.
3. If several world readings rise or fall together, the formula behaves mostly like brightness.
   For example, all five inputs at 60 produce grade `(6,6,2,4)`, an effective displayed shift of
   only `(+10,+10,+6)`—slightly warmer/brighter, not a new world palette.
4. Only a few directional associations exist: warm→red, wet→blue+green, vitality→green,
   illumination→brightness, substrate→small red+brightness. There is no independent authored color
   intention, dominant/secondary palette choice, saturation axis, or material-atmosphere family.
5. Flora currently retains its species palette exactly, and resources retain canonical identity
   colors. Large map elements therefore do not participate in the shared atmosphere yet.
6. Clamping can flatten distinctions in already-dark or already-bright palette channels.

Before adding color choices to sigil/bookwriting, measure the actual bound-world distribution:
record the five normalized inputs, resulting grade, effective per-channel delta, and a perceptual
distance metric for a representative campaign sample. Render the same 12-ground sheet for every
sample at phone scale and cluster near-duplicates. This separates a coefficient/range problem from
a missing player-authored color axis.

Placeholder recommendation: do not silently widen v1 coefficients. Treat any stronger transform as
`world-grade-2` with anchored-world migration/version behavior. First test three bounded options:
(a) stronger but still derived grade; (b) derived selection among authored atmosphere palette banks;
(c) an explicit disclosed bookwriting color/atmosphere choice. Any option must preserve grayscale
affordance, gold/copper/etc. canonical accents, species identity, fog invariance, and must not encode
hidden stats or rune IDs by accident.

## 11 Aug 2026 — illumination and vitality must leave the recoloring formula

Aimee identified two incorrect responsibilities in `world-grade-1`:

- **Illumination is not terrain brightness.** It is a gameplay light condition. Below a settled
  threshold, the party should see less of the currently traversed map and the presentation should
  darken outside a party-owned light radius. A Torch increases that radius. Atmospheric conditions
  such as smoke may reduce the radius and/or steepen the darkness falloff. Exact thresholds and
  curves remain Design authority rather than AssetLab assumptions.
- **Vitality is not greenness.** It is ecological capacity. Higher resolved vitality should produce
  more flora coverage and species abundance, and may support bounded larger/taller species where
  resolved flora traits say so. It must not force green into flora whose legitimate generated hue
  is red, blue, pale, fungal, mineral-like, or otherwise strange. Higher vitality may increase the
  saturation/richness of that flora palette within contrast limits while preserving its hues.

The live rules already implement part of this intent. `FloraRules.castSize` increases flora species
count from Vitality within metabolic viability and the settled cast bounds. `TerrainRules.paintGrowth`
derives covered-tile budget from Vitality and mean stature; habit controls patch topology and stature
resolves groundcover versus sight-blocking growth. `WorldRules.visionRadius` already combines
book-authored vision modifiers, party perception, the trip-persistent Torch bonus, and a night penalty;
`WorldRules.reveal` applies that radius through line-of-sight blockers. The Torch already increases
`torchVisionBonus` and immediately reveals through the larger radius.

The current model also exposes the main gap: `Tile.isRevealed` is permanent accumulated knowledge,
not a separate current-light visibility field, and the renderer has no darkness/falloff mask. A new
game-owned current visibility/light field must therefore remain distinct from permanent reveal:

1. Unrevealed remains invariant fog with no informative pixels.
2. Revealed but currently unlit terrain may remain known while being darkened; transient actors or
   content outside current sight remain disclosure-suppressed by game rules.
3. Radius and falloff resolve from current illumination phase plus allowlisted atmosphere opacity or
   particulate facts. Smoke affects sight only when that fact exists; gray art never implies smoke.
4. Torch/light sources modify this light field, not terrain identity pixels. The field follows the
   game-owned party position and map line of sight.
5. Minimap discovery remains rules-owned. Darkness neither undiscoveries knowledge nor grants POI
   exceptions.

For the replacement world-color system, remove both `22*life` from green and `16*light` from value.
Thermal, hydrology, substrate/material atmosphere, and any future explicit book-authored color intent
may select the coherent palette family. Illumination composes afterward as dynamic light; Vitality
composes through flora population, bounded stature, and flora-palette saturation. This is a versioned
`world-grade-2` change because anchored worlds must not silently change appearance or hashes.

Smallest proof: the same revealed 7×7 map under bright, dim, smoky-dim, and torch-lit conditions,
plus low/high-Vitality versions using the same non-green flora hue family. Prove permanent reveal is
unchanged; smoke reduces current visibility; Torch restores a bounded radius; high Vitality increases
flora count/coverage and bounded stature/saturation without greening terrain; fog and undiscovered
POIs remain unchanged; grayscale, Reduce Motion, and VoiceOver/game-rule visibility stay truthful.

## 11 Aug 2026 — first-class authored color declarations

Aimee accepts all three complementary palette mechanisms: a stronger derived transform, derived
selection among authored atmosphere palette families, and explicit disclosed color/atmosphere choices
in bookwriting. Explicit color is not limited to Atmosphere. It may qualify many legitimately written
subjects—for example the hue of a Sun—and should remain attached to the thing it describes.

Recommended compositional model (placeholder pending Game Design authority):

- A color declaration is a persisted qualifier on a written source/sigil, not a hidden post-bind roll
  and not page-position syntax. Existing books with no declaration resolve through a neutral/default
  migration path.
- **Emitter color** (Sun, Moon, Aurora, fire, other legitimate light sources) owns emitted-light hue.
  It may tint currently illuminated surfaces through a separate light-composition layer; it does not
  replace material identity or determine light intensity/radius.
- **Atmosphere color** owns scattering, haze, and distance tint. Atmosphere density/clarity owns how
  strongly that tint accumulates; an authored hue alone does not invent smoke, toxicity, or opacity.
- **Material color** owns bounded palette tendencies for terrain/water/substrate that legitimately
  belong to the written material. Ground families retain their invariant value/edge grammar.
- **Ecology color** biases generated flora/creature palette families while each species retains its
  resolved coloration and readable anatomy. Vitality controls abundance and bounded saturation, not hue.
- Canonical resource/item identity accents remain recognizable; local light/atmosphere may affect their
  displayed lighting but cannot recolor Gold into a different material or leak rarity/properties.

Multiple declarations should compose by named scope rather than averaging every chosen color into one
brown/gray tint. Material establishes local base color; ecology establishes living palettes; atmosphere
adds bounded distance/scattering; emitters add bounded local illumination. Conflicting declarations in
the same scope need an explicit, previewable rule (such as weighted mixture by written intensity and
count) with a disclosed result swatch. They must never resolve by catalogue order, last-write-wins, or
an undisclosed random winner.

The Writing Desk should preview the declared color on the exact subject and separately preview the
resolved world palette family. Color selection must be named as an authored fact, preserved in grayscale
by shape/value semantics, and never become the sole carrier of passability, depth, hazard, discovery,
toxicity, rarity, or defence. A red Sun is red light; it is not automatically hotter or more dangerous
unless the written pressure contributions independently say so.

Smallest proof: two otherwise identical books differing only in a declared Sun color, plus a third with
the same Sun and a separately declared Atmosphere color. Show the Writing Desk swatches, resolved palette
recipe, bright and dim map states, neutral/gold resources, water/deep-water, and two flora species. Prove
Sun hue affects illuminated light but not radius; Atmosphere hue affects scattering but not smoke/density;
flora hues remain species/world authored rather than Vitality-green; material/resource identities and all
grayscale affordances survive. Version the declaration schema, palette resolver, and renderer tuple before
anchored-world use.

## 11 Aug 2026 — exact catalogue tier-2 slice accepted in AssetLab

- Added the approved eleven exact tier-2 catalogue identities: Keen Blade, Raking Edge, Banded Mace,
  Warded Spear, Banded Buckler, Ridged Helm, Banded Guard, Studded Gloves, Shod Boots, Balanced Pick,
  and Cold Compass.
- Counterpart rows communicate bounded construction ancestry only where the authored objects support it.
  Warded Spear and Cold Compass remain honestly different objects from their mechanical-line counterparts;
  no universal tier silhouette, scale, brightness, ornament, rarity, reach, or damage code is embedded.
- Direct Design review caught and removed a repeated gold accent that initially read as `tier 2 = gold`.
  Banded Mace alone retains an object-specific gold band; other accents derive from their object treatment.
- The lossless proof includes native 32-pixel color and literal-grayscale pairs plus an unlabeled collision
  row against the generic unknown body, Rubble, fine glassy quill, and Raw Essence. All remain distinct by
  direct inspection and occupied-pixel tests.
- Artifact: `AssetLab/artifacts/catalogue-tier2-proof-v0.1.png`, SHA-256
  `3b66f65d4dbf835600ea361efb1a0f53f98b2296294766eed16dce62bb3115b0`; the separate JSON key explicitly
  labels this as `assetlabReviewFixture`, `integrationReady:false`, and names the field `pngSHA256`.
- Promoted only the eleven reviewed hashes. The full suite passes and the golden regression is now 282
  checked / 0 changed. Native catalogue adapter/schema/version/cache work remains separately unauthorized.

## 11 Aug 2026 — exact catalogue tier-3 slice accepted in AssetLab

- Added the eleven exact tier-3 catalogue identities and kept tier, rarity, stats, context, and crafted
  family identity outside catalogue pixels. Anvilfall's central head was corrected so its weight remains
  visible against the proof background in literal grayscale.
- Artifact: `AssetLab/artifacts/catalogue-tier3-proof-v0.1.png`, SHA-256
  `73aafbb4a95e98239d77a04dadc31143747251d23eb0b938926475464ec3d169`.
- Direct Design review accepted the isolated slice. Regression is 293 checked / 0 changed. The evidence
  remains `integrationReady:false`; native catalogue resolution remains a separate gate.

## 11 Aug 2026 — world-grade-2 v0.2 exploratory calibration candidate

This candidate is deliberately unpromoted pending direct Design calibration. It removes Illumination and
Vitality from inherent terrain recoloring and separates the future game resolver from the pixel renderer.
The renderer consumes only resolved material identity, non-assertive palette-family ID, bounded material
transform, explicit atmosphere medium/density/palette, explicit persisted flora cast and placements, and
at most one eligible authored color contribution per technical scope. It consumes no raw pressures and no
map seed. It never invents haze or a fictional material.

The authoritative first-slice color allowlist is Sun → emitter, Smoke → atmosphere, Granite → material,
and Bloom → flora. Granite color is restricted to legitimate stone/substrate surfaces; Bloom never colors
creatures. Smoke density is measured separately from smoke palette. Flora coverage may change legitimately,
but each rendered placement uses its resolved species' own stable form and stature rather than a global
Vitality resize.

Evidence comprises 23 otherwise-controlled native map fixtures in color and literal grayscale, a separate
current-visibility/Torch sequence, and a keyed JSON measurement report. It records per-layer input facts and
CIELAB output distances without total-ordering incomparable axes. Current artifact hashes are:

- color: `9e52d9bc2bef593a86752e7eaebf4b6442b9607a7de32f610d881183daa5bf7b`
- grayscale: `85be8f1352d9c65f3a5def4f0580d43d6afe1fe983e1cd2e3c53b907ce2262c1`
- current visibility: `85afe83506f00fe0021191304400424b39056db8bab767d34fa9959afa2003f6`

Design accepts v0.2 as a calibration foundation, not a palette/schema freeze. The governing rule is
proportional meaningful diversity: identical resolved visual facts may render identically, near neighbors
should read as relatives, and opposed authored/resolved facts should separate proportionally. Runtime must
never optimize for novelty or uniqueness against earlier worlds. Open recommendations remain the
palette catalogue/math, accepted perceptual bands, Ochre/Brown material anchor, color acquisition, compound
semantics, and later separate Creature eligibility. No native integration is authorized.

## 11 Aug 2026 — authored color vocabulary v0.1 Asset recommendations

Settled structural authority remains limited to relative meaningful diversity, authored scoped connected
color rather than a global tint, and Flora remaining separate from Creature. The proposed twelve IDs/names,
starter/common/later grouping, Sun/Smoke/Granite/Bloom first-slice eligibility, achromatic treatment, and
omission of Brown are implementation-ready but reversible Game Design recommendations/placeholders.

Asset's v0.1 recommendations are deliberately separate and reversible:

- canonical coordinates use versioned OKLCH triples converted deterministically to bounded sRGB;
- every color receives a stable redundant pattern/glyph, while its player-facing name remains authoritative;
- White, Black, and Grey are calibrated primarily through lightness and very low chroma, not treated as
  arbitrary hue stops;
- Ochre is lower-chroma and earthier than Orange, and is compared against Yellow plus ordinary earth ramps.
  Asset recommends keeping Brown absent until phone play demonstrates an authored intention that Ochre and
  actual material identities cannot express; neither the vocabulary nor Brown exclusion is Aimee-settled.

The proof shows all twelve swatches in color and literal grayscale, scoped Yellow Sun / Violet Smoke / Red
Granite / Blue Bloom examples, and the Ochre collision row. Artifacts:

- `AssetLab/artifacts/authored-color-vocabulary-proof-v0.1-color.png`, SHA-256
  `eb9959d18a1469e0f290e9faab4f402c31fa52b07268d3c1e88539681a21b97c`
- `AssetLab/artifacts/authored-color-vocabulary-proof-v0.1-grayscale.png`, SHA-256
  `ebb803af7e3db86269bf1dd3f0b6e55b0f2690f998dd36dd02aae9a7cfda0bf8`

This is `integrationReady:false` exploratory evidence. Exact coordinates, gamut policy, pattern vocabulary,
blend coefficients, and phone-play tuning remain recommendations pending direct review and native schema.

## 11 Aug 2026 — fixed named-color acquisition direction superseded

Aimee supersedes the proposed twelve-name ownership/acquisition direction before integration or promotion.
The current direction is player-mixed colored ink, with Game Design recommending subtractive CMY plus a
player-facing Depth control for review. Standard ash-black writing ink means **unspecified color** (`nil`),
not an explicit Black declaration. An eligible unspecified Sigil remains open to full bind-time color
resolution; the resolved color must then persist so redraw/relaunch/anchored revisit never rerolls it.
Explicitly mixed black is a distinct authored instruction from ash/no instruction.

The v0.1 vocabulary and Writing Desk/Library sheets are retained only as superseded exploratory evidence
for grayscale patterns, named accessibility, connected-mark footprint and scoped preview layout. Their
fixed swatches, ownership groups, starter/common/later acquisition, locked-color Library presentation and
named-color round-trip are not the live design direction. They remain `integrationReady:false` and must not
be promoted, migrated into native code or used as save authority while Game Design revises the contract.

## 11 Aug 2026 — existing CMY/Depth reuse audit for mixed ink

This is a source audit, not a proposed schema. Native `Coloration` already stores a CMY triangle normalized
to sum 100 plus independent `depth` and `patterning`, and flora/creature trait persistence already proves
that exact numeric coloration can survive saves. AssetLab's live flora adapter also transports normalized
CMY and Depth deterministically. Those mechanics are useful reference implementations for color conversion,
clamping and cross-language vectors.

They cannot become authored ink unchanged:

- `Coloration.normalise()` maps a zero-total CMY input to 33/33/34. It therefore cannot distinguish no
  pigment/instruction from an equal balanced mixture. The new direction requires `nil` ash/no instruction
  to remain semantically distinct from any explicit mix.
- Current generated-life CMY is always a value, never optional. Its tolerant default is 33/33/34 at Depth
  50. Applying that default to a Sigil would silently turn legacy ash writing into an authored color.
- CMY normalization stores hue proportions, while Depth carries pale-to-near-black value. This can represent
  an explicit mixed black only if the authored instruction is present independently from its numeric output.
- `Sigil` currently persists Intensity, Scale, Count and negations but no authored or resolved color. Page
  qualifier rules can enforce one rung per ladder, yet there is no mixed-ink mark/recipe or bind resolver.
- Existing flora/creature randomness is species-generation randomness. It must not be reused as the seed or
  cache identity for unspecified Sigil color resolution.

## 11 Aug 2026 — Penmaker progression owner

Aimee settles that deliberate ink mixing is an upgrade unlocked by the Penmaker. The existing
progression owner is Isolde: her Scriptorium already owns Penmanship, pencils, pens, chaining and
compounds, so this does not add another traveller or station. Game Design places **Ink mixing** at
Scriptorium tier 1 after **A pencil**; exact cost is reversible tuning.

Before that node, the Writing Desk is Ash-only and color remains open. After purchase, the Desk gains
CMY+Depth mixing and saved mixtures everywhere; the fountain pen and tier 2 are not prerequisites.
Asset evidence should compare those locked/unlocked states. Existing eligible saves must migrate
without a duplicate purchase, and no UI may imply that fixed named colors are separately owned.

**Superseded later 11 Aug:** see “Writing-tool progression correction” below. Pencil is no longer a
current tool; Brush is the first ink-capable hand and direct prerequisite for Ink Mixing.

## 11 Aug 2026 — colored bases derive from world resources

Aimee further settles that CMYK/CMY+Depth bases must be derived from resources. The Scriptorium
upgrade unlocks process and UI, not infinite colored stock. Current Game Design recommends saved
formulas prepared as bounded vials; drafting remains free and applications commit only at bind, while
unlimited Ash preserves the continuation floor. Twelve focus applications per vial is a reversible
DEBUG candidate.

Asset must not infer pigment from a generic resource's current icon or rendered color. Game Design
has now settled the first recipe identities: Copper→Cyan, Ichor→Magenta, Sulfur→Yellow and
Obsidian→Depth. Each resource processes into four integer base measures. Ichor is used because it is
already an authored rare world resource with a canonical dark-magenta identity; no generic biological
sample or retrospective color inference is needed.

A vial consumes one Resin plus `ceil(channel / 25)` measures for each nonzero channel and currently
provides twelve applications. Exact 0...100 formula values remain frozen even though inventory cost
uses four bands. UI evidence should show source identity, exact measures before/after, Resin,
applications, insufficient-stock rejection and atomic preparation. The twelve-use yield remains
DEBUG tuning; the four resource identities are current.

Schema/mechanical dispositions from the revised Game Design contract:

1. Authored ink is `nil | {cyan, magenta, yellow, depth, conversionVersion}` with four exact integer
   amounts in 0...100. It is not normalized into the generated-life CMY triangle.
2. Zero CMY with nonzero Depth is a valid explicit neutral-dark recipe; all four zero is invalid/no mixture.
3. Persist both authored provenance and the exact versioned resolved scope output.
4. Bind-time rules resolve `nil` from stable world/source identity and immediately persist the output.
   Viewport, catalogue order and redraw are never random authorities.
5. What numeric domain, quantization, gamut policy and mixing curve are player-visible? Existing 0...100
   Doubles and normalization are implementation precedent, not automatic writing authority.
6. Is `patterning` excluded from ink authorship? The new direction names CMY+Depth only; Asset will not infer
   texture/pattern from a pigment mix.
7. The first allowlist remains Sun/Smoke/Granite/Bloom, projected only into emitter/atmosphere/material/flora
   scope respectively. Flora color never projects into creatures.

Exact conversion coefficients, quantization, gamut policy, preset recipes and pattern derivation remain
open Asset/Engineering proof questions. No native integration is authorized yet.

Engineering and Design independently confirm the safest future type boundary, still recommendations-only:

- optional `AuthoredInk` (absence means ash/no instruction) must be distinct from the already-resolved native
  `Coloration` type;
- a separately persisted, versioned resolved declaration must record the scope output and whether it came
  from an authored mix or bind-time random resolution;
- authored ink should carry only the eventual CMY+Depth controls, never platform RGB, technical scope,
  patterning, palette metadata or ownership/acquisition state;
- resolved life identity may continue to carry normalized CMY, Depth and independently generated patterning.
  Existing creature/flora coloration remains historical resolved output and must never be reinterpreted as
  authored ink or rerolled;
- Bloom-like flora influence, if retained, should persist a source-level generation tendency and final
  per-species colors rather than painting every species with one vector.

Additional implementation gates found in source: native `Coloration` decoding currently accepts unnormalised,
negative, out-of-range and nonfinite channel values; it is therefore not a validation template. Any authored
recipe needs exact closed fields, finite/range validation and pinned quantization. A future bind transaction
must store its resolved declaration atomically with Essence spend; redraw-time seed derivation is conformance
evidence only and cannot be the persistence mechanism.

## 11 Aug 2026 — Writing-tool progression correction

Aimee settles **Rough charcoal → Brush → Fountain pen**. Brush replaces Pencil as the plain 2–3-cell
hand and is the first liquid-ink tool. Ink Mixing is a direct adjacent Scriptorium tier-1 unlock that
cannot be learned before Brush; it remains independent from Compound Assembly and Chaining.

Brush and Fountain pen use unlimited Ash/open ink by default and can use CMY+Depth mixtures only
after Ink Mixing. Rough-charcoal marks cannot carry liquid ink. Existing `Hand.plain` page geometry
remains unchanged and displays Brush; `pen_pencil` becomes one-way migration input for `pen_brush`,
not a permanently mismatched internal identity. Asset glyph/stroke proofs use dry crumb, bristle
spread and fine nib as the three distinct grammars. Exact current authority is
`writing-tool-progression-current.md`.

## 11 Aug 2026 — Handmade-art ownership boundary

Aimee owns final handmade visual art for characters, buildings/stations, weapons, inventory/items,
sigils and combat-node glyphs. AssetLab may retain basic functional placeholders for stable identity,
layout, collision, accessibility and integration wiring, but Asset/Design must not commission
aesthetic iteration, semantic pictogram candidates or competing final-art systems for those
families unless Aimee explicitly reopens one.

Asset Lead's ordinary autonomous scope remains functional UI, accessibility, layout, conformance,
world-color support and other specifically authorized generated-world systems. Placeholder quality
must be sufficient to test the game without becoming a shadow final-art queue. Game Design supplies
mechanical meaning, names, interaction states and collision requirements; those semantic contracts
do not authorize generated final art.
