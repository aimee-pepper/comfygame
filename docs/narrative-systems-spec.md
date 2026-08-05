# Narrative Systems — Travellers, Clues, Diaries, Named Places, the Great Work (v1 spec)

**Status:** first full spec of the story layer. **[PROPOSAL]** marks my calls; **[OPEN]** marks things genuinely undecided. All numbers **[PLACEHOLDER]**.

**The premise, restated:** the world shattered. People were flung into the worlds. Restoration is the long arc; a **great work** must be assembled to avert what comes next. The catastrophe already happened — the dread is ambient. **No timers, ever.**

---

<details>
<summary><b>1. Travellers and trails — the core structure</b></summary>

### Travellers are static, but they *travelled*

Locked: travellers do not move during play. But their scattering happened over time, and that history is the entire search structure.

**A traveller has a fixed path through worlds, decided at world-creation and never changing.** They were flung somewhere, moved (before the game begins), and stopped. They are at the **end** of their path.

**They wrote as they went.** Pages are scattered along the path — in the worlds they passed through, not only where they ended up.

This gives the search its shape: **a trail.** A page found in one world describes the *next* world along their path. Follow it, find another page, follow that. The final page describes where they stopped, and that's where they are.

It also resolves the honesty invariant cleanly. Every page is true of the moment it describes — a page written mid-journey truthfully describes a place they were passing through. Nothing is stale in a way that misleads; a page simply describes an *earlier link in the chain*.

### Path length is the difficulty knob

- **Short trail (1–2 hops)** — early travellers, found quickly. Teaches the mechanic.
- **Long trail (5+ hops)** — someone who went far and strange. A whole arc.
- **[PROPOSAL] Shortcuts exist.** Some pages skip ahead ("I gave up on the northern route and went straight to..."), and cross-references from *other* travellers can drop you mid-trail. So a long trail isn't necessarily a long grind — it's a long *story* you can enter partway.

### Two kinds of traveller

| | **Named** | **Generic** |
|---|---|---|
| Count | **[PLACEHOLDER]** ~12–20 | Unbounded |
| Authored | Fully — name, voice, diary, arc, relationship to the great work | Procedural from templates |
| Trail | Hand-authored path through condition signatures and named places | Generated |
| Pages | Written prose, distinct handwriting, teach specific compounds | Generated from clue templates; teach common compounds |
| Recruitment | Individual conditions (see companions spec) | Simple |
| Purpose | The story, the great work, the emotional weight | Density, ambient clues, ordinary companions |

**[PROPOSAL] Cross-references are authored only.** Generic travellers carry simple single-thread clues. Named travellers can reference each other and named places. Keeps the web small and meaningful.

### Where a traveller "is"

A traveller's location is a **condition signature** — a set of pressure ranges — or a **named place**. Not a specific world instance. So:

- Write a world matching the signature → they're there.
- Multiple valid worlds satisfy it — you can find them more than one way, which preserves unpredictability.
- **[PROPOSAL]** Once found, they're found. Recruiting them (or not) is a separate step, and they remain findable at that signature until recruited.

</details>

<details>
<summary><b>2. Clues</b></summary>

### The absolute rule

**Clues are never wrong.** Partial, ambiguous, sensory, or describing an earlier link in a trail — all fine. Deliberately false — never. The failure mode is "you read it too loosely" or "that's where they *were* on the way," never "the game lied."

**Invariant (adopted from Claude Code):** *every clue ever emitted must remain true of the moment it describes.* Testable.

### Clues are sensory, not mechanical

A clue never names a sigil, a target, or a value. It describes **experience**, and the player translates.

> *"Three days of white sky and no shadow anywhere. The ground gave under us like ash over embers — warm to the touch a foot down."*

That's high illumination with poor clarity (no shadow → diffuse/occluded light), volatile substrate, geothermal warmth. **The translation is the gameplay**, and it's what makes rune knowledge feel like literacy rather than inventory.

### Clue precision tiers

| Tier | Names | Gets you |
|---|---|---|
| **Vague** | One condition, loosely | A direction, not a destination. Narrows the search. |
| **Specific** | 2–3 conditions with qualifiers | A writable signature. This is the workhorse tier. |
| **Exact** | A named place by name | Go there, if you can write precisely enough |

### Clue sources

1. **Diary pages** — found in worlds, usually in ruins (see `sites-system.md`). The primary vector.
2. **Traveller accounts** — a traveller you've met tells you about someone else.
3. **The tavern** — met-but-unrecruited people turn up and can be asked.
4. **The Library** — cross-referencing pages you already hold can yield a clue neither page held alone.
5. **[PROPOSAL] Old ruins** — the people who came before left records too. These point at named places and rune knowledge rather than at travellers.

</details>

<details>
<summary><b>3. Diaries and the Library</b></summary>

### Diaries

A **diary** is the set of pages one traveller wrote, scattered along their trail. Found out of order.

- **Completion is a REWARD, never a GATE.** Partial diaries must always suffice to find someone. Never require a complete diary to progress.
- **Returning a completed diary** to its author is a payoff moment with a reward from them **[OPEN: what]**. Deliverable any time, including long after recruitment.
- Pages found *after* meeting someone still matter.
- A diary completed for someone **not yet found** is itself a strong lead — you have their whole route.
- **[PROPOSAL]** Each diary has a **final page** that is the location clue proper. Everything else is voice, story, cross-references, and rune knowledge.

### The Library (base station)

The visible face of the restoration arc — a room that fills as lost knowledge is recovered.

**Functions:**
1. **Holds pages**, grouped by author, ordered by trail position once inferable.
2. **Highlights significant phrases** — and this rule is absolute: **highlight what matters, never what it means.** The game marks *"the ground gave under us like ash over embers"* as significant. It never says "→ volatile substrate." **No code path from a highlight to a sigil.** Test the absence.
3. **Cross-referencing** — pages that mention the same place/person link. Sometimes two partial pages together imply a third fact; the Library surfaces that a connection exists, not what it means.
4. **Rune study** — pages teach compounds. Studying is where writing knowledge enters from the story layer.
5. **Re-reading pays.** A page read before you knew a rune reads differently after. This keeps the Library live content, not an archive.

**[PROPOSAL] Library upgrades:** shelving (capacity), an index (better cross-referencing), a study desk (faster/deeper rune extraction). Ordinary research-tree branch.

</details>

<details>
<summary><b>4. Named places</b></summary>

Decided in session 5; restated for completeness.

- **Same instance every visit** — fixed seed, persistent state. Layout and unique things persist (a page found isn't re-findable; a door opened stays open); **ordinary resources replenish** so places don't brick.
- **They are worlds anchored long ago by the people who came before.** That's why they persist and have names. This teaches anchoring experientially long before the player can do it.
- **Reached by precision:** distance (your pressures near the signature) **and** coverage (you named enough of its defining conditions). Close+vague → a world that resembles it. Close+specific → the place. Far → elsewhere.
- **Tiered ladder:** early places reachable with a small common vocabulary; late places need rare runes and page space. Rare/hard-to-write conditions belong to later tiers only.

**[PROPOSAL] What a named place contains:** authored layout, a resident population or its absence, ruins with authored contents, sometimes a resident traveller, and usually one thing found nowhere else. They are the game's set-pieces.

**[PLACEHOLDER] Count:** ~10–15 across the ladder.

</details>

<details>
<summary><b>5. The Great Work</b></summary>

**[PROPOSAL] — this is the least-decided part of the design and the most load-bearing. Treat as a first draft.**

### What it is

A thing assembled at the base, over the whole game, from components. Each component requires **both**:

1. **A material** — with specific properties, obtainable only from a world you must author deliberately (extreme conditions, rare substrate, a specific creature trait combination).
2. **Knowledge** — held by a named traveller, so you must find and recruit them.

That structure makes both halves of the game mandatory rather than parallel: you cannot finish by only exploring or only searching.

### Why it exists

To avert what comes next. **[OPEN]** what exactly is coming — the ambient dread works without specifying it, and specifying it too early forecloses. Options: another shattering; the worlds unravelling one by one; something that came *through* when the world broke. Deciding late is fine.

### Structure **[PLACEHOLDER]**

- **5–7 components**, each a mini-arc: a person to find, a world to learn to write, a material to bring home.
- Components can be done in any order — the search is non-linear.
- Each completed component gives a permanent, visible benefit, so the great work isn't only a score bar.
- **The final component requires the hardest world in the game** — the endgame is an authoring challenge, not a boss fight. **[OPEN]** whether there's a confrontation at all, or only a completion.

### How it ends

**[OPEN].** Three shapes worth considering:
- **Completion** — you finish it, the threat is averted, the world is restored. Clean, fits restoration.
- **Confrontation** — the work enables a final encounter. More conventional, needs combat to carry more weight than it currently does.
- **Choice** — the work can be used more than one way. Risky; needs the fiction to be much more settled.

### Ties to everything

- **Reality layer** finally has narrative content: the great work lives there, and it's what survives resets.
- **Named places** hold several components' materials.
- **Diaries** contain the knowledge of the people who were *working on it* when the shattering hit — so pages are both breadcrumbs and pieces of the work.
- **The people who came before** built the anchored named places; the great work may be *their* unfinished project.

</details>

<details>
<summary><b>6. Open questions</b></summary>

1. What exactly is coming? (Deliberately deferrable.)
2. What does returning a completed diary give you?
3. Does the great work end in completion, confrontation, or choice?
4. How many named travellers, and how many are required vs. optional?
5. Is there a third, older ruin layer predating the people who came before?
6. Can generic travellers ever join a named traveller's trail as a cross-reference, or is that authored-only?
</details>
