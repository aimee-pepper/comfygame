# First-three-worlds execution plan — current

**Status:** Cross-lead execution authority beneath `player-progression-implementation-roadmap-current.md`.
This document translates Bands 0–3 and the causal-presentation plan into bounded implementation and
acceptance packets. Later roadmap bands remain ordered but are not expanded here.
**Priority authority:** Aimee's latest explicit priority calls; live item state remains
`Sources/Content/Data/playability-roadmap.json` and must be re-read before every dispatch.
**Updated:** 21 August 2026

## Non-negotiable scheduling rules

1. **Do not dispatch from this document blindly.** Before every packet, the orchestrator reads current
   `origin/main`, the live roadmap JSON, the Engineering task and the Asset task. The handoff states current
   active item, player-visible result, stable dependencies, rework risk and displaced item. If any fact is
   missing, no order is sent.
2. **One Engineering primary.** A packet closes as committed/green and either installed for acceptance,
   accepted, or explicitly blocked before Engineering starts the next packet.
3. **Asset works only for the named current/next native consumer.** A proof does not create mechanics and
   cannot expand into a gallery programme. Idle is valid.
4. **Game Design prepares at most two packets ahead** and designs actual content/systems rather than
   repeatedly auditing closed work.
5. **No tutorial work.** Tutorial remains dead last. Ordinary persistent labels/help needed to operate a
   current mechanic are part of that mechanic, not tutorial popups.
6. **Ordinary phone first.** No XXL/accessibility-size matrix, exhaustive device matrix, localization or
   final-art polish before the ordinary screen/mechanic is accepted. Correct transaction, touch geometry,
   visibility and motion-reduction fallback remain part of structural correctness.
7. **Save compatibility:** preserve when contained and honest. If a necessary early schema redesign cannot
   migrate safely, increment save format compatibility, label incompatible files before load, preserve
   export/delete, and keep only the newest gameplay implementation.
8. **No bundled acceptance.** Several source-complete changes may coexist in one build because main is
   cumulative, but Aimee receives one short acceptance card per outcome so a failure reopens only its exact
   packet.

## Current dispatch state

At authoring time the live roadmap reports `encounter-scaling` as the sole `inProgress` primary. Starter
World Pages, visibility, collapse HUD, contextual blockage, field notes, plain-language clues, the slot-free
material reserve, Dictionary, Templates, first combat choices, traveller pacing and world color are already
source-complete/`readyToTest` candidates. **This plan does not order anyone to reimplement them.**

No new packet below may pre-empt the **source implementation** of scaling. Phone playtest/acceptance is not a
dependency gate: once the rules, receipts, automated matrix and no-known-P0 source checkpoint are green,
Engineering marks scaling `readyToTest` and advances to the next source checkpoint even if Aimee is not
currently motivated to test combat. A later playtest finding may reopen scaling at its real severity.

---

## Gate A — make the opening survivable and testable

### A1 · Complete level-1 encounter-scaling source, then leave acceptance nonblocking

**Player result:** Normal Binder + Quill contacts are usually survivable and meaningfully interactive;
Teeming is visibly disclosed as exceptionally dangerous rather than silently normalized.

**Engineering:** do not add more combat nodes. Freeze one encounter-scaling receipt containing world danger,
creature budget/cast, party count, each member's level/gear power, foe level/power, apex flag and final
composition. Tune from the existing rules authority, preferring encounter composition/action pressure over
universal HP inflation.

**Asset:** none unless a current danger/foe telegraph is demonstrably unreadable in the phone matrix.

**Deferred/nonblocking acceptance card:** God mode off; fresh Binder + Quill. Two isolated Normal contacts, one ordinary Normal
world with sequential contacts, one disclosed Teeming contact attempted/withdrawn. Record rounds,
aggregate HP loss, passed-out members, retreat possibility and whether the danger was legible. Then later
fixtures for parties 3/5 and uneven levels may be source-tested now but phone-accepted when reachable.

**Source-complete gate:** deterministic automated/simulator fixtures cover fresh Binder+Quill Normal,
sequential contacts, Teeming disclosure, parties 2/3/5, uneven levels and apex scaling; every encounter
freezes a truthful receipt; no known generated Normal composition is mathematically unwinnable under the
intended action model. Build/tests are green. Engineering may then proceed.

**Playtest target, not queue gate:** Normal isolated fights usually last 2–4 rounds and cost roughly 5–20%
aggregate party HP; Teeming may exceed that. This target remains adjustable when Aimee next feels like combat
testing.

**Prohibited:** difficulty modes, starter-weapon grants, deeper tree consumers, apex rewards, late party
balance or God-mode evidence counted as balance.

### A2 · Add DEBUG God mode (testing)

**Player result:** Aimee can test noncombat systems without repeatedly dying, while ordinary balance remains
measurable separately.

**Exact behavior:** DEBUG Settings toggle; off by default; frozen at encounter creation. Enemy decisions,
damage, conditions, cooldowns and logs execute normally, but active party HP cannot fall below 1 and defeat
does not transition. No damage, accuracy, loot, XP, spawn or retreat bonus. Persistent banner/encounter and
bug-report receipts say `God mode testing`; balance telemetry is marked invalid.

**Pass:** toggling outside combat affects only newly opened encounters; relaunch preserves setting; an
otherwise lethal encounter proceeds at 1 HP; turning it off before the next encounter restores ordinary
defeat.

**Prohibited:** mid-encounter toggle, instant win, invulnerability that skips condition/log calculations,
shipping as a player-facing difficulty mode.

### A3 · Install and accept the already-built Band-1 truth fixes

**Player result:** one current-source phone build exposes Starter Pages, truthful collapse phase, contextual
blocked movement, current visibility, field notes, plain-language clues and non-slot harvested materials.

**Engineering:** integrate nothing from preservation branches by name. Build only from current clean main;
run each existing validator/focused suite; install only with Aimee's explicit approval and exact source/build
receipt. If any candidate is not ancestral/current, stop and report it instead of recreating it.

**Acceptance cards, individually:**

- three Starter Page instances survive relaunch, consume only on successful bind and preserve runway;
- stability phase no longer claims `turns left`; collapse progress is truthful;
- deep water/chasm/collapse refusals name the correct fact;
- hidden/fringe cells reveal neither terrain adjacency nor content; low-light radius changes visibly;
- field notes vary from truthful local world facts rather than one generic line;
- one traveller clue can be paraphrased as an observable world property;
- 19 Hides/Bones take zero item slots and aggregate once (category wording is transitional until E1).

**Prohibited:** visual-polishing the temporary combined resource category, adding tutorials, or accepting all
seven because the build launched.

**Gate A source exit:** current main can start one fresh save, use a Starter Page, produce deterministic
intended Normal/Teeming scaling receipts, understand visibility/collapse/blockage and return with no
item-capacity loss from body materials. Aimee's phone acceptance cards remain independently `readyToTest` and
do not block Gate B.

---

## Gate B — make writing visibly cause the first world

### B1 · Template instant reconstruction acceptance

**Player result:** one tap on a saved Template restores the complete saved rune layout so repeated writing
does not require replacing every mark.

**Authority:** `world-pages-templates-dictionary-current.md`.

**Exact behavior:** Pages → Templates → tap template. Empty draft loads immediately. A nonempty different
draft asks `Replace current draft?`; confirm atomically remaps every placed mark instance ID and every link
endpoint, restores hand/layout/current persisted Page fields, then returns to Write. It never binds, spends
Essence, consumes a collected page or copies a collected page. Binding cost is recalculated normally.

**Engineering:** verify source-complete implementation; fix only contradictions. Later explicit-ink receipt
migrates into templates when Ink Mixing is canonical; do not invent placeholder ink state.

**Asset:** one compact Template thumbnail state and replace confirmation only if current six-across Pages UI
does not already convey it.

**Pass:** save/load/rename/overwrite/delete/relaunch and two link-remap fixtures; loaded draft is visibly the
same arrangement and remains editable.

### B2 · Writing Desk composition/projection correction

**Player result:** Write feels like manipulating a page; The world truthfully explains what the page strongly
causes, what remains open and what departure costs—without becoming a backend parameter form.

**Engineering input:** existing Write / Pages / The world architecture, Page/Projection rules and atomic bind
transaction. Preserve the projection facts currently used by native rules; no gallery value becomes real
merely because it appears in a mock.

**Asset packet:** ordinary-phone Write, Templates loaded, and The world states. Paper gets the primary area;
rune/tool tray is compact. The world includes page thumbnail, concrete projection, authored/open distinction,
Essence cost/runway, stability/hold behavior, legitimate danger/harvest preparation and exact blockers in a
scrollable body above fixed final action. Do not use an oversized decorative page that hides information.

**Engineering checkpoints:**

1. freeze one view model from current rules;
2. integrate Write layout without changing Page mutation;
3. integrate The world from the same view model;
4. prove cancel/tab/detail are zero mutation;
5. prove final Bind & Depart consumes once and hands one world receipt to B3.

**Pass:** Starter Page, blank page and authored Gold page. Gold warning follows the extraction authority once
that capability exists; unknown marks never leak.

**Prohibited:** direct bind from Home, arbitrary spawn counts, hidden POIs, a settings list, gallery-only
invented forecast fields.

### B3 · Frozen arrival receipt and concrete description

**Player result:** after a successful bind, the game can describe the exact world without rerolling or
spoiling it.

**Authority:** `world-arrival-causal-reveal-current.md`.

**Engineering:** persist the pure `WorldArrivalReceipt`; implement the exact deterministic two-sentence,
18–55 word grammar from `world-arrival-description-grammar-current.md` and exact disclosed facts. Validate
prohibited riddle register, reshaped/increased/reduced/none causal contribution and no
unknown-mark/site/entity leak.
No visual promotion yet.

**Pass:** Open Flats, Rainwashed Shore, Stone Hollow; near/far world pairs; relaunch identity; unknown mark;
hidden site/apex/resource; missing optional fact.

### B4 · Native dynamic arrival reveal

**Player result:** dynamic generated image plus concrete description visibly connects the written page to the
map before exploration.

**Asset:** exact B3 receipt adapter into accepted lifecycle-splash grammar. Prove the three starter seeds
(Open Flats 67, Rainwashed Shore 26, Stone Hollow 23),
near/far pairs, first-map continuity and the still-open entry-visible-site candidate. Site candidate is a
review pin; base v1 cannot reveal a hidden site and does not wait on this decision.

**Engineering:** integrate only after Asset proof uses the exact game receipt. Loading screen remains separate.
World reveal appears after the world is ready and resumes/dismisses idempotently.

**Pass:** physical phone shows no askew/cropped splash, deterministic scene/description, accurate first map;
same receipt survives relaunch.

### B5 · World visual-relative-diversity acceptance

**Player result:** worlds look proportionally related/different according to actual pressures, not like one
grid under random recolors.

**Engineering/Asset:** accept/integrate current world-grade-2 adapter only if current main does not already own
it. Use material, hydrology, ecology, atmosphere, illumination and scoped authored color separately. Remove
full-grid dominance while preserving exact tile movement. No false sidewall from color/material boundaries.

**Phone set:** the three starter worlds, one near pair, one far pair, one Ash/open-color world, true
elevation beside material-only change, color and grayscale.

**Pass:** similar stats look similar; opposed stats separate; no hidden adjacency/content leak; map and splash
agree.

**Gate B exit:** compose/load Page → truthful projection → bind → dynamic image+description → matching world,
with the causal chain readable without DEBUG.

---

## Gate C — make exploration observational and recovery tangible

### C1 · Adjacent consequence preview and contextual Look

**Player result:** learned harm and slow terrain are visible before movement; Look explains the actual tile.

**Authority:** `field-feedback-and-loot-presentation-current.md`.

**Engineering:** one pure four-direction preview owns both cues and Look. Implement red harm crescent, three
grey drag lines, combined state and exact blocker copy. No map-content mutation.

**Asset:** integrated native-scale sheet for all four directions/backgrounds, combined states and fog boundary.

**Pass:** known/unlearned damaging flora, mud, combined hazard, deep water, chasm, collapsed cell, hidden and
fringe-only cell, state change after preview. Aimee visually tunes actual-phone clarity.

### C2 · Local pickup feedback

**Player result:** a recovered object icon rises locally about 1.5 tiles and fades; collection feels physical
without crossing the screen.

**Engineering:** transaction receipt drives 450 ms animation after immediate authoritative mutation; edge
clamp, same-kind aggregation, three-kind burst cap and cancellation safety exactly follow the field-feedback
authority.

**Asset:** world resource, creature material, item, page and unknown feedback icons at native map scale.

**Pass:** ordinary/top-edge pickup, `×19` body material, multi-kind site result, navigation cancellation,
duplicate tap and reduced-motion fallback.

### C3 · Return collection layout

**Player result:** Return presents recognizable collected evidence before XP, not many receipt rows.

**Engineering:** one frozen outcome receipt; groups **World resources / Creature materials / Items / Writing
recovered / People who came home**, then concise XP. Six-across icons; quantities aggregate by legitimate
family; exact items remain exact instances; anchored detail remains in viewport.

**Dependency:** E1 storage/category split must be source-stable before final Creature-material group is
accepted. Until then, underlying material preservation may ship, but do not polish or approve the temporary
combined Resources presentation as final.

**Pass:** 19 Hides once, Hides and Bones separately, two different pelt property profiles retain provenance,
exact item instances, page/person, failure/loss and relaunch.

**Gate C exit:** player can inspect before stepping, recover objects with local feedback and understand the
exact haul on return.

---

## Gate D — make the Base a house and growing village

### D1 · Attention-event receipts

**Player result:** real new/updated destinations can glow until checked without fake chores.

**Authority:** `home-house-and-village-current.md`.

**Engineering:** stable idempotent events for construction complete, contribution unlocked, stock refreshed
and waiting item/recovery. Exact clear rules; DEBUG injection. No scene art yet.

### D2 · Binder House cutaway

**Player result:** Base opens on the Binder House/yard containing the settled Writing Desk, Library, Party
and yard Essence Spring anchors plus left/right/down arrows to Commerce Row, Makers' Row and The Commons.
Workshop and Constellation remain noninteractive/removable in this proof until Aimee settles their role.

**Asset:** follow `home-village-library-asset-packet-current.md`: Library first, three districts second, then
the provisional four-anchor cutaway/yard plus three-arrow collision/value packet. **Engineering:** wait for
the role decision and accepted proof before freezing the hotspot manifest; then use normalized shared
art/hotspot adapters, measured 368×800 fit, direct existing routes, Library-contained Bestiary and
noncommitting Prepare a world. Promote behind reversible fallback, then ordinary acceptance.

### D3 · Village exterior

**Player result:** House is its own root screen; Commerce Row, Makers' Row and The Commons hold the village.
Storehouse/Firepit are in The Commons, Essence Spring is in the house yard, and recruit buildings appear as
real campaign progress.

**Asset/Engineering:** exact lifecycle unknown/known-buildable/built/improved/attention. Standard pictogram+
name signs reinforce obscure silhouettes. Town never has damaged/repair states. Add only reachable buildings,
starting Trading Post → Recycler → Blacksmith.

**Pass:** all three district routes/Home returns, Storehouse and Firepit geography, construction plot, one
improvement, all four attention reasons/clear/relaunch, three obscure sign identities, no duplicate House
tile, no hidden future building and no town damage under defeat/collapse.

**Gate D exit:** the opening Base reads as house/community and retains every real opening verb.

---

## Gate E — correct living-world ecology and recovered materials

### E1 · Split player-facing resource domains

**Player result:** Storehouse/Field Kit/Return distinguish **World resources** from **Creature materials**;
neither consumes item slots.

**Authorities:** `creature-ecology-and-materials-overhaul-current.md` and, once Aimee settles it,
`crafting-intuition-and-quality-review-current.md`.

**Decision dependency:** Engineering may implement habitat/body-family work before this checkpoint, but may
not migrate material storage, stacking, crafting, price or power while the hybrid is paused. Once settled,
World resources and Creature materials use explicit domains; resources stack by exact
`domain + family/resource + qualityBand`; Items remain capacity objects. Bestiary/World History preserve
known source records rather than pretending a merged unit still has one exact provenance.

**Pass:** zero item-capacity use; same-family/same-band stacks merge while different domains/families/bands
do not; every old unit and Tier1–4 gear instance migrates losslessly or is visibly version-gated; crafting,
commerce, Distillery, Scent Mask, Recycler, Instrument and refit/legacy-rework consumers match the accepted
model. No
parallel old grade or second player-facing rarity colour remains.

### E2 · Habitat-aware creature identities

**Player result:** wet worlds can contain actual water-bound fishlike life; terrestrial, shoreline and aerial
forms occupy plausible terrain while remaining strange pressure-generated creatures.

**Engineering:** persist `CreatureEcologyIdentity`, resolve terrestrial/shore/aquatic/aerial only after terrain
availability is known, use separate deterministic salt, and constrain spawn/roam tiles. Aquatic components
include shallow and deep water. Deep occupants remain non-enterable until they naturally reach shallow water
or a later legitimate interaction exists. No gameplay RNG perturbation or land-path rewrite.

**Asset:** ecology sheet crossing four habitats with feathered, finned, furred, plated/scaled and chitinous
forms; straight top-down world profile and existing Encounter/Bestiary morphology continuity.

**Pass:** aquatic never on land and stays in one connected shallow+deep component; terrestrial never in water;
shore stays shoreline; a deep-only fish is visible but not falsely enterable; same seed stability; old frozen
worlds retain identity.

### E3 · Body-derived creature-material rewards

**Player result:** creature bodies yield recognizable related parts—feathers/down, fins/oil, scales/plates,
pelts, chitin, fang/horn/claw/bone/ichor—rather than every animal becoming Hide/Bone quality variants.

**Engineering:** deterministic trait-to-part table and quantities from the authority. Remove random world
resource and curio/key drops. Add one 3% eligible gear roll per victorious ordinary encounter, never per
creature; source/campaign caps apply and copy frames it as recovered territory gear. Apex keeps its explicit
trophy plus body parts.

**Asset:** complete creature-material atlas with cross-family collision proof and body→yield specimen cards.

**Pass:** four ecology fixtures produce causally related, stable rewards; 100 failed gear rolls add none and a
forced success adds exactly one eligible ordinary item regardless of foe count; no resource/key/quest/unique/
apex leakage; Bestiary previews only legitimately learned possible yields.

**Gate E exit:** early worlds contain ecologically placed varied life and body-derived, slot-free creature
materials that are visibly distinct from world resources.

---

## Gate F — make character/build progression spatial and live

### F1 · Promote completed meetings in reachability order

**Player result:** every reachable traveller has coherent live meeting text; Aimee reviews it while playing.

**Engineering/Design:** promote exact schema-valid stable objects: opening trio first, then current Band-3
cast. Atlas mirrors live content but prior Atlas approval is not a gate. Promote meeting, replies, outcomes,
clues/pages and first real contribution together; do not install a late station merely because prose exists.

**Pass:** all currently reachable people have one live meeting, response choices actually branch, stable IDs
and old-save outcomes survive; bug reports name the exact text unit.

### F2 · Party shell and Diary route

**Player result:** five-person compact grid; character tabs Stats / Gear / Skills / Gambit; Diary opens the
Library entry and returns correctly.

**Authority:** `party-character-surface-current.md`.

**Pass:** no Story/Combat ambiguity, all rank labels, no unnecessary scroll, exact Diary back route and Gear
ownership unchanged.

### F3 · Production true graph for reachable points

**Player result:** first earned skill points are spent on an actual fan-and-fork graph and immediately change
combat.

**Engineering:** typed arbitrary stable-node ownership/purchase/migration precedes renderer promotion. Promote
accepted graph as Skills; exact solid parents and dashed OR alternatives; unsupported deeper nodes stay
blocked rather than inert. Do not implement the full late tree merely to draw it.

**Asset:** native-scale graph based only on generated nodes/connectors; no recommended route.

**Pass:** fresh roots and three-point forks, one hybrid alternative, relaunch, stale purchase, point receipt,
active/passive effect truth. Production has no `Learn next` list.

**Gate F exit:** current characters speak, equip and grow through understandable identities/graphs rather
than administrative lists.

---

## Gate G — disclosed resource capability progression

### G1 · Extraction domain and three vertical fixtures

**Player result:** the party understands that Iron is basic, Gold requires Extraction 2, and Adamant requires
Extraction 4; known Gold can motivate future preparation before it is mineable.

**Authority:** `resource-extraction-progression-current.md`.

**Engineering:** add data-owned required rank, active-party equipped Field Pick resolver, frozen node receipt,
no-turn under-equipped refusal and atomic harvest for Iron/Gold/Adamant. Writing warns for known explicitly
authored gated resource but does not block bind; unknown marks do not leak.

**Asset:** node detail/map rank-notch grammar for Iron 0, Gold 2, Adamant 4 and exhausted Gold.

**Pass:** no-pick opening can build Blacksmith; known Gold warning/refusal; appropriate pick success;
Home/nonparty pick ignored; node stable after relaunch.

### G2 · Complete mineral catalogue

**Player result:** every mineral uses the same understandable access progression.

**Engineering:** extend exact authority table to all current minerals and fail validation on omission. Higher
rank grants access only; no hidden yield bonus/durability/mining XP. Add Web World Generator columns for node
count, required rank and reachable/extractable count under selected party rank.

**Pass:** full catalogue validator plus representative soft, ordinary, valuable, strange and extreme seams.

**Gate G exit:** learning a valuable rune creates a disclosed equipment goal, not an arbitrary surprise or
progression deadlock.

---

## Later order after these gates

Only after Gates A–G are accepted does the detailed roadmap resume Band 3+ systems: Brush → Ink Mixing →
Fountain Pen; Mara/Edren/Sela contributions and wild World Pages; then midgame crafting/avoidance and one
complete reachable combat route. Advanced shops, Menagerie, Deep Works, Channelworks, Distillery, Anchoring,
late capstones, final art and tutorials retain their existing later bands.

## Per-packet handoff template

Every dispatch to Engineering or Asset must include exactly:

1. packet ID and linked authority;
2. current main hash and live roadmap item/status;
3. previous active packet closure receipt;
4. ordinary player-visible outcome;
5. exact included state/actions/visuals;
6. explicit exclusions and non-owned files/systems;
7. dependencies proven stable;
8. known rework risk;
9. focused automated gates;
10. phone/visual acceptance card;
11. source-complete vs installed vs accepted reporting language;
12. displaced item (`none` unless Aimee explicitly reordered it).

A handoff missing any field is a request for clarification, not implementation authorization.
