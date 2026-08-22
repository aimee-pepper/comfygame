# Writing Desk B1 implementation packet — current

**Status:** Game Design implementation authority for B1.5a
**Priority:** current first-three-world Engineering primary; E1/E2 are source-complete and E3–E7 finish the
native Writing flow before native world-arrival promotion
**Owners:** Engineering owns the rules/view model and native transaction; Asset owns the page, mark, tool,
ink and compact projection grammar; Game Design owns disclosure, hierarchy and copy
**Updated:** 21 August 2026

## Player result

The Writing Desk must feel like handling one physical page whose writing becomes one world. The player can
answer four questions without reading a parameter form:

1. **What page am I using?**
2. **What did I deliberately write?**
3. **What remains uncertain?**
4. **What will departure cost or require?**

The same page identity passes through **Write → The world → Bind & Depart → arrival → History**. Pages and
Templates are ways to obtain or reconstruct that page; they are not alternate world generators.

## Explicit non-goals

- no tutorial work;
- no automatic “best” composition;
- no raw pressure table, spawn count, seed, hidden POI or exact random roll;
- no second bind action at Home, in Pages or in Write;
- no editable collected World Page;
- no list row for every rune, projection field or inventory object;
- no Asset-authored forecast value or mechanically meaningful page position;
- no native arrival image in this checkpoint; successful commit emits its exact receipt to B1.6a.

## The two authorities that must remain separate

Engineering creates both values from the same selected page, but they have different jobs.

### Simulation source

The complete canonical page used to price and generate the world. This includes unread marks on a collected
World Page. It is allowed to determine the actual result; it is not automatically legal to display.

### Player disclosure

The subset the current campaign can legitimately interpret. Known meanings come from canonical writable
ownership and Reality encounters. An unread glyph remains visually present on the page but is labelled
`??`; its target, focus, qualifier, contribution, resource relationship and downstream effect are absent.

The projection UI consumes the player disclosure. It must never render a full canonical `BookProjection`
and try to hide leaked rows afterward. Redaction happens in the pure view-model factory before any player
string, accessibility value, icon label or sort key exists.

Native implementation uses `LibraryRules.dictionaryEntries(reality:base:)` as the single current knownness
projection for every page `LexemeIdentity`; it does not create a Writing-Desk-only knowledge flag. Current
targets and writable qualifiers are known, owned Sources/Compounds are known, and an encountered unowned
identity is visible only as `??`. A legacy `.rune(Sigil)` contributes separate source and target identities;
knowing one half never reveals the other.

## Source state machine

There is exactly one active review source:

```text
WritingDeskSource
  draft(pageRevisionID, frozenPageSnapshot)
  collected(instanceID, definitionID, canonicalDefinitionHash, frozenPageSnapshot)
```

| Player action | Resulting source | Mutation |
|---|---|---|
| Open Writing Desk normally | current draft | none |
| Write, move, connect, disconnect, recolor or clear a mark | current draft with new revision | only the draft edit |
| Load a Template | reconstructed draft with new mark/link instance IDs | one atomic draft replacement after any required confirmation |
| Tap a collected World Page | exact owned instance | inspection may record encountered glyph identity; no consumption or meaning grant |
| Pages → The world | selected collected instance | none |
| The world → Pages | preserve the selected collected instance for this presentation session | none |
| Enter Write from a collected-page review | current draft | clear only the ephemeral collected selection |
| A collected instance disappears or its canonical hash changes | unavailable state | no fallback to the draft and no bind |
| Bind succeeds | same reviewed source | atomic transaction below |
| Bind fails | same reviewed source | no mutation except a displayed refusal |

Templates are never a third source kind. Loading one reconstructs the draft and returns to **Write**. A
collected World Page is never copied into a Template.

## Pure review model

The three panes read one `WritingDeskReviewModel`. It is rebuilt from current authoritative state and has no
mutation methods:

```text
WritingDeskReviewModel
  sourceKey
  sourceRevisionOrDefinitionHash
  sourceKind: draft | collected
  title
  pageThumbnail: redacted physical-page receipt
  visibleMarkCount
  unreadMarkCount
  knownRequests[]
  openSubjects[]?
  uncertaintyReason
  stabilityRange
  collapseRange
  sightDisclosure
  dangerDisclosure
  ecologyDisclosure
  knownPreparation[]
  analysisSections[]
  costQuote
  fieldKitSummary
  anchorOption?
  bindAvailability
```

`pageThumbnail` is not a canonical `Page`. It contains only physical rendering facts: page dimensions;
stable mark instance IDs; opaque visual-asset keys; hand; origin; frozen shape/cells; authored ink; and link
endpoint instance IDs. It never carries `MarkContent`, `Sigil`, source/target/qualifier/compound identities or
personal-compound expansion into the player-facing model. A visual-asset key is explicitly forbidden as
player copy, a sort key or an accessibility value even when an existing key happens to match a semantic
catalogue ID.

`openSubjects` is nullable. It may list exact untouched subjects only when every relevant mark on the page is
readable. If any mark remains unread, show `Some of this page is still unread` rather than using subtraction
to reveal what those marks affect.

An unread semantic mark also forbids a canonical-hidden value from narrowing the headline risk. In v1 that
review model uses disclosure-safe `Stability 0–100` and a typed collapse bound from
`BookRules.turnsAvailable(0)` through **indefinite**. Its copy is
`Collapse may begin after about {lower} turns, or the world may hold indefinitely.` Sight and danger use one
unread-page sentence rather than a hidden-derived band. Exact physical cost remains legal. Two different
canonical hidden pages with the same visible/unread surface must produce identical review fields and player
strings. This equality includes ecology/life copy: an unread Vitality mark may not change the disclosed text
relative to an unread non-Vitality mark. Once every mark is known, ordinary readable-page bounds apply.

### Field disclosure table

| Field | Always legal | Legal only when known/authored | Never pre-bind |
|---|---|---|---|
| Page | physical thumbnail, visible glyphs, links, tool/ink appearance, mark count | glyph names and meanings | hidden meaning in labels or accessibility |
| Cost | exact total; current Essence → after-departure Essence | exact prepared-ink applications when that recipe is known | a cost different from commit authority |
| Stability | honest worst–best range and approximate collapse range | Tier-4 causal breakdown for legitimately readable/calibrated facts | seed-resolved point value while uncertainty remains |
| Requests | readable subject/focus/qualifier chains in page order | learned secondary effects behind the settled analysis/calibration tier | raw source/target IDs or unknown contributions |
| Open dimensions | exact subject names only when the complete page is readable | `N subjects left to the world` when that count itself is disclosure-safe | identities rolled for those subjects |
| Sight | authored known trade or an honest range | exact clear-sight value only when the rules prove the page fixes it | peeked-seed Illumination presented as authored certainty |
| Danger | known authored danger relationship or honest bounded/open wording | exact tier only when fixed by readable writing | random creature count, species or apex promise |
| Harvest | known tendencies caused by readable requests | extraction requirement for a known deliberately requested resource | percentages presented as guaranteed loot; hidden resource identity |
| Life/flora | qualitative tendency when Vitality writing is readable | Tier-5 allocator tendency after its real unlock | exact cast, species, defence or metabolism identity |
| Cycle | nothing when open/unmeasured | qualitative band only after authored Cycle plus required calibration | peeked-seed clock schedule |
| Sites/people | nothing | a future explicitly authored/disclosed World Page landmark under its own authority | generated site, traveller or portal location |

The next bind seed may be peeked internally to produce an atomic quote, but that fact does not make its
rolled values player-readable. Prediction and disclosure are separate permissions.

## Exact projection language

### Source header

- Draft with no saved name: **Current page**.
- Loaded Template: still **Current page**; one secondary line may say `Loaded from {Template name}` until the
  first edit. The Template is provenance, not live linkage.
- Collected page: exact frozen title plus `Collected World Page · consumed only when departure succeeds`.
- Unread collected page: title may remain **Unknown page** until inspection; no canonical title in VoiceOver.

### What the page says

Render readable requests in source-page order, one compact two-column collection where space allows:

```text
{Subject icon} {Subject}
{Focus}; {qualifier summary}
```

Do not print numerical pressure contribution at the opening analysis tier. An inert or unjoined known mark is
shown once beneath the collection: `{N} placed marks are not connected into a request.` Unknown marks are
counted separately: `{N} marks remain unread.`

Only the target actually used by a request, its displayed sources and qualifiers directly attached to those
sources are represented by that request. An extra target in the same connected component, or a qualifier
attached to the target/another qualifier rather than its source, remains in the inert/silent count. Merely
belonging to the same graph component cannot make an ignored mark disappear from the player's explanation.

### What remains open

- Empty readable draft: `Nothing is written yet. Every subject is left to the world.`
- Fully readable partial draft: `{N} subjects are left to the world: {ordered subject names}.`
- Fully specified readable draft: `Every subject is written.`
- Any unread mark: `Some of this page is still unread. The world may answer it in ways you cannot interpret
  yet.` Do not print an open-subject count in this state.

### Risk

Always show:

- `Stability {low}–{high}` or a point only when the range genuinely closes;
- `About {low}–{high} turns until collapse`;
- `May hold indefinitely` instead of the internal sentinel;
- one concise danger/sight line following the disclosure table.

`Stability` and `turns until collapse` are distinct. Neither becomes `turns left` after arrival.

### Preparation

Show only actionable facts before departure:

- known gated-resource tool warning from `resource-extraction-progression-current.md`;
- exact Field Kit readiness/refusal from the current atomic quote;
- known prepared-ink shortfall;
- active-expedition, insufficient-Essence or Anchorage refusal.

Do not show generic advice, all possible loot, creature predictions or a checklist of every system.

## Ordinary-phone composition

### Shared shell

- Native navigation back control, then one **Write / Pages / The world** segmented control in the navigation
  principal area. Do not repeat the screen title beneath it.
- Changing panes dismisses any page connect/disconnect/drag state and any anchored item detail.
- Tutorial, if it is eventually revisited, is always a non-displacing overlay and is not part of B1.5a.

### Write

1. The complete 6×6 page is always visible above the palette. Size it from the remaining viewport, align cell
   edges to whole device pixels and cap it near 48% of available body height; never crop its final row.
2. Immediately beneath it, one 38–44 point writing-tool/Ink Well strip shows current hand and ink state.
3. Then one 44-point horizontal subject-bin strip with a visible continuation peek.
4. The remaining height is the independently scrolling current palette.
5. At 368 points, rune/focus choices use exactly three recognizable tiles across, each at least 104 points
   wide and 58 points tall. Glyph and name lead; footprint and known stability trade are subordinate.
6. Clear and Save Template remain compact navigation actions. Neither creates a second bottom bar.
7. There is no Bind button in Write.

Tapping outside the page while connect/disconnect/placement mode is active cancels that mode. Changing bin,
pane or navigation route also cancels it.

### Pages

- Nested **Collected / Templates** segmented control.
- Two physical-page cards across at ordinary phone width; thumbnail dominates, then title and one state line.
- Collected card line: exact bind cost. Template card line: mark count.
- Tap collected page inspects/selects it and opens **The world**.
- Tap Template opens its anchored action popover: Load, Rename, Overwrite, Delete. Load is the leading action.
- Edge and bottom popovers remain fully on screen. Loading over a nonempty different draft uses the settled
  `Replace current draft?` confirmation, then returns to Write.

### The world

The body scrolls independently above one fixed bind bar. In this exact order:

1. **source card:** 72–88 point page thumbnail, title/source kind and exact cost;
2. **What the page says:** compact request tiles;
3. **What remains open:** one concise state;
4. **Risk:** Stability/collapse plus disclosed sight/danger;
5. **Preparation:** only current actionable facts;
6. **Further reading:** collapsed by default, containing the player's genuinely unlocked Tier 2–5 analysis.

Do not embed the existing full `PreviewPanel` as one long rounded card. These sections use the page surface
as their common visual container; they are not six unrelated full-width settings cards.

The fixed bar contains:

- optional **Born anchored** toggle only when Anchorage is unlocked;
- one line `Essence {current} → {after}` or the exact refusal;
- one 50-point **Bind & Depart** button.

The bar never covers the final scroll content. At 368×800, the source card, What the page says heading, risk
headline and complete Bind button must be visible without scrolling for a starter page. Longer analysis and
preparation may scroll; the primary transaction may not.

## Atomic bind handoff

The visible availability and commit consume the same staged quote:

```text
BindQuote
  quoteVersion
  sourceKey + revision/hash
  reservedCampaignSeed
  generationSeed
  frozenPageHash
  availableEssence + pageCost + anchorPremium + totalCost + essenceAfter
  anchorageReceipt
  preparedInkReceipt[]
  fieldKitReceipt
  availability/refusal
```

This is a rules-internal transaction object, not a player-disclosure model. Its exact receipts are:

- draft source: full current-page revision hash; collected source: physical instance ID, definition ID and
  exact canonical-definition hash;
- `reservedCampaignSeed`: the next campaign seed which every successful bind consumes exactly once;
  `generationSeed`: that same seed for a draft or the frozen authored seed for a Collected page;
- `frozenPageHash`: the complete selected page, including links, Hand, shape, personal snapshot and ink;
- Essence: the exact current wallet, component costs, total and resulting wallet shown by the fixed bar. A
  still-affordable wallet change is stale; it never silently commits under an old `current → after` line;
- Anchorage: requested boolean, current station entitlement and the exact premium derived from this page;
- ink: deterministic recipe order, then exact vial IDs in ascending stable-ID order, each vial's recipe,
  including conversion version, before applications, consumed applications and after applications.
  Aggregate matching stock is not enough; CMYD ties use conversion version as their final stable order;
- Field Kit: confirmed loadout revision, satchel capacity, exact source stack IDs/counts, exact packed split and
  exact remaining Home inventory; and
- current absence of an active expedition plus the complete typed refusal when any gate fails.

The quote owns no RNG stream beyond the two explicit seed values and mutates nothing. Its deterministic ink
and item ordering prevents a rebuild from selecting different equivalent stock and appearing stale. Player
copy reads only the disclosure-safe review model and the quote's exact cost/readiness summary; vial IDs,
inventory fingerprints and hidden seeds never enter labels or accessibility.

On activation, Engineering rebuilds and compares the complete typed quote. Before any save mutation it must successfully
construct the complete world, `WorldVisualReceipt`, `WorldArrivalReceipt` including grammar v1 description,
and exact first-map state. The single atomic mutation then:

1. consumes the reserved campaign seed;
2. spends page cost, anchor premium and prepared ink;
3. moves the staged Field Kit;
4. consumes the exact collected page instance if and only if that was the reviewed source;
5. records immutable History provenance;
6. creates the active run and pending arrival reveal.

A normal draft remains on the Writing Desk after binding so it can be edited or deliberately reused; the
world and History freeze their own copy. A collected World Page disappears because its exact physical
instance was consumed. Any stale source, failed generator/adapter, insufficient resource or changed Field Kit
returns one exact refusal and changes none of the six steps above.

The commit compares again inside the one synchronous state mutation before spending the first vial or moving
the first stack. A different-but-equivalent vial or stack plan is a stale quote and is rebuilt for a second
attempt; it is never silently substituted. A double activation sees the first active-run/consumed-source
result and becomes a typed no-op. Generator, visual-receipt or arrival-description construction cannot write
to campaign state, advance a seed, consume a physical Collected page or emit a durable History record on its
own.

## Asset production boundary

Asset supplies a composable Writing Desk kit, not three painted screenshots:

- page/paper surface and 6×6 placement sockets;
- Rough Charcoal, Brush and Fountain Pen mark treatments using the same placed-mark geometry;
- Ash/open ink plus scoped mixed-ink treatment without recoloring the whole page;
- known, encountered-unknown and unavailable glyph states;
- link, selected, legal placement, illegal placement, connect and disconnect states;
- compact subject/focus/qualifier tile family;
- current-page, collected-page and Template thumbnail frames;
- restrained risk/open/preparation section grammar and fixed bind bar.

Every production bitmap or command record has a stable ID, native dimensions, pivot/attachment where
applicable, deterministic source and lossless RGBA output. CSS/div mock shapes, SF Symbols and screenshot-only
art are evidence aids, not production assets.

### Native production-pack seam

The accepted A1 and A2 JavaScript compositors are Asset authoring tools, not an iOS runtime dependency. The
native app must not execute JavaScript, copy proof phone PNGs, or reproduce the glyph, footprint, stroke,
overlay, link, thumbnail or chrome drawing algorithms in Swift. Before native view integration, Asset exports
one deterministic `WritingDeskProductionPack` v1 from the frozen accepted sources; Engineering consumes that
pack through one closed, fail-closed adapter.

The v1 pack contains:

- the exact blank 172×172 page, unread marker and three writing-tool silhouettes;
- one stable-key mark record for every current target, source, qualifier and compound lexeme in Rough
  Charcoal, Brush and Fountain form — 108 lexemes × three hands at the current catalogue receipt — including
  its exact cell footprint, bounds and shape identity;
- explicit tint-role masks for player-mixed ink and separate fixed-detail roles where a hand treatment owns
  non-tinted dark pixels. Native code supplies only the already-resolved game-owned ink colour to the declared
  tint role; it does not recolour paper, chrome, state or unread pixels;
- a complete stable-key map from every distinct hand footprint to each of the six accepted independent state
  overlays;
- one horizontal and one vertical cardinal connector in each hand. Runtime links exist only where occupied
  cells touch cardinally, matching `PageRules.areAdjacent`; A1's long diagonal linked composition is a
  stroke-style proof, not a legal runtime page. When two multi-cell marks share more than one edge, the
  renderer chooses one edge by shared-edge midpoint in reading order — top to bottom, then left to right,
  with the horizontal edge first only if a malformed case produces the same midpoint. The connector uses the
  coarsest endpoint hand (`Rough Charcoal` before `Brush` before `Fountain`), remains Ash/open neutral, and is
  drawn above paper but below the two marks so its ends tuck beneath their strokes. Nonadjacent or unresolved
  contact fails closed. This needs no new `MarkLink` persistence field;
- every vocabulary-tile combination needed by the live catalogue: lexeme × current hand × known, unknown,
  unavailable or selected. Semantic names and explanations remain native game text and are never baked into
  these images;
- exact tool/ink chrome with declared tint sockets; Collected and Template card shells with a transparent
  62×62 page-thumbnail socket and an exact nearest-neighbour sampling map from the already-composed page;
  and the accepted two-, three- and four-row popover shells plus all four pointer variants; and
- one closed versioned manifest containing stable keys, native dimensions, hashes, role masks, pivots/insets,
  socket coordinates, thumbnail mapping, accepted A1/A2/A3 source hashes and lookup tables. Unknown versions,
  duplicate keys, missing files, unexpected files and hash mismatches refuse the adapter rather than falling
  back to approximate native drawing.

A3 contributes responsive layout geometry, ownership and composition rules; none of its phone screenshots is
production input. Runtime page thumbnails are composed from the exact current page, so blank/partial/dense
proof-card screenshots are not shipped as substitutes for player state. The pack exporter proves exhaustive
108×3 mark lookup, all six cardinal hand/orientation connectors plus deterministic contact-edge selection,
both one- and multi-cell state coverage, crop/bounds safety,
mixed-ink containment, representative runtime thumbnail composition, literal grayscale and byte-identical
repeat export. This packaging gate changes no accepted pixels or visual semantics and remains
`integrationReady:false` until Game Design reviews the generated pack and Engineering verifies its loader.

### Ordered Asset checkpoints

Asset works through these gates in order. Passing a later screenshot cannot rescue an earlier unreadable
production part, and no checkpoint authorizes native/PBX integration.

#### A1 — physical page and writing-hand style gate

Deliver one reusable **172×172 logical-pixel** page shell intended for exact 2× presentation at ordinary
368-point phone width. It has a 162×162 writing area arranged as six 27×27 placement sockets inside a
5-pixel paper margin. The grid is a faint ruled/pressed guide on one continuous piece of paper, not 36
separate square tiles. Socket boundaries may guide placement but must not visually dominate written marks.

Deliver reusable mark/link/state parts against that same geometry:

- `writing.page.blank` — warm fibrous paper with restrained worn edges; no prewritten symbols;
- `writing.hand.charcoal` — Rough Charcoal's dark, slightly broken 2–3-pixel stroke with sparse smudge and
  pressure variation; it remains legible when several cells are occupied and never resembles a disabled
  state;
- `writing.hand.brush` — a controlled 2–4-pixel wet stroke with tapered ends and small pigment-density
  variation; Ash uses a neutral soot/umber writing colour while mixed ink colours **only the mark**;
- `writing.hand.fountain` — the most precise 1–2-pixel line, with a deliberate nib start/finish and enough
  local value contrast to remain legible over the same paper;
- one undirected link grammar whose endpoints meet the actual mark strokes and remain distinguishable in
  charcoal, brush and pen forms;
- selected, legal-placement, illegal-placement, connect-source, connect-target and disconnect states as
  independent overlays rather than recoloured page screenshots; and
- a small independent unread-state marker for an encountered-but-unknown glyph. The physical glyph itself
  remains visible and unchanged; do not replace it with `?`, reveal its category by silhouette, or make an
  unknown mark resemble an unavailable palette choice.

Ash is the standard visually dark writing medium but semantically leaves world colour open. No page, frame,
background or forecast becomes black because Ash is selected. Mixed-ink evidence uses exact Cyan, Magenta,
Yellow and Depth inputs already owned by `InkRecipe`; Asset does not implement another colour model.

The A1 proof contains, at minimum:

1. blank page at exact native and ordinary-phone 2× scale;
2. the same four disclosed glyph footprints in Rough Charcoal, Ash Brush and Ash Fountain Pen;
3. the same Brush glyph in three explicit mixed inks plus Ash/open, changing only mark-owned pixels;
4. one dense legal composition touching the first and last page rows with no crop;
5. legal/illegal/connect/disconnect overlays on the same composition;
6. one encountered-unknown mark beside a known mark, with no semantic label leakage; and
7. literal grayscale and a collision/socket overlay proving all 36 exact tap regions remain in bounds.

Production source must be exact logical RGBA bitmaps or deterministic integer-pixel commands with bounded
reviewed palettes. A generated composition reference may guide style only and must be declared
`productionSource:false`; downsampling a large generated image is not a production source.

Asset stops for Game Design visual review after A1. It does not draw palette tiles, cards or full phone
screens until the page/hand grammar is accepted.

##### A1 v0.1 disposition — held for correction

The 172×172 shell, exact sockets, deterministic part/export structure, CMYK+Depth mark-only recolouring,
first/last-row bounds, separate unread marker and broad Charcoal/Brush/Fountain stroke direction are the
right foundation. The candidate is not production-ready because it uses four invented one-cell
`glyph-a`…`glyph-d` identities, so it neither consumes the real lexeme vocabulary nor demonstrates the
mechanical writing-hand progression. Its dense independent paper stipple also competes with Fountain strokes
and reads closer to sand than a quiet fibrous sheet; placement guides are effectively absent. Several
selected/legal/connect overlays separate mainly by hue and become ambiguous in literal grayscale.

Correct the same A1 checkpoint with these additional authorities:

- production glyph identity is a deterministic `writing-glyph-v1` canonical skeleton keyed by the real
  stable lexeme ID; the same skeleton survives every hand treatment, all current stable lexeme IDs resolve
  collision-free, and an unknown ID fails closed;
- the comparison fixtures use exact current IDs `plains`, `verdant`, `archipelago` and `caverns`, not
  substitute A–D labels. A full current-lexeme census proves deterministic identity and collision freedom;
- hand progression uses actual game-owned `PageRules`/`rune_shapes.json` receipts: Rough Charcoal renders
  the rune across its deterministic `crude` 4–6-cell footprint, Brush across its `plain` 2–3-cell footprint,
  and Fountain Pen inside its `refined` one-cell footprint. The written mark visibly occupies the complete
  mechanical footprint; a hand is not represented as a one-cell glyph with only a thicker line;
- obtain those footprint receipts from a read-only live bridge or exact frozen game output. Asset does not
  select convenient footprint shapes or alter Page placement rules;
- replace dense independent speckles with sparse coherent paper fibres/creases and leave most interior
  pixels quiet. Add five faint ruled or pressed guides per axis at the exact 27-pixel socket boundaries;
  they must remain visible at 2× and in grayscale without making the page look like 36 separate cards;
- strengthen Fountain's dark core so every stroke separates from the darkest legitimate paper fibre in
  literal grayscale; and
- use redundant state geometry: selected four-corner brackets, legal four inward ticks, connect source a
  dashed enclosure, connect target paired endpoint dots/wedges, illegal an X and disconnect a slash across
  the actual link/footprint.

Add one same-real-rune three-hand footprint comparison and one multi-cell linked composition to the existing
A1 evidence. Preserve every accepted dimension, ink ownership, disclosure, collision, determinism and
clean-baseline gate. A1 remains `integrationReady:false`; A2 is not released.

##### A1 corrected-candidate disposition — held for final state legibility

The corrected candidate establishes the intended page and writing grammar: a quiet fibrous sheet with five
guides per axis; real `plains`, `verdant`, `archipelago` and `caverns` identities; one deterministic
`writing-glyph-v1` skeleton across all 108 current lexemes; fail-closed unknown identities; exact
PageRules-derived six/three/one-cell compound footprints; readable Charcoal, Brush and Fountain treatments;
mark-owned CMYK+Depth colour; a separate unread marker; and an in-bounds multi-cell link. Those parts are
accepted and must not drift during the final A1 correction.

A1 remains held because the legal-placement ticks and connect-target endpoints are too faint at exact phone
scale, especially in literal grayscale, and the purported dense first/last-row fixture contains only four
corner marks. Correct only these contained issues:

- legal placement uses four compact inward-facing two-stroke chevrons outside the mark, with enough neutral
  value contrast to remain visible against both paper and dark ink without relying on green;
- connect target uses paired filled inward endpoint wedges or diamonds, each with at least a 5×5-logical-pixel
  visible extent, outside and separate from the physical mark;
- the dense edge fixture contains exactly twelve legal one-cell Fountain marks: one in every column of row 0
  and row 5, cycling the four disclosed proof lexemes in page order, with color and literal-grayscale evidence;
  and
- the focused state gate compares all six overlay geometries pairwise and enforces meaningful opaque-pixel
  minima for legal and connect-target states rather than merely finding any nonzero alpha.

Preserve selected brackets, connect-source enclosure, illegal X and disconnect slash unchanged. A2 remains
blocked until the corrected state and density evidence passes visual review; A1 remains
`integrationReady:false` and authorizes no native, PBX or golden promotion.

##### A1 final disposition — accepted Asset candidate

Game Design visually accepts the corrected physical page and writing-hand kit with canonical body SHA-256
`89ae14e9f0ecfdee5e35ced08df0f9d9ba76e224fc4908be271f50c1bd01a627`, manifest-file SHA-256
`6a8eff7e038f7789a1839ab7c5537f1847163bd1f4d311cecdc46e983793801d` and unchanged lexeme receipt SHA-256
`4126428ef7d5f00891a4afc267f42f0db4fe0320cb1088d5d75e40d2512904f3`. Legal chevrons and paired
connect-target diamonds remain distinct in literal grayscale, and the dense proof now contains all twelve
edge-row marks without crop. Asset checkpointed the exact five-path boundary as commit `0eb2720e` on
`codex/preserved-shared-dirty-20260820`. This accepts the candidate as the frozen input for A2 only. It
remains `integrationReady:false` and does not authorize native, PBX, golden or A3 work.

#### A2 — vocabulary, page-card and tool-strip kit

After A1 acceptance, reuse its glyph/mark language to deliver:

- 104×58-point-at-phone subject/focus/qualifier tiles, exactly three across at 368 points;
- known, encountered-unknown and genuinely unavailable palette states without semantic leakage;
- a 38–44-point writing-tool/Ink Well strip showing Rough Charcoal, Brush or Fountain Pen plus Ash/open or
  explicit mixed ink;
- current-page, collected-page and Template physical thumbnail frames derived from the same paper;
- exact two-across Collected/Template cards whose page thumbnail dominates title and one state line; and
- anchored action-popover chrome with above/below and left/right edge variants that remain on screen.

Do not invent a conventional settings form, full-width rune list, second bind button, generic gear-card
frame or novel icon vocabulary. A2 stops for review before integrated screens.

##### A2 exact production matrix

All A2 raster parts use integer logical pixels and are reviewed at exact 2× phone presentation. Native text
is composited by the app into declared text reserves; Asset does not bake English labels into production
sprites. Proof annotations may sit outside the reviewed part.

**Vocabulary tile.** One production shell is exactly **52×29 logical pixels**, presented at **104×58
points**. Three tiles fit the 344-point ordinary-phone body as `8 + 104 + 8 + 104 + 8 + 104 + 8`.

- reserve a left 18×21-logical-pixel well for the actual A1 glyph treatment;
- reserve the upper-right area for the native name and the lower-right area for one actual six-by-six
  footprint microdiagram plus at most one short known trade line;
- target, source/focus, qualifier and compound use the same outer shell. Category-colored or
  category-shaped chrome would reveal an encountered unknown and is prohibited;
- **known** shows the physical glyph unchanged, its legitimate name and footprint;
- **encountered unknown** shows the same physical glyph unchanged and `??` in the name reserve. It has no
  category badge, semantic icon, effect line or category-specific sorting surface;
- **known but currently unavailable** keeps the glyph and name readable and places one closed cord/tab
  across only the footer/action reserve. It never veils the glyph and never resembles the unread marker;
- **selected** uses a pressed double-outline/corner treatment outside the glyph well; and
- footprint cells are the exact current Hand receipt, not an Asset estimate. A Hand change recomposes the
  tile from the same A1 glyph skeleton.

Unknown entries never appear inside a Subject/Focus/Qualifier bin whose heading would reveal their category.
They may appear only on a physical collected page, in the neutral Dictionary unknown collection, or in a
neutral unknown reference surface. The Writing palette contains things the player can actually write.

**Writing-tool and Ink Well strip.** One shell is exactly **172×22 logical pixels**, presented at
**344×44 points**. It is one compact control, not three full-width buttons.

- the left 20 logical pixels hold one physical tool silhouette: blunt broken charcoal, tapered bristle brush
  on a wooden handle, or metal nib and pen body;
- the center is a native text reserve for `Rough charcoal`, `Brush` or `Fountain pen`;
- the right 42 logical pixels are the Ink Well/sample reserve. Ash/open is a dark neutral well plus an
  uncoloured paper sample and never a black-world swatch; explicit ink changes only the liquid and sample;
- prove Rough Charcoal/Ash, Brush/Ash, Fountain/Ash and Brush with three exact A1 CMYK+Depth recipes. Hand
  silhouettes and the mixed/Ash distinction must survive literal grayscale by shape/value, not hue alone;
- do not add hand power ranks, world-colour forecasts or a second colour model.

**Collected and Template cards.** Each reusable card shell is exactly **82×88 logical pixels**, presented at
**164×176 points**. Two cards plus an 8-point gap fill the 336-point body inside normal 16-point screen
margins. A 62×62-logical-pixel square thumbnail reserve dominates the upper card; native title and one state
line occupy the footer.

- the thumbnail is composed at runtime from the actual A1 page, not selected from painted page states;
- a Collected card is one worn physical page with a restrained deckled/folded edge and no duplicate sheet;
- a Template is a reusable tracing: two slight offset vellum sheets plus registration corners. This visual
  promise is valid because Load reconstructs the complete draft immediately;
- outer silhouettes, not color, distinguish Collected from Template;
- selected and unavailable overlays are independent. An unavailable/stale Collected page must retain its
  frozen visible thumbnail and title while its action state explains that it cannot be bound;
- do not place a Bind button, resource promise, creature silhouette or destination thumbnail on either card.

**Anchored action popover.** Supply one stretchable logical-pixel paper body, one dark edge, and independent
5×3-logical-pixel pointer parts for above-left, above-right, below-left and below-right anchoring. Engineering
composes native 44-point action rows and chooses the variant that keeps the complete popover at least 16
points from every phone edge. The part supports two through four rows without scaling its border. It contains
no baked arrows or action text. Load is the leading Template action; Rename, Overwrite and Delete follow in
that order. Delete uses ordinary destructive confirmation rather than alarming decoration on the card.

##### A2 required evidence and gates

1. exact 2× three-across row with known, encountered-unknown and known-unavailable states using the same
   physical glyph, plus literal grayscale;
2. all 108 current lexemes passing through the tile compositor without collision, crop, fallback art or
   category-coded unknown chrome;
3. the same real rune under all three Hand/footprint states inside the tile shell;
4. the 344×44 tool strip in all three Ash/open Hand states and three explicit mixed Brush inks, color and
   grayscale;
5. runtime-composed Collected and Template cards showing blank, partial and dense pages, including selected
   and stale/unavailable overlays;
6. two-across card geometry at exact ordinary-phone width with no crop or horizontal scrolling;
7. all four popover edge variants attached to first/last-row cards inside a 368-point viewport, with every
   native action hit region at least 44 points and wholly on screen; and
8. deterministic repeat export, binary-alpha/palette bounds, pairwise non-color state signatures and a clean
   full AssetLab baseline.

The A1 canonical body and lexeme receipt are immutable inputs. A2 may import them but may not redraw or
fork the page, mark, link, ink, unread-marker or interaction-state grammar. A2 remains
`integrationReady:false`, stops for Game Design review and authorizes no A3/native/PBX/golden work.

##### A2 v0.1 disposition — held for tool-silhouette correction

Game Design accepts the vocabulary compositor, all 108 lexeme receipts, known/unknown/unavailable/selected
tile distinction, Hand footprint diagrams, compact Ink Well/sample behavior, runtime page cards, physical
Collected-versus-Template distinction, two-across geometry and all four edge-safe popover placements in
candidate body SHA-256 `76acd55ca862319477480fa827d7623066d407a48a82fff379be33c30e61d4ca`.
Those parts and every A1 input remain frozen.

A2 is held because Rough Charcoal, Brush and Fountain Pen currently read as three diagonal line variants in
the left tool slot. Correct only those three physical silhouettes within the existing 20×18-logical-pixel
reserve: a short irregular 3–4-pixel-thick broken charcoal stub with blunt/chipped writing end; a slim wooden
handle, distinct ferrule/knot and broad tapered bristle tuft for Brush; and a straight barrel plus visibly
wider 5–7-pixel metal nib with shoulders, point and one-pixel split/vent for Fountain Pen. Supply label-free
exact-2× and true-400% three-tool comparisons in color and literal grayscale, and require pairwise different
non-color masks/bounds. Preserve the strip shell, text/Ink reserves, all non-tool strip pixels, every
tile/card/popover and every A1 byte. A2 remains `integrationReady:false`; A3 stays blocked.

##### A2 final disposition — accepted Asset candidate

Game Design visually accepts the corrected A2 kit with canonical body SHA-256
`19f45f8188fd99a9308ac2b3d29adfde070a5971eb103ea86a8310e754821b90` and manifest-file SHA-256
`9e7c00c5fda50eeb0c7ecc7ccbe3538a962987e6fbc797d9b5af1abc0af6e1bf`. The exact 2× and true-400%
evidence now reads as three separate physical tools in color and literal grayscale: short chipped charcoal,
handled/bristled Brush and barrel/split-nib Fountain Pen. All vocabulary tiles, runtime cards, popovers,
non-tool strip regions and frozen A1 inputs remain unchanged. This accepts A2 as the immutable input for A3
only. Asset checkpointed the exact five-path boundary as commit `d0b1359c` on
`codex/preserved-shared-dirty-20260820`. It remains `integrationReady:false` and authorizes no native, PBX
or golden promotion.

#### A3 — integrated Write / Pages / The world proof

After A2 acceptance, compose the reusable kit into the exact three-pane 368×800 fixtures in this packet.
The world pane uses one common page surface, compact request tiles, concise open/risk/preparation sections
and one fixed bind bar; it is not a stack of unrelated full-width cards. The proof must exercise actual
short/long copy, starter-page unknown disclosure, edge popovers, the complete first/last grid rows and the
fixed Bind & Depart action. Screenshots are evidence only; A1/A2 parts and a pure deterministic compositor
remain the production deliverable.

##### A3 exact 368×800 composition

Use the native status/safe areas and one 52–56-point navigation bar. The Back control owns the leading
44-point hit region. **On Write only**, one trailing 44-point page-actions menu owns **Save Template** and
**Clear**; Pages and The world show no empty ellipsis or inert reserved action. The principal area contains
the single **Write / Pages / The world** segmented control. There is no repeated `Writing Desk` body title.
Switching panes cancels placement/connect/disconnect state and closes anchored details before changing
content.

All body measurements below are points at the exact 368×800 proof size. When a safe-area value differs on a
real phone, Engineering measures the remaining viewport and preserves the same ownership/order rather than
scaling a screenshot.

**Write pane**

1. A **344×344** complete page sits centered with 12-point horizontal margins. It is the exact 2× A1 page,
   aligned to whole device pixels; row 5 and the paper edge are always visible.
2. An 8-point gap precedes the **344×44** A2 Hand/Ink Well strip. A3 fills A2's declared native-text
   reserve with the current Hand name and ink state—`Rough charcoal`, `Brush` or `Fountain pen`, plus
   `Ash ink · color open` or the selected mixed-ink name/state. The strip cannot remain mostly blank beside
   unlabeled silhouettes; text is runtime UI and is never baked into the sprite.
3. A 6-point gap precedes one **344×44** horizontally scrolling vocabulary-bin strip. Its trailing edge
   shows a 12–20-point continuation peek whenever another bin exists.
   The strip uses the live bin authority in this exact order: **Illumination, Thermal, Hydrology, Substrate,
   Relief, Vitality, Atmosphere, Cycle, Modifiers, Compounds**. It is not a replacement category row called
   Subjects / Focuses / Modifiers / Compounds. A target bin contains its Subject, learned Focuses and narrow
   modifiers as already settled; the Compounds bin contains Plains, Verdant, Archipelago and other owned
   compounds. Whenever the proof shows those compound tiles, **Compounds** is visibly selected and the strip
   is scrolled to that selection. A leading continuation peek/fade indicates earlier bins at the end.
4. A 6-point gap precedes the palette viewport. Only this palette viewport scrolls vertically. Tiles use the
   exact `8 + 104 + 8 + 104 + 8 + 104 + 8` three-column row and 8-point vertical gaps.
   Tile labels use current display names and capitalization, never lowercase stable IDs.
5. Selecting a palette entry enters placement mode and changes legal page sockets; it does not navigate.
   The mode instruction is a maximum 36-point translucent paper chip over the lower inside edge of the page,
   so it never changes page or palette geometry.
6. Tapping outside the page, changing bin/Hand/ink/pane, using Back or opening the page-actions menu cancels
   placement/connect/disconnect immediately. A cancellation spends nothing and changes no page receipt.
   A required before/after proof opens the two-row page-actions popover at the top-right edge after connect
   mode: the mode overlay disappears, page content is byte-identical, and both **Save Template** and
   **Clear** remain fully on-screen in 44-point rows.

If the measured body cannot hold 344 + 8 + 44 + 6 + 44 + 6 plus at least one complete 58-point palette row,
reduce only the page while retaining square/whole-device-pixel cell alignment. At the required 320-point
fallback the complete page is **296×296** with 12-point screen margins; 320×320 cannot fit inside a
320-point viewport and is retired. Never crop, independently squeeze one axis, touch the screen edge, hide
the tool strip or make the whole screen scroll.

**Pages pane**

1. A centered **Collected / Templates** segmented control occupies 36 points with 8-point body margins.
2. After 8 points, cards form a two-column vertical collection inside 16-point screen margins: exactly
   164×176 points per card, 8-point column and row gaps.
3. The collection alone scrolls. Its first row begins fully below the nested segment; the last row receives
   safe-area bottom padding.
4. A Collected tap selects that exact physical instance and opens **The world**. It never opens a generic
   item-detail route and never consumes or teaches the page.
5. A Template tap opens the A2 anchored action popover at that card. **Load** reconstructs the draft and
   returns to Write; Rename/Overwrite/Delete remain in the popover. A nonempty different draft receives the
   exact `Replace current draft?` confirmation before Load/Overwrite mutation.
6. A stale Collected card remains visible with its frozen physical snapshot and an unavailable action state;
   selecting it shows one contained refusal and never falls through to the current draft.
7. The fresh-campaign runtime-exact proof shows the three actual starter cards—**Open Flats 14e**,
   **Rainwashed Shore 14e** and **Stone Hollow 16e**—in authored order with their own physical thumbnails.
   This is separate from the Templates/action-popover proof; A3 cannot claim the Pages pane from Templates
   alone.

**The world pane**

The bottom transaction bar is fixed; only the page-surface body above it scrolls. Without Anchorage the bar
is **96 points plus bottom safe area**; with Anchorage it is at most **132 points plus bottom safe area**.
It contains one 24–36-point Essence/readiness line and one complete **344×50** Bind & Depart action. The
optional Born anchored switch occupies its own compact 36-point row above the Essence line. The bar is
opaque enough to own its surface and inserts equal bottom content padding, so it never covers the final row.

Inside the scrolling 344-point page surface, use 8-point section gaps and this exact order:

1. a minimum 96-point source row with one 72–88-point runtime page thumbnail, title/source line and exact
   cost. The row expands inside the scrolling surface when an authored title needs a third line; the title
   is never measured at a smaller font and then clipped at the trailing edge. A
   Draft uses the current A1 page itself in a plain single-page frame; it must not reuse the A2 two-sheet
   Template tracing silhouette. A Collected source uses its worn single physical page. Loading a Template
   creates a Draft before this pane, so **Template is never a bind-source kind**;
2. **What the page says** plus zero or more two-column request tiles (164 points each, 8-point gap). Tiles
   are at least 44 points high and expand in 18-point line increments to show the complete exact request;
   both tiles in one row use the taller required height. Text is not truncated or drawn through the
   neighbouring tile;
3. one **What remains open** paper line, never a checklist of all possible subjects when unread;
4. one **Risk** block: Stability and collapse are separate, followed by disclosed sight/danger copy;
5. **Preparation** only when at least one current actionable fact exists; and
6. one 44-point **Further reading** disclosure row, collapsed by default.

For each starter page at 368×800, the initial scroll position must simultaneously show the complete source
row, the `What the page says` heading, the Stability headline and the complete fixed Bind & Depart button.
If request copy is longer, its lower rows scroll; the source/risk/action hierarchy does not turn into six
stacked full-width settings cards. Empty optional sections disappear rather than reserving blank panels.

##### A3 compositor and review gates

- Production is a pure compositor importing the frozen A1 and accepted A2 parts plus fixture data. Full
  phone PNGs are evidence, never selectable production screen assets.
- Render color and literal-grayscale 368×800 proofs for every required fixture below. Also render one
  320-point-width fallback proving two palette columns and one card column without horizontal scroll.
- Ordinary-phone type is gameplay UI, not decorative sprite detail. At final proof size, primary/body copy
  is at least 13 points, secondary/source/cost copy at least 12, section and segment labels at least 12, and
  title/final-action copy at least 15. Long content scrolls inside its owned viewport; Asset cannot shrink
  semantic copy to 9–10 points merely to fit more of it in one evidence image.
- Every fixture includes a hit-region/collision overlay: Back/menu/panes, all 36 page sockets, visible palette
  tiles, tool strip, nested Pages segment, cards/popovers and fixed Bind action are each at least 44 points
  where interactive and remain within the current viewport.
- Long title/refusal/request fixtures use the actual app-owned strings or exact length-matched neutral
  typography receipts; Asset cannot rewrite or truncate the semantic source to make a proof fit.
- Every wrap helper measures with the exact font/size it subsequently renders. The long-copy proof includes
  initial and scrolled states when expansion moves content below the viewport; together they show every
  exact string, while the fixed transaction bar remains unchanged and never covers the scrolling surface.
- Fixture data labels every semantic string as either `runtimeExact` or `typographyOnly`. A typography-only
  receipt exists only to prove shape and wrapping, uses neutral language, and cannot be presented in a
  starter/current-game screenshot as if rules produced it.
- Current starter-page authority is exact: **Open Flats costs 14 Essence**, **Rainwashed Shore costs 14** and
  **Stone Hollow costs 16**. Their known compound names are **Plains**, **Verdant**, **Archipelago**,
  **Caverns** and **Ore**. Asset must not replace them with plausible environmental paraphrases such as
  “Open plains,” “low growth at wet edges” or “connected shallow and deep water.” Those descriptions may be
  true of generated results, but they are not `WritingDeskKnownRequest` output.
- The required unread Open Flats proof is an explicit counterfactual knowledge fixture, not fresh-campaign
  state: Verdant is encountered but unread while Plains remains known. It therefore shows only the readable
  **Plains** request, one unknown mark, no open-subject list, Stability 0–100 and the current rules-owned
  indefinite collapse sentence beginning at **60 turns**. It uses the exact shared unread sight/danger and
  life copy from `WritingDeskReviewModel`; it never prints the obsolete 8-turn floor.
- Field Kit presentation uses the exact typed departure evaluation. The ordinary ready fallback is
  **Field Kit ready.** Asset cannot invent family counts or readiness summaries not present in that receipt.
- Selected collected identity, page revision, Hand/ink state and pane are fixture inputs. The compositor
  contains no gameplay defaults, source fallback, generated seed, risk calculation or bind mutation.
- A3 remains `integrationReady:false` and stops for Game Design plus Aimee ordinary-phone review. Native/PBX
  integration is a separately scheduled Engineering checkpoint after this visual/product acceptance.

#### A3 visual/product disposition — accepted 2026-08-21

Game Design accepts the contained A3 compositor candidate with canonical body
`54340469ed3f0fe308532470c8cc38716f38581cb3d7f0cb544836c8b7536c8c` and manifest file
`0ccac5d60e31f439ddee2954416b036cd723322c6e2b4c106ffc8f619b6c89eb`, checkpointed in exact Asset commit
`7db995f9816dec715e1ea348e021da5939a9a017`. The accepted candidate proves the
ordinary 368×800 and 320×800 fallback compositions, exact Open Flats unread runtime receipt, three starter
Collected cards, Draft/Collected/Template physical-source distinction, page-actions cancellation, mixed-ink
Fountain state, exact bin order and responsive long-copy wrapping above the fixed Bind bar. The synthetic
`starter-world` fixture is retired; typography-only refusal and long-copy fixtures remain visibly nonsemantic
layout evidence and are not game copy.

This is visual/product acceptance only. The A3 checkpoint stays `integrationReady:false`; its phone PNGs are
review evidence rather than production assets. Engineering checkpoint E3 may package only the frozen A1/A2/A3
composable sources after the exact A3 Asset commit is available, and must pin all three accepted hashes before
opening native view integration.

### Required proof fixtures

1. blank Rough Charcoal draft;
2. Open Flats starter page with unread-mark disclosure variant;
3. loaded linked Template, followed by one edited mark;
4. fresh-campaign Collected grid with all three exact starter pages;
5. full-page Fountain Pen composition with mixed ink;
6. illegal placement and page-actions cancellation before/after;
7. starter The world review at 368×800 with complete fixed action;
8. insufficient Essence, ink shortfall and Field Kit refusal;
9. Gold request with Extraction 2 unmet/met;
10. exact collected-page consumption versus reusable draft; and
11. grayscale and first/last-row crop checks.

## Engineering checkpoint sequence

Each checkpoint lands green before the next opens; a later screen does not absorb unfinished rules or Asset
work into one unreviewable change.

1. **E1 — redacted review and exact quote: source-complete.** Commits `221c8732`, `b43e3f24` and correction
   `a35c2cdc` establish the physical-only review model, cluster-aware request projection, typed uncertainty,
   exact source/wallet/Anchorage/ink/Field-Kit quote and inside-mutation revalidation. No view migration.
2. **E2 — bound-world/arrival identity seam: source-complete through `ef941f33`.** The versioned
   `WorldArrivalReceipt`, active-run/History identity, atomic quote/revalidation, disclosure-safe scene ABI,
   shared production counterfactual stages, exact causal grammar and the three current-generator starter
   receipts are executable-gate green. Pending creation/action blocking remains deliberately disabled until
   the reachable native Enter-world root lands in the same deployable checkpoint; an invisible pending state
   must never strand a bound run. Hidden crop cells carry no terrain/elevation/flora payload. No Writing Desk
   redesign entered E2.
3. **E3 — accepted Asset adapter: active Engineering/Asset slice.** Import the exact accepted A1/A2/A3
   authoring dependencies, then consume the reviewed `WritingDeskProductionPack` v1 described above. Pin the
   accepted source and production-pack hashes; validate the closed manifest and map game-owned physical
   receipts to stable pack keys. A schema-agnostic fail-closed loader may land before the final pack, but the
   adapter cannot claim source completeness until exhaustive 108×3 marks, state-footprint coverage, the
   cardinal connector/contact-selection contract, dynamic thumbnail composition and missing/hash/version
   failure fixtures pass. Do not copy
   proof phone PNGs, execute JavaScript in iOS, reimplement glyph/footprint pixels in Swift or start E4 view
   integration from proof-subset assets.
4. **E4 — Write pane.** Replace the legacy page surface/tool/palette layout with the exact responsive Write
   composition. Preserve all current PageRules mutations, connect/disconnect semantics, outside-tap
   cancellation, Template save action and zero-spend editing. Prove 6×6 completeness and three/two-column
   palette behavior independently of the other panes.
5. **E5 — Pages pane.** Add Collected/Templates navigation, runtime physical cards, stable selection,
   edge-safe anchored actions, replacement confirmations and stale-source refusal. Loading a Template returns
   to Write; selecting a Collected instance goes to The world. No item-detail navigation.
6. **E6 — The world pane and fixed transaction bar.** Render only the redacted review model, exact
   preparation/analysis gates and matching quote summary. Bind invokes E2; the fixed action never reconstructs
   facts from view strings. Exercise short/long/unread/refusal/Anchorage states.
7. **E7 — end-to-end/migration/phone closure.** Fresh campaign: all three starter Pages, one drafted world,
   Template save/load/edit, failed and successful binds, crash-before/after arrival dismissal, History
   identity, relaunch and old-save behavior. Then capture ordinary and shorter-phone evidence. No unrelated
   Tutorial, broad accessibility, combat-tree or late-building work enters this closure.

## Engineering acceptance

1. Draft/collected source transitions match the table and survive route changes without accidental fallback.
2. Unknown marks have no semantic string, icon label, analysis field or accessibility leak.
3. Blank, partial, unread and fully specified pages use the exact uncertainty states above.
4. Pre-bind sight, danger, ecology and harvest obey field-level disclosure even when the next seed is known
   internally.
5. Tier 2–5 analysis matches `description-analysis-surface-current.md`; it is collapsed presentation, not
   deleted progression.
6. Template reconstruction remaps every mark/link identity and never binds or spends.
7. All edit/detail/pane actions are zero-spend; only successful Bind & Depart mutates the expedition receipt.
8. Stale quote, generator failure, visual-adapter failure and duplicate activation are atomic no-ops.
9. Open Flats 67, Rainwashed Shore 26 and Stone Hollow 23 hand the exact source page and one frozen arrival
   receipt to B1.6a.
10. Ordinary 368×800 and one shorter phone fixture show the full page, no clipped rows, no covered content and
    a complete reachable final action.

## Player review

Review on an ordinary phone with a fresh campaign:

1. inspect each starter page and confirm unknown writing remains genuinely unknown;
2. bind one starter, return, then load and edit a Template;
3. write one partial world and explain aloud what is requested versus open;
4. provoke one insufficient-Essence or Field Kit refusal and confirm nothing changes;
5. compare the page in Write, arrival and History for identity continuity.

Balance acceptance is not required for this UI/transaction checkpoint. Any source-complete combat tuning may
continue independently.
