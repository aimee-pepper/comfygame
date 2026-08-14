# World Pages, saved templates and the Rune Dictionary — current

**Status:** starter pages are source-complete; Dictionary checkpoint `dc30c6c` is ready for phone
visual acceptance with 82/82 focused tests green; Templates are source-complete with 6/6 focused
runtime tests green and await only isolated checkpoint/ordinary-phone visual acceptance; wild-page
production remains queued; tuning remains playtest-reviewable  
**Date:** 14 August 2026  
**Roadmap position:** Bands 1–3, with full authored map blueprints parked for Band 6+

Save evolution follows `save-compatibility-policy-current.md`: prefer tolerant additive migration,
but choose an explicit format break rather than retain parallel obsolete page/generator semantics.

## Player promise

The Writing Desk should support three different relationships with a page:

1. **Write** — the current editable page, paid for and bound normally.
2. **Collected World Pages** — physical, authored pages found or granted as exact consumable
   instances. They can contain marks the player cannot yet write.
3. **Saved Templates** — reusable copies of pages the player personally wrote, used to restore a
   familiar arrangement without recreating it mark by mark.

The Library gains a **Dictionary** that remembers glyphs the player has encountered. A known entry
shows its name and understood function. An encountered but unidentified entry shows the glyph and
`??`; possession, inspection and use do not reveal its meaning by themselves.

These systems add authored footing to the opening without replacing procedural worlds. The first
three pages are invitations into the core system, not a tutorial sequence.

## Terms that must not collapse together

- **Diary Page:** permanent recovered writing about people, places, recipes or teachings. Already
  stored in the Library and never consumed.
- **World Page:** a physical page that can be bound into one expedition. It is consumed by a
  successful departure.
- **Template:** a reusable player-authored composition. Loading it replaces the current draft; it
  does not create a world, waive Essence or preserve a seed.
- **Curated procedural page:** exact authored marks plus generation policy; the normal generator
  still creates the map and population.
- **Authored world blueprint:** an optional later definition of fixed/curated map topology,
  encounters, sites, scripted facts and allowed variation. A page of sigils alone is not this.

Player-facing copy uses **World Pages**, **Diary Pages**, and **Templates** consistently. Internal
types should use the same nouns rather than aliases.

## Direction established by Aimee

- Give the player a small starting set of approachable World Pages (working quantity: three).
- World Pages can be found during exploration and can eventually carry handcrafted/story content.
- Collected World Pages are consumable and disappear when visited.
- The Writing Desk exposes collected pages and reusable player-written Templates.
- The Library contains a rune Dictionary.
- A page may expose unfamiliar glyphs without teaching their meaning; those glyphs appear as `??`.

The implementation rules below are Game Design's recommended working profile. They are deliberately
reversible where play evidence may change quantity, cost, drop rate or UI arrangement.

## Recommended working behavior

### Starting pages

- Every new campaign begins with exactly three distinct World Page instances.
- All marks on the starting three use vocabulary available at campaign start. The Dictionary adds
  no `??` entries merely because the starter bundle exists.
- They are curated, low-complexity procedural requests with a frozen seed policy, so they are useful
  as repeatable fresh-save balance fixtures while still exercising the real generator.
- They do not silently bind, auto-select or force an order. The player may ignore them and write a
  page immediately.
- They pay the ordinary base and authored-symbol precision cost. Because the physical page is
  already inscribed, it waives only the cell/ink-writing component; the preview names that discount
  explicitly. The bundle must remain affordable from starting Essence and preserve continuation.
- Existing progressed saves receive no duplicate retroactive starter bundle. A pre-first-bind legacy
  save with no World Pages may adopt it once through an explicit migration receipt.

The first content pass should teach comparison through identity rather than prose:

1. **Open Meadow** — `Plains + Verdant`; 12 charcoal cells; 21 Essence if copied by hand, **14** on
   its pre-inscribed World Page. Calm, traversable, visibly living and modestly resourced.
2. **Rainwashed Shore** — `Archipelago`; 6 charcoal cells; 18 Essence if copied, **14** pre-inscribed.
   Water/relief contrast and a different route shape without opening lethality.
3. **Stone Hollow** — `Caverns + Ore`; 10 charcoal cells; 22 Essence if copied, **16** pre-inscribed.
   Substrate/relief and ordinary ore, still within the accepted level-one combat envelope.

Exact spatial layouts and frozen starter seeds are authored in `world-pages-authority.json`:
Open Meadow uses seed 2, Rainwashed Shore seed 26 and Stone Hollow seed 23. Each sampled world has
three ordinary encounters, guaranteed writing, 11–16 obtainable Raw Essence, no apex, full content
reachability and at least 45 projected collapse turns. They were resampled after commit `51d5bee`
corrected creature budgets, and the post-scaling evidence is recorded in `world-pages-authority.json`.
Phone play remains the acceptance gate. The pages must not carry hidden bespoke
enemy nerfs; the accepted Band-1 encounter envelope remains the only opening protection.

### Collected World Pages

- Every owned copy has a stable instance ID and a definition/provenance ID. Consumption always
  targets the exact selected instance, never every copy of a catalogue entry.
- A collected page is read-only. It cannot be edited, decomposed, saved as a Template or harvested
  into the writable palette. Otherwise consumption and unknown vocabulary are trivial to bypass.
- Selecting one shows the whole page. Known marks use their normal labels; unidentified marks show
  their stable glyph and `??` everywhere, including detail and projection. Accessibility labels say
  “unknown mark,” not the hidden catalogue name.
- The rules engine still resolves every mark. Presentation may describe only what current knowledge
  justifies; it must not reveal a hidden mark through the preview, cost breakdown, debug-like
  contribution copy or World History before identification.
- A World Page is removed only inside the successful atomic bind-and-depart mutation, after world
  generation and visual receipts have succeeded. Refusal, adapter failure, insufficient Essence,
  app termination before commit, or cancelled selection consumes nothing.
- Once departure commits, the page is gone even if the expedition later fails. World History keeps
  the immutable page used and its provenance.
- Seeing a mark records a Dictionary encounter in Reality. Losing the physical page later does not
  erase having seen its glyph.
- Finding World Pages uses its own content budget. It never replaces the guarantee that every world
  contains at least one piece of writing.
- Repeatable ordinary pages and unique story pages are distinct catalogue dispositions. Unique pages
  cannot drop twice; repeatable definitions may produce multiple exact instances.
- A repeatable page is ordinary carried property during an expedition and participates in the same
  discrete failure-retention budget as other found objects. A unique/story page is protected once
  taken so a one-time site or story trigger cannot become permanently missable.
- World Pages occupy one satchel slot in the field. At Home they live in the Writing Desk's
  Collected folio rather than consuming Storehouse slots. The folio has no arbitrary hard cap;
  random repeatable drops exclude definitions for which two unconsumed copies are already owned.
- A pre-inscribed page's price is `ordinary resolved book cost − cell/ink cost`. It never discounts
  the base binding fee, authored compound value, anchoring premium or any future explicit surcharge.
  Templates receive no discount because loading a pattern still requires writing a new page.

### Saved Templates

- The player can save the current editable page under a name, load it, rename it, overwrite it only
  after confirmation, and delete it after confirmation.
- Template v1 stores the complete `Page` representation production owns today: composition,
  spatial layout, links and hand. It stores no world seed, generated result, traveller arrival or
  outcome. When Ink Mixing ships, the Template schema adopts the then-canonical persisted ink
  receipt; Templates must not invent a temporary ink field before that authority exists.
- Loading replaces the editable draft only after confirmation when that draft is nonempty.
- Loading never binds automatically. The loaded draft remains editable and uses the ordinary live
  preview, Essence price, contradiction, color and bind transaction.
- Only marks the player could legally write at save time may enter a Template. A collected World
  Page has no Save as Template action.
- Template mark instance IDs are remapped when loaded so repeated uses cannot alias historical
  pages or one another.
- Start with a cap of 20 Templates. This is a save-size/UI bound, not monetized progression; DEBUG
  reports the cap and count so play can show whether it is too small.

#### Exact v1 Template receipt and actions

Persist an ordered array of `SavedPageTemplate` records in Base. Each record owns an opaque stable
`PageTemplateID`, a player-facing name, the complete frozen `Page`, and a monotonically increasing
creation ordinal. Array position and name are presentation facts, never action identity. New IDs
come from a persisted monotonic counter; tolerant decode initializes the counter above every
decoded ID so deleting a Template never permits identity reuse.

As a reversible v1 naming default pending playtest, names are trimmed, 1–40 characters, and may
repeat: rejecting or silently rewriting a duplicate name would make the name an accidental
identity. A blank name becomes **Untitled page** only after explicit confirmation. Saving an empty
page is disabled. Saving a new record at the cap refuses without mutation; overwrite and rename of
an existing exact ID remain available at the cap.

Four typed atomic actions own mutation:

- **Save new** validates that every hand, source, compound and qualifier in the current draft is
  presently writable, freezes the exact current page, assigns the next stable ID/ordinal and
  appends once.
- **Overwrite** revalidates the exact record ID and current draft, preserves that record's ID,
  name, ordinal and list position, and replaces only its frozen page.
- **Rename** changes only the exact record's name. **Delete** removes only that exact ID after a
  destructive confirmation. Stale IDs and validation failures are zero-mutation refusals.
- **Load** does not mutate the Template. It remaps every placed-mark ID to a fresh page-local ID,
  rewrites both endpoints of every surviving link through the same bijection, and also refreshes
  the nested `Sigil.id` in legacy `.rune` content. Origin, content, hand, shape ID, page dimensions
  and link topology remain exact. A link whose endpoint is absent is rejected during Template
  validation rather than quietly copied or repaired.

Loading into an empty draft proceeds directly. Loading the page already present is a no-op. Loading
over any different non-empty draft requires a confirmation that names the number of marks being
replaced; cancel preserves the draft, current interaction mode and selected Template. A successful
load replaces the draft atomically, clears transient ghost/connect/disconnect selection, returns to
**Write**, and creates no Dictionary encounter or binding discount.

The Pages → Templates surface is a compact page-thumbnail grid, not a prose list. Selecting a card
opens an anchored action popover (Load, Rename, Overwrite, Delete) that adapts inward/upward at phone
edges. Save Template belongs to the Write pane and shows the frozen thumbnail and editable name
before confirmation.

### Rune Dictionary

- The Dictionary is a Library tab, available from a new campaign. Lys may add later search and
  cross-reference tools but does not gate basic literacy.
- Entries cover the actual written vocabulary: targets, focuses/sources, qualifiers and compounds.
  Structural gestures or connectors belong in a separate grammar reference, not as fake runes.
- Entry state is derived from two authorities:
  - **encountered:** a Reality-layer set of typed lexeme identities;
  - **identified/writable:** the canonical acquisition/ownership authority, reconciled into durable
    knowledge rather than copied into UI-local flags.
- Starter/writable vocabulary appears known immediately. A glyph first seen on a collected page is
  added as encountered and displays `??` until a real teaching/identification event occurs.
- Repeated sightings do not reveal meaning and do not create duplicate entries.
- When an existing legitimate acquisition teaches the rune, the same entry changes from `??` to its
  name/function and the rune becomes writable through the normal authority.
- Merely binding or visiting the resulting world is not identification. The previously settled
  attribution/confidence system for unidentified compounds remains the later evidence-based route;
  it is not silently implemented as a one-use reveal.
- Dictionary state never reveals undiscovered POIs, hidden world rolls, traveller conditions or the
  full semantic expansion of an unidentified compound.

#### Exact v1 knowledge projection

Use one tagged, hashable `LexemeIdentity` with exactly four cases: `target(PressureTargetID)`,
`source(PressureSourceID)`, `qualifier(QualifierID)` and `compound(SymbolID)`. Persist only a set of
these identities in Reality as **encountered**. Do not persist names, effects, icons, catalogue
indices or a second `known` flag.

`known` is derived at read time from the same authority that lets the Desk write the mark:

- every live pressure target is known, because all subjects are currently writable;
- every result of `PageRules.writableQualifiers()` is known;
- a source is known only when `BaseState.ownedSources` contains it; and
- a compound is known only when `BaseState.ownedSymbols` contains it.

This deliberately means a catalogue entry can be known before it has been encountered on a found
page: acquired literacy belongs in the Dictionary immediately. The visible set is
`encountered ∪ known`, ordered by category and then the catalogue's authored order—not by raw ID or
the order a save happened to encounter it.

Recording a modern mark records its one typed identity. The legacy `.rune(Sigil)` representation is
not a fifth vocabulary category: record its typed source and target identities. Unknown or retired
IDs remain durably encountered but render a stable fallback glyph and `??`; they must not fall back
to their raw ID as player-facing text. `RuneGlyph(id:)` may draw the identity without consulting the
hidden name, while detail and accessibility copy use only **Unknown mark** until the ordinary
knowledge projection becomes true.

#### Dictionary presentation and encounter transaction

The phone surface is a glyph atlas, not another full-width list: six square glyph cells per row at
ordinary phone width, grouped by **Subjects**, **Sources**, **Qualifiers** and **Compounds**. A cell
shows the glyph and either its short known name or `??`; selecting it opens an anchored detail
popover that flips inward or upward at screen edges. Known detail explains only the ordinary
catalogue function already licensed by ownership. Unknown detail says **Unknown mark** and nothing
else—no hidden name, acquisition hint, contribution, target compatibility or expanded compound
components.

`recordEncounter(on:)` is one idempotent Reality mutation over an exact `Page`: atomic marks record
their typed identity, compounds record the compound, and legacy runes record source plus target.
Opening the full read-only view of a collected World Page performs that mutation once. A thumbnail,
loot toast or undisclosed map tile does not: the player must actually inspect the page. Selecting a
starter World Page may record its marks, but all are already known and therefore causes no visible
`??` change. Loading a Template does not create new encounters because Templates can contain only
marks the player was already licensed to write.

## Writing Desk information architecture

Do not add four cramped peer tabs to the existing two-pane toolbar. Use three stable primary tabs:

- **Write** — current page grid and palette.
- **Pages** — a compact internal switch between **Collected** and **Templates**. Collected cards show
  page identity, known/unknown mark count and provenance; Templates show name and composition.
- **The world** — preview and commit for the currently active draft or selected collected page.

Loading a Template returns to Write. Choosing a collected page makes it the active read-only bind
source and opens The world. Switching back to the editable draft never mutates either source.

The page itself remains the visual identity. Do not render World Pages as another full-width prose
list; use page thumbnails with concise badges and anchored detail.

## Content and drop design still required

Game Design owns these before wild-page breadth is assigned:

The initial catalogue is authored with exact 6×6 layouts in `world-pages-authority.json`: three
starter pages, eight repeatable wild pages and four unique site pages.
`python3 Scripts/validate_world_pages.py` checks its IDs, writing hands, geometry and prices against
the live symbol and shape catalogues before implementation or content changes are accepted.

### Random placement profile

- Random World Pages begin only after the first completed expedition; the starter folio already
  supplies the opening choice.
- Base chance is **15% per resolved ordinary expedition**.
- After five consecutive resolved expeditions without banking a random World Page, the next
  eligible world guarantees one. The counter resets only when a page is banked, not merely placed,
  missed in fog, declined for capacity or lost on failure.
- At most one World Page appears in a world. A unique site/story page suppresses the random roll for
  that world.
- Context-matching definitions receive 3× weight; every repeatable definition retains baseline
  weight so writing habits cannot make it permanently unreachable.
- Known-vocabulary repeatables enter after one resolved expedition, Gilded Caverns after two,
  Storm Coast and Blighted Garden after three, and rare Mote Understone after five. These are opening
  pacing gates, not knowledge gates: once eligible, a page remains eligible whether its candidate
  unfamiliar marks are still `??` or have since been learned.
- A definition with two unconsumed Home copies is excluded. Copies currently carried or offered in
  the active run also count toward that limit.
- The page reserves a reachable host after guaranteed ordinary writing and before optional content.
  It does not consume the diary/field-writing roll or its fallback.

These are playtest numbers, not permanent economy law. Measure banked pages per ten expeditions,
missed/declined/lost opportunities, folio copy counts and how often players actually bind one.

### Field interaction and return

- A visible page tile is labelled **Loose page** until inspected; its catalogue title is then shown.
- Inspect is zero-turn and records every glyph encounter in Reality. **Take** is also zero-turn but
  requires one satchel slot; a full satchel opens the exact existing keep/swap decision.
- The return receipt has separate **World Pages kept** and **World Pages lost** groups. It never mixes
  them with Diary Pages, generic writing or item stacks.
- A unique page uses the protected line and is always kept once taken. Repeatable copies use the
  outcome-wide discrete retention budget and keep their stable instance/provenance IDs.
- Discarding a Home copy requires confirmation. It does not erase Dictionary encounters or World
  History and does not clear a unique grant receipt.

#### Exact wild-page receipt and transaction

A physical wild page is not a Diary Page or an `ItemStack`. It is a `WorldPageInstance` with an
opaque stable instance ID, stable definition ID, unique/repeatable policy, inspected flag and frozen
provenance: origin world/run ID, generation seed and map position. The active expedition owns
separate carried and offered World Page collections, but each carried page consumes one ordinary
satchel slot through the shared capacity calculation. It never becomes generic loot, material
reserve, Trading Post stock or Recycler input.

Selection is deterministic in the generation seed. Eligibility uses the count of previously
resolved expeditions; context weighting uses the generated world's frozen readings, never
undisclosed player knowledge. The placement roll and selected definition are frozen before a host
is reserved. The stable instance ID is drawn once from the world's content stream, so repeatable
copies never alias even when their definition and frozen layout match.

Persist the random-page drought counter with campaign world progression. A resolved eligible
expedition that does not bank a random page increments it once; placement, inspection, refusal,
missing it in fog, dropping it in a swap or losing it on failure never reset it. Banking an exact
random page resets it once. At the guarantee threshold, every subsequent eligible expedition keeps
guaranteeing a candidate until one is actually banked. Unique site/story grants use their own
durable definition-ID receipts and neither advance nor reset the random drought counter.

Inspect and Take revalidate the exact visible tile and instance. Inspect changes only that
instance's inspected flag and Reality's encountered lexemes; Take atomically moves that exact
instance into carried pages or opens the normal exact keep/swap decision. Stale, hidden or already
removed tiles are zero-mutation refusals. Taking without inspecting is legal and does not teach the
marks; the Home folio continues to call it **Unknown page** until opened.

The expedition outcome freezes exact kept/lost World Page instances before showing the recap.
Repeatables participate as indivisible units in the same outcome-wide discrete retention budget as
other unprotected carried objects; uniques are protected after Take. Return attaches kept copies to
Home once, preserves their provenance, and resets pity only if at least one kept random copy was
newly banked. Relaunching or replaying an outcome cannot duplicate a page, reset pity twice or
consume another capacity/retention unit.

### Initial catalogue purpose

The eight repeatable pages form four steps: known safe variation, known risk/reward, a candidate
unknown compound in a legible context, and a rare high-value candidate unknown. Actual known/unknown
display always derives from that campaign's knowledge; `candidateUnknownSymbolIDs` is content intent,
not saved disclosure state. The four unique site pages are
protected authored curios, not yet mandatory main-story beats. This lets storyline ownership be
added later without rewriting their physical rules.

## Engineering slices

### Shared ownership boundary

No slice begins while the required shared model/action/UI files contain another active checkpoint.
The known overlap includes `BaseState.swift`, `Library.swift`, `GameActions.swift`,
`GameActions+World.swift`, `WorldRules.swift`, `WritingDeskView.swift`, `LibraryView.swift`,
`WorldView.swift`, `EconomyTests.swift`, `LibraryTests.swift` and `WorldTests.swift`. Clean helper files
alone would create an inert partial and are not a reason to start early.

### Slice A — Dictionary foundation (implementation-ready after boundary review)

Add typed encountered-lexeme identities to Reality; derive known/unknown presentation from canonical
knowledge; add the Library Dictionary grid and exact `??` veil; record starter knowledge. No World
Page drop or identification inference belongs in this slice.

Expected seams: typed target/source/qualifier/compound lexeme identity beside the Page vocabulary;
Reality/Library tolerant persistence; `LibraryRules` projection; `LibraryView` grid; persistence,
Library and content-authority tests.

Gate: tolerant old-save decode, stable typed IDs, no catalogue-name leakage, idempotent encounter,
legitimate acquisition promotion and compact phone presentation.

### Slice B — Templates (implementation-ready)

Add durable named Template records and atomic save/load/rename/delete actions, then add the Pages →
Templates grid. It can ship before collected pages because it only copies player-legal drafts.

Every load remaps mark IDs and all link endpoints together. Ordered stable template IDs, rather than
array position or name, own rename/delete/overwrite actions.

Gate: exact current Page/links/hand round-trip, ID remap, dirty-draft confirmation, cap, relaunch and
ordinary binding parity. Ink joins this gate only after its production receipt exists.

### Slice C — Starter World Pages (needs the three authored definitions)

Add catalogue definitions, exact instances, new-game/migration receipt, read-only selection and
atomic selected-instance consumption. No random drop table yet.

Gate: three affordable new-game pages; selection/refusal/relaunch atomicity; world/history receipt;
Dictionary sees no unknown starter marks; three seeded worlds pass Band-1 survival and continuation.

### Slice D — Wild curated World Pages (needs content/drop design)

Add world/site/story grants, provenance, unique/repeatable policy and Dictionary encounter hooks.

Gate: never displaces guaranteed writing, respects failure retention and capacity, no duplicate
unique page, no hidden-name leakage, correct recap and deterministic seeded placement.

### Slice E — Unidentified evidence (later design/implementation)

Add per-component attribution receipts and confidence only after Dictionary sightings and wild pages
are stable. This is an earned-learning system, not required for the first World Page release.

### Slice F — Authored world blueprints (Band 6+)

Add fixed/constrained map blueprints for story worlds only after ordinary world generation,
encounter scaling, sites and persistence are accepted. Until then, World Pages curate inputs rather
than claiming to hand-author the resulting map. The exact later contract is
`authored-world-blueprints-current.md`.

## Explicitly deferred identification question

The first Dictionary slice does not invent a confidence meter. An encountered unknown remains `??`
until an existing legitimate teaching/identification route resolves it. Before evidence-based rune
identification is implemented, Game Design must reconcile one conflict: observation should be able to
teach meaning, but it must not accidentally bypass research-, diary- or traveller-owned progression.
That is a Band-3 decision after unknown pages are playable, not a blocker for sightings or the basic
Dictionary.

## Roadmap rule

This feature does not pre-empt the active level-one encounter-scaling checkpoint. Dictionary and
Templates may follow as contained work; starter pages enter Band 1 only after their seeded worlds
prove they do not bypass or destabilize the same opening balance gate. Wild pages enter Band 3.
Blueprint worlds remain late because every system they pin must first be stable.
