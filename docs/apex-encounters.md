# Apex Encounters & Wild-Only Weapons

**Implementation status, 8 Aug 2026:** the encounter generator, risk draw and consent rules are
built. Five weapon rules work; three are inert, the locked-cache lottery is missing, and several
open clauses require review. See `apex-system-audit.md`.

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
| **Approach is the commitment** | Stepping adjacent starts it. Nothing else does |

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
| **Barbed edge** *(placeholder; replaces Rimed edge)* | Applies legacy bleed **without a coating** | Coatings are consumed; this isn't |
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

**[PROPOSAL] Weight the lottery toward the world's own character**, so a cold world's rare drop is the rimed edge. It should feel like it came from *there*.

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

## 8. Open

1. **How many apexes** — eight proposed, one per weapon.
2. **Do they respawn?** *(Leaning: a world holds one, and an anchored world's apex stays dead once killed — otherwise an anchored world becomes a farm.)*
3. **Should an apex ever guard a named place?** It would make arriving somewhere hard-won mean more.
4. **Do they appear in the pre-bind projection?** *(Leaning: **no** — like sites, silhouette only once met. Knowing one is there removes the choosing.)*
5. **Should the strongest apexes require specific world conditions**, so hunting one means *writing* toward it — which would make apex hunting a use for the writing system rather than a thing that happens to you.
