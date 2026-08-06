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

### Aimee's direction, session 4 (2026-08-04)

- **Maximise what is playable before assets exist.** Build so the game can be played and felt with
  placeholder glyphs and list UIs; art arrives into a working game rather than gating it. This is
  why the writing system is being built language-first, page-second
  (`engineering-notes-session-4.md` §2 and §7).
- **Dark mode is required, not a nicety.** Aimee plays before bed. Shipped immediately: Settings →
  Appearance (System / Light / Dark), preference stored outside the save file.


## 2026-08-04 — Session 5 (named places, precision, rotation, tuning flags)
*(Bookkeeping: you read it correctly — I mislabelled. Session 4's "N1, N2 and N3 are void" meant your session-3 N1 and N2, plus the N3 I had introduced in the same session-4 doc. Traveller movement and clue history are both off. My error.)*

---

## Approved without changes

**§2 — the page/language separation, and the invariant.** This is the best structural catch on the project. Yes: **where a sigil sits on the page never affects what the world becomes.** Build the test asserting that the same sigils in any two valid arrangements produce byte-identical worlds. If adjacency ever becomes desirable it is a deliberate decision, never a discovery.

The consequence you drew — a page is a multiset of sigils plus a proof it fits, so the save stores the sigil list as truth and layout as presentation — is right, and "same book, better hand" falling out for free is exactly the intent.

**§3 — contradiction measured gross, not net.** Correct, and this would have been a real bug. Track **net** (what the world becomes) and **opposed magnitude** (force applied in conflicting directions and cancelled) separately per target. Instability reads greed from abundance and contradiction from opposed magnitude. A world that is perfectly ordinary to stand in and violently unstable is precisely the flavor wanted.

**§4 — generate-twice-and-diff for the attributable reveal rule.** Elegant, and it's a good reason to keep worldgen pure as it grows. Confidence state in the Reality layer as described. On the threshold: yes, express "observable" as a **fraction of that target's total pressure**, not an absolute.

**§7 — sequencing.** Agreed. Milestone 5 first, then the writing system as its own milestone in the order §2 implies. The curio identify flow as a rehearsal for per-component identification is a good instinct.

---

## Q12. Named places — SAME INSTANCE (option A), with a resource caveat

Reinehaven is a real place. If it re-rolls on each visit it is a description, not a place, and "her family was in Reinehaven" stops meaning anything.

**Lore that makes this consistent rather than an exception:** named places are worlds that were **anchored long ago, by the people who came before**. That's *why* they persist and have names. This is load-bearing in three ways:

1. It explains persistence without special-casing.
2. It teaches anchoring before the player can do it — you visit anchored worlds for a long time before you learn to anchor your own, so the concept is familiar when it arrives.
3. It gives Q-A (when does the player anchor?) a natural narrative on-ramp.

**What persists between visits:**
- **Layout and structure** — same seed, same place, recognizably.
- **Unique things** — a unique item taken stays taken; a door opened stays open; a found page is not re-findable.
- **Ordinary resources replenish.** It's a living place, not a stripped mine. This avoids both bricking authored content and needing any clock to regenerate it.

Everything not a named place stays disposable and instanced as today.

## Q13. Precision — distance AND coverage, as you proposed

Approved as specced, including the three-outcome table (close+vague → a world that resembles it; close+specific → the place; far → elsewhere).

**Named places form a difficulty progression.** They are not uniformly gated — there's a ladder from easy-to-reach to hard-to-reach, and where a place sits on it is authored per place.

- **Early places** are reachable with a small common vocabulary and a loose description. They're how the player learns that named places exist at all.
- **Mid places** need more of their signature named, more tightly.
- **Late places** require rare vocabulary and enough page space (refined hands, compounds) to say something very specific.

The rare/hard-to-write conditions belong to the **later tiers**, not to every place. That keeps precision meaningful as a gate at the top of the ladder while letting the bottom of it be welcoming.

Practically: a place's tier is a function of how many conditions its signature demands, how tightly, and how rare the runes needed to express them are. Some late places should be unreachable until specific vocabulary is learned — which ties named places directly to the writing-system progression and gives long-hunted runes an obvious destination.

## Q14. Rotation — YES, free rotation

A rune drawn sideways is still that rune; the fiction doesn't object. Rotation makes crude irregular shapes tractable to arrange without removing the spatial decision — fitting runes on the page is deliberate gameplay, and it's where depth-versus-breadth actually gets decided. If glyph legibility suffers visually, rotate the glyph with the piece rather than restricting rotation.

---

## Two tuning flags (design-side, not engineering)

**`World.baseVisionRadius = 2` on a 14×14 grid may be too tight.** That's roughly 24 of 196 tiles visible; exploration risks feeling like groping rather than discovering, and a vision-reducing quirk pushing it to 1 leaves nowhere to cut. Suggest trying **3** as the baseline so quirks have room to bite. Playtest call, but worth testing 3 first.

**`World.lockedCacheChance = 0.5` needs a look alongside key drop rates.** Worlds are disposable, so a cache you can't open is gone permanently. That's a good "come back with a key" tease *if* players routinely carry keys — but at 50% players will often watch caches die unopened, which reads as taunting rather than tantalising. Either lower the rate or ensure key availability keeps pace. Worth deciding deliberately rather than discovering in playtest.

### Aimee's stability rebalance (chat, same session)

Stability is now measured in **steps you get**, not an abstract decay rate. 5% is five moves,
literally; each band above 25 / 50 / 75 multiplies; 100 is indefinite. Implemented as
`Tuning.World.stabilityTurnBands` with the calibration table in `Tuning.Book`. Pinned by tests.

### Aimee's corrections, session 5 (chat)

- **All research is gated behind themed group trees**, never a flat list of purchasable things.
  Implemented as `research.json`: four branches (Instruction, The Hand, The Hold, The Forge), each a
  DAG of one-time nodes with prerequisites. Repeatable-feeling upgrades are chained nodes, so
  "rank" no longer exists as a concept.
- **Gambit research grants COMPONENTS, never whole rules.** You learn "Self", or "30%", or "Skill",
  and assemble sentences from what you know — so one new component multiplies with everything you
  already have. Components can also be found in the wild (locked caches now grant them). Mirrors the
  writing system: literacy, not inventory.
- **Loot from mobs was invisible.** It was dropping and never being reported, which is the same as
  not dropping. Spoils are now rolled at the moment of victory and shown on the victory screen.
- **Stability units must make sense.** A symbol's printed number is now *the number the headline
  moves by* — no conversion factor. A book starts at 100 and each symbol adds its own delta. Picking
  three stabilisers reads 95, not ~50. Pinned by tests.

### Aimee's answers, late session 5

- **Chance draws from the whole pool, not just what you own.** A chance-filled slot that could only
  return things you already knew is a shuffle, not a surprise. Deliberate choice stays limited to
  what you've learned.
- **Unwritten targets are rolled, not defaulted.** A sensible default makes every under-specified
  world the same tepid place.
- **Using a rune does not teach it to you** (Q16). You write the world, you don't learn the word.

### Q20 answered (Aimee, 5 Aug 2026)

**A chance-filled book that rolls a near-dead world is not a bug to fix in the rules.** Chance keeps
drawing from the whole pool and the steps curve stays literal at the bottom. The fix is
presentational: world load animations make a short-lived world visible as you enter, and an
instantly-collapsing one plays out as a scene — the world crumbles as you step through and you get
back out in time. The gamble stays a gamble; the player just gets to *see* it rather than being
handed an unreadable number.

---

## Session 6 (2026-08-05)
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

---

## Session 7 (2026-08-05)
---

## The search loop, corrected

### Distance is difficulty of description, not hops

**Disregard hop count entirely.** A traveller is not "N worlds away." A traveller is **at a condition signature**, and what varies is how hard that signature is to *write*.

- An **early** traveller sits somewhere a starting vocabulary can describe — "any sunny world."
- A **late** traveller sits at a hyper-specific signature needing rare runes and page space you don't have yet.

So search difficulty scales off the **writing system**, not off traversal. The multi-hop "trail" model in `narrative-systems-spec.md` §1 is **wrong and should be removed** — long journeys exist, but as a *range*, not the default shape.

### Trail length is a scaling range

Most travellers are found straightforwardly once you can write their signature. **Long, elaborate searches are reserved** for exceptional companions and for ones that make sense later in the story. Do not make length the norm.

### Pages are partial descriptions that accumulate

**The number of location pages scales with signature complexity.**

- Simple signature ("a sunny world") → **one page** says it all.
- Complex signature → **each page names another piece of it**, and you assemble the description across several.

Pages are a **guide, never a gate**: a traveller is simply *at* a signature, so a player who writes the right world — deliberately or by luck — finds them without ever reading a page. A lucky early clue leading to a late-game character is fine and should not be prevented.

**Consequence worth protecting:** partial knowledge is playable. Knowing four of six conditions means either hunting for more pages or writing what you know and **leaving the rest to chance-fill** — a real gamble with a real price, since binding costs essence. This is the first place leaving slots empty is strategically meaningful rather than merely cheap.

### One page, one unlock

Each page unlocks exactly **one** thing. Page unlock types:

- A piece of a traveller's location description
- Another companion's whereabouts
- A specific world worth writing
- A ruin's existence
- A symbol, taught outright
- **A head start on a research node** (partial progress, not the finished thing)

### All pages come from travellers' diaries

There is **no separate class of found writing** — no scholar's notes, no workshop records. Everything is somebody's diary. This is what makes completing the diary of an easy-to-find companion coherent: you already have the person, and their diary is still scattered and still paying into four other systems.

**Diaries contain all page types, with a slight lean toward the author's specialisation.** An archaeologist's diary skews toward ruins and research leads; a wanderer's toward places and people. A soft preference, not a hard filter — so chasing a *particular* person's diary can be motivated by what they knew.

### Page placement: weighted, with a fallback

Pages prefer worlds **relevant to their author** — an archaeologist's pages surface in worlds with ruins. But if the player hasn't generated a matching world after **a set amount of exploring/generation [PLACEHOLDER threshold]**, the system stops waiting and places those pages **anywhere**.

Nothing is permanently unreachable because of how a player happens to write.

### The Library: a hint page per diary

Each diary gets a **hint page** that accumulates as pages are found — a single place where everything known about that traveller's location is assembled.

Rules:
- **It collects, it does not interpret.** The hint page assembles the actual passages ("no shadow anywhere," "warm to the touch a foot down") side by side, with gaps shown as gaps. It never renders them as a condition list, and never names a sigil, target, or value. The player does the translation.
- **It shows how many pieces are still missing** — a count only. Knowing you have four of six tells you whether to keep hunting or gamble.
- **It does not show what *kind* of piece is missing.** That crosses the line into interpretation.

---

## Anchoring (Q-A) — RESOLVED. Three routes, not two.

Supersedes the two-step tether/anchor proposal in `companions-base-anchoring-spec.md` §3.

Anchoring is accessible **multiple ways**:

1. **Anchor at bind.** Pay the cost up front and the world is born anchored. This is how you deliberately build a world for a purpose — a grazing world you intend to staff with companions — without gambling on finding anything inside it.
2. **Find an anchor point in-world.** A site the world may generate; reach it and anchor there. Cheapest route, but you must survive to it.
3. **Place an anchor manually with an expensive crafted item.** For when hunting for a natural anchor point before collapse is too risky. The item is a genuine treasure and gives crafting a high-value sink.

All three produce the same result: a permanent, revisitable world.

**Open:** relative costs, and whether route 1's premium is large enough that routes 2 and 3 stay attractive.

---

## Still Claude's inventions, awaiting Aimee's review

Flagged so they aren't mistaken for decisions. In rough order of how much rests on them:

1. **Implicit secondary effects** — a source bound to one target also affects others (sun warms).
2. **Contradiction as an instability source** — "a sun that does not warm" is writable and unstable.
3. **"Named places were anchored long ago by the people who came before"** — invented lore now load-bearing.
4. **The great work's structure** — 5–7 components, each needing a rare material *and* a named person's knowledge.
5. **Companion "wants"** as the recruitment mechanic.
6. **Sustain economy** — upkeep on run completion, paid from production, failure means dormancy.
7. **Reality reset** — trigger, what survives, what resets.
8. **Permanent-loss policy** — the whole table.
9. **The 149-rune vocabulary** — reviewed only in part.
10. **System-shaping calls** — source characters, cross-target constraints, energy budget, material properties, crafting buildings, gear slots, site categories, unidentified-compound reveal rule, page size and footprints.

### World-description length (Aimee, 5 Aug 2026)

**A full-length description is fine.** Claude capped the panel at five clauses on the grounds that
eight read as "a list wearing a sentence's clothes"; Aimee's ruling is that there's nothing wrong
with the long version. Cap removed. The natural bound is one clause per pressure target, so a world
that is remarkable in eight ways says eight things.

---

## Session 8 (2026-08-05)
---

## 1. Correcting a premise Claude repeated

Claude has repeatedly written that **opacity was Mystcraft's real failure** and designed around "fixing" it. **That is wrong and should be struck from the docs wherever it appears** (`writing-system-rune-spec.md`, `pressure-model.md`, `contradiction-danger-spec.md` §6, `decisions-session-*`).

**Aimee, who played it:** opacity was the *joy*. Figuring out what your own writing had done to a world is the game, not a usability problem to be solved.

Design consequence: **do not front-load explanation.** The player is meant to write half-blind at first and learn by observing.

---

## 2. Implicit secondary effects — CONFIRMED, and **discovered, not printed**

A source bound to one target also affects others (Sun bound to Illumination also warms; Magma feeds Substrate; Canopy lowers Vitality's light ceiling). This stands — it's what makes the system causal rather than a set of sliders, and it's what gives contradiction something to negate.

**Secondaries are NOT listed on the rune.** A Sun rune does not read "light, and warmth." You write suns for a while and work out that your worlds keep coming out hot. That realisation is content.

---

## 3. Analysis is a third progression axis

Alongside **vocabulary** (what you can say) and **page space** (how much you can say), there is now **analysis** — how much you can *read*. Unlocked over the game, so the same book is a different object depending on how well you can read it.

**Rough tiers** (order decided; exact contents **[PLACEHOLDER]**):

1. **Qualitative only.** The world-description panel gives sensations, no numbers. "Frozen over. Little light."
2. **Targets become readable.** You can see where a world sits on illumination, thermal, and so on.
3. **Attribution.** Which sigils are responsible for what — *including secondaries*. This is where "the sun has been heating my worlds all along" clicks.
4. **Instability broken out.** Greed vs. contradiction, and which contributor is which. **The red/green underlining lives here**, not at the start.
5. **The living layer.** Trait distributions, why this world grows what it grows, predicted spawns.

**The world-description panel always *describes*; what it *attributes* grows with what you've unlocked.** That keeps its deduction job (matching a clue's description to a world's description) intact from the very beginning, while attribution is earned.

---

## 4. Instruments — analysis is crafted, not researched

Analysis comes from **instruments**, crafted from materials, mirroring how pens and inks gate writing. Reading and writing are symmetrical: both crafted, both material-gated.

### 4.1 Field instruments — measure a world you're standing in

- Carried into a world; take readings **after generation**.
- **Per-target** — a thermometer reads thermal, a hygrometer reads water, and so on. More of them, collectible, each needing materials with matching properties.
- **Grade matters.** A fine instrument reads more precisely than a crude one. This gives material grade a job beyond gear.
- **[OPEN]** whether they occupy gear slots or have their own carry allowance.

### 4.2 The page lens — predict before you spend

- A desk instrument. Shows the impact of runes **as you build and change the page**, so you can calibrate before binding and stop wasting materials on experiments.
- Later-game. Its arrival is a real progression beat: you stop discovering what you made and start deciding it.
- **The lens only shows you what you have already measured.** Field readings *feed* it. So field work and prediction are **one progression**, not two systems — early measuring is visibly building toward something.
- Field instruments aren't made worthless; they're superseded gradually, target by target, as your readings accumulate.

### 4.3 Readings are permanent knowledge

**Field readings become permanent, like specimens.** Measuring thermal in a volcanic world teaches you about volcanic worlds generally.

Same storage rule as the bestiary: **store the observation, derive the meaning.** Readings live in the Reality layer and are never taken away — consistent with "knowledge is never taken back."

This connects readings to the specimen model directly and means the analysis axis is built on machinery that already exists.

---

## 5. Consequences for existing docs

- `contradiction-danger-spec.md` §6 — the description panel's red/green underlining is **tier 4**, not a starting feature. The panel still ships early, describing only.
- Any doc claiming the game should explain instability up front — revise. Explanation is earned.
- `materials-crafting-spec.md` — instruments join pens, inks and book covers as crafted goods. The Blacksmith and Apothecary are the likely makers; **[OPEN]** whether a dedicated station is wanted.

---

## 6. Open

1. Do field instruments take gear slots, or a separate allowance?
2. Which building crafts instruments?
3. Do instrument *grades* map to the analysis tiers, or are tiers separate unlocks that grade only sharpens?
4. Can readings be shared/traded, or found in ruins as someone else's notes?

---

## Session 9 (2026-08-05)
The plot is not settled and Aimee is not ready to settle it. What follows is the part that is, plus the mechanical rules that follow from it. Everything marked **[UNDECIDED]** should stay open — don't propose resolutions.

---

## 1. The Atlas — what was broken

There was an **Atlas of the known world** that anchored all the realms together. It was **stolen and destroyed**, and that caused the **sundering**.

**The great work is rebuilding it.** This replaces the invented "5–7 components, each needing a rare material plus a person's knowledge."

Why this is stronger: the player has been rebinding a book the whole game. Every world written is a page; the Atlas is the binding that held them together. It also explains the existing systems without strain:

- **Named places** persist because they were Atlas pages and still partly hold.
- **Travellers** were scattered because the connections between realms snapped.
- **Old ruins** belong to the people who maintained it.
- **Instability** is what worlds do without an Atlas holding them.
- **Anchoring is literal** — you aren't preserving a world, you're re-binding it into the Atlas.

## 2. Progress is measured in realms re-anchored

A unit of progress is **a realm restored**, not a part assembled: find the people who knew that realm, write your way back to it, bind it in.

This makes the great work's structure the same shape as the rest of the game rather than a parallel crafting track, and it fits restoration as the theme.

## 3. The cult

**Someone — likely a cult — stole the Atlas.** Some died in the sundering; some were **scattered like everyone else**; some **survive and still work against restoration**.

Consequences worth building on:

- They are **stranded too**. That keeps the melancholy intact and means opposition never becomes a siege.
- Their antagonism is expressed in the game's own language: **un-anchoring, tearing pages out** — not combat set-pieces.
- **Some ruins are cult ruins**, and their diaries scatter exactly like everyone else's. You may complete a diary and only then realise whose it was. Costs nothing to build; the diary system already exists.
- **Cultists appear as both mobs and NPCs.**
- **A turned cult member or two can be recruited** — people whose experience of the sundering changed their minds. Their diaries record that turn happening across scattered pages, and early pages may be read without knowing who wrote them.

## 4. FINALITY RULE — treat as a pillar

**The cult can never un-anchor anything the player has anchored. Completing something is final and must feel secure.**

Reversal is stressful and unfun and is out of bounds — the same principle as knowledge never being taken back.

**So opposition is friction toward things not yet done, never reversal of things done.** Acceptable expressions:

- Realms *they* un-anchored (past tense) are harder to reach or restore
- They already hold or sit on things you want
- They interfere with a restoration **in progress**, never a finished one

All of that lands as difficulty. None of it takes anything away.

## 5. [UNDECIDED] — leave open

- **Why they wanted the sundering**, or whether it was incidental to something going wrong during the theft. Aimee's note: possibly leave genuinely uncertain, with the surviving cult **disagreeing among themselves** — some insisting it went as intended, others knowing it didn't. Their diaries can contradict each other while every page stays honest, and the question can be deferred indefinitely.
- What is coming, if anything.
- Whether the great work ends in completion, confrontation, or choice.
- How many realms the Atlas needs.

**Do not propose resolutions to these.** Aimee will decide when she has a firm direction.

---

## Session 10 (2026-08-05)
---

## 1. CORRECTION — the page never grows

`writing-system-rune-spec.md` §3 said the page starts at 6×6 and is "expanded by permanent (Reality/base) unlocks." **That was Claude's invention and it is wrong.** It contradicts the instrument progression, which is the actual design.

**The page is a fixed grid. It never grows.** You have one page your whole life. Progression is **learning to write smaller on it** — finer instruments shrink footprints, learned compounds compress meaning. That is the entire point of the burnt stick → pencil → fountain pen ladder.

Spec corrected.

## 2. The page fits on one screen

**No scrolling.** The whole page is visible at once while composing.

Practical consequence: on an iPhone in portrait, with the projection panel also on screen, that caps the grid at roughly **7–8 cells across** at a comfortable touch size. **Page size is a UI constraint, not a progression dial** — pick the size that makes a crude page feel constrained but not miserable, and leave it fixed.

Worth noting what this implies: at 6×6 (36 cells), crude runes at 4–6 cells give you about **seven** sigils on a page; refined 1×1 runes give you **thirty-six**. The progression is dramatic without the page changing at all.

## 3. Sigils can be picked up and moved

Placed sigils can be lifted and repositioned freely while composing. Arranging is not a one-shot commitment.

## 4. Compound sigils (glyphs) are assembled in a popup

**Assembling a composite sigil is unlocked in the skill tree**, not available from the start.

Once unlocked, assembly happens in a **smaller popup within the page-writing menu** — you build the glyph there, then place the finished thing on the page. Keeps the page itself purely about placement.

---

## Open (for Aimee, not to be assumed)

1. **When a sigil won't fit** — refuse the placement outright, or allow it and highlight the overflow so it can be rearranged?
2. **Does moving a placed sigil cost anything**, or is arranging free until you bind?
3. **Exact fixed page dimensions** — needs playtesting on device.

---

## Session 11 (2026-08-05)
---

## 1. THE DESCRIPTION RULE — absolute

**A description may reveal nothing the player did not directly place.**

Currently a description appears **before any runes are placed at all**. That's the leak in its purest form: the panel is describing a rolled world.

The rule, stated fully:

- **While composing:** the description derives **only** from runes actually on the page. Place nothing, get nothing — a blank page has no description. Place three runes, the description speaks to those three and is silent on everything else.
- **Rolled values are never surfaced pre-departure.** Not as text, not as a hint, not as a stability number that only makes sense if you know what rolled.
- **Two things unseal it:** anchoring the page before entering, or having visited. After either, the rolled values are known and the description may show them in full.

That second part is the useful nuance: **anchoring or visiting is the reveal trigger.** A world you've been to has no secrets; a world you haven't written and haven't seen has nothing but secrets.

## 2. The palette must be sectioned

Runes are currently presented as one undifferentiated box of everything. They need **sorting into sections** by category, so the palette reads as a vocabulary rather than a pile.

## 3. EXCLUSIVITY AND CHAINING — new mechanic

**One main choice per category, then modifiers.** You cannot place multiple land-defining runes in the same book. Same for the other categories: one primary, and then whatever modifiers you like.

**Chaining is an unlock.** An **advanced chaining rune** lifts the restriction for its category, letting you combine multiple primaries — multiple lands in one world, and so on.

Why this matters beyond tidiness: it makes the early game *legibly constrained* (one land, one climate, then decoration), and it turns "a world with two kinds of land in it" into an earned capability rather than something you could always do. It also mirrors the source grammar this design took from — one biome controller, one terrain controller, everything else layered on.

### Answered

**"Category" = pressure target.** Exclusivity is **one primary source per pressure target**, plus unlimited modifiers on each. The eight targets:

| Target | Governs |
|---|---|
| **Illumination** | Light: how much, from what, when |
| **Thermal** | Temperature |
| **Hydrology** | Water: how much, what form, where |
| **Substrate** | What the ground is made of |
| **Relief** | The shape and openness of the land |
| **Vitality** | How much life the world supports |
| **Atmosphere** | Air: density, wind, weather |
| **Cycle** | Time: day length, seasonality, constancy |

So: one thing making light, one thing shaping the land, one thing setting the climate — then decorate.

**Chaining is a SINGLE unlock for now**, lifting the restriction across all targets at once. Per-target chaining runes remain possible later if the single unlock proves too blunt.

**The palette's sections (§2) should be these same eight targets**, so the vocabulary's organisation and its grammar are the same thing.

### Standing caveat

These eight targets are on the tier-1 list in `audit-claude-invented-assumptions.md` — Claude pruned them from a research candidate set and stated them as settled without asking. They are now load-bearing for exclusivity, the palette, all 41 pressure sources, every description clause, and the contradiction catalogue. **Cycle is the weakest**: it has few sources of its own and mostly describes what other targets are doing. If the target list changes, exclusivity and the palette change with it.

## 4. Runes need icons that represent their shape

Symbols currently use SF Symbols (`mountain.2`, `leaf`, `snowflake`, `cloud.bolt.rain`). **They need icons that represent the actual rune shape** — the glyph as it would be drawn on the page.

This is the point where the writing system stops being a metaphor: the thing in the palette should be the thing that gets written. It also connects to the illustration work — the crude-hand glyphs are the first asset set needed, and they're needed here before anywhere else.

**Interim, if artwork isn't ready:** a placeholder that is clearly a *glyph* — abstract, monochrome, drawn-looking — rather than a pictographic app icon. A wrong-but-glyph-shaped placeholder is closer to right than a correct-looking SF Symbol.

---

## The eight targets are load-bearing on purpose (Aimee, 5 Aug 2026)

The standing caveat in session 11 §3 — and tier-1 item 1.3 in `audit-claude-invented-assumptions.md`
— is **answered: the eight pressure targets are confirmed and are meant to be core.**

Illumination · Thermal · Hydrology · Substrate · Relief · Vitality · Atmosphere · Cycle.

They are load-bearing for exclusivity, the palette's sections, all pressure sources, every
description clause, the contradiction catalogue and the world-description silence rule. That is
correct and intended, not a risk to be hedged against. Build on them as settled.

---

## Session 12 (2026-08-05)
---

## 1. The gambit UI is unusable and must be rebuilt

Currently: a **modal sheet** with "When" and "Then" sections and a stack of `Picker`s. You leave the list, assemble a rule through pickers, come back. That is nothing like FF12 and it's painful.

**What FF12 got right, and what to copy:**

- **The whole priority list is visible at once**, numbered. You read your party's logic top to bottom without opening anything.
- **One rule is ONE ROW.** Condition on the left, action on the right.
- **Editing happens in place.** Tap a part of the row, change it, done. **No modal sheet.**
- **Drag to reorder.** Priority is positional and reordering is the main act of authoring, so it must be effortless.
- **Toggle a rule on/off** without deleting it, so you can experiment.

**The complication, and the answer.** Our rules have five components (subject · property · comparator · threshold · action) where FF12 had two dropdowns. **Granularity is a content decision, not a UI one** — it must still read as one line.

**[PROPOSAL — Aimee to confirm]** Render each rule as a **tappable sentence**:

> `2. Ally · HP · < · 30% → Mend`

Every segment is individually tappable; tapping one opens a compact inline picker for that segment only, in place, without leaving the list. Unset segments show as placeholder chips (`Ally · HP · ? · ?`), so a half-written rule is still readable and you can see exactly what's missing.

Whatever the final form: **the list stays visible, editing is in place, and reordering is a drag.**

## 2. The research trees are not trees

They're collapsible lists of rows. Prerequisites exist in the data but are never drawn.

**They must render as actual trees** — nodes with visible edges to their prerequisites, so you can see what leads where and plan a route. The branching structure is the point; a list of rows with hidden dependencies is just a shop with extra steps.

## 3. Crafting buildings come from PEOPLE, not research

**Remove the Forge / party-modification section from research.** Modifying party members through a research node is not how this works and never was.

**Crafting buildings arrive as you recruit the people who staff them** — a blacksmith, an armorer, a bowyer, and so on. You don't research a smithy; you find a smith.

This supersedes `materials-crafting-spec.md` §6, which had three research-unlocked buildings (Blacksmith / Tannery / Apothecary). The building set is now **larger, more specialised, and companion-gated** — which ties crafting to the search loop and gives recruiting a concrete mechanical payoff beyond party slots.

**[OPEN]** the full list of crafting trades, and whether a recruited specialist *is* the building or unlocks the ability to build it.

## 4. Gear is lootable in the wild

Until custom crafting exists — and after — **gear should be findable**. Party members need something to wear before there's a smith to make it.

**Sites are the right home for better-than-average gear.** This fits the Q17 ruling (ruins pay knowledge and unique items, never currency): gear *is* the unique-item reward. It also gives sites a reward identity that ordinary nodes can't match, and it means walking to a site with a full satchel is worth it.

Suggested distribution: ordinary gear from encounters and common finds; **notably better gear from sites**, especially ruins, where it reads as something left behind by someone.

---

## Consequences for existing docs

- `materials-crafting-spec.md` §6 — building list superseded (see §3 above).
- Research content — the Forge branch needs removing; its non-party contents may need rehoming.

---

## A recruited specialist unlocks the ability to *build* the building (Aimee, 5 Aug 2026)

Answers the open question in session 12 §3. A specialist is **not** the building, and recruiting one
does not conjure a workshop. **Finding the smith unlocks the ability to build the smithy** — you
still have to build it.

Consequences worth building on:

- Recruiting stays a story beat rather than becoming a construction order.
- Building remains a real cost, so a recruited specialist is a *door opening*, not a reward handed
  over. That keeps the base a place you develop rather than a list that fills in.
- It means two separate progressions have to be tracked: who you have found, and what you have
  built. A specialist recruited but whose building you can't afford yet is a legitimate, and
  probably common, state.

---

## Session 14 (2026-08-05)
---

## 1. The grammar: target first, then connected sources

A composition reads **target sigil → connected sigils**. You write the **Illumination sigil**, and connect sources to it.

This replaces Claude's invented `[qualifiers] → source → Bind → target` ordering.

## 2. Connection requires BOTH adjacency and a connector

**Sigils must be adjacent to connect** — but adjacency alone is not enough.

Why both are needed:
- **Adjacency alone fails**: the page is small, so on a full page nearly everything touches everything. Everything would connect to everything.
- **A connector alone fails**: you could link across the page and relative position would stop meaning anything.

**Together they do distinct jobs: adjacency constrains, the connector declares intent.** Two things touching are only joined if you say so.

### How connecting works (decided)

**A connect mode, entered by a button.** Then tap a sigil, tap an adjacent one — they're joined. Keep tapping onward to chain further sigils into the same cluster.

**No page space is spent on connections.** There is no connector rune occupying a cell; the link is a relationship, not an object. This matters on a page that holds about seven crude sigils.

### Linked sigils become ONE object

**Once linked, the whole cluster moves and rotates together.** You are not placing individual runes any more — you assemble a piece, then fit that piece onto the page.

Consequences:
- **Links can never break by accident.** Moving preserves the shape, so it preserves every internal connection.
- **Rotating a cluster is where the packing gameplay actually lives.** An L-shaped cluster of four sigils has to fit somewhere as an L. More interesting than rotating single runes, and it's the tetris framing made literal.
- **Unlinking splits a cluster back into movable parts.** **[OPEN]** whether breaking a mid-chain link yields two smaller clusters or loose sigils.

### Adjacent ≠ connected, and the page must show which

**Separate clusters can and must sit adjacent without connecting** — otherwise nothing could be packed next to anything else.

So the visual has to distinguish them unmistakably: **an outline around connected sigils**, marking a cluster as one object. Touching-but-unjoined clusters read as separate. Without this a page's meaning would live in an invisible adjacency graph and be unreadable.

## 3. CORRECTED INVARIANT — absolute position is meaningless, relative position is not

The old rule ("position on the page never affects outcome," with a test asserting any two arrangements produce identical worlds) is **superseded but only partly**.

**What still holds:** absolute position carries no meaning. The same cluster written top-left and bottom-right produces the same world.

**What changes:** *relative* position carries meaning. Which sigils touch which is the composition.

**The test to replace the old one:** translate every sigil by the same offset, or rotate the whole page — the resulting world must be byte-identical. Only the adjacency graph may affect outcome.

**Consequence:** arranging is now *writing*, not tidying. Packing stops being a container problem and becomes a semantic one. It also means a list UI can no longer stand in for the page — the grid is load-bearing.

## 4. QUALIFIER RULE — generic ladders first

**A qualifier earns its place only if no generic ladder covers it.**

**"Bright" is cut.** A great sun *is* a bright sun — it's a redundant word that only works on one target.

**But "big" is not one idea, and must not collapse into one word.** A big sun is *intense*; a big sea is *extensive*; a big swarm is *numerous*. Those are three existing ladders and merging them would lose real expressiveness — you could no longer write a small-but-blinding light, or a vast shallow sea.

**The three generic workhorses, applying across all eight targets:**
- **Intensity** (Faint · Moderate · Great · Overwhelming)
- **Scale** (Minute · Small · Large · Vast)
- **Count** (Single · Pair · Few · Many · Countless)

**Target-specific qualifiers survive only where no ladder can say it:**
- **Phase** (Frozen · Solid · Liquid · Vaporous) — genuinely hydrology-only, irreplaceable
- **Direction** (N/E/S/W) — celestial-only

Everything else in the 51-qualifier list gets re-examined against this rule. Expect cuts, which also means fewer runes to illustrate.

---

## Still open from this conversation

1. **Does breaking a mid-chain link** yield two smaller clusters, or loose sigils?
2. **Does the target sigil's presence stay mandatory?** With target-first ordering it's the anchor of the cluster, so probably yes — but confirm whether an unambiguous source can imply its target.
3. **Can qualifiers modify the target rather than the source?** Currently they scale the source only, so there's no way to say something about illumination itself independent of what produces it. Possibly fine; noting the limitation.
4. **Re-audit the 51 qualifiers** against §4.

## Noted for later — not now

**Footprint numbers** (crude 4–6 cells · plain 2–3 · refined 1×1) are **fine as placeholders**, but need finessing in a later version. They require manual sigil-generation effort until Aimee builds the sigil generator, so tuning them now would be wasted work.

---

## Session 14 answers and additions (Aimee, 5 Aug 2026)

- **A modifier sigil takes up space on the page**, like any other sigil. Modifiers are not attached
  diacritics that ride along free — they are written, and writing them costs cells.
- **The target sigil is mandatory** (session 14 open #2). It's the anchor of the cluster; a cluster
  without one says nothing at all.
- **World size needs no new mechanism.** Scale was already in the vocabulary and already placeable
  as a qualifier sigil — it simply wasn't being read. Session 13 §5's "Scale applied to the Relief
  source" is a *reading* of what already exists.
- **A tutorial will be needed** at some point. Noted, not scheduled.

---

## Writing desk layout and target footprints (Aimee, 5 Aug 2026)

- **Ten bins, one per pressure target**, each holding everything you'd write about that target: the
  target sigil itself, every source that pushes on it, and any modifier that only makes sense there.
  Plus a bin for the generic ladders and one for compounds. Writing about light means opening one
  bin, not hunting across three lists.
- **The bin bar is a horizontally scrolling row along the bottom**, with the next bin visibly
  peeking and fading at the edge so it's obvious there's more.
- **A target sigil is one square, in every hand, forever.** It's the anchor of a cluster rather than
  a statement, and charging four cells for saying which dial you mean would tax you for writing at
  all. The hands still compress everything else, which is where the progression is.
- **Be economical with space.** Cut anything that repeats what the screen already shows — the cell
  counter duplicated the empty squares, and the hand name displayed a constant.

---

## A source attaches to ONE target (Aimee, 5 Aug 2026)

The rune spec §5 says "each attaches to a target" and then organises the 86 sources by material
category without ever saying which target each one attaches to. **That mapping was missing**, and
its absence showed: the palette listed every source that *touched* a target, so Rain appeared under
Illumination because rain dims light.

**Rain can't illuminate.** A source attaches to the target it *is an instance of* — the spec's own
Celestial / Water / Fire & Thermal / Stone & Mineral / Air / Living / Strange grouping is the
mapping, and it now lives on each source as `attachesTo`.

Everything else a source does still happens, as an implicit secondary. You just can't write it.

Also: **long-press a sigil for what you can do with it** — join to a named neighbour, unjoin from
one, and turn the piece. Replaces connect mode; a mode is something you have to remember
you're in, and the page already knows which neighbours a sigil isn't joined to.
