# Decisions Log — Session 6 (2026-08-05)

Append to `docs/decisions-log.md`. Answers Q17–Q19 in `questions-for-design.md`.

---

## Q17. Site rewards — **option 3: differentiate by category. No new currency.**

Landmarks and living sites pay in **materials**. Ruins pay in **knowledge** — diary pages, compounds, rune forms — and **never in currency**.

Reasoning:
- It lines up with the narrative spec, where ruins are the clue and rune-knowledge vector. This isn't a balance patch; it's what ruins are *for*.
- An Insight currency would make research stop competing with play — and that competition is good. Essence doing double duty (go-again vs. get-better) is the classic roguelite spend decision, and removing it removes a real choice.
- No new number on the Base screen.

**One gap to close:** if a ruin only pays knowledge, a ruin whose knowledge you already hold is worthless — the failure mode you flagged for option 1, relocated. So **ruins also hold unique items** (not currency): a tool, a keepsake, an instrument, something property-matched and singular. Knowledge first, an object always. A ruin is never empty.

**Sites remain distinct from nodes** — that was the real point of the question, and it's satisfied: nodes give materials, ruins give understanding and artefacts, landmarks give concentrated materials plus a reason to walk there.

---

## Q18. Site preview — **option 3, and build the world-description panel regardless.**

Describe the world qualitatively. Silhouette only sites you have already met.

Your reasoning is correct and the option isn't on the doc's list because I didn't think of it. Specifically right:

- Creature mix and site presence are different shapes of information. A distribution tells you texture; "Binder's Workshop: possible" is a checkbox that ends deduction.
- **Matching a description to a description is the deduction gameplay.** The clue says *a vault under cold stone*; the desk says *frozen over, enclosed, layered stone, little light*. The player does the join. That's the loop the whole game is built to enable.
- Once found, silhouetted thereafter — knowledge earned by exploring pays off in authoring, which is the right direction for this game's progression.

**Build the world-description panel as its own thing, independent of sites.** You're right that a world's entire climate and character is currently invisible despite being computed. That panel is the only place the pressure model becomes legible to the player, and it's the thing that teaches the causal grammar. It should ship with the pressure model, not with sites.

Option 4's bare count: hold. Add only if playtesting shows people never notice sites are condition-gated.

---

## Q19. Sites and stability — **option 3 now. Option 4 is scheduled, not "eventually."**

### Now: rich places are *guarded*, not unstable

A Crystal Cavern doesn't destabilise the world — it has things living in it. Use `enemyTierDelta`, more spawns, a hazard ring, the guardian mechanic sites already have.

Why this and not option 2:
- The meter stays literally legible, which is the rule you just spent effort establishing.
- The fiction is better: the world doesn't object to being rich; rich places attract occupants. It gives Crystal Cavern and Brood Warren one shared logic.
- It avoids the `peekNextSeed` discipline hazard entirely. A preview that *could* see the whole world is a surprise-killing bug waiting for a careless refactor. Not worth it for a second line on the panel.

**Greed is still priced** — at the symbol level, where Rich Ore already costs −45. Sites add a *second, different* price on top, paid in danger rather than time. That's not a free lunch; it's two costs with different textures, which is better than one cost applied twice.

### Scheduled: derived instability (option 4)

You're right that §0 of the sites doc is the bigger claim and that it isn't implemented. It should be, and it shouldn't happen under a sites feature.

**Make it its own milestone, with an explicit trigger:** migrate when the symbol catalogue passes roughly **40 entries**, or sooner if hand-tuned numbers start fighting each other (a symbol needing a different value depending on what it's written beside is the tell). The research pass recommends profiling-against-baseline precisely because it self-balances as catalogues grow, and ours are specced to grow a great deal.

When it lands, the preview still shows each symbol's contribution and those still sum exactly — the legibility rule survives, the numbers just stop being hand-written.

Option 1 correctly rejected. Option 2 held in reserve if §5 is ever wanted literally.

---

## Confirmations

- **Q15 (Ore as twelfth starter):** correct, keep as granted. A ladder missing its middle rung teaches nothing.
- **Q16 (chance-fills don't teach):** confirmed as shipped.
- **Q20 (instant-collapse worlds):** confirmed — presentation, not rules. Note the implementation caution stands: the animation is decoration over an already-settled result, never something the simulation waits on.
