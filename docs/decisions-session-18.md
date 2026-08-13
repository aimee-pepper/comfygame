# Decisions Log — Session 18 (2026-08-08)

Append to `docs/decisions-log.md` when the next consolidation pass is made.

## 1. Design-lead authority and working method

- The design lead may **freely challenge** inherited designs, but may not freely revise them.
- Challenges are discussed with Aimee before the current design changes. The design and engineering
  leads may confer first, then bring a recommendation to Aimee for review.
- Historical decisions remain archived so the game's evolution and reasoning stay visible. Live
  working documents should describe the current design cleanly.
- Design work should batch related decisions and offer a recommendation for each.

## 2. Target play shape

- The target player is Aimee and people with similar tastes.
- A session may be about **15 minutes to an hour or more**, particularly before bed.
- The campaign should comfortably sustain **at least a month and likely longer**.

## 3. Debug tuning menu — approved direction

A debug/balancing menu is a high-priority development tool.

- Start with adjustments that affect the **next world/run**, rather than mutating live state.
- Organise controls into named design groups, with raw values subordinate to those groups.
- Persist tuning in a **separate debug profile**, never in the normal player save.
- Always show when non-default tuning is active and provide **Reset All**.
- First controls: diary-page frequency/pacing; raw-essence frequency and yield; unwritten-subject
  intensity spread; stability/turn bands; resource-node and creature density; combat damage and
  cooldown multipliers.

## 4. A world should contain writing

**Player-facing invariant:** the player should find some kind of page in essentially every world.
Five or more consecutive worlds without one is not acceptable pacing.

The current implementation does two things that conflict with this intent:

1. It chooses `0...2` diary pages per world, so zero is explicitly valid.
2. After an unfound authored page has waited eight generated worlds, it ignores that page's
   preferred conditions and may place it anywhere.

The second rule was anti-deadlock insurance, not a narrative decision. Aimee has chosen to **retain
the fallback provisionally**, but only for **one nominated diary page at a time**. Ordinary unfound
pages remain eligible when their conditions fit; only the front page of the patience queue counts
toward the eight-world fallback. Once it appears, the next nominated page begins waiting. This
prevents many pages becoming universally eligible in one influx.

Allowing an overdue diary page to appear in a mismatched world may still damage the story logic.
**Explicit playtest revisit:** keep it visible as provisional and reassess once the expanded page
catalog and expanded character roster can be tested in real play.

Every world guarantees **at least one writing**, chosen from diary pages and other writing types.
Which kind appears is allowed to vary. Exact weights and the chance of additional pages remain
tuning, not a locked design rule.

### Design-lead starting balance — pending playtest

- **One guaranteed writing per world.** A **10%** chance of a second gives an average of 1.1 without
  making pages feel like clutter.
- Fill the guaranteed slot from condition-fitting unfound diary pages when available, interleaved
  with non-diary writing rather than exhausting every diary first.
- Starting target: **roughly 70% diary / 30% other writing** while both pools have eligible entries.
  Reweight dynamically when a pool is exhausted; never produce an empty world merely to preserve a
  ratio.
- Most named travellers have **5–10 authored diary pages**, giving their diary room for an
  assortment of location clues, rune or other knowledge, sites of note, other travellers,
  worthwhile worlds and character fragments. Late travellers may have longer books when their
  signatures require more clues. Tune how quickly those pages surface from campaign play rather
  than shrinking the diaries solely to protect discovery pacing.
- Keep **one signature condition per location page**. This makes each page one discrete deduction.
  A traveller signature is capped at **10 conditions**; a ten-condition traveller has ten location
  pages plus their other diary material rather than compressing clues to fit an arbitrary book cap.

**Superseded proposal:** the design lead initially suggested 3–4 pages per traveller as a discovery-
pacing safeguard. Aimee rejected that as too few to support the intended assortment; the page pool
and placement rate should be balanced around full 5–10-page diaries instead.

## 5. Flora — settled review calls

1. **Flora and creature budgets remain separate.** They influence each other through producer
   productivity and the food web rather than spending one zero-sum trait budget.
2. **No per-tile flora jitter.** Variation lives in the world's flora cast and spatial patterns.
3. **Resin is a secondary harvest from woody, defended flora.** Timber or fibre remains its primary
   material; resin likelihood or quantity rises with defence/reactivity.
4. **Tall growth costs one additional world turn to cross.** Groundcover remains normal. The route
   planner must account for and communicate terrain cost, and travel should pause before entering
   costly growth when danger is nearby.
5. **Mud should also slow travel.** Marsh conditions should produce legible muddy ground where wet
   hydrology meets passable soil. Mud costs one additional world turn, parallel to tall growth.

## 6. World-screen minimap

The minimap belongs **under the movement/navigation controls**, as previously requested in session
13. `MinimapView` exists but is not embedded in `WorldView`; this is an implementation omission, not
an open design question.

## 7. Instruments — restore the fieldwork loop

The acquisition skeleton is built, but purchasing an instrument currently counts as having measured
its subject everywhere. That simplification is rejected; restore the session-8 fieldwork design.

- A newly made instrument can read its subject in the field but does not automatically calibrate
  the page lens.
- A single **Survey** action uses every instrument carried into the current world and costs **one
  world turn**.
- The first observation of a subject permanently calibrates it for the page lens. Later observations
  improve precision. Knowledge lives in Reality and is never taken back.
- Store compact knowledge per subject—observation count/range and best precision—rather than every
  raw interaction.
- Instrument grade has one clear job: **crude** gives a qualitative band and broad numerical range;
  **good** narrows the range; **fine** gives the exact value.
- Lens tier controls what kind of explanation the player can access; instrument grade controls how
  precise each subject reading is.
- Early analysis retains qualitative flora/life forecasting because it supports clue deduction.
  Detailed trait distributions, ecological roles and spawn likelihoods wait for lens tier 5.
- Writing Desk, current-world display and World History must use the same measurement/precision gate.
- Tier 3 must attribute primary and secondary effects to individual focuses. Tier 4 must break
  instability into greed and contradiction from actual contributors. Tier 5 must provide the
  distinct living analysis described above.

Full evidence and clause status: `instrument-system-audit.md`.

## 8. Apex encounters — completion decisions

- **Ranked Spear:** Throughstroke deals full damage to the selected foe and half damage to one
  additional foe. Do not add enemy ranks solely for this weapon.
- **Living Hook:** gains growth credit when an encounter is won while it is equipped; milestone
  growth is capped at **+2 tiers**.
- **Warded Haft:** provides modest continuous reduction against its authored damage type and stacks
  multiplicatively with the temporary Ward skill.
- Apex discovery receives an explicit bestiary badge/variant and a separate apex-sighting
  collection. Its underlying species remains derived from its traits.
- Apex locations remain marked from world entry; identity is still learned through encounter.
- Add environment/condition affinities later so hunting an apex becomes a world-writing goal while
  retaining the current risk/value appearance draw and never guaranteeing a spawn.
- Apexes may inhabit named places only where they do not block a required traveller, core clue or
  sole route. Optional treasure and side areas are valid.

When the locked-cache wild-weapon lottery fires at its **3% chance**, the weapon is a **bonus**
alongside the cache's normal progression reward. The rarity is low enough to keep the added value
safe, and a jackpot should not consume the delayed-payoff knowledge or motes the cache already
promises.

## 9. Traveller development process

Before auditing and expanding the roster, establish one reusable named-traveller template derived
from the six implemented travellers and refine it as the cast grows. `traveller-template.md` is the
current template. It separates the required playable loop—identity, contribution, writable
signature, diary packet, meeting and implementation handoff—from optional biography and cast
connections.

The template adds two requirements that were implicit or absent in the current traveller data:

- an explicit **campaign phase and authored progression order**, because traveller order also
  governs vocabulary reachability and pity targeting;
- a player-facing **reason to seek and recruit** each traveller, so nobody exists only to fill the
  roster.

Most named-traveller diaries contain **5–10 pages**, while complex late-game diaries may be longer.
One location page carries one signature condition, and no traveller requires more than **10
conditions**. The longer diary is an intentional part of a late traveller's hunt, not a problem to
solve by combining clues.

Do not finalize the six implemented travellers before applying the same template to the rest of the
proposed cast. Character approval happens against a **comprehensive whole-roster view** so roles,
order, teachings, diary distribution and relationships can be balanced together. The current pass
is recorded in `full-roster-structural-audit.md`.

The equipment-making progression has three tiers of ownership: Halloway’s **Blacksmith** establishes
ordinary equipment work; Bracken’s **Armoury** provides higher-tier armour upgrades and recipes; and
a paired **Weaponsmith** provides higher-tier weapon upgrades and recipes. Who owns the Weaponsmith
remains a cast decision.

**Roster-count correction:** roughly 28 travellers was an estimate, not a cap. The cast may grow
when an additional person adds worthwhile character, relationships or gameplay. Do not merge roles,
broaden an existing calling or reserve a single “final slot” merely to preserve the number. A new
Weaponsmith is therefore allowed, but still needs to be a person rather than a building label.

**Animal-role and Oda correction:** the Menagerist and Beast-handler are one role, owned by **Sabine**
through the Menagerie. **Oda** remains a separate traveller but no longer duplicates animal handling;
Oda will unlock a shop for **ranged magical weapons**. “Spellwright” and “ranged-magic workshop” are
working labels only. Exact weapons, resources, shop name, teaching and voice remain to design.

The developed identities in `traveller-identities-sabine-oda.md` are approved. **Sabine** replaces
the earlier working name **Ilse**, which was too similar to Isolde. Sabine’s identity centres animal
care as consent, routine and renewed trust. Oda is a **channelwright** whose identity centres
distance, containment and responsibility; she owns **The Channelworks**. Ranged magic weapons are
projected emanation implements using the existing Craft branches rather than a separate mana/spell
system. **Arc** remains provisional until it passes the vocabulary-purpose audit.

**Equipment specialisation correction:** Bowyer and Weaponsmith remain separate. **Fen’s Bowyer**
owns all higher-tier non-magical ranged weapons, not bows alone. A **new Weaponsmith traveller** owns
higher-tier non-magical melee weapons. **Oda’s Channelworks** expands from ranged-only to **all
magical weapon families**, at close, mid and far reach. Bracken’s Armoury continues to own advanced
armour. The earlier pressure to fold Fen into Weaponsmith is superseded.

**Equipment-specialist identities approved:** Bracken reads armour through the harm transferred
behind it; Fen understands anticipation, preparation and physical trajectory; **Maud** is the
Weaponsmith and fits melee weapons to real bodies and chosen proximity. Their advanced shops create
horizontal trade-offs rather than automatic replacements. **Bone** and **Silk** become exclusive
diary focuses taught by Bracken and Fen; their ordinary wild/merchant acquisition routes are
removed. Maud’s teaching remains deliberately open pending a vocabulary-purpose audit.

**Auber and the Distillery approved:** the Refinery retains simple raw essence conversion. Auber’s
Distillery **crystallises, attunes and infuses** essence using selected **world resources**; outputs
are items or modifications, not additional wallet currencies. Auber’s identity centres separation,
residue and refusing to equate purity with improvement. **Brine** replaces Amber as his exclusive
diary focus, and its ordinary research route is removed. Exact recipes, costs and property changes
remain a later system-design pass.

## 10. Value-and-knowledge identity batch — approved

`traveller-identities-value-and-knowledge.md` develops four recommendations for the next cast review:

- **Vance** distinguishes circulation, price and worth; Amber is recommended as his exclusive diary
  focus because preservation productively contradicts his belief in keeping objects useful through
  exchange.
- **Kestrel** is a hunter and field naturalist who distinguishes evidence from entitlement. Her
  recommended exclusive teaching is the `Foe: unrecorded species` gambit subject, intended to pair
  with the existing Read skill and permit automated bestiary discovery before a kill.
- **Lys** preserves contradictions and relationships between records rather than serving as a human
  Library menu. Echo is recommended as her exclusive diary focus.
- **Ashe** is defined as an Emanant whose body carries and expresses emanation without a crafted
  housing. Their recommended teaching is the `Foe: emanating` gambit subject; Ground is a working
  active-technique concept awaiting combat design.

All four identity directions and teachings are approved. **Amber** and **Echo** are now exclusive
diary focuses for Vance and Lys; their former ordinary acquisition routes are superseded. Ashe's name
is retained: their own emanation is specifically **thermal**, while their embodied sensitivity can
recognise other forms. Ground remains a working technique that requires a later combat balance pass.

## 11. Martial-discipline identity batch — approved with one mechanical hold

`traveller-identities-martial-discipline.md` develops Talin, Dagg, Rook and Marrick beyond their
combat labels. The common structure is time and commitment in combat: Talin owns the opening, Dagg
the recovery, Rook the approach and Marrick the long duration. All four identities and their diary
targets are approved. Talin and Marrick retain their proposed gambits. Rook's teaching is simplified
from a numerical reach comparison to the legible state **Foe: cannot reach me**. Dagg's recovery
teaching is held until his active skills establish which condition is genuinely useful; the design
must not add action-history complexity merely to illustrate his character concept.

## 12. Bryn and Wren identity batch — approved

`traveller-identities-bryn-wren.md` completes the dedicated-fighter identity pass. Bryn's identity is
personal protection without ownership, debt or permanent authority over the protected person. Wren's
identity treats Quicken's existing burst-and-skip rule as tempo debt and distinguishes tactical
movement from Sela's exploratory curiosity. Both retain their existing gambit components, add no new
player-facing systems, and use approved diary targets of seven pages for Bryn and nine for Wren.

## 13. Strange-traveller premise audit — approved

`strange-travellers-premise-audit.md` establishes that strange travellers may justify recruitment
through late strategic vocabulary, narrative access and ordinary shared-tree growth rather than each
opening a private subsystem. Perren and Nine have approved present identities, with diary-exclusive
Mirror and Dream respectively. Tam is formally held—not removed—until anchoring, the Great Work,
Reality reset and Glass/quartz are settled. Perren's and Nine's acquisition routes change to diary
exclusives; Tam has no reserved focus or altered acquisition route while held.

## 14. Living-and-deep-material identity batch — approved

`traveller-identities-living-and-deep-materials.md` establishes Corrin, Nessa and Grimmond while keeping
their shop boundaries narrow. Corrin owns flexible goods and foundational light armour, not Bracken's
advanced armour progression. Nessa uses the existing consumable plan without adding toxicity or
tolerance systems. Grimmond improves deep access and extraction without independently approving a
new underground-navigation mode. Chitin, Thorn and Mercury are diary-exclusive focuses and their
former ordinary acquisition routes are superseded. Nessa moves to early–mid so preparation matters
for more of the campaign.

## 15. Orsa and the Tavern — approved current direction

`traveller-identity-orsa-tavern.md` defines Orsa as a keeper of temporary shelter and negotiated
company, not a maternal caretaker. The Tavern upgrades the existing Firepit and organizes visitors,
clues, wants and rest without adding a relationship currency or hospitality minigame. **Hive** is
Orsa's diary-exclusive focus, and its former ordinary route is superseded. Her diary target is seven
pages across three signature conditions.

## 16. Apothecary coating/status alignment — engineering unblocker

The Apothecary's four coatings use the combat outcomes that already have producers: **Venom →
poison**, **Firebrand → burn**, placeholder **Briar Oil → bleed**, and placeholder **Flashsalt →
dazzle**. Rimeoil/freeze and Stormsalt/shock are superseded; old item names do not justify expanding
the deliberately narrow status taxonomy. Coating names and exact ingredient pairs remain placeholder
review items in `design-review-queue.md`.

**Stonebark** targets one selected party member, prevents exactly the next attempted affliction
including legacy bleed, and expires when it prevents that affliction. It does not prevent the
triggering attack's damage. An untriggered guard expires with the current encounter and never carries
between combats.

The same taxonomy correction propagates to adjacent live designs: Quenching Draught clears burn and
dazzle; the working `kindling` branch uses heat, caustic and light emanation producing burn, poison
and dazzle; and placeholder **Barbed Edge** replaces Rimed Edge, applying legacy bleed without a
coating rather than reintroducing freeze. Final branch/weapon display names remain reviewable.

**11 Aug amendment:** Venom, Firebrand, Briar Oil and Flashsalt are now the settled first-slice
coating names. Their exact zero-Essence recipes are recorded in
`apothecary-coating-identity-current.md`. Briar Oil uses Fiber + Resin rather than duplicating
Venom's Toxin, and native `fibre` is an invalid resource ID that must be corrected to catalogue
`fiber`; no duplicate spelling or resource is introduced.

## 17. Implemented-six reconciliation — current design

`traveller-identities-existing-six-current.md` completes the held audit of Mara, Edren, Halloway,
Isolde, Sela and Tovin against the comprehensive cast. All six identities and meetings remain.
Authored order is Mara → Edren → Halloway → Isolde → Sela → Tovin. Seven misleading signature
passages receive honest replacements without changing thresholds, and Sela remains a wanderer whose
fieldcraft follows from travel. Ruin, Gold ore, Pond and Drift become diary-exclusive to Edren,
Halloway, Sela and Tovin. Mara uses the existing surveyor-owned Scarp instead of adding Bluff; Hush
replaces atmospheric Stillness so Stillness belongs only to Cycle. Tovin's expansion remains held
behind anchoring and vocabulary reachability.

Sela's station is **The Wayfarer's Table**, a shared workspace for routes, provisions, field notes,
organic-yield knowledge and flora recognition. It does not make her a shopkeeper or imply she remains
behind a counter. The older Forager's Shed name is superseded.

## 18. Whole-roster coherence audit

`roster-coherence-audit-current.md` is the current control document for composition, teaching
ownership, diary distribution, relationship coverage and progression risks. Eighteen world focuses
have one approved diary owner, seven fighters have approved gambit teachings, and Maud, Oda, Dagg and
Tam remain deliberately unresolved for documented reasons. **Coral** is now diary-exclusive to
Sabine. Every active developed traveller has at least two relationship anchors; Tam's single edge is
intentional while held. The audit identifies only six material decision areas that should interrupt
routine content production.

## 19. Channelworks and Arc resolution

`channelworks-system-current.md` defines Contact, Conduit and Projection housings using heat, caustic
or light attunement. They deal lower raw emanation damage that bypasses ordinary armour, is reduced by
Ward/insulation, applies an existing weak affliction and cannot accept coatings. They add no mana,
ammunition, freeze/shock or fourth physical damage corner. Auber prepares attuned items; Oda houses
them. **Arc is retired** because it lacks a necessary world-writing purpose and implies unsupported
electricity. Oda instead teaches an exclusive housing schematic/research lead.

## 20. Maud's teaching resolution

Maud teaches an exclusive **fitting pattern**, the first advanced melee recipe explicitly fitted for
balance and recovery in a real wielder's hands. It is a Weaponsmith recipe/research lead, not a new
equipment slot or character-bound fitting subsystem. She receives no world focus: Obsidian already
has a route, Adamant is overloaded, Glass belongs to an unresolved question, and Edge lacks a distinct
world-writing purpose.

## 21. Anchoring implementation model

`anchoring-system-current.md` carries forward the settled three routes: premium anchoring at bind,
a cheaper natural anchor point found in-world, or an expensive carried crafted Anchor Frame. All
three produce the same permanent, revisitable realm; the older tether intermediary is removed.
Sustain is a calculated expedition-return obligation rather than a new currency or wall-clock timer.
Failure creates recoverable dormancy, never realm deletion. Permanent companion and animal loss is
removed from anchored-world assignments; danger may instead cause visible temporary setbacks or a
safe return to base. The first realm being sustain-free, relative route costs and natural-site rate
are explicitly reversible playtest placeholders. Reality reset, the final Atlas threshold and Tam's
act remain separate questions and do not block Tovin's first Anchorage implementation.

## 22. Implemented-six focus profiles and Tovin expansion

`diary-focus-mechanical-profiles-current.md` defines implementation-safe profiles for Scarp, Ruin,
Gold ore, Hush and Pond, while preserving the existing Drift profile. `Strange` is not a live pressure
target: Ruin attaches to Relief, adds worked/broken terrain and a semantic site-weighting hook, but
does not guarantee a ruin site. Numeric magnitudes remain playtest values; each focus's direction and
distinct use are current.

Tovin now has an eight-condition signature: darkness, fungal life, rich substrate, enclosure, briny
water, deep cold, still air and exact time. It is reachable with pre-Tovin vocabulary and never
requires Drift, his own diary reward. Its thresholds remain subject to accidental-match simulation.

## 23. Whole-roster progression control

`roster-progression-current.md` turns the comparison worksheet into an implementation-facing order.
The first six order values remain settled; later rows are reversible placement placeholders governed
by current system dependencies. Nessa moves immediately before Corrin, fighters interrupt the
advanced-equipment block, Grimmond precedes the deepest transformation shops, and Tovin remains late
but before the interpretive/endgame travellers. The document also makes reachability, hand capacity,
non-self-keyed signatures, singular teaching ownership and phase-sensitive accidental-match testing
mandatory validation rules.

## 24. Dagg recovery teaching

Dagg teaches the exclusive gambit subject **Self: recovery complete**. A condition that tried to act
while recovering would be inert because Overbear's recovery is a skipped turn. The new subject instead
matches on the first actionable turn after all skipped-turn debt is paid and clears after one action.
It grants no buff or extra turn and adds no stamina/recovery subsystem. Exact wording and the value of
pairing it with the broad `Skill` action remain playtest questions.

## 25. Ashe's Ground technique

Ground is a consent-driven protective active: for two working rounds it intercepts the next
emanation-damage event aimed at another party member, redirects it to Ashe, halves its damage and
attempts its burn, poison or dazzle against Ashe through ordinary guard rules. It catches one event,
has a working four-round cooldown and does not affect physical harm. It is Ashe's starting technique,
not a second diary teaching, and adds no mana/charge meter. Exact duration, reduction and cooldown
move to playtest.

## 26. Emanation branch display name — ID policy superseded by Decision151

The Craft branch with implementation ID `kindling` is player-facing **Emanation**. Kindling falsely
centred fire after the status/system correction; Emanation accurately includes heat, caustic and
light, as well as both projecting and resisting them. The stable ID does not change, preserving saves
and engineering references. **Decision151 supersedes only that final ID policy:** graph v2 uses new
semantic discipline ID `emanation` and maps legacy `kindling` one-way during migration. The
player-facing name and save-preservation intent remain current.

## 27. Early–mid signature batch

`traveller-signatures-early-mid-current.md` defines three-condition worlds for Bryn, Orsa, Vance and
Talin. Each is writable from earlier vocabulary, avoids its owner's teaching and carries only sensory
claims guaranteed by its pressure conditions. Bryn and Talin intentionally oppose enclosed protection
and exposed commitment; Orsa uses earlier Hush; Vance joins open routes to concentrated material and
life pockets. Thresholds, particularly Vance's Vitality dispersion, remain simulation/playtest values.

## 28. Natural/crafted anchoring and settlement interaction

The natural anchor site is the **Atlas Seam**, an old-binding remnant with a working 25% appearance
rate and cost of the greater of 10 essence or one quarter of the born-anchor premium. It may foreshadow
anchoring before Tovin but becomes usable only once the Anchorage is built. The carried **Anchor
Frame** is crafted at the Anchorage, consumes one slot, anchors from a valid safe tile and charges no
second essence payment; its property recipe waits on the Adamant-demand audit.

Sustain shortfalls are paid in essence through a return-to-base settlement summary. The player chooses
which realms to cover; the game never silently spends essence or selects a realm for dormancy. Unpaid
realms become dormant only on confirmation, and reactivation remains a separate previewed action.

## 29. Midgame four-condition signatures

`traveller-signatures-mid-current.md` defines Nessa, Corrin, Dagg, Rook and Lys through four writable
pressure conditions each. Nessa combines toxicity with viable life and usable carriers; Corrin uses
producer-backed vitality, motion and distributed water; Dagg uses hard footing and high-amplitude
cycles; Rook uses flat open ground, standing water and still air; Lys uses Ruin-marked terrain,
regular time, persistent low light and Hush. None requires its owner's teaching or promises a
discrete site, creature or item. Thresholds remain simulation/playtest values.

## 30. Five-condition signature band

`traveller-signatures-five-condition-current.md` defines Bracken, Fen, Wren, Kestrel and Maud. Bracken
tests protection across material and thermal strain; Fen studies repeatable tension across distance;
Wren preserves exits inside pervasive change; Kestrel reads a producer-supported food web through
incomplete traces; Maud fits mixed hard/ductile material to changing stance. All profiles use
pre-owner vocabulary, avoid self-keying and keep thresholds available for simulation tuning.

## 31. Adamant demand and Anchor Frame recipe

Adamant remains in permanent late analysis progression but is not the generic cost of anchoring.
Anchor Frames consume six distinct property-matched world resources—two hardness 65, two density 65,
one flexibility 55 and one reactivity 65—plus 60 essence, using weakest-qualifying-first matching.
This resolves the Frame recipe without making every anchored realm compete with Cycle/living analysis.
Replacing Waystone's repeatable Adamant with Rift-glass is logged separately for review rather than
silently changing an implemented consumable during anchoring work.

## 32. Marrick's six-condition signature

Marrick's world provides hard footing, bounded-but-usable space, shared atmospheric pressure, a small
thermal range, regular time and distributed usable water. These conditions support repeatable group
routines under sustained strain without inventing a battlefield, formation site or guaranteed group.
His ten-page diary allocates six location pages and retains the approved relationship, exclusion and
teaching material. Thresholds remain playtest values.

## 33. Seven/eight-condition signature band

`traveller-signatures-seven-eight-current.md` defines Sabine through a producer-supported, spatially
gathered ecology with repeatable routines; Grimmond through dark, concentrated value inside enclosed
load-bearing terrain; and Oda through mixed hard/volatile material, bounded space and repeatable
thermal/light/toxic containment tests. No profile requires Coral, Mercury, Oda's housing schematic or
retired Arc/electrical vocabulary. Thresholds remain late-campaign playtest values.

## 34. Auber and Ashe eight-condition signatures

Auber's location combines concentrated standing saline water, responsive substrate seams, retained
vapour and strong thermal/cycle separation without requiring his Brine reward. Ashe's combines
geothermal heat, sourceless light, volatile ground, toxic moving air, producer life and high-amplitude
cycles without adding Arc, electricity, freeze or shock. Both retain eight location pages and use
pre-owner vocabulary; thresholds remain refined-hand playtest values.

## 35. Perren and Nine nine-condition signatures

Perren requires three genuinely opposed pressures inside Ruin-marked, tightly framed and repeatedly
interpretable conditions; this uses the existing contradiction model without false clues or a cult
exception. Nine requires irregular high-amplitude Cycle alongside several locally verifiable
constants, using earlier Drift but never her own Dream reward. Perren's instability/survivability and
both accidental-match rates remain endgame fixture tests.

## 36. Worldwork aptitude

Anchored-world production is not level-only. Companions receive one visible authored **Worldwork**
rating from 0–3, with working contribution `1 + Worldwork + floor((level-1)/5)`. The implemented six
are Mara 2, Edren 2, Halloway 2, Isolde 1, Sela 3 and Tovin 3; generated companions default to 1.
This preserves calling and growth without adding Mining/Farming/Defence worker-stat machinery before
distinct realm jobs exist.

## 37. Implemented-six complete diary packets

`implemented-six-diary-packets-current.md` fixes complete packet totals at Mara 6, Edren 7, Halloway
6, Isolde 7, Sela 7 and Tovin 14. New ready-now pages supply worthwhile worlds, sites, research leads
and existing-target relationships; Lys, Dagg and Orsa pages are authored but deferred until those
traveller IDs exist. Every page carries exactly one unlock, catalog validation remains strict, and
Tovin's longer book earns its length through held/lost worlds and the Atlas Seam rather than fourteen
location conditions.

## 38. Bryn, Orsa, Vance and Talin diary packets

`diary-packets-early-mid-current.md` authors four complete seven-page diaries with three location pages
and four singular teaching/relationship/site/world unlocks each. Fighter pages introduce a dedicated
optional gambit-component teaching field rather than masquerading as research or symbols. The batch
covers Bryn's consent-aware intervention, Orsa's temporary shelter, Vance's circulation/provenance and
Talin's time-bound judgement while preserving non-gating location recovery.

## 39. Midgame diary packet batch

`diary-packets-midgame-current.md` authors Nessa, Corrin, Dagg and Rook at eight pages and Lys at nine.

Each book has four location pages, its singular focus/gambit reward, and relationship/world/site pages
that carry the approved human arc. Forward references to Auber, Bracken, Kestrel and Perren remain
authored but deferred until their IDs validate; they are not replaced with filler or allowed to weaken
catalog checks.

## 40. Five-condition diary packet batch

`diary-packets-five-condition-current.md` authors Bracken and Fen at eight pages and Wren, Kestrel
and Maud at nine. Every book has five one-condition location pages. Bone and Silk remain exclusive
focus teachings; Wren and Kestrel teach one semantic gambit component each; Maud teaches one fitting
pattern without creating fitted equipment state. Relationship pages are non-gating and later targets
remain deferred until their IDs validate.

## 41. Marrick diary packet

Marrick's ten-page book contains six one-condition location pages, one singular
`subject_ally_hp_below_any` gambit teaching, two non-gating relationships and one account of a
formation whose successful count excluded unassigned people. The any-ally component tests whether a
living ally crosses the player-configured HP threshold; it does not silently choose the lowest-HP ally.

## 42. Sabine, Grimmond and Oda diary packets

The late specialist packet fixes Sabine at ten pages, Grimmond at eleven and Oda at twelve. Their
condition counts remain seven, seven and eight respectively; extra pages carry relationship and
ethical complication rather than more locks. Coral and Mercury remain focus teachings. Oda instead
teaches only the settled `emanation_housing` schematic, without restoring Arc or granting a weapon.

## 43. Tovin authored-order collision resolved

The older six-character order described relative order inside that set, not six consecutive global
slots. `roster-progression-current.md` controls whole-cast order: Mara–Sela remain 1–5, expanded
travellers occupy 6–25, and Tovin is **26 / `late`**. The existing-six current doc now says this
explicitly so order 6 cannot collide with Bryn.

## 44. Auber and Ashe diary packets

Auber and Ashe each receive twelve-page books: eight one-condition location pages, one exclusive
teaching and three human/site pages. Auber teaches only Brine. Ashe teaches
`subject_foe_emanating`, which requires a live emanation producer/state rather than visual identity;
Ground remains their starting technique. Ashe's `spent_emanation_housing` site lead now uses the
reversible current profile and remains catalog-gated until that exact ID lands.

## 45. Perren and Nine diary packets

Perren's twelve-page book is explicitly order-independent: nine condition pages, Mirror, one Lys
relationship and one unconditioned turn page. No page labels a conversion/departure chronology, and
Mirror never acts as a truth detector. Nine's thirteen-page book uses nine condition pages, Dream and
three present-tense relationships. Dream does not recover a canonical biography or introduce a memory
minigame; her arc concerns chosen continuity and return rather than restoration of a “true” self.

## 46. Whole-corpus diary audit

The designed corpus now covers 28 travellers and 251 target pages. Expansion tables contain 204
unique page IDs; including implemented-six additions, all 218 newly authored IDs are unique. Every
signature condition has one location page, every book has one singular teaching, and relationship
pages remain non-gating and strict-reference validated. Tam remains excluded until the settled
endgame prerequisites permit an honest packet.

## 47. Later diary focus profiles

The twelve later focus rewards now have implementation-facing profiles using only the eight live
pressure targets. No Strange target or private subsystem is added. Hive, Amber, Chitin, Thorn, Bone,
Silk, Coral, Mercury, Brine, Echo, Mirror and Dream each receive distinct primary/aspect/tag behavior;
their magnitudes remain playtest tuning while signs and conceptual contrasts are current.

## 48. Singular diary teaching registry

All 28 designed travellers now have exactly one exclusive diary teaching: eighteen focuses, eight
semantic gambit subjects, Maud's fitting pattern and Oda's housing schematic. Pages may populate only
one teaching/reveal field, acquisition is permanent and idempotent, moved focuses lose ordinary
acquisition routes without revoking old saves, and Tam receives no placeholder reward.

## 49. Great Work design boundary consolidated

The Atlas premise, realm-as-restoration-unit and finality rule are implementation-safe. Realm history
data may be preserved now, but no ending score, realm quota, Reality reset, cult motive or Tam act may
be inferred. `great-work-boundary-current.md` consolidates the explicit hold and the related questions
for Aimee without proposing outcomes.

## 50. Glass/quartz audit and Ashe site placeholder

Quartz, Rift-glass and the proposed Glass focus are distinct concepts. Generic inventory Glass is not
recommended because current lens/vessel needs already use Quartz and rare reality craft uses
Rift-glass. Replacing Waystone's repeatable Adamant with Rift-glass remains a recommendation for
Aimee, not a settled recipe. Ashe's `spent_emanation_housing` now has a reversible thermal old-ruin
profile with modest ordinary yields and no schematic/item grant.

## 51. Traveller's Token challenged

The held token is incompatible with deterministic signature placement: a valid match already places
the traveller, while overriding a non-match would make the diary false. The design lead recommends
cutting the item rather than preserving an eighteen-item count. This is recorded for Aimee's review,
not silently removed; Engineering continues to hold it while the other seventeen items remain usable.

## 52. Apex hunting affinities authored

All eight wild weapons now have additive pressure-condition affinities. They bias the weapon awarded
by an apex or lottery but never guarantee the encounter or result. Barbed Edge is separated from cold
fiction; overlapping weapon families receive distinct second conditions. The existing risk/value
apex appearance model remains unchanged.

## 53. Animal combat placeholder

Animal companions do not use human trees or introduce an animal-only tree. Their generated traits
determine a fixed small action kit; normal levels scale them, normal gambits automate only valid
animal actions, and they occupy one of the five party slots. No animal gear, breeding, respec, bond
meter or free sixth combatant is added in v1. This remains reversible until taming and mixed-party
playtests exist.

## 54. Combat progression questions reconciled

The implemented eight-node branches, one point per level, level cap 25 and paid full Spring respec
become playtest-current rather than open structure. Twenty-four level-earned points complete three
branches. Authored calling leans are a small bonus above that budget, so older “exactly three and six
untouched” prose is corrected: a finished person may also hold a shallow fourth investment without
approaching full-tree convergence.

## 55. Building staffing formula corrected

A keeper's earned station tier and the purchased tier are two routes to the same content, so effective
tier is their maximum rather than their sum and never exceeds `maxTier`. Keeper milestones default to
levels 8/16/24 where applicable. Home discounts use per-station base/slope/cap tuning, while party and
anchored-realm assignments provide their own benefits. UI uses “assigned,” not “posted.”

## 56. Exchange and Recycler boundaries

Gold remains the Exchange's separate currency. Vance owns the station through identity rather than a
retired fixed Trader class. Stock refreshes on expedition resolution and sells only ordinary staples;
gold-to-essence is capped rotating stock. The Exchange buys ordinary gear so selling can compete with
recycling, with previews and protections on bulk actions. Crafted gear may later retain its actual
consumed-material provenance. Found catalog gear currently has none, so it uses explicit authored
salvage profiles or remains sell-only rather than fabricating “original materials.” Gold ore sells at
a premium but receives no exceptional direct-mint action.

## 57. Compound assembly and station-tree ownership

Player-authored compounds preserve the exact semantics of 2–5 known atomic sigils while compressing
their footprint; they cannot nest compounds or hide unknown vocabulary. Compound Assembly is a
reliable Scriptorium tier-1 Penmanship capability available after the pencil. A composition becomes
formalizable after one successful binding rather than repeated-world grinding, then lives in the
runebook with a player nickname and inspectable expansion. The existing station-owned research
architecture is current and should be extended: specialist practice lives at its station, while
self-taught general infrastructure remains at the Workshop. Nodes should unlock meaningful decisions
or content families rather than minor percentage bonuses.

## 58. Tavern, roster capacity and random companions

The five-person limit applies only to the active combat party, including the Binder; it must not cap
the persistent roster. All named travellers remain recruitable, and Home/realm assignments require a
larger community. Random companions are persistent generated individuals with ordinary shared-tree
characters, Worldwork and one validated reachable want, but no diary, signature, exclusive teaching
or station. Their appearance is favoured by sites, greed and produced life without requiring any one
of them. Orsa upgrades the existing Firepit into the Tavern, whose placeholder three visitor seats
rotate only on expedition resolution; rotation never erases an unmet person or adds a social meter.

## 59. Curio identification becomes permanent knowledge

Identifying one curio resolves that physical item; resolving two examples of the same family
permanently records its identity in Reality, after which all existing and future duplicates reveal
for free. Storehouse study, Solvent and valid-context use all feed the same observation record.
Use-to-identify applies the hidden item's real effect and consumes it normally; it is offered only
where the result has a valid attributable target. A compatible unknown key can be tried directly at
a locked cache. Contextless attempts consume nothing and teach nothing. Recognition atomically
normalizes matching owned stacks and can never be lost.

## 60. Rune pity and missing-word legibility

Rune pity targets only the first unowned authored `pityFocuses` entry for the next known unrecruited
traveller in global order. It does not infer a canonical word from numerical thresholds or warm the
whole unowned pool. The placeholder escalation is 10/25/40/55/70%, then a guaranteed trace on the
sixth resolved expedition; return and collapse count, empty abandoned runs do not. The Library may
mark a recovered passage as not deliberately writable with current vocabulary and hand, using the
copy “You do not yet have the words to ask for this reliably. Chance may still write it.” It never
names the missing word or translates the prose into conditions, preserving accidental solutions and
the player's interpretive work.

## 61. Palette directions and honest vocabulary names

The palette stays subject-first and adds collapsible Light/Shadow, Warming/Cooling and
Growing/Consuming subgroups through explicit per-subject display metadata. Multi-subject focuses may
belong to different groups in different bins; grouping never changes mechanics. The obsolete data
taxonomy migrates from pressure sources to focuses and from symbols to compounds. Existing
`symbols.json` gameplay is retained as authored compound shorthand—the false category is retired,
not the content. Stable raw IDs and world output remain identical through tolerant save/catalogue
migration.

## 62. Predation without ecosystem simulation

Creature-on-creature behavior occurs only inside the party's current active awareness, never in
previously revealed fog or off-screen anchored time. Trait comparisons identify prey; local fleeing
and one-tile pursuit create a visible intervention window, then adjacent predation resolves
immediately rather than running hidden combat. Kills leave a one-turn harvest carcass with half
ordinary material quantity and no decay timer, scavenger chain or hunter buff. Apexes remain
deliberate and outside predation. Optional herd/solitary local preferences may be deferred if they
add phone-turn latency.

## 63. Count reaches world prose

Count already affects pressures and dispersion; descriptions must now preserve the authored cause.
Absent Count/Single, Pair and Few mean one, two and three exactly. Many and Countless retain their
qualitative player-facing words while internal four/five remain representative diminishing-return
rungs. Focuses author discrete, occurrence or mass count grammar so “three suns” remains natural and
Ash is not awkwardly pluralized. Preview, generated entry prose and World History receive semantic
sigils rather than trying to reconstruct count from clamped pressure readings.

## 64. Void becomes a categorical cap

An active un-negated Illumination Void removes whole celestial-light causes—currently Sun, Moon,
Stars, Aurora, Eclipse and Ring—including their heat and other secondaries. Crystal, luminous Fungus
and Magma may still light the ground, preserving a lit world with no celestial sky. Suppressed demand
still contributes greed and opposed magnitude but no final tags/forms/aspects. Void's intensity still
scales its ordinary cold/dark contribution while the no-celestial rule remains binary. The pre-bind
projection names every suppressed focus explicitly.

## 65. Gear recipes recut around tactical families

Physical crafting uses twenty-one property-driven recipe families: eight foundational Blacksmith,
three foundational Tannery, three Armoury profiles, three far-reach Bowyer families and four
advanced Weaponsmith families.
Recipe count measures distinct slot/damage/reach/defensive choices rather than mirroring every found
item name. Construction tier and reforging separate: Halloway improves any piece within its tier,
while Bracken, Fen and Maud exclusively build/rebuild tiers 3–4 in their domains. Crafted instances
store resolved combat identity, material provenance and quality. Placeholder craft grade weights the
weakest input 60% and the average 40%; station caps warn before wasting exceptional stock.

## 66. Anchored realms produce only what the player has learned there

Posted companions spend their existing Worldwork contribution on sustain first, then apply surplus
to one player-selected renewable yield actually discovered in that realm. Production resolves once
per completed expedition, never by wall clock. A saved renewable manifest excludes unique rewards,
Gold, essence, carcass-only parts and apex trophies; assignment cannot invent resources or silently
hunt. Placeholder cadence is one unit per four surplus points, banked into a six-unit realm delivery
tray that pauses safely when full. Field replenishment and assignment draw from the same source state
so a renewal cannot be collected twice. Worker specialities, needs and mission-board simulation stay
out until this smallest loop has been played.

## 67. Tutorial teaches the loop without solving the writing

Tutorial cards teach verbs, consequences and record locations, one non-blocking card per screen.
They complete from durable game facts, survive interruption and remain replayable as Field Notes.
The first binding may be blank or authored; no scripted neutral world or prescribed Mara solution is
allowed. The first world teaches movement, interaction, stability and return, while results route the
player toward the one relevant Base record. An optional second binding asks the player to change one
request and compare histories. Later lessons appear only when their systems first matter. Diary prose
is never translated into a condition checklist, and undiscovered vocabulary remains concealed.

## 68. Generated people arrive practised; animals remain trait-built

The obsolete “wild companion” label is split. Generated people lock to the Binder's level when first
met and persist a visible coherent plan containing one branch per human tree, an ordered 24-node path
and one calling-lean bonus point. Their earned points through that level arrive spent; future choices
remain manual, with an optional one-tap continuation of their practice. They receive the same full
paid Essence Spring respec as named people. Tamed animals never use this path or human trees; their
generated traits remain their fixed combat build.

## 69. Animal companionship is consent through one reachable want

Sabine's Menagerie unlocks an account-wide one-turn Attend action. It reveals one deterministic,
saved trust condition for an eligible non-apex animal; satisfying the visible condition makes
acceptance certain rather than rolling capture odds. The first slice uses two-turn patient presence
as a universal fallback and a single property-matched offering only when a qualifying ordinary
resource is already demonstrably reachable. Taming preserves the individual specimen and survives
expedition failure, but does not auto-add a combatant. The Menagerie has no initial hard cap and no
breeding, gifts meter, hunger, obedience, animal equipment or permanent loss.

## 70. Corrin owns flexible foundations without an intermediate-goods chain

The twenty-one-family physical catalogue is redistributed, not expanded: Halloway keeps eight rigid
foundations while Corrin's Tannery owns Supple coat, Working gloves and Working boots. Corrin also
gates advanced—but never basic—satchel and Storehouse capacity through the existing capacity stats.
Prepared bindings are a station capability that consumes the selected provenance-bearing sample in
the final recipe, not a new strap inventory chain. Bracken retains exclusive tier-3/4 defensive
profiles, and all already-purchased capacity survives migration.

## 71. The first Distillery crystallises and attunes; it does not generically upgrade

Auber spends ordinary essence and Quartz to make stackable blank essence crystals, then combines one
with a named bulk catalyst and a selected provenance-bearing world resource to create Heat, Caustic
or Light cores. Core potency uses a reversible 70%-sample-grade/30%-relevant-property formula and is
capped visibly by Oda's housing. Crystals are items rather than wallet currencies, and Oda consumes
them into recorded weapon properties. The approved Infuse direction remains held until one named
crafted profile has a designed compensating trade-off; no universal late-game +1 action is invented.

## 72. Deep Works adds saved geological decisions, not another map

Eligible worlds save at most one inert deep sign at bind, readable before Grimmond only as unresolved
physical evidence. His Deep Works unlocks deterministic sounding and finite extraction on the
ordinary map. The first Buried seam profile has reversible 20% eligible-world frequency and 3–5 safe
pulls; outputs must already belong to the world's resource profile. One later brace may exchange hard
and flexible world resources plus essence for one additional pull while always leaving structural
support. Deep sites never replenish, enter passive realm production, roll hidden cave-ins or contain
generic pages/ruin rewards.

## 73. The Library precedes Lys; she turns shelves into an archive

The Library remains unlocked from new game because recovered writing is the route to every earlier
traveller, including Lys herself. Tier 0 supports full page reading, basic diary grouping, honest
missing counts and teaching acquisition. Recruiting Lys attaches her as keeper rather than building
or resetting the station; she adds authored search, explicit-ID cross-references, comparison and the
non-spoiling writability marker. Her Home/Party staffing follows ordinary tier rules, but no posting
can hide basic pages or already learned knowledge. The Library never converts prose into condition
checklists or inferred solutions.

## 74. Every station has an explicit lifecycle and immediate use

Opening infrastructure stays available without a keeper; ordinary trade stations appear as durable
build sites after recruitment; Lys deepens the existing Library and Orsa upgrades the existing
Firepit. A current matrix assigns every keeper, tier cap, first capability and reversible build
bundle. Tier 0 must perform one honest action immediately. Because Oda precedes Auber, she carries one
damaged Heat Conduit with an intact non-recoverable core; constructing the Channelworks restores that
authored fixture, while repeatable cores still belong exclusively to the later Distillery. No
real-time construction or party-posting dependency is added.

## 75. Sites carry authored place without carrying the whole writing guarantee

Site value is counted through ordinary world contents/greed; retired authored `stabilityDelta`
fields never apply a second charge, and contradiction Tears remain consequences rather than extra
causes. Anchored sites preserve identity, depletion and history. Every world still contains writing,
but page selection precedes host selection and has a non-site fallback, so generation never invents
a ruin merely to place a page. Six new threshold-driven profiles expand natural, living, recent-ruin,
old-ruin and hazard breadth. Known-site previews may show likelihood bands from authored conditions,
never reveal a rolled site under fog.

## 76. Vocabulary expansion stops at a purposeful 85

The live 62-focus catalogue gains exactly twenty-three current additions across Illumination,
Thermal, Hydrology, Substrate, Relief, Vitality and Atmosphere. The cut prioritizes missing ordinary
requests and live downstream material/site needs; redundant Comet/Cinder/Chalk/Lead/Gale/Thunder/
Moss/Vine proposals stay out. Direct water-independent cold is named **Chill** rather than Frost.
Glass remains outside generic expansion. Every new focus requires palette group, Count grammar,
analysis prose, visible consequences and reachability/distribution fixtures before shipping; an
inert name-and-number entry does not count as content.

## 77. Expedition failure risks only what this expedition acquired

Portal and Waystone returns keep the full haul; defeat and collapse keep a reversible 50% of net-new
unbanked haul. Unused consumables, instruments, Anchor Frames and any other property owned before
departure return in full unless actually consumed. Knowledge, XP, recruits, tamed animals, Base and
anchored realms remain safe. Current saved-RNG item retention may remain temporarily, but exit
summary must name both recovered and lost objects. Game Design recommends comparing player-chosen
retained acquired slots at the same budget; that agency change awaits Aimee's review rather than
landing silently.
## Decision 78 — Armour gambits use absolute typed marks

Armour thresholds are absolute current-armour points, initially 1/3/5, because armour is flat soak
with no honest maximum to normalize against. HP percentage marks remain HP-only. Talin retains the
approved `subject_foe_armour_above` teaching and fixes the measured property/comparator while action
and priority remain player-authored. Exact marks remain playtest values. See
`gambit-stat-thresholds-current.md` and DRQ-091.

## 79. Found writing keeps the per-world promise after diaries thin out

Every generated world contains at least one discoverable writing in its start-connected reachable
region. The starting mix remains roughly 70% diary / 30% other writing with a 10% second piece, but
eligibility reweights rather than producing an empty world. Found writing is separate from named
diaries: disclosure-safe Field notes and Route marks supply repeatable world-bound records, while
visible-site fragments and real finite Working scraps appear only when eligible. Content selection
precedes host selection, and other writing never advances or resets the one-at-a-time diary patience
queue. See `found-writing-system-current.md`, DRQ-092 and DRQ-093.

## 80. Qualifier connections must form one readable statement

The live qualifier catalogue is 17 rungs, not the obsolete 51-item backlog. Intensity, Scale and
Count retain their settled generic roles, with Small corrected below the unwritten ordinary centre.
A component may contain exactly one target, only compatible focuses, modifiers linked directly to
one focus and at most one rung per ladder per focus; invalid prospective links are rejected instead
of being resolved by collection order. Hydrology Phase remains held and hidden because its live
labels are inert and do not map honestly onto standing/flowing/frozen/airborne. Replacing those words
is a recommendation for Aimee, not a silent revision. See `qualifier-grammar-audit-current.md`,
DRQ-094 and DRQ-095.

## 81. Cycle needs a clock consumer, not more synonym focuses

Tide, Orrery, Drift, Stillness, Echo and Dream are the current six direct Cycle focuses; Moon and
Amber contribute secondarily. The older candidate list is superseded and broad Time is rejected as
a duplicate of the subject sigil. Cycle peak now has a design-ready player-turn clock: <=8 stops,
then base periods 64/40/28/20 across increasing bands; regularity applies deterministic bounded
period jitter without reversing or repeating turns. Amplitude keeps its current ecology role until
a genuine per-phase dynamic-state pass exists. See `cycle-system-current.md`, DRQ-096 and DRQ-097.

## 82. “Quirk” is a paired-tradeoff principle; the separate layer is under review

The settled principle remains: memorable world requests offer opportunity and consequence together.
Current pressures, greed, ecology, terrain and Danger runes already produce that structure. The old
Quirk slot belongs to the retired page taxonomy, so a separately rolled catalogue plus veto/reroll
would duplicate causality and weaken the choice to leave a target unwritten. Game Design recommends
retiring that separate layer, but this is a challenge for Aimee's review rather than a silent settled
revision. Dim Sky remains great Cloud with reduced vision and pressure-derived ecology while its
legacy creature weight and flat tier bump are audited separately. See
`quirk-pattern-audit-current.md`, DRQ-098 and DRQ-099.

## 83. Debug tuning grows by playtest question, not by constant count

The live DEBUG-only persistent profile and its first five next-world controls are the correct base.
Expansion is grouped into expedition feel first and long-campaign pacing second, with explicit scope,
section resets, default values and profile export. Deterministic seed/content forcing lives in a
visibly separate Test Setup area, while read-only generation diagnostics precede a flood of new
sliders. Existing worlds never mutate when tuning changes, and semantic/story invariants are not
balance controls. See `debug-balancing-surface-current.md`.

## 84. Contradiction stays authored, narrow and honest about reachability

Opposed forces never create contradiction unless a named catalogue entry fires. The current first
slice is disclosed Stability cost plus Tear eligibility; generic danger multipliers and unique bulk
materials would duplicate Danger runes and invite farming. The six Negate entries are dormant
because live writing has no Negate grammar, so Game Design recommends holding that later authorship
branch rather than pretending it is content. Rain without air and A day that never turns remain
valid assertions, including uncommon unwritten-world combinations. Root-based Green in the dark is
disabled as a stale semantic bug because current dark flora may be fungal or chemosynthetic. See
`contradiction-danger-audit-current.md`, DRQ-100 through DRQ-102.

## 85. Analysis never outruns field calibration

The five-tier page lens remains qualitative prose, calibrated readings, focus attribution,
Stability explanation and living tendencies. Tier 3 currently leaks exact primary/secondary effects
for subjects the player has never measured; Desk and History must filter attribution by the affected
subject's permanent calibration. The page's own link structure and inert-mark warnings remain visible
from Tier 1, while Stability risk remains an opening binding promise rather than an instrument fact.
Tier-4 red/green meaning also needs an accessibility value. See
`description-analysis-surface-current.md`, DRQ-103 and DRQ-104.

## 86. Party overview chooses people; the minimap remembers known space

The Party member tabs and swipe pager now match the requested structure, but the roster still
duplicates all five core attributes. Keep Level/Health/Rank status and move the full attribute read
to Stats only. The minimap belongs directly below the D-pad, not beside it in the contextual-action
stack. It may always show portals and the separately settled revealed apex, but writing and sites
require legitimate reveal/discovery; the current all-page marker leaks the guaranteed writing's
position. See `playtest-ui-corrections-current.md`, DRQ-105 and DRQ-106.

## 87. Failure costs the expedition, not the next session

Partial acquired-haul loss, the paid binding and the end of an unanchored expedition are a sufficient
failure state for this long, bedtime-friendly campaign. Do not add injuries, repair debt, XP loss or
recovery timers. The recap must distinguish controlled return, combat defeat and structural collapse,
then show Recovered, Lost and permanently kept progress. Truly one-copy narrative/progression
objects cannot become missable through the random retention pool; they must commit, return protected
or remain recoverable until banked. Rare repeatable loot may still be risked. See
`expedition-outcomes-current.md`, DRQ-107 and DRQ-108; recovery agency remains DRQ-089 review.

## 88. Opening tutorials follow durable facts in the real game

Writing Desk and first-world lessons now have stable IDs, exact eligibility/completion facts and
short anchored copy. Blank-page binding remains valid; tap-to-travel and D-pad stepping are both
taught; interactions appear where the party stands, not merely beside an object. One card may appear
per screen, encounters/warnings outrank it, and old saves receive replayable Field Notes rather than
an opening takeover. No tutorial world, free bind or hidden safety rule is added. See
`tutorial-opening-slices-current.md` and DRQ-109.

## 89. Waystone may test Rift-glass without permanently spending the decision

Quartz remains the ordinary precision/lattice material, Rift-glass the rare reality-stressed
material, and Glass a proposed world-writing focus rather than an automatic inventory resource.
To keep implementation moving, the Waystone may reversibly replace its repeatable Adamant with one
Rift-glass while retaining the hardness-qualified world resource, one Mote, 30 essence and its
full-haul return effect. This protects Adamant's permanent analysis role and better matches boundary
crossing fiction, but remains DRQ-026 playtest rather than permanent approval. Tam inherits none of
these materials while their endgame role is held. See `glass-quartz-waystone-audit-current.md`.

## 90. Focus expansion lands as complete playable batches

The 62→85 vocabulary expansion is sequenced 7/3/4/5/4 by acquisition and downstream readiness:
ordinary reliable directions, early discoveries, mid reliable goals, mid discovered specialisation,
then late atmospheric/celestial identity. Every obtainable focus must already resolve, produce an
observable consequence, appear honestly in analysis, obey qualifier grammar and pass acquisition
and distribution fixtures. Material-named focuses bias rather than guarantee resources. Glass stays
outside the 23-entry scope. See `focus-expansion-implementation-batches-current.md`.

## 91. Gear migration preserves paid power without preserving the bypass

Legacy integer Blacksmith upgrades become construction tier up to 4, with any excess retained as a
visible non-growing legacy masterwork credit. Future reforging is rank 0–3 at 0.2 effective tier per
rank and never changes construction tier; fractional power carries to the final combat rounding
boundary. Stored and equipped gear retain one lossless instance profile, while legacy items receive
no fabricated recipe or material provenance. Specialist rebuilds explicitly warn before clearing a
legacy credit, and apex/Channelworks identities remain outside ordinary physical rebuilds. See
`crafted-gear-migration-current.md`. This explicitly supersedes historical Q35's rarity-based
+1/+2/+3/+5 reforge ceiling.

## 92. Specialist craft quality remains earned by the stock

Physical construction provisionally costs 12/24/48/80 essence by actual output tier after the
station cap, with normal keeper-at-Home discounts. Specialist stations permit tier 3/4 work but do
not inflate poor materials into it: construction remains the lower of natural grade tier and station
cap, with explicit confirmation for below-headline or wasted-grade selections. Crafting is
deterministic, one persistent piece at a time, and the first 21 families receive no generic named-
resource tax beyond their property-bearing inputs. Values remain DRQ-111 playtest. See
`gear-crafting-families-current.md`.

## 93. Other writing pays in local knowledge, not filler currency

Route marks reveal a persisted 2–4-tile content-free local terrain segment, Site fragments attach
authored pre-search-safe prose to a legitimately visible site without touching its contents, and
Working scraps teach one currently reachable ordinary recipe without granting its item or costs.
Every payload is chosen and frozen before placement; ineligible specialist weight becomes a Field
note rather than weakening the one-writing promise or leaking fogged content. See
`found-writing-breadth-current.md` and DRQ-112.

## 94. Site fragments speak only from what the site already shows

All nine implemented and six current expansion sites now have three stable anonymous fragment lines
safe before search. They describe visible construction, use or physical evidence without naming
contents, guardians, remote sites or analysis-only causes. Buried seams remain Deep Works evidence,
not generic writing hosts. New sites require at least two safe authored lines before entering the
Site-fragment pool. See `site-fragment-corpus-current.md`.

## 95. Field notes remember one truthful local relation

The repeatable fallback no longer draws only generic path prose. It selects a persisted qualitative
fact from local terrain, light/air, growth, water or a non-identifying visible creature trace, using
stable authored templates and a provisional 35/20/20/15/10 family mix. Exact pressures, hidden
content, species identity and analysis-only causes remain concealed; unusual worlds always retain a
truthful host-terrain fallback. See `field-note-grammar-current.md` and DRQ-113.

## 96. Exchange prices are authored bands; Recycler remembers actual construction

The first Exchange slice uses persisted expedition-refreshed staple/uncommon stock, resource sell
bands 1/2/5/12, grade-banded samples and a deliberately harsh 10 essence→1 gold / 8 gold→10 essence
door. Bulk selling is exact and excludes protected identities. Crafted rebuilds carry cumulative
real construction receipts while reforges add nothing recoverable; Recycler tiers return a chosen
40/55/70% subset and never invent found/legacy provenance. Values remain DRQ-114/115 placeholders.
See `trading-post-recycler-economy-current.md`.

## 97. Found salvage follows visible construction, not a fictional source

Found catalogue gear has no trustworthy construction receipt. Its authored Recycler profile may
therefore return reclaimed world resources for visibly forged/mineral pieces or reclaimed material
samples for visibly organic pieces. Tier bands return one, two or three outputs; none inherit a
creature, flora or world provenance the item never stored. Broad family profiles are a reversible
DRQ-116 placeholder, while item-level art/description contradictions override the family. See
`trading-post-recycler-economy-current.md`.

## 98. First return follows one real result; comparison never pretends chance was controlled

Tutorial slices 3–4 freeze one Base destination from the first expedition's actual returned
evidence, with new writing first and no stack of competing badges. Library copy describes only the
writing type recovered, so a non-location page cannot prematurely teach the traveller search loop.
The optional second-world exercise compares semantic target chains rather than page layout and
emphasizes changed requests without attributing every rolled difference to them. History continues
to respect the player's current analysis tier. See `tutorial-return-comparison-slices-current.md`
and DRQ-117/118.

## 99. Combat teaches the current decision; recruitment teaches two different homes for people

The first fight receives one current-actor/action lesson and a visible retreat explanation, never a
hidden safety exception. Gambits wait until after a player-involved encounter and are edited in
Party, not combat. The physical triangle waits for deliberate weapon/covering inspection rather
than appearing because a foe exists. A first traveller meeting explains that questions are free and
declining is only safe while the world remains; Firepit owns who travels, while Party owns stats,
gear, rank and gambits. See `tutorial-combat-recruit-slice-current.md` and DRQ-119.

## 100. The final tutorial hooks attach only to real system decisions

Later teaching does not become a second linear tour. Complete clues, build previews, carried
instruments, curio routes, full-satchel choice, actual collapse, available anchoring routes and
Worldwork each teach one boundary only when their normal verb exists. Complex stations retain
permanent help, and every destructive/paid decision remains uncommitted by the lesson. This closes
the paper design for tutorial slices 3–6 while leaving presentation density as playtest work. See
`tutorial-later-system-hooks-current.md` and DRQ-120.

## 101. Building the Tannery includes its foundational Wear capability

A station's substantial construction bundle buys its advertised first use, not another empty room.
Successful Tannery construction therefore grants the Wear root and makes Supple coat, Working gloves
and Working boots available at tier 1. Fitted Layers still buys tier-2 quality; Carry and Keep remain
separate advanced-capacity capabilities. Existing saves with a built Tannery infer the root once
without paying or losing purchased capacity. See `tannery-system-current.md` and DRQ-121.

## 102. A newly built equipment specialist already performs one Tier-3 job

The universal station lifecycle outranks the contradictory line that required an upgrade before an
advanced shop could make anything. Armoury, Bowyer and Weaponsmith at effective tier 0 each include
one foundational Tier-3 family/profile root. Tier 1 broadens authored choices/fitting while retaining
the Tier-3 cap; tier 2 permits Tier 4. Thus every substantial build bundle buys a real first use and
both later upgrades still add decisions rather than filler throughput. See
`gear-crafting-families-current.md`, `station-integration-matrix-current.md` and DRQ-122.

## 103. Armoury rebuild changes protection profile without inventing another gear ladder

Bracken rebuilds one existing protective instance in place: stable identity, slot, wearer and visible
history remain, while selected new layers replace construction tier/profile and reset reforge work.
Rigid uses full physical power; reversible placeholders make Balanced half a point and Insulated one
point lighter in ordinary protection while their selected insulation remains mechanically real.
Crafted receipts append actual new samples, found gear invents no old provenance, and legacy credit
can be cleared only behind a distinct before/after warning. See
`armoury-rebuild-implementation-current.md` and DRQ-123.

## 104. Weaponsmith fitting is a legible craft choice, not a wearer-bound subsystem

Maud's shop makes the existing physical triangle and reach rules more deliberate: point/edge advise
Finesse, maul advises Might, and the diary-taught polearm chooses a physical kind at mid reach. The
preview names that lean, but the resulting ordinary gear instance stores no chosen wielder, fit score
or equip restriction. Tier 0 starts with Fitted point, tier 1 adds edge/maul and tier 2 permits tier 4;
the polearm depends on Maud's persistent diary pattern. See `weaponsmith-implementation-current.md`
and DRQ-124.

## 105. Keeper-earned station tiers are an alternate route, not a crafting-only shadow tier

Every station surface resolves against effective tier. If keeper level supplies Tier 1, it satisfies
the same action gate and research rung as purchasing Tier 1; the player may reach a genuinely higher
paid rung without paying for obsolete access. The game does not forge a completed paid-node ID or
refund an earlier purchase: paid history remains truthful while prerequisite resolution recognizes
the earned route. See `building-staffing-current.md` and DRQ-125.

## 106. Raw Essence has one world acquisition grammar

Raw Essence is a removable wild drop placed by its dedicated world-generation pass. It is not an
ordinary harvest node, has no depleted-node state and receives no minimap node marker. The generic
resource yield table must therefore exclude both Reality currency and Raw Essence; allowing the
dedicated drop to enter that table consumes an ordinary world-resource draw and creates a second,
contradictory acquisition path. Frequency and quantity remain separate debug controls, and balance
changes wait for diagnostics measuring eligible drops, placed drops and obtainable total.

## 107. Minimap knowledge is earned through exploration or explicit investment

Aimee superseded the earlier navigation-promise exception after seeing the live minimap in play.
Portals, writing and the singular apex no longer bypass fog; they join sites, resources/items,
travellers, encounters, caches and hazards as discovery-gated points of interest. The entrance portal
is normally known because its starting tile is revealed. A skill-tree/station-tree node or consumable
may deliberately buy bounded insight, but the base minimap never reads hidden world-generation data.
The existing Farsight Draught is an aligned explicit spend; Reliquary-wide site revelation must become
an earned/selected effect rather than an automatic station-unlock leak. See
`minimap-disclosure-current.md` and DRQ-106.

## 108. Phone minimap sits beside the D-pad, above Portal home

The earlier “below the D-pad” placement was superseded after Aimee reviewed the repaired live phone
screen. On an ordinary phone the minimap fills the otherwise empty space beside the movement arrows
and directly above the Portal-home action. Stacking it under the arrows wastes horizontal room and
unnecessarily lengthens the world screen. The accepted side-by-side geometry is now a regression
fixture, independent of whether a tutorial overlay is present.

## 109. Phone world geometry is viewport-owned and whole-cell aligned

The first compact-height repair was rejected after physical-phone evidence showed a fractional last
grid row and tutorial-driven reflow. The accepted replacement derives the square from the actual
region remaining above fixed controls, floors each of 11 cell widths to whole device pixels, and
draws the tutorial through an overlay that cannot participate in layout. Lossless overlay/clear
proofs show the complete 11×11 grid and bottom border; the clear proof also preserves Decision 108's
D-pad/minimap/Portal arrangement. Full suite passed 810/0. Historical failed evidence remains in the
playtest record rather than being presented as acceptance.

## 110. Tovin's Isolde cross-clue points to stone, not high land

`tovin_about_isolde` says Isolde wanted stone she could see by. Its live `clueIndex: 0` incorrectly
routes that prose to Isolde's high-Relief condition; index 1 is her high-Substrate condition. The
metadata moves to index 1 while the authored line remains untouched. This is a clue-honesty repair,
not a prose revision or an added condition.

## 111. Explorable-map people use a dedicated straight-overhead grammar

World characters are not upright combat/portrait sprites rotated into the map camera. Their
16-pixel grammar uses crown/headwear occlusion, compact shoulders and foreshortened limb/garment
geometry, with N/E/S/W communicated by shape before colour. Party/current/actionable state belongs
to independent game overlays; no person owns a canonical blue body, face plane, floating nameplate
or equipment glyph that can be mistaken for a POI. AssetLab `mapTopDown` v0.3 is the accepted golden
proof. Its native adapter is versioned separately and follows, rather than mutates, the frozen
terrain/flora map-slice contract.

## 112. Launch shows the Atlas immediately and loads saves behind an honest boundary

Bookbinder uses a static system launch page and a matching in-app loading page built from the same
paired-page binding geometry. Save decode, reconciliation and committed persistence no longer leave
an unexplained black screen before the first SwiftUI frame. Loading shows no invented percentage;
timeout serializes behind the one active writer, failure offers safe Retry and diagnostics, and
VoiceOver receives one-shot Ready/actionable-failure announcements. The 816-test native v1 checkpoint
and ordered transition capture close the playtest launch-hang defect. Future timing work may optimize
the measured phases but cannot trade away save safety, truthful state or recovery.

## 113. Traveller meetings are independent exchanges grounded in visible practice

Every traveller meeting opens on one concrete action, then offers up to three optional independent
questions covering practice, tension and presence. Questions may be asked in any order or skipped;
none is a hidden recruitment test. Offer, accepted and declined copy are separate authored states
shown before dismissal. Stable semantic exchange IDs survive copy revision and atlas review. The 21
missing meetings now have a comprehensive scene-anchor/batch plan, but those anchors are not
placeholder dialogue: exact prose remains subject to Aimee's authored-text review before entering
the live catalogue.

The first authoring batch—Bryn, Orsa, Vance, Talin and Nessa—now has complete review copy and fifteen
stable exchange IDs in `traveller-meetings-early-hinge-review.md`. This records a review candidate,
not approval: its catalogue/atlas state remains `Draft / needs Aimee review`, and Engineering may use
it for atlas/schema exercises without exposing it as shipped dialogue.

The second review batch—Corrin, Dagg, Rook, Lys, Bracken and Fen—adds six complete meeting drafts and
eighteen stable exchanges in `traveller-meetings-mature-core-review.md`. It follows the same boundary:
the batch is coherent authoring evidence and atlas input, not approved live copy. Together the first
two batches cover eleven formerly missing meetings and thirty-three independently reviewable
exchanges.

The third review batch—Wren, Kestrel, Maud, Marrick, Sabine and Grimmond—adds six complete meeting
drafts and eighteen stable exchanges in `traveller-meetings-specialists-review.md`. Its authoring
boundary is unchanged. The three completed batches now cover seventeen formerly missing meetings
and fifty-one independently reviewable exchanges without silently expanding the live catalogue.

The final review batch completes all twenty-one formerly missing meeting drafts. Oda, Ashe, Perren
and Nine add twelve stable exchanges, while Auber receives a three-exchange revision candidate that
preserves his existing semantic IDs and invalidates old exact-text hashes. The four corpus documents
therefore contain sixty-three new exchanges plus Auber's three revised exchanges; all remain
`Draft / needs Aimee review` until the atlas review explicitly promotes them.

## 114. Encounter scaling reads the whole travelling party without inventing foes

Difficulty references Binder plus every valid selected companion and uses the upper median of their
levels, so one veteran does not punish a mostly new group and the legacy single-companion accessor
cannot erase three party members. `partyCount` always includes Binder. Ordinary density may collect
only actual visible/awake persisted world entities; an unrepresented budget becomes a bounded,
explicit level adjustment and never a synthetic off-map combatant. Apexes scale through a visible
level floor, HP/offence profile and genuine round action slots while remaining stationary, opt-in and
Unbindable. Exact coefficients remain a three-profile DEBUG comparison under DRQ-128 rather than a
settled difficulty claim.

## 115. Generated people persist by identity, not by roster position

A generated person receives a stable generated-person ID and an explicit origin distinct from both
Quill and named travellers. The durable met pool owns their identity, want, first-met level and
three-branch recommendation; worlds, Tavern seats and assignments reference that ID rather than a
mutable roster index. Visitor rotation is a persisted expedition-outcome snapshot and never erases
the met pool or advances on wall-clock time.

**Graph-planning portion superseded by Decision148.** At the time, arrival builds stored an ordered
sequence of branch steps rather than combat-node IDs, matching the then-live branch-depth model. A high-level arrival also receives threshold-
correct experience, ordinary replayed stat growth and exactly one calling-lean free point; visible
level cannot coexist with level-1 stats or impossible next-level XP. Exact appearance chances,
visitor weights and want mix remain playtest values under DRQ-052/053/073.

## 116. Tamed animals preserve the exact individual across field, Menagerie and combat

Attend targets a visible non-pursuing individual and saves trust against its world-persistent enemy
identity. Patient presence uses a disclosed minimum distance-2 watching band so animals with ordinary
detection radius 1 still have the universal non-adjacent solution; this does not enlarge aggro.
Offerings consume an exact property-bearing world-resource sample, never an aggregate resource that
has no individual properties. Join us atomically mints one stable `TamedAnimalID` and preserves the
saved trait/species/visual receipt.

Tamed animals are not nil-traveller human companions. They own a distinct saved state and combatant
identity, a frozen trait-derived kit and threshold-correct level/XP. Shared party and combat systems
work through stable member identity while human equipment, trees and respec remain ineligible. Trust
turns and derived-kit coefficients remain playtest scope under DRQ-046/074; identity, no capture roll,
no free sixth slot and no human-tree disguise are structural.

## 117. Essence income must sustain authored continuation, not merely avert a hard lock

The existing anti-lock Spring shortfall remains an emergency guarantee, but routinely funding only
the 10-Essence blank bind is not a healthy loop. A reasonably explored ordinary world should
normally fund another ordinarily authored world while gradual surplus makes optional Essence use
possible; highly precise books may still cost savings. Raw Essence remains the single dedicated
world acquisition grammar and stays fog-hidden.

The current 2–4 drops worth 1–2 Raw Essence averages only about 12 refined Essence including the
Spring and is confirmed too lean. Use 5–7 drops worth 2–3 each as the reversible Recommended
playtest profile, with Lean and Generous comparisons and explicit generated/collected/cost/runway
telemetry. Exact rates remain under DRQ-126 rather than silently becoming final balance.

## 118. Anchored production begins with stable, shared renewable-source receipts

Realm assignments persist worker identity rather than roster position. A discovered eligible source
receives a stable realm-local identity and survives depletion as saved source state instead of
becoming semantically empty. Field harvest and posted production reserve that one source atomically,
so the same renewal cannot be collected twice.

The first complete production slice handles only ordinary bulk resource nodes already represented
by `ResourcePool`; it does not invent property-bearing material samples. Each expedition outcome is
processed at most once through a saved receipt, with sustain, progress, delivery, Essence payment or
dormancy committed together. Flora and non-lethal animal production follow only when their exact
  source/provenance receipts exist. Rates and tray capacity remain playtest values under DRQ-132.

## 119. Companion placement and station keeping require stable, separate authority

Every non-Binder companion has one stable identity and one authoritative placement: Home, Party or
one anchored realm. Party order may remain ordered presentation, but mutable roster indices and
independent arrays cannot own placement. Generated people share this contract; tamed animals may be
placed without thereby becoming human keepers or first-slice Worldwork staff. Ambiguous legacy
references return safely Home rather than being guessed.

Station lifecycle, builder/unlock traveller, keeper and keeper-activation condition are separate
facts. This allows Lys to deepen the already-present Library and Orsa to own the Tavern only after
the Firepit upgrade, while simple found-then-built trades may name the same person as builder and
keeper. Home discounts begin only once the station exists, so initial construction is not
discounted; later eligible paid actions are. Exact discount rates remain tuning under the existing
staffing design, while stable placement and truthful ownership are DRQ-133 migration boundaries.

## 120. Party-member identity is namespaced and progression follows the individual

Quill, named travellers, generated people and tamed animals receive distinct namespaced persistent
identities; the Binder is stable but not a roster record. Optional Traveller ID, display name and
roster position cannot imply identity or origin. Human versus animal state is explicit, with human
origin separating Quill, named and generated people. Skill trees, gambits, gear, respec, keeper and
Worldwork eligibility follow visible capabilities rather than nil checks.

Party, encounter actors/targets, run HP/status, equipment, expedition progress and assignment all
reference the same stable identity. The roster-index migration converts these references once using
the frozen legacy roster and does not keep two writable authorities. Invalid legacy references may
return a real companion safely Home or invoke explicit encounter recovery, but can never alias the
person who happens to occupy that index. This shared DRQ-134 boundary precedes generated-person,
animal and renewable-realm implementations so they do not create incompatible local identity types.

## 121. Exchange, Recycler and Blacksmith form the opening found-person sequence

The intended first people found are Vance/Exchange, a new distinct Recycler keeper, then
Halloway/Blacksmith. This is authored clue/signature priority rather than a hard nonlinear-discovery
gate. Vance retains trade, appraisal, circulation, Amber and his established voice but no longer owns
material recovery. Working new traveller Noll (they/them) reads how objects part and owns an
independent Recycler; exact name, prose and exclusive teaching remain reviewable rather than silently
final.

Provisional opening signatures use one starter-writable Relief condition for Vance, two starter-
writable Substrate conditions for Noll, and Halloway's existing two. Exchange and Recycler begin as
separate cheap Essence-only constructions (10/15 placeholders) so the stations that relieve early
surplus do not require that surplus to exist. Recycler correctness, exact provenance and preview are
baseline rather than diary gates. DRQ-135 tracks identity/cost/playtest values; the role split and
authored order are current.

## 122. One expedition outcome receipt advances every return-based system exactly once

Each active-expedition-to-Base transition mints one campaign-local monotonic
`ExpeditionOutcomeID`. World run index cannot serve because anchored realms are revisited repeatedly.
Spring income, writing/rune pacing, Exchange stock, anchored production/replenishment, tutorial and
history/telemetry consume that shared receipt idempotently; ordinary combat victory/flee and recap
dismissal mint none. A pending Anchorage or future recovery choice references the same committed
outcome rather than inferring another return.

The exit transition freezes kind and result inputs, commits permanent rewards/haul or pending
recovery, runs automatic consumers once, saves their receipts and clears the active expedition
atomically. UI is a projection and cannot reroll or retick on relaunch. Dedicated subsystem RNG may
derive from outcome ID, but return processing never consumes mutable world/combat RNG by accident.
DRQ-136 is the shared prerequisite for the later Exchange, anchored-production and recovery slices.

## 123. Noll's first complete working packet teaches portable, honest dismantling

Noll remains the working second-found Recycler keeper between Vance and Halloway. Their identity,
two-condition signature, six-page diary and three-branch meeting are now structurally complete in
`traveller-identity-noll-recycler-current.md`; exact name, pronouns and prose remain atlas-reviewable.
Their distinctions stay mechanical as well as verbal: Vance prices circulation, Noll recovers useful
material, and Halloway repairs or makes whole objects.

The reversible singular diary pattern `field_separation_kit` adds one-use expedition dismantling at
tier-1 Recycler efficiency, using the same exact receipt-versus-authored-profile preview and atomic
recovery rules as Home. It costs a placeholder 5 Essence, 2 Timber and 2 Fibre and one committed
world turn; failures/cancellation cost nothing. This is portable convenience, not baseline safety or
better yield, and it creates no scrap currency. If device play shows administration without a real
choice, retire the pattern without weakening the ordinary Recycler to make it necessary. DRQ-033 and
DRQ-135 retain the prose, cost and playfeel review boundaries.

## 124. Trading Post replaces Exchange in both player language and implementation identity

Vance owns a **Trading Post**, not an Exchange. Its fiction is a merchant with expedition-refreshed
rotating stock: the player sells eligible goods for gold and buys the particular resources/items he
currently carries. “Exchange” incorrectly implies a general resource-to-resource conversion table.

Because this station is not implemented and no shipped save depends on an old ID, the stable station
ID is `trading_post` and its state is `TradingPostState`; there is no migration benefit to preserving
an unused misleading internal name. The unrelated `TravellerMeeting.Exchange` type still means one
question/reply pair and is not station terminology. Decision124 supersedes the station name in
Decision121 and any current doc that still says Exchange; archived wording remains historical.

## 125. Essence gains unlockable refining progression without making research a continuation tax

The opening 2-refined-per-raw economy must fund ordinary writing before upgrades. After baseline
telemetry, the keeper-free Essence Spring branch adds Measured batches (quantity control), Second pass
(reversible future-only 2→3 conversion) and Continuous settling (optional one-per-outcome automatic
refinement after haul retention). Existing Deepen the Spring remains a separate return-dividend node.

Exact costs and the 3:1 rate remain DRQ-137 playtest values. No node repairs historical transactions,
creates fractions, moves refining to Auber or makes the Trading Post a superior refining route. This
turns a long campaign's Essence handling into progression while preserving B0 as a true baseline
playability requirement.

## 126. On-device bug capture enters an untriaged durable queue after blockers

After Essence continuation and early Trading Post/Recycler offloading pass, DEBUG receives a movable
floating Report Bug control. It captures the pre-sheet app scene, build/safe gameplay context and
Aimee's text into a durable local outbox. Aimee does not assign priority; Design/Engineering triage
Blocker/High/Medium/Low later. Offline or transport failure cannot lose a confirmed report, and one
stable BugReportID is the idempotency key.

Direct delivery still needs an explicit authenticated shared destination. Until selected, the honest
fallback is “Saved on this phone — not yet shared” plus one-tap Share/export, never a false Submitted
state. Tokens are not embedded in the app. Exact transport remains DRQ-138; capture/privacy/outbox
semantics are current in `debug-bug-reporting-current.md`.

## 127. World visual distance reflects relative authored and resolved diversity

Worlds are not required to look universally unique. Their visual relationship must be truthful:
books and resolved worlds that are materially similar should produce related visual identities,
while meaningfully different material, ecological, atmospheric or emitted-light facts should create
proportionally stronger separation. Arbitrary cosmetic variation must not make near-identical worlds
look unrelated, and a weak global tint must not collapse strongly opposed worlds into the same place.

Illumination is a current-light and visibility mechanic rather than stored terrain brightness.
Vitality governs legitimate ecology—species abundance, coverage, bounded stature and bounded
richness within resolved hues—rather than adding universal green. Material color, ecology color,
atmosphere scattering and emitter light remain scoped compositional layers. Unrevealed fog,
minimap/POI disclosure, rule-bearing terrain grammar, canonical resource identities and species
identity remain invariant. `world-color-differentiation-current.md` owns the current proof and
versioning boundary; exact palette families, coefficients, swatches and blend math remain reviewable.

Decision131 supersedes the page-grammar portion of this decision: color authorship is now an ink
attribute on a source mark rather than a connected qualifier with its own footprint. The scoped-
ownership boundaries remain current: scope derives from an authored source allowlist, Flora and
Creature stay separate, visible atmosphere still requires an explicit resolved medium, and material
identity remains distinct from presentation palette.

## 128. The first authored-color slice is learned vocabulary, not a theme picker

**Superseded by Decision131.** Retained to show why the fixed named-color vocabulary was explored.

Pending Aimee's later swatch/rate play review, Design adopts the reversible first-live package in
`authored-color-vocabulary-current.md`. Color is a connected qualifier with ordinary page footprint,
permanent Reality acquisition and at most one color on each source in the first slice. The player
chooses a named color and focus; a closed source-ID allowlist derives technical scope. Sun/Emitter,
Smoke/Atmosphere, Granite/Material and Bloom/Flora are the first four mappings. Bloom cannot recolor
creatures, and unsupported sources fail before binding rather than receiving an inferred global tint.

The provisional twelve words are Red, Orange, Yellow, Green, Cyan, Blue, Violet, Magenta, White,
Grey, Black and Ochre. Red/Yellow/Blue/Grey start known; six common colors arrive as found writing;
Cyan/Magenta enter later. Brown remains out until play demonstrates an intention not covered by
Ochre, material identity or mixing; Pale/Bright/Dark are not mislabeled as colors. Found colors are
permanent writing knowledge, never loot, never loss-eligible, and never displace a selected diary,
story teaching or traveller-pity word. Exact coordinates, rates and later acquisition routes remain
reversible tuning rather than settled fiction.

## 129. Ordinary party scaling uses real nearby foes, then visible lighter tempo

The current `+level` conversion for missing ordinary foes is rejected: two hidden levels are only
about 1.188× on the live curve and misdescribe encounter composition as species level. The reversible
candidate in `encounter-scaling-playtest-current.md` instead gathers awake reachable map entities
within party-sized path radius, then converts each whole missing equivalent into +15% encounter HP
and one saved 55% single-target affliction-free follow-up. A half equivalent adds +15% HP only. No
entity appears from off-map, and XP, loot and Bestiary progress remain based on real foes.

Profile B's apex +2 level floor, bounded HP/offence and 1/2/3 interleaved actions remains the first
phone candidate. Ordinary pressure never stacks into an apex encounter. Recommended replaces
nil/Legacy as the next-bound development default once the new candidate exists, using a versioned
tuning migration that leaves active runs untouched; Legacy remains an explicit DEBUG comparison.
Coefficients remain playtest tuning and must be revised if phone evidence shows one-hit defeats, HP
walls or unreadable action tempo.

## 130. Base destinations are four compact place boards with explicit order

The long-campaign Base uses **Home, Make, Study and Realms** tabs rather than one two-column scroll of
every station. Ordinary phone layout uses three compact illustrated place tiles across; six opening
Home destinations fit in two rows. Construction is the foundation state of the eventual station tile,
not a second full-width building-site list. Bind & Depart remains fixed outside every tab.

Station placement is authored by `homeSection` plus unique `sectionOrder`; duplicated `sortOrder` and
JSON array order cease to be presentation authority. Make begins Trading Post, Recycler, Blacksmith,
preserving Aimee's opening sell→recover→make sequence. Firepit→Tavern and Library keeper depth retain
one stable tile. Unknown places remain absent, and section badges derive from legitimate foundation/
attention state rather than manual counters. `base-destination-board-current.md` owns the complete
26-destination mapping, migration and phone/accessibility gates.

## 131. The Penmaker unlocks deliberate colored ink; Ash leaves color open

The starting Ash ink is visually dark on a page but semantically means **color unspecified**. An
eligible Ash-written or unwritten world feature receives a full-range, scope-valid random color at
bind time, and that resolved result persists. Ash is not an instruction to make the world black;
explicit mixed black is a distinct non-nil recipe.

Deliberate color authorship is earned through Isolde's Scriptorium. The tier-1 **Ink mixing**
Penmanship upgrade, placed after **A pencil**, permanently adds a CMY+Depth mixer and saved-mixture
library to the Writing Desk. It does not create another Penmaker traveller/shop and does not require
the fountain pen. The exact node cost remains reversible alongside the other hand costs.

Mixed ink is an optional recipe attribute on an eligible source mark, not a Color qualifier, extra
page footprint or collectible word. The first slice has no per-mark pigment consumption. Exact
recipes and resolver versions persist; old saves/pages decode missing ink as Ash/open. The old
twelve-swatch proof remains accessibility and gamut research only. Sun/Smoke/Granite/Bloom retain
the first closed scope allowlist, and color remains mechanically visual.

## 132. Maker stations share a spatial workflow, not long recipe lists

Blacksmith is the first proof for a reusable maker-station shell. Station-local verbs become tabs;
recipe or profile families use three-column illustrated tiles; exact stock, material samples and
owned targets use six-across icon trays. Names, requirements, provenance and comparisons remain
available through selection rather than appearing as one full-width row per object.

One rules-owned preview supplies readiness, requirement sockets, eligible/rejected exact stock,
deterministic suggestions, output comparison, cost, warnings and the atomic commit fingerprint.
Presentation cannot restate thresholds or costs. Item information opens in an anchored popup that
flips/clamps at screen edges, with a compact accessibility-sheet fallback; it never pushes a new
full-screen item page or loses the station workflow.

The shared shell does not merge mechanics. Blacksmith retains Make/Reforge/Learn; Tannery, Bowyer,
Armoury, Weaponsmith, Apothecary, Distillery and Channelworks reuse only the appropriate verbs and
components. Existing stable-instance, provenance, tier, legacy-loss and transaction contracts remain
unchanged. `maker-station-screen-grammar-current.md` owns the phone and accessibility gates.

## 133. Compound shorthand must be earned by binding the full statement first

A personal compound may formalize one complete 2–5-atom statement only after that exact normalized
statement has been successfully bound at least once. The bind writes an idempotent proven-statement
receipt; it does not include page coordinates, uncontrolled world rolls or outcome. At Isolde's
Scriptorium, the player chooses a proven eligible statement, reviews exact semantic equivalence and
compression, names it and pays once. The Writing Desk places existing compounds but cannot mint an
unproven shorthand from arbitrary atoms.

Penmanship branches after A pencil and the tier-1 Scriptorium into three independent capabilities:
Ink Mixing controls medium/color, Compound Assembly compresses one proven statement, and Chaining
joins distinct statements. None requires another; the fountain pen still requires Chaining and
Scriptorium tier 2. Exact costs remain playtest values.

Proven receipts and personal compounds are separate persisted identities. Placed compounds freeze
their expansion, so deleting a Runebook entry removes only future palette access and never mutates
saved pages, bound books or worlds. A later re-formalization receives a new stable personal ID.
Unknown components, nested compounds and semantic order changes cannot be laundered through the
formalizer. `compound-assembly-station-trees-current.md` owns the interaction and interruption gates.

## 134. Growing catalogues derive classifications; authored judgment stays explicit

The dynamic-authority audit does not proceduralize design. It moves deliberately authored facts to
the catalogue/manifest that owns them, then derives consumers or validates required compiled mirrors.
Four next boundaries are current:

- the generated draft meeting corpus owns its traveller-ID set; the DEBUG atlas cannot maintain a
  second hand-written list;
- each resource/item definition owns its explicit Trading Post band/disposition; rules and UI cannot
  infer tradeability from rarity/name or require a second Swift allowlist;
- one frozen versioned AssetLab integration manifest owns accepted render vectors, with native
  conformance generated or validated rather than visually reimplemented by hand;
- expanding permanent research capabilities migrate from writable one-off booleans to stable
  capability IDs when Ink Mixing/Compound Assembly land, while typed accessors remain computed.

Missing classifications fail closed and name the missing stable ID. Runtime Release builds never
parse design Markdown, historic decisions remain archived, and balance/prose/order stay authored.
`static-manual-authority-audit-current.md` owns sequencing and acceptance.

## 135. Colored-ink bases come from world resources

Decision131's “no pigment consumption” first-slice assumption is superseded. Isolde unlocks the
technique, but Cyan, Magenta, Yellow and Depth base stocks must be prepared from world resources;
the Scriptorium does not conjure them from Essence or a color picker.

Drafting, mixing and preview remain free. Preparing a saved-formula vial consumes its exact quoted
bases/binder, and binding atomically consumes applications only for mixed-ink source marks. The
first DEBUG candidate is twelve applications per vial. Ash remains unlimited and uncolored, so
resource scarcity can limit optional color control but never block an ordinary world or campaign
continuation.

Pigment provenance must be authored/persisted. Fungible minerals may have canonical pigment yields;
flora/creature resource samples may freeze the source species' pigment profile at harvest. Generic
Toxin, Reagent or Pulp cannot retroactively claim Magenta because of a recipe name. Copper/Resin,
magenta-bearing biological sample/Resin, Sulfur/Resin and Obsidian/Resin are proof candidates for
C/M/Y/Depth, not settled recipes. Exact inputs, yield and the Magenta availability floor remain
DRQ-141 playtest questions.

## 136. Combat actions stay on the stage and never choose an unstated ally

The combat stage remains visible while the player chooses Attack, Techniques, Items or Unbind.
Techniques use a compact glyph grid and items the six-across object tray rather than full-screen/modal
prose lists. One structured rules preview supplies action, legal/rejected targets, visible default,
disclosed consequence and atomic fingerprint.

Foe-, ally-, self-, all- and no-target actions share one explicit stage-target grammar. An ally skill
does not silently choose the lowest-health person. A one-legal-target action may resolve immediately;
otherwise the player chooses or re-taps the selected action to use the visibly named default. Attack
never temporarily means “use the selected skill.” Items appear once per stack rather than once per
possible recipient.

Player-facing retreat is **Unbind**, with a compact consequence confirmation; internal flee IDs may
remain. Companion automation is controlled by an actor-scoped Direct/Gambits affordance rather than
tapping arbitrary party cards. `combat-action-palette-current.md` owns the phone, accessibility and
interruption gates; combat effects and tuning are unchanged.

## 137. Combat progression uses three prerequisite graphs — topology superseded by Decision151

The implemented nine `branchDepth` ladders are superseded. Offense, Defense and Craft are three
actual trees, each drawn as three discipline lanes across eight ranks. All 72 existing node names and
effects remain, but ownership moves to stable node IDs and explicit prerequisite edges.

Ranks 1–3 establish a lane. At ranks 4 and 6, a node may be reached from the preceding rank in its
own lane or an adjacent lane; outer lanes never jump directly across the centre. Ranks 5 and 7
continue in-lane. A rank-8 capstone requires its rank-7 predecessor and at least five owned nodes in
that final lane. This gives pure and hybrid routes real opportunity cost while allowing a complete
route in eight points. The 24 standard level points therefore still fund three capstone routes, but
do not prescribe one rigid branch per tree.

The visual lane order is Force/Precision/Swiftness, Fortitude/Protection/Evasion and
Venom/Emanation/Shadow. Centre disciplines are semantic bridges. The native screen must present the
whole selected 3×8 graph with visible edges and anchored node details, not branch cards, prose rows or
a global Learn-next button. Legacy `(branch, depth)` state migrates losslessly to the same-lane prefix
of stable IDs. This rank-lattice topology was later rejected as still too ladder-like; Decision151
and `combat-tree-true-graph-current.md` now own the exact prerequisites, node table, migration and
acceptance tests. The stable-node and lossless-migration conclusions here remain current.

## 138. Ink bases use four existing world resources and integer measures

The initial live pigment recipes are Copper→Cyan, Ichor→Magenta, Sulfur→Yellow and
Obsidian→Depth. Each exact world-resource unit processes deterministically into four measures of its
base without Essence or Resin. Ichor replaces the earlier generated magenta-sample candidate because
it already has a canonical dark-magenta resource identity and does not require inventing retrospective
color provenance.

A prepared mixed-ink vial consumes one Resin plus `ceil(channel / 25)` measures for every nonzero
CMY/Depth channel. The exact 0…100 formula remains stored; only inventory cost is quantized into four
readable bands. A vial currently supplies twelve successful mixed-focus applications. Drafting remains
free and all preparation/bind consumption is atomic. Ash remains unlimited, so pigment access cannot
block world writing. Twelve applications and acquisition frequency remain playtest tuning; the four
source identities and integer-measure transaction are current.

## 139. A combat node is implemented only when gameplay consumes it

The combat-tree correction includes the semantics of all 72 nodes, not only graph presentation and
owned-node storage. The live fossil test is insufficient: it proves that buying a node changes a
`Loadout` field, while most of those fields are never read by combat, world, crafting or yield rules.
The graph cannot become the default while such nodes are inert.

`combat-node-viability-current.md` now fixes each node's trigger, target, stacking, provenance and
encounter/run boundary. Party auras use the strongest applicable copy once; carried/splash/chained
effects cannot recursively proc themselves; player actions do not silently choose allies, harm kinds,
conditions or emanation kinds. First Strike and Ambush are first-turn, once-per-encounter actions;
Quench removes one chosen emanation affliction rather than every condition; Emanation Strike offers
Heat/Caustic/Light instead of hardcoding Burn. Every stable node ID requires a scenario-level test
whose outcome changes when its actual consumer is removed.

## 140. Encounter scaling uses additive party power, not median or maximum level

Newly bound Recommended encounters use the Binder as a stable level anchor. Each active companion
adds `clamp(0.5 × 1.09^(companion level − Binder level), 0.25, 1.5)` foe-equivalent power, with the
ordinary total capped at 3. Equal-level parties therefore retain the intended
1/1.5/2/2.5/3 budgets, while adding any lower- or higher-level member can never lower difficulty.

Ordinary real foes keep Binder/world/Greed/Stability base level. Budget shortfall creates the already
specified path-honest pressure slots and proportional fractional durability, not hidden foe levels.
Apex durability and offence read the same power budget; apex action slots continue to read party
count because turn-stage tempo depends on the number of actors. Maximum level is rejected because it
makes low-level allies liabilities, and upper median is retained only as historical decode/debug
evidence because it can fall at odd-party boundaries. Exact coefficients remain phone-playtest
tuning; the additive, monotonic structure is current.

## 141. Recycler recovery rules are implemented; their catalogue ownership still needs migration

The current Recycler rules satisfy the structural design: real cumulative construction receipts take
precedence; the player selects exact recoverable samples; found gear uses explicit honest 1/2/3-output
profiles; ordinary current gear has complete coverage; apex, unique and legacy-masterwork gear remains
protected; stored/overflow commits and stale previews are atomic. DRQ-115/116 therefore move from
placeholder design to implemented-rules/phone-playtest status. Efficiency and outputs remain tunable.

The current found-gear map is nevertheless a private Swift table keyed by every item ID. Before the
next ordinary gear catalogue expansion, move each item's `salvageProfileID` or protected disposition
into catalogue metadata and validate it against one profile registry. This changes no accepted output
and never permits slot/name/rarity inference; missing metadata remains sell-only.

## 142. Research prerequisites must render as a graph, not an outline

The research catalogue is already a real prerequisite DAG, but the native branch screen deliberately
turns it into cheapest-first full-width rows and states that “there are no edges.” That contradicts
the earlier settled requirement that players see what leads where and recreates the list-heavy UI
problem under indentation.

Every research branch now uses a screen-width topological graph with up to three compact node columns,
all prerequisite edges—including diamond parents—visible, stable-ID deterministic placement and an
anchored edge-clamped node detail for grant, requirements, cost and Study. Independent roots occupy a
labelled root band; small branches remain small graphs. Optional authored layout hints may group
siblings but never change semantic rank or prerequisites. Price, name and JSON order cannot rearrange
the graph. The current outline survives only as a topology-preserving accessibility-large fallback,
not the ordinary screen. Mechanics, costs and completion state are unchanged.

## 143. The current Constellation is one honest star, not a fake future tree

The live Constellation contains only The Long Instruction. It therefore presents one centred Reality
node with anchored detail rather than a full-width card list or invented locked constellation. The
effect is stated exactly: one additional Gambit rule slot for every eligible current and future person
in this campaign.

Remove the native claim that Constellation purchases “survive everything, including a future reset”
and that nothing else does. Reset/Great Work outcomes are intentionally unresolved, so this is
unimplemented-ending leakage rather than useful foreshadowing. Current copy says only that the
Constellation changes Reality rather than one building or person. A spatial constellation graph is
revisited only after at least three approved, consumed Reality nodes exist; fossil nodes cannot be
restored to decorate the screen.

## 144. Combat points are durable choices with explicit technique and capstone windows — pacing superseded by Decision151

Every level after level 1 grants one bankable standard combat point; no level-up flow automatically
spends it. The original rank-3/rank-6 technique windows belonged to the rejected ladder/lattice.
Under Decision151's true fork, the earliest first technique is level 3, a second authored technique
opportunity is level 4 or 5 depending on discipline/route, and capstone windows remain levels 9, 17
and 25. These are opportunities rather than mandatory build checkpoints, so hybrid or broad
investment may delay them.

The Binder receives one dismissible first-point explanation on the actual graph. Expedition recaps
and Party tiles expose unspent points without interrupting the return flow. Companion arrival plans
use legal stable-node sets and unresolved legacy nodes return their point rather than aliasing new
content. Full Spring respec atomically returns the exact standard-plus-calling budget and never
auto-spends a replacement build. Exact UI and acceptance are in
`combat-tree-progression-experience-current.md`.

## 145. Mundane preparations do not tax world-writing; departure supplies are chosen

The current blanket Essence cost on all 17 Apothecary recipes contradicts the continuation economy:
ordinary salves, cures, coatings and field tools consume the same scarce medium required to write the
next world even though their named resources and qualifying samples already price them. The
Recommended playtest profile therefore sets mundane preparations to zero refined Essence, retains 6
for Stillwater and 12 plus one mote for Waystone, and measures those two values before promotion.
Only effects that directly hold together or escape a bound Reality normally justify an Essence cost.

Departure also stops auto-packing every identified consumable in inventory order. Home stores one
explicit desired-count Field Kit loadout by stable item ID; new bindings and anchored revisits resolve
the same loadout atomically and never pack unselected filler. A conservative legacy suggestion is
shown for review rather than preserving the accidental old ordering. The full implementation and
screen contract is `consumable-economy-field-kit-current.md`.

## 146. World History is a compact experimental archive with ordinary two-world comparison

The History landing no longer embeds each world's full prose and written lines in a full-width card.
It uses two-column frozen world covers as entry points into the existing earned-analysis detail. New
records freeze a small versioned visual summary; legacy records receive an honest neutral mark rather
than being rerolled through current art rules.

Any two visible records may be selected for the same comparison tool used by the tutorial. Semantic
differences use the union of stable request keys and explicitly show Not written on the absent side;
measured differences appear only when both saved records and current calibration legitimately support
them. Search cannot reveal hidden people or subjects. Bookmarking is in-place, while erasing names the
exact world and requires confirmation, with stronger protection for kept records. Exact behavior and
schema are in `world-history-collection-comparison-current.md`.

## 147. Anchorage is a realm portfolio; settlement never defaults to dormancy

The Anchorage uses Atlas, Work and Deliveries views rather than repeating one full-width management
card per realm. Compact realm destinations preserve frozen world identity, active/dormant state,
sustain, posting and attention; detailed work retains the settled one-source, sustain-first model.
Posting uses person tiles and explicitly previews contribution plus removal from Party, another realm
or a Home keeper benefit before one stable-ID atomic transfer.

Most importantly, the settlement sheet cannot interpret untouched unchecked rows as consent to make
every due realm dormant. Each due realm requires an explicit **Sustain** or **Let rest** decision and
Confirm stays disabled until all are decided. Sticky totals show payment, remaining Essence, authored-
bind runway and realms that will rest. Dormancy returns people safely; reactivation never auto-posts
them. Exact interaction and migration rules are in `anchorage-portfolio-assignment-current.md`.

## 148. Generated people use real stable-node graph plans, not buy-next branch ladders

The older generated-arrival design persisted branch IDs and repeated “buy next” steps specifically
instead of combat node IDs. That is incompatible with the settled graph: it cannot represent hybrid
crossovers and allows topology changes to silently reinterpret a person's prior practice.

New generated people persist three validated pure/hybrid route-template IDs, an ordered explicit
`CombatNodeID` plan, graph version and calling-root node. The default cadence finishes the primary
route by level 8, reaches each supporting route's first technique by level 12 and one development in
each by level 14, finishes all three
capstone routes by level 24 and uses level 25 for one saved legal breadth node. Follow their practice
previews the next exact node and never skips an invalid entry. Legacy branch steps replay through
decode-only pure paths once; unresolved points become unspent rather than being positionally aliased.
Exact generation and fixtures are in `generated-companion-arrival-builds-current.md`.

## 149. Party, Home and realm posting are one exclusive person placement

The Firepit cannot call every non-party person “around the fire,” because some are working in anchored
realms. More seriously, the live party-selection action can add such a person without removing their
realm assignment. Recruited humans therefore use one stable placement authority—Home, active Party,
one realm or a future typed assignment—with old arrays retained only as projections/migration input.

Firepit shows fixed departure positions and a location-grouped Community; Orsa adds persisted Visitor
tiles to the same destination. Taking a Home keeper or realm worker previews the exact suspended
benefit before an atomic transfer. A full party uses one explicit replacement transaction, and
returning someone sends them Home rather than guessing an old job. Generated visitor build summaries
read the new stable-node graph plans. Exact interaction and reconciliation live in
`community-party-tavern-current.md`.

## 150. Lys catalogues typed recovered evidence and preserves where a page was found

Lys immediately adds recovered-only search/filter, explicit references and a non-spoiling writability
marker to the existing opening Library. She never gates basic reading or page rewards, and her tools
do not convert prose into conditions or a signature solution.

Because `foundPages` stores no world/site provenance, first successful page reads now require one
stable `RecoveredPageRecord` containing page ID, discovery order and optional exact outcome, History
record and site IDs. Legacy records preserve order with honest unknown provenance. Catalogue links
come only from explicit author/subject/site/teaching/recovery fields; full-text search finds recovered
words but creates no relationship. Writability uses the actual current-hand reachability solver while
revealing no pressure, threshold or missing word. Exact schema and disclosure gates are in
`library-lys-catalogue-current.md`.

## 151. Combat trees use true fan-and-fork graphs, not ladders with crossover decoration

The earlier three-lane/eight-rank correction still left most purchases in three straight vertical
ladders and therefore did not satisfy the requirement for game-like combat trees. Its Asset v0.2
proof is rejected design history and must not be promoted or implemented.

Each 24-node tree now uses five visual depths: three discipline roots, six fundamentals, six
developments, six masteries and three capstones. Every root forks into two meaningful choices;
authored adjacent-discipline edges enable hybrids without making the disciplines interchangeable.
A capstone requires its own root, one owned node at every intermediate depth, five nodes in its
discipline and seven non-capstone ancestors, so it cannot arrive before the eighth route point. Exact
placement, edges, routes, migration and acceptance gates live in
`combat-tree-true-graph-current.md`; `combat-tree-v2-authority.json` is the machine-readable all-tree
contract shared by Asset and Engineering so topology is not manually recopied. Tutorial slices 5–6
are explicitly dead last and cannot displace
this or another queued enabling dependency. The same audit found that Quench alone grants the
unrelated `steady` skill, which clears every status and legacy bleed rather than one selected
emanation affliction. The graph migration replaces it with stable `quench` plus tolerant one-way
cooldown migration. Emanation Strike likewise replaces legacy internal `elemental_strike` with
stable `emanation_strike`; parallel internal/player names are not retained.

## 152. Combat openings freeze what the player could see before contact

The live field has creature awareness and pursuit but no saved fact saying whether combat began as an
ambush. That would leave Slippery, Watchful, Ambush and Unseen without one coherent rules authority.
Every encounter therefore freezes a typed opening from the pre-contact world presentation:
player-visible approach, mutual contact, undisclosed non-apex creature ambush, or an explicitly named
scripted opening. Ordinary creature ambushes grant each living foe one opening action before normal
initiative. Apexes never ambush.

Slippery converts an otherwise valid ordinary ambush to mutual contact on one saved-RNG roll;
Watchful preserves the ambush fact but cancels its foe-only opening actions. Ambush and Unseen read
the same frozen value rather than inventing skill-local definitions. The opening and prevention roll
survive relaunch, and DEBUG may explain the inputs only after contact without leaking hidden traits.
Exact classification and composition rules are in `combat-node-viability-current.md`.

## 153. Every combat node has a semantic glyph; proof codes never become game vocabulary

The corrected combat graph can fit a phone only by using compact node buttons, but `F1`, `P3A` and
similar proof codes are not acceptable player-facing identities. All 72 nodes now have one authored
pictorial referent in `combat-node-glyph-vocabulary-current.md`. Discipline motif, ownership state,
technique marker and capstone frame remain separate layers, so an icon does not have to encode four
facts at once and color never owns meaning.

Asset may refine pixel contours but cannot replace semantic referents with letters, generic swords or
color-only variants. Final proof must test the deliberately confusable node families at actual
interior size in color and grayscale; pairs with the same dominant silhouette are redrawn rather than
rescued by tiny accents.

## 154. Traveller meeting offers are player speech, and the expanded roster has 29 meetings

The prominent recruitment button displays the player's line, as the seven live meetings already
establish. The review corpus nevertheless authored many `offer` strings in the traveller's voice,
creating terminal transitions where a traveller invited themself home and then answered that
invitation. All draft offers now use player voice; `accepted` and `declined` remain traveller replies.
Atlas/schema acceptance reads each transition with speaker labels rather than validating strings in
isolation.

Noll expands the roster to 29 rather than replacing an existing traveller. Their meeting is therefore
the twenty-second missing meeting, not outside a fixed 28-person corpus. The canonical current Noll
copy now lives beside Vance in the early-economy review batch; the identity document preserves the
first draft as explicit history. Atlas counts, corpus acceptance and generated-draft validation use
29 total / 7 live / 22 draft rather than silently omitting Noll.

## 155. Field avoidance is a visible awareness decision, not an encounter-deletion roll

Quiet Step's legacy loadout value resembles a negative encounter chance, but its current game meaning
is deterministic: once per ordinary roaming creature, a movement-only wake becomes one visible alert
turn at non-adjacent range. The player may leave the notice radius or remain and accept pursuit. The
per-creature use is saved and cannot be farmed by stepping away or relaunching. Low Profile and
Shadowed alter readable notice distance; Vanish is the explicit post-contact escape. None changes
spawn rates, hidden creature disclosure, apex behavior or direct contact.

Scent Mask remains the preparation-side extension for chemo-dependent detection. It creates at most
the same one readable disengagement opportunity and does not stack into repeated alert turns with
Quiet Step. Because it is mundane field preparation rather than a Reality-changing item, its current
recipe direction costs world resources and zero refined Essence. Exact material/property and duration
remain playtest values. Taming reads the same awareness authority: masking an animal's only useful
sense cannot simultaneously count as patient visible presence.

## 156. Combat-tree comprehension is persistent UI; tutorial remains dead last

The true combat graph does not ship with or wait for a first-point teaching overlay. Point receipt
uses the ordinary durable balance and Party badge; opening the Combat tab shows a persistent compact
connector key, exact owned/available/blocked states and anchored prerequisite/Learn detail. Optional
help explains the same always-available surface without recording progression or teaching state.

No first-point modal, focus change, tutorial receipt, DEBUG reset or migration field belongs in the
combat-tree checkpoint. A later tutorial may point to the completed graph only after the explicitly
higher-priority playability, correctness, visual, progression and content work. This preserves
Aimee's repeated instruction that tutorials are dead last and prevents instructional polish from
holding up the structural tree correction.

## 157. Writing progresses from Rough charcoal to Brush to Fountain pen

Pencil is retired from the current Penmanship progression. The Binder begins with **Rough
charcoal**, Isolde next teaches the **Brush**, and the **Fountain pen** remains the final writing
tool. Their physical footprints remain crude 4–6 cells, plain 2–3 cells and refined 1 cell, so saved
page geometry and the established spatial progression survive the fiction correction.

Brush is the first liquid-ink hand. It always supports unlimited Ash ink; **Ink Mixing** is a direct
adjacent unlock that cannot be learned before Brush and then adds CMY+Depth colored inks. Fountain
pen supports the same Ash/mixed inks at finer spatial precision but does not itself grant Ink Mixing.
Rough-charcoal marks cannot carry a mixed liquid-ink recipe and must be explicitly rewritten rather
than silently shrunk or reflowed.

The implementation does not retain a misleading live `pen_pencil` identity. New research uses
`pen_brush`; the old ID is one-way migration input, existing `Hand.plain` placements keep their exact
geometry and display Brush, dependent nodes migrate once, and old diary/reward references receive an
explicit alias. `writing-tool-progression-current.md` owns the complete topology and acceptance
matrix.

## 158. World-grade 2 is resolved once at bind and preserved as history

The accepted world-grade-2 renderer receives one immutable game-owned visual receipt when a new
world is successfully bound. It does not infer appearance independently on each render. Legacy
receipt-less worlds remain permanently world-grade 1, so a visual-system upgrade never recolors an
existing saved or anchored world.

Material derives only from resolved Substrate composition, Thermal centre and usable Hydrology;
Smoke is the only v1 atmosphere medium; persisted Flora traits and realized placement own species
forms, coverage, richness and colors; Sun remains an emitter rather than inherent terrain color.
Granite, Smoke, Sun and Bloom are the first scoped authored/open color sources. Ash and undefined
marks are genuinely open and receive a broad deterministic bind-time color rather than default
black or beige. Similar resolved inputs are allowed to remain visually similar; the renderer never
novelty-optimizes against prior worlds.

`world-grade-2-bind-adapter-current.md` owns the exact resolver multipliers, selection order,
formulas, schema provenance, atomicity and acceptance corpus. The complete request, descriptor and
hash are validated before costs or page state change; History and render caches consume the frozen
receipt rather than recomputing it after tuning changes. Its later compatibility correction freezes
scope salts/SplitMix draw order and golden vectors, includes only Flora species actually placed on
non-chasm map tiles in the renderer request, regenerates explicit color from the versioned
InkRecipe, and hashes the receipt with the pack's canonical JSON grammar rather than dictionary
encoding. A Flora reference found only on chasm is not visible growth and therefore cannot produce
a nonempty cast paired with zero coverage.

## 159. Emanant strengthens matching roots instead of deleting their value

The Emanant capstone's Heat and Caustic choices previously reproduced Sparkhand's weak burn and
Tainted Edge's weak poison exactly. That made an earlier purchased root mechanically dead at the end
of its own Craft progression, contrary to the no-dominated-node rule.

Heat Emanant with Sparkhand, or Caustic Emanant with Tainted Edge, now strengthens the matching
application from 1 damage for 2 rounds to 2 damage for 2 rounds rather than applying a duplicate
status. When the chosen emanation and root do not match, both weak afflictions remain distinct under
ordinary stronger-status replacement. Light retains weak dazzle because no earlier root duplicates
it. This is a capstone synergy correction, not a fourth status or another action.

## 160. Shadowed replaces field radius, not Low Profile's whole value

Shadowed's two-tile party detection reduction legitimately replaces Low Profile's smaller one-tile
field reduction; stacking both radius numbers would often hit the adjacency floor and create no
visible distinction. But that left a purchased Low Profile strictly dead once Shadowed was learned.

Low Profile therefore also gives its owner +6 percentage-point evasion during the frozen foe-only
opening actions of an ordinary creature ambush, through the existing authoritative 85% miss cap.
Shadowed does not replace that personal opening benefit. The bonus does not apply to normal rounds,
apexes or scripted openings, so Footwork remains the general evasion root and Watchful remains the
party answer that cancels an ordinary ambush's enemy-only opening order.

## 161. The first Brush cost describes a brush and protects continuation

The reversible implementation value for Isolde's Brush is **150 Essence + 2 Copper + 6 Fibre + 4
Timber**. Copper is the pressure-holding ferrule named by Halloway's diary lead, Fibre is the bristle
bundle, and Timber is the handle. This replaces the live Pencil-era 8 Copper + 10 Timber recipe
rather than cosmetically renaming it.

The 150-Essence weight preserves the intended importance of the largest early page-capacity jump;
the reduced and broadened material bill avoids making a required core tool depend on a large Copper
spike. It remains a playtest value. Isolde-phase fixtures must prove writable/Trading-Post routes
and enough post-purchase Essence for the configured next authored bind; failed runway reduces the
counts before it turns the Brush into a free grant. Crystal is no longer a prerequisite for the
Brush and remains independent vocabulary progression.

## 162. Aimee owns final handmade art; functional proofs do not compete with it

Aimee is the final visual author for characters, buildings/stations/sites, weapons and other
inventory items/resources, sigils/writing marks, and combat-node/technique glyphs. Game Design may
specify semantic reads and collision boundaries. AssetLab may provide plainly labelled functional
placeholders for layout, state, accessibility, stable-ID and conformance tests, but acceptance of
such a proof never approves its pictured art or transfers authorship to the Asset Lead.

Engineering consumes a versioned handmade pack after Aimee supplies or approves it and preserves a
labelled fallback while art is absent. `handmade-art-ownership-current.md` is the current central
boundary; older “Asset owns final pixels/silhouettes/glyphs” language is retired.

## 163. Base separates destinations from persistent campaign utilities

Party is not a village building and no longer occupies a Home destination tile. The ordinary phone
Base keeps one compact persistent bottom row with a neutral **Party** button and a visually primary
blue **Bind & Depart** button. Both are ordinary label-sized 44-point-or-larger controls rather than
giant full-width cards. Settings, Testing and DEBUG remain in a compact utility affordance and never
join the station grid.

The four destination tabs remain Home/Make/Study/Realms. Home now contains Writing Desk,
Storehouse, Firepit/Tavern, Essence Spring and Workshop; its five tiles, tabs, compact status and both
bottom actions fit the ordinary 368×800 frame without routine scrolling.

## 164. First-slice colored ink processes pigment just in time

The first native Scriptorium slice does not require a separate foregone “process Copper into Cyan”
step before preparing a vial. One atomic preparation spends existing CMY+Depth measures, processes
the minimum whole Copper/Ichor/Sulfur/Obsidian units needed to cover the shortfall, retains resulting
excess measures and consumes one Resin. The preview exposes all of those before/after quantities.

This preserves world-resource derivation and persisted base stocks while removing an accounting-only
tap from the core writing flow. It is a reversible placeholder: explicit batch processing should
return only if play demonstrates a meaningful, enjoyable timing or quantity decision.

## 165. Combat routes need a save-isolated observable DEBUG explorer

Combat v2 ships its DEBUG gate with a route explorer that builds temporary legal node sets, compares
A/B builds under identical production fixtures/RNG and exports node-contribution receipts to the bug
reporter. It cannot silently write ownership, points, choices, gear, health, inventory, discoveries
or outcomes; controlled encounters grant no durable reward. Applying a route to a real character, if
offered at all, enters the ordinary previewed Spring respec/purchase transaction behind a second
explicit confirmation.

The explorer recommends no “best” build and assigns no scalar power score. It answers where two
routes behave differently, links each of all 72 nodes to positive/counterfactual fixtures, and keeps
the actual fan-and-fork graph visible. It is testing infrastructure, not tutorial content.

## 166. A local bug-report save must never imply submission

Until a real relay returns a valid receipt, the capture form action says **Save on this phone** and
the result says **Saved on this phone — not submitted**. After saving, **Done** only dismisses and
**Open bug queue** only navigates; neither performs a transport call. Manual export says **Share
saved report…**, while **Submit to triage** is reserved for the configured network action.

This wording is a correctness requirement, not polish: a bare **Save** followed by **Done** led Aimee
to reasonably wonder whether the report had been submitted.

## 167. Authored-text review inventory is a live-plus-draft identity union

The DEBUG atlas cannot derive its rows only from the shipped traveller catalogue. Noll is the
approved additive twenty-ninth designed identity but remains review-only until promotion; omitting
her from the atlas makes that promotion impossible to review honestly. Atlas rows therefore derive
from the union of live catalogue IDs and generated review-corpus IDs, with DEBUG-only display/order
metadata for draft-only identities.

The current evidence is 28 live travellers, 7 live meetings, 21 live missing meetings, 23 review
meetings (the 21, Noll and Auber's revision), 29 union identities and 233 live pages. Those numbers
are milestone assertions, not hard-coded inventory logic. Noll remains absent from release content
and campaign saves until her separate review/promotion checkpoint.

## 168. Combat v2 uses one spatial graph and one graph-derived accessible traversal

The ordinary combat-tree presentation is the true fan-and-fork graph, with visible same-discipline
branches and cross-discipline alternative parents. Large Text and VoiceOver may traverse that same
authority depth by depth when the full graph cannot remain readable, but each entry must retain its
discipline, graph depth, state, role, exact Effect and all alternative prerequisites. That adaptation
does not authorize a return to linear buy-next progression.

AssetLab v0.4 is accepted only as functional layout/accessibility evidence. Its temporary marks are
not final glyph art, and it is not mechanics or native-integration authority; Aimee retains final
combat-node glyph ownership. Native consumers derive topology from the versioned combat-v2 authority
and generated Effect copy.

## 169. Apex adjacency is safe; occupied-tile entry starts combat

Standing beside an apex never aggros it. Combat begins only when the player deliberately attempts to
move onto the apex's occupied tile. The apex remains stationary, ordinary fog/discovery rules still
apply, and adjacency is the player's final safe position for inspection, preparation or retreat.

Auto-pathing may travel beside a disclosed apex but may not silently route through its occupied tile.
A direct one-step move/tap onto the disclosed apex is itself the commitment and begins combat; a
longer path stops adjacent and requires that final explicit step. This supersedes the older
“stepping adjacent starts it” prose without adding a confirmation modal.

## 170. Field contact is typed; stationary does not mean adjacency-triggered

Encounter contact is defined by threat kind rather than one generic stationary-threat shortcut.
Ordinary roaming creatures may notice and pursue from range, and adjacency immediately wakes them,
but combat still begins only when party and creature occupy the same tile. Apexes ignore proximity
and begin combat only on deliberate occupied-tile entry. Active-defence flora is rooted and begins
combat when its tile is entered; adjacency and Look are safe. Authored guardians must declare their
own visible warning/trigger rule rather than inheriting one of these accidentally.

Look never advances awareness or invokes a trigger. Long auto-paths stop before disclosed apex and
active-flora tiles so the final hazardous entry remains an explicit movement action.
## 171. Research prices use continuation roles, not one global curve

**Date:** 11 August 2026
**Status:** Current design rule; no additional live price changes authorized

The research economy has three distinct cost roles: core expressive unlocks, optional capability
unlocks, and long-horizon capacity. Penmanship is the immediate outlier because expensive early
purchases gate the central writing loop. Hold's steep optional tail and the incremental
Instrument/Lens branches are not automatically reduced with it. Any Essence purchase should be able
to show an advisory recent-median authored-bind runway, but that warning never blocks the purchase.
See `research-economy-shape-audit-current.md` and the still-open DRQ-170 price review.

## 172. Dynamic authority replaces mirrors, not authorship

**Date:** 11 August 2026

Deliberate prices, classifications, prose, topology and visual judgment remain authored in one
appropriate authority. Counts, unions, summaries, eligible sets and adapters derived from those
facts must not be maintained separately. Versioned generated receipts are valid only with source
identity and a normal freshness check; historical snapshots remain dated history. The first live
audit found the native combat-v2 generated catalogue stale against schema-2 design authority, so
generator repair and regeneration are a gate before native combat-v2 promotion. See
`static-manual-authority-audit-current.md`.

## 173. Prove trait-driven apex challenge before adding boss phases

**Date:** 11 August 2026

Recommended additive scaling is the first apex challenge slice: for an equal-level five-person
party it reaches a +2 level floor, 2.4× HP, 1.4× offence and three interleaved lighter action slots.
It is ready to test, not accepted as balanced. Target 3–6 rounds and 1–3 meaningful tactical or
resource decisions without one-hit-before-action failures or a solved-pattern HP wall. Tune action
tempo, then durability, then offence. Add no bespoke apex phase system unless several distinct
trait-driven fixtures meet duration targets but still fail to produce decisions.

## 174. Look reports entry consequences without becoming flora analysis

**Date:** 11 August 2026

Adjacent Look is read-only and describes the contemplated entry. Active flora copy says **Entering
will start an encounter**; it never says approaching or adjacency triggers it. Physical growth may
name visible barbs and warn of entry damage; chemical growth warns of a lingering entry hazard
without disclosing an unearned exact status. Slow ground states total turns and exact extra turns
from the frozen run. Until a real flora-knowledge receipt exists, Look must not expose exact defence,
tissue, metabolism, damage/status magnitude or harvest quality. Sela may later deepen recognition
through an explicit capability rather than a universal inspection leak.

## 175. Sela's flora recognition belongs to the Wayfarer's Table

**Date:** 11 August 2026

Building the durable Wayfarer's Table makes Sela's shared field guide available to every expedition;
Sela need not remain Home or occupy the active party. Look always gives disclosure-neutral entry
consequences. With the Table, it additionally derives the exact visible flora name, practical defence
family and ordinary yield kind from the live Flora and `FloraRules.yield`. It never reveals numeric
traits, harm magnitude, harvest amount, grade, hidden flora or remote POIs. This completes the
settled “flora identified on sight” contribution without another Boolean or parallel lookup table.

## 176. Traveller stations need useful identity, not symmetric feature counts

**Date:** 11 August 2026

The original six station contributions were re-audited against native rules. Mara's instruments,
Edren's site catalogue/yield interpretation, Halloway's physical making, Isolde's current/queued
writing progression and Tovin's realm portfolio each supply a real first slice. Sela's missing flora
recognition is the only identified promised gap and is owned by Decision175. Do not invent parallel
perks or duplicate systems merely to make all six station descriptions equally long; add later depth
only when play exposes a distinct decision.

## 177. Nessa—not DEBUG—owns Apothecary access

**Date:** 11 August 2026

The live Apothecary is unreachable because it is locked at start yet lacks both `builtBy` and a build
cost. Nessa's authored prose review is not a mechanical feature flag. The station is a normal
Nessa-owned persistent build site using the reversible current bundle 85 Essence, 16 Clay, 6 Quartz
and 12 Reagent; tier 0 immediately exposes dependency-safe preparations. Existing built saves remain
exact, and already-recruited Nessa saves gain the build opportunity rather than a free station.
Ordinary CMY+Depth writing ink remains at Isolde's Scriptorium.

## 178. Apothecary construction teaches one useful vocabulary, not an empty room

**Date:** 11 August 2026

Building the Apothecary permanently teaches Lesser Salve but grants no prepared item or ingredients.
Its visible shortfall introduces property-qualified world resources plus named reagents; the rest of
the catalogue remains permanently inferred from suggestive partial stock. An unlocked/migrated
Apothecary must reconcile to at least this one known recipe. At the same contained checkpoint, use
the settled continuation profile: ordinary preparations cost zero Essence, Stillwater costs six,
and Waystone costs twelve plus one mote. This is embedded first-use clarity, not tutorial content.

## 179. Oda's first conduit is restored once; later conduits consume cores

**Date:** 11 August 2026

Building the Channelworks itself restores Oda's authored recipe-version-0 Heat Conduit and records a
durable one-time receipt. An unlocked legacy save adopts an exact existing authored fixture or grants
one if absent; later item movement, sale, recycling or loss never causes another grant. The station
screen confirms that restoration and labels the separate Heat-core transaction **Build another
conduit**, with Auber's Distillery named as the repeatable-core source. Item location is never used as
the one-time entitlement receipt.

## 180. One full-match traveller appears; pages break ties only among contemporaries

**Date:** 11 August 2026

The first-world Mara+Bryn playtest result is rejected even though both signatures happened to match.
A newly bound world places at most one unfound traveller. Blind later people require the rolling
authored-order floor
`max(3, order - blindDiscoveryWindow)`, with DEBUG Recommended window 3, in
`traveller-world-pacing-current.md`, unless the Library already contains one exact location clue for
that person. A same-day hard-spine proposal was rejected because multiple recovered clues must remain
meaningful, and an explicit Seek selector was rejected as too leading. Instead, every candidate must
fully match. Selection first chooses the earliest represented authored `storyArrivalBand`; only
inside that band does `recoveredClues + 2×causallyAuthoredKnownMatches` break ties, followed by order
and stable ID. Evidence coefficients are DEBUG-tunable, bands are not. No volume of later pages can
beat a simultaneous earlier-band match, but a later person may still appear when no earlier-band
candidate matches. There is no second random draw and no world can collapse several recruitment
beats into a crowd.

## 181. Library indexes one page set by author and subject

**Date:** 11 August 2026

The Library's Diaries view groups recovered pages **written by** each author; People groups recovered
location/relationship evidence **about** each known person. A page may be reachable through both
routes but remains one stable recovered object and never doubles the global count. Counts always
state their basis—pages written versus clues about them—and unknown legacy page IDs remain visible
as Older records rather than disappearing. The native correction is integrated; phone acceptance is
still outstanding and is tracked dynamically rather than leaving the current document as a stale
implementation candidate.

## 182. Noll may enter playtesting without pretending provisional prose is final

**Date:** 11 August 2026

Under Aimee's standing permission for reversible placeholders that unblock progress, Game Design
approves Noll/`noll`, they/them, Salvager, authored order 2/story-arrival band 0, the two-condition
opening signature, Recycler ownership and the 15-Essence/no-resource build cost for native
playtesting. Existing stable-ID meeting and six-page diary units may ship as **Provisional** in the
DEBUG Atlas; later line-level approval preserves those IDs and cannot revoke earned recruitment or
station state. The Field Separation Kit remains review-only and is neither taught nor exposed. This
separates the game-blocking Recycler owner from final-copy and optional-reward review rather than
silently treating every draft as settled.

## 183. Longer traveller books do not buy more clue-lottery weight

**Date:** 11 August 2026

The accepted five-to-ten-plus-page traveller books may take longer to complete, but their larger page
count must not make their owners proportionally more common. Ordinary diary selection first chooses
a normalized discovery bucket—location pages by `about` person, other pages by diary author—then one
eligible page within it using the existing world-context preference. The exact one-at-a-time patience
nominee still overrides when due. Overall writing/diary rates, prose and eligibility do not change.
This removes an accidental late-cast frequency bias while preserving longer books as more varied,
longer collections.

## 184. Traveller arrival scales linearly from chance to authored certainty

**Date:** 11 August 2026

After the one-person story-band selector chooses a complete signature match, arrival chance is
`25% + 75% × causallyAuthoredConditionFraction`, plus 25 percentage points per saved prior near miss,
capped at 100%. No authored requirements therefore yield 25%, half yield 62.5%, and all authored
requirements guarantee arrival. Failure places no substitute and increments only that traveller's
receipt; the third selected full match is guaranteed. Arrival causality counts every condition the
page actually made true, whether or not its clue was recovered; recovered knowledge remains the
separate same-band selection input. Multiplicative per-condition failure is rejected because it
would make long late signatures nearly impossible after an already-rare full match.

The same-seed counterfactual must rerun ordinary unwritten-target filling after authored pressure is
removed. Merely retaining the original world's random sigils leaves newly silent targets blank and
therefore falsely credits the authored page for conditions the same seed could still have supplied.

## 185. Combat-v2 naming and starting ownership may enter reversible playtesting

**Date:** 11 August 2026

To unblock the combat-v2 consumer and action-palette queue without silently claiming Aimee's final
approval, Game Design promotes two existing recommendations as reversible playtest placeholders.
The Binder's signature damage technique remains **Unbind**; ordinary party retreat becomes
**Withdraw**; Vanish modifies one confirmed Withdraw; legacy `rout` is decode-only. Starting
identity ownership is Binder Unbind/Sight and Quill Mend/Read, with Ashe's Ground, exact graph-node
techniques and exact item actions remaining distinct. Every conscious actor retains ordinary Attack,
eligible Items and Withdraw. Generated and other named people do not inherit Binder/Quill identity.
A Quill-free party deliberately has no renewable Mend and must see that fact plus carried healing
uses before departure. Aimee's later naming/role review remains open, but the obsolete universal
four-technique grant must not survive merely to avoid testing the real party distinction.

## 186. Essence refining belongs to the Spring and rewards practice rather than hoarding

**Date:** 11 August 2026

Game Design promotes the linked Essence Spring recommendations as a reversible playtest profile.
All player-facing Raw refinement moves from Workshop to the Spring. Fresh saves receive free exact
selected/all control at the baseline 2:1 rate; basic transaction control is not a research reward.
**Second pass** costs 80 Essence + 10 Quartz and requires 50 lifetime Raw actually refined, then
changes future conversions to 3:1. **Continuous settling** follows Second pass at Spring tier 1 for
120 Essence + 12 Quartz + 8 Pulp and processes only newly retained Raw once per exact expedition
outcome. **Deepen the Spring** remains a parallel return-dividend branch and no longer depends on
unrelated shelving. Practice increments only on committed conversions, old saves do not infer
fictional history, and past conversions are never recomputed. Costs and the 50-Raw gate remain
DEBUG-tunable for Aimee's later economy review; baseline Essence availability must remain viable
without these upgrades.

## 187. Penmanship's first usable hand is an early commitment, not a late capstone

**Date:** 11 August 2026

Game Design promotes the complete Penmanship price table in
`penmanship-economy-runway-review-current.md` as reversible playtest tuning. The Scriptorium remains
60 Essence. Brush is 45; stable table 70; Ink Mixing 40; Compound Assembly 55; Chaining 90; ruling
frame 140; Fountain pen 220, with the exact world-resource bundles in that document. This preserves
Rough charcoal → Brush → Fountain pen and the settled fan/fork topology while rejecting the legacy
150-Essence first hand that would consume 4.5 average gross worlds before bind spending. Every
purchase previews post-purchase Essence and recent-median ordinary authored binds remaining, with a
restrained **Low writing runway** advisory below two; it never blocks a deliberate purchase or uses
the emergency 10-Essence anti-lock minimum as a healthy baseline. Aimee's final price review remains
open and all prices may be tuned without changing stable IDs, topology or page geometry.

## 188. Hydrology source choice owns water form; do not add a duplicate qualifier

**Date:** 11 August 2026

The inert Phase palette remains hidden and its Frozen/Solid/Liquid/Vaporous values remain legacy
decode input only. Game Design rejects the proposed universal Water Form replacement for the first
writable grammar because the live source vocabulary already makes the four meaningful choices:
standing Pond/Lake/Marsh/Sea, flowing River/Geyser, frozen Ice/Snow/Glacier and airborne Rain/Mist.
A redirecting qualifier would mostly create strained combinations such as Standing Rain while
adding saved schema, page cost, migration and History explanation for a choice the source already
owns. If play later exposes a genuine need to transform one source independently of its identity,
design an explicit compound/transformation with honest Stability consequences rather than a free
modifier.

## 189. Cut Traveller's Token and the separate Quirk/reroll layer

**Date:** 11 August 2026

Traveller's Token is removed from current design. Complete-signature arrival now has a deterministic
story-band selector plus authored-confidence roll; biasing an incomplete signature would falsify
clues, while multiplying evidence would sell back deduction the player already earned. Scent Mask
is independently retained because play exposed a visible animal-avoidance need, not to preserve an
item count. The obsolete separately rolled Quirk catalogue and veto/reroll affordance are also
retired with the old Terrain/Biome/Bounty/Quirk page taxonomy. Paired opportunity/consequence remains
a system-wide design principle expressed through pressure resolution, greed, Danger runes and
contradictions. Legacy compound/item IDs may remain decode-only; no current UI or crafting source
promises either removed system.

## 190. Ordinary compound hostility must use one causal model

**Date:** 11 August 2026

The old yield and creature-weight tables are dead compatibility mirrors beside pressure-driven
generation and may retire after tolerant decode fixtures. Flat `enemyTierDelta` is still live on
Ashen, Rich Ore, Teeming Life, Dim Sky, Gilded Veins and Mote Vein: every +1 adds two base map
creatures before vitality, area and other multipliers, while Mote Vein adds four. Game Design
recommends retiring all six together rather than removing only the two once called Quirks, but this
is not authorized as a silent cleanup because it can materially reduce population. Engineering must
first run the same-seed comparison in `compound-hostility-fossil-audit-current.md`. If difficulty
needs replacement tuning, use vitality, party encounter scaling, greed/world level, typed Danger or
local guardian rules—the authority that actually explains the consequence. Danger rune tier and
its disclosed Stability bargain are out of scope and remain intact.

## 191. Four exact-combatant afflictions share one authority

**Date:** 11 August 2026

Combat's complete current affliction set is Burn, Poison, Dazzle and Bleed. Freeze and Shock remain
cut; Ground is Ashe's beneficial protection, not a fifth status. One typed definition per stable ID
owns tuning defaults, presentation, cure membership, Quench eligibility, Stonebark eligibility and
encounter persistence, while explicit producers still decide what they apply. Same-kind
reapplication keeps greater damage and remaining duration; different kinds coexist. Every instance
belongs to one exact combatant. This closes a live defect where the single legacy companion Bleed
counter damages every living companion, plus Broad Antidote's hidden array-first removal. Clearing
removes Bleed+Poison, Quenching removes Burn+Dazzle, Broad Antidote selects exactly one when several
exist, and Quench deliberately excludes Bleed. Legacy fields remain decode-only and migrate
tolerantly; new saves encode the canonical collection.

## 192. Expedition loot receipts preserve stable and exact identity

**Date:** 11 August 2026

The return recap's current name/SF-symbol/count rows are not an adequate immutable receipt. They
discard stable resource/item IDs and unique item profiles, can collide on identical fallback labels,
cannot consume the shared accepted resource/item graphics and cannot support truthful anchored
detail. The consolidated return constructor must freeze typed resource, homogeneous stackable,
unique-instance and legacy-fallback lines. Stable IDs resolve shared pictorial assets; frozen labels
remain historical fallbacks; exact property-bearing objects never aggregate merely by catalogue ID.
Recovered and Lost use the settled six-across trays on ordinary phones, with quantity badges and an
edge-clamped detail popup driven solely by the receipt rather than mutable Storehouse state. Old
string-only receipts remain readable as explicitly legacy lines.

## 193. Failure fraction is independent of resource variety

**Date:** 11 August 2026

Bulk world resources remain automatically retained/lost, but the current per-resource flooring is a
correctness defect: at 50%, four different one-unit resources return zero while four units of one
resource return two. The automatic retained total becomes `floor(total acquired resource units ×
fraction)`, allocated by largest fractional remainder and tied by a stable
`ExpeditionOutcomeID + ResourceID` hash. This preserves the configured total and approximates the
original mix without a player decision or reroll. Bulk has no minimum-one mercy; the approved
discrete one-object mercy remains separate. Raw Essence and Motes participate normally, and adding
another resource kind cannot change the total number retained.

## 194. Noll promotion is unblocked; correct the swapped meeting identities with it

**Date:** 11 August 2026

Decision 182 already approved Noll's reversible native identity, order-2/band-0 signature, Recycler
ownership, provisional meeting/diary copy and 15-Essence build. Current roadmap language still
claiming Aimee must approve Noll first is stale; the live gap is implementation, not design review.
After the active combat checkpoint, promote Noll as the twenty-ninth live traveller, add the distinct
player-facing Recycler route over its existing rules/state, keep the Field Separation Kit
unavailable, and preserve old dormant Recycler state without granting Noll. Halloway is already
order 3 and needs no recruitment rewrite. The same catalogue migration corrects six live stable
meeting IDs whose Sela/Halloway owner prefixes are swapped; DEBUG review decisions move only through
exact text-hash aliases, so one person's review can never attach to the other's exchange.

## 195. Noll enters the shared graph through Precision and Protection

**Date:** 11 August 2026

The earlier reversible “Guard + Control” combat lean did not name real branches in the accepted
nine-branch graph. Noll instead arrives with one authored point in **Precision** and one in
**Protection**. Precision expresses reading joins, weaknesses and exact separation; Protection
expresses choosing what remains whole and where a cost is borne. This gives Noll a coherent starting
direction without inventing aliases, a Salvager class or private techniques. The values remain
playtest-tunable, but their branch identity is current.

## 196. Keep the opening 10/15/30 station costs for measured comparison

**Date:** 11 August 2026

Fresh-save arithmetic does not justify pre-emptively changing Trading Post 10, Recycler 15 or
Blacksmith 30 Essence. At a representative 14-Essence authored bind, two Lean-profile returns still
leave 43 Essence after the first two stations; Recommended returns leave 53. Three immediate Lean
returns plus all three builds leave 27, just below a two-bind comfort target, making Blacksmith the
measurement point rather than proving the whole profile wrong. Keep these reversible values while
every station preview reports spendable Essence after construction, recent-median nonblank binds
remaining, **Low writing runway** below two and a stronger factual warning below one. Never rely on
Blacksmith's random Ore/Fibre delay as protection, and never raise Raw Essence drops merely to
subsidize an overpriced station.

## 197. The Base board is implemented; hidden Party placement is compatibility only

**Date:** 11 August 2026

The native Base already uses authored `homeSection` plus unique `sectionOrder`, four tabbed grids,
foundation/built tile states and persistent Party/Bind & Depart utilities. Legacy duplicated
`sortOrder` no longer owns presentation. A hidden `party` station definition remains at Home order 2
in the compatibility map, so visible Firepit/Essence Spring/Workshop encode 3/4/5 while still
appearing as the third/fourth/fifth destinations; contiguous integers are not a UI requirement.
Party is filtered from destinations and appears exactly once below the board. Noll's Recycler now
integrates at Make order 1 without reopening layout; later Menagerie/Deep Works use their reserved
Realms positions and remain absent until legitimately known.

## 198. Keep the Armoury's existing three-way offset profile for comparable playtest

**Date:** 11 August 2026

The implemented Rigid/Balanced/Insulated physical offsets of `0/−0.5/−1.0` are coherent enough to
be the first native evidence profile. Fractional protection is summed across the loadout and rounded
once, while Heat protection already reads exact selected-sample insulation through a shared capped
rule. Adding fixed resistance bonuses, armour subtypes or another slot would duplicate existing
material identity. The values remain reversible after same-actor, same-foe Tier-3/4 substitutions;
construction tier, stable profile identity and provenance do not become tuning knobs.

## 199. The four coating identities are settled and ordinary coatings cost no Essence

**Date:** 11 August 2026

Keep **Venom → Poison**, **Firebrand → Burn**, **Briar Oil → Bleed** and **Flashsalt → Dazzle** as
the first-slice names and effects. Their distinct recipes are Toxin + Fiber + reactive stock,
Reagent + Sulfur + reactive stock, Fiber + Resin + flexible stock, and Reagent + Mercury + lustrous
stock respectively. All four cost zero refined Essence because named/property-qualified world
resources already price ordinary preparation. The live Venom key `fibre` is invalid against the
catalogue's `fiber` ID and is a correctness bug; do not add a duplicate spelling. Briar Oil stops
spending Toxin so it no longer reads as a second Venom. Freeze and Shock remain absent.

## 200. Barbed Edge owns severe Bleed, not a duplicate legacy clock

**Date:** 11 August 2026

**Barbed Edge** is the final player-facing name; `rimed_edge` remains internal compatibility only.
Because every Rend weapon already applies ordinary Bleed, “Bleed without a coating” was not a unique
apex rule. Native also wrote Barbed Bleed and Rend Bleed into separate stores, causing an accidental
double tick. Replace both with one canonical max-refresh Bleed at **3 damage for 3 rounds**. Ordinary
Rend/Briar Oil remain 2/3; Bloodletter alone owns non-expiring Bleed. Briar Oil is ineligible on a
weapon that already applies stronger Bleed, while different coating afflictions may coexist.

## 201. Oda's schematic expands Channelworks reach; it does not gate her starter

**Date:** 11 August 2026

The designed `emanation_housing` diary teaching opens the later Contact and Projection housing
recipes. Oda's Channelworks construction still restores her one authored Heat Conduit, and the basic
repeatable Conduit route remains independent of diary luck. Learning the schematic grants no weapon,
core or output. Implement it as generic validated, saved schematic knowledge rather than station
state or an Oda-only Boolean. Talin's missing armour-threshold gambit may promote separately; Noll's
Field Separation Kit remains explicitly held and cannot block either implementation.

## 202. Ashe's Spent Emanation Housing is live content, not a deferred placeholder

**Date:** 11 August 2026

The exact site definition and Ashe's `ashe_site_spent_housing` page both exist in the live catalogue.
Keep its thermal/volatile/still-air eligibility, two-turn search, 3 Raw Essence + 2 Ore recovery and
absence of item/schematic rewards as the reversible first profile. Its authored −4 stability value
remains uncharged under the wider settled site-stability hold. The remaining work is a named
eligibility/search/yield/anchored-revisit fixture and playtest tuning, not content promotion.

## 203. A tamed animal's saved defence branch selects its combat technique

**Date:** 11 August 2026

Animal companions retain no human combat tree. Their instinctive attack still derives from the exact
saved armament/body, while the saved singular defence branch selects one technique: armour →
Interpose, speed → Harrier, crypsis → Slip Away, and aposematism → Warning Display. A specimen with
no defence branch uses armament-based Commit. Cut the earlier “high sensory investment” and
“conspicuousness” selectors: senses are a normalized allocation and conspicuousness is not a stored
trait, so both would require hidden invented scores. Freeze the derived kit/version when taming
completes; later threshold or catalogue changes never silently rebuild an existing companion.
Animals use shared base/Research/Constellation gambit slots but receive no personal Wit term: they
have no human stats, and surrogate Wit would be a concealed obedience system.
Freeze the specimen's level-1 derived combat stats and encounter level at taming; subsequent levels
apply the existing foe scaling curve only to max HP, attack and armour. Initiative, evasion,
retaliation, damage kind, reach, delivery and emanation remain its trait identity.

## 204. Tavern seats rotate by least recent outcome, never by time or screen opening

**Date:** 11 August 2026

The v1 Tavern has three persisted seats containing only met, unrecruited generated people. On each
new accepted expedition outcome, select never/least-recently seated people first, then first-met
order and stable ID. This produces fair deterministic rotation, keeps three-or-fewer people visible
and makes repeated OutcomeID processing inert. Recruiting repairs the vacancy without pretending a
new expedition occurred. Named diary travellers never enter this pool. When a world passes its
generated-person appearance roll, use a reversible 60% preference for recurrence if anyone is
eligible, but retain one total generated-person encounter per world; recurrence cannot create a
second encounter.

## 205. Source-to-Focus is a writing-domain migration, not a global word replacement

**Date:** 11 August 2026

The current writing vocabulary is Subject, Focus, Modifier, Compound and Chain. Rename only the old
writing-domain pressure-source and precomposed-symbol types/data; stable raw IDs and resolved
mechanics do not change. Keep legitimate `source` language for material provenance, events,
transactions, migration origins and physical sources, and keep “symbol” where it means an icon or
ordinary notation. Old roots are versioned decode-only fallback; new bundled data and encoded saves
write only Focus/Compound authority. Seeded book→reading→price→world equivalence is the gate, not a
blind repository-wide text scan.

## 206. Group motion may break a movement tie but never create a move

**Date:** 11 August 2026

Keep the small same-species motion texture without adding flock simulation. Only after flee, hunt or
party-pursuit logic has produced equally good neighbouring tiles may grouping choose among them.
Unarmed animals prefer a nearest same-species peer within two tiles; armed animals avoid ending
adjacent and prefer more separation. Primary movement score, target, awareness and move count always
win, and no second path search or saved herd identity exists. A DEBUG on/off dense-world profile may
disable this texture if even the local tie-break is visibly slow; predation remains independent.

## 207. Fix expedition-loss arithmetic before adding recovery-choice UI

**Date:** 11 August 2026

The Tier-A return/loss checkpoint uses one typed outcome receipt and one total-unit retention budget.
For `N` exposed units at positive fraction `f`, retain `ceil(N × f)` units, clamped to the pool; zero
fraction retains zero. Allocate bulk resources proportionally by largest remainder with stable
outcome-ID tie breaks, and apply the same total budget to discrete exposed quantities while
preserving carried-property protection exactly. This replaces per-kind/per-stack flooring and the
over-generous idea of retaining one unit from every category. Keep deterministic automatic item
selection for this correctness checkpoint. The proposed **What did you hold onto?** screen remains
a later reversible agency comparison after Aimee has accepted one trustworthy automatic receipt.

## 208. Affliction duration counts consequences, and Stonebark blocks meaningful change

**Date:** 11 August 2026

Canonical affliction duration is ticks remaining: a three-round damaging affliction produces exactly
three future round-boundary ticks, never an immediate application tick, and Dazzle remains active for
the same three completed boundaries. One persisted round-advance receipt prevents relaunch skips or
duplicates. Resolve same-kind max refresh before checking Stonebark; consume its one guard only when
the application would add, strengthen or extend an affliction, not for a strictly weaker no-op.
Attack damage still lands. A successful coating strike is spent even when it defeats the target, but
no new affliction or guard consumption is recorded on a non-standing target.

## 209. Canonical afflictions preserve actor source; Flense no longer owns legacy Bleed

**Date:** 11 August 2026

Every canonical affliction instance keeps target, tick-damage source actor when known, provenance,
damage, ticks and application receipt. Same-kind max refresh changes tick ownership only when a
strictly higher-damage payload wins; duration-only or equal-damage refreshes do not steal credit.
Flense now applies covering-scaled canonical Bleed rather than preserving a parallel legacy wound.
Virulence adds two authored ticks before Constitution halves the final duration. Blight's copied
Poison retains the original actor as source, is marked copied, passes through the second target's
Stonebark and Constitution and cannot trigger Blight/Virulence again. Corrode is limited by an exact
actor + target + round receipt; source-unknown migrated Poison never invents its benefit.

## 210. Quicken grants two actions now and one skipped turn later

**Date:** 11 August 2026

Quicken cannot spend an action merely to grant one replacement action and then skip the next turn;
that is usually worse than never buying it. At the start of a fresh scheduled personal turn it is
zero-turn and replaces the ordinary one-action credit with exactly two normal-cost actions, then
adds one skipped scheduled-turn debt. Blur is the once-per-encounter debt-free version of the same
two-credit expansion. Expanded credits cannot select Quicken, Blur, Fall Back or another zero-turn
setup, and the shared receipt prevents chaining. Ambush uses a separate opening opportunity and may
precede either expansion; First Strike may spend the first expanded credit when still eligible.
Remaining credits and Quicken debt persist exactly across relaunch.

## 211. Interpose replaces a target; Cover splits one landed hit

**Date:** 11 August 2026

For a single-target direct hit, Guardian/rank rules first establish a legal target. The oldest valid
Interpose activation then replaces that target completely; the interposer's avoidance and mitigation
apply, the original target's do not, and Cover cannot also redirect the hit. Multiple Interposes form
an activation-order queue rather than overwriting each other. Without Interpose, Cover may split 30%
of a landed back-rank ally's already-mitigated final damage to one conscious front owner; do not
mitigate that share twice. Sidestep is consumed before passive Ghost on the actor actually receiving
the hit. Area, multi-target, environmental and status damage consume none of these single-hit
redirections/guaranteed misses.

## 212. Launch progress reports real work and healthy launches are read-only

**Date:** 11 August 2026

The production campaign-slot path, not only the obsolete direct-store path, must show a functional
loading bar. Its phases name real legacy adoption, campaign inspection, writer acquisition, save
load, catalogue reconciliation and any necessary commit; do not animate a timer that merely guesses
how long launch may take. Late or reordered callbacks cannot move the bar backwards or overwrite a
new launch generation. A normalized campaign performs no diagnostics-only rewrite on opening.
Genuine reconciliation still commits atomically once. DEBUG timing separates shelf adoption and
inspection from campaign load, reconciliation and persistence so a loading surface never becomes a
substitute for fixing avoidable delay.

## 213. Existing tutorials overlay pages; transient page tools end outside the page

**Date:** 11 August 2026

Every existing in-game tutorial prompt is a safe-area-constrained hovering overlay. It may cover or
dim ordinary content, but it never participates in layout, changes map/page size, pushes controls or
alters scroll geometry. This is a correctness fix for existing prompts, not permission to move new
tutorial content ahead of its dead-last priority.

Connect and Disconnect are transient Writing Desk page tools. Any off-page interaction,
tab/navigation/dismissal or page change ends the mode and clears its pending first endpoint and
error. Returning always starts in ordinary selection mode. The same interaction may still perform
its intentional navigation or palette action; cancellation must not become a blanket tap-blocking
layer.

## 214. Combat-v2 bonuses enter one shared direct-damage pipeline exactly once

**Date:** 11 August 2026

Extend the live committed-strike `CombatDamageRules` path for v2 rather than wrapping node arithmetic
around it in each action. Roll base power, sum legal pre-matchup integer node/action bonuses once,
apply covering and reach/rank and round, apply a successful Steady Hand 1.5× critical and round,
resolve one armour-ignore rule, subtract armour, apply minimum damage, commit HP, then enqueue
non-recursive consequences. Receipt `rawDamage` is the post-matchup/post-critical, pre-armour
integer. Preview uses the same pure path with roll bounds and a disclosed critical branch, never a
promised roll. Component values are diagnostic provenance inside the total, not extra additions;
this prevents the dormant derived-stat output and the strike consumer from double-counting Heavy
Hand, Keen Eye or Momentum.

## 215. Secondary kills keep source credit without opening recursive trigger chains

**Date:** 11 August 2026

Separate credited damage source from an active-action defeat. Second Wind, Rally and Cascade trigger
once per foe defeated while resolving the actor's current action and its finite consequence queue,
including one foe killed by that action's non-recursive Flurry or Conduction damage. Their bounded
healing/initiative rewards cannot enqueue another hit. Later Burn, Poison or Bleed ticks retain their
actor source for logs and telemetry but do not retroactively fire action-timed defeat rewards.
Killing Stroke remains direct-hit-only, one foe emits one defeat receipt, Second Wind cannot revive
a passed-out owner and Rally requires its owner still conscious. This preserves attribution for
attrition builds without turning delayed ticks or carried damage into an unbounded proc engine.

## 216. Brace protects one landed hostile action slot and is not a round-shaped inert flag

**Date:** 11 August 2026

Native currently stores and ticks Brace without reading it in damage resolution. One action now
arms a saved receipt for the next hostile action slot that lands direct damage on the owner. Every
direct event from that one slot is reduced 35%, then the receipt is consumed once at slot end. A
miss, another target, status tick or environmental boundary neither benefits nor consumes it.
Matching Ward/insulation applies before legal armour; Brace and low-HP Endurance combine
multiplicatively against the post-armour integer and round down once; Cover splits only the final
already-mitigated hit. Minimum direct damage remains. This makes Brace a predictable general answer
without duplicating Ward's stronger selected-harm duration or allowing a hidden round counter to do
nothing.

## 217. Envenom has three landed-hit charges; its existing clock is not an implementation

**Date:** 11 August 2026

Native sets and ticks `envenomed` but never reads it on a strike. Replace that inert round clock with
three persisted successful-direct-weapon-hit charges for the encounter. Each armed hit applies
canonical strong Poison at 2 damage for 3 authored ticks and then spends one charge; misses,
non-weapon and carried hits spend none. Reactivation resets rather than adds charges. Virulence adds
ticks to the Poison payload, not charges. Envenom consumes no inventory and may coexist with a
prepared non-Poison coating, whose own one-hit receipt remains independent; prepared Venom is
visibly ineligible while the stronger Envenom treatment is armed. The same audit confirms the live
`interposing` clock is also unread: implement Interpose as Decision211's queued one-hit target
replacement, not as another ticking Boolean.

## 218. Sidestep and Ghost each stop one attack, not every attack in a clock window

**Date:** 11 August 2026

Live `evades` never consumes the Sidestep clock and treats Ghost ownership as a miss on every
round-one attack. V2 replaces both with saved one-hit receipts. After target replacement, the actual
receiver consumes Sidestep first; otherwise they consume an unspent Ghost. That one otherwise legal
single-target direct attack misses, lands no affliction and skips the ordinary evasion roll. Area,
multi-target, environment and status harm cannot consume either; Conceal remains target legality.
Already-active legacy encounters retain their frozen rules until they end because their save has no
history capable of reconstructing which repeated legacy miss should have spent the charge. New v2
encounters create one Ghost receipt per owner and arm Sidestep only when its action commits.

## 219. Draw Off belongs to its actor, never implicitly to the Binder

**Date:** 11 August 2026

Live `taunts` remembers only foe and duration, then hard-codes the Binder as target. V2 stores the
targeted foe, exact owning actor, two-round duration and activation sequence. The foe chooses that
actor as primary for every action slot while they remain conscious, disclosed and legal under
reach/rank/Guardian; it overrides random/apex diversity preference but not physical legality. Using
Draw Off ends the actor's Conceal. If temporarily illegal, the foe chooses another legal target and
the round duration still advances. A newer Draw Off on the same foe visibly replaces the previous
owner. Area delivery can still affect additional targets. Existing active legacy encounters retain
their frozen Binder behavior until they end rather than inventing a missing owner during migration.

## 220. Snuff suppresses the foe's next two turns, not the rest of the encounter

**Date:** 11 August 2026

Live `snuffed` state is a set with no expiry, so one use silently removes a foe's emanation for the
entire encounter. V2 stores two remaining scheduled hostile turns for the exact foe. One turn covers
that foe's primary and all follow-up slots and consumes the receipt once after the whole turn, making
apex multi-action delivery neither drain several charges nor change harm type midway through a
turn. Reactivation refreshes to two rather than stacking. Suppression removes new emanation damage
and its affliction payload but not the underlying physical blow, Rend's physical Bleed, or Burn,
Poison and Dazzle already ticking. The receipt is saved across relaunch and discarded on defeat or
encounter end.

## 221. Stagger delays one complete foe turn block and never stacks

**Date:** 11 August 2026

One eligible landed direct Crush hit rolls the saved 30% chance and may arm one receipt for that foe's
next round. After ordinary living-actor order is built, the foe's complete turn block moves exactly
one actor position later; its primary and follow-up slots stay together. Multiple successes refresh
one receipt rather than accumulating positions or rounds. Breaking Blow's first eligible landed hit
per personal turn writes that same receipt automatically and does not also roll. If the foe already
occupies the last block, the receipt visibly has no later opening and is consumed rather than rolling
forward. This keeps Stagger a modest tempo effect instead of a hidden skip-turn engine, especially
against apex multi-action blocks.

## 222. Feint and Untouchable use exact direct-attack receipts

**Date:** 11 August 2026

Feint's +10 evasion arms after its owner's direct attack completes, survives skipped-turn debt and
zero-turn setup, and expires after their next normal-cost action; carried damage cannot arm it and
repeat activation refreshes rather than stacks. Untouchable counts actual direct-attack receivers
after target replacement. At round end, one or more targeted misses and zero landed direct attacks
grant one +5 step, capped at +20; any landed direct attack resets it immediately. Cover,
environmental harm and status ticks neither build nor reset the stack. Character evasion, Footwork,
Feint, Untouchable and eligible Low Profile add once before the existing 85% clamp; guaranteed
Sidestep/Ghost misses resolve first without consuming the ordinary RNG roll.

## 223. Unyielding saves one lethal damage event, not a whole action

**Date:** 11 August 2026

After all target replacement, mitigation and Cover splitting, the first final integer damage event
that would pass out a conscious Unyielding owner consumes one saved encounter receipt and leaves them
at exactly 1 HP. The hit still landed for Brace, Untouchable and on-hit consequences. Direct,
environmental and status damage may spend it, but a later event in the same multi-hit/action queue
can still pass out the 1-HP actor. It never revives somebody already at 0, never refreshes on healing,
round transition or relaunch, and mints again only for a new encounter. Legacy active encounters may
initialize it unspent because the old build had no working consumer that could already have spent it.

## 224. Launch progress may fill, but the splash composition may not move

**Date:** 11 August 2026

The launch screen reserves the final progress-track geometry from the system frame onward. Zero and
nonzero progress render the same mark, title, subtitle, frame and 192×4 track coordinates; only the
track's internal fill width changes. A system `ProgressView` or conditional bar whose intrinsic size
recentres the artwork is invalid even if it reports real phases. Source/layout tests cover ordinary
and Large Text, while exact installed-build handoff evidence remains required before phone acceptance.

## 225. Continue and New Game are equal-sized peer actions

**Date:** 11 August 2026

When both actions are present on the campaign chooser, they use the same actual bordered width and
height, typography, icon allocation, padding and reserved two-line subtitle region. Continue may be
visually emphasized, but its geometry is not privileged. At Accessibility sizes both stack at the
same full width and shared growing height. Equal minimum-height modifiers do not satisfy this rule;
rendered bounds must compare equal with realistic short and long campaign names.

## 226. Ward protects the activation round and the following round

**Date:** 11 August 2026

Ward stores one selected harm and expires before round `activation + 2`: it works immediately for
the remainder of the current global round and throughout the next. Reactivation replaces the harm
and restarts the window rather than stacking. It reduces every matching incoming direct event after
target replacement, but does not reduce an already-carried Burn, Poison, Dazzle or Bleed tick and
does not prevent a matching hit's affliction payload by itself. Manual use requires an explicit
choice; gambits save and log their disclosed rules-owned default. Skips, action expansion and
relaunch never change the saved expiry boundary.

## 227. Combat v2 activates through honest end-to-end node slices

**Date:** 11 August 2026

The first Combat Tree v2 activation proves Heavy Hand and Keen Eye only. Exact stable node IDs enter
through an explicitly labelled DEBUG harness, encounter entry freezes the matching physical
pre-matchup bonus and provenance, and both visible direct-hit preview and fixed-roll commit use that
same saved calculation. Each matching node contributes +2 exactly once and contributes zero to the
wrong damage kind. The first slice covers ordinary attacks plus Overbear for Crush and Pry for
Pierce; Unbind is explicitly nonweapon and receives neither bonus. Relaunch preserves the frozen receipt; changing harness ownership cannot rewrite
an encounter underway. Binder-only exposure is a temporary harness limitation, not node ownership.
Momentum and the remaining initiative, HP, armour, evasion and emanation derivations remain
scaffolded—not active—until their real encounter consumers are connected. This establishes the
required implementation cadence for the remaining tree: a node is not called implemented because
its catalogue, loadout or diagnostic field changed.

## 228. The lower-right opening view is not a broken camera

**Date:** 11 August 2026

Rendered evidence initially looked as though the main world map had been compressed into the
lower-right. Exact runtime facts disproved that diagnosis: the captured world is 18×18, the entry is
at (16,17), the fixed 11×11 clamped-follow viewport correctly begins at (7,7), and all black cells
are unrevealed in-map fog. Tile scale and camera origin are correct; no out-of-map background is
showing. Do not add auto-zoom, reveal-bounds framing or a camera patch. The awkward composition is a
P1 playfeel question produced by a boundary entry and only nineteen initially revealed tiles. Any
future correction belongs to starting placement/reveal or fog presentation and must preserve fixed
spatial scale and explore-to-discover semantics.

## 229. Bind refusal is a rules-owned result and can never fail silently

**Date:** 11 August 2026

The Writing Desk uses one current rules-owned binding evaluation for both button availability and
commit revalidation. A refusal names its exact reason: an expedition already exists; Born Anchored
was requested without the Anchorage; or available Essence is below the exact ordinary-plus-anchor
cost. If state changes between rendering and activation, commit presents the fresh refusal and
changes no page, Essence, seed or world state. Visual-receipt failure remains a separate atomic
precommit error. UI may add a Raw Essence refining hint, but that hint is not eligibility authority.
An enabled-looking control that returns to the same page without either a committed run or an
explicit refusal is always a defect, even when the initiating tap may have come through DEBUG audit
tooling.

The rendered incident that prompted this decision was subsequently traced to that tooling: the
Simulator accessibility driver routed the reported Bind element reference to another target (the
same reference selected the Write tab under physical interaction). The eligible saved campaign was
not rejected by production binding. Decision229 is retained because source still contained a real
silent stale-refusal path, but the incident is not evidence of a P0 world-binding failure.

## 230. Quick Step and Light Frame modify their owner's frozen encounter initiative

**Date:** 11 August 2026

The next Combat v2 consumer checkpoint retains the live Binder/companion initiative baselines of 42
and 40. Quick Step adds +4 and Light Frame +3 to their exact owner; one actor owning both receives
+7 because these are personal effects, while copies on other people never become a party aura. At
encounter creation, each participant freezes baseline, stable-node components, total and resulting
order position. That total—not a display-only derived field—feeds the existing authoritative sorter.
Pre-contact DEBUG comparison may show totals but cannot promise the order of equal totals, whose tie
is resolved by saved encounter RNG. The created encounter shows and persists the actual frozen order.
Foe `strikesFirst`, foe initiative and the existing Crush penalty remain unchanged. Light Touch and
Momentum remain outside this checkpoint until exact equipment initiative is owned by the same path.

## 231. Thick Hide owns one frozen expedition health cap

**Date:** 11 August 2026

Thick Hide adds +6 to its exact owner's maximum and starting HP for a newly created expedition. The
departure receipt freezes each participating person's ordinary maximum, stable-node component, final
maximum and starting current HP; that receipt is the shared authority for world healing, combat
healing, health fractions, passed-out state and presentation throughout the run. It is personal, has
no party aura and cannot be toggled into an active expedition. Legacy adoption preserves saved current
HP, adding the cap never fabricates healing, removal clamps only impossible over-cap HP, and return
home continues to heal implicitly by starting the next expedition full.

## 232. Formation armour freezes ownership but evaluates the live formation

**Date:** 11 August 2026

Iron Skin, Bulwark and Shieldwall enter the single incoming-harm armour calculation. Encounter entry
freezes exact equipment/sturdiness and personal stable-node ownership; current rank and consciousness
remain live encounter facts. Iron Skin gives its owner +2. A conscious Bulwark owner receives +1 and
grants other conscious allies in the same current rank +2 strongest-once. Any conscious front-rank
Shieldwall owner grants every conscious front-rank member +2 once. Those distinct components may
coexist, duplicate auras never multiply, a passed-out owner stops contributing immediately, and a
redirected hit uses only its final receiver's armour. The combined value then follows the existing
armour-ignore/minimum-damage pipeline; Cover never mitigates its split a second time.

## 233. Footwork contributes to one frozen personal miss calculation

**Date:** 11 August 2026

Encounter entry freezes each participant's character evasion and exact personal Footwork +6
percentage-point component. After any target replacement, Sidestep then Ghost guaranteed misses
resolve without RNG; otherwise one saved encounter roll uses character evasion + Footwork + eligible
temporary components, clamped once at 85%. A miss carries no damage or affliction. Footwork has no
party aura and does not apply to party accuracy, area/multi-target actions, status ticks or
environmental harm.

## 234. Insulation reduces only one chosen emanation harm

**Date:** 11 August 2026

Insulation stores one explicit Heat, Caustic or Light choice and reduces matching typed emanation
harm by 35%. It composes multiplicatively with Ward, worn insulation and other continuous harm
multipliers against raw harm, rounding down once before legal armour. It is personal and does not
reduce physical harm or Burn/Poison/Dazzle/Bleed ticks. Cancel spends nothing; missing or unknown
legacy choices never silently become Heat.

## 235. Attunement waits for both promised attack families

**Date:** 11 August 2026

Attunement is not complete until +3 pre-matchup raw damage is consumed exactly once by canonical
Emanation Strike and by a real playable Channelworks combat attack. The existing conduit-fixture
treasure is not such an attack. Ordinary weapons, Emanant payloads, Conduction copies, statuses and
station crafting are excluded. A diagnostic `+3` field alone remains inert scaffolding.

## 236. Immovable expands armour scope without granting armour

**Date:** 11 August 2026

Immovable makes its exact owner's legal armour ignore Pierce's partial bypass and apply against
Heat, Caustic and Light emanation harm. It gives no armour points, does not strengthen already-armoured
Crush/Rend, and does not armour affliction ticks. Ward and Insulation still precede armour; final-target
redirection and ordinary formation armour determine whose scope and points apply.

## 237. Conditional direct-hit bonuses share one pre-hit snapshot without leaking covering

**Date:** 11 August 2026

Follow Through (+3 at target armour >=8), Bracing Stance (+3 when rank has not changed since the
actor's previous completed action), Weak Point (+3 at covering density >=50) and Exploit (+4 when a
qualifying affliction already exists) sum once before matchup in one typed direct-hit snapshot.
Encounter entry counts as held rank; Fall Back makes the following completed attack ineligible, after
which the new rank becomes held. An affliction created by the current hit is too late for Exploit.
Carried/status/environmental consequences inherit none of these bonuses. When target covering remains
unidentified, preview shows Weak Point as a conditional +3 branch rather than exposing whether the
hidden threshold is met; exact preview becomes available only after covering is legitimately known.

## 238. Steady Hand rolls only after a direct attack lands

**Date:** 11 August 2026

Steady Hand gives its owner one 12% saved-RNG critical roll for each landed direct attack. Misses do
not consume the roll. A success multiplies post-matchup/pre-armour damage by 1.5 with one rounding;
carried, copied, splash, status and environmental events are excluded. Preview shows ordinary and
labelled 12% critical branches without advancing RNG or presenting an average as a promise.

## 239. Breaking Blow uses one automatic Stagger per personal-turn window

**Date:** 11 August 2026

Every landed direct Crush hit by a Breaking Blow owner fully ignores armour. The first such hit in a
saved personal-turn window also applies Stagger automatically; later hits in that window keep armour
ignore but do not delay again. Quicken/Blur actions share their scheduled window. A pre-contact
opening attack has one separate window and cannot carry an unused trigger into the first scheduled
turn. Misses, other damage kinds and carried/status events consume nothing; ordinary and automatic
Stagger share the same refresh-not-stack complete-turn-block receipt.

## 240. Killing Stroke's apex +4 uses the same 15% threshold

**Date:** 11 August 2026

After a positive landed direct hit, Killing Stroke checks a surviving target at or below 15% maximum
HP using integer cross-multiplication. A non-apex is defeated; a disclosed apex instead takes one
bounded +4 HP loss with no second attack, mitigation or on-hit payload. Apexes above 15% receive no
bonus. Carried/status/environmental damage cannot invoke it, an already defeated target emits no
second transition, and preview branches honestly when its roll range crosses the threshold.

## 241. Playable ordinary systems precede accessibility and edge-case hardening

**Date:** 11 August 2026

Aimee's play path is the scheduling authority. Work proceeds through blockers, completion of mechanics
already present, coherent ordinary-phone interaction/visual design, and gameplay balance before
accessibility-size variants, rare layouts, animation or other edge hardening. Audit severity inside a
specialized test matrix does not grant priority. Such findings are recorded but remain queued unless
Aimee explicitly promotes them, they also break her ordinary play path, or they are a trivial part of
the already-authorized ordinary implementation. Tutorials remain dead last. Before dispatching work,
Game Design must verify the live active item, its authorizing Aimee instruction, its ordinary visible
outcome and any displaced item; missing evidence means no dispatch.

## 242. The true combat graph cannot replace working progression with disabled learning

**Date:** 11 August 2026

The native 24-node graph component and DEBUG route explorer may be built and accepted before Combat
Tree v2 release ownership is complete. The ordinary production tree, however, cannot be replaced by
a graph whose Learn action is disabled merely to avoid activating inert nodes. Existing functional
progression remains available until stable-ID persistence, legal graph purchase, lossless point
migration and real consumers can promote together. Production promotion must add the true graph
without removing a playable facet.

## 243. Every queue change requires a development-stage and rework audit

**Date:** 11 August 2026

Before changing the active queue, Game Design must inspect whether the proposed work's mechanics,
schema, transaction and ordinary UI foundations are stable; whether known queued work would invalidate
it; whether it creates a complete playable result now; whether any disposable scaffold is strictly
necessary and isolated; and whether its acceptance evidence will remain valid. The handoff records
stage fit, stable dependencies, player-visible result, rework risk and displaced item. A task stays
behind its dependency when it would otherwise be substantially redone later. Accessibility tuning
before ordinary redesign, final balance before combat authority, final art before identity contracts,
and disabled production replacements are canonical sequencing failures, not reasons to do the work
early.

## 244. Almost all current UI is provisional but must remain playtest-quality

**Date:** 11 August 2026

Aimee expects almost the entire application UI to change, but current UI must still feel good, look
intentional and play well on her ordinary phone. Iterating layouts when she finds a screen repetitive,
confusing, unpleasant or ineffective is active game-design work, and alternative layouts may be built
to test the answer. Rules, transactions, stable IDs and interaction state remain separate from
replaceable presentation. What is held is premature *finalization*: accessibility-size variants,
exhaustive device edges, animation, final navigation/design-system claims and polish whose evidence
will be invalidated. Spatial writing, world navigation, combat and graph topology receive strong
current visual/interaction design because they determine play feel; acceptance is playtest-quality,
not permanent final UI.

## 245. The DEBUG combat explorer is staged support, not a prerequisite mega-feature

**Date:** 11 August 2026

The active first stage proves the authored 24-node topology, stable-ID selection, exact connector and
Effect semantics, 8/17/25 route budgets, legal local Learn/reset and zero campaign mutation in an
intentional ordinary-phone surface. It must also reveal selected detail without requiring an
undisclosed manual scroll. A/B simulations, every scenario fixture, route export, reporter attachment,
accessibility-size reflow and exhaustive assistive-technology work do not precede real production
ownership and consumers. Deterministic fixture and contribution tools are added in bounded groups as
the consumers they test become real; later comparison/export work may not displace higher live-roadmap
playability items.

## 246. Combat-v2 consumers precede ordinary ownership promotion

**Date:** 11 August 2026

After the reusable graph proof, Engineering remains on Combat Tree v2 but implements the remaining
effects as bounded scenario-tested consumer groups behind the isolated stable-ID path. Ordinary save
ownership, point spending, migration and production graph replacement promote together only after
every purchasable node is functional. Persisting or selling inert nodes earlier would either remove
working legacy progression or require a second migration when the consumers stabilize. This sequence
does not defer the combat trees; it completes their actual gameplay before exposing their purchases.

## 247. Physical launch experience overrides source-only loading acceptance

**Date:** 11 August 2026

Aimee's newly installed phone build still showed a long black main-app startup wait and no visible
loading bar, so `launch-handoff` is reopened ahead of the next combat-v2 consumer after the
already-running graph checkpoint is isolated. The later loader shown while opening a selected save
does advance correctly, but its splash composition is askew. Preserve that working progress state
machine; identify the exact installed build and slow pre-first-frame phase, eliminate the black
handoff, and align static/initial/save-loading compositions. The existence of source/tests is not
acceptance when the real installed launch does not present them. A broader accessibility/device
matrix remains deferred; this correction owns the ordinary play path.

## 248. In-combat bug reports must preserve the frozen scaling receipt

**Date:** 11 August 2026

The floating DEBUG reporter currently captures an encounter ID and the active global tuning profile,
but those do not reconstruct the encounter that actually formed. After the active launch checkpoint,
an in-combat report will optionally embed the already-saved encounter scaling receipt, final foe
stats, opening/current combat position and current HP state. The payload is tolerant evidence only:
it does not recompute difficulty, mutate the save or automatically label a fight balanced. This is a
small prerequisite for efficient fresh-save balance acceptance, not a broader analytics project, and
does not displace launch repair or Aimee's current testing.

## 249. Expedition health has one frozen cap receipt

**Date:** 11 August 2026

Thick Hide adds +6 maximum and starting HP to its exact owner for the next expedition, but it cannot
be implemented as another live loadout lookup. Every departing member receives one saved health-cap
receipt containing their ordinary character/equipment maximum, stable-node components and final
maximum. Departure current HP, world and combat healing, health fractions, bars and passed-out state
all read that authority. Base preview remains prospective; changing a Base loadout or DEBUG selection
cannot rewrite a trip underway. Legacy active runs adopt once after full-state decode without changing
their current HP, then persist the receipt. This replaces the existing disagreement between dynamic
maximum-health calculation and constant run-health presentation rather than layering Thick Hide on
top of it.

## 250. Feature documents do not own operational queue position

**Date:** 11 August 2026

Current design documents may state whether their feature is specified, implemented, installed,
accepted or blocked, but `Sources/Content/Data/playability-roadmap.json` is the sole operational queue
authority shown in the app. A prose header may link its stable roadmap ID; it may not continue calling
itself “active,” “next” or “current priority” after scheduling changes. Historical checkpoint text is
retained and dated. This prevents a technically useful feature document from silently becoming a
second task board and sending work ahead of Aimee's current playability priority.

## 251. Fresh-save encounter acceptance is stratified by real group size

**Date:** 11 August 2026

A single ordinary foe, a disclosed two-foe group and a disclosed three-foe group are not held to one
HP-loss band. For a fresh Binder + Quill, provisional healthy bands are 5–20%, 15–35% and 25–50%
aggregate starting HP respectively, with three-foe groups uncommon in Normal worlds. Teeming may make
visible groups common and dangerous through world population, but does not excuse unavoidable or
hidden opening death. Its density, pre-density count increase, pressure-derived world level, species
matchup and encounter grouping are diagnosed separately. Individual creatures are not globally
weakened merely because a crowded Teeming contact failed, and the additive party scaler is not
blamed when two or three real map bodies already exceed its 1.5-equivalent fresh-party budget.

## 252. Identity-owned baseline techniques are implemented, not a combat-v2 blocker

**Date:** 11 August 2026

Checkpoint `ce9b1af` already implements the reversible Decision 185 ownership split: Binder owns
Unbind/Sight, roster-stable Quill owns Mend/Read, Ashe owns Ground, exact graph grants remain personal,
and ordinary named/generated people borrow none of them. DRQ-160 therefore remains open only for
Aimee's later feel review of Quill-free healing and naming. It no longer blocks combat consumers or
production ownership design, and it cannot justify restoring the obsolete universal four-technique
grant. Exact Sight/Read instrument transfer and departure healing disclosure close with their own
playable consumers.

## 253. Unbind/Withdraw naming is implemented reversible playtest authority

**Date:** 11 August 2026

Checkpoint `ce9b1af` already implements Decision 185's naming/mechanics split: Unbind is the Binder's
damage technique, Withdraw is the ordinary confirmed retreat, Vanish waives exactly one Withdraw cost
per expedition through a saved receipt, and decoded legacy Rout is inert. DRQ-159 remains open only
for Aimee's later feel/copy review. It no longer blocks the action palette or combat-v2 promotion,
and it does not permit two player actions called Unbind or conversion of legacy Rout into Vanish.

## 254. Combat-v2 schema generation is a closed prerequisite

**Date:** 11 August 2026

Checkpoint `71ffca2` already promoted canonical schema-2 combat content: 72 stable nodes, exact Effect
copy, canonical optional technique IDs with 20 non-null/52 null, authority/source hashes and
migration-only legacy payloads. The authoritative generator check is currently green. This is a
maintained freshness gate, not queued work and not a reason to delay the next missing consumer.

## 255. Captured phone plans remain history, not parallel live schedules

**Date:** 11 August 2026

The former Phase-1 phone card and playability-priority sequence preserve a useful record of the
`ce9b1af` protected-test plan, but their “now,” pending-install and source-work statements became
false as checkpoints advanced. They are archived in place rather than manually rewritten. Live queue
state comes only from `playability-roadmap.json`; installed-device identity comes from an exact
receipt. Later roadmap items may link reusable acceptance bullets without turning the old sequence
back into an executable board.

## 256. Combat-v2 reuses working mechanics but replaces their legacy ownership seam

**Date:** 11 August 2026

Pry/Overbear/Shatter/Finish, defensive techniques, conceal/opening effects, field-awareness effects,
Vanish and Unseen already have meaningful legacy-path mechanics and saved receipts. Combat-v2 does
not rebuild parallel versions. It wires canonical stable-node ownership and frozen provenance into
the existing resolver/receipt and proves the exact owner by scenario counterfactual. These nodes are
not complete merely because the legacy mechanic works, but neither are they blank feature
construction. No second opening roll, conceal store, retreat receipt or field-movement engine is
introduced for v2.

## 257. Combat-tree topology holds; fresh weapon readiness becomes playtest evidence

**Date:** 11 August 2026

The 72-node fan-and-fork passes its route-quality audit: every capstone has at least 13 legal routes,
hybrid alternatives preserve a five-node discipline commitment, and similar effects have distinct
timing/ownership jobs. No further topology or naming redesign precedes real consumers. A fresh save,
however, equips no weapon, leaving Heavy Hand, Keen Eye, Tainted Edge and Sparkhand potentially
inactive when an early point arrives. This remains an explicit playtest question. Current gear
applicability and point banking must be visible; if suitable gear does not ordinarily arrive soon,
an explicit early equipment route may be designed separately. No starter weapon or generic unarmed
fallback is silently added while fresh encounter balance is under measurement.

## 258. Complete the Trading Post as a merchant, including one bounded equipment line

**Date:** 11 August 2026

The live Trading Post fulfills selling, gold, resource stock and occasional Essence, but its refresh
does not yet generate the settled material-sample or basic-consumable lines. Although the saved stock
enum and view recognize item/material cases, buying either currently fails deliberately. Calling this
merchant stock complete would repeat the misleading resource-conversion identity Aimee rejected.

The completion slice adds 0–2 common material samples, 0–2 permanently-known basic consumables and
exactly one ordinary tier-1 catalogue equipment piece to each expedition-refreshed snapshot. Until
the campaign owns any weapon in storage, overflow or on a person, the equipment line is constrained
to an ordinary weapon; afterward every ordinary tier-1 slot is eligible. It does not grant starting
gear, guarantee one damage kind, reroll on sale/equip, expose unknown recipes, or admit unique, apex,
diary, key or narrative objects. Purchased objects preserve one frozen stable identity and use the
ordinary capacity-safe storage/Waiting path in the same atomic gold-and-stock transaction.

This completes an existing advertised system and supplies an eventual early equipment recovery route;
it is not allowed to displace the active launch repair, fresh encounter acceptance or the already-
started Thick Hide consumer. Fresh first-point weapon readiness remains evidence because Vance and
construction are not guaranteed before that point.

## 259. Equipped gear receives frozen combat tempo, not an encumbrance system

**Date:** 11 August 2026

Light Touch and Momentum cannot consume the live model as written because gear stores no initiative
modifier. Add one explicit authored integer tempo modifier to each catalogue definition/craft recipe
and freeze it on each exact gear profile. A tolerant optional/versioned saved field distinguishes a
missing legacy value from an authored zero until full-state adoption fills and persists it once. It affects combat initiative only while equipped; it does
not create inventory weight, carrying penalties, field movement cost, durability or material-density
inference. Missing legacy values adopt once from the authored definition during full-state
normalization and then remain stable across catalogue tuning.

The reversible first profile makes close Rend/Pierce weapons and feet/tools/keepsakes neutral;
mid/far reach modestly slower; Crush weapons, off-hands and progressively rigid head/body gear slower;
and hands at most slightly slower. The eight wild weapons receive explicit handling values. Exact
values and the full table live in `combat-tree-v2-consumer-plan-current.md`.

Light Touch halves only the summed negative equipped contribution toward zero and preserves any
positive contribution. Momentum reads the remaining positive difference between unencumbered and
final initiative, granting `min(4, floor(0.4 × penalty))` raw direct-hit damage once. Their opposition
is deliberate: relieving load recovers order but reduces the damage available from committing to
weight. Low base stats, statuses and temporary order changes never masquerade as gear load.

## 260. Defeat-trigger nodes share one source-attributed transition

**Date:** 11 August 2026

Second Wind, Rally and Cascade consume one exact first transition from living foe to zero rather than
maintaining separate kill checks. Event provenance credits the stable party actor who authored a
direct hit, Killing Stroke consequence, carried Flurry/Conduction damage or delayed affliction tick;
source-unknown legacy afflictions, environmental harm and scripted removal grant no party credit.
Already-zero foes cannot pay twice.

Each actual foe defeated may trigger the source owner's Second Wind +3 self-heal, Rally +2 healing to
every other conscious ally and one Cascade +3 initiative stack, capped at three. Healing never
revives and clamps to the frozen expedition cap. Cascade drains after the damage event and reorders
only unresolved actor blocks: the current block completes, completed blocks stay completed, apex
follow-ups remain attached, and initiative never creates, repeats or skips an action. These terminal
consequences cannot recursively produce another defeat transition.

## 261. Flurry and Conduction carry final HP loss through one terminal event

**Date:** 11 August 2026

For both nodes, “damage actually dealt” means the primary target's exact HP loss, excluding overkill.
Positive loss carries `max(1, floor(loss × fraction))`: 40% for Flurry, 50% for Conduction. The
secondary event retains the original actor for defeat credit but does not reroll or reapply attack,
critical, avoidance, matchup, rank, armour, coating, execute or any direct-hit consumer. It may defeat
the secondary once; `carried` provenance prevents recursion.

Flurry follows physical attack legality and reach when choosing the first other living stable-order
foe. Conduction may jump beyond physical reach to the first other living disclosed foe. Conduction
also copies the matching Burn/Poison/Dazzle payload at half its authored post-Virulence,
pre-Constitution duration, rounded up; the secondary's Stonebark and Constitution then apply once.
Copied provenance prevents another Virulence/Conduction expansion while preserving actor-owned
Poison for later Corrode.

## 262. Venom nodes consume the canonical affliction application outcome

**Date:** 11 August 2026

Virulence, Corrode and Blight ship only on the exact-combatant affliction authority from Decision191/
DRQ-177, never on another poison store. Virulence adds two pre-Constitution ticks to its owner's
direct/coating applications, excluding copied, retaliation, environment and migrated-unknown
provenance. Canonical max refresh returns a typed prevented/no-op/added/strengthened outcome.

Blight fires only when its owner successfully adds or strengthens Poison. It copies half of that
prospective post-Virulence/pre-Constitution payload—not an older merged row—to another living
disclosed foe, rounding damage/ticks up with minimum one; the new target's Stonebark, Constitution and
max refresh apply. Copied provenance blocks recursive Virulence/Blight/Conduction expansion.

Corrode reduces a living target's later armour by one after the first source-owned Poison tick per
actor/target/global round. It stores encounter erosion rather than mutating frozen stats, floors
armour at zero, preserves exact source through canonical refresh, and grants nothing to unknown
legacy poison. An owner passing out does not retroactively unauthor their existing Poison.

## 263. Survival nodes use pre-event health and one final-damage receipt

**Date:** 11 August 2026

Constitution halves a prospective Burn/Poison/Dazzle/Bleed application's final authored ticks after
producer/Virulence bonuses and before Stonebark/max refresh, rounding up with minimum one. It changes
neither damage nor existing rows and does not shorten an endless sentinel.

Endurance checks current HP against the frozen expedition maximum before each event. At or below half,
it replaces already-mitigated positive damage with 75%, floored and bounded by that event's minimum.
The crossing hit is not reduced; later hostile direct, carried, affliction and environmental events
are. Voluntary costs and Cover's already-mitigated redirected share are excluded.

Unyielding then checks the final integer. Once per encounter, the first event that would pass out a
conscious owner leaves them at 1 HP and persists a spent receipt. It preserves landed-hit payloads,
does not protect a later event in the same action, recharge after healing or revive somebody already
passed out. All three nodes read the same Thick Hide health-cap authority.

## 264. Hostile targeting has one intent, replacement and split order

**Date:** 11 August 2026

Hostile single-target intent filters living/disclosed candidates, then reach/rank, then Guardian's
front protection; a legal exact-owner Draw Off overrides ordinary choice. Interpose may replace that
frozen intended target before avoidance/mitigation, and Cover may split a landed non-Interposed hit
only after the final back target's mitigation. Area, multi-target, environment and status delivery do
not accidentally enter this single-target pipeline.

Draw Off stores foe and stable PartyMember rather than defaulting to the Binder, breaks Conceal,
lasts two boundary ticks and must remain legal for each action slot. Interpose chooses the oldest
valid receipt, breaks concealment and is spent on replacement even if the interposer subsequently
evades. Cover uses one conscious front owner and a 70/30 largest-remainder split, with ties favoring
the original target; its redirected share receives no second mitigation, while Unyielding may still
answer lethal final HP loss as a survival receipt. Explicitly
tagged scripted exceptions may bypass redirection, but apex identity alone may not.

## 265. Quicken and Blur grant two real actions through one saved block receipt

**Date:** 11 August 2026

A fresh scheduled personal block owns one normal-action credit and one zero-turn setup window.
Quicken or Blur consumes that window and replaces the credit with two consecutive normal-action
credits. Quicken immediately adds one future skipped-block debt; Blur adds none and spends its
once-per-encounter receipt. Expanded credits cannot use Quicken, Blur, Fall Back or another setup,
and using another setup first closes the expansion opportunity. Ambush remains a separate opening
attack.

Overbear consumes one credit, attacks once and adds one debt, stacking with Quicken and with another
expanded Overbear. First Strike is the actor's first **normal-cost** action, so opening/setup/skip
events do not consume it and it may use the first expanded credit; it adds +4 once and prevents
retaliation only on that hit. Credits stay inside one initiative block, cooldowns/round boundaries do
not advance between them, and saved block/debt/first-action receipts survive relaunch. This replaces
the live `extraTurns += 1` Quicken behavior that currently produces only one action after activation.

## 266. Opening classification, suppression, concealment and free attack remain separate

**Date:** 11 August 2026

One frozen opening receipt keeps the physical initial classification and resolved consequence. For
an ordinary creature ambush, strongest-once Slippery first rolls 50% to resolve mutual contact; only
after failure does strongest-once Watchful suppress forced foe actions without reclassifying the
ambush. Unseen then conceals each exact owner through the end of ordinary round 1, including pending
foe actions. Low Profile adds +6 personal evasion only while its owner is the final target of those
actual forced opening actions.

Without suppression, each living ordinary foe receives one forced primary action before—not inside—
the untouched ordinary schedule. The party has one shared Ambush attack only in mutual/approach or
explicitly allowed scripted openings; Watchful does not make a creature ambush eligible, while a
successful Slippery resolution does. Ambush is zero-turn, consumes on a committed legal attack even
if it misses, retains ordinary retaliation and spends neither the scheduled setup window nor the
first-normal-action credit. Scripted/apex exceptions use explicit disclosed flags rather than names.

## 267. Anatomy and Apothecary's Hand modify exact transaction outputs

**Date:** 11 August 2026

Anatomy adds `max(1, floor(base butchery quantity × 0.35))` to every truthful material family from
each creature when any exact expedition participant owns it, strongest once. It changes no grade,
properties, source, material-family eligibility, ordinary resource/gear/XP or apex reward and does
not require the owner to land the defeat or remain conscious.

Apothecary's Hand adds 50% (floored, minimum +1) to exactly one typed scalable field of a beneficial
item used by its exact actor: numeric healing magnitude or genuine timed duration. Binary cures,
one-affliction Stonebark, coatings, escape, identification, Lure and zero-valued effects cannot
manufacture charges/copies. Current world-item actions without a stable user receive no bonus rather
than borrowing Binder ownership. Preview and commit consume one shared receipt and one item.

Distiller remains unresolved because its existing 40%-with-minimum-one discount changes none of the
current one-unit coating ingredients. The two-charge self-coating recommendation is explicitly held
for Aimee in `combat-tree-distiller-effect-review-current.md`; it is not silently settled here.

## 268. Same-hit weapon afflictions merge once by kind before protection

**Date:** 11 August 2026

Tainted Edge supplies Poison 1/2, Sparkhand Burn 1/2 and Emanant supplies chosen Burn 1/2, Poison 1/2
or Dazzle 0/2 on eligible landed direct physical weapon hits. Matching Heat+Sparkhand or
Caustic+Tainted Edge becomes one strengthened 2/2 payload; nonmatching kinds coexist.

All same-kind contributors from the hit—including Envenom and one prepared coating—merge by maximum
damage/duration into one prospective application with complete provenance. Virulence applies once,
then target Constitution and canonical max refresh. Different kinds apply in Burn→Poison→Dazzle→Bleed
order so one Stonebark guard has deterministic meaning. Misses/nonweapon/carried/status events are
ineligible; a lethal successful hit spends prepared charges but adds no status to a defeated target.

Emanant purchase atomically chooses Heat/Caustic/Light. Only full Spring respec removes the choice;
repurchase asks again. Legacy choice-less ownership adopts Heat once with a migration receipt, and
encounter entry freezes the exact owner's choice.

## 269. Stagger moves one complete foe block in the next ordinary round

**Date:** 11 August 2026

A landed direct Crush hit rolls the exact owner's 30% Stagger after damage unless Breaking Blow
already guaranteed it for that hit. Success writes one foe/next-round receipt; repeated successes
merge rather than stack. Pre-schedule Ambush targets round 1, while a hit in round N targets N+1.

At that boundary, build living initiative/Cascade order, then process pending foes from later to
earlier current positions and swap each complete selected block once with the next living block.
Apex/pressure follow-ups never separate, the last block stays last, and the receipt is consumed even
when no later position exists. Stagger never skips, duplicates or interrupts an action; death clears
pending state and a new hit during the displaced round may schedule the following round.

## 270. Party avoidance resolves guaranteed receipts before one probability roll

**Date:** 11 August 2026

After target replacement, a legal single-target direct attack consumes Sidestep first, then Ghost,
then—only if neither guaranteed miss applies—one saved RNG roll against character evasion + Footwork
+ Feint + Untouchable + eligible Low Profile, capped once at 85%. Misses land no damage/affliction or
prepared-hit consumption. Other delivery types consume nothing.

Feint grants +10 after any committed direct attack and lasts through reactions until the owner
finishes their next normal-cost action; refresh replaces, never stacks. Untouchable gains +5 at an
ordinary round boundary when at least one direct attack targeted the owner and none landed, caps at
20 and resets immediately on a landed direct attack. No targeting retains but does not grow the
stack. Forced pre-round opening attacks can reset existing state but cannot award a pre-round stack.

## 271. Active mitigation techniques use event-scoped receipts, not generic clocks

**Date:** 11 August 2026

Brace persists to the next hostile action slot that actually deals direct damage to its exact owner,
reduces every qualifying event in that slot by 35%, and consumes at slot end. Ward explicitly chooses
one of Crush/Pierce/Rend/Heat/Caustic/Light, reduces matching direct harm by 60% for the activation
round plus the following ordinary round, and never guesses from encounter contents. Both use the one
incoming-harm pipeline and do not retroactively reduce affliction ticks.

Snuff stores two complete scheduled hostile turns on one emanating foe, suppressing all attached
slots to its underlying physical profile without erasing identity or existing afflictions. Quench
removes one explicitly selected Burn, Poison or Dazzle from one conscious ally/self; it does not
clear Bleed, Ground or other rows. The sole legacy `steady` node reference migrates one way to stable
`quench`; release does not preserve the misleading broad-cleanse alias.

## 272. Combat-tree Effect copy follows settled event semantics

**Date:** 11 August 2026

The player-facing 72-node Effect authority now names real action and expiry boundaries instead of
legacy shorthand. Quicken promises two ordinary actions after zero-turn setup; First Strike and
Ambush key to normal-cost actions; Slippery states its 50% mutual-contact result; Feint names its
next-normal-action window; and Brace, Ward and Snuff state their exact reduction/block durations.
The generated Effect mirror and native schema-2 catalogue were regenerated from that one Markdown
authority. This is copy alignment with Decisions265, 266, 270 and 271, not a new balance change.

## 273. Active stance and prepared strikes have exact reveal, charge and choice receipts

**Date:** 11 August 2026

Fall Back consumes a fresh personal block's zero-turn setup window, changes Front↔Back and preserves
the ordinary action. Conceal costs an action, lasts through the following ordinary round and excludes
its owner only while another legal target exists; direct attack, Draw Off or Interpose reveals them.
Opportunist consumes one +5 opportunity on the first landed direct hit while concealed or during the
same/next normal action in which they emerge, without surviving a miss into a later turn.

Envenom arms three successful physical-weapon hits with Poison 2×3 and resets rather than stacking.
Emanation Strike explicitly chooses Heat/Caustic/Light, deals direct typed raw power 9 and carries
canonical Burn 4×2, Poison 2×4 or Dazzle 0×2. It uses frozen weapon reach for legality but is not a
physical weapon hit. Manual selection updates the actor's gambit preference only on commit; legacy
`elemental_strike` migrates one way.

## 274. Pry, Finish and Flense use distinct direct-versus-affliction transactions

**Date:** 11 August 2026

Pry is a raw-power-7 direct Pierce weapon technique that ignores but does not destroy armour. Finish
is a direct Pierce weapon technique using raw 14 at or below 35% current HP and floor(14/3)=4 above,
then follows the ordinary hit/consequence pipeline rather than executing by itself. Flense is not a
direct weapon hit: it applies canonical source-attributed Bleed for three ticks at
`max(1, round(9×covering insulation/100))`, with hidden covering protected in preview.

Shatter is not silently settled with them. Live code is a non-damaging four-armour debuff while its
copy and declared Crush identity promise a strike. The recommended landed power-4 Crush hit followed
by four armour damage awaits Aimee in `combat-tree-shatter-effect-review-current.md`.

## 275. Nineteen combat actions are specified; Shatter alone remains held

**Date:** 11 August 2026

The canonical 20-entry technique grant map now has complete selection, action-cost, outcome, failure,
receipt and relaunch contracts for 19 actions. Shatter alone remains contradictory and held at
DRQ-197. Distiller is not a technique grant and remains a separate passive-economy review, so neither
review should obscure the readiness of the other action cohorts or be mistaken for full release
implementation.

Implementation attaches ready techniques only after their shared actor, affliction, direct-hit,
scheduler, opening, targeting and incoming-harm primitives exist. Per-technique temporary clocks or
counters are rejected because they would be knowingly discarded when those shared consumers land.

## 276. Stagger delays saved slots without collapsing lighter-action interleaving

**Date:** 12 August 2026

Decision269's “complete block” reinsertion is superseded after implementation review exposed a
conflict with the settled apex/pressure cadence: those lighter actions must remain interleaved and
must never become a consecutive burst. At the applying boundary, process pending foes from later to
earlier primary position. For each foe, process its saved slot indices last-to-first and move each
slot across at most one next living slot owned by another actor. Preserve slot kind, strength,
affliction suppression and relative order. Log success when at least one slot moves; “no later
opening” only when none can cross another living actor.

The same correction governs future automatic Stagger from Breaking Blow. Cascade moves only its
party owner's unresolved ordinary slot and never gathers or relocates saved foe follow-ups. This is
not a balance buff or nerf to apex actions; it preserves their already-settled readable tempo while
allowing control and initiative nodes to affect the schedule truthfully.

Decision269's Ambush→round-1 example is also superseded. Live Ambush is chosen on its owner's first
ordinary scheduled slot, despite costing zero turns, so that round is already in progress and its
Stagger targets the following round. Only a genuinely pre-schedule future producer may affect the
upcoming round 1 before its cursor begins.

## 277. Failure-retention arithmetic is correctness; exact-item agency remains a player choice

**Date:** 13 August 2026

The outcome-wide retained-unit budgets and stable apportionment in
`failure-recovery-agency-recommendation.md` are not optional generosity: they correct the live defect
where splitting an identical total haul across more inventory/resource kinds causes more of it to
disappear. Engineering may implement that arithmetic with deterministic automatic item selection
before any new UI.

Whether the player may replace that suggested item set is a separate design choice. Homework question
`failure-recovery-agency` now compares player selection, deterministic automatic selection,
favourite-first automation and deliberately holding agency until the arithmetic/receipt is playable.
No answer may change the fixed retention budget, bulk-resource automation or protection for knowledge,
people and pre-departure property.

## 278. The single fresh-save defeat does not authorize a global encounter nerf

**Date:** 13 August 2026

The only retained feel evidence is one uncontrolled fresh-save defeat in a possibly Teeming world,
without a complete encounter receipt. Recommended scaling adds 15% HP and no follow-up to one real
foe against fresh Binder + Quill; it adds no hidden pressure to an already-visible two-/three-foe
group. Generated species, grouping, Greed/Stability level, opening and matchup can each explain a
loss independently.

Keep the current reversible coefficients until the exact Normal-versus-Teeming control in
`encounter-scaling-playtest-current.md` is captured. Repeated isolated Normal failure routes to the
level-1 creature/unarmed baseline; Teeming-only grouped failure routes to density/grouping/contact
agency; a single species outlier routes to that identity. Apex values remain structurally accepted
but numerically unpromoted until two- and five-person phone bands exist. This is disciplined tuning,
not acceptance of the present feel.

## 279. Coherent authored content enters the game before review

**Date:** 13 August 2026

Completed coherent traveller meetings, dialogue replacements and clue sequences are promoted into
live game content without waiting for Aimee to preapprove each unit in the DEBUG Atlas. Aimee reviews
them through ordinary play and bug reports; the Atlas remains useful for targeted revision, hashes,
notes and corpus navigation rather than acting as a release gate.

This authorizes promotion of the 21 completed missing-live traveller meetings, Noll's replacement,
Auber's revision, Isolde's three optional-reply replacements and Sabine's seven-location sequence.
Stable IDs, authored order, condition indices, migrations and generator freshness remain mandatory.
Only genuinely incomplete or internally contradictory copy remains draft-only. A play-found bad line
is revised in place; it does not justify withholding unrelated completed content.
