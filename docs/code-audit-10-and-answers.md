# Code Audit #10 + Answers Q39–Q41 (2026-08-06, commit `837d4a2`)

476 tests. **Format change at Aimee's request: each question is stated before its answer**, so she can judge the question as well as the response.

---

## Part 1 — Audit note

The traveller meeting scene is built, and **the bug it fixed is worth naming**: arriving in a world matching someone's signature silently marked them "found" in the save. Aimee built a forge for a smith she'd never seen. The system worked exactly as written — finding a person was a condition check rather than an encounter.

Otherwise unchanged from audit #9: **skills still 2 of a specced 12** (the biggest imbalance in the game), pressure sources 41 of 79, session 17's stats and levels not yet in.

---

## Q39 — Meeting a traveller: three calls inside it

> **His question, in brief.** Travellers now stand on a tile, and walking onto them opens a written scene. Three judgement calls, all his, all cheap to change: **(1)** recruiting costs nothing — finding them is the cost; **(2)** declining leaves them standing there, so the world takes them like any other tile — "I'll come back for them" is a bet, not a plan; **(3)** once found they stop being generated, so a matching world doesn't have them in it any more.
>
> **Plus:** they're currently placed anywhere passable a minimum distance from the entry. He'd rather they were *somewhere that made sense* — a smith beside a landmark, an archaeologist at a ruin — and wants a ruling on whether that's a **preference or a requirement**.

**1, 2 and 3: agreed, all three.**

Recruiting costing nothing is right — writing their world *is* the price, paid in the game's core currency. Declining leaving them exposed makes the offer a real decision rather than a formality, and it fits the finality rule: nothing *completed* is lost, and declining isn't completing.

**4. Placement — a strong PREFERENCE, not a requirement.**

A smith beside a landmark is much better than a random tile. But as a **requirement** it creates a failure mode: a world that satisfies someone's signature but happens to generate no suitable site silently can't host them, so a correctly-written world just doesn't work. Same shape as the marooning bug — right in the common case, dead end in the uncommon one.

**Place them at a fitting site when one exists; fall back to the current rule when none does.**

### Wants — the split Aimee has now made

> Context: `companions-classes-spec-v2.md` §3 gave named companions "wants" that must be satisfied before they'll join. Q39's call #1 says recruiting costs nothing, which conflicts.

**Aimee's ruling, 6 Aug:** *"finding the targets with diaries can cost nothing, but maybe random companions and companion animals can generate in worlds and those can be recruited via wants."*

The split is by **how you came to them** — and it's the opposite of what I'd specced:

| | How you find them | Cost to recruit |
|---|---|---|
| **Named / diary travellers** | You **hunted** them — deduced a signature from pages and wrote your way there | **Nothing.** The hunt was the price. |
| **Random companions** | You **stumbled** on them in a world written for other reasons | **A want** — bring, find, show or reach something |
| **Animal companions** | Stumbled on | **A want**, plus taming |

**This is better than my version.** The people you worked to find cost nothing more; the people you got for free cost something. `companions-classes-spec-v2.md` §3 needs updating to match.

---

## Q40 — Should every building own its own research tree?

> **His question.** Aimee suggested every building be upgradeable with its own skill tree. Currently there's one tree at the Workshop — 5 branches, 39 nodes. He thinks it's right and not merely a reorganisation, because **(a)** it answers Q37 by itself (capacity is what a tanner knows, so that branch belongs at the Tannery), **(b)** it makes session 12 true rather than nearly true — right now you find the smith and then buy everything she knows from a generic menu that predates meeting her, and **(c)** it finally gives building tiers a job.
>
> **Three risks he wants ruled on:** what the Workshop is *for* afterwards · whether it gates progression behind finding people · five doors instead of one.

**Yes. Build it. His three leans are all correct.**

**What the Workshop is for — his first option.** It keeps the writing-side branches and becomes *the place you get better at writing*. Clean identity, and the right split: **everything you learn yourself lives at the Workshop; everything you learn from a person lives with that person's building.** Writing is the Binder's own craft, not a trade someone else brings.

**Gating — state his lean as a rule:** *every building's tree has its first rung or two available at the Workshop from the start.* Finding the person **accelerates and deepens; it never unblocks.** A player stuck at 16 storehouse slots because a four-condition tanner hasn't turned up would read as the game being broken, not as a consequence.

**Five doors — the Base-screen summary is the right fix.** **[PROPOSAL]** a station row shows an affordable-now count, so the Base screen answers "where should I go" at a glance without becoming a shop.

**One addition:** a building's **tier should gate its tree's depth**, which is the job `maxTier` has never had.

---

## Q41 — The Exchange: four things before building it

> **His question.** The merchant spec is mostly buildable as written. Four calls he'd rather not make alone: **(1)** how gold-the-resource becomes gold-the-currency; **(2)** whether the Exchange buys gear or only the Recycler handles it; **(3)** whether to build bulk-sell-by-grade-band; **(4)** confirmation that stock refreshing "on run completion" means returning home, not binding.

### 1. Gold — and what "minting" meant

**Terminology first, since I used it without explaining.** A *mint* is where coins are made. **"Minting directly"** would mean gold ore converts straight into currency at the Exchange — hand over ore, get coin, by a special rule that exists only for gold. **The alternative** is that gold ore is simply *sold* like any other resource, at a much higher price.

Both produce the same outcome: a gold-rich world makes you rich. The difference is whether gold is **mechanically special** or **just valuable**.

**His lean, which I agreed with: sell at a large multiple.** No special case in the code, same economic effect, and *"write a gold world"* is still a real play. **Now that the term is explained, Aimee may want to re-decide** — minting is more evocative and makes gold feel like a different kind of thing.

### 2. Does the Exchange buy gear? — **YES** (Aimee, correcting me)

I said no. **That was wrong.** Aimee: *"the exchange absolutely does buy gear, that's the way you can get gold for it, otherwise you can only get resources from recycling."*

The two halves aren't competing, because **they pay in different things**:

| Building | Take gear, receive |
|---|---|
| **Exchange** | **Gold** |
| **Recycler** | **Materials**, at their original grade |

So every unwanted piece is a real decision: currency now, or the right material later. Without Exchange gear-buying, gear could only ever become materials — a much poorer choice.

### 3. Bulk-sell by grade band — **build it, with his safeguard**

Selling forty hides one at a time is not a game. His naming safeguard is exactly right: *"14 hides, crude and plain. Your best is not in this."* Stating what's about to leave **and** confirming what's staying turns a dangerous convenience into a safe one.

### 4. Stock refresh — **on RETURNING HOME.** Confirmed.

Not on binding. Binding is repeatable at base, so refreshing on bind is a rerollable slot machine; returning home is a completed run. And he's right that anything else is a wall-clock timer in costume.

### 5. The Trader's meeting scene is Aimee's — voice, like the other five.

---

## Priority unchanged

1. **Skills 2 → 12** — still the biggest gap; session 17's classes need them to mean anything.
2. Session 17: stats, levels, ranks, escape item.
3. Per-building trees (Q40).
4. The Exchange.
