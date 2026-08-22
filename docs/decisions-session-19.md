# Decisions — Session 19

This log continues the chronological record after Decision 282 on the reconciled main line. Detailed living
authorities named below govern implementation; this file preserves why the direction changed.

## 283. Field pickup feedback rises locally rather than flying to a counter

**Date:** 21 August 2026

On successful field collection, show the recovered icon at its source, raise it about 1.5 tile heights and
fade it locally. Authoritative quantity updates immediately and a compact counter may pulse, but the icon
does not travel across the screen. Same-family multi-yield aggregates as `×N`; animation remains nonblocking,
edge-clamped and transaction-independent. This preserves spatial causality and avoids trajectory clutter.
Exact timing/burst behavior is in `field-feedback-and-loot-presentation-current.md`.

## 284. Creature materials are distinct from world resources and derive from ecology/body

**Date:** 21 August 2026

**Historical status:** the separation, ecological families and body-derived reward rule remain settled.
The pure removal of material quality described below is **withdrawn as implementation direction** by
Decision 292 while the hybrid family-plus-band proposal is under Aimee's review. Do not dispatch the
pure-no-grade migration from this historical entry.

World resources are named yields from ground, flora and sites. Creature materials are body-derived animal
parts. Both remain slot-free but have separate player-facing reserves and Return groups. Creatures must
support pressure-biased terrestrial, shore, aquatic and aerial ecologies; fishlike life is water-bound,
while feathered, furred, plated/scaled and chitinous forms produce causally corresponding materials.

Remove generic quality as the creature's **primary identity** and remove unrelated random world-resource and
curio drops from ordinary animals. Preserve exact functional properties and source knowledge. A later
correction permits one rare, explicitly territory-sourced gear roll per victorious ordinary encounter; it
does not make gear a body part. Full current schema, habitat and reward rules are in
`creature-ecology-and-materials-overhaul-current.md`.

The remainder of the original decision removed universal grade entirely and reassigned every consumer to
family/properties/maker state. That comparison is retained in the ecology authority for history, but it is
not current implementation authority while Decision 292 is open. World-material and Creature-material
reserves remain distinct under either outcome.

## 285. Known Gold before mining access is deliberate progression

**Date:** 21 August 2026

The game may teach Gold before the active party can extract it. A disclosed unavailable Gold seam/world gives
the player a reason to improve a Field Pick and deliberately write that world later; binding is not blocked.
Extraction is based on the best qualifying pick equipped by the departing party, not Binder level. Iron is
rank 0 to prevent a Blacksmith construction deadlock; Gold is rank 2. Under-equipped Use Tile costs no turn
and changes nothing. The old “three-resource experiment” is superseded: Iron/Gold/Adamant are first vertical
fixtures for the complete data-driven mineral table in `resource-extraction-progression-current.md`.

## 286. Base opens on the Binder House; revised to three village districts and no duplicate House

**Date:** 21 August 2026

**Historical correction:** the original six-hotspot sentence below records the proposal at this point in
the session. Decision 294 removes Workshop; Decision 300 preserves Constellation as a review-gated mastery
surface. Current navigation authority is `home-house-and-village-current.md`.

The Base root is the Binder House/yard, not House/Village tabs. Its six hotspots are Writing Desk, Library,
Constellation, Workshop, Party and yard Essence Spring. Bestiary is inside Library. Storehouse is a separate
town-supplying building in The Commons. Left/right/down open Commerce Row, Makers' Row and The Commons; the
House is never duplicated as a district tile. Village buildings progress absent → known buildable → built →
improved and may carry temporary truthful attention. The town will never be damaged, defended, repaired or
rebuilt.

Obscure stations use functional silhouettes plus standardized pictogram/name signs. Construction,
contribution, stock-refresh and waiting events create a warm restrained glow that clears when the exact
content is checked. Details are in `home-house-and-village-current.md`.

## 287. Character detail is Stats / Gear / Skills / Gambit; Diary deep-links to Library

**Date:** 21 August 2026

Remove the invented generic Story tab. A Diary action opens the exact person's Library diary/dossier and
Back restores the character/tab. Rename the ambiguous Combat tab to Skills because it is the combat skill
tree. The production tree must be a real graph. Dashed alternate hybrid connections are OR parents: own the
solid parent or named dashed parent, then still spend one point. They are not extra AND requirements or free
nodes. Exact behavior is in `party-character-surface-current.md`.

## 288. Broad causal-presentation ideas require exact Gates A–G before cross-lead dispatch

**Date:** 21 August 2026

`first-three-worlds-execution-plan-current.md` replaces the broad phase sketch as cross-lead handoff
authority. Every Engineering/Asset packet states live status/hash, player outcome, exact included behavior,
dependencies, exclusions, rework risk, automated and phone acceptance, receipt language and displaced item.
Current encounter scaling remains the sole source primary until its deterministic implementation/test gate
closes; Aimee's phone feel card is nonblocking and may remain `readyToTest`. Source-complete items are
accepted or corrected, not reimplemented. Tutorial remains dead last.

## 289. Encounter-scaling phone acceptance is not a queue gate

**Date:** 21 August 2026

Encounter scaling remains active until deterministic rules, receipts and automated/simulator matrices are
green with no known P0 intended-Normal defect. Aimee's subjective combat-feel card then remains
`readyToTest` and does not block Writing/arrival/field/Home implementation. Later phone evidence may reopen
scaling at its real severity.

## 290. Deep-water aquatic life and rare ordinary encounter gear are valid

**Date:** 21 August 2026

Aquatic species may spawn and roam through connected shallow and deep water. Deep-water occupants cannot be
entered under current movement and become ordinary combat targets only if they reach shallow water or a
later legitimate deep-water interaction exists. Ordinary animal victories receive one initial 3% eligible
gear roll per encounter—not per creature—framed as recovered territory gear. Body-derived materials remain
independent; keys, quest items, authored uniques and apex weapons are excluded.

## 291. Library owns Bestiary and grows from folded paper into books

**Date:** 21 August 2026

Bestiary moves under the Library. The Library root is a visual room/bookcase with Diaries, Bestiary,
Dictionary, Field Notes and World History shelves. Real collection counts derive paper/folio/softbound/
hardcover stages; each traveller diary grows from its own recovered-page count. Exact behavior is in
`library-shelves-current.md`.

## 292. Hybrid material identity + six-band quality was recommended, then settled by Decision 293

**Date:** 21 August 2026

Game Design recommended material/family identity for capability, six discrete grey/white/green/blue/purple/
orange bands for yield/object quality and value, and gear item level/output quality derived from recipe and
inputs. Same domain+family+band resources stack. Decision 293 records Aimee's acceptance and corrections;
this entry remains the historical proposal boundary.

## 293. Hybrid crafting core is settled: Schematic + material + 70/30 quality

**Date:** 21 August 2026

Aimee accepted the six quality bands, 70% primary/30% secondary component weighting, removal of hard station
quality caps and Refitting. `Schematic` is the player-facing term for the recipe/object plan; existing
`PatternID` may remain an internal decode alias. All-Peerless inputs produce Peerless output. Stations control
available schematics, component complexity and specialist behavior rather than discarding input quality.

Implementation remains held until Game Design authors the complete ComponentProfile and schematic-socket
tables. The separate territory-find category rates are not accepted by this decision.

## 294. Workshop is removed; Party planning never teaches

**Date:** 21 August 2026

The Workshop is a 54-node catch-all and will be removed as a standalone destination after lossless route and
entitlement migration. The earlier proposal to move Instruction into Party is withdrawn: Party selects and
applies people, formation, gear, skills and already-known Gambits; it contains no research, teaching or
purchase tree.

Workshop knowledge is re-audited by primary source rather than copied into another menu. Recovered writing,
traveller teaching, sites/caches and bounded specialist instruction own learnable words; physical capacity
belongs to Storehouse/Tannery. Existing ownership and paid effects are preserved.

## 295. Constellation retirement is reopened for the Mote mastery proposal

**Date:** 21 August 2026

**Historical status:** Decision 300 expands this three-star proposal into the current review-gated pair of
three-star clusters. This entry preserves the earlier reasoning and is not the current full graph.

Do not retire or expand Constellation yet. The current review proposes three campaign-wide stars that open
depths 4–5 of Offense, Defense or Craft for every current/future person while every node still costs its
ordinary point and prerequisites. Long Instruction may remain as the one universal Gambit-capacity star once
the duplicate Workshop slot nodes are retired.

Recommended first scope is combat mastery only, not a Mote tax on every shop tier. A later broad masterwork
permission may be considered after hybrid crafting is live. Prices and whether persistence is campaign-slot
Reality versus global across separate New Games remain open for Aimee.

## 296. Asset outputs must be production pixel art, not reproducible placeholder shapes

**Date:** 21 August 2026

HTML/CSS may host review controls and overlays, but depicted game objects/places must export as task-appropriate
lossless pixel products: composite sprites, scene/layer kits, modular component kits or animation sets with
stable IDs, pivots/attachments and hashes. Technical determinism does not equal visual acceptance.

Candidates must be beautiful and recognizable without labels, work at native size and grayscale, provide an
ordinary-Chrome HTTP route plus standalone PNG evidence, and remain integration-unready until the actual art
is approved/frozen. The first deterministic House/village/Library candidate was rejected as placeholder art
despite its correct manifest/export format.

## 297. Asset and Engineering Leads report completions directly to Orchestration

**Date:** 21 August 2026

Both leads must proactively update the current Game Design/Orchestrator task when a bounded task becomes
source-complete, integrated, installed, rejected, blocked or abandoned, before starting a different task.
Reports name exact paths/commit, achieved receipt, evidence, player-visible result, missing acceptance,
decisions and next safe action. Aimee is not the go-between and Orchestration should not have to poll.

## 298. Territory-find percentages remain an open tuning proposal

**Date:** 21 August 2026

The shorthand `3% / 1.5% / 0.5%` means absolute per-victorious-ordinary-encounter chances for gear,
eligible consumable and ordinary cache key respectively, with 95% no bonus and at most one result. It is
equivalent to one 5% find roll followed by 60/30/10 category weights. It is per encounter, not per creature,
and Teeming does not multiply it. These rates are explained for review, not yet authorized for implementation.

## 299. Every real village building gets Built, Improved and Mastered forms

**Date:** 21 August 2026

The live station catalogue's mixed `maxTier` values are not visual or progression authority. Every actual
village building now targets three constructed forms: useful Built/Tier 0, decision-adding Improved/Tier 1
and culminating Mastered/Tier 2. No village structure is ever damaged. Rooms, shelves, Party, Essence Spring,
Constellation and removed Workshop compatibility are not fake buildings and do not inherit these tiers.

Each rung has a real capability and a physical addition to the same recognizable structure. Station tiers
open capabilities, schematics, convenience or reach; they never impose a hard quality cap. Exact building
effects and visual anchors are in `village-progression-and-asset-matrix-current.md`. Existing higher-tier
save entitlements must migrate to the nearest equal-or-better new entitlement without loss.

## 300. The current Constellation recommendation is two matched three-star mastery clusters

**Date:** 21 August 2026

**Review status:** reversible Game Design recommendation awaiting Aimee's direct acceptance; do not implement
new consumers yet.

Keep the current Long Instruction star and propose Offense, Defense and Fieldcraft mastery beside Commerce,
Makers and Commons mastery. A combat star permits depth-4/5 purchases in that discipline campaign-wide; a
village star permits Tier-2 activation across that district. The Mote buys permission—not a node, recipe or
building—and every underlying purchase/cost/prerequisite remains. Initial tuning is one Mote per mastery.
Purchases live in the current save's Reality layer; a genuinely new save starts clean.

This uses three village gates instead of taxing every shop and aligns the town's three directions with the
combat tree's three disciplines. Exact prerequisites and migration are in
`village-progression-and-asset-matrix-current.md` and `workshop-constellation-role-audit-current.md`.

## 301. Village art advances through one finished-sprite style gate

**Date:** 21 August 2026

The rejected House/Library batches remain exporter infrastructure, not an aesthetic seed. Asset work resumes
with one finished label-free Tier-0 Trading Post sprite. It must pass native-size, 400% nearest-neighbour,
grayscale and phone-placement review before the opening-five set, upgrade forms, Binder House or close-up
Library proceeds. This prevents another technically complete batch from propagating an unaccepted visual
language. Exact pixel dimensions, physical referents and forbidden readings live in
`home-village-library-asset-packet-current.md` and `village-progression-and-asset-matrix-current.md`.

## 302. Adjacent consequence cues are learned, current and rules-owned

**Date:** 21 August 2026

The accepted field cue grammar places a shallow red harm crescent and/or exactly three disconnected grey
slow rays at the party-cell edge corresponding to each adjacent direction. Slow footing is visible for
current mud/tall growth; rubble is not slow under current movement rules. Flora harm appears only after the
campaign truthfully learns that exact world-seed/flora-ID/defence key through actual contact, an actual
sessile-flora encounter, or a narrow earned recognition contribution. Current full visibility and a fresh
rules-owned four-direction preview are required; remembered/fringe/hidden cells reveal nothing.

Look consumes the same preview and uses exact contextual copy for boundary, crumbled ground, deep water,
chasm, turn cost and learned flora consequence. It does not reuse the current trait-leaking inspection
helper. The frozen Asset cue-only checkpoint is commit
`e448553c1c1f095a01b4274aea812faa76955110`; it remains `integrationReady:false` until native rules and
composition are implemented and accepted.

## 303. Local field pickup rises; Creature materials do not spray from combat

**Date:** 21 August 2026

A committed direct field pickup immediately updates ownership, then raises one exact source icon locally
up to 1.5 tile heights over 450 ms and fades it. Same-identity yield aggregates (`×19` is one icon), top-edge
travel clamps inside the map viewport, Reduced Motion uses a stationary fade, and animation never owns or
delays mutation.

Creature materials are a different presentation boundary. Combat result and Expedition Return aggregate
them by exact family+quality; the world map does not spray Hide/Bone/Feather icons after a fight. The first
Asset pickup proof therefore covers Quartz, Raw Essence, Chipped Blade, recovered writing and the legitimate
unknown parcel only. Missing known-object pickup art skips optional animation with a diagnostic rather than
borrowing an unrelated silhouette.

## 304. Arrival causality pairs dramatic light before flora, but routine light after it

**Date:** 21 August 2026

When one causally authored mark already owns World Arrival Sentence 2, the paired environmental fragment
uses heavy air, heavy precipitation, true darkness/blazing light, light air, light precipitation, concrete
flora, then routine dim/bright light. Concrete growth therefore beats merely routine dim/bright light, but
never conceals a genuinely dark or blazing arrival. Rainwashed Shore's frozen receipt is `trueDark`, so its
accepted runtime sentence names restricted visibility rather than sparse growth. The no-causal environmental
fallback keeps its existing priority; this is the narrower one-causal pairing rule.

## 305. Writing Desk ships an exhaustive Asset-built pack; runtime links stay adjacent

**Date:** 21 August 2026

The accepted Writing Desk JavaScript compositors remain Asset authoring tools and never become an iOS
runtime or a second Swift drawing implementation. Asset exports one exhaustive, hashed
`WritingDeskProductionPack` v1 covering all current lexemes/hands/states and dynamic card/tool/popover
composition; Engineering loads it through a closed fail-closed adapter. Proof phone PNGs and proof-subset
sprites are not runtime substitutes.

Live connections continue to follow `PageRules.areAdjacent`: only cardinally touching occupied cells can be
joined. A1's long diagonal linked page is retained only as stroke-style evidence. Runtime uses horizontal or
vertical Asset connectors, selects one shared edge deterministically in reading order, uses the coarsest of
the two endpoint hands, remains Ash/open neutral and draws below the marks. This avoids a `MarkLink` migration
and replaces the always-on cluster outline instead of double-encoding the same relationship.

The pack's 108 identities are authored catalogue lexemes, not the unbounded player-created Personal
Compound namespace. During this early-flow checkpoint, and only for a frozen `personalCompound` snapshot,
the existing deterministic glyph remains as an explicit save-compatibility route. Missing authored pack keys
never borrow it. A later Scriptorium/Runebook visual checkpoint replaces that compatibility glyph rather than
expanding E3 and delaying the first-three-world loop.

The corrected v1 pack is accepted with canonical body
`b9b244ee8382e9f0fca0776603202e51330a651d50b0c499af62a50be2be7ce0` and manifest-file SHA
`3a1709f91de0c39c49a854aea9ba6a427fe44bdba31b23e9ea47fc26ce5982e5`, frozen in Asset commit
`b54db384bbedfd07b8a858f309087adb35c660f3`. Its tool table excludes the
impossible Charcoal/mixed state; tint masks replace only their owned base pixels and fixed masks are never
drawn. Cardinal links are exact 28×5/5×28 centre-spanning assets with frozen shared-edge offsets. This
releases the fail-closed E3 loader only; E4 stays blocked until that loader passes.

## 306. World Arrival freezes validated draw commands at bind

**Date:** 21 August 2026

The accepted World Arrival JavaScript compositor is the visual reference, not a runtime dependency or an
invitation to approximate its scenes in Swift. Asset exports a canonical conformance corpus of sanitized
receipts and ordered integer `rect-v1` commands. Engineering's mechanical native adapter must match the
entire corpus and frozen scene pixels exactly.

Before successful Bind & Depart mutates the save, the adapter freezes a
`WorldArrivalRenderedSceneReceipt`: accepted program/source hashes, input scene-receipt hash, the validated
160×100 command list, command hash and rendered RGBA hash. Active run and History store it. The reveal renders
only those commands, so existing worlds keep their exact arrival picture while a later visual program can
replace the current implementation for new binds without retaining old generation logic. Proof phone PNGs
are never runtime scenes, and a generation/hash failure remains an atomic pre-spend refusal.
