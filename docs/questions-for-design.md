# Questions for Design — from Claude Code

> **STATUS:** **Q1–Q10 answered** in `decisions-log.md` §§ Session 2–3. Kept for the record; see `engineering-notes-session-2.md` and `-session-3.md` for what was built from them.

Ambiguities hit while building. Each one has a **conservative interpretation already shipped**, so
nothing is blocked; answering just tells me whether to keep or change it. Answers belong in
`decisions-log.md` (newest entries win).

Format: question → what I shipped → where it lives in code.

---

## Milestone 1 (2026-08-04)

### Q1. Which layer owns the encounter-flag registry (the bestiary)?
The brief requires "encountered" flags per creature/resource type from milestone 1, but doesn't say
which persistence layer holds them.

**Shipped:** the **Reality** layer — knowledge is Pokédex-like, and a future base reset taking away
"you have seen this creature" feels like erasing the player's history rather than the character's
possessions.

**If the answer is Base:** move `discovery` from `RealityState` to `BaseState`. Nothing else changes.
`Sources/Model/Discovery.swift`, `Sources/Model/RealityState.swift`.

---

### Q2. The starter collection is labelled 10 symbols but lists 11.
`design-brief-v0.md` heads the list "Starter collection (10 symbols)" and then names eleven:
3 terrain (Plains, Caverns, Archipelago) + 3 biome (Verdant, Ashen, Frostbound) + 3 bounty (Sparse
Ore, Rich Ore, Teeming Life) + 2 quirk (Dim Sky, Gilded Veins).

**Shipped:** all **11** named symbols — dropping one to hit the count would silently remove content
you named explicitly.

**If it should be 10:** say which one starts locked and I'll flip its `acquisition` to `research`.
`Sources/Content/Data/symbols.json`.

---

### Q3. What does a station "tier" count?
The brief says the Storehouse starts at 8 slots, "+4 per Storehouse upgrade (3 tiers tonight)".

**Shipped:** tier = **upgrades purchased**, so tier 0 is the built, un-upgraded station.
Storehouse 0→3 gives 8 / 12 / 16 / 20 slots, i.e. three purchasable upgrades.

**Alternative reading:** "3 tiers" means three states total (8 / 12 / 16, two upgrades).
`Sources/Content/Data/stations.json`, `Tuning.Economy`.

The same question applies to the Essence Spring, where the brief says "Tier 1 built-in; Tier 2
upgrade purchasable". Shipped as: tier 0 = the built-in trickle, tier 1 = the one purchasable
upgrade. Amounts are PLACEHOLDER (3 and 7 essence per return).

---

### Q4. Do Motes bank straight into the Reality layer?
Motes are the Reality-layer currency but they're picked up inside a world, which means a mote sits
in a run's satchel — a Worlds-layer object — until banked.

**Shipped:** on banking, motes go to `reality.motes` while everything else goes to `base.resources`.
An unbanked mote lost in a collapse is lost like any other haul.

**Open sub-question:** should motes be exempt from collapse loss, given they're the permanent-layer
currency and the brief's sources for them (locked caches, Mythic drops) are already rare? Related to
Q-F in `open-questions.md`, which I'm not touching.
`Sources/Debug/HarnessActions.swift` (`bank`).

---

### Q5. Working title and bundle identifier.
**Shipped:** target/product `Bookbinder`, bundle ID `com.aimeepepper.bookbinder`, display name
"Bookbinder". The brief says rename freely — say the word and it's a one-line change in
`project.yml` plus `xcodegen generate`. (Renaming the bundle ID resets the save file on device,
since Documents is per-bundle-ID.)

---

### Q6. Is there a cap on the run satchel?
Resources are stackable and slot-free, but *items* found in a world need somewhere to go, and the
brief only gives an inventory size for the Storehouse at base.

**Shipped:** the run satchel carries its own item capacity, currently copied from base capacity at
depart time. A full satchel refusing loot mid-run is a real design moment (do you drop something?),
so this shouldn't stay accidental.
`Sources/Model/WorldsState.swift` (`WorldRun.satchelItems`).

---

## Milestone 2 (2026-08-04)

### Q7. How much does the preview reveal about slots left to chance? **(the interesting one)**
Two locked rules pull against each other. "Legibility before commitment" says show the player what
they're buying. "Empty slots are random-filled — under-specification is a surprise" says don't.

**Shipped:** an unfilled slot turns every headline number into a **range**. A book with all four
slots empty reads "Stability 53–100 · holds ~17–104 turns · tier 1–4 · cost 19–28". Fill a slot and
the ranges narrow; fill them all and they collapse to exact numbers. You always know the bounds
you're signing up for; you don't know where inside them you'll land. The harvest/inhabitant mixes
show *expected* shares rather than ranges, because a column of ranged percentages is unreadable.

A test (`BookRulesTests.testEveryPossibleRandomFillLandsInsideTheProjectedRange`) checks 200 seeds
to prove no actual bind can escape the range the player was shown.

**The sub-question I'd most like answered:** the player is currently **charged for symbols they
didn't choose**. "Cost scales with total symbol value" reads as including random fills, and the
bind button quotes the worst case up front — but "you must be able to afford up to 28 for a book
you didn't specify" may feel like a tax on under-specification, which is meant to be playful. The
alternative is that random fills are free, which makes leaving slots empty strictly cheaper and
turns under-specification into the budget option.
`Sources/Rules/BookProjection.swift`, `Sources/Screens/PreviewPanel.swift`.

---

### Q8. What does the Reality unlock's 5th book slot actually hold?
"+1 symbol slot in books" is one of the three Constellation nodes, but the slot taxonomy is exactly
four kinds (Terrain / Biome / Bounty / Quirk). A fifth slot has to be *something* — a second quirk?
a free choice of any kind? a new kind entirely?

**Shipped:** nothing. `RealityState.bonusBookSlots` exists and is not yet read by the book model,
which still has exactly four slots. The node is unpurchasable until milestone 5, so this isn't
blocking — but the answer changes `BookDraft` from a fixed four-key structure into an ordered list,
which is easier to do before there are saves in the wild.
`Sources/Model/BaseState.swift` (`BookDraft`), `Sources/Model/RealityState.swift`.

---

## Milestone 3 (2026-08-04)

### Q9. Is the entry portal a way out?
The brief gives the entry portal at the edge and "exit portal (always ≥1, revealed on discovery)"
as separate things, without saying whether the entry works in both directions.

**Shipped:** the entry is also an exit, *and* every world generates 1–2 more portals elsewhere. So
retreating the way you came always works, it just costs the turns to walk back — and the further in
you push, the more that retreat costs.

**The tenser alternative:** one-way entry, so you must find an exit or be caught. That makes the
first portal you find a genuine relief and turns a bad roll into a real emergency. It also means a
run can strand you, which cuts against sleep-friendliness.
`Sources/Rules/Worldgen.swift`. Also asked in plain language as Q6 of questions-for-aimee.md.

---

### Q10. What happens to loot that won't fit when you bank it?
Resources are slot-free, but items aren't, and the Storehouse has a fixed slot count.

**Shipped:** items that don't fit when a run banks are **lost silently**. In practice this can't
happen yet (items only start dropping in milestone 5), but it will the moment curios exist, and
"your rare drop evaporated on the way home" is a bad thing to discover by accident.

Options: refuse to bank and make the player choose; overflow into a temporary spillover the
Storehouse holds until sorted; or auto-convert to essence. This wants an answer before milestone 5.
`Sources/Rules/GameActions+World.swift` (`bankHaul`).

---

## Milestone 4 (2026-08-04)

### Q11. What limits a Skill?
The brief gives each party member Attack, **Skill (1 each)**, Item and Flee — but no resource to
spend on a skill, and v0 has no MP. With no limiter at all, Skill is strictly better than Attack
every single turn, and the action bar stops containing a decision.

**Shipped:** a **cooldown counted in rounds** (never seconds). The Binder's Unbind is 2 rounds, the
companion's Mend is 3. It has a nice knock-on: a gambit whose skill is on cooldown falls through to
the next rule, so cooldowns are exactly what make rule *order* matter.

Alternatives if you'd rather: once per encounter; a shared party resource that regenerates per
round; or charges that refill on returning home (which would tie combat to the run economy).
`Sources/Content/Data/skills.json`, `Tuning.Encounter`.

---

## Session 4 (2026-08-04) — writing system & named places

Full reasoning in `engineering-notes-session-4.md`. These three are the ones I can't pick a
conservative default for, because each default forecloses something.

### Q12. Is a named place the same *instance* every time, or the same *recipe*?
Persistent Reinehaven (fixed seed + state that survives visits) vs. a fresh world generated from a
fixed signature each time. The first makes named places effectively pre-anchored worlds and needs
somewhere in the save for per-place state; the second fits the current disposable-world model
exactly. I lean persistent, for named places only.

### Q13. What is "precision", numerically?
Proposal: require both **distance** (your pressures near the place's signature) and **coverage**
(you actually named enough of its defining conditions). Distance alone lets a vague page arrive by
luck; coverage alone ignores whether you got it right. Together they give the three-tier behaviour
session 4 asks for — resembles it / is it / somewhere else.

### Q14. Do sigils rotate when placed?
Unaddressed in the spec, and it changes the packing puzzle a lot. Default I'd take: free rotation.

---

## Answered by the spec, no longer open

- **Q11 (what limits a Skill)** — still open; unaffected by session 4.
- **Q7/Q8 (slot pricing, fifth slot)** — dissolved by the writing-system redesign. Unwritten targets
  cost the flat cheap rate, which is the same rule, now expressed in the new vocabulary.

---

## Session 5 addendum

### Q15. "Ore" is a twelfth starter symbol
Aimee's correction: the bounty slot needs a neutral middle rung, because stability tracks *deviation
from what a world would naturally have* — Sparse Ore asks for less and calms a world (+10), Ore asks
for the baseline and costs nothing (0), Rich Ore asks for more and destabilises (−45).

That required a symbol that didn't exist. **Shipped:** `common_ore`, display name "Ore", as a
starter — a ladder whose middle rung is missing teaches nothing. That makes twelve starters against
the eleven named in the brief (Q2).

Say if it should be researched rather than granted, and I'll move it.

### Q16. Does a chance-filled symbol teach you anything?
Chance now draws from the **whole** pool, so a slot left open can hand you a symbol you've never
learned — that's what makes under-specification a surprise rather than a shuffle (Aimee's
correction). But using one doesn't currently grant it.

**ANSWERED (Aimee, 2026-08-04): no.** Using a rune does not teach it to you. You write the world,
you don't learn the word — vocabulary stays something you research or find, never something you
back into by leaving a slot open. Keeps deliberate study meaningful, and keeps a chance-fill a
gamble rather than a shortcut.

Shipped as-is; no change needed.
`Sources/Rules/BookRules.swift` (`candidates` vs `writable`).

---
## Q17 — Do sites grant a separate research currency, or essence?

`docs/sites-system.md` §2 lists "research points" among a site's contents. The shipped economy has
no such currency: research nodes cost **essence plus resources**, and nothing else.

**Shipped, conservatively:** a site's `essence` field grants essence outright.

### What's actually at stake

Essence is currently doing two jobs. It's the **go-again** currency (it buys the next book) *and*
the **get-better** currency (it buys research nodes). So every point spent on research is a book you
didn't write. That's either a good tension or a bad one, and which it is depends on how you want
research to feel.

There's also a structural problem with sites specifically. **If sites give the same things resource
nodes give, sites are just big nodes.** A Crystal Cavern that pays out ore is a rich vein with extra
steps. What makes a site a different kind of object is that it gives a different *kind* of reward —
and right now Wayfarer's Camp hands you fiber and essence, which is exactly what the ground does.

### The options

1. **Essence only (status quo).** One currency, one number, and a real opportunity cost. The
   research DAG already gates progression, so nobody rushes the tree just because they're rich.
   Cost: sites stay flavourful nodes.
2. **A separate Insight currency, spent only on research.** Research stops competing with play, and
   sites get a reward identity nothing else has: *nodes give you materials, sites give you
   understanding*. This is the one that makes a site worth walking to with a full satchel — which
   feels like the property you actually want, given sites are meant to be destinations.
   Cost: a new number on the Base screen, and a new thing to balance.
3. **Differentiate by category instead of by currency.** No new currency. Landmarks and living
   sites pay in materials (they're places, and places have stuff); **ruins pay in knowledge** —
   symbols, compounds, diary pages — and never in currency at all. The distinction is carried by
   what kind of site it is rather than by a new resource.
   This is the cheapest, and it lines up with `narrative-systems-spec.md`: pages teach compounds,
   old ruins are where rune knowledge lives. Knowledge is *already* a non-currency reward track.

**My read:** 3 is the strongest for the least new machinery, and 2 is the strongest full stop if
you're happy adding a number. 3 also has a nice consequence — it means a ruin is never a
disappointment because you were rich already, which is a failure mode 1 has.

## Q18 — Should the pre-bind preview show which sites a world can host?

`docs/sites-system.md` §6.3 leans yes-as-silhouettes, matching the creature preview rule.

**Shipped:** it doesn't. Sites are a surprise you walk into.

### Why the obvious answer is a trap

The creature preview silhouettes creatures you haven't met, so consistency says do the same here.
But creature mix and site presence aren't the same shape of information. Creature mix is a
probability distribution over the whole world — "paper moth, 40%" tells you the texture of the
place. Site presence is discrete and usually singular, and "Binder's Workshop: possible" is
enormously more actionable.

Which runs straight into what sites are *for*. From §4:

> Writing toward a condition set is writing toward a *kind of place*, which is why deduction from a
> sensory clue works.

If the desk lights up a site's name when its conditions are met, that deduction collapses into a
fiddle-until-it-glows checklist. You'd never read a clue again — you'd just permute symbols and
watch the panel. The thing the whole system exists to enable is the thing a site list would kill.

But saying nothing has its own failure: a player could reasonably conclude sites are pure random
scatter and never learn they're condition-gated at all. Then the deduction loop never starts either.

### The option that isn't on the doc's list

**Describe the world, not its contents.** The pressure model already derives what a world is *like*
— `WorldConstraints.character(of:)` computes ambush-vs-pursuit, wet-cold vs dry-cold, arid syndrome,
two-niches, iridescence-enabled, and the constraint pass tags things `frozen-over`, `barren`,
`light-limited`, `thermally-buffered`. That's a qualitative sentence about the world, and it's
already computed, tested, and shown nowhere.

So the desk says: *"Frozen over. Enclosed, layered stone. Little light, and what lives here doesn't
need it."* And the clue in your hand says she wrote about a vault under cold stone. **You match a
description to a description.** That's deduction — you're reading the world, not watching a
checkbox — and it teaches the conditions themselves rather than the answers.

Then, separately: **once you've found a site, it silhouettes in the preview thereafter.** That's the
discovery-log pattern already in use, and it means knowledge earned by exploring pays off in
authoring, which is the direction this game's progression should run.

### The options

1. **Nothing** (status quo). Preserves surprise, risks nobody learning sites are gated.
2. **Silhouettes when eligible.** Doc's suggestion. Most legible, collapses the deduction loop.
3. **Describe the world qualitatively; silhouette only sites you've already met.** Preserves
   deduction, teaches conditions, rewards exploration, and the descriptive half is already built.
4. **3, plus a bare count** — "this world can hold 2 features you haven't seen." Tells you there's
   something to find without telling you what.

**My read:** 3, and 4 if playtesting says people aren't noticing sites exist. The world-description
panel is worth building either way — it's the only place the pressure model becomes visible to the
player, and right now a world's entire climate and character is invisible.

## Q19 — Should sites move the Stability headline?

**Shipped:** they don't. `SiteRules.stabilityDelta` is built and tested and one line from being
switched on in `WorldRun.effectiveStabilityScore`.

### The collision, precisely

Your ruling, session 5:

> *"adding .2 to stability and seeing it go up a weird number is unhelpful"*

which became: a book starts at 100, and a symbol reading −25 moves it to 75. **The number printed on
the symbol is the number on the meter.** No conversion factor, no hidden term.

`sites-system.md` §5, tagged `[PROPOSAL]`:

> High-value sites (crystal caverns, intact old ruins) add to total world value and therefore to
> greed instability. Writing toward treasure destabilizes, exactly as writing toward rich substrate
> does.

Sites are rolled at bind from the seed. So switching this on means the meter shows a number no
symbol on the page accounts for — the exact complaint that prompted the rebalance. In practice a
world can take two Tears and a Crystal Cavern and lose 32 points nobody chose. When I had it on, it
was collapsing worlds inside five steps.

### The thing underneath, which is bigger

§0 of the same doc carries an audit correction that goes further than §5:

> Profile everything the generated world actually contains against a baseline and charge instability
> on the excess — the Mystcraft approach, and self-balancing as the content catalog grows.

That's not "sites subtract points." That's **instability should be derived from what the world
contains, not authored per symbol.** Under it, `stabilityDelta` wouldn't be hand-written on symbols
at all; it'd fall out of profiling the resolved world.

Worth saying plainly: **that correction isn't implemented, sites or no sites.** Symbols carry
hand-tuned numbers that *approximate* value. Nothing profiles what a world actually ended up
holding. So Q19 isn't really "do sites count" — it's **is Stability authored or derived?**

### The options

1. **Sites never touch Stability.** Perfectly legible meter. Cost: a Crystal Cavern is a free lunch —
   concentrated value at no price — which quietly undercuts the greed pillar the game is built on.
   Rich worlds should cost something.

2. **Preview shows it as its own term.** The desk reads:
   `Symbols −18 · The world itself −20 · Stability 62`.
   Your rule survives *literally* — symbols still sum exactly to their printed numbers — and the
   world's charge is a second, visible term rather than a hidden one. Legibility-before-commitment
   holds because you see the real number before you pay.
   **This is already mechanically possible.** `SeedSequence.peekNextSeed()` exists for exactly this
   and is threaded into `BookProjection`; I built and verified it before backing it out.
   Two cautions:
   - It needs memoising. The projection is a computed property SwiftUI may read every frame, and
     this version runs worldgen.
   - **Discipline required:** peeking the seed means the preview *could* know the entire world,
     including your chance-filled slots. It must use that only for aggregate numbers and never to
     reveal composition, or the surprise dies by accident.

3. **Sites cost something that isn't Stability.** A Crystal Cavern doesn't make the world unstable —
   it makes it *guarded*. More enemies, a higher tier, a hazard ring. The meter stays clean, greed
   still has a price, and it composes with machinery that already exists (`enemyTierDelta`, and the
   guardian mechanic sites already use).
   Fictionally this may be the best of the three: the world doesn't object to being rich, but rich
   places have things living in them. It also gives Crystal Cavern and Brood Warren a shared logic.

4. **Go derived, per §0.** Stop authoring `stabilityDelta`; compute instability by profiling the
   resolved world against a baseline. Self-balancing as the catalog grows, which matters a lot given
   how much the catalogs are meant to grow. The preview then shows each symbol's *derived*
   contribution — still exact, still sums, so your rule survives.
   Cost: you lose hand-tuning, which you have just spent real effort on, and it's the largest change
   on this list by some distance.

**My read:** **3 now, 4 eventually, 2 if you want §5 as literally written.** Option 3 gets greed
priced without touching the meter you just fixed, and the fiction is better than the fiction of
option 2. Option 4 is where this ends up if the catalog reaches the size the research passes
imagine — but it should be a deliberate migration, not something that happens under a sites feature.

Option 1 is the only one I'd argue against: it makes finding treasure strictly free, and this game's
whole thesis is that it isn't.

## Q20 — A chance-filled book can roll a world that dies almost immediately — **ANSWERED**

**Aimee, 2026-08-05: leave the rules alone; solve it in presentation.**

> Worlds will get load animations. For a world that would shortly collapse, the animation makes that
> clearly visible. For an instantly-collapsing one, the animation runs with a message along the lines
> of *"the world you entered crumbled around you as you stepped through the portal — you jumped back
> through just in the nick of time."*

Which turns the failure into a scene instead of a number, and it means the gamble stays a real
gamble without the player feeling cheated by an outcome they couldn't read. No rules change: chance
keeps drawing from the whole pool, and the steps curve stays literal at the bottom.

**Implementation notes for whoever builds it:**
- The message implies the player gets *out* rather than dying — so an instant-collapse world needs a
  distinct outcome from a normal collapse: you keep your essence-paid loss, but you aren't caught by
  the partial-haul rule, because there was nothing to haul.
- This wants a threshold in `Tuning` for what counts as "instantly collapsing" (probably
  `turnsAvailable` below some floor), and a second, softer state for "shortly".
- The animation is presentation, so it must not be a timer the simulation waits on — pillar 1. The
  state change happens on the turn; the animation is decoration over an already-settled result.

## Q21 — Chance-filled slots *can* fire assertion contradictions. Confirm that's wanted.

`contradiction-danger-spec.md` §7.2 asks this and leans yes. Now that the catalogue is built, here's
what actually happens, so the ruling can be made against behaviour rather than a guess.

**Negations can never happen by chance.** You have to write a Negate rune, and chance has no rune to
write. The spec's central safety claim for its largest category holds, and there's a test pinning it.

**Assertions can.** One chance-filled slot rolls growing things; another rolls the world dark; *green
in the dark* fires. Nobody chose it. Measured over 200 chance-filled worlds it happens in a minority
of them — a gamble rather than a tax — and there's a test asserting it stays a minority.

**The argument for leaving it:** an assertion contradiction is a statement about the world, and the
world doesn't care who wrote it. It also gives leaving slots open a real, legible risk, which is the
first thing that has made under-specification feel like a gamble rather than a discount.

**The argument against:** the player is charged for a claim they didn't make. Every other penalty in
the game is something you chose.

**Middle option:** chance-fills participate, and the preview *says so* — "what you've left to chance
could contradict what you've written." Warned, not prevented. That fits how the rest of the preview
works, since cost is exact and outcomes are ranged.

**Shipped:** they participate, with a warning not yet built. Tests document it as observed behaviour
rather than a ruling, and name the one to change if this lands the other way.

## Q22 — Two copies of the pressure model are now in `docs/`

`pressure-model.md` consolidates the four `pressure-model-*.md` files, and the four are still there.
Same content, two places. Given CLAUDE.md makes `docs/` the source of truth and the newest dated
entry wins, a stale copy is a real hazard — the next person to update one won't necessarily update
the other.

Suggest deleting the four originals and keeping the consolidated file. Not done, since deleting your
docs isn't my call.
