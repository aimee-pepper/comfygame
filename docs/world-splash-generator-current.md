# World Splash generator — comprehensive functional authority

**Status:** Game Design generator and disclosure authority; supersedes the incomplete v2 splash-input coverage
**Priority:** third active implementation milestone, after terrain continuity and World field feedback;
before the broad player-control responsiveness migration
**Functional owner:** Game Design
**Visual owner:** Asset Lead after generator acceptance
**Implementation:** Engineering
**Updated:** 22 August 2026

## Player outcome

The World Splash is the first major payoff for writing a world. It must show the place that was actually
generated, not a generic landscape with a related tint.

The current implementation is functionally insufficient. It collapses the world to one dominant ground,
one coarse water relationship and at most four flora summaries, with no complete spatial-distribution
receipt. That permits a splash with no prominent pink growth even when the generated map is visibly
dominated by pink foliage.

The correction has four ordered stages:

1. Engineering freezes a comprehensive, disclosure-safe receipt and proves it with temporary placeholder
   parts.
2. Game Design and Aimee verify that the generator represents the real world and that the reveal has the
   correct information priority.
3. Asset Lead designs the final recolorable modular pixel-art system against the accepted receipt.
4. Engineering integrates the accepted art without changing receipt, disclosure or generation.

Asset work does not begin before stage 2. Atmosphere is not reopened as a separate milestone; the Splash may
represent only atmosphere and precipitation already generated and frozen by existing rules.

## Authority relationship and migration

This document supersedes only sanitized input coverage, generator acceptance and phone information priority
in world-arrival-causal-reveal-current.md and world-arrival-asset-packet-current.md. Those documents continue
to own bind atomicity, causal prose, History identity, pending-arrival lifecycle and accepted legacy proof
provenance unless directly contradicted here.

Existing v2 receipts remain decodable and playable. They are historical evidence, not sufficient input for a
new comprehensive Splash. New binds use world-splash-v3. A legacy receipt missing v3 coverage may show a
truthful text-first legacy arrival and enter normally; it may not synthesize plausible ecology from unknown
facts or block the run.

## Closed v3 receipt

One immutable WorldSplashReceiptV3 is created from the successfully generated, persisted world before the
bind mutation commits. Its canonical hash covers the normalized typed payload. Display consumes the receipt;
it never reruns Worldgen, re-bands values or samples new RNG.

### Identity and provenance

The receipt includes version, receiptID, worldSeed, worldVisualReceiptID, sourcePagePhysicalReceipt,
descriptionGrammarVersion and finalDescription.

The source Page retains only disclosure-safe physical Sigils and the label or ?? known at bind. Later
Dictionary learning does not rewrite the historical Splash.

### Terrain profile

The terrain profile contains:

- map width, height and non-chasm tile count;
- every GroundType with exact count and closed coverage band;
- dominant dry ground and deterministic secondary visible grounds;
- a disclosure-safe coarse region grid containing ground-share bands;
- one exact resolved WorldGrade2 material/recolor descriptor shared by the represented GroundType
  semantic-role families; each ground ID plus that frozen descriptor is the complete family render request,
  and neither receipt creation nor display duplicates or re-resolves it per family;
- independent snow and settled-Ash bands/distribution when generated.

The closed GroundType vocabulary remains stone, soil, sand, ice, ash, water, deepWater, rubble, mud, growth,
chasm and groundcover.

The receipt does not flatten mixed worlds to dominantGround. The coarse region grid is derived from actual
generated cells and preserves broad masses while omitting exact hidden interactable coordinates.

### Water profile

The water profile contains shallow, deep and frozen counts; coverage band; exact final connected-body
count; dominant topology; closed topology flags; and shallow/deep/frozen share bands by coarse region.

`connectedBodyCountBand` is undefined and deferred for v3. No rules-owned denominator or thresholds exist,
so the receipt, command generator, proof matrix and implementation must not emit or require a qualitative
band for the exact connected-body count. This does not relax water coverage: the exact count, coarse-region
shares, supported topology flags, semantic commands and all W01 through W04 evidence remain mandatory.

Legal topology flags include standing, flowing, pool, lake, channel, shelf, island and broken. They derive
from actual connected ground geometry, not color or prose. Ponds/lakes and channels/rivers are all legal when
Worldgen generated them. The contract prevents flowing water from becoming an unrelated pond and standing
water from becoming an unrelated channel.

### Relief profile

Relief derivation consumes every final generated cell's exact elevation `0...3`; it may not sample cells or
infer height from palette or ground family. The relief profile contains exact elevation counts for 0 through
3, maximum elevation, the canonically ordered sizes of cardinally connected components formed by all cells
above elevation 0, exact south-facing exposure-contact counts for depths 1 through 3, and elevation share
bands by coarse region. The already-disclosure-safe first-map crop retains its exact per-cell elevations.
Only real generated elevation owns relief. Equal elevation creates no wall.

For v3, `flat` is the only defined relief-shape label: it means every generated tile has elevation 0. The
previously listed `rolling`, `ridge`, `basin`, `shelf`, `enclosed` and `broken` labels have no settled
rules-owned topology or threshold. They are deferred, non-operative and not required or emitted by the v3
receipt, command generator, proof matrix or implementation. Their removal does not permit raw relief to be
collapsed: exact per-cell derivation, height counts, elevated connected components, south-facing exposure
depths, first-map continuity and regional distribution remain mandatory. A later authority may define
additional labels without reinterpreting an existing v3 receipt.

### Complete flora profile

The flora profile contains aggregate coverage, occupied tile count and every actually placed species. Each
species carries:

- species stable ID and persisted map render identity;
- form ID and exact resolved color roles;
- exact placed tile count and coverage band;
- rules-owned habit and eligible grounds;
- that species' share band in every coarse region.

Rules:

1. Include every persisted species with at least one actual placement. Do not use flora.prefix(4) or any
   other input truncation.
2. Render identity, form and resolved colors are the exact identities used by the first map renderer, not a
   second Splash classifier.
3. Spatial coverage derives from actual placements. Aggregate and species bands alone are insufficient.
4. Species order is placed count descending, then stable ID. Catalogue input order cannot hide a dominant
   species.
5. Habit changes with identical color/count alter only flora-distribution commands.
6. Zero-placement species are omitted. Names, metabolism, loot and hostility are excluded.

This profile must make the photographed pink-growth world visibly pink and growth-dominant.

### Environment profile

The environment profile contains resolved illumination band/source class, suspended-atmosphere
medium/density/motion and precipitation medium/intensity/motion.

These are already-resolved presentation bands. The Splash does not create weather, advance it, infer it from
palette or expose numeric pressures.

### Exploration-opportunity profile

The pre-exploration Splash truthfully reveals that generated sites exist and may call out exceptional
harvestable resource opportunities. This is an invitation to explore, not prior discovery and not a solved
map.

- `sites` contains every actually placed site profile with its exact placed-instance count, ordered by stable
  site-profile ID. A world with one or more sites always emits site-opportunity commands and visibly
  represents at least one site opportunity;
- `resources` is optional. A resource family is eligible only when it has at least one actually obtainable
  placed source and an existing rules-owned predicate classifies that opportunity as unusually rare/special
  or unusually abundant. Rows retain exact eligible-source counts and are ordered by stable resource ID;
- the current catalogue's authored `tradeBand == rare` or `tradeBand == precious` is the only exact v3
  rare/special predicate. `nontradeable` is not a rarity synonym. No current rule defines an unusually
  abundant world-relative resource threshold, so v3 emits no abundance-selected resource row. The branch is
  deferred and non-required until rules freeze its expectation and threshold; node-count tuning, total map
  share and ad hoc coverage bands may not substitute;
- the profile contains no tile coordinate, placed-instance ID, route, key, site contents, per-source yield,
  remaining-harvest count or search result;
- entry/exit portals are navigation infrastructure, not site opportunities, and do not enter this profile;
- deterministic placeholder commands and pixels must visibly respond to added/removed site profiles and
  eligible resource families. Ordinary resource families do not enter the Splash merely because a node or
  drop exists. Opportunity composition is representative and makes no claim about exact map location;
- relocating the same site/resource opportunities while preserving their stable profiles/families and counts
  leaves this aggregate profile and its placeholder output byte-identical.

The final Asset system will consume these same semantic opportunity requests after the generator is accepted;
Asset does not infer their identities or mechanics.

### Causal, entry and continuity data

- causalVisualFacts retain the existing known-only typed contract and own rules prose, not hidden map facts;
- entryMark is a projection, not a second persisted identity: when the frozen source Page has marks, it is
  the first mark in sourcePagePhysicalReceipt insertion order and contains only that already-disclosed
  footprint/material treatment; an empty Page has no entryMark;
- firstMapCropReceipt preserves the exact party-aware 9 by 9 disclosure boundary and the same terrain/flora
  render identities used above;
- site/resource opportunities use only the aggregate pre-exploration profile above; the first-map crop does
  not acquire their hidden coordinates.

## Explicit disclosure exclusions

The receipt and placeholder generator must not contain, count, silhouette, name or position:

- travellers, meetings or recruitment;
- ordinary creatures, apexes, combat groups or loot;
- quest state, hidden hazards or undiscovered Sigils;
- flora mechanics beyond visible form, color, coverage and habit.

For site/resource opportunities, only exact coordinates, placed-instance identity, routes/keys, site contents,
source yields and remaining-harvest state are excluded. Stable aggregate site profiles and eligible exceptional
resource families with their placed source counts are intentionally revealed before exploration.

Changing any excluded fact while legal v3 fields remain identical must produce a byte-identical receipt,
placeholder command list and rendered scene.

## Deterministic functional layer ownership

The temporary generator and later Asset compositor share these scopes:

1. terrainMass — ground census, region shares and material descriptors;
2. waterStructure — water topology and region shares;
3. relief — elevation distribution, connected components and south-facing exposure contacts;
4. surfaceDeposit — snow and settled Ash independently;
5. floraIdentity — exact persisted form and resolved color;
6. floraDistribution — coverage, habit and region shares;
7. illumination;
8. suspendedAtmosphere;
9. precipitation;
10. entryMark.

Each field has one owner. A single-scope counterfactual changes its owned commands plus only mechanically
necessary occlusion/composition output. It cannot recolor or rearrange unrelated layers.

The v3 placeholder renderer may use simple deterministic shapes. It is generator evidence, not an Asset
candidate and not production art.

## First-map continuity

The Splash is illustrative, not a literal map screenshot, but identity is exact:

- represented grounds use the same material descriptor as the map;
- represented flora use the same persisted render identity and resolved colors;
- shallow, deep and frozen water remain distinct;
- deposits and environment use the same semantic families;
- the first map crop after Enter World contains the same identities and palette roles as its v3 receipt.

Continuity compares semantic render requests, not approximate screenshot color. Placeholder Splash and first
map both resolve from the same typed identity receipt.

## Reveal information and behavior

The ordinary phone state contains, in priority order:

1. world/Page title;
2. generated-world scene as the largest single content region;
3. complete concrete two-sentence description;
4. compact source-Page provenance;
5. exactly one fixed Enter World action.

There is no unexplained empty body region while scene or description is compressed into a utility card.
Scene, title and description use the available decision area above the fixed action. Asset Lead owns exact
composition, frame, spacing and aesthetic hierarchy after the generator passes.

At ordinary 368 by 800, the scene is no smaller than the existing 320 by 200 presentation, description and
provenance are complete, and the fixed action neither covers content nor creates a decorative void.

The scene keeps an intelligible aspect and visible summary; text never shrinks, clips or becomes
horizontally scrollable.


## Exact acceptance matrix

| ID | Fixture or counterfactual | Required proof |
|---|---|---|
| S01 | Open Flats starter | Exact v3 receipt, placeholder scene and first-map continuity |
| S02 | Rainwashed Shore starter | Shallow/deep structure and frozen prose remain correct |
| S03 | Stone Hollow starter | Enclosing relief; ore remains prose-only, not a deposit icon |
| F01 | photographed pink high-coverage world | Pink flora dominates Splash and first map |
| F02 | same world, flora removed | Only flora commands and legitimate occlusion change |
| F03 | same count/form, color changed | Flora color changes; geometry remains identical |
| F04 | same identity/color, sparse to abundant | Coverage/distribution visibly changes |
| F05 | same coverage, clustered to spreading | Distribution changes without recolor |
| F06 | six-or-more placed species | Complete census retained; no four-species truncation |
| F07 | dominant species last in catalogue order | Output unchanged by input order |
| W01 | standing pool/lake | Standing broad body is legible |
| W02 | flowing channel/river | Connected directional channel is legible |
| W03 | mixed shallow/deep shelves | Depth regions remain distinct |
| W04 | frozen water | Frozen receipt does not reuse moving-water output |
| T01 | mixed secondary ground | Secondary mass remains visible |
| T02 | same geometry, opposed material descriptor | Geometry identical; palette roles change |
| T03 | snow only, settled Ash only, both | Independent deposits; base remains legible |
| R01 | flat vs generated depth 1/2/3 relief | Every final cell participates; exact height counts, elevated-component sizes, south-facing exposure depths, first-map elevations and regional commands agree; undefined shape labels are neither emitted nor required |
| E01 | illumination matrix | Environment-owned value changes only |
| E02 | existing atmosphere/precipitation matrix | Existing facts represented; no weather generation |
| O01 | add/remove one generated site profile at fixed terrain | Only site-opportunity receipt/commands and legitimate occlusion pixels change; profile/count is retained |
| O02 | add/remove one obtainable authored rare/precious resource family at fixed terrain | Only resource-opportunity receipt/commands and legitimate occlusion pixels change; family/count is retained |
| O03 | add/remove an ordinary, non-qualifying resource family | Receipt, commands and pixels remain byte-identical; ordinary presence alone is not a Splash hook |
| O04 | relocate identical site/resource opportunities | Receipt, commands and pixels byte-identical; no coordinate is persisted or implied |
| D01 | mutate traveller/apex or excluded site/resource details | Receipt, commands and pixels byte-identical |
| D02 | hidden crop terrain/flora mutation | Hidden cells remain coordinate/visibility only |
| C01 | exact first-map crop | Identity/palette parity for every disclosed cell |
| C02 | same receipt twice | Receipt, commands and RGBA byte-identical |
| C03 | title/description correction | Scene commands and RGBA unchanged |
| P01 | ordinary 368 by 800, light and dark | Correct priority, no void, one fixed action |

Every scope test records normalized input diff, ordered semantic-command diff and rendered-pixel diff. Green
unit tests without native evidence do not close P01.

## Staged implementation

### Stage 1 — Engineering generator proof

The smallest post-field-feedback Engineering slice is:

1. add WorldSplashReceiptV3 beside tolerant v2 decode;
2. replace flora.prefix(4) with complete placed-species census and coarse spatial profile;
3. derive terrain, water and relief from the actual persisted map without new RNG;
4. add a deterministic placeholder command generator and this matrix;
5. update native Splash to consume the placeholder and satisfy the functional information order;
6. preserve Enter World lifecycle and first-map identity;
7. build/install and stop for Game Design/Aimee coverage review.

No final Asset parts, visual polish, atmosphere milestone, hidden-site extension, creature ambience, mechanics
or balance change belongs here.

### Stage 2 — functional acceptance

Game Design and Aimee review native generator evidence, especially F01, F06, W01 through W04, C01 and
P01. The gate asks whether the reveal represents the generated world and gives the payoff proper
functional priority. It does not accept final art.

### Stage 3 — Asset visual system

Only after Stage 2, PM dispatches Asset Lead the frozen v3 schema, scopes, fixture matrix and native
placeholder evidence. Asset designs recolorable modular pixel-art terrain, water, relief, flora, deposit and
environment parts plus final visual composition. Asset may not change generation, disclosure or legal
actions.

### Stage 4 — frozen art integration

Engineering pins accepted Asset keys, replaces placeholder drawing through semantic keys, reruns the matrix,
installs in place and stops for Aimee's phone acceptance.

No stage may be skipped by declaring the old v0.3 proof sufficient; the photographed continuity failure is
new acceptance evidence.
