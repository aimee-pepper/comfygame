# Code Audit #8 (2026-08-05, commit `aa4fe9f`)

447 tests. **The marooning bug is properly fixed**, and the fix is better than what I suggested.

---

## 1. Marooning — fixed, and correctly

A tile is only taken if the player can still walk to a portal afterwards (`wouldMaroonPlayer` → flood fill). And when *nothing* can be taken safely, **the world takes the player's own tile** — by then every surviving tile is on the last corridor out, so anything else would sever it.

That's a better answer than my "bias the crumble away from the route": it's exact rather than approximate, and it turns the endgame into *being caught*, which is the intended ending, rather than *being stranded*, which is a bug.

Also worth noting: **the first version of the test passed with the fix disabled**, because a run starts standing on the entry portal, so it asserted nothing. He caught that himself and rewrote it to place the player at the furthest ring, where it fails 22 ways without the protection. That's the kind of thing that usually ships as a green test proving nothing.

---

## 2. Performance — worth watching, not yet a problem

`wouldMaroonPlayer` **copies the whole map and runs a BFS, per candidate, per crumbled tile, per turn.**

Rough worst case on 18×18: the outermost surviving ring can hold ~68 candidates, and `crumbleRate` **accelerates the longer you stay**. At 10 tiles/turn that's ~680 map copies and ~680 flood fills in a single turn — roughly 200k tile visits plus 200k element copies, during the most dramatic and most collapse-heavy phase of a run.

Probably fine today. But it grows with acceleration, it lands on the exact turns where responsiveness matters most, and low-stability worlds now spend *most* of their life here (confirmed intended drama).

**Cheaper equivalent if it ever bites:** one **articulation-point pass** over the reachable component per crumble step instead of one BFS per candidate. Only cut vertices can maroon; everything else is safe by construction. That's O(V+E) once rather than O(V·E).

Not urgent. Flagging so it's a known trade rather than a surprise.

---

## 3. CONTENT VOLUME — the systems are outrunning the content

First time I've audited this, and it's the clearest gap now that generation works.

| Content | Count | Assessment |
|---|---|---|
| pressure sources | 41 | Against a specced **79**. Roughly half the vocabulary. |
| symbols | 21 | |
| qualifiers | 17 | Against a specced 51, though session 14's rule cuts that number a lot |
| rune shapes | 13 | Fewer than symbols — so some runes have no shape |
| **creatures** | **3** | Now only used as authored fallbacks — but see below |
| **resources** | **4** | Very thin for a game about hauling materials |
| **items** | **10** | |
| **skills** | **2** | Two skills in the whole game |
| sites | 7 | |
| travellers / pages | 4 / 16 | A real start on the search loop |
| research nodes | 39 across 5 branches | Healthy |
| description clauses | 44 | Healthy |
| contradictions | 9 | Reasonable for the catalogue approach |

**The pattern: the generative systems are in good shape and the authored vocabulary they draw on is thin.** Four resources and two skills means every world hands you the same handful of things and every fight has the same two options, regardless of how varied the *generation* is.

This is the likeliest reason play still feels samey even though pressures now drive terrain, cast and butchery: the machine is working and there isn't much in it.

**Highest-value additions, in order:**
1. **Resources** (4 → 15–20). They're what a world *gives you*, and Substrate composition can already differentiate far more than four.
2. **Skills** (2 → 10+). The whole player side of combat is two buttons; `combat-depth-spec.md` assumes more.
3. **Pressure sources** (41 → 79). Halfway through the specced vocabulary, and each one is a thing a world can *be*.
4. **Rune shapes** to cover every symbol.

---

## 4. Still unbuilt (specced, handed over)

Stacking and storage tiers · combat depth · flora · predation · anchoring's three routes · crafting · named places · companions · the crystal currency.
