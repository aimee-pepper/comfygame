# Where I deviated from the design — an honest audit

**From:** Claude Code · **Date:** 2026-08-04
**Prompted by:** Aimee — *"are there other areas where you've deviated from the plan? don't collapse
the designs, we designed them the way we did for a reason."*

Fair challenge. This is everything I can find where I narrowed, flattened or reinterpreted a design
rather than building it. Fixed items first, then the ones still outstanding and needing a decision.

---

## Fixed today (both caught by Aimee, not by me)

### 1. Stability collapsed to a single axis
I built stability as a straight trade against yield, so "stable" implicitly meant "poor". That
flattened a system that already had four dials — stability, sight, danger, resource mix — into one.

**Now:** every symbol trades on several axes. Dim Sky buys stability with *sight* and with things
that hunt in the dark. Plains is stability-neutral and lets you see further. Caverns hides ore in
ground you can't see across. A stable world is not an empty one; it's one that costs you elsewhere.
Guarded by `testAStableWorldStillCostsSomethingElse`.

### 2. I made "no book can be fully stable" and called it elegant
It wasn't elegant, it was a constraint I'd created by mis-scaling the numbers and then rationalised.
Stacking neutral and stabilising choices **should** produce a stable world.

**Now:** it does — reachable, indefinite, and it still costs you sight and danger.
Guarded by `testStackingNeutralAndStabilisingSymbolsReachesAStableWorld`.

### 3. Symbol numbers and the stability headline were in different units
A symbol said "+0.2" and the headline moved by 1.6. Composing a book was guesswork.

**Now:** one unit. A book starts at 100 and each symbol adds exactly the number printed on it.

---

## Still deviating — these need your call, not mine

### 4. Manual override happens *before* the companion's turn, not during it ← the real one

**The design says:** "tapping the companion during their turn overrides the gambit for that turn
(FF12 rule)."

**What I built:** you tap the companion on *your* turn to hand yourself their next turn. Their turn
then waits for you instead of resolving automatically.

**Why I changed it:** the literal reading needs the game to pause on the companion's turn and ask
"let it act, or take over?" — which is a tap every single round, and the acceptance criterion says
the companion should fight *unattended*. I judged those to be in tension and picked one.

**But that was a design decision and I made it silently.** The literal version has you watching an
intention form and choosing to intervene, which is a genuinely different feel — it's *supervision*,
not *pre-authorisation*. Options:

- **A** — Keep as built. Unattended by default; override is pre-emptive.
- **B** — Build it literally: pause on the companion's turn showing what it intends, with "Let it"
  and "Take over". Costs a tap per round, and the unattended criterion softens to "one tap".
- **C** — Both, behind a setting: supervise on/off. More machinery, satisfies both readings.

I'd build **B or C** if the intervention moment matters — say which.

### 5. The satchel's "keep or leave it" moment is a message, not a decision

**The design says** (session 4): carry limit forces "keep it or leave it" decisions in-world, and the
decision UI lands with the items in milestone 5.

**What I built:** a full satchel refuses the drop and prints "no room, left behind". The decision is
made *for* you.

That's the moment collapsed into a notification. It needs a real prompt: here's what dropped, here's
what you're carrying, choose. Not built — flagging rather than quietly leaving it.

### 6. The rarity ladder exists in data and appears nowhere

**The design says:** Common / Uncommon / Rare / Mythic, **colour-coded**.

**What I built:** `Rarity` is on every item and is never once displayed. Every item reads the same.
An entire designed axis is invisible.

### 7. Skills got a cooldown I invented

Already logged as Q11, restating for completeness: the brief gives each character one Skill and no
resource to spend on it. With no limiter Skill beats Attack every turn, so I added a round-counted
cooldown. Reasonable, but it *is* a mechanic I added rather than one you designed.

---

## Checked and faithful

For completeness, things I went back and verified against the brief rather than assuming:

- Movement: all three input methods (tap-adjacent, tap-to-path with interrupt, D-pad) ✓
- Enemies inert until a 2-tile radius, then step toward you each world-turn ✓
- Stability thresholds 50 (hazards) / 25 (crumble) / 0 (collapse) ✓
- Banking 100% via portal, fraction on collapse, random item loss off the run's own RNG ✓
- Harvest as 1–3 pulls, one turn each ✓
- Gambit editing out-of-combat only — enforced in the store, not just hidden in the UI ✓
- Empty book slots random-filled, never an error ✓
- Bestiary in the Reality layer; silhouette until encountered ✓
- No death state — being beaten ejects you home with a partial haul ✓
- Three creature types; art out of scope; SF Symbols throughout ✓

## What I'll do differently

The pattern in all three fixed items is the same: I hit a tension between two designed things and
resolved it myself instead of surfacing it. The override deviation is the same shape. From here,
when a design pulls in two directions I'll build the most faithful version I can and put the tension
in `questions-for-design.md` — rather than picking a side and writing a confident comment about why
my version is elegant.
