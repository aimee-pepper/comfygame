# Decisions Log

Newest entries win over older brief text where they conflict. "Locked" = Aimee's stated decision. Items not listed here that appear in the brief tagged [PLACEHOLDER] are Claude-designer stopgaps, freely changeable.

## 2026-08-04 — Session 1 (design conversations + research passes 1–3)

**Structure & platform**
- Three persistence layers: Reality (survives everything incl. future resets) → Home Base (persistent) → Authored Worlds (instanced). Locked.
- Native iOS (Swift/SwiftUI), sideloaded via Xcode; TestFlight later. Locked.
- v0 scope = full loop: author → explore/harvest → encounter → bank → spend. Locked.
- Turn-based, interruptible, sleep-friendly; comfy = session ergonomics, NOT the cozy genre. High tension/greed/loss are in-bounds; offline time is always safe. Locked.

**World authoring**
- Mystcraft-style symbol composition; empty slots random-filled; pre-bind preview with projected cost/stability (legibility before commitment). Locked.
- Book parameters must grow FAR beyond the v0 set, unlocked via BOTH world discovery AND a research/tech tree; granularity increases with progression (coarse early → specific late), modeled on Mystcraft's grammar tiers. Locked direction.
- Quirks are paired tradeoffs (example given: Dim Sky → more nocturnal creatures/plants spawn, but reduced visibility range and torches needed). Locked pattern; individual quirks TBD.
- Pre-bind preview shows expected creature/resource spawn icons: silhouette if never encountered; once encountered, real icon + % likelihood + expected ratio. Locked.
- Stable (anchored) worlds are functionally eternal and fully explorable. Locked.
- High-instability worlds must EVENTUALLY be permanently anchorable at great resource cost. Locked intent; WHEN in the loop the anchor choice occurs is OPEN (see open-questions).

**Economy**
- Essence: found as single wild drops + upgradeable home Essence Spring; later an unlockable Essence Distillery. Locked direction.
- Multiple concurrently-running (anchored) worlds with resource extraction feeding projects (e.g., continuous essence-input flows); more output → more worlds affordable. Locked direction, v1+.
- Minion/worker characters assignable to those worlds with gambits governing their harvesting, for passive resource generation over time (funds base building, off-world infrastructure, armor). Locked direction, v1+.

**Combat & automation**
- Bump-to-encounter opens a granular JRPG-style fight (SPD/Spiderweb lineage). Locked.
- Party members automatable via gambits; automating YOUR OWN character is itself an unlock. Locked.
- Gambit pieces grow more granular/specific through progression (discovery + research), mirroring original-PS2 FF12's staged availability (NOT Zodiac Age's all-at-once). Locked direction.
- Gambit editing only OUT of combat. Locked.
- Movement: SPD-style — tap adjacent tile / tap-to-path / optional directional input. Locked.

**Party & companions (v1+)**
- Party is expandable. Companions and animal companions are found in authored worlds and recruited via various means; assignable to party, home, or specific worlds (maintenance/harvesting/crafting). Locked direction.
- Tavern unlock at home village: previously-encountered-but-unrecruited characters have a chance to visit. Locked direction.

**Base**
- Base is a hub of subscreens with unlockable buildings over time (blacksmith for training/crafting/upgrading gear, tavern, distillery, etc.). Locked direction.


## 2026-08-04 — Session 2 (answers + redesign heads-up)
## ⚠️ Heads-up: world composition redesign is coming

**Do not over-invest in the current symbol semantics.** The Terrain / Biome / Bounty / Quirk taxonomy from the v0 brief is a placeholder and will be replaced.

**Where it's going:** sigils will describe **environmental pressures** (temperature, light level, humidity, productivity, predation pressure, terrain openness, substrate, etc. — final axis list still being designed). Pressures shift **probability distributions** over creature and flora trait axes; creatures are then generated part-by-part from those distributions, and coherent part combinations resolve into recognizable identities (e.g. slim build + fangs + dark coloration = an ambusher). Players never specify creature traits directly — only world conditions. Loot derives from the same trait vectors, and recipes will ask for material *properties* rather than named items.

**What this means for you now:**
- Make book slot **count and slot types fully data-driven** — no hardcoded four-type assumption anywhere (storage, UI, validation, save format).
- Don't polish the starter symbol set; it will be rewritten.
- **Unaffected and safe to keep building:** grid generation, movement, fog of war, stability decay/crumble/collapse, banking, encounters, gambits, base/economy scaffolding. Only symbol *semantics* change.
- Keep creature/resource definitions data-driven for the same reason.

Nothing is blocked. Continue Milestone 3 as planned.

---

## Answers to `questions-for-aimee.md`

**1. Cost of random-filled slots — NEITHER A NOR B.** Empty slots cost a **flat cheap rate** regardless of what rolls (a discount, not free). Rationale: free makes bulk-random the correct broke strategy forever; full price kills the pressure valve. This encodes a design principle — **precision costs, serendipity is cheap** — so leaving slots empty stays attractive even late-game. Keep quoting the worst case on the Bind button, but quote the actual (discounted) charge.

**2. The fifth book slot — DEFERRED, and the question dissolves.** It's an artifact of the placeholder taxonomy. Action: make slot count and types data-driven (see redesign note above); leave the Constellation "+1 slot" unlock's meaning unresolved until the pressure axes are settled. Don't build against a four-type model.

**3. Starter symbols, ten vs. eleven — SHIP ELEVEN.** The brief's "10" was a miscount, not a design intent. Don't polish the set; it's being rewritten.

**4. Bestiary survives reset — YES, confirmed.** Creature knowledge lives in the Reality layer permanently. Knowledge is never taken back; the silhouette→revealed collection is a lifetime record.

**5. Motes safe from collapse — NO, keep them losable.** They're the rare currency and collapse is the one moment greed should hurt. If it playtests as too brutal, the fix is **dropping fewer motes**, not making them immune.

**6. Entry portal also works as an exit — YES, keep as built.** One-way entry under a decay clock is the opposite of sleep-friendly. Retreat should cost **turns**, which is already the currency instability taxes.

**7. Game name — Aimee's call, still open.** "Bookbinder" remains the placeholder. Note that "binding" vocabulary may get crowded once sigils/pressures are the core language.

**8. Satchel size — DECOUPLE from Storehouse.** Satchel should be **smaller** than storage and separately upgradeable. Two distinct pressures: carry limit forces "keep or leave it" decisions in-world; storage limit forces "hoard or refine" decisions at home. Two upgrade paths.


## 2026-08-04 — Session 3 (answers to engineering notes + narrative direction)
## Answers to engineering questions

### 4a. Bestiary key under generated creatures — RESOLVED

**The durable key is the raw trait vector. Identity is a derived view, never the stored key.**

Every creature you encounter is recorded as a **specimen**: its actual trait values, verbatim. The resolved identity ("ambusher," "grazer") is *computed* from that vector at read time, not written into the save.

Why this settles the permanence worry: if identity-resolution rules change in a later build, identities are recomputed from stored specimens and nothing is lost. The Reality layer's promise holds because what's stored is observation, not interpretation.

**This gives both collection feels rather than forcing a choice:**
- **Identity tier** — a tidy, completable set. Silhouette until you meet your first of that identity, then revealed. This is the Pokédex layer, and it's what the preview panel speaks in.
- **Specimen tier** — an open-ended field journal beneath each identity. Every variant recorded; supports personal bests/extremes ("largest you've seen," "only prismatic one"). This is where computed-rarity percentiles live (personal + global, both shown).

**Preview sub-question — what silhouette do you show for something never seen?** The identity class. Pressures reliably predict the *class* of creature a world produces, not its specific traits — this mirrors real convergent evolution (same environment → same ecomorph across unrelated lineages; contingency fills in details). So the preview honestly promises "something ambusher-shaped is likely here" while the specific creature stays a surprise. Identity silhouettes are authored art; specimens are generated.

**Implication for content:** identities are authored definitions (a name, a silhouette, and the trait-space region that resolves to them), stored as data like everything else. Expect this catalog to grow.

### 4b. Cost display — CONFIRMED, one exact number

Your reasoning is right and better than the original instruction. One committed number on the Bind button; no range. "The price is certain, the world is not" is exactly the split we want, and watching the price *drop* when you clear a slot makes "precision costs, serendipity is cheap" legible in the moment.

Flat rate at 1 as a `Tuning.swift` placeholder is correct — a constant is right for now. Revisit only if playtesting shows bulk-empty books are dominant.

### 7. Satchel — resources stay stackable and slot-free

Keep the default you proposed. Carry pressure applies to **items only**. Making raw materials compete for slots mid-run is the more aggressive design and it fights the hoarding pillar; instability already taxes greed in *turns*, which is enough pressure for now. Flag for revisit if in-world greed ever feels costless.

Sequencing note acknowledged — capacity split now, decision UI at milestone 5.

### 5. Forward-compat catches — APPROVED, both

Foes carrying resolved stat blocks in the save, and item instances carrying what they *are* rather than a reference: both correct, both consistent with the specimen principle in 4a. Same rule generalizes: **saves store resolved facts, not pointers into regenerable content.**

---

## Narrative direction (new — affects content, not yet code)

Early-stage; nothing here needs building yet. Recorded so content structures aren't designed against it.

**Premise.** The world shattered. Restoration is the long arc; a **great work** must be assembled to avert what's coming next. The catastrophe already happened — the dread is ambient, not a countdown. **No timers, ever.** (Narrative urgency is fine and wanted; mechanical time pressure is not. The only sleep-friendly requirement is that nothing advances while the player is idle.)

**Scattered people.** People were flung into the worlds when it shattered. Some have skills enough to try to make their way home, so they *move between worlds over time* — they are not static pickups.

**Finding them is a search, not a lookup.** A lost person is found in worlds that **satisfy conditions** (cold + dim + mineral-rich), never in one exact reconstructable world. Multiple valid solutions preserve unpredictability and keep authorship from becoming a combination lock.

**Clues: never wrong. Ever.** Partial, sensory, ambiguous, or *stale* — all fine. Deliberately false — never. The failure mode is "she isn't here anymore" or "you read it too loosely," never "the game lied." Because travelers move, a true clue can describe where someone *was*, leaving a further trace. This is how the clue system stays honest while remaining a real deduction challenge.

**Clue sources:** diary pages found in worlds; accounts from other travelers met in worlds; the tavern (unrecruited people you've met turn up and can be asked). Clues are qualitative and sensory — the player translates description into pressures. That translation *is* the gameplay, and it's what makes symbol knowledge feel like literacy rather than inventory.

**NPC types:** hand-authored **named** NPCs (real diaries, real arcs, tied to the great work — some were *doing* something when it hit, so their writings are both breadcrumbs and pieces of the work itself) plus **generic spawning** travelers (procedural, provide ambient clues and recruitment).

**Ties to existing systems:** recovered people are the companions assignable to party/home/worlds; the tavern hosts the unplaced; the great work needs both materials (sourced from increasingly extreme worlds) and people (who know things nobody else does).

### The Library (new base station)

A base station that holds recovered diaries and traveler accounts. It is the **visible face of the restoration arc** — a room that fills up as lost knowledge is recovered — and the natural home for the Reality layer's "knowledge is never taken back" promise.

**Clue highlighting — highlight what matters, never what it means.** Significant sensory phrases are marked in the text ("the stones sang when the cold came"), but the game NEVER translates them into pressures or sigils. The player does that translation; it is the core deduction gameplay and the thing that makes symbol knowledge feel like literacy. Auto-interpretation would destroy it. Side benefit: re-reading old pages after learning more sigils is genuinely rewarding, so the Library stays live content rather than an archive.

**Diaries are collectible sets.** Pages are found scattered across worlds, out of order.

- **Completion is a REWARD, never a GATE.** Partial diaries must always be sufficient to locate a person. Never require a complete diary to find someone — scattered pages plus a hard gate leaves the player stuck with no recourse.
- Returning a **completed diary to the person it belongs to** is a payoff moment and grants a reward from them (nature TBD). Deliverable at any time, including long after recruitment — so the collection loop survives finding them.
- Pages found *after* meeting someone still matter (see above).
- A diary completed for a person **not yet found** is itself a strong lead.

Also likely an achievement (see below).

### Achievements & unlockables — DEFERRED, with a framing to hold

Not being designed yet. When we do: they should be **discovery records, not task lists** — recognizing what the player noticed rather than chores completed. Examples of the right flavor: first prismatic specimen; read a page in the world it describes; found someone from a single stale clue; completed a diary. Precedent: Shattered Pixel Dungeon, where achievements unlock real content (hero classes). Fits the bestiary/library spine.

**Not yet decided:** the nature of the great work; what exactly is coming; whether there's a final confrontation or a completion; how many named NPCs; what completed-diary rewards actually are; the achievement/unlockable list.


## 2026-08-04 — Session 4 (travellers static, named places, writing-system redesign)
Full rune vocabulary and grammar: `writing-system-rune-spec.md`.

## N1–N3. Traveller movement — CANCELLED. Travellers do not move.

**Reverse the session-3 direction. Travellers hold static positions.** Their scattering and wandering happened in the *past*, before the player began searching — that's why pages by one person are found across several worlds. Nobody relocates during play.

Rationale: a found page must still point true. If travellers moved live, a diary could stop describing where its author actually is, which destroys the entire premise of the search. **Do not build the `worldClock` traveller machinery, deterministic paths, or cadence rules.** N1, N2, and N3 from session 4 are void.

The honesty invariant still stands and gets easier: *every clue must remain true of the moment it describes* — trivially satisfied when positions don't change. Clues describe the past because pages are old, not because anyone is in motion.

(`worldClock`-style counters remain the correct pattern for anything that genuinely must change between visits. Nothing currently does.)

## N4. Clues: mostly simple, sometimes cross-referencing

**Most clues point at one thing** — a place, or a person, or a condition. Straightforward single-thread pointers, and that's the normal case.

**Some** pages reference other travellers or places by name, e.g.: *"I'll be trying to stop by Reinehaven, I think maybe Serena had family there so maybe I can find her and resupply on water before I make the desert trek."* That one carries Marek's destination, Reinehaven's existence, Serena's connection to it, and a desert beyond.

So the clue set is a **list with some cross-links in it** — not a fully interconnected web. Build for the simple case; support the linked case.

Consequences of the linked subset:
- Some pages about an already-found person retain value by advancing other threads.
- Travellers need optional **relationship references** (who mentions whom), not a full relationship graph for everyone.
- Generic procedural travellers can carry simple clues only; cross-references can stay authored.

## N5. Named places — worlds are DESCRIBED, not created

Taking the Myst-derived lore literally, and it resolves how a diary can name a place:

**Most descriptions link you to some world matching them. A sufficiently precise description links you to a specific, real, named place.** Reinehaven exists independently of the player. Writing "cold, coastal, mercury ponds" gets you *a* cold coastal mercury world; writing it precisely enough gets you **Reinehaven itself**.

This gives the page's depth-vs-breadth tradeoff a narrative engine: **breadth explores, precision arrives somewhere specific.** It's also why finding people requires literacy — you must be able to write your way to an actual address.

Implications to design around:
- Named places are **authored content** with a defined condition-signature and a precision threshold for linking to them.
- A named place should be **discoverable by accident** at low precision (you land somewhere that *resembles* Reinehaven, or brushes its edges) and reliably reachable once you can write precisely enough.
- Precision comes from page space, refined hands, and compounds — so the whole writing-system progression is in service of reaching specific places.
- Travellers, diaries, and named places are one system: people are *at* places, pages *name* places, and writing precisely is how you get there.

---

## Writing system — redesigned; expect a content rewrite

Full spec: `writing-system-rune-spec.md` (Aimee's illustration doc). Summary of what it means for the build:

**Books become a spatial grid, not a slot list.** Sigils are tetris-like pieces placed on a page grid. Page size is permanent progression; essence remains the per-bind consumable. This supersedes the slot taxonomy — but your `slots.json` work is what makes it a data edit rather than a rewrite, so the timing is good.

**Four rune classes:** Targets (8, fixed — the world's dials), Sources (86, growing — concrete causes), Qualifiers (51, reusable modifiers), Structural (11, grammar). 156 base runes total.

**A sigil is self-contained:** `[qualifiers] → source → Bind → target`, assembled internally and placed as one unit. **No page-wide adjacency effects** — neighbours never interact. This was a deliberate design choice to keep the page readable on a phone.

**Footprint shrinks with instrument:** crude (charcoal) 4–6 cells and irregular; plain (pencil) 2–3 cells; refined (fountain pen) always 1×1. Same glyph throughout — it's a font change, not a new symbol. Refined tier dissolves the packing puzzle entirely, which is the intended late-game arc.

**Compounds** are learned single glyphs meaning several components at a reduced footprint (proposal: `ceil(sum × 0.6)`). Stored in a player **runebook**. Acquired by inventing, finding in the wild, learning from diary pages, or from NPCs.

**Two new proposals with mechanical weight:**
- **Implicit secondary effects.** A source bound to one target also contributes secondary pressures automatically (a Sun bound to Illumination also warms). This is what makes the system causal rather than a set of sliders.
- **Contradiction as an instability source.** "A sun that does not warm" is writable, and deeply unstable. Instability now has two origins: **greed** (abundance/value) and **contradiction**. Fits the Myst lore and gives advanced writers a reason to court danger deliberately.

**Unidentified compounds** (found in the wild) are usable immediately, identified per-component, and reveal a component when its effect is *attributable* — i.e. not masked by another source acting on the same target. Sparse pages become laboratories. Subtle components need evidence accumulated across multiple bindings, with a **confidence meter per unknown slot** (required — without it, slow reveals feel broken). Identifying an unseen component **grants that base rune outright**. Full mechanics in §10 of the spec.

**Not blocking milestone 4.** Encounters and gambits are unaffected.

---

## Small confirmations

- **Library highlighting enforced in code** — yes, please build it so there is no code path from a highlight to a sigil. Exactly right that it's cheap now and near-impossible to walk back later.
- **Specimen tier as an added field** — agreed, nothing to build until traits exist.
- **Achievements as queries over the specimen tier** — agreed, and it's why that structure was chosen.
