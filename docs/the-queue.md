# The Queue — everything still to build

**What this is.** `BACKLOG.md` is the milestone plan and is authoritative for *what v0 is*. This is
the working list: everything specced-or-decided and not yet built, in the order I'd take it, with
what blocks what. Kept current by the implementation engineer.

**For the overview** — where the whole build stands, what's blocked on a decision, and the long-term
plan — read `state-of-the-build.md` first. This file is the detail under it.

**Last updated 7 Aug 2026.** Order set by Aimee: flora → instruments → apexes → the traveller roster.
**Flora, instruments and apexes are done**, along with the fossil audit. What's left at the top of
the list is the **traveller roster**, which is blocked on Aimee for names, voices and diary passages.

---

## The order, and why

### ~~1. Flora~~ — **built**

The material half first: the six organic resources stopped reading vitality's `peak` (which counts
herds) and started reading `produced`, so a world of grazing animals and no plants no longer yields
timber. Then the terrain half — the trait model, the metabolism axis, growth writing the ground,
harvest by tissue, defended flora.

**What it changed that's worth knowing:**

- **Nothing paints growth but plants.** Cover used to be scattered per-tile off Vitality, so it had
  nothing to do with what grew there. Habit now decides patterning and stature decides whether it
  breaks a sightline — a world can be topographically open and still be a maze
- **A lightless volcanic world teems.** Chemosynthesis lifts both life caps, because eating basalt
  needs neither light nor water. It was capped twice over for two reasons that don't apply
- **A world with nowhere to make a living carries no food web** — no producers, therefore no
  herbivores, therefore no predators. ~3% of worlds, and writable on purpose
- **Organic nodes stand where something is growing**, and which one it is comes off the plant

**Open, logged as Q48:** whether flora and creatures should share one world-wide life budget. It is
the better design and it retunes every existing creature number, so it isn't a thing to do quietly.

### ~~2. The real instrument system~~ — **built**

Eight field instruments at **Mara's Survey Post**, one per subject; four page-lens tiers at the
Scriptorium, gated on how many instruments you own; and the lens only ever shows subjects you have
actually been out and measured. Mara has a building. Sight and Read scale with the lens.

### ~~3. Apex encounters~~ — **built**

The creature, the restraint rules, the greed draw, and the eight weapons. Five of the eight rules are
wired; three are authored and inert pending decisions — logged as **Q49**.

### 4. The traveller roster — **6 of ~28**, and now the top of the list

`cast-roster.md` and `the-cast.md`. The cast is what the search loop is *for*, and four of the six
who exist unlock nothing. Needs, per traveller: signature, diary pages, a meeting scene, a building,
a starting lean *(the lean mechanism is built)*.

**Blocked on Aimee** for names, voices and diary passages.

---

## Everything else, grouped

### Specced and unbuilt

| | Where | Note |
|---|---|---|
| **Crafting recipes** | `crafting-spec.md` | 0 exist. ~60 proposed; property-based recipes should cover several outputs each |
| **Consumables** | `crafting-spec.md` PART FOUR | **1 exists**, 18 specced. Includes the escape item (Waystone) |
| **Building staffing** | `building-staffing.md` | Posted → a discount; in the party → their XP levels the building |
| **Compound assembly** | session 10 §4 | Ungated, and the *assembly* half doesn't exist. Gating a feature that isn't built would be a dead button, so both go together |
| **Per-building research trees** | Q40 | Each building its own branch |
| **The Exchange / Recycler** | `merchant-recycler-spec.md` | Vance's, and the way gear returns to materials |
| **The Tavern** | | Firepit → Tavern upgrade; the Keeper brings other people's travellers through |
| **Predation** | `creature-system-spec.md` | Creatures eating each other |
| **Anchoring** | `companions-base-anchoring-spec.md` | Three routes; also the only thing that makes a world permanent |
| **Random companions** | `cast-roster.md` §7 | Found before any named traveller; cost a want; no diary |
| **Wild companions pre-spent** | `combat-trees-full.md` §6 | Arrive at the player's level with points already spent, coherently |

### The writing system

| | Note |
|---|---|
| **Rune pacing** | The needed set, pity toward *the next rune for the next companion*, the hard floor |
| **"You don't have the words for this one"** | The Library marker. Without it a player short a rune can't tell a missing word from a misread clue |
| **Void as a cap** | Write a sun into it and the sun isn't there — the first rune that constrains rather than contributes |
| **Light and Shadow sections** | And the same treatment for Thermal (warming/cooling) and Vitality (growing/consuming) |
| **Count reaching the description** | A world with three suns should say so |
| **The vocabulary rename** | `pressure_sources.json` → `focuses.json`; retire `symbols.json` and the old taxonomy |

### Identification and knowledge

| | Note |
|---|---|
| **Identification becomes knowledge** | N of a kind identified = known permanently, stored in Reality |
| **Use-to-identify** | The second route: find out what it is by using it |

### Awaiting the designer

| | Question |
|---|---|
| **Q47** | Traveller pacing — should a blank book find anybody? Should placement need the clue in hand? |
| **Q48** | Should flora and creatures share **one** world-wide life budget? More honest, more constraining, and it retunes every creature number |
| **Q49** | Three apex weapon rules need a decision before they can be wired — and whether the strongest apexes should require worlds you deliberately *write* toward |
| **Branch depth / point income** | 8 nodes and 1/level are proposals; they set the level cap at 25 |
| **Whether animals use the combat trees** | Leaning a reduced set |
| **Kindling's name** | It leans fiery when it also covers freezing and shock |
| **Adamant's load** | Endgame material *and* anchoring material may be too much for one resource |
| **Glass** | New resource, or quartz serves |

---

## Recently closed

**The whole fossil audit** — the slot taxonomy and everything that only made sense inside it, the
Constellation node written for one companion, and the site-`stabilityDelta` guard the comprehensive
audit asked for. Plus **flora**, **the instruments** and **apexes**.

And before those, all four `clause-audit.md` findings and the two Aimee raised directly:

- **F1** — the bestiary had no screen at all; built, with personal *and* global percentiles
- **F2** — analysis had no door; instruments at the forge *(placeholder, see item 2 above)*
- **F3** — compound assembly's gate; folded into the assembly work, since a gate on a missing
  feature is a dead button
- **F4** — stale: the writing surface already drew glyphs, and the SF Symbol accessor behind it was
  read by nothing
- **The party of five**, and the Party screen showing the party
- **Found travellers stranded** — marked found, never seated, and never placed again
