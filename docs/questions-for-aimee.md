# Questions for Aimee

Plain-language version of `questions-for-design.md` — same questions, no code in them. Every one of
these already has a working answer in the build, so nothing is waiting on you. This is just "here's
where I guessed, tell me if I guessed wrong."

Answer however you like — scribble in this file, tell me in chat, or route it through the designer
Claude into `decisions-log.md`. Anything you don't answer, I'll keep as-is.

---

## The two I'd most like answered

### 1. Should you pay for symbols you didn't choose?

Leave a slot empty and it gets filled at random when you bind. Right now **you're charged for
whatever it rolls**, and the Bind button quotes you the worst case ("at most 28").

- **A — Keep it.** Random slots cost like any other symbol. Leaving slots empty is the *chaotic*
  option, not the cheap one.
- **B — Random fills are free.** You pay only for what you chose. Leaving slots empty becomes the
  *budget* option — a way to get a world when you're broke.

B makes under-specification something you'd do on purpose when poor, which might be a nice pressure
valve. A keeps it purely about appetite for surprise. I shipped A because "cost scales with total
symbol value" reads that way, but B is arguably the better game.

**Your answer:**

---

### 2. What is the fifth book slot?

One of the three Constellation unlocks is "+1 symbol slot in books". But books have exactly four
kinds of slot — Terrain, Biome, Bounty, Quirk. So a fifth slot has to be *something*:

- **A — A second Quirk.** Quirks are the paired-tradeoff ones, so this is the spiciest option.
- **B — A wildcard.** Any kind you like, chosen when you fill it.
- **C — A new kind entirely** (that doesn't exist yet).

Not urgent — you can't buy the unlock until milestone 5. But the answer changes how books are stored,
and that's much easier to change *before* there's a save file on your phone you care about.

**Your answer:**

---

## Smaller ones

### 3. Your starter symbols: ten or eleven?

The brief says "Starter collection (10 symbols)" and then lists eleven of them. I shipped all
eleven. If it should be ten, which one starts locked?

**Your answer:**

### 4. Does the bestiary survive a reset?

"Creatures you've met" currently lives in the Reality layer, so a future base reset would *not* take
it away — your knowledge is yours forever, Pokédex-style. Sound right, or should a reset wipe it
back to silhouettes?

**Your answer:**

### 5. Are Motes safe from collapse?

Motes are the permanent currency. Right now, a mote you picked up but haven't banked is lost like
anything else if the world collapses on you. Should they be exempt, given how rare they are?

**Your answer:**

### 6. Can you always walk back the way you came?

You arrive through a portal at the edge of the map, and there's at least one more portal hidden
somewhere. I made **the portal you arrived through also work as an exit** — so you can always retreat
the way you came, it just costs you the turns to walk back. The alternative is that the entry is
one-way and you *must* find an exit, which is much more tense and much more punishing.

**Your answer:**

### 7. What's the game called?

It's "Bookbinder" everywhere right now — that was the placeholder from the brief. Renaming is a
one-line change, best done before you install a build you care about (renaming resets the save on
your phone).

**Your answer:**

### 8. How much can you carry into a world?

Your satchel currently holds as many items as your Storehouse does. When it's full mid-run, you'd
have to drop something to pick something up — which could be a great moment or an annoying one.
Worth deciding on purpose rather than by accident.

**Your answer:**

---

## Not for me to answer

`docs/open-questions.md` (anchoring, the sustain economy, reality resets, permanent-loss policy,
the quirk catalog) is yours and the designer Claude's. I haven't touched any of it, and nothing in
the code assumes an answer.
