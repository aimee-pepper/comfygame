# Code Audit #7 (2026-08-05, commit `4192efc`)

429 tests. The collapse rework is a real improvement — being ejected by a number while the map was ninety per cent intact was the right thing to fix.

**But it has a hole that recreates the exact problem it was meant to solve**, one level down.

---

## 1. THE FINDING — the portal survives, the path to it doesn't

Crumbling eats from the outermost ring inward (`ring(of:) = min(x, y, w-1-x, h-1-y)`, lowest first — so the map edge goes first). **Portals are excluded while any non-portal tile survives.** Crumbled tiles are impassable (`isPassable = !isCrumbled && ground.isPassable`).

Put those together:

- **The entry portal is on the map edge — ring 0 — which is the first ring to go.**
- The portal tile itself is spared, but **every tile around it crumbles.**
- The player, further in, is now separated from an intact portal by a band of impassable ground.
- **There is no route out.** You stand there until your own tile goes and you're ejected.

Which is precisely what the commit set out to prevent:

> *"a collapse that eats them first turns 'get to a portal in time' into 'wait to be thrown out', which is no decision at all."*

Sparing the portal isn't enough — **the portal has to remain reachable.**

There's a milder version of the same problem: because crumbling picks randomly *within* the outermost surviving ring, a player standing in that ring can end up surrounded by crumbled tiles with their own tile intact, unable to move at all until it goes.

### Suggested fixes **[PLACEHOLDER — pick one]**

1. **Spare a path, not just a tile.** Before crumbling a tile, check whether removing it disconnects the player from every surviving portal; if so, pick a different tile. Correct, and it makes "run for it" always meaningful — but it's a connectivity check per crumble, which on 324 tiles is fine but isn't free.
2. **Crumble inward from the edge *behind* the player** — bias the pick away from the shortest player-to-portal route. Cheaper, approximate, and it reads as the world closing in behind you, which is the better fiction anyway.
3. **Spare the portal's neighbourhood**, not just the portal. Cheapest. Leaves a small island around each portal, so there's always somewhere to reach — though a player can still be cut off from the island.

**I'd suggest 2, with 1 as a correctness backstop if it proves fiddly** — biasing away from the escape route gives the intended feeling *and* mostly prevents marooning, and the fiction of the collapse chasing you is better than the fiction of it politely leaving a corridor.

### Worth testing explicitly
A test that runs a collapse to completion from several player positions and asserts **a portal is reachable on every turn until the player's own tile crumbles.**

---

## 2. Turn budget still unscaled (from audit #6, unactioned)

The map is 18×18 (324 tiles) and `stabilityTurnBands` are unchanged from the 14×14 era. At stability 25 you get **25 turns**, which won't cross the map once; below 26 you never see a night at all, so the day/night system and Illumination's dynamic range are invisible on exactly the greedy worlds most likely to be interesting.

**Aimee has confirmed the collapse-heavy feel is the intended drama** — a low-stability world spending most of its life coming apart is the point, not a problem. So the turn budget question is purely about the bottom band being *usable*: 25 turns can't cross the map once, which reads as broken rather than as tense. A greedy world should be a scramble, not an ejection.

---

## 3. Still unbuilt (all specced and handed over)

Stacking and storage tiers · combat depth (gear still has no damage type) · flora · predation · anchoring's three routes · crafting · named places · companions · the crystal currency.
