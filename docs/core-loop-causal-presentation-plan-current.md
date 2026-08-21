# Core-loop causal presentation plan — current

**Status:** Game Design implementation plan; individual slices require their own source, visual,
installation and playtest receipts. This plan does not promote an AssetLab proof or queue a late-game
feature merely by naming it.
**Owner:** Game Design owns player outcome and behavior; Engineering owns native rules and composition;
Asset Design owns functional visual grammar and conformance; Aimee owns final handmade pictorial art and
playtest acceptance.
**Updated:** 20 August 2026

## Product outcome

The first three expeditions must make one causal sentence legible without consulting DEBUG:

> I composed this page; its writing produced this kind of place; the place warned me about what I had
> learned; I chose what to approach and recover; I brought recognizable evidence home; that evidence and
> the people I found changed what I could compose or survive next.

This is not a request for a whole-app cosmetic rewrite. Each checkpoint below makes one link in that
sentence playable and is accepted independently on the ordinary phone.

## Current factual boundary

- Repository reconciliation is complete at `main` / `origin/main` `1776d31`; the accepted phone-source
  baseline `2d2e7ce` remains ancestral. The phone remains unchanged on build 234.
- The accepted lifecycle-splash v0.3 proof exists in AssetLab but is not a native game consumer.
- The accepted combat-graph v0.4 proof exists in AssetLab/DEBUG, but the ordinary character progression
  surface must become a real legal-purchase graph rather than a styled linear list.
- World-grade-2 v0.2 is accepted as the isolated relative-diversity candidate, not native integration.
- The resource reserve, six-across object grammar, Base destination board and complete meeting-review
  corpus already provide implementation authorities. Do not redesign these from scratch.

## 1. Writing Desk: composition rather than parameter configuration

### Intended experience

The player handles a page, makes marks with a writing tool, connects those marks and binds the resulting
artifact. Exact costs and legal blockers remain explicit, but the primary interaction is with the page;
resolved simulation data is an interpretation of the writing, not a form the player fills out.

### Ordinary presentation

1. Preserve the settled **Write / Pages / The world** architecture.
2. **Write** gives the paper most of the viewport. The 6×6 page, placed rune marks, links, current hand
   and ink are the controls. Tool/ink choices use a compact tray or anchored detail; they are not one
   full-width settings row per property.
3. Marks retain their written appearance and provenance: Rough charcoal is irregular and cannot carry
   liquid color; Brush produces controlled broad ink; Fountain pen produces fine ink. Ink Mixing remains
   adjacent to and locked behind Brush.
4. The rune palette shows symbols and ownership state. A known meaning may be inspected; an encountered
   but unresolved lexeme remains `??`. Selecting a rune does not turn the page into a list of its numeric
   pressure contributions.
5. **Pages** treats collected World Pages as physical consumable sheets and templates as player-made
   tracings. Loading a template reconstructs the player's current persisted page representation; it does
   not become a conventional preset/settings screen.
6. **The world** is the Binder's reading of the completed page. It shows a small page thumbnail, Essence
   cost/runway, binding blockers and a concise uncertain projection: dominant tendencies, important
   tensions and visibly open/unwritten dimensions. It does not promise spawn counts, reveal sites or
   reproduce the complete pressure table.
7. Only final **Bind & Depart** spends Essence, consumes a collected World Page and creates the run. Home's
   departure shortcut opens this review and commits nothing.
8. A successful bind receives a short page-to-place transition: the page closes/fills and hands the exact
   frozen world receipt to the arrival splash. This may be restrained; it may not reroll or invent facts.

### Acceptance

- A new player can make or select one page without interpreting the screen as a parameter form.
- The page seen in Write, projection and History is recognizably the same artifact.
- The projection distinguishes facts the page strongly implies from facts left open to generation.
- Viewing, switching tabs, opening detail and cancelling change no resources or page ownership.
- A successful bind charges and consumes exactly once and the entry identity comes from that same receipt.

## 2. World arrival: dramatize the written result without leaking it

### Intended experience

Arrival is the reveal of a possibility becoming inhabitable. It should give the player an immediate
emotional and visual answer to “what did this writing make?” before presenting the navigation grid.

### Native integration contract

1. Integrate the accepted **lifecycle-splash v0.3** grammar rather than drawing a second unrelated splash.
2. Use a framed book illustration/page-like tableau made deterministically from the exact bound world
   descriptor and the same asset identities used in the explorable map.
3. Compose only legitimate entry knowledge: dominant terrain/material, current light, actual atmosphere
   and non-spoiling ecological silhouettes. Do not reveal an undiscovered resource, site, traveller or
   identifiable rare/apex creature.
4. Echo authored causality with at most two short lines:
   - one concrete statement about the strongest authored/resolved identity;
   - one concrete tension or uncertainty if it materially affects the opening.
   These are descriptions, not riddles and not a generated lore monologue.
5. Keep the world title, source-page thumbnail and entry action visually subordinate to the scene. The
   screen is a reveal, not a receipt table.
6. Enter the exact map state after dismissal. The splash cannot create a second camera truth, entity
   placement, palette or weather state.
7. Reuse the same world identity on exit/return while showing the actual lifecycle outcome: portal return,
   defeat/emergency extraction, collapse and anchored continuity remain distinct.

### Acceptance

- Three starter worlds are identifiable from their arrival tableaux before reading the title.
- Two materially similar worlds remain visual relatives; an opposed pair separates proportionally.
- The first visible map region feels continuous with the splash rather than like an unrelated board.
- Entry never leaks a hidden POI, traveller, resource or apex identity.
- Save/relaunch produces the same composition for the same frozen world receipt.

## 3. Explorable worlds: places with proportionate identity, not recolored grids

### Governing rule

World visuals reflect **relative meaningful diversity**. Identical resolved visual facts may look
identical, nearby inputs should look related, and opposed authored/resolved facts should separate
proportionally. Runtime never forces novelty merely because the player recently saw a similar world.

### Layer responsibilities

1. **Material/ground:** ground family, bounded material palette family, adjacency, passability, cracks and
   real elevation own terrain shape. Material/color changes alone never create false sidewalls.
2. **Hydrology:** water/deep water, shoreline, flow/standing forms and wet substrate own their recognizable
   geometry. Color supports but never owns passability or depth.
3. **Ecology:** the actual persisted 1–4 flora species, coverage, stature and habit create living pattern.
   Vitality changes legitimate abundance/richness, not a universal green tint.
4. **Atmosphere:** actual medium, density and scoped color add bounded scattering/particles. A gray palette
   cannot invent smoke or sight obstruction.
5. **Illumination:** current light changes the visibility field and local emitted-light treatment, not the
   inherent terrain palette. Torch modifies this layer.
6. **Authored color:** CMY+Depth ink stays attached to the eligible written subject and resolves at bind
   through the versioned scoped-color receipt. Ash/open leaves that eligible scope open; it does not make
   the world black. Unwritten color remains legitimately random and frozen.
7. **Objects and inhabitants:** resources, sites, travellers and creatures retain stable silhouettes and
   provenance. World light may grade them but cannot erase identity or leak hidden information.
8. **Camera:** all explorable-map assets, including neutral and triggered flora, remain straight top-down.

### Map composition changes

- Remove an unconditional full grid as the dominant visual structure. Tile boundaries should arise from
  actual material, water, contour, route and discovered-object geometry.
- Use clusters, clearings, shore shapes, trails, rubble fields and growth habits so world structure reads
  above individual square cells while retaining exact tile movement.
- Preserve opaque unexplored fog. Remembered-but-not-currently-visible terrain can remain recognizable but
  cannot reveal moving/content state.
- Minimap remains a disclosure-neutral navigation abstraction; it reflects explored terrain/growth class,
  not every flora specimen or hidden POI.

### Acceptance

- A phone contact sheet of near/mid/far world pairs is judged proportionate, not merely “different.”
- Grayscale preserves water depth, passability, elevation, cracks, route and hazards.
- Similar worlds do not receive artificial recolors; extreme authored facts do not collapse to a muted
  common palette.
- A player can identify at least terrain family, water relationship, ecological density and one important
  atmosphere/light fact from the map without opening DEBUG.

## 4. Environmental consequences: warn before impact when knowledge permits

### Intended experience

Exploration becomes observation and choice rather than stepping blindly, taking a penalty and reading an
after-the-fact message. Warnings describe only visible facts the party could legitimately know.

### Adjacent consequence cues — first slice

1. Evaluate the four cardinal adjacent tiles after movement, visibility, collapse and world-state changes.
2. A **red glowing crescent** on the corresponding side of the party marker means that visible adjacent
   space contains a known direct-harm/affliction hazard.
3. **Three grey drag lines** on that side mean that entering the visible adjacent terrain costs extra world
   turns. Mud, rubble and dense growth keep their own terrain identity; the cue communicates the shared
   consequence rather than pretending they are the same material.
4. If both consequences apply, show the grey inner lines plus red outer crescent. Do not add a third stacked
   badge to the same edge in v1.
5. Slow footing may be readable on first sight. A flora harm cue requires either:
   - this campaign has been harmed by that exact flora species/defence before; or
   - the active party legitimately recognizes it through the settled Wayfarer's Table/field-recognition
     contribution.
6. Hidden/crypsic creatures and unrevealed tiles produce no cue. The system never changes the minimap,
   discovers a POI or previews beyond current rules-owned visibility.
7. Cues are deterministic, spend no turn and contain no random danger roll. Motion is a restrained pulse or
   shimmer only; shape and location remain sufficient when motion is absent.
8. **Look → direction** explains the exact visible reason in plain language before movement: turn cost,
   passability and known hazard. Entering an impassable tile uses contextual text such as deep water,
   chasm or collapsed ground rather than “the ground crumbled away” for every refusal.
9. Seamlight remains a separate pale/blue portal-direction grammar and appears only after its item is used
   or the later Seamward passive applies. It is not another generic danger cue.

### Later field agency, after the cue proof

- Add one prepared **seeker instrument** through the existing Field Kit/Survey Post loop. It spends a world
  turn to report a direction sector and signal strength for a chosen known family, not an exact route or
  coordinate. The source must be reachable; “no signal” is valid.
- First proof targets mineral/world-resource families. Later instruments may seek medicinal flora or
  creature sign. Guaranteed ordinary writing never requires a seeker.
- Seeking does not clear fog or place POIs on the minimap. Precision and narrower target families can
  improve through real field-instrument progression.

### Acceptance

- A player can choose among safe, slow and known-harmful adjacent steps before committing one.
- Repeating a learned harmful encounter changes future field information without becoming global
  omniscience.
- Look copy and movement refusal always name the actual local fact.
- No cue leaks fog, hidden enemies, undiscovered sites or unrevealed resources.

## 5. Loot and resources: recognizable recovered evidence, not receipt rows

### During exploration

1. A discovered resource or object uses its stable family silhouette on the map and in the Field Kit.
2. Collection gives a short object-to-satchel/reserve motion and updates the corresponding compact icon
   quantity; it does not interrupt exploration with a full-screen list.
3. Gear, consumables and curios use exact item instances and real capacity rules. World resources—including
   Hides and Bones—enter the non-slot resource reserve, retain sample grade/properties/provenance, and never
   consume item/satchel slots.
4. The HUD shows only the compact carried summary needed in-world. Tap opens anchored detail; it does not
   permanently print every object name.

### Return presentation

Present the haul as a laid-out collection with four semantic groups:

- **Resources:** six-across resource silhouettes with aggregate quantity; `Hides +19` is one object tile,
  not nineteen `Hides +1` lines. Tap exposes retained sample grades/properties and origin.
- **Items:** six-across exact-instance icons, with quantity only where the item genuinely stacks.
- **Writing recovered:** physical page/book tiles, permanent Diary/lexeme result and source.
- **People who came home:** identity tiles and exact arrival/recruitment result.

XP/progression remains a concise breakdown after the recovered evidence. Failure/loss uses the same object
grammar so the player can tell what was lost rather than reading a generic receipt. Continue is available
only after the recap has been presented once, but detail inspection is optional.

### Progression option — deliberately not yet settled

Do not immediately hard-gate Gold behind Binder level. That would let a player deliberately write/find a
valuable world and then discover that an arbitrary number makes it unusable. The recommended experiment is
**capability-based extraction**:

- common exposed material is always collectable;
- a hard/delicate/volatile source yields a small surface sample with the basic kit;
- the correct tool/training enables full yield, better retained quality/properties, safer collection or
  lower turn cost;
- no tool durability system is implied;
- disposable worlds always permit some meaningful takeaway because “return later” is not reliable before
  anchoring.

Test this first on three families—hard ore/Gold, fragile Quartz and one organic source—before redesigning
all resources or gear. Mara/Survey Post owns detection and field instruments; Halloway/Blacksmith may own
extraction tools; Sela/Wayfarer's Table owns practical flora recognition/packing, not a route-map subsystem.
If the proof creates satisfying preparation choices, expand family by family. If it feels like arbitrary
denial, retain seeking and current collection rather than forcing a resource overhaul.

### Acceptance

- The player recognizes common loot/resource families without reading every label.
- Return aggregation, reserve quantities and exact instance identities agree after relaunch.
- Resources never consume item capacity or spill into item overflow.
- Tapping any edge/bottom object keeps its anchored detail on-screen and returns to the same collection
  position.
- Provenance answers “what world/creature/site produced this?” and suggests a real future use.

## 6. Home: a growing community rather than a station menu

### Intended experience

Home is the stable place altered by people and expeditions. The player should recognize where work happens,
who contributed it and what changed since the last return without traversing a simulation-heavy town.

### Destination-board correction

1. Preserve the settled **Home / Make / Study / Realms** navigation groups, but present each as a consistent
   illustrated district/page of the same Base—not a categorized settings list.
2. Station positions and silhouettes are stable. Foundation, built, improved and damaged states alter the
   same place rather than creating a new menu row.
3. The opening Home view contains exactly Writing Desk, Storehouse, Firepit, Essence Spring and Workshop,
   with Party and departure as utilities rather than fictional buildings.
4. A station tile leads with its structure and function silhouette. Its name and at most one truthful
   attention state support the image; it is not a large card containing its full backend.
5. New people leave a small authored signature at the station they enable and appear in the Base's people
   context even when assigned to the travel party. Do not make a building unusable because its owner is
   currently travelling.
6. Return changes are visible on the board: a constructed destination, a refreshed merchant, one waiting
   recovery, or a newly available contribution may receive a restrained marker. No decorative exclamation
   marks and no invented chores/upkeep.
7. Entering a place reveals only its distinct verbs. For example, Wayfarer's Table owns packing, provisions,
   practical field notes/visible-flora recognition and related yield; it does **not** own a campaign route
   graph, world selection or a second departure system.
8. Home's departure shortcut opens Writing Desk → The world and commits nothing. The only bind transaction
   remains inside Writing Desk.
9. The board fits its finite opening set on an ordinary 368×800 phone without unnecessary scrolling. Later
   districts may scroll/page because their collections are genuinely larger, not because tiles have
   arbitrary oversized minimum heights.

### Acceptance

- A fresh-save player can point to the five opening places and describe each first payoff.
- Recruiting/building changes one persistent visual location and unlocks one understandable contribution.
- The player can find Storehouse, Writing, Party and departure from visual place identity rather than
  remembering a list position.
- No destination mockup invents mechanics merely to fill visual space.

## 7. Character growth and combat skills: visible builds rather than administration

### Party/person shell

1. Party is a compact identity grid; all five ordinary party slots fit at 368×800. Each tile shows portrait,
   name, health/level and labelled rank without becoming a full-width button.
2. Tapping a person opens stable tabs such as **Overview / Gear / Combat / Gambit / Story**. Do not show every
   stat, biography, equipment slot and rule on the collection surface.
3. Overview visualizes the person's current role and consequential changes. Gear uses body/slot placement
   plus the exact six-across source tray. Gambit remains an ordered list because order is its mechanic.

### True combat graph

1. Replace production `Learn next`/branch-card progression with the accepted real fan-and-fork graph derived
   from stable node IDs and generated Effect copy. It is a mechanics migration, not a reskin.
2. Show the three roots, parent connectors, cross-discipline alternate prerequisites, owned/available/
   blocked state and the person's unspent point count simultaneously at ordinary size.
3. Tap selects a node and opens collision-aware anchored detail with exact effect, prerequisites, current
   loadout applicability and explicit **Learn**. Merely selecting never purchases.
4. Purchase is one typed atomic legal transaction: spend one point, persist the exact stable node, reveal
   newly available nodes and preserve state through save/load. A stale/illegal request changes nothing and
   explains why.
5. The first three to four earned points must create tactically different routes—different actions,
   targeting, reach, protection, control or preparation—not only slightly different percentages.
6. A learned active technique appears in the combat action palette with the same identity. A passive shows
   its contribution in the relevant derived breakdown rather than pretending to be a new button.
7. Companions arrive with legal coherent authored experience and any flexible points clearly separated.
   Existing saves preserve stats and legal ownership; unresolved legacy nodes return points rather than
   silently substituting another skill.
8. Respec remains a deliberate full rebuild at the Essence Spring with exact cost, removed techniques and
   returned point budget. No auto-recommended rebuild and no tutorial gate.

### Combat presentation connection

The encounter stage must answer four questions before requiring log reading: whose turn, who is threatened,
who can reach whom and what effect just changed the state. Technique/condition icons and target geometry
carry those answers; the ordered combat log remains supporting evidence rather than the primary interface.

### Acceptance

- Levels 2–5 expose meaningful divergent legal purchases with exact point accounting.
- Two characters at the same level can visibly and tactically differ.
- Active/passive effects agree among graph detail, combat control, calculation and recap.
- Purchase/respec survives relaunch and cannot double-spend, lose a point or infer ownership from graph
  position.
- Production is recognizably a tree at ordinary phone size; DEBUG-only graph proof is not claimed as shipped.

## 8. Character meetings: live in reachability order, reviewed through play

“Atlas review” means the DEBUG Authored Text Atlas: a searchable browser that lets Aimee read, flag and
revise every dialogue/clue outside normal play. It is useful for batch editing but is **not a release gate**.
The phrase “without waiting for advance Atlas review” means:

- a coherent, schema-valid completed meeting is promoted into the live traveller catalogue in campaign
  order;
- the Atlas mirrors that same live text and remains available for optional review;
- Aimee encounters the meeting normally, submits a bug/text flag if it feels wrong, and that exact stable
  unit can be revised afterward;
- incomplete, contradictory or mechanically impossible content remains draft-only, but absence of a prior
  thumbs-up/rating does not block coherent content.

Promotion batches follow actual reachability:

1. opening economy/recruitment characters the player can meet now;
2. the Band-3 cast once their clue/condition and contribution paths are reachable;
3. each later band only when the preceding campaign loop is playable.

Each batch promotes exact meeting object, stable exchange IDs, recruitment/decline outcomes, clues/pages,
voice authority and any first contribution together. It does not install a late station backend merely
because that traveller's prose exists. Exact catalogue order and current live/missing census are rederived
from the reconciled source before every batch, never copied from an old audit.

## 9. Early combat curve and testing safety

### DEBUG Godmode — recommended support, not balance

Add **God mode (testing)** under DEBUG Settings:

- default off and clearly persistent on-screen while active;
- all enemy turns, damage calculations, conditions, cooldowns and logs still execute;
- active party members cannot be reduced below 1 HP and the defeat transition is suppressed;
- it grants no damage bonus, instant victory, extra loot/XP or encounter-generation change;
- bug reports and encounter receipts record the flag, and balance evidence from such a run is labelled
  invalid;
- freeze the flag for an encounter so toggling it mid-transaction cannot create ambiguous receipts.

This allows noncombat testing without making ordinary combat artificially easy. It is not a player-facing
difficulty mode.

### Scaling closure

Finish the existing causal scaling work before deeper combat nodes:

1. verify isolated Normal and disclosed Teeming contacts with fresh Binder + Quill and baseline gear;
2. run party sizes 2/3/5 at low, mid and uneven reachable levels;
3. keep world danger/species identity primary and use additive party power to prevent another body from
   lowering pressure;
4. scale composition/action pressure as well as durability—do not solve every mismatch with health inflation;
5. preserve the meaning of progression: old/easy worlds may become easy, Teeming remains denser, and apexes
   remain optional major threats;
6. require readable avoid/retreat/contact agency where a fight legitimately exceeds the comfortable band;
7. tune from receipts with Godmode off, not from fixture victory alone.

Opening target remains an ordinary one-foe Normal contact in roughly 2–4 rounds and about 5–20% aggregate
party HP, with wider bands for legitimate groups. Apex tuning is a separate 2/3/5-person gate.

## 10. Granular implementation order

### Phase 0 — repository truth (**complete**)

- Reconciled `main` preserves the installed phone-source baseline and current Design authority.
- Rejected/historical/unfinished work remains preserved outside `main` rather than silently merged.
- Every future assignment begins by checking HEAD/origin, dirty ownership, visual disposition and installed
  provenance.

### Phase 1 — make current testing honest

1. DEBUG Godmode, with receipt marking and no reward/scaling mutation.
2. Finish the early combat scaling acceptance matrix with Godmode off.
3. Verify the existing Campaign → Home → Writing → World → Return chain for three fresh-save expeditions.

**Exit:** Aimee can test any current noncombat feature without repeated defeats, while ordinary combat has
one accepted early curve rather than being alternately lethal and trivial.

### Phase 2 — make the first expedition causally legible

Implement as separate receipts in player order:

1. Writing Desk composition/projection transaction.
2. Native entry/exit lifecycle splash using the accepted compositor.
3. World-grade-2 relative-diversity integration and map material/ecology composition.
4. Adjacent harm/slow cues plus exact Look/blocked-movement language.
5. Compact in-world collection and object-like Return layout/resource aggregation.
6. Home district/place presentation and return-state changes.

**Exit:** three starter/free-written worlds visibly connect page, place, decisions, haul and Home without
DEBUG explanation or hidden POI leakage.

### Phase 3 — make the first progression arc expressive

1. Production true combat graph and levels 2–5 purchase/respec acceptance.
2. Opening traveller meetings promoted in reachability order and reviewed during play.
3. First mineral seeker-instrument proof using the Field Kit/Survey Post grammar.
4. Continue Band-3 meetings only as their clue and contribution paths become reachable.

**Exit:** the player has at least one meaningful build fork, one deliberate field-preparation choice and a
growing community whose people are actually encountered.

### Phase 4 — test deeper gathering before committing to a revamp

1. Three-family capability-based extraction proof: hard ore/Gold, Quartz and one organic source.
2. Measure whether partial basic yield plus improved trained yield creates anticipation rather than denial.
3. If accepted, define the minimum extraction-tool recipes and extend by resource family.
4. Only then revisit the broader resource/gear economy. Do not create durability, mining levels or a complete
   equipment rewrite as accidental dependencies.

### Phase 5 — broaden only behind a reachable complete band

- Promote later meetings, stations, specialist shops, combat nodes and resource techniques in the order the
  playable campaign reaches them.
- A later feature enters implementation only when its prerequisite loop is implemented, installed and
  playable—not merely documented or green in isolation.
- Tutorials remain dead last, after the mechanics and layouts they would teach are stable.

## Cross-lead acceptance discipline

Every slice receives separate receipts for settled Design, visual candidate, visual approval, frozen asset
contract, source completion, integration, installation and playtest acceptance. “Implemented,” “looks good
in AssetLab,” “is on the phone” and “feels good in play” are not interchangeable.

No Asset mockup may invent behavior to fill a screen. No Engineering implementation may replace a place,
tree, page or object with a generic list because that is easier to wire. No Design audit counts as progress
unless it closes an ambiguity needed by an implementation, playtest or player-facing correction.
