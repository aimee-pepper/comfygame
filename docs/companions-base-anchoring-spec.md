# Companions, Base, Anchoring & the Long Economy (v1 spec)

**Status:** first full spec. **[PROPOSAL]** marks my calls — including on four questions previously flagged "Aimee decides" (Q-A anchoring, Q-B sustain, Q-C reality reset, Q-F permanent loss). Those are proposed here so the game is buildable end-to-end; override freely.

---

<details>
<summary><b>1. Companions</b></summary>

### Where they come from
- **Recovered travellers** — named and generic, found via the search (see narrative spec).
- **Animal companions** — creatures from authored worlds, tamed rather than recruited.

### Recruitment: companions want something

**[PROPOSAL]** Finding someone isn't recruiting them. Each has a **want**, and satisfying it is how they join. This ties recruitment into every other system rather than making it a pickup:

| Want type | Example | Ties into |
|---|---|---|
| **Material** | A specific property-matched material | Worldgen, materials |
| **Person** | Someone else found first | The search web |
| **Place** | Take them somewhere, or prove you can reach it | Named places, writing precision |
| **Knowledge** | Show them a rune or a completed diary | The Library |
| **Nothing** | Some just want out | Early/generic, keeps it from being a chore |

**[PROPOSAL]** Named travellers always have a want; generic ones usually don't.

### Animal companions
Tamed via the creature system rather than dialogue. **[PROPOSAL]** taming odds depend on the creature's traits (a low-armament grazer is easier than an apex ambusher) and on what you bring — so the material economy feeds taming too. An animal companion's *generated traits carry over*, so a tamed creature from a strange world is genuinely unique and worth the trip.

### Assignment — the three postings

| Posting | Role |
|---|---|
| **Party** | Fights alongside you; runs gambits; gains experience |
| **Home** | Works a base station: crafting, refining, research speed, Library indexing |
| **World** | Assigned to an anchored world; harvests, maintains, defends (see §3) |

**[PROPOSAL]** Reassignment is free and instant at base — this shouldn't be a logistics puzzle. The interesting decision is *what each person is best at*, not shuffling them.

**[PROPOSAL]** People have aptitudes, drawn from their story: a miner is better at world-harvesting, a scholar speeds Library work, a fighter belongs in the party. Aptitudes are visible, so assignment is informed. Animal companions have narrower aptitudes derived from traits — a burrower harvests, an armoured thing defends.

### Party
Expands beyond 2 over the game **[PLACEHOLDER: to 4?]**. Party slots are a Reality-layer or research unlock. Each member has their own gambit rule list and slots.

</details>

<details>
<summary><b>2. The base and its buildings</b></summary>

Data-driven station list (already built). Buildings unlock via research.

| Building | Function | Status |
|---|---|---|
| Writing Desk | Compose books | Built |
| Storehouse | Inventory, identify | Built |
| Workshop | Research trees | Built |
| Party | Roster, gear, gambit editing | Built |
| Constellation | Reality-layer unlocks | Built |
| Essence Spring | Essence trickle on return | Built |
| Refinery | Raw essence → essence | Built |
| **Library** | Pages, highlighting, cross-reference, rune study | **To build** |
| **Tavern** | See §2.1 | **To build** |
| **Blacksmith** | Craft/upgrade gear from property-matched materials | **To build** |
| **Menagerie** | Animal companions; taming; trait inspection | **To build** |
| **Distillery** | Advanced essence production (v2 roadmap) | Later |
| **The Work** | Where the great work is assembled | Later |

### 2.1 The Tavern

**[PROPOSAL]** Met-but-unrecruited people turn up here. Mechanics:

- Anyone you've **encountered but not recruited** may visit. Visits refresh on run completion (never wall-clock).
- You can **ask them things** — clues about other travellers, about places they've been, about what someone else wants.
- You can **satisfy their want here** if it's a material or knowledge, and recruit them without another expedition. This is the tavern's real job: it makes meeting someone valuable even when you can't recruit them on the spot.
- **[PROPOSAL]** It's also where generic travellers accumulate, so the base gradually fills with people you saved — a visible restoration counterpart to the Library.

</details>

<details>
<summary><b>3. Anchoring (Q-A) — PROPOSED RESOLUTION</b></summary>

**Two-step: a cheap in-world tether, then an expensive anchor from base.**

### Step 1 — Tether (in-world, cheap)
- Available at a **tether site** the world generates (see `sites-system.md`), or from a consumable you carry.
- Effect: **preserves the world's seed and state** so it can be returned to. **[PROPOSAL]** also pauses decay for N turns, so it doubles as an emergency brake.
- Cheap enough to use speculatively on anything interesting.
- Tethered worlds appear in a list at base.

### Step 2 — Anchor (from base, expensive)
- Performed at the Writing Desk on a tethered world, at leisure, with full information.
- Cost scales with the world's **value and instability** — greedy worlds cost enormously more to hold open. This is the sink that makes greed pay for itself.
- An anchored world becomes **permanent and revisitable**, functionally eternal.

### Why this shape
- Preserves "found it, kept it, realised later it was special" — you can tether now and decide days later.
- The in-world moment has tension (reach the tether site before collapse) without a timer or a forced decision.
- Best fit for interruptibility: the expensive irreversible choice happens at base, where nothing is pressing.
- **[PROPOSAL]** Tether slots are limited and upgradeable, so *which* worlds you hold is itself a decision.

</details>

<details>
<summary><b>4. Sustain economy (Q-B) — PROPOSED RESOLUTION</b></summary>

**Anchored worlds cost upkeep, upkeep is paid from production, and failure means dormancy — not destruction.**

- **Upkeep** is a per-world cost scaled by value and instability, charged **on run completion** (never wall-clock).
- **Payment comes first from what that world produces** — companions assigned there harvest, and the harvest pays the upkeep before anything reaches your stores. A rich world with good workers is self-sustaining; a rich world with nobody in it drains you.
- **If upkeep can't be paid, the world goes DORMANT** — not destroyed. Dormant worlds stop producing and can't be visited until re-anchored (at a cost, cheaper than the original anchor). This keeps stakes without permanent loss of something you invested in.
- **[PROPOSAL]** A small number of anchored worlds is free; the cost bites as your portfolio grows. So the mid-game decision is "is this world worth a slot and a worker?"

### Passive harvesting (v2 roadmap, specced here)
- Companions assigned to a world harvest over time — measured in **runs completed**, never clock time.
- **Gambits govern their harvesting** — the same grammar as combat, applied to work: *"if ore < 20, mine"*, *"if threatened, retreat"*. This is why the gambit system being a compositional grammar matters beyond combat.
- **Workers in unstable worlds are at risk.** High-instability anchored worlds can harm or lose companions. That is the ongoing cost of holding a greedy world open, and it ties instability, harvesting, and companions into one loop.
- **Make it alive, not a mission table:** visible workers doing visible jobs, aptitude specialisation, and authored logic. If an optimiser could solve assignment as arithmetic, it's a chore — add risk and personality until strategy beats maths.

</details>

<details>
<summary><b>5. Reality-layer reset (Q-C) — PROPOSED RESOLUTION</b></summary>

**[PROPOSAL] Trigger:** player-initiated, available once a meaningful threshold is passed **[PLACEHOLDER: e.g. first great-work component completed]**. Never forced.

**Survives a reset:**
- The **bestiary and specimen records** (locked: knowledge is never taken back)
- **Rune vocabulary and compounds** — literacy is permanent
- **Named places discovered**, and their persistent state
- **The great work** and its completed components
- **Constellation unlocks**
- **Recovered travellers' identities** — you know who they are; **[OPEN]** whether they must be re-recruited

**Resets:**
- Base buildings and research trees
- Essence, materials, inventory
- Anchored worlds (tethers survive **[PROPOSAL]**, anchors don't)
- Party assignments

**The payoff, previewed before committing** — this is non-negotiable per incremental-design theory: the reset screen must show concretely what you gain *before* you accept. **[PROPOSAL]** the gain is a permanent multiplier plus access to a research tier unreachable in a first pass, so a reset is genuinely a new capability, not a lap.

**Confirmation required.** Never a one-tap irreversible wipe.

</details>

<details>
<summary><b>6. Permanent-loss policy (Q-F) — PROPOSED RESOLUTION</b></summary>

| Thing | Losable? |
|---|---|
| Un-banked haul (resources, items, motes) | **Yes** — the core risk, already built |
| Companions in the party | **[PROPOSAL] No** — injured/incapacitated, never dead. Losing a person you spent an arc finding is disproportionate |
| Companions assigned to unstable worlds | **[PROPOSAL] Yes, but with warning** — the only place people can be truly lost, deliberately, as the price of greed |
| Animal companions | **[PROPOSAL] Yes** — they're replaceable-in-kind, and it gives the menagerie stakes |
| Anchored worlds | **No** — dormancy, not destruction |
| Tethered (un-anchored) worlds | **[PROPOSAL] Yes** — tether slots are finite; a displaced tether is gone |
| Knowledge (runes, bestiary, pages) | **Never** |
| The base | **Never**, except by a chosen reset |
| Anything at all while the app is closed | **Never** |

</details>

<details>
<summary><b>7. Build order</b></summary>

Assumes the pressure model and page system land first (they're prerequisites for most of this).

1. **Library + diaries + clues** — the search loop's spine. Buildable before travellers exist, using pages alone.
2. **Travellers + trails** — generic first, named after.
3. **Companions + assignment + tavern** — recruitment, aptitudes, party expansion.
4. **Tether + anchor** — the two-step, plus tether slots.
5. **Anchored-world upkeep + passive harvesting** — the long economy; needs companions.
6. **Blacksmith + menagerie** — crafting from property-matched materials; taming.
7. **The great work** — last, since it depends on everything.
8. **Reality reset** — needs a full game to reset.
</details>

<details>
<summary><b>8. Open questions</b></summary>

1. Do recovered travellers need re-recruiting after a reality reset?
2. Party size cap.
3. How many anchored worlds are free before upkeep bites?
4. What does the reset multiplier actually multiply?
5. Can animal companions be bred, or only tamed? (Locked earlier: no breeding — but the menagerie may make it tempting again. Staying no unless revisited.)
6. Does the tavern ever bring people you *haven't* met, or only the met-and-unrecruited?
</details>
