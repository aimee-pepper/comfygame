# Game Design takeover assessment — 4 September 2026

Initial assessment for Aimee after accepting the Game Design lead role. Recommendations below are design
review, not changes to accepted mechanics, an Engineering dispatch, or a delivery receipt.

**Subsequent Aimee direction:** see [design direction and first progression packet](game-design-early-progression-direction-2026-09-04.md).
Aimee has explicitly made recipes, upgrade costs, and progression/recruitment order provisional and
authorized redesign for playability, enjoyment, coherence, and intuitive physical crafting. Earlier passages
below about preserving the accepted order or tuning describe the initial review, not a continuing restriction.
She authorized the early progression design work and relay of this assessment to the current Project Manager.

## 1. Evidence and boundaries

Read the succession handoff and recent completed history from former Game Design task
`019fe2ea-e58d-7cd1-99d7-84808e57c4f3`, the shared `AGENTS.md`, and the newer
[documentation authority](documentation-authority-current.md). The latter records further Aimee decisions,
incoming lead assessments, and a hold on assignments during the role transition; the predecessor queue is
not an instruction to restart work.

Source checkpoints inspected:

- Design: `faa2e87fedaca1c38bad59fedd73a8e63fda3bda`, worktree
  `/Users/aimeepepper/Documents/comfygame-worktrees/resource-crafting-progression-v1`.
- Accepted resource/world documents: `b4081f63bd643eeccedb669e8d713fdccde166cc`, worktree
  `/Users/aimeepepper/Documents/comfygame-worktrees/player-wiki-github-pages-v1`.
- Runtime candidate: `216d249830ab7e469cfe19108ebe93a863d0710d`, worktree
  `/Users/aimeepepper/Documents/comfygame-worktrees/party-training-human-ui-v1`.
- Shared checkout: older `db92978c` with substantial unrelated work in progress. It was used for orientation
  and current takeover notes, not treated as the production integration parent.

Read the four accepted resource/world documents and the coupled building/traveller reconciliation. Inspected
representative implementations in Worldgen, BookRules, LifeRules, LibraryRules, GambitEngine, TutorialRules,
BaseState, PhysicalGearCraftingRules, GameActions+Economy, and GameStore, plus relevant test coverage. This is
a selective architecture and gameplay review, not a claim to have inspected every file.

Retrieved the live public Wiki in the browser: home, Getting Started, World Writing, Exploration, Combat,
Village, Current Progression, status guide, first-pass resource rules, Noll, and World Splash inventory.
Local Wiki checkout age does not establish the current deployed revision; newer Homework publication is
recorded in the shared authority note.

No app build, test-suite execution, Simulator interaction, phone installation, or campaign mutation was
performed. No visual acceptance is claimed. Any later visual acceptance must use the actual target iPhone
and its native viewport at default text, recording the device and dimensions. Superseded fixed-368×800 gates
in the roadmap were identified and not followed. All AGENTS.md exclusions remain in force.

## 2. Overall design judgement

Bookbinder has a distinctive central promise: author a request, discover its consequences in a generated
place, learn how that place works, and bring something meaningful back into the Cottage and the next Page.
The overhaul substantially strengthens that promise.

The strongest connections are:

- World Writing and Gambits both let the player compose rules and see consequences. That is a coherent
  identity across exploration and combat.
- Physical terrain, anatomy, materials, and visible equipment colour can make an item a reminder of a
  particular expedition. Compact stacks preserve that connection without making every species a new item.
- Knowledge and people survive expedition failure. That supports curiosity and experimentation alongside
  meaningful decisions about the haul.
- Named specialist ownership makes the settlement understandable and gives recruitment practical value.
- Deterministic worlds, saved discoveries, exact transactions, and free refusals support player trust.

Aimee enjoys complexity and wants to avoid tedium. The design standard should therefore be meaningful
decisions per journey: richer options, understandable consequences, and little repeated administration.

## 3. Early survival needs a complete acquisition path

**Confirmed design dependency, not a demonstrated softlock:** the accepted early Apothecary foundation asks
for 4 Quartz. The newer harvesting table puts Quartz behind Pick level 2, while upgraded-tool recipes and
unlocks are explicitly unfinished. Moving Nessa earlier does not by itself make healing available earlier.

There is a related future trap: Fen owns prepared Hafts and Planks but sits at authored order 17. Early tool
recipes must not accidentally require those processed components. The existing permission to use raw Logs
is valuable and should be used deliberately.

**Proposed narrow correction:** specify the first Pick upgrade under Halloway, before Nessa's useful
Apothecary milestone, with ingredients reachable through opening tools and raw wood. Map the complete path
through the first actual remedy, including its ingredients and enough remaining Essence for another Bind.
Do not rely on a lucky merchant, nearby find, Rubble bonus, or a later resource Sigil as the only path.

This needs an acquisition dependency table, not merely ascending prices. Record recruit, tool, material,
process, building, first useful output, and remaining expedition budget together. Final Nessa/Corrin/Bryn
signatures follow the early land/ecology vocabulary they actually require; infrastructure need not wait for
the entire catalogue.

Sources: [coupled progression](</Users/aimeepepper/Documents/comfygame-worktrees/resource-crafting-progression-v1/docs/building-traveller-progression-reconciliation-current.md>),
[published first-pass rules](https://aimee-pepper.github.io/comfygame/references/resource-world-numbers-decided-so-far.html).

## 4. Peerless crafting risks rewarding repetition

The accepted first pass offers 3% Peerless odds, 5% with the matching specialist, and a guarantee on the
twentieth consecutive eligible craft of the same schematic at the same facility. This is optional and
explicitly not a progression gate; those safeguards matter.

Nevertheless, under repeated eligible attempts at fixed odds, the expected wait is approximately 15.2 crafts
without staffing or 12.8 with staffing, including the twentieth-craft guarantee. About 56% or 38%,
respectively, reach that twentieth attempt. These are arithmetic implications of the proposed rules, not
observed player behavior or measured resource costs.

That creates an incentive to make redundant copies of an expensive object. Visible bad-luck protection
improves fairness but can also turn a rare delight into an explicit production quota.

**Recommendation for discussion:** retain the accepted rule pending a concrete balance review. Before
implementing it, compare the complete material/time cost of one pursued Peerless result with an optional
masterwork refinement of an existing item. The latter is a proposed alternative, not an accepted mechanic.
Avoid introducing a requirement to fill the inventory with copies simply to reach the desired reward.

Also resolve the eligibility example for equipment built entirely from ungraded metal/wood: ordinary output
defaults to Fine and the Peerless rule names Rare/Exceptional quality-bearing inputs. A recipe must explain
its workmanship and attainable result without implying that an advanced metal is weak because its badge
stays Fine. Preserve the settled ungraded-mineral rule; compare actual output statistics and explicit recipe
tiers before making any change.

Source: [published quality and crafting rules](https://aimee-pepper.github.io/comfygame/references/resource-world-numbers-decided-so-far.html).

## 5. The opening must teach control, and clues must teach usable observations

The live Wiki correctly distinguishes the current 12 compound/15 source opening from the intended no-rune
introduction and Illumination/Sun lesson. The planned protection of those discoveries is strong.

**Design risk:** connecting two marks can teach interface syntax without proving that Writing matters.
The first authored world should visibly identify the Sun the player requested and explain that the other
conditions remained generated. A broadly generated introduction might already be sunny, so a simple
before/after claim that the player changed darkness into daylight is not universally valid.

**Narrow correction:** make the first successful Bind explicitly connect the player's written request to
the visible result. Later comparison teaching should distinguish a written consequence from an unwritten
change. Judge the lesson by whether the player can explain what they controlled and why.

Traveller clues then need that same discipline. For example, Noll's public clue still uses narrow seams;
its future meaning must match a learned, visible land property and an available way to influence it.
Do not rewrite the whole clue corpus ahead of the land/Sigil pass. For each final clue, map observation →
known term → available Writing action → reachable meeting. Preserve character voice around that cue.

Sources: [opening](https://aimee-pepper.github.io/comfygame/getting-started.html),
[World Writing](https://aimee-pepper.github.io/comfygame/systems/world-writing.html),
[Noll](https://aimee-pepper.github.io/comfygame/people/noll.html).

## 6. World breadth needs travel and decision pacing

The intended 36×36 world has four times the area of the ordinary 18×18 world, but a simple crossing is only
about twice as long. Actual route length also depends on topology, hazards, harvesting, and returns.
Scaling all budgets by area alone cannot establish comparable expedition tension or useful decisions per
minute. The detailed structure already acknowledges that these budgets still need tuning.

**Narrow correction:** preserve the accepted size ladder and tune travel, harvest actions, return routes,
and Stability together. Track time to the first useful choice, typical goal-completion route, empty travel,
and the remaining return margin. More ground should support a different expedition rather than requiring
the player to clear a larger checklist. These are game-world pacing measures, not additional device/UI
configurations.

The material catalogue needs a similar check. Two recipe consumers are a good admission rule, but do not
prove two stones create different decisions. Each promoted material should have a recognizable reason to
choose it: physical use, environmental interaction, cost/access tradeoff, or desired appearance. Preserve
geological breadth while avoiding multiple names that always lead to the same choice.

Source: [published world and material rules](https://aimee-pepper.github.io/comfygame/references/resource-world-numbers-decided-so-far.html).

## 7. Settlement depth needs enough campaign life to pay off

The accepted tendency places Sabine/Menagerie at order 22 and Tovin/Anchorage at 27 of 29 travellers.
These are not strict linear gates: legitimate clue-backed discoveries may reach ahead. Still, the ordinary
campaign needs room to enjoy companionship and returning to a kept world after those systems arrive.

**Recommendation:** define the intended uses and satisfying goals after each late unlock before inferring
that the current order supplies enough runway. Keep the accepted order while measuring actual recruitment
and use pacing. Do not move people merely because their order number looks large.

Specialists should also remain people the player wants around. Noll's observations about Vance and Halloway
already connect work with relationships; preserve that texture as processing and station interfaces expand.
The Cottage should visibly accumulate a community alongside its capabilities.

For parallax, the modular five-plane direction is promising. Its central obligation is to show the world
the game actually resolved. Use the saved environment result for both art and rules; do not commission a
separate painting for every combination or use a beautiful generic landscape that contradicts the expedition.
Final production files still require the named native consumer and measurements. Later accepted palette
decisions in the documentation authority supersede older open-choice language.

Sources: coupled progression above and
[World Splash inventory](https://aimee-pepper.github.io/comfygame/references/world-splash-assets.html).

## 8. Player trust has two concrete outstanding issues

**Independently checked source issue, also identified by incoming Engineering:** at candidate `216d2498`,
`craftConsumable` and `craftPhysicalGear` call `mutateIf(flush: true)`. That helper publishes the candidate
and returns success without propagating a failed save. The same store already provides a persist-before-
publication helper. A source-level failure path is established; an actual player-loss incident is not.

**Correction:** Engineering should reuse durable commitment for these affected crafting routes before
carrying the pattern into the overhaul, with focused failed-save and relaunch proof. The design promise
is simply that confirmed crafting success remains true after closing the game.

References in the inspected candidate:
[craftConsumable](</Users/aimeepepper/Documents/comfygame-worktrees/party-training-human-ui-v1/Sources/Rules/GameActions+Economy.swift:711>),
[craftPhysicalGear](</Users/aimeepepper/Documents/comfygame-worktrees/party-training-human-ui-v1/Sources/Rules/GameActions+Economy.swift:1583>),
[mutateIf](</Users/aimeepepper/Documents/comfygame-worktrees/party-training-human-ui-v1/Sources/Persistence/GameStore.swift:1165>).

**Confirmed public contradiction:** the status guide says Scent Mask and Seamlight have usable Field effects
and later says neither works properly through the Field Kit. The incoming Engineering review identifies
candidate controls; installed behavior still needs verification. The public Wiki remains the intended single
product record, but it is not yet perfectly self-consistent.

**Correction:** reconcile that page against a named delivered build and update the conflicting statements
together. Also synchronize the four accepted resource/world authorities so same-named older files cannot
restore obsolete rules. Preserve the exact Aimee Reference section. No external publication was performed
during this review.

Source: [live status guide](https://aimee-pepper.github.io/comfygame/guide-status.html).

## 9. Proposed first design work

1. Close the early land/material/tool acquisition dependencies needed by Halloway, Nessa, and Corrin,
   including the first useful output and the next expedition's budget.
2. Continue the functional land/geology catalogue with explicit hosts and meaningful consumers. Complete
   generated creature/habitat and material production in dependency order.
3. Finalize the affected traveller signatures, Sigil progression, and clue teaching only against the vocabulary
   those paths establish. Do not make the entire catalogue a prerequisite for unrelated infrastructure.
4. Review the complete effort and reward of one ordinary equipment craft and one proposed Peerless pursuit.
5. Assess coherent playable slices through Aimee's ordinary journey as they become available, and reconcile
   the public record with each actual delivery.

This assessment adds no assignments, changes no accepted tuning, and does not resume the predecessor's
production queue. It preserves a concrete starting point for the new design lead's discussion with Aimee.
