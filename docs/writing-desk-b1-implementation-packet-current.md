# Writing Desk B1 implementation packet — current

**Status:** Game Design implementation authority for B1.5a
**Priority:** first-three-world loop; schedule after the current encounter-scaling source checkpoint and
before native world-arrival promotion
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
  pageThumbnail
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

`openSubjects` is nullable. It may list exact untouched subjects only when every relevant mark on the page is
readable. If any mark remains unread, show `Some of this page is still unread` rather than using subtraction
to reveal what those marks affect.

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
  sourceKey + revision/hash
  reservedCampaignSeed
  pageCost
  anchorPremium
  preparedInkReceipt
  fieldKitReceipt
  availability/refusal
```

On activation, Engineering rebuilds and compares the quote. Before any save mutation it must successfully
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

### Required proof fixtures

1. blank Rough Charcoal draft;
2. Open Flats starter page with unread-mark disclosure variant;
3. loaded linked Template, followed by one edited mark;
4. full-page Fountain Pen composition with mixed ink;
5. illegal placement and connect-mode cancellation;
6. starter The world review at 368×800 with complete fixed action;
7. insufficient Essence, ink shortfall and Field Kit refusal;
8. Gold request with Extraction 2 unmet/met;
9. exact collected-page consumption versus reusable draft;
10. grayscale and first/last-row crop checks.

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
