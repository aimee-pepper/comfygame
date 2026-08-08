# State of the Build — 7 Aug 2026

**Who this is for:** Aimee, and the designer Claude. A single place to see what exists, what's next,
what's blocked on a decision, and where the whole thing is going.

**Where it sits in the docs:** `BACKLOG.md` is the milestone plan and is authoritative for *what v0
is*. `the-queue.md` is the working list of specced-and-unbuilt. This is the overview above both.

**Numbers as of today:** 639 tests · 94 Swift files, ~25,000 lines · 16 content files.

---

# PART ONE — Where we are

## The one-paragraph version

**The systems are done and the content is thin.** Every major mechanism in the design brief is built
and end-to-end: you write on a page, it resolves into eight pressures, the pressures generate
terrain, plants, animals, sites, resources and people, you walk around in it, fight things derived
from the same numbers, and carry the results home to a base that grows. What's missing is *volume* —
6 travellers against ~28, 1 consumable against 19, 0 crafting recipes — plus a handful of progression
hooks and one whole system (anchoring) that the long-term design hangs off.

## What's built, by system

| System | State | Notes |
|---|---|---|
| **Persistence** | ✅ Complete | Three layers kept separate; atomic debounced save after every action; force-quit mid-encounter resumes exactly. **Still wants one on-device force-quit pass** |
| **The writing system** | ✅ Complete | 6×6 page, polyomino footprints, three hands, target-first grammar with clusters and connectors, order-invariant. 45 focuses, 8 subjects, 17 qualifiers |
| **The pressure model** | ✅ Complete | 8 subjects, dual-valued light and heat, diminishing returns, opposed magnitude tracked gross, cross-target constraints, the energy budget |
| **Worldgen** | ✅ Complete | Seeded; terrain, water, chasms, reachability guarantees, sites, resource nodes, day/night |
| **Creatures** | ✅ Complete | Budget-allocated traits, per-world cast, per-spawn jitter, derived identity and names, combat and loot both derived. No drop tables anywhere |
| **Flora** | ✅ Complete | Trait model, the metabolism axis, growth writing the ground, harvest by tissue, hostile plants |
| **Combat** | ✅ Complete | Party of five, ranks, damage triangle, statuses, gambits, 24 skills, three trees × three branches × eight nodes |
| **The search loop** | ✅ Mechanism, ⚠️ content | Signatures, diary pages, the Library, meeting scenes, recruitment, the Firepit. **6 travellers of ~28** |
| **The base** | ✅ Mechanism, ⚠️ content | 12 stations, found-then-built specialists, 73 research nodes across 8 branches |
| **Analysis** | ✅ Complete | 8 field instruments at Mara's Survey Post, 4 page-lens tiers at Isolde's, gated on what you've measured |
| **Apexes** | ✅ Mostly | The creature, the restraint rules, the greed draw, 8 wild weapons. 5 of 8 weapon rules wired |
| **Crafting** | ❌ Not started | 0 recipes. The material economy that feeds it is done |
| **Anchoring** | ❌ Not started | **The biggest hole.** Blocked on Q-A |

## The last five days, in one line each

- **The greed model was wrong twice and is now right.** It charged you for daylight; then it charged
  the clamped outcome instead of the ask.
- **Writing started at zero instead of at ordinary** — Aimee caught it. A third of the vocabulary
  wrote literally nothing. Fixed, and it was the deepest fault in the system.
- **The party of five actually fights together**, and the Party screen shows the party.
- **Flora, the instruments and apexes** landed this week, in that order.
- **The fossil audit is cleared** — the slot taxonomy is gone, along with everything that only made
  sense inside it.

---

# PART TWO — What's next

## The immediate queue, in order

### 1. The traveller roster — **blocked on Aimee**

**6 of ~28**, and four of the six unlock nothing. This is the single highest-value thing left,
because **the cast is what the search loop is for**. Every mechanism is built: signatures, diary
pages, the Library, meeting scenes, recruitment, found-then-built buildings, starting leans.

**What each traveller needs, and only the first is mine:**

| | Who |
|---|---|
| A condition signature | Claude Code can derive one to a target rarity |
| **A name and a calling** | **Aimee / designer** |
| **A voice — the meeting scene** | **Aimee / designer** |
| **2–4 diary passages** that point at their conditions | **Aimee / designer** |
| A building, or none | Designer — and see the trades list below |
| A starting lean | Claude Code |

**Also needs answering: Q47.** Should a blank book find anybody at all? Right now somebody is present
in roughly half of all blank books, and six characters take ~19 runs to collect without ever reading
a diary. Three levers in `questions-for-design.md`; my lean is that people should stand only in
worlds somebody *wrote for them*.

### 2. Consumables and the Apothecary

**1 exists, 19 are specced** in `crafting-spec.md` PART FOUR. Includes the **Waystone**, the escape
item — a real gameplay hole, since a run that goes wrong currently has no answer but walking.

**Needs first:** Nessa (a traveller who doesn't exist) and the Apothecary building. So this is
partly blocked behind item 1.

### 3. Crafting recipes

**0 exist**, ~60 proposed. The material economy underneath is finished — properties, grades,
qualifiers inherited from the animal or plant they came off. Recipes ask for *properties*, never
item names, so one recipe covers many outputs; the open question is how many recipes that actually
needs.

### 4. Anchoring

**The only thing that makes a world permanent**, and the hinge the whole long-term design turns on.
Blocked on **Q-A**, which has been open since the brief. See Part Four.

## Smaller unblocked things, roughly by value

| | Where | Size |
|---|---|---|
| **Living worlds** — creatures act on each other during a run | `living-worlds-spec.md` | Medium |
| **Building staffing** — posted staff give a discount; in the party, their XP levels the building | `building-staffing.md` | Medium |
| **Compound assembly** + its gate | session 10 §4 | Medium |
| **The Exchange / Recycler** — Vance's, gear back into materials | `merchant-recycler-spec.md` | Medium |
| **Identification becomes knowledge** — N of a kind identified = known forever | | Medium |
| **Movement cost from terrain** — crossing growth costs the same as stone | | Small |
| **Void as a cap** rather than a subtraction | | Small |
| **Count reaching the description** — three suns should say so | | Small |
| **Light/Shadow palette sections**, and the same for Thermal and Vitality | | Small |
| **The vocabulary rename** — `pressure_sources.json` → `focuses.json` | | Small, mechanical |
| **A tutorial** | Nobody's written it | **Large, and overdue** |

**On the tutorial:** the writing system now has four vocabularies, connection, clusters, rotation,
qualifier ladders and a spatial packing constraint. It is not discoverable cold. This isn't scheduled
and probably should be.

---

# PART THREE — What's waiting on a decision

**Nine open questions, and three of them are load-bearing.** Everything here is in
`questions-for-design.md` unless marked otherwise.

## The three that matter most

### Q-A — When does anchoring happen? *(in `open-questions.md`, open since the brief)*

Three candidate designs: anchor at bind, anchor in-world at a discovered site, or anchor
retroactively from base. The doc suggests a hybrid — a cheap in-world **tether** that pauses decay,
with the expensive permanent anchor performed from base. **Tension in the moment, commitment at
leisure.**

**Why it's urgent now:** everything anchoring needs is built. Worlds keep their cast, their flora and
their looted state; the Library remembers every world you wrote. It is one decision away.

### Q47 — Traveller pacing

Should a blank book find anybody? Should placement require the clue in hand? **This sets the pace of
the entire game**, because the cast is the progression.

### Q48 — Should flora and creatures share one world-wide life budget?

Currently two budgets, both scaled by Vitality. **One shared budget would be more ecologically honest
and much more constraining** — a world of enormous animals would have to be a world of thin plants.
I think it's the better design. It also retunes every existing creature number, so it isn't
something to do quietly.

## The rest

| | Question | Cost of getting it wrong |
|---|---|---|
| **Q44** | The authored `stabilityDelta` values are 3–4× the emergent ones and were tuned for the old formula — retire them? | A greedy book is charged twice |
| **Q49** | Three apex weapon rules need decisions before wiring; and should the strongest apexes require worlds you deliberately *write* toward? | Three items are inert |
| **Q19** | Do sites move the Stability headline? Built, tested, deliberately switched off | Guarded by a test now, so it can't drift |
| **Q37** | The full list of crafting trades — Tannery and Apothecary specced and unbuilt | Blocks consumables |
| **Q-B/C** | Sustain economy for anchored worlds; the Reality reset | Both downstream of Q-A |
| **Branch depth / point income** | 8 nodes and 1/level are proposals — they set the level cap at 25 | Rebalance, not rework |
| **Small ones** | Whether animals use the combat trees · Kindling's name · Adamant carrying both endgame *and* anchoring · whether Glass is a resource or quartz serves · the Long Instruction's price now it applies to five people | |

---

# PART FOUR — The long-term build plan

## The shape of the game, as designed

Four loops, nested:

1. **Write a world** → bind → explore → harvest → come home. *Built.*
2. **Spend what you brought** on being able to bring more. *Built.*
3. **Find people**, who unlock buildings, which unlock what you can make and learn. *Mechanism
   built, cast missing.*
4. **Keep a world.** Anchoring turns a disposable run into a permanent place. *Not built.*

Loop 4 is the one that turns this from a good roguelike loop into the game the brief describes, and
it is the one thing entirely blocked on a decision.

## Where the three progression axes stand

The brief's whole thesis is **literacy, not inventory** — you get better by knowing more, not by
carrying more. Three axes carry that:

| Axis | What it is | State |
|---|---|---|
| **Vocabulary** | What you can say. 45 focuses of ~85 specced | ✅ Working, ⚠️ half-authored. Learned from research, sites and caches |
| **Page space** | What you can fit. The page **never grows** — better hands say the same things in less room | ✅ Complete |
| **Analysis** | What you can *read*. 8 field instruments + 4 lens tiers | ✅ Complete as of today |

**All three are now real.** Analysis was the one with no door into it for weeks; it has one now, and
the gate on it — *the lens only shows what you've been out and measured* — is the best single rule in
the game's progression.

## A proposed order for what's left

**Phase 1 — Fill the cast** *(blocked on Aimee)*
The roster from 6 toward ~28, in batches. Each traveller is a signature, a voice, diary pages and
usually a building. Answer Q47 first, because it decides how many worlds a player writes per person
found.

**Phase 2 — The making half**
The Apothecary and Tannery, consumables, then crafting recipes. Everything underneath is done: the
material economy, properties, grades, the Blacksmith's reforging. This is where the resources you
haul finally become things you chose to make.

**Phase 3 — Anchoring** *(blocked on Q-A)*
The tether, the anchor, the sustain economy, and what a permanent world does that a disposable one
can't. Anchored worlds keep their cast and their flora already.

**Phase 4 — Living worlds, and depth**
Creatures acting on each other, predation, per-building research trees, the Tavern and other
people's travellers passing through.

**Phase 5 — Teach it**
The tutorial, and a pass over discoverability. Realistically this should start earlier than fifth.

**Ongoing, in parallel**
Content volume — focuses toward 85, sites past 7, consumables, recipes — and the device-testing pass
on the numbers that can only be settled by playing: map size, day length, viewport, and the
stability→turns curve.

## What would worry me if I were the designer

1. **The cast is the bottleneck for everything.** Three of the four remaining phases route through
   travellers, because buildings hang off people. Six people is not enough to test whether the search
   loop is fun.
2. **Nothing has been played end-to-end for long.** 639 tests prove the systems agree with
   themselves; they don't prove a run is enjoyable. The numbers most likely to be wrong are the ones
   only playing can settle.
3. **Anchoring has been open since the brief** and the game is now built right up to its edge.
4. **The tutorial debt is compounding.** Every good thing added to the writing system makes the cold
   start harder.
5. **There is no failure state worth the name.** Running out of health ejects you home with half a
   haul. That may be exactly right for a comfy game — but it should be a decision, not a default
   nobody revisited.

---

## Appendix — content census, 7 Aug 2026

| | Built | Specced | |
|---|---|---|---|
| Focuses | **45** | ~85 | The vocabulary |
| Subjects | 8 | 8 | Complete |
| Qualifiers | 17 | ~25 | |
| Resources | 23 | 23 | Complete |
| Items | 56 | — | 52 gear · 2 curios · **1 consumable** · 1 key |
| Skills | 24 | 24 | Complete |
| Combat tree nodes | 72 | 72 | Complete |
| Research nodes | 73 | — | Across 8 branches |
| Sites | 7 | — | Thin |
| **Travellers** | **6** | **~28** | **The bottleneck** |
| Contradictions | 9 | — | |
| Description clauses | 50 | — | Every one reachable, by test |
| Stations | 12 | — | |
| Consumables | **1** | **19** | **The other gap** |
| Crafting recipes | **0** | ~60 | |
