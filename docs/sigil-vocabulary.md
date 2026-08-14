# The Sigil Vocabulary

> **Current scope authority (9 Aug 2026):** The live catalogue contains 62 focuses. The reconciled
> expansion is the exact 23-entry plan in `focus-expansion-85-current.md`. Older 39→95 counts,
> proposed entries and open acquisition notes below remain historical provenance where they conflict
> with that current plan.

**Scope:** how runes are sorted, how they're obtained, and a rating for every one. Three companion documents cover **compounds**, **the cast**, and **Isolde** separately.

**What this supersedes:** the "tiers" I invented in `rune-pacing-spec.md` §2.1 — a word used across two documents and never defined. There are no tiers. There is a curve.

---

## 1. Three axes (Aimee)

**Standardness** — how ordinary this is in a world. Rated 1 (universal — most worlds have one) to 5 (almost unheard of).

**Value**, of two kinds, and a focus can carry both:
- **Direct (d)** — *"valuable like rich veins, where it directly gives value via loot."*
- **Strategic (s)** — *"being able to add lightning or hail as instability release valves."* Capability rather than yield.

**Specificity** — *"being able to call for gold ore, or ponds, or trees specifically. Precision should increase as the game progresses."* Broad → Named → Precise.

**Commonness is a function of all three.** Standard, cheap and broad → everywhere. Strange, valuable and precise → chased.

## 2. What specificity does mechanically — [PROPOSAL]

**A broad word leaves it to the world. A precise word decides.** Write **Stone** and the world picks which stone; write **Gold** and it's gold.

**So precision is control over the roll** — the same tension the page already runs on, where an unwritten subject is one the world writes for you, extended *inside* a subject.

Three things follow:

- **Precision costs**, so specificity feeds greed without needing a new rule. *"Some stone"* can't be greedy — greed is asking for something in particular.
- **Broad words stay useful forever.** *"Some water"* is cheap and roomy when you don't care, so early vocabulary never becomes dead weight.
- **You learn what a world holds by writing broadly and seeing what turns up** — the discovery loop, applied to materials.

**Build note.** Broad-word rolling and unwritten-subject rolling are nearly the same mechanism — one scoped to a subject, one to everything. Build once with a scope parameter, or they'll drift apart.

## 3. The curve (Aimee)

| | Player has | Player is doing |
|---|---|---|
| **Early** | Deliberately limited | Seeking things out to expand what's expressible |
| **Mid** | Most of the **main functionality** | Understands the system; using it |
| **Late** | Still chasing niche and rare | Specialty vocabulary, strange worlds, last capabilities |

**A rate, not a gate.** Nothing is locked behind a number — rare things are rarer, and the curve is how likely you are to hold them by a given point.

### Capability runes versus value runes — [PROPOSAL]

*"Most of the main functionality by mid-game"* only means something if functionality is identifiable.

**A capability rune makes a kind of expression possible at all.** Three sorts:
1. **The broad word for a subject you have none for** — *Water* is the difference between Hydrology existing and not.
2. **The only focus that pushes a subject one direction** — `thin_air` is the only thing that lowers Atmosphere.
3. **Grammar rather than vocabulary** — chaining, compound assembly.

**These must be reliable, not rare.** Missing one doesn't make the game harder; it makes part of it unavailable. **This is exactly what deadlocked Isolde.**

**Everything else is refinement**, and refinement can be as rare as you like.

## 4. Two dimensions of expansion

**Breadth** — which subjects you can say anything about at all.
**Depth** — how precisely you can speak within one you already have.

**This settles a disagreement I got wrong.** I asserted *"every subject writable at the start"*; Aimee said not every subject should be. **Both are right, because they're different axes.** A starting player has coarse words for some subjects and **nothing at all** for others.

**A subject you can't write is a subject that's always rolled**, so early worlds have more chance in them, and **every new subject you learn is a piece of the world moving from luck into your hands.**

That gives **Cycle** a purpose rather than a gap: *its rhythm is rolled until you learn to name it.*

## 5. Acquisition routes (Aimee)

| Route | Covers |
|---|---|
| Research tree | Some |
| **Random wild drops**, at varying rates | **Almost all** |
| **Travelling merchants** | **Almost all** |
| Diary completion | Some — **exclusive** |
| Quest / storyline *(later)* | Some — **exclusive** |

**Almost every rune has redundancy.** Never found it in the wild? Buy it. Never met the merchant? Research it. **That redundancy is what stops vocabulary from ever hard-blocking a player.**

**Only three kinds are single-route:**
1. **Diary-completion runes** — the reward for finishing somebody's diary
2. **End-of-branch research runes** — the last node of a discipline
3. **Quest/storyline runes** *(later)*

## 6. Pity — corrected (Aimee)

`rune-pacing-spec.md` §2.2 defined the needed set as *"runes required by **any** un-found companion whose other conditions you can already write."* **Too broad.**

**The escalating chance applies to the next rune for the next companion only.** One target at a time.

Better in two ways: a dry run makes **one specific thing** likelier rather than quietly warming the whole pool, and the player's next step stays legible. **The hard floor now guarantees a single named rune**, which is a stronger and simpler promise than guaranteeing "something from a set."

**Consequence: the cast order is the pity order.** The system must know who's next, so the order has to be **authored**, not emergent. See `the-cast.md`.

---

# PART TWO — Every focus, rated

**Key.** **Std** 1 universal → 5 almost unheard of · **Val** d direct / s strategic · **Spec** B broad / N named / P precise · **bold route** = the only route.

## Broad focuses — 8 NEW, and mostly what a starting player has

*"Some stone." The world picks which.* **All are capability runes** — each is the difference between a subject existing and not.

| Focus | Subject | Std | Val | Spec | Route | Why here |
|---|---|---|---|---|---|---|
| **Light** | Illumination | 1 | s | B | **start** | A world has light or it doesn't |
| **Warmth** | Thermal | 1 | s | B | **start** | |
| **Water** | Hydrology | 1 | s | B | **start** | |
| **Stone** | Substrate | 1 | s | B | **start** | Ground you can stand on |
| **Land** | Relief | 1 | s | B | **start** | |
| **Life** | Vitality | 1 | s | B | **start** | |
| **Air** | Atmosphere | 2 | s | B | early wild · research · merchant | Found, so gaining it is a moment |
| **Time** | Cycle | 3 | s | B | mid wild · research · merchant | The last subject to become writable |

## Illumination

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Sun** | illu +55 · ther +40/f+8 | **1** | — | N | **start** — *the most standard thing a world can have* |
| **Moon** | illu +12/f+4 · cycl +30 | 1 | — | N | start |
| **Stars** | illu +4 | 2 | — | N | early wild · research · merchant |
| **Aurora** | illu +14 | 4 | — | P | late wild · merchant — *light with no warmth* |
| **Comet** | illu +15 · ther +5 · cycl +10 | 4 | — | P | late wild · merchant |
| **Void** | illu −25/f−15 · ther −20/f−30 | **5** | s | P | **late wild only** — *Rift merged in; the strangest word in the vocabulary* |

*The Moon's `cycl +30` is why it's the counter-cyclic light — but its illumination floor is only +4, so it barely lifts the night. Worth raising if it's to mean what its name suggests.*

## Thermal

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Ice** | hydr +20 · ther −22/f−28 | 2 | — | N | start |
| **Snow** | hydr +15 · ther −15/f−18 | 2 | — | N | start |
| **Smoke** | illu −25 · ther +5 · atmo +18 | 3 | — | N | mid wild · merchant |
| **Wildfire** | ther +30 · hydr −15 · atmo +20 · **vita −30** | 3 | s | N | mid wild · research · merchant |
| **Ash** | illu −30 · subs +10 · atmo +20 · ther −18 · vita −18 | 3 | s | N | mid wild · merchant |
| **Magma** | illu +30/f+30 · **ther +60/f+45** · subs +25 | 4 | **d** s | P | late wild · research · merchant |
| **Volcano** | ther +45 · subs +35 · atmo +25 · reli +30 | 4 | **d** s | P | late wild · research · merchant |

*Wildfire and Ash move **out** of the starting set. They're destructive and situational — a beginner shouldn't be handed the two runes that strip a world of life.*

## Hydrology

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Rain** | hydr +30 · illu −8 · **vita +30** | **1** | — | N | **start** |
| **Sea** | hydr +45 · ther −15/f+22 · reli −15 | 1 | — | N | start |
| **Lake** | hydr +25 · ther −7/f+10 | 2 | — | N | start |
| **River** | hydr +20 · vita +15 · reli +20 | 2 | — | N | early wild · merchant |
| **Mist** | hydr +14 · illu −12 · atmo +15 | 2 | — | N | early wild · merchant |
| **Marsh** | hydr +22 · reli −8 · **vita +25** | 3 | — | P | mid wild · merchant |
| **Glacier** | hydr +35 · **ther −30/f−35** · reli +25 | 4 | — | P | late wild · merchant |
| **Geyser** | ther +20/f+15 · hydr +8 · subs +12 | 4 | d | P | late wild · research · merchant |
| **Pond** *(new)* | small standing water | 2 | — | P | **diary — Sela the wanderer** |

## Substrate

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Granite** | subs +8 · **reli +20** | 1 | — | N | start |
| **Sand** | hydr −20 · subs +4 · reli −10 | 1 | — | N | start |
| **Iron** | subs +8 | 2 | **d** | N | start — *the workhorse metal* |
| **Salt** | hydr −10 · subs +8 · **vita −25** | 3 | d | N | mid wild · research · merchant |
| **Sulfur** | subs +15 · vita −12 | 3 | d | P | mid wild · research · merchant |
| **Crystal** | **illu +18/f+18** · subs +25 | 4 | **d** | P | **early-precise** wild · merchant; no longer a Brush prerequisite |
| **Gold** | subs +40 | 4 | **d** | P | late wild · merchant |
| **Gold ore** *(new)* | precise, richer | 4 | **d** | P | **diary — Halloway the smith** |

*Gold and Crystal leave the starting set. **They are where greed lives** — handing them over on turn one gives away the game's central tension before the player has met it.*

## Relief

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Granite** *(mountain)* | reli +20 | 1 | — | N | start |
| **Sand** *(dune)* | reli −10 | 1 | — | N | start |
| **Canopy** | illu −35 · reli +12 · **vita +35** | 3 | — | N | mid wild · merchant |
| *also shape land:* River +20 · Glacier +25 · Volcano +30 · Marsh −8 · Sea −15 | | | | | |
| **Canyon · Terrace · Scarp** *(unbuilt, Q30)* | | 3–4 | — | P | mid–late; **Scarp is diary — Mara the surveyor** |

*Relief is the thinnest subject. Three of the six words proposed in Q30 don't exist.*

## Vitality

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Root** | vita +25 | 1 | — | N | start |
| **Bloom** | vita +20 | 1 | — | N | start |
| **Herd** | vita +12 | 2 | d | N | start |
| **Swarm** | vita +8 | 3 | — | N | mid wild · merchant |
| **Rot** | vita +15 · subs +4 | 3 | — | N | mid wild · research · merchant |
| **Fungus** | **illu +12/f+12** · vita +20 | 3 | **s** | P | mid wild · research · merchant |
| **Trees** *(new)* | timber, canopy | 2 | **d** | P | early–mid wild · merchant |

***Fungus is a capability rune.*** *It's what lets a lightless world hold life at all — the metabolism that makes dark worlds inhabitable.*

## Atmosphere

| Focus | Contributes | Std | Val | Spec | Route |
|---|---|---|---|---|---|
| **Cloud** | illu −20 · atmo +15 · ther −12/f+10 | 1 | — | N | start |
| **Wind** | atmo +15 · ther −8 · reli +10 | 1 | — | N | start |
| **Ash** | *see Thermal* | 3 | s | N | mid |
| **Thin Air** | **atmo −30** · ther −5/f−30 · hydr −12 | 3 | **s** | P | **mid — RELIABLE. research · merchant · wild** |
| **Miasma** | illu −18 · atmo +22 · **vita −20** | 4 | s | P | late wild · research · merchant |

***Thin Air is the clearest capability rune in the game.*** *It is the only focus that lowers Atmosphere. Without it, an entire direction of an entire subject is unsayable no matter how much else you own — which is precisely what made Isolde's original signature a deadlock. **It must not be rare.***

## Cycle

| Focus | Std | Val | Spec | Route |
|---|---|---|---|---|
| **Tide** | 2 | — | N | mid wild · research · merchant |
| **Orrery** | 4 | s | P | late wild · research · merchant |
| **Drift** | 4 | — | P | **diary — Tovin the binder** |
| **Stillness** | 5 | s | P | **late wild only** |

*Current authority:* Cycle has six direct focuses—Tide, Orrery, Drift, Stillness, Echo and Dream—
plus Moon and Amber secondaries. The old candidate cut is superseded; see
`cycle-system-current.md`. The remaining gap is the world-clock consumer, not vocabulary count.

---

# PART THREE — Modifiers, danger runes, structural

## Modifiers (17 built)

**Precision applies here too** — a coarse hand knows *great*; a fine one knows *overwhelming*.

| Ladder | Rungs | Route |
|---|---|---|
| **Intensity** | faint · moderate · great | **start** |
| | overwhelming | mid wild · research |
| **Scale** | small · large | start |
| | minute · vast | mid wild · research |
| **Count** | single · pair | start |
| | few · many | mid |
| | countless | late |
| **Phase** | liquid · frozen | mid — arrives with Hydrology depth |
| | solid · vaporous | late |

**Unbuilt and wanted** (`backlog-referrals-worked.md` §1): **Constancy** (constant · cyclic · seasonal · erratic) and **Direction** (N/E/S/W). Both survive the qualifier rule, both are mid-game, both are tied to Cycle and celestial depth.

## Danger runes (7)

**Purely strategic** — Aimee's own example of strategic value, and the release valve that makes greedy worlds viable. **None carries direct value; all are capability.**

| Rune | Std | Spec | Route |
|---|---|---|---|
| **Storm** | 2 | N | mid wild · research · merchant |
| **Predation** | 2 | N | mid wild · research · merchant |
| **Swarm** | 3 | N | mid wild · research · merchant |
| **Blight** | 3 | N | mid wild · research · merchant |
| **Tremor** | 4 | P | late wild · research · merchant |
| **Miasma** | 4 | P | late wild · research · merchant |
| **Peace** | 5 | P | **end of a research branch** |

*Peace is the family's inverse — it buys calm and **costs** stability — which makes it the right thing to sit at the end of a discipline rather than be found in a hole.*

## Structural

**Join · separate · rotate** — from the start. These are how the page works, not vocabulary.

**Chaining** and **compound assembly** are **capability runes**: mid-game, reliable, research-guaranteed. **Compound assembly currently has no gate at all** (`clause-audit.md` F3) — session 10 §4 said it should be unlocked in the skill tree and nothing checks.

---

## PART FOUR — Open

1. **The standardness numbers.** Mine are a first pass and they set drop rates — the most useful thing to overrule.
2. **The ~6 new precise focuses** — pond, gold ore, trees, and the relief and light words. Names are Aimee's.
3. **Which diary teaches which**, covered in `the-cast.md`.
4. **Which branches end in an exclusive rune.**
5. ~~**The Cycle cut**~~ — resolved by the live six-focus set and `cycle-system-current.md`.
6. **Crystal's exact position** in the precise band, independent of the Brush's current
   Copper/Fibre/Timber recipe.
7. **Whether a subject arrives with its first focus**, or unlocks separately.


---

# PART FIVE — The expansion: 39 → 95 focuses

**`writing-system-rune-spec.md` specced 79 focuses. Thirty-nine exist.** The vocabulary is at half strength, and it shows: three subjects have four or fewer words, and a player who wants to say something ordinary often can't.

**Proposed total: 95** — the 39 built, 38 from the original spec that were never made, 8 broad, 6 precise, and 4 for Cycle.

## Illumination — 6 → 11

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Sun · Moon · Stars · Aurora · Comet · Void | | | | | |
| **Meteor** | 4 | d | P | late wild · merchant | Falling light. Leaves things behind |
| **Eclipse** | 5 | s | P | late wild only | A sun that is sometimes not there — *dynamic range, not magnitude* |
| **Ring** | 4 | — | P | late wild · merchant | A banded sky; light that arrives sideways |
| **Shattered Moon** | 5 | — | P | **late wild only** | A moon in pieces. Strange, and it belongs to the sundering |
| **Thunder** | 3 | — | N | mid wild · research · merchant | Light without a source, briefly |

## Thermal — 6 → 9

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Ice · Snow · Smoke · Wildfire · Ash · Magma · Volcano | | | | | |
| **Hot Spring** | 3 | — | N | mid wild · merchant | Warmth from below, gentle |
| **Cinder** | 3 | — | N | mid wild · merchant | What's left burning after |
| **Frost** | 2 | — | N | **start** | Cold without water — *Thermal currently has no cold that isn't Ice or Snow* |

## Hydrology — 8 → 12

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Rain · Sea · Lake · River · Mist · Marsh · Glacier · Geyser | | | | | |
| **Spring** | 2 | — | N | start | Water arriving from the ground |
| **Waterfall** | 3 | — | P | mid wild · merchant | Falling water; erodes |
| **Pond** *(new)* | 2 | — | P | **diary — Sela the wanderer** | Small, still, standing |
| **Brine** | 3 | d | P | **diary — Auber the distiller** | Salt water — *pairs with Salt for the undrinkable world* |

## Substrate — 8 → 20

**The thinnest subject relative to its importance.** Greed lives here, materials come from here, and there are eight words.

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Granite · Sand · Iron · Salt · Sulfur · Crystal · Gold | | | | | |
| **Basalt** | 1 | — | N | start | Dark stone. Volcanic country |
| **Limestone** | 1 | — | N | start | Soft stone. Caves form in it |
| **Chalk** | 2 | — | N | early wild · merchant | Softer still |
| **Clay** | 1 | — | N | start | Workable ground — *vessels, base building* |
| **Quartz** | 3 | d | N | mid wild · research · merchant | **Lenses — the analysis instruments** |
| **Obsidian** | 3 | d | P | mid wild · merchant | Edges. Piercing weapons |
| **Copper** | 2 | d | N | early wild · research · merchant | Alloys, conductive work |
| **Silver** | 3 | **d** | P | mid wild · merchant | Fine work; **instrument nibs** |
| **Lead** | 2 | d | N | early wild · research · merchant | **Brush ferrules and Fountain-pen parts** — dense, soft, workable |
| **Mercury** | 4 | **d** | P | **diary — Grimmond the delver** | *Aimee's own example.* Strange work; **chaining** |
| **Adamant** | 5 | **d** | P | **end of a research branch** | Endgame. Candidate anchoring material |
| **Gold ore** *(new)* | 4 | **d** | P | **diary — Halloway the smith** | |

## Relief — 3 → 9

**The thinnest subject outright.** Three of the six words proposed in Q30 don't exist.

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Granite · Sand · Canopy *(plus River, Glacier, Volcano, Marsh, Sea shaping land)* | | | | | |
| **Mountain** | 1 | — | N | start | Relief has no word for its own high end |
| **Plain** | 1 | — | N | start | Nor its flat one |
| **Canyon** | 3 | — | P | mid wild · merchant | Cut deep; encloses |
| **Terrace** | 3 | — | P | mid wild · research | Stepped country |
| **Scarp** | 4 | — | P | **diary — Mara the surveyor** | A face you can't climb |
| **Dune** | 2 | — | N | early wild · merchant | Moving land |

## Vitality — 7 → 15

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Root · Bloom · Herd · Swarm · Rot · Fungus · Canopy | | | | | |
| **Grass** | 1 | — | N | **start** | The most ordinary living thing there is |
| **Moss** | 2 | — | N | start | Low, damp, patient |
| **Vine** | 2 | — | N | early wild · merchant | Climbing growth; cover |
| **Thorn** | 3 | s | N | **diary — Nessa the apothecary** | **Defended flora** — the hazard half |
| **Coral** | 4 | d | P | **diary — Sabine the menagerist** | Living stone. Aquatic |
| **Kelp** | 3 | — | P | mid wild · merchant | Underwater forest |
| **Hive** | 3 | d | P | **diary — Orsa the keeper** | Concentrated life; a site as much as a focus |
| **Trees** *(new)* | 2 | **d** | P | early–mid wild · merchant | Timber |

## Atmosphere — 5 → 8

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| *built:* Cloud · Wind · Ash · Thin Air · Miasma | | | | | |
| **Hush** | 2 | s | N | **diary — Isolde the calligrapher** | Air that does not move — *and the only thing that lowers motion* |
| **Gale** | 3 | — | N | mid wild · merchant | *(Cut in the session-5 audit as redundant with Great Wind. **Reinstate only if** Intensity proves too coarse.)* |
| **Weight** | 4 | s | P | late wild · research | Thick air — heat retention, and it feeds gigantism |

## Cycle — historical 0 → 5 proposal

**Superseded:** Cycle now has six direct focuses and does not need the broad Time placeholder. See
the current Cycle table above and `cycle-system-current.md`.

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| **Time** *(broad)* | 3 | s | B | mid wild · research · merchant | The subject exists |
| **Tide** | 2 | — | N | mid wild · research · merchant | The world moves to a pull |
| **Orrery** | 4 | s | P | late wild · research · merchant | A clockwork, still running |
| **Drift** | 4 | — | P | **diary — Tovin the binder** | Time passes unevenly |
| **Stillness** *(Cycle sense)* | 5 | s | P | **late wild only** | Nothing turns. No day, no season |

*Historical note:* this table predates the live six-focus set. Atmosphere's motion reducer is now
**Hush**, so Cycle keeps **Stillness** without a naming collision.

## The Strange family — 0 → 11

**Specced in the rune spec and never built.** This is where rare, late, evocative vocabulary lives — and the game currently has none of it.

| Focus | Std | Val | Spec | Route | What it is |
|---|---|---|---|---|---|
| **Bone** | 3 | d | N | **diary — Bracken the armorer** | Something died here at scale |
| **Amber** | 4 | **d** | P | **diary — Vance the trader** | Preserved things |
| **Tar** | 3 | d | N | mid wild · research · merchant | Slow, black, catching |
| **Glass** | 3 | d | P | mid wild · research | Ground fused |
| **Mirror** | 5 | s | P | **diary — Perren** | Surfaces that return light |
| **Silk** | 3 | d | P | **diary — Fen the bowyer** | Something spins here |
| **Chitin** | 3 | d | N | **diary — Corrin the tanner** | Armoured life at scale |
| **Ruin** | 4 | s | P | **diary — Edren the archaeologist** | **The people who came before.** Sites, pages, the Atlas |
| **Echo** | 5 | s | P | **diary — Lys the archivist** | The world repeats something |
| **Dream** | 5 | s | P | **diary — Nine** | The strangest thing writable |

## Totals

| Subject | Built | Proposed | Total |
|---|---|---|---|
| Illumination | 6 | +5 | **11** |
| Thermal | 7 | +3 | **10** |
| Hydrology | 8 | +4 | **12** |
| Substrate | 7 | +13 | **20** |
| Relief | 3 | +6 | **9** |
| Vitality | 7 | +8 | **15** |
| Atmosphere | 5 | +3 | **8** |
| Cycle | 0 | +5 | **5** *(historical proposal; live direct set is 6)* |
| Strange | 0 | +10 | **10** |
| **Broad** | 0 | +8 | **8** |
| **Total focuses** | **39** | **+56** | **95** |

**Full vocabulary: 8 subjects + 95 focuses + 25 modifiers + 7 danger + 14 compounds + 3 structural = 152.**

*Which lands almost exactly on the 149 the original rune spec called for — arrived at from the other direction.*

## What the expansion is actually for

- **Substrate 7 → 20** is the biggest change and the most needed. Greed lives there, every material comes from there, and it had seven words. **Lead and Silver and Quartz aren't decoration** — they support brush ferrules, pen parts and lenses, so the writing and analysis progressions finally have material costs that make sense.
- **Relief 3 → 9** — a subject with no word for *mountain* or *plain*.
- **Cycle 0 → 5** was the historical gap; the live six-focus set closes it. The remaining work is
  making the resolved Cycle drive the world clock.
- **The Strange family** gives the late game somewhere to go. Everything currently rare is rare because it's *valuable*; nothing is rare because it's *strange*.
