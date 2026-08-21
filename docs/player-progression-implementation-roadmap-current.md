# Player-progression implementation roadmap — current

**Status:** operational ordering authority beneath Aimee's priority calls  
**Date:** 21 August 2026
**Purpose:** order implementation by what a real fresh-save player can reach and test, rather than
by whichever late dependency is easiest to isolate in code.

For Bands 0–3, exact cross-lead implementation packets, dependencies, prohibited scope and phone cards now
live in `first-three-worlds-execution-plan-current.md`. This roadmap owns reachability order; that execution
plan owns how each early item may be handed off. A broad row here is never sufficient implementation
authority by itself.

This document supersedes any plan that treats “finish all combat nodes,” “finish all stations,” or
“clear every implementation-ready design” as one active work item. The machine board remains
`Sources/Content/Data/playability-roadmap.json`; its sequence and priorities must agree with the
bands below.

## Current reconciliation — 21 August

- Repository reconciliation is complete. `main`/`origin/main` reached docs-only checkpoint `7f61dcd` after
  preserving the accepted phone-source baseline `2d2e7ce` ancestrally and keeping rejected/unfinished
  packets outside main. The phone remains build 234 sourced from the accepted baseline; no later source
  completion is implied installed or accepted.
- The old shared checkout is clean on its named preservation branch. New Game Design packets in that
  checkout require one exact docs-only integration into current main before they are dispatch authority;
  no gameplay may be implemented from the preservation branch itself.
- The accepted/source-complete Asset and native candidates remain separate receipts. Writing, arrival,
  world visuals and Return are not accepted merely because components exist in AssetLab or on main.
- **Encounter scaling remains the sole active/acceptance primary according to the live roadmap.** Engineering
  and Asset were idle at this reconciliation check; no new source task is authorized by these docs alone.
- The next product milestone is still an accepted Campaign → House → Writing → World → Return chain over
  three fresh-save expeditions, now decomposed exactly by `first-three-worlds-execution-plan-current.md`.

Receipt meanings and mockup behavior fences are authoritative in
`cross-lead-delivery-contract-current.md`. A source-complete item parked for a later reachable band
is not a request for Aimee to test it now.

## The pipeline rule

At any time:

- **Aimee tests band N.** Bugs that prevent the band's loop are interrupts within that band.
- **Engineering builds band N+1.** It may repair band N from evidence, but may not begin N+2 or a
  later feature merely because its files are convenient.
- **Game Design prepares at most band N+2.** Later ideas may be recorded, but they do not become
  implementation assignments.
- **Asset supports bands N and N+1.** It may prepare an immediately required native contract, but a
  proof with no N/N+1 consumer is not progress. Idling is acceptable.
- One primary implementation checkpoint exists per workstream. A safe finished checkpoint is
  committed before priorities change; work is never abandoned half-transaction.

“Band” is a reachability window, not forced pacing. World count, level and traveller order are test
fixtures for when a feature should become reliable, not promises that every campaign advances on an
identical turn.

## Promotion rule

A band advances only when:

1. its complete ordinary player loop is reachable from a fresh or correctly migrated save;
2. no known bug blocks continuation, inventory control, combat survival, return, or the next
   authored bind;
3. its rules/persistence/UI focused suites are green;
4. the build containing it is installed; and
5. Aimee can perform the band acceptance card without DEBUG state mutation.

One failed feel sample may open diagnosis; it does not justify an unrelated feature or a global
retune. Conversely, a source-green feature is not accepted merely because tests exist.

Save evolution follows `save-compatibility-policy-current.md`: preserve campaigns when migration is
contained and honest, but do not let prototype compatibility block a necessary redesign or require
parallel obsolete gameplay implementations. An intentional break must be versioned and disclosed
before load, with export/delete available and the original file left untouched.

---

## Band 0 — The testable shell

**Reach:** before starting or loading a campaign.  
**Goal:** Aimee can repeatedly create, load, preserve and report on real test campaigns.

1. **0.1 Launch ownership:** static launch, first SwiftUI frame and save-loading composition remain
   aligned; progress is real or explicitly indeterminate; no black gap.
2. **0.2 Save control:** Continue, New Game, Load, export and confirmed delete work without one slot
   damaging another or legacy adoption losing data.
3. **0.3 Bug capture:** the floating reporter remains reachable, captures the actual screen and
   context, saves durably, and clearly distinguishes local Save from real submission.
4. **0.4 Base navigation:** Settings, Testing, Writing Desk, Storehouse, Party and return navigation
   cannot trap the player or bury their primary actions.
5. **0.5 Fresh-fixture discipline:** every later acceptance can start from a named fresh save or a
   copied migration fixture without deleting the campaign Aimee is currently playing.

**Exit gate:** cold launch → new campaign → save shelf → Settings/Testing → return → relaunch/load →
save a bug report, all on the phone.

## Band 1 — First world, first fight, first return

**Reach:** worlds 1–3; Binder + Quill; approximately levels 1–3; no recruited specialist assumed.  
**Goal:** the core game is survivable, understandable and repeatable before progression breadth.

1. **1.1 Blank and authored binding:** an empty page produces genuinely varied ordinary worlds;
   authored marks causally affect pressures; binding cost and Stability are truthful.
2. **1.2 Continuation economy:** each ordinary expedition exposes enough Raw Essence and anti-lock
   support that another authored bind remains possible without farming an impossible world.
3. **1.3 Level-1 encounter scaling — immediate primary:** Normal Binder + Quill fights usually last
   2–4 rounds and cost roughly 5–20% aggregate HP; Teeming may be dangerous without making an
   ordinary opening unwinnable. Diagnose baseline, grouping, world level and species before tuning.
4. **1.4 Starting World Pages:** a new campaign receives three optional, consumable curated pages
   whose known marks create distinct, affordable and survivable opening worlds; ordinary writing
   remains available immediately.
5. **1.5 World readability:** the full map, bottom border, fog, minimap, route, party, resources,
   portal and controls fit; POIs remain hidden until discovered.
6. **1.6 Causal arrival and visual diversity:** a frozen generated image plus concrete description leads
   into a matching map; terrain, flora, resources and world color reflect actual relative world difference
   while similar worlds remain related. Hidden sites remain undisclosed pending the explicit splash-site
   visual decision.
7. **1.7 Found writing:** every world contains at least one reachable writing; page acquisition and
   the return recap agree exactly.
8. **1.8 Contact authority and field consequence:** Look is safe and zero-turn; adjacent known harm/slow
   cues describe real visible consequences; apex/active flora require direct entry; ordinary creature
   contact and ambush state are visible and persisted.
9. **1.9 Basic combat usability:** Attack, starter techniques, target legality, items, flee, HP,
   armour, rank, status and passed-out state remain truthful. No late tree node is required here.
10. **1.10 Loot and equipment:** all accessible stored/overflow/worn/carried candidates are visible; exact
   gear identity survives swap, full storage, relaunch and recap; local pickup feedback preserves spatial
   cause; slot-free harvested samples never displace items.
11. **1.11 Return/failure truth:** portal, Waystone, collapse, defeat and abandon share the typed
    receipt; partial retention is stack-independent; pages, people, XP and exact loot appear.
12. **1.12 Complete loop proof:** write or choose a starting World Page → bind → explore → fight or
    avoid → collect → return → inspect loot/pages/XP → afford the next authored bind.

**Exit gate:** three Normal fresh-save expeditions including two ordinary fights and one failure or
emergency return; continuation succeeds and no summary/inventory fact is missing.

## Band 2 — Opening economy and the first three travellers

**Reach:** roughly worlds 2–8 / levels 2–6; Vance → Noll → Halloway.  
**Goal:** the player can sell, salvage, equip and make foundational gear early enough to keep testing.

1. **2.1 Traveller pacing:** at most one fully matching traveller appears per world; Vance, Noll and
   Halloway have the intended order; chance matches do not produce first-world crowds.
2. **2.2 Clue distribution:** recovered pages help target real candidates without long diaries
   swallowing the entire drop pool.
3. **2.3 Vance / Trading Post:** 10-Essence construction, safe selling, gold, persistent mixed stock,
   exact material/item purchases and no-weapon protection are playable.
4. **2.4 Noll / Recycler:** 15-Essence construction, honest recovery profiles and exact dismantling
   provide a distinct way to offload unwanted objects.
5. **2.5 Halloway / Blacksmith:** foundational construction, exact samples and useful early recipes
   work before advanced specialist shops matter.
6. **2.6 Storage/equipment presentation:** six-across icon grids, anchored details, Waiting,
   cross-character equipment and dashed “worn by someone else” state remain usable on phone.
7. **2.7 Opening item identity:** the resources, ordinary weapons/armour, sale stock, salvage output
   and loot seen in this band must be visually distinguishable. Late catalogue art is not required.
8. **2.8 Live character content:** completed Vance/Noll/Halloway meetings and clues ship; Aimee
   reviews them through play rather than preapproval.
9. **2.9 Opening-economy proof:** return → sell → buy → recycle → construct/re-equip → write the
   next world, with enough Essence runway preserved.
10. **2.10 Rune Dictionary:** known vocabulary and encountered `??` glyphs share one compact Library
    reference without revealing an unidentified meaning.
11. **2.11 Saved Templates:** player-authored pages can be named, restored and edited without
    copying collected pages or bypassing ordinary binding cost.
12. **2.12 House and opening village:** Base opens on the four-zone Binder House; Village owns Firepit,
    Essence Spring and the Trading Post → Recycler → Blacksmith growth sequence. Obscure stations use
    silhouettes plus signs, truthful updates glow until checked, and the town is never damaged.
13. **2.13 Creature ecology/material domains:** World resources and Creature materials are separate
    slot-free categories; generated aquatic/shore/terrestrial/aerial forms occupy legal habitat and yield
    body-derived parts rather than unrelated world resources, gear or curios.

**Exit gate:** a fresh campaign recruits the opening trio in order and completes the entire
sell/recycle/make/equip/bind loop without DEBUG grants.

## Band 3 — Early knowledge and the first combat choices

**Reach:** roughly worlds 5–15 / levels 4–10; Mara, Edren, Isolde, Sela, Bryn and Orsa.  
**Goal:** deepen the core loop only after the opening economy works.

1. **3.1 Mara / Survey Post:** field instruments, packing, observations and upgrades are reachable
   and useful against real worlds.
2. **3.2 Edren / Reliquary:** site discovery and recovered-site yield are truthful and do not reveal
   undiscovered minimap POIs.
3. **3.3 Isolde / Scriptorium:** migrate Pencil to **Brush** losslessly; Rough Charcoal → Brush is
   the first live tool upgrade.
4. **3.4 Ink Mixing:** Brush-gated CMY + Depth mixing is an adjacent choice; Ash remains open-color;
   pigment resources and preview/commit share one authority.
5. **3.5 Sela / Wayfarer's Table:** its real early field contribution is present, including settled
   flora recognition rather than a decorative room.
6. **3.6 Bryn and Orsa:** their live meetings, diaries, party identities and combat leans are the
   honest recruitment payoff. Orsa may visibly use the Firepit, but no miniature Tavern mechanic,
   generic clue bonus or relationship currency begins merely because she is recruitable; the later
   Tavern lands as one complete visitor/want/permission-safe-rumour/rest loop.
7. **3.7 Combat roots and first forks:** only the choices reachable with the first three earned
   combat points must be purchasable, functional and testable. Unsupported deeper nodes remain
   visibly unavailable rather than inert.
8. **3.8 Spring/Constellation:** refining practice and the truthful one-star Constellation can be
   tested after the opening continuation loop establishes real inputs.
9. **3.9 Library usability:** recovered writing, people, diaries and world history remain compact
   and accurate as the collection grows.
10. **3.10 Live prose expansion:** every coherent meeting/clue encountered in this band ships and is
    revised from play reports.
11. **3.11 Wild World Pages:** curated physical pages can be found without displacing guaranteed
    writing; unknown marks enter the Dictionary as `??`, and exact instances consume only on bind.
12. **3.12 Disclosed extraction progression:** equipped Field Pick rank—not Binder level—controls mineral
    access. Rank-0 Iron prevents Blacksmith deadlock; known Gold may appear before rank 2 and truthfully
    motivates the upgrade without blocking binding.

**Exit gate:** one ordinary campaign reaches Isolde, uses Brush and an early mixed ink, owns three
functional combat choices, and uses Mara/Edren/Sela contributions in real expeditions.

## Band 4 — Midgame survival and one complete build

**Reach:** roughly worlds 10–30 / levels 8–15; Talin, Nessa, Corrin, Dagg, Rook and Lys.  
**Goal:** support a coherent midgame build and sustainable preparation.

1. **4.1 Talin:** foe-armour Gambit knowledge and combat teaching are reachable and truthful.
2. **4.2 Nessa / Apothecary:** build, recipe inference, Lesser Salve, cures, Stonebark and four
   coatings work through the canonical affliction system.
3. **4.3 Scent Mask:** add the prepared animal-avoidance route only after the Apothecary is accepted.
4. **4.4 Corrin / Tannery:** flexible armour and its capacity choices become relevant before Armoury.
5. **4.5 Dagg and Rook:** their combat/keeper contributions and live meetings are available.
6. **4.6 Lys / Library depth:** search, cross-reference and study extend the already-correct Library.
7. **4.7 First complete combat route:** implement and phone-test one representative eight-point
   route only when Aimee has a save within two levels/points of reaching it.
8. **4.8 Midgame scaling:** test two-, three- and five-person parties across ordinary and Teeming
   contacts before declaring the level curve stable.
9. **4.9 Reforge correction:** replace paid ranks that do not change combat with the settled honest
   improvement before asking Aimee to test repeated reforging.

**Exit gate:** one level-appropriate party has a complete functional build, prepares remedies,
crafts/fits gear and survives representative midgame worlds without hidden difficulty fossils.

## Band 5 — Specialist equipment and alternative builds

**Reach:** approximately levels 12–20; Bracken, Fen, Wren, Kestrel and Maud.  
**Goal:** widen viable builds after one build and the underlying combat curve work.

1. **5.1 Bracken / Armoury:** higher-tier protection profiles and recipes.
2. **5.2 Fen / Bowyer:** bows plus nonmagical ranged alternatives.
3. **5.3 Wren/Kestrel:** skirmishing, hunting and Bestiary-facing contributions.
4. **5.4 Maud / Weaponsmith:** higher-tier melee and polearm work.
5. **5.5 Alternative combat routes:** complete the second and third representative eight-point
   routes, then hybrids actually reachable at this level.
6. **5.6 Specialist item identity:** only now require full visual distinction for these advanced
   gear families.
7. **5.7 Animal systems preflight:** prepare Menagerie/taming contracts only if the corresponding
   traveller and resources are now reachable; do not implement the late building early.

**Exit gate:** three materially different party builds and each specialist equipment shop are
playable with honest item identity and comparable encounter evidence.

## Band 6 — Late specialists and simulation depth

**Reach:** approximately level 18+; Marrick, Sabine, Grimmond, Oda and Auber.  
**Goal:** add expensive systems only when the campaign can actually reach their people and inputs.

1. **6.1 Marrick:** formation/shared-routine depth.
2. **6.2 Authored-world blueprints:** unique story World Pages may now pin fixed or constrained map
   facts because world generation, encounters, sites and persistence have already stabilized.
3. **6.3 Sabine / Menagerie:** taming and animal assignment; no separate redundant beast-handler.
4. **6.4 Grimmond / Deep Works:** persistent signs, finite pulls and brace decisions.
5. **6.5 Oda / Channelworks:** one-time restoration receipt first; then repeatable conduits and real
   combat attacks.
6. **6.6 Auber / Distillery:** core economy, retuning and only approved extensions.
7. **6.7 Late combat consumers:** Attunement follows a real Channelworks attack; remaining capstones
   and passives follow their actual producers rather than creating temporary mechanics.
8. **6.8 Living-world predation:** bounded creature-on-creature behavior only after ordinary world
   performance and encounter density are accepted.
9. **6.9 Compound assembly:** implement once Brush/Ink Mixing and its Scriptorium capability schema
   are already stable.

**Exit gate:** every late station has a reachable owner, sustainable inputs, a distinct first payoff
and a real downstream consumer; no empty or decorative late room counts as implementation.

## Band 7 — Anchoring, endgame and complete breadth

**Reach:** Ashe, Tovin, Perren and Nine; long campaign / endgame.  
**Goal:** finish permanent-world and endgame systems after the disposable-world campaign works.

1. **7.1 Ashe:** embodied emanation progression and late combat identity.
2. **7.2 Tovin / Anchorage:** settlement, dormancy/reactivation and placement acceptance.
3. **7.3 Anchored production:** renewable work receipts, deliveries and portfolio management.
4. **7.4 Perren/Nine:** final traveller content and chosen-continuity consequences.
5. **7.5 Remaining combat breadth:** every one of 72 nodes has a real consumer, migration and
   scenario proof; only now is “complete combat trees” an active whole-project gate.
6. **7.6 Great Work/endgame:** dedicated emotional and mechanical review with Aimee; no invented
   reset, score or ending trigger.
7. **7.7 Final art replacement:** replace functional placeholders with Aimee-approved immutable
   packs across every now-stable system.
8. **7.8 Tutorial completion — dead last:** finish remaining teaching only after the UI and mechanics
   it teaches have stopped changing.

**Exit gate:** a long campaign reaches permanent worlds and its authored ending boundary without a
missing station, inert progression purchase, placeholder gameplay promise or unreviewable result.

---

## Immediate order from this audit

1. Preserve the known installed phone build and separate the shared dirty packets. Do not merge or
   overwrite AssetLab, Design or held Campaign work merely to make the checkout look clean.
2. Reconcile the clean `2d2e7ce` UI branch screen by screen against the current visual ledger and
   `cross-lead-delivery-contract-current.md`. A package-level `integrationReady` flag cannot promote
   a rejected Campaign or Writing candidate.
3. Correct and freeze Campaign, Home departure, Writing projection, World presentation and Return
   Recap as bounded screens; integrate them onto one clean shared line.
4. Install that exact checkpoint. Aimee runs the Band-0 route once and then the three-expedition
   Band-1 card. Encounter scaling remains the sole acceptance primary during this pass.
5. Engineering fixes only failures in that chain. When Aimee is actively testing the installed
   checkpoint, the only permitted next preparation is a bounded Band-2 opening-economy or opening-
   traveller dependency that does not overlap the protected UI files.
6. Asset supports only the named current screen/identity consumer and may be idle. A visually
   appealing proof for a later system is not substitute work.
7. Promote completed traveller meetings in reachability order rather than waiting for Atlas
   preapproval: opening trio, then Band 3, then later bands as the campaign can encounter them.
8. Pause blanket combat-v2 work. Resume the first-three-point consumer set after Band 1 exits; deeper
   routes wait for saves that can reach them.
9. Do not expand Channelworks, Deep Works, Distillery, Menagerie, late stations, anchoring depth or
   late capstones until their bands become current.

Already-built late work is preserved and tested when reached. The correction is about where new
effort goes, not deleting completed work.

**Transition note:** deeper personal-turn combat edits already present in the shared dirty tree are
frozen in place. They are not an excuse to continue the late slice. Engineering may checkpoint them
only if the isolated existing work is already coherent and green; Band 1.7 diagnosis otherwise stays
in scaling integration tests and does not overlap those files.
