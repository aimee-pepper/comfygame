# For the designer — what's waiting on you

**Kept current by the implementation engineer.** Everything here is blocked on, or improved by, a
design call. Ordered by how much it unblocks.

Format: **question → why it's blocking → what I've built in the meantime.** Nothing here is
waiting on me; if you answer nothing, all of it still ships with the interpretation noted, and I'll
have chosen conservatively rather than well.

Last updated 6 Aug 2026, after `code-audit-9-and-answers.md` and `backlog-referrals-worked.md`.

---

## 1. Blocking a system that's specced and ready to build

### 1.1 The class set — **the biggest one**
`decisions-session-17.md` §1 decides characters get stats and classes, and says *"the set is
hers."* Five stats are proposed (Might · Finesse · Fortitude · Perception · **Focus**). The hook
you gave is a good one: **a companion's class is what they were before the sundering** — a smith, a
scholar, a hunter, a delver — which ties classes to session 12's "you don't research a smithy, you
find a smith."

**What I need:** the list of classes, and for each one, roughly what they were and how they fight.
Six to eight is plenty. I can derive stat spreads from the descriptions.

**Until then:** I'm building stats and levels without classes, so a companion is a stat block with a
name. That works but it's the flavourless half.

### 1.2 Do the twelve skills belong to *characters* or to the *party*?
`resources-skills-spec.md` §4.5 asks this and doesn't answer it. It matters a lot for the shape of
the code and for how classes read: if skills are per-character, a class is largely *its skill list*
and recruiting a specialist is a real event. If they're a shared pool, classes have to mean
something else.

**My lean:** per character, with a small shared ladder from research. That's what makes a class a
class.

**Until then:** I'm building the twelve skills with an `ownedBy` field that already exists, so
either answer is a data change rather than a rewrite.

### 1.3 The trade list — **and it is also the class list**
`backlog-referrals-worked.md` §6 spots something worth acting on: session 17 ties a companion's
class to what they were before the sundering, and session 12 ties crafting buildings to finding the
person who ran one. **So the list of trades and the list of classes are one list.** Write it once.

Five travellers exist — a surveyor, an archaeologist, a wanderer, a binder and a smith. Each of them
now has a written meeting scene and could plausibly bring a building, a class, or both.

### 1.4 Cycle has no sources of its own
`cycle-sources-draft.md` has eleven candidates waiting on you and I'm holding off because adding
core vocabulary isn't mine to do. The audit's short answer is **Tide, Orrery, Stillness, Drift**.
Cycle is the only target with no primaries, so it can only ever be written about indirectly.

### 1.5 The Tannery taking capacity upgrades off the Workshop — Q37
Audit #9 says yes and flags it as yours. Session 12 decided crafting buildings come from **people,
not research**; satchel and storehouse capacity being research-bought predates that. Moving them
makes *finding a tanner* a moment with a payoff you can feel.

**What I need:** yes or no. If yes, do the existing research nodes disappear, or stay as a cheaper
parallel ladder?

**Until then:** capacity is still bought at the Workshop, and the Tannery isn't built — I'd rather
not ship a dead building.

**Build costs scale with how advanced the trade is** (Aimee, 6 Aug). The Blacksmith is deliberately
early and cheap enough for one good haul; a late building should be several hauls of setup and want
something you can only get out of a world too greedy to hold. The ladder is written into the
`_note` at the top of `stations.json`, which is where you'll be when you add one.

---

## 2. Vocabulary that needs *writing*, not deciding

This is the gap audit #8 §3 found and audit #9 confirms is still the limiting factor: the
generative machinery works and there isn't enough in it. **All of this is authoring — it's your
voice, and I can't fake it.**

| Content | Have | Specced | Notes |
|---|---|---|---|
| **pressure sources** | 41 | 79 | Each one is a thing a world can *be*. The biggest single lever on world variety |
| **rune shapes** | 13 | ≥21 | Fewer shapes than symbols, so some runes have no glyph of their own |
| **qualifiers** | 17 | 51 | Session 14's rule cuts that number a lot — how far? |
| **description clauses** | 44 | — | Healthy, but every new source wants its own sentence |
| **creatures** | 3 | — | Authored fallbacks only now that worlds grow their own. Do we still want authored ones at all? |

**Relief's own words (Q30)** is part of this and has a concrete proposal already on the table —
*mountain · canyon · plain · dune · terrace · scarp*. Audit's recommendation is to add all six.
It's core vocabulary so I haven't added them unilaterally. **Say the word and they go in.**

**Naming vocabulary (Q28)** is explicitly yours: the adjective bands for creature and material
names, ordered mildest → strongest, where an empty list means "not remarkable in that direction."

**Qualifier ladders**, per `backlog-referrals-worked.md` §1: the seventeen built all pass session
14's rule, so the shortfall is authoring rather than pruning. Still to write — **Colour** (a set,
not a ladder), **Constancy**, **Elevation**, **Direction**. Distribution and Finish are cut, and
correctly.

---

## 3. Newest, and both worth reading first

### Q40 — should every building own its own research tree? *(Aimee's idea)*
I think yes, and I think it **answers Q37 for free**: if a building owns the branch about it, then
capacity upgrades live at the Tannery because capacity is what a tanner knows, and it stops being a
judgement call. It also makes session 12 true rather than nearly true — you find a smith and then
buy everything she knows from a generic menu that existed before you met her.

Three risks written up in `questions-for-design.md` Q40. The one I'd most like your view on: **what
is the Workshop for afterwards?**

### Q41 — the Exchange, before I build `merchant-recycler-spec.md`
Four calls I'd rather not make alone — gold as resource *and* currency, whether the Exchange buys
gear or only the Recycler does, bulk-sell safety, and confirming "refreshes on run completion" means
*returning home* rather than binding (anything else is a wall-clock timer in costume).

**And one thing only you can do:** the Trader needs a meeting scene, same as the five in
`travellers.json`. That's voice.

---

## 4. Open questions with a real fork in them

### Q29 — do composed fallback names stay long?
A creature matching no known form currently gets a long composed name that sits oddly beside a
*sable grazer*. Audit leans **keep them long** — the strangeness is informative. It's voice, so
it's yours.

*(One part of this I'll do either way: a composed name should hand its **most distinctive** word to
its materials, not its first.)*

### Q25 — cold worlds make smaller animals, and you said "test it and adjust"
The test that matters is **cold *plus* productive** — a cold sea, or a cold world with geothermal
warmth and standing water. I'll write that test and tune the thermal nudge against what it shows,
then report the numbers back here. **No answer needed unless you dislike what it produces.**

### Q38 leftover — should `teeming_life` contain its own opposition?
The vitality fix has landed and a written-for-life world is now properly alive (sterile 40% → 5%,
animals 5 → 10). What's left is a smaller question: `teeming_life` expands to producers *and*
consumers. Now that consumers add rather than subtract, that's fine. But **should a single symbol
contain both halves of a food web**, or should consumers get their own symbol so a player can write
"plants but nothing eating them"?

Audit #9 also asked for **a sweep for other symbols whose expansion mixes characters that pull
against each other.** I'll do that sweep and report; if it turns up more, this question generalises.

---

## 5. The hole session 17 opened

`decisions-session-17.md` §7 removes permanent loss entirely for now — companions in unstable
worlds, animal companions, and displaced tethers are all no longer losable. **That was the thing
that made holding a greedy world genuinely expensive**, and §7 flags the replacement as open.

The obvious candidates named there are **resource upkeep** and **dormancy**, both of which already
exist as concepts. This one isn't blocking me yet — anchoring isn't built — but it will be the
moment it is, and it's the kind of question that's much cheaper to answer before the code exists.

---

## 6. Still open from `open-questions.md` (older, and largely still open)

- **Q-A. When does the anchor choice happen?** Marked "the big one" and still unanswered.
- **Q-B.** Sustain economy specifics — now entangled with §4 above.
- **Q-C.** Reality-layer reset: what exactly survives.
- **Q-D.** Symbol vs gambit acquisition economies.
- **Q-E.** Automation vs content scaling.
- **Q-F.** Permanent-loss policy per layer — **superseded** by session 17 §7. Worth deleting.
- **Q-G.** Quirk catalog.

---

## 7. One collision the jargon audit missed

**"Subject" was already taken.** The gambit rule builder has used *Subject* since it was written,
meaning *who a rule is about* — a foe, an ally. `vocabulary-settled.md` now gives *subject* to the
eight things a world has. Two meanings, two screens, one word.

I've renamed the **gambit** one to **Who**, which is clearer in its own right — a rule is about
somebody, and *"Who: any foe → Attack"* reads better than *"Subject: any foe"*. The writing-desk
meaning is the one worth protecting, since it's the one that makes a page read as a sentence.

Say if you'd rather it went the other way.

## 8. Housekeeping

- **Q22 — delete the four `pressure-model-*.md` files.** You've already ruled on this; the
  consolidated `pressure-model.md` is the keeper and a stale duplicate under a "newest wins" rule
  is a live hazard. I haven't deleted them because they're yours.
- `companions-base-anchoring-spec.md` §6's permanent-loss table is superseded by session 17 §7.
- `combat-depth-spec.md` §7.2's "skip ranks" note is overruled by Q34 and should be struck.

---

## What I'm doing while you read this

In priority order from audit #9, minus what's blocked above:

1. ~~Q38 vitality~~ — **done, 6 Aug**, including audit #9's trophic-depth refinement and the sweep
   it asked for (only `blight` fights itself, and there it's the point).
2. ~~The search loop~~ — **done, 6 Aug.** Travellers stand on the map and are recruited in a written
   scene; see Q39.
3. **Skills, 2 → 12** — the biggest remaining imbalance. Building the whole starter set from
   `resources-skills-spec.md` §2, plus the new effect kinds in `CombatRules` they need.
4. **Session 17** — stats, levels, XP from combat *and* discovery, mob levelling, ranks, the
   escape item, nobody dies.
5. **Salvage at the Blacksmith**, which the audit proposes and I agree with — breaking down gear you
   don't want back into stock.
6. **Over-hanging placement**: a rune that won't fit is currently refused outright; session 11 asked
   for it to glow red and be refused on the drop. I'll change it — it's legibility, not design.
7. Whatever of §2 above you've authored by then.
