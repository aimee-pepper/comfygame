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

## 26. Emanation branch display name

The Craft branch with implementation ID `kindling` is player-facing **Emanation**. Kindling falsely
centred fire after the status/system correction; Emanation accurately includes heat, caustic and
light, as well as both projecting and resisting them. The stable ID does not change, preserving saves
and engineering references.

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
See `exchange-recycler-economy-current.md`.

## 97. Found salvage follows visible construction, not a fictional source

Found catalogue gear has no trustworthy construction receipt. Its authored Recycler profile may
therefore return reclaimed world resources for visibly forged/mineral pieces or reclaimed material
samples for visibly organic pieces. Tier bands return one, two or three outputs; none inherit a
creature, flora or world provenance the item never stored. Broad family profiles are a reversible
DRQ-116 placeholder, while item-level art/description contradictions override the family. See
`exchange-recycler-economy-current.md`.

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
