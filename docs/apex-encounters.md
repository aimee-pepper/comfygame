# Apex Encounters & Wild-Only Weapons

**Current status, 11 Aug 2026:** the encounter/reward loop and all eight wild rules are wired; the
ordinary-creature and locked-cache lottery routes are live. Fog-gated disclosure supersedes the old
immediate-marker proposal, adjacency is safe, and deliberate occupied-tile entry starts combat.
Recommended party-power scaling is integrated and awaiting the phone comparison defined in
`apex-system-audit.md` and `encounter-scaling-phone-test-card-current.md`. This document preserves
older proposal labels as design history; the audit owns current implementation disposition.

> *"there need to be some rare weapon drops that only happen out in the wild. maybe there should be scary only-by-choice mob encounters out in the wild that they have a guaranteed drop from, but there's a tiny percent drop chance from normal mobs or locked caches?"*

**Two routes to the same thing: hunt it deliberately, or get lucky.** Which respects both a player who wants the fight and one who doesn't.

---

## 1. What an apex is

**A creature the world cannot afford.**

`BookRules.enemyTable` filters creatures by `appetite <= energyBudget` — a world only spawns what it can feed. **An apex breaks that rule on purpose:** its traits are drawn far beyond the world's budget, so it is bigger, harder and stranger than anything that belongs there.

**That's a good fiction as well as a good mechanic.** Something too large for this world to feed either **came from somewhere else**, or **is eating everything else**. Both read, and both are true of what it does to the map.

## 2. By choice — the rule that makes it work

**You must be able to see it and walk away.**

| | |
|---|---|
| **Visible from range** | Marked on the map and the minimap from the moment its tile is revealed — **not** hidden by fog like ordinary spawns |
| **Never ambushes** | Even if its traits are cryptic. **An apex that jumps you isn't a choice** |
| **Doesn't hunt you** | It holds its ground, or patrols a small area. It is *somewhere*, not *coming* |
| **Contact is the commitment** | Adjacency never starts combat. Combat begins only when the player deliberately steps onto the apex's occupied tile |

**[PROPOSAL] One per world, at most.** Two makes them scenery.

**Fleeing works**, at the usual stability cost — so a fight you misjudged is survivable. **Nothing here should be able to end a run you didn't consent to.**

## 3. Where they appear — greed, danger, and sites

Spawn weight rises with the things that already mean *this world is dangerous and worth it*:

| Condition | Why |
|---|---|
| **High greed** | The clearest one. A rich world is worth guarding, and it gives greed a *third* payoff beyond loot and instability |
| **High instability** | Something wrong is here already |
| **Danger runes written** | You asked for hostility; this is hostility |
| **A site present** | Apexes gravitate to landmarks and ruins — *something is guarding it* |
| **Deep in the map** | **[PROPOSAL]** never near the entry portal. You should have to go in |

**The greed link is the important one.** Writing a greedy world currently costs stability and buys materials. Now it also **draws something**, which makes the decision richer: *do I want what's in this world enough to share it?*

## 4. The drops — rules, not numbers

**A unique weapon should break a rule, not have bigger numbers.** A +3 sword is a crafting tier; a weapon that does something no crafted piece can is a reason to go looking.

**[PROPOSAL] Each apex drops one wild-only weapon**, and each breaks exactly one rule:

| Weapon | Breaks | Why it can't be crafted |
|---|---|---|
| **Two-natured blade** | Carries **two damage types** at once | No material has two dominant armaments |
| **Long fang** | **Far reach** on a close weapon | Reach comes from the haft; this one doesn't |
| **Ranked spear** | Strikes **both ranks** in one blow | Nothing crafted reaches past the front |
| **Barbed Edge** | Landed hits apply one **3 damage / 3 round Severe Bleed** | Ordinary Rend/Briar Oil apply default 2/3 Bleed; the barbs raise severity without a second status |
| **Living hook** | **Grade rises** as you use it | Grade is set by the material at forging |
| **Quiet knife** | Attacking **doesn't break concealment** | Nothing else in Shadow allows it |
| **Bloodletter** | Bleed that **doesn't expire** | Every status has a duration |
| **Warded haft** | Turns aside one damage type **while held** | Wards are a skill, not an object |

**Eight, matching an apex roster of eight.** Each is a sentence a crafted weapon can't say.

**They should not be strictly better.** A two-natured blade with mediocre grade is a real trade against a superb crafted one — **you're buying the rule, not the numbers.**

## 5. The unlucky route

> *"a tiny percent drop chance from normal mobs or locked caches."*

**Same items, vanishingly rare, from two sources:**

| Source | Rough weight |
|---|---|
| **An ordinary creature** | **[PLACEHOLDER]** well under 1% |
| **A locked cache** | **[PLACEHOLDER]** a few percent — caches already cost a key found in another world |

**Why both routes matter:** the apex is the *reliable* path and the lottery is the *surprise*. A player who never fights one still occasionally opens a cache and finds something they can't make — and that's a better memory than a guaranteed drop, precisely because it wasn't earned.

**Weight the lottery toward the world's own character.** Barbed Edge follows defended-flora
affinity, never cold/rime; the complete table is in `apex-hunting-affinities-current.md`.

## 6. What an apex is made of

**Same trait system, different budget.** No new creature model — an apex is `LifeRules` sampling with the budget lifted.

- **Traits drawn far above the world's budget**, so it's large, armoured, well-armed, or all three
- **Its identity still derives** — you meet *a monstrous plated bulwark*, named the way everything else is
- **Butchery yields are exceptional** — its plate is a monstrous plate, because it *is* one. That's the material chain working, not a special case
- **[PROPOSAL] It counts as its own species** in the bestiary, so an apex is a distinct entry rather than a big specimen of a common one

## 7. Where this leaves the loot economy

| Route | Gives |
|---|---|
| **Crafting** | The bulk of your gear. Predictable, property-matched, improvable |
| **Found gear (44 pieces)** | What tides you over before crafting; sites carry the best |
| **Apex drops** | **The eight things you cannot make** |
| **Locked caches** | Keys, curios, and a small chance at an apex weapon |

**Four routes, four different feelings** — made, found, hunted, and stumbled upon. Nothing overlaps.

## 8. Historical questions and current disposition

These were the original open questions. They are retained to show the design's evolution, but are no
longer unowned proposals:

1. **How many apexes?** Eight wild-weapon identities are current; any one world contains at most one
   apex. The apex itself remains trait-generated rather than one of eight fixed boss species.
2. **Do they respawn?** No farming loop. A defeated apex stays absent for the current run, and an
   anchored world must persist that defeat once anchored-encounter persistence exists.
3. **May one guard a named place?** Yes, only for optional treasure/side space. It may never gate a
   required traveller, core clue, sole route or campaign progression.
4. **Does projection reveal it?** No. Pre-bind projection does not reveal apex presence, and the
   minimap obeys ordinary fog/discovery unless the player has invested in an explicit scouting
   effect.
5. **Can writing help hunt one?** World conditions bias the awarded wild-weapon weights after an
   apex is actually defeated. They do not guarantee appearance, disclose it before discovery or
   alter its combat stats. See `apex-hunting-affinities-current.md`.
