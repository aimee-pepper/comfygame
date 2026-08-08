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

## Q23 — The danger-rune stability cap breaks "the number on the symbol is the number on the meter"

`contradiction-danger-spec.md` §5 proposes capping each danger rune's stability gift so stacking six
can't make an arbitrarily greedy world safe — the Mystcraft precedent, where the scorched/lightning
bonus applies once. That's clearly right in intent: without a ceiling, the release valve becomes a
cheat code.

But it is the **only** place a symbol stops moving the meter by exactly its printed number, which is
a ruling and not a proposal.

**Shipped:** capped at a total of 40 (`Tuning.Danger.maximumStabilityGift`), with the shortfall shown
on its own line in the preview — *"Danger runes can only buy so much time: −N of what they offer."*
That's the same discipline §3 already requires for the contradiction escalation term, so there's
precedent for a disclosed non-linear term.

**Worth knowing: the cap cannot currently bite.** All seven runes live in the `quirk` slot and a book
has one of those, so no book today can write two. It is future-proofing for the page, where several
runes will fit. If that bothers you, the honest alternative is to drop the cap until the page exists
and the problem is real.

**Also worth knowing:** stacking still *broadens* the danger — hazards, per-turn damage, spawn
counts and tiers all accumulate normally. Only the stability gift is bounded, which is what §5 asks
for ("stacking should broaden the kinds of danger rather than multiply the stability gift").

**The one real cost:** the projection's stability range is computed by summing per-slot extremes,
which is exact *because* stability is additive. A cap makes it non-additive, so once several runes
can be written the range has to learn about the cap or the preview will promise a floor it doesn't
honour. There's a test that catches this (`testEveryPossibleRandomFillLandsInsideTheProjectedRange`)
and it will start failing the moment the page allows two runes — which is the right time to fix it.

## Q24 — The energy budget can price a creature out of the worlds it belongs to

Found while wiring pressures into generation, and worth knowing before the creature catalogue grows.

**The chain:** darkness caps vitality (the light cap in `WorldConstraints`), vitality pays for the
energy budget, and the budget decides what a world can afford to feed. So a creature that *prefers*
dark worlds is, by default, excluded from them — the Margin Wraith liked the dark and could never be
afforded there, because the dark is poor.

**Fixed by making the wraith cheap** (appetite 3, below everything else), which is right for a thing
that's barely there. But the interaction is general and will bite again: **any creature authored to
like a condition that suppresses vitality has to be cheap enough to survive its own preference.**

Three ways to handle it as the catalogue grows, none of which I've picked:

1. **Author around it** — as now. Cheap things like poor worlds. Simple, and it means appetite
   quietly encodes "how marginal is this", which is a real and readable idea.
2. **A creature's requirements exempt it from the budget** — if a thing *needs* the dark, the dark
   affording it is assumed. Loses the square-cube discipline the budget exists for.
3. **Fungal-style exemptions on the budget itself** — vitality isn't the only currency; a
   scavenger's budget could come from `decaying` rather than from productivity. Closest to the
   biology the pressure model already models, and the most work.

The invariant that must hold either way, and now has a test: **a world always holds something.** A
world too poor to feed anything still spawns the cheapest thing in the catalogue, because empty for
reasons the player can't see is worse than sparse.

## Q25 — Cold worlds make *smaller* animals, because cold worlds are poor

Found while building the trait distributions. Two pressures pull on size in opposite directions and
one of them wins:

- **Cold nudges size up.** Bergmann's rule — bigger bodies lose heat more slowly. It's in the spine
  spec's table.
- **Cold caps vitality.** Light and water caps mean a cold world is usually a poor one, and
  productivity is what pays for size.

Poverty is currently the stronger term, so a glacial world's animals come out *smaller* than a
volcanic one's, which is the opposite of what the table implies.

**This may be correct.** Bergmann's rule is about endotherms in places that can still feed them; a
frozen desert genuinely shouldn't grow anything large. If so, nothing needs changing and the spec's
table just needs the caveat.

**Or the thermal nudge is too weak** against the vitality term, and cold should win where there's
anything at all to eat.

Left as-is, and the test asserts only the unconfounded half — cold shortens extremities and thickens
covering. Not papered over with a test that picks convenient worlds, because the confound is the
interesting part.

## Q26 — Ornament and finish define each other; I cut the loop one way

`creature-system-spec.md` §2 describes the relationship from both ends: `ornament` is "derived from
finish brightness and iridescence", and `finish` "feeds `ornament` cost". Those two together are a
circle — each is computed from the other and neither has a starting value.

**Cut as: allocation spends budget on `ornament`, and `finish` follows from what was spent** (plus
pressure shifts — a mineral world shines, a volatile one goes iridescent). That's the only reading
where the costly axis is the one that costs, which is what §4's budget model needs.

The other cut — finish is free, ornament is read off it — would make costly signalling free, and the
whole point of ornament being a costly axis is that only a rich world can afford to advertise.

Say if it's backwards and I'll turn it round; nothing else depends on the direction.

## Q27 — Colour needs more than a CMY triangle, so I added two axes

The spec's pressure table asks for **pale**, **dark**, **countershaded** and **maximally
contrasting** colorations. A CMY triangle normalised to sum 100 carries hue and nothing else — it
has no room for how dark or how patterned a thing is, and crypsis and aposematism are both claims
about exactly those.

So `Coloration` is the triangle **plus** `depth` (pale ↔ near-black) and `patterning` (flat ↔
banded). Both are free axes, both shaped by pressures, neither costs budget.

Flagging because it's an addition to a spec structure rather than an implementation of one. If the
intent was that hue alone should carry it, the crypsis and aposematism branches need rewriting.

## Q28 — The naming vocabulary is voice, and it's yours

`name-generation-spec.md` §8.5 asks whether the word lists are yours to write. They're in
`Sources/Model/Naming.swift` as `Axis.low` / `Axis.high` — about seventy words across fourteen axes,
tagged PLACEHOLDER.

**The mechanism doesn't care what any of them say.** Replace every word and nothing else changes:
the axis a creature is named for, the collision handling, and the inheritance into materials are all
independent of the vocabulary. Two things worth knowing before rewriting them:

- **Order matters within a band.** Each list runs mildest → strongest, and how far a creature sits
  from its world's average decides which one it gets. `["great", "vast", "monstrous"]` must stay in
  that order.
- **An empty list means "not worth naming in that direction."** `ornament` has no low words, because
  being *less* decorated than average isn't remarkable — the absence is the default. Same for
  `nonVisual` and `emanation`.

I also lengthened two of the spec's words: *close* and *stub* became *short-limbed* and
*stub-limbed*, because "close grazer" doesn't read as English.

## Q29 — Should the composed fallback keep its own adjectives, or take the qualifier?

A creature that matches no identity region gets a composed name — *huge blind armoured walker*. A
creature that matches one gets *[qualifier] [kind]* — *sable grazer*.

Those are two different naming schemes, and a composed name is longer and more specific than a
matched one. Right now a composed name keeps its own words and hands its *first* word to its
materials, so a *small shape* drops a *small hide* rather than a word that appears nowhere in its
name.

It works, but the two schemes sit oddly next to each other in a list — *sable grazer* and *huge
blind armoured walker* don't read as the same kind of thing. Which may be exactly right (§8.3 says
the unmatched ones are the animals players remember) or may want the composed names shortened to
two words to match.

## Q30 — Relief has no words of its own, and I borrowed seven rather than invent any

Relief had **no sources attached to it at all**. Its bin was empty on screen, so the shape of the
land was the one thing in the pressure model you could not write about — with nothing in the UI to
say why.

`attachesTo` is now a **list** rather than a single target, because some causes genuinely belong to
more than one: a volcano is a heat source and a mountain, a glacier is water and a valley. Relief
borrows seven that already contribute to it — *canopy · glacier · granite · marsh · river · sand ·
volcano*. There's a test now that every target has something you can write about it.

**But Relief still has no words of its own**, and it wants some: *mountain · canyon · plain · dune ·
terrace · scarp*. Inventing source runes is adding to the core vocabulary, which isn't mine to do.
Say the word and I'll add whichever of those you want.

## Q31 — Should greed read a target's aspects, or only its magnitude?

Stability now reads **greed from abundance** — how far past a target's baseline you asked it to go.
It reads the target's *magnitude* only.

It does not read **aspects**. So writing Sand on Relief costs nothing, because sand *flattens*
(−10 relief) even though it pushes openness to +25 — you asked for a wide open plain and were
charged for nothing. Same for hydrology's dispersion, atmosphere's motion, cycle's amplitude.

Two readings, and I've taken the first:

1. **Magnitude only** (as built). Aspects describe *what kind* of a thing a world has rather than
   *how much*, and only how much is greed. Simple, and the number stays workable-out-able.
2. **Aspects count too.** An extremely open world or a wildly swinging one is asking for something
   real, and charging nothing for it means whole axes of the vocabulary are free.

Worth deciding before the aspect-heavy sources get written, because it changes what they cost.

## Q32 — A lone cluster can resolve to nothing, and the meter correctly says nothing happened

Writing *Vitality ← Bloom* on an otherwise empty page produces **no life at all**, so it costs no
stability. That's the cross-target constraints working: illumination's baseline is 0, no light means
no life, and the cap zeroes it.

The model is right. The *experience* may not be — you wrote a bloom and the world says nothing
happened, and nothing on screen explains that it's the dark that stopped it. The Life line does say
"Nothing lives here", which is a hint but not an explanation.

Flagging rather than fixing, because the fix is a design choice: either the preview names the
constraint that bit ("nothing grows without light"), or it doesn't and learning it is the game.

## Q33 — Only the companion can carry a weapon, so the matchup only half reaches the player

Combat depth §1 is built: weapons carry a damage type, pierce and crush beat hard coverings, rend
beats thick soft ones, and the encounter prints what a creature is wearing so the matchup is a read
rather than a guess.

**But `equipped` lives on `CompanionState`.** The Binder has no gear slots at all — its attack is a
flat `Tuning` constant. The brief puts gear on the Party screen and the Binder is half the party, so
I've read the equipped weapon as **the party's**: both of them fight with what's in Quill's slots.
That makes the matchup reach the player's own attacks immediately, and it adds no structure.

It is a reading, though, and the alternatives are yours:

1. **As built** — one weapon, the party swings it. Simple, and "which weapon am I carrying" stays a
   single decision rather than two.
2. **The Binder gets its own slots.** More faithful to "power comes from gear", and it doubles the
   loot that matters — but it's two weapons to think about on a phone, and the Binder's attack has
   been a constant since the first build.
3. **Gear stays the companion's** and the Binder is deliberately unarmed. Then the matchup only
   ever applies to Quill's automated turns, and §1 gives the player nothing to decide — which is
   the thing the whole spec exists to fix.

## Q34 — I have not built ranks, and the spec is unsure about them too

`combat-depth-spec.md` §3 proposes two ranks — front takes the attacks, back is reachable only by
far reach or area delivery, swapping costs a turn. §7.2 calls it "the piece I'm least sure of" and
notes that everything else in the spec reads traits that already exist while ranks are a new
concept.

**Left unbuilt deliberately.** Everything else in §1–§4 is in: damage types and the matchup, reach
on weapons, bleed from rending, retaliation from warning colours, elemental attacks that armour
doesn't stop. Ranks would be the first thing in the fight that isn't derived from something a
creature or a material already is.

If you want them, it's a contained piece of work. If you don't, say so and I'll strike §3 from the
spec so it stops looking outstanding.

## Q35 — Rarity decides how far a piece can be reforged, and that's my call

`materials-crafting-spec.md` §7 asks for **upgrading over replacing** and doesn't say where it
stops. It has to stop somewhere, or a common blade reforged eight times catches a mythic one and
finding a mythic stops being worth anything.

**Built:** rarity sets the ceiling — common +1, uncommon +2, rare +3, mythic +5
(`Tuning.Smith.maximumLevelByRarity`). So rarity means two things at once: where a piece starts,
and how far it goes. A mythic ends at tier 9, a common at tier 2.

Alternatives if you'd rather:

1. **As built.** Rarity is the ceiling. Finding a mythic stays a real event.
2. **A flat ceiling for everything** (say +3). Simpler to explain; makes a common piece you like
   genuinely viable late, at the cost of rarity mattering less.
3. **No ceiling, rising costs only.** The curve does the limiting. Most generous to attachment —
   the blade you started with can go all the way — but the numbers have to carry all the weight.

## Q36 — Each slot is judged by one property, and I picked which

§5 says recipes ask for properties. For reforging I needed a mapping from slot → property, and
chose one that gives every property a job so no part of the hoard is universally junk:

| Slot | Property | Reading |
|---|---|---|
| Weapon, Off-hand, Head, Body | hardness | it has to hold an edge or stop one |
| Hands, Feet | flexibility | armour you still have to move in |
| Tool | density | mass is what works hard ground |
| Keepsake | lustre | the singular things |

`SmithRules.workingProperty(for:)`, all PLACEHOLDER. Insulation and reactivity currently have no
slot — they're waiting on the Tannery and the Apothecary.

## Q37 — The Tannery and the Apothecary are specced and unbuilt

§6 names three crafting buildings. **Only the Blacksmith is built**, because it's the one with a
job that stands alone: reforging. The other two are specced around things that don't exist yet —
the Tannery makes "satchel and storehouse upgrades", which the Workshop research tree already
sells, and the Apothecary makes consumables and inks, which are barely a system yet.

Rather than ship two dead buttons I've left them out and built the *mechanism* generally: a station
with `builtBy` in `stations.json` is found-then-built, so adding either is a JSON edit plus a
screen. **The question is whether the Tannery should take capacity upgrades off the Workshop** —
if it should, that's a real move of an existing system and I'm not doing it unilaterally.

## Q38 — A world written for life is barely alive — **ANSWERED AND FIXED (Aimee, 6 Aug)**

> *"a world with verdant and teeming life should be crawling with flora and fauna. effectively
> sterile shouldn't be anything near that."*

Three separate things were doing it, and it turned out **not** to be mainly the consumers I blamed
below. Measured over the same 200 seeds:

| | before | after |
|---|---|---|
| median vitality | 8 | 29 |
| effectively sterile | 40% | 5% |
| species in the cast | 3 | 4 |
| **animals standing in the world** | **5** | **10** |
| the same book, but ash-choked | 4 | 1 |

1. **Light was a hard cap, not a change of metabolism.** A target you didn't write gets rolled from
   the seed, plenty of illumination sources are occluding, and a dark roll took the cap to nearly
   zero — so what you *didn't* write silently voided what you did. Dark now keeps
   `Tuning.Pressure.darkLifeFraction` of what you wrote and turns it **fungal**, which is the
   metabolism answer the designer already gave for Q24, arriving ahead of flora. The preview says
   it out loud: *"What lives here eats rather than grows."*
2. **Usable water went to zero the moment a world froze over**, which killed the other quarter.
   Deserts and ice sheets are sparse and hardy, not sterile, so dryness keeps `dryLifeFraction` —
   less than darkness does — and tags the world `hardy`.
3. **Population was measured against a vitality of 100 that nothing reaches.** Stacking falloff
   means the strongest life book the vocabulary can write lands around 55, so every world read as
   half-dead. `Tuning.World.teemingVitality` is the yardstick now, and the population term runs
   from a fifth of the base to three times it instead of 0.5→1.5.

**Consumers are life too**, which was the original diagnosis and is still right, just smaller:
`herd` and `swarm` went from −5 and −8 to +12 and +8, keeping their `trophicDepth` push. A world
crawling with herds is not less alive than an empty one.

**Still open for you:** whether `teeming_life` should expand to producers only, with the consumers
getting their own symbol. The numbers work now either way; it's a question about whether a symbol
should contain its own opposition.

<details>
<summary>The original write-up, kept for the reasoning</summary>

### A world written for life is barely alive, and it's the sources doing it

Measured while wiring up the expanded resource catalogue, over 200 seeds on a book that says
**plains + verdant + teeming_life** — as direct a request for life as the vocabulary allows:

| | vitality peak |
|---|---|
| lowest | 0 |
| **median** | **8** |
| highest | 92 |
| below 3 (effectively sterile) | **40% of worlds** |

The cause is in `pressure_sources.json`, not in anything I've built:

```
teeming_life → bloom (great) + herd (moderate) + swarm (faint)
   bloom  vitality  peak +20   producing
   herd   vitality  peak  −5   consuming   (trophicDepth +30)
   swarm  vitality  peak  −8   consuming   (trophicDepth +20)
```

**Two of the three sources a symbol called Teeming Life expands to are consumers**, and their
negative peaks eat most of the producer's. As a model of a food web that's honest — consumers do
take from producers, and they're what deepens the web. As a *symbol* it doesn't do what it says.

**Not fixed unilaterally**, because the source vocabulary is design. Three ways out, all yours:

1. **Consumers stop suppressing the total** — they add `trophicDepth` and take nothing off `peak`.
   Vitality then reads as "how much is here" and trophic depth as "how complex it is", which are
   two different questions and arguably should be.
2. **`teeming_life` expands to producers only**, and the consumers get their own symbol. The
   food-web model survives; the symbol stops arguing with itself.
3. **Raise the producers** so the net clears. Smallest change, but it leaves a symbol whose parts
   pull against each other for anyone reading the data later.

This is wider than fibre. Vitality feeds the creature cast, butchery, flora when it lands, and
every organic resource — so a median of 8 is very likely part of why play reads samey (audit #8 §3).

</details>

## Q39 — Meeting a traveller: what I built, and the three calls inside it

Aimee, 6 Aug, in three messages: *"finding a traveller should mean actually running across the
person as an entity on a world you find them in"*, *"they need to be only generated on a map that is
appropriate to where their sought world location parameters are"*, and *"there should be a text
interaction where you recruit them."*

**Built.** They stand on a tile, well away from the way in. Walking onto them opens a written scene
— an opening line, questions you can ask, and an offer. Agreeing is what writes them into the
Library and raises their building. The signature gating was already exactly what she asked for:
`LibraryRules.travellersPresent` only returns people **every one of whose conditions holds** in that
world, so nobody turns up anywhere that isn't theirs.

**The bug this fixes:** arriving used to mark somebody found, silently, in the save. Aimee built a
forge for a smith she had never laid eyes on and asked, reasonably, when she had met him. The answer
was "when you bound a world with a hot ductile substrate, and nothing told you."

Three calls inside it, all mine, all cheap to change:

1. **Recruiting costs nothing.** Finding them is the cost — you had to write their world. Adding a
   price would make the search loop pay twice.
2. **Declining leaves them standing there**, and the world will take them like any other tile. So
   "I'll come back for them" is a bet, not a plan. The alternative is that they persist across
   worlds, which is kinder and much less interesting.
3. **Once found they stop being generated**, so a world matching Halloway's signature after you have
   Halloway just doesn't have him in it. Otherwise the fifth meeting is a chore.

**Also worth your attention:** they're currently placed anywhere passable at least
`Tuning.World.travellerMinimumDistance` from the entry. It would be better if they were *somewhere
that made sense* — a smith beside a landmark, an archaeologist at a ruin. That's a `sites.json` join
and I'd like a ruling on whether it should be a preference or a requirement.

## Q40 — Should every building own its own research tree? **[AIMEE'S IDEA, and I think it's right]**

Aimee, 6 Aug: *"maybe all the buildings should be upgradeable and have their own skill trees?"*

**What exists now:** one tree at the Workshop, five branches, 39 nodes — Instruction (12), The Hold
(15), The Bargain (7), Penmanship (3), The Hand (2). Every station has a `tier` and a `maxTier`
already, and only the Storehouse's tiers actually do anything, bought from the Workshop's Hold
branch.

**Why I think this is the right shape and not just a reorganisation:**

1. **It answers Q37 by itself.** Q37 asks whether the Tannery should take satchel and storehouse
   capacity off the Workshop. If a building owns the branch about it, the question stops being a
   judgement call: capacity is what a tanner knows, so The Hold lives at the Tannery. Same for The
   Bargain moving to the Exchange the moment `merchant-recycler-spec.md` is built.
2. **It makes session 12 true instead of nearly true.** *"You don't research a smithy, you find a
   smith"* is currently half-implemented: you find the smith, and then everything you learn from her
   is bought from a generic Workshop menu that existed before you met her. A person bringing their
   own tree is what makes recruiting one feel like anything.
3. **It gives the building tiers a job.** `maxTier` is 1 on almost everything and nothing reads it.
   A building's own tree is the obvious thing tiers should gate.

**Three real risks, and I'd want your call on each:**

- **What is the Workshop for afterwards?** If every branch goes to a building, the Workshop is an
  empty room. Options: it keeps the writing-side branches (Penmanship, The Hand, Instruction) and
  becomes specifically *the place you get better at writing*, which is a clean identity; or it
  becomes the tree for the base itself. **My lean: the first.**
- **It gates progression behind finding people.** Audit #9 already flagged this for skills-from-
  companions. If The Hold moves to the Tannery and the tanner is a four-condition signature, a
  player can be stuck at 16 storehouse slots for a very long time through no error of their own.
  **My lean: every building's tree has its first rung or two available from the start elsewhere, so
  finding the person accelerates rather than unblocks.**
- **Five doors instead of one.** Today "what can I buy" is one screen. Afterwards it's a tour.
  Worth a single "what can I afford right now" summary on the Base screen — which the station rows
  are already the right place for.

**What I'd build if you say yes:** `ResearchBranchDef` gains a `station` field, the Workshop shows
only its own branches, every other station shows its own, and the whole thing is a `research.json`
edit plus one field. The tree UI is already per-branch and would need no rework. It's a small change
for something quite structural, which is usually the sign of a good one.

## Q41 — The Exchange: what I need before building `merchant-recycler-spec.md`

The spec is good and mostly buildable as written. Four things I'd rather not decide alone:

1. **Gold is currently a resource in `resources.json`, gated on a rich ductile substrate.** §2 wants
   it to be the currency as well, with gold ore worth far more than other minerals or minting
   directly. Minting directly is more evocative and makes one of twenty-three resources structurally
   unlike the rest. **My lean: it sells at a large multiple rather than minting** — same economic
   effect, no special case in the code, and "write a gold world" is still a real play.
2. **Does the Exchange buy gear, or only the Recycler handle it?** (§6.3.) If the Exchange buys
   gear, the Recycler is competing with it from inside the same building.
3. **Bulk-sell by grade band** (§6.4) is genuinely needed — selling forty hides one at a time is not
   a game — but it's the single easiest way to sell something you meant to keep. **My lean: build
   it, and make it name what it's about to take** (*"14 hides, crude and plain. Your best is not in
   this."*).
4. **Stock refreshes on run completion** (§3) — confirm that means *returning home*, not *binding*.
   Anything else is a wall-clock timer wearing a costume, and pillar 2 forbids it.

**Not blocking:** I can build selling, bin-level selling and the Recycler against the leans above and
change any of them in an afternoon. What I can't do is invent the Trader's meeting scene — that's
voice, same as the other five in `travellers.json`.

## Q42 — Burn, freeze and shock: three statuses or one? — **THREE (Aimee, 6 Aug), and built**

> *"q42 is 3 for sure."*

**Built as three — but as the three this game actually produces**, which is the one place I read
past the audit's wording. `EmanationKind` has exactly three cases and they're generated onto real
creatures; toxicity is a separate flag. Burn and freeze and shock would have been *two effects with
nothing in the game making them*, which is the same bug as an inert qualifier, one layer down.

| Status | Produced by | What it does |
|---|---|---|
| **Burn** | a **heat** emanation | short and hard, through armour |
| **Poison** | a **caustic** emanation, and touching anything toxic | slow, long, and armour never helped |
| **Dazzle** | a **light** emanation | costs you your accuracy rather than your health |

Poison from toxicity is the one that closes a loop: warning colours were already honest — hitting
something that advertises costs you — and now what it was advertising is venom.

**Ward was widened to match.** It guards a `Harm`, which is a blow *or* an emanation — six things
rather than three. That's what makes setting one a decision, and what makes spending a round on
Sight first worth doing. With nothing stated it guards the likeliest incoming harm, and **an
emanation wins over a blow**, because nothing you wear stops one.

**If you want freeze and shock**, they need producers first — a cold or electric emanation on the
creature side, which is a `CreatureTraits` change and yours to call.

## (original question)

Audit #11 §3 is right that this is the real gap, and it names the fork exactly. **Producers exist
and effects don't:** `emanation` is a generated creature trait that appears in descriptions; toxic
flora is specced; Apothecary coatings are specced. An emanating creature currently bypasses armour
and says *"sears"*, and that's the whole of it — nothing lingers.

- **One `elemental` status carrying its element.** Simpler, one code path, reads fine.
- **Three distinct statuses.** More work, but **Ward has something specific to turn aside**, which
  is the thing that makes Ward worth a round instead of a bigger heal.

**My lean: three**, and only because of Ward. The skill set is built on "every skill answers a
specific kind of creature", and a Ward that turns aside *elemental* in general is exactly the
good-against-everything shape the spec warns about. Three gives it a real question — you saw it
sear, so you ward against burn.

**Not blocking:** I'll build whichever you say. If you say nothing I'll build three and it's an
afternoon to collapse them.

## Q43 — Isolde's signature, and the one thing that could deadlock a save

`hands-and-calligrapher-spec.md` makes the Calligrapher **required**, which I've built exactly as
written — Penmanship lives at the Scriptorium with **no free rungs**, no Workshop fallback.

That makes her the one character who can wedge a game, so I've built the three safeguards §3 asks
for and turned them into tests that will fail if anybody breaks them later:

1. **Her world is writable in charcoal.** Two conditions, common vocabulary — a bright-floored,
   thin-aired world. The test measures against the *actual* crude footprints, so re-authoring the
   shapes re-checks it.
2. **She's named in more than one diary.** Her own two location pages, plus Tovin mentioning her —
   *"Isolde taught me. Whatever you think of my handwriting, it was worse."* One unlucky page
   distribution can't hide the character the game insists you meet.
3. **The block says who, not what.** A locked Penmanship node reads *"Isolde hasn't been found"*
   rather than greying out.

**What I'd like you to check:** her two conditions are `illumination floor ≥ 35` and `atmosphere
peak ≤ 45` — a world that never gets properly dark, with thin still air. That's deliberately
writable early, but it's also a *specific* pair, and if the starting vocabulary can't reach one of
them the gate closes. Worth your eye on whether the passages point at the right targets, which is
§3.3 of the feedback spec.

## Q44 — The greed fix landed, and it makes the authored deltas the whole meter

`greed-formula-fix.md` is built: two axes, a `neutral` per subject separate from its baseline, and
a heavier weight on Substrate and Vitality. Aimee's complaint is fixed —

| Focus | Was | Now |
|---|---|---|
| **Sun** on illumination | **−25** | **−2** |
| Gold on substrate | −18 | −5 |
| Granite on relief | −4 | **+2** |
| Salt on vitality | — | **+14** |

A sun is a slight excess rather than an outrage, a mountain is nearly free, and a dead world is a
gift. §3's predictions all hold.

**But §6.4's open question is now the live one, and I have numbers for it.** Measured over three
real books:

| Book | Authored `stabilityDelta` | Emergent greed | Score |
|---|---|---|---|
| Plains · Verdant · Sparse Ore · Dim Sky | **+22** | +25 | 100 |
| Plains · Verdant · Rich Ore · Gilded | **−75** | −22 | 3 |
| Caverns · Ashen · Rich Ore · Gilded | **−98** | −32 | 0 |

**The authored numbers are three to four times the emergent ones**, and they were tuned when greed
was the old formula — so a greedy book is now charged twice for the same greed, once by hand and
once by measurement, and both greedy books bottom out at nothing.

§3 says the authored values *"become unnecessary"* and §6.4 lists retiring them as open. **I've not
retired them**, because that's the meter's headline behaviour and it's a design call, not a
refactor. But the two can't both stay at these magnitudes: either the authored deltas go and
stability becomes fully emergent (which is the profiling model, and self-balances as the vocabulary
grows), or they shrink to a flavour adjustment on top.

**My lean: retire them.** The whole argument for the two-axis model is that a focus added next year
is priced correctly the moment it exists. Hand-tuned deltas are exactly what stops that being true.

### One thing I did differently from the spec, on purpose

§3 says *"the baselines are the actual bug"* and proposes moving them. **I added a separate
`neutral` instead and left the baselines alone**, because `baseline` is what a subject reads with
nothing written about it — physics — and it feeds the whole world model: terrain, life caps,
creature budgets, descriptions. Moving illumination's from 0 to 45 would mean an unwritten world is
*mid-lit*, which is a much larger change than the meter fix and would need its own round of
measuring.

`neutral` is judgement — what an ordinary world has — and it's the thing greed should measure
against. They genuinely differ: a world with no light source really is dark, and an ordinary world
really does have a sky. **Say if you want the baselines moved as well** and I'll do it as its own
piece, with the numbers first.

### **ANSWERED (`answer-q44.md`), and the answer led somewhere much larger — see Q45**

Both halves are built. The eleven greed deltas are gone, the seven danger ones live on
`danger.stabilityTrade`, and `SymbolDef.stabilityDelta` is **deleted rather than zeroed** so "no
authored greed" is enforced by the compiler instead of by memory. `DangerTests` asserts it against
the raw JSON as well, because the field would come back one day for a reason that seemed good.

Greed is now charged on **everything a book says, compounds included**. That had to follow: with the
authored numbers gone, a compound that isn't priced by its expansion is priced at nothing, and Rich
Ore would have become free. Writing *Rich Ore* and writing out *great iron, gold* are now the same
world at the same price — they were 45 and 8.

**On the two things you asked me to re-check:** they still balance, and I'd have got that wrong by
eyeballing it. The cap is +40 against a greediest writable book of −100. Before any of this it was
+40 against −98. One danger rune is still paid in full; six still hit the ceiling. **No rescale.**

---

## Q45 — Writing started at nothing, not at ordinary, and a third of the vocabulary did not exist

**[AIMEE, 7 Aug, and she is right]** — *"the entire issue is that the starting point of writing is
0 rather than neutral."*

This is the thing under Q44, and neither of us had it. I was measuring what the numbers *did*; the
question that would have found it is **what does a subtractive word do when there is nothing beneath
it?**

**33 of 97 authored contributions are subtractive** — occluding, suppressing, draining, flattening,
sinking, thinning. Readings clamp at zero, and four subjects started at zero. So subtraction from
nothing was nothing:

```
WRITES illumination: ash=0 canopy=0 cloud=0 miasma=0 mist=0 rain=0 smoke=0 void=0 · stars=4 … sun=55
WRITES vitality:     ash=0 miasma=0 salt=0 sulfur=0 wildfire=0 · swarm=8 … canopy=35
```

**Thirteen focuses wrote literally nothing** when written on their own. `canopy` is authored to
shade light by 35 and did nothing. `salt` suppresses life by 25 and did nothing. *A salt flat where
nothing grows* was not a sentence the vocabulary could say — you could only decline to mention life.

**And it is where the hand-typed numbers came from.** Dim Sky is `cloud, great`, which resolved to
**0**, and carried `+12` to pay for it. The constants were propping up a broken floor, which is why
they looked necessary right up until the floor was fixed.

### What changed

`baseline` **is** the ordinary value now, and a page says how a world *differs* from an ordinary one.
Your §3 table was right all along — it was the floor that was wrong. Illumination 45, Thermal 50,
Hydrology 40, Substrate 30, Relief 35, Vitality 40, Atmosphere 50, Cycle 50.

Three consequences worth your eye:

1. **The floor needed a floor.** An unremarkable world is lit by day and dark by night, and one
   number can't say both, so dual-valued subjects carry a separate `baselineFloor` (illumination 0).
   Without it a sun's floor contribution is zero *because a sun sets*, so every night was noon.
2. **Greed bills the demand, not the reading.** Peaks clamp at 100 far more often now, and a world
   riddled with veins would otherwise cost the same as a merely rich one.
3. **`neutral` survives as an optional override and nothing sets it.** Your "physics and judgement
   should not share a number" argument was right in general and its premise doesn't hold here: once
   writing starts at ordinary, the two coincide. The field is there for the subject that ever needs
   them apart.

**Aimee's correction to me, which I had wrong and is worth recording:** this does *not* make an
under-specified world plain. Subjects nobody wrote about are still rolled from the whole pool. It
makes an **undeviated** world plain, which is the point of ordinary — and a void world is one you
write with negative focuses.

### Measured, before and after

| | before | now |
|---|---|---|
| Sparse Ore | +10 authored, −1 measured | **+8** |
| Common Ore | 0 authored, −4 measured | **−4** |
| Rich Ore | −45 authored, −8 measured | **−21** |
| Gilded Veins | −30 authored, −18 measured | **−32** |
| a world written dead | unwritable | **+27, and it holds 2 animals against 14** |

### Two things I decided, and would like overruled if they're wrong

- **Substrate and Vitality carry a greed weight of 1.8 and 1.5** against everything else's 0.35 —
  about five to one, which is where the two-axis model's *value* half lives. Set by measuring until
  the six outcomes your §3 promises came true, not by taste.
- **Verdant now costs about −20.** It was hand-typed as free. Aimee's *"a verdant lush world slowly
  scales up destabilization"* says it shouldn't be, so I let it cost — but it does mean the old
  calibration table's *Plains · Verdant · Ore · Dim Sky = 100* is now 75.

---

## Q46 — Three subjects could only ever be asked for *more* of, and I have authored five words

**[AIMEE, 7 Aug]** — *"if no source subtracts then we've been building this wrong from the start"*
and *"author the missing words."*

Once the floor moved I measured which subjects could be written downward at all. **Substrate and
Cycle could not** — every focus touching them raised them. So Sparse Ore was a *greedy* choice, and
"Reliable as a clock" was a sentence with nothing to trigger it.

**Authored, all `[PLACEHOLDER]`:**

| Focus | Subject | What it says |
|---|---|---|
| **Chasm** | Substrate ↓30 | More hole than floor. Aimee asked for this one by name |
| **Silt** | Substrate ↓18 | Sorted fine and washed through. Nothing hard left in it |
| **Stillness** | Cycle ↓35 | Nothing turns. Your own standout in `cycle-sources-draft.md` |
| **Tide** | Cycle ↑, regularity ↑ | The world moves to a pull |
| **Orrery** | Cycle, regularity ↑↑ | A great clockwork, still running |

**Sparse Ore expands to Silt now**, so it means what its name says. **Common Ore is faint iron**
rather than moderate, so the ladder has a middle: below, at, above.

Chasms are real ground — impassable, per Aimee. Pathing is guaranteed two ways: holes are bridged
until most of the solid ground is walkable-to, and *nothing is placed outside the reachable region*,
which also fixes an older bug where a site could land on a shoal behind deep water. At **maximum
chasm the world has no exit portal** and you leave the way you came, exactly as she described — read
off what was *written*, never the chance fill, so a rolled focus can put holes in your world but
can't close the door behind you.

### What I'd like from you

1. **The rest of the Cycle list.** Your draft's open Q1 asks how many ship; I took Stillness, Tide
   and Orrery because you named them the tightest, and left Drift, Pulse, Procession, Breath,
   Cascade, Echo and Unwinding alone. **Drift** is the obvious fourth.
2. **Are Chasm and Silt the right two words for poor ground?** They're mine, and the vocabulary is
   yours.
3. **Relief, Hydrology and Atmosphere each have exactly one or two subtractive words.** They work,
   but they're thin — a subject you can only really write upward is the fault we just fixed, in
   slower motion.

---

## Q47 — You meet everybody far too easily, and progression has no pace

**[AIMEE, 7 Aug]** — *"82% of blank book worlds containing a traveller is too high. we need there
to be game progression."*

She's right, and I measured it while chasing the firepit bug. **Writing nothing at all — a blank
book, which is what a new player binds while learning — put somebody in front of you in 82% of
worlds.** Median run to first meeting: **1**. Median runs to have met all six: **19**.

The search loop is the spine of the game: read a diary, work out what world its author was standing
in, write that world, walk up to them. At these rates you don't do any of that. You bind whatever
and people are simply there.

### Where it came from, and the part I've already fixed

One character accounted for most of it. Isolde was in **67%** of blank books; everybody else was
9–25%.

| | clue 1 | clue 2 | overall |
|---|---|---|---|
| Isolde | `relief ≥ 18` (ordinary **35**) — 87% | `substrate ≥ 30` (ordinary **30**) — 76% | **67%** |
| Mara | `illumination ≥ 60` (ordinary 45) — 25% | | 25% |
| Sela | three clues, 41–63% each | | 16% |
| Halloway | `thermal ≥ 60` — 48% · `substrate.hard ≥ 35` — 27% | | 11% |
| Edren | `substrate.hard ≥ 35` — 28% · `thermal.floor ≤ 25` — 27% | | 9% |
| Tovin | four clues, 32–67% each | | 9% |

**Both of Isolde's thresholds sat at or below her subject's ordinary value**, so *"There is something
in the rock that holds a light"* was true of any world with ordinary rock in it. That is a defect
rather than a pacing choice, and it is mine twice over: I set those numbers when relief and
substrate started at **0**, and moving the floor to ordinary (Q45) emptied them without touching the
file. **Fixed** — `relief ≥ 55`, `substrate ≥ 55`, which is what *"stone above, stone below"* and
*"something in the rock"* actually describe. She lands at **26%**, and the two guards that stop her
deadlocking a save — writable in charcoal, holds through 18 of 20 rolls — are both still green.

**A guard now covers the whole class**, because I had already missed this once in the other
direction: `ReachableContentTests` asserts every signature clue is true of between 1% and 85% of
worlds, and that nobody stands in more than 40% of blank books. A clue that is always true is as
dead as one that is never true, and only the second kind is visible.

### What's left is yours, because it's pacing

Even fixed, the numbers are **Isolde 26%, Mara 25%, Sela 16%, Halloway 11%, Edren 9%, Tovin 9%** —
so *somebody* is present in roughly half of all blank books, and six characters take about 19 runs
to collect without ever reading a diary.

**Three levers, and I don't think this is my call:**

1. **Clue count.** Tovin needs four conditions and lands at 9%; Mara needs one and lands at 25%.
   The cheapest lever, and the most legible to the player — more clues means more diary pages to
   find, which is the loop working.
2. **Should a blank book find anybody at all?** The strongest version of the search loop is that
   people only stand in worlds somebody *wrote for them* — signatures tight enough that chance
   almost never satisfies them. That makes every meeting earned, and makes the diary pages
   load-bearing rather than a hint system you can ignore.
3. **Should finding them need the clue in hand?** Right now a traveller is placed whenever the
   world matches, whether or not you've read a page naming them. Gating placement on
   `knownTravellers` would mean the diary is genuinely how you find people, and the world you wrote
   by accident holds nobody.

**My lean is 2 and 3 together**, with 1 as the tuning underneath — but progression pace is the
thing the whole game's shape hangs off, so I've changed nothing beyond the broken thresholds and
left the rest here.

---

## Q48 — Flora: three calls I made building it, and the one I'd most like back

**Context.** The terrain half of `flora-system-spec.md` is built: the trait model, metabolism,
growth writing the ground, harvest by tissue, and defended flora. Three of the spec's own
"what I'd want challenged" items had to be answered to build it at all. I took the conservative
reading each time and they're all cheap to reverse.

### 1. §9.5 — one ground type with a hidden property, or two? **Two.**

`growth` now means *tall enough to hide something* and a new `groundcover` means *you can see over
it*. The spec proposed one type with stature deciding sight-blocking; two is what shipped, because
a hidden property on `growth` would also have quietly reinterpreted every tile in every save that
already had one — a world in progress would have changed its sightlines under the player.

**The cost:** the ground vocabulary is one word longer. **The gain:** an overgrown world reads at a
glance, on the map and the minimap, without the player having to learn an invisible rule.

### 2. §9.3 — does a plant that attacks you belong in the creature system? **Both, and neither is a
copy.**

An active-defence plant is *grown* by the flora system and *fought* by the creature system: its
combat vector is derived from its flora traits, so there is no second combat model and no second
loot table. What the map adds is one flag — it is rooted where it stands. Waking it means it is
ready, not that it is coming, which is what keeps it a hazard you walk *into*.

**Measured:** 12 of them across 150 generated worlds, so about one world in twelve holds one. The
spec asked for rare and that's rare.

### 3. §9.4 — should flora draw from the same budget as creatures? **No, for now.**

They have separate budgets, both scaled by Vitality. One shared world-wide life budget split between
producers and consumers would be more ecologically honest *and* more constraining — a world of
enormous animals would have to be a world of thin plants — and I think it's the better design. I
didn't do it because it changes every existing creature-budget number at once, and rebalancing the
whole animal cast is not a thing to do quietly inside a flora commit.

**This is the one I'd like an answer on.** If you want it, it's a small change to
`GrowingConditions.budget` and `WorldTendencies.budget` plus a retune.

### And one thing I changed that you should know about

**Chemosynthesis lifts both life caps.** A world lit by nothing and floored in sulfur used to be
capped twice over — once for darkness, once for dryness — for two reasons neither of which applies
to something eating basalt. It now keeps all the life it was written with and says
*"whatever grows here is eating the rock."*

Fungal darkness deliberately does **not** get that exemption: `darkLifeFraction` already keeps most
of a dark world's life and tells you it grew mushrooms, and exempting damp-and-dark outright would
have erased the difference between *writing* Fungus and happening to roll a dark world. Writing the
word should be worth something.

**Measured across 150 worlds:** 54 photosynthetic, 48 fungal, 43 chemosynthetic, 5 that can make no
living at all. The last of those is the state the metabolism axis exists to make reachable, and it's
about 3% of worlds — rare, and writable on purpose.
