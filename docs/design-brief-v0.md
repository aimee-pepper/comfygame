# V0 Design Brief — Working Title: "Bookbinder" (placeholder, Claude's suggestion — rename freely)

**Audience:** Claude Code, building a native iOS prototype tonight, sideloaded from Aimee's MacBook to her iPhone.
**Author of decisions:** Aimee, via design conversation. Anything marked **[PLACEHOLDER]** is Claude's stopgap choice for tonight, made to unblock the build — tune or replace after playtesting. Anything unmarked is Aimee's stated decision or a direct consequence of one.

## Summary

A turn-based iPhone game with three persistence layers: a **Reality** layer (most permanent, survives everything), a **Home Base** (persistent), and **Authored Worlds** (instanced runs). The player collects **symbols**, binds them into books that generate explorable worlds, adventures/harvests inside them on a tile grid (bump-to-encounter JRPG combat with programmable party automation), and hauls loot home to spend on base and reality upgrades that unlock better symbols. Richer worlds are less stable and crumble in-session. Tonight's slice is the **full loop**: author → explore/harvest → fight → bank → spend. Interruptibility is non-negotiable: state saves after every action, nothing decays while the app is closed, and the app can be killed at any moment with zero loss.

---

<details>
<summary><b>Design pillars (do not violate)</b></summary>

1. **Turn-based everywhere.** No timers, no real-time anything. The game must be playable while falling asleep.
2. **Interruptible.** Persist full state after every player action. App kill/relaunch resumes the exact state, mid-encounter included. Decay/instability advances only on in-session player turns — never wall-clock time, never while backgrounded.
3. **Every session advances something permanent.** Even a failed run yields something spendable.
4. **Author → explore → harvest synergy.** The joy is the loop between the three, not any one alone. Composition choices must visibly change the generated world.
5. **Legibility before commitment.** Projected instability/yield is shown *before* binding a book (fixes Mystcraft's #1 flaw). In-session consequences can then be fast and dramatic — legibility ≠ softness.
6. **Delayed-payoff itemization.** Items found now, purposes found later. Unidentified items exist from v0.
7. **Automation is collectible progression.** Gambit-style condition→action pieces are loot/purchases, not menus that come free.
8. **One-handed portrait play.** ≥44pt touch targets, thumb-reachable primary actions.

</details>

<details>
<summary><b>Tech spec</b></summary>

- **Platform:** iOS 17+, Swift + SwiftUI. No SpriteKit/engine for v0 — SwiftUI `LazyVGrid` for the world map is sufficient at v0 grid sizes. **[PLACEHOLDER]** — migrate to SpriteKit later if perf demands.
- **Install path:** Xcode → run on device via cable. Note: free Apple ID provisioning expires after 7 days (rebuild to renew); a paid dev account allows TestFlight internal builds with no expiry.
- **Persistence:** Single `Codable` game-state struct serialized to JSON in Documents, written after every state mutation (debounced ≤100ms). No SwiftData/CoreData for v0 — one file, atomic writes. **[PLACEHOLDER]**
- **Worldgen:** Seeded deterministic RNG (`GameplayKit` `GKMersenneTwisterRandomSource` or hand-rolled) — seed stored in save so a world regenerates identically on reload.
- **No backend, no accounts, no analytics.** Fully offline.
- **Orientation:** Portrait only.

</details>

<details>
<summary><b>The three layers — v0 treatment</b></summary>

| Layer | Persists across | v0 content |
|---|---|---|
| **Reality** | Everything, incl. future base resets | One "Constellation" screen: 3 permanent unlocks bought with **Motes** (rare currency). v0 unlocks: +1 symbol slot in books; +1 gambit slot; +10% starting Essence after any future reset. **[PLACEHOLDER unlocks]** |
| **Home Base** | Between runs | Three stations: **Writing Desk** (compose books), **Storehouse** (inventory + identify), **Workshop** (spend resources on upgrades) |
| **Authored Worlds** | Duration of the run only (all v0 worlds are disposable; anchoring is deferred — see Open Decisions) | Seeded tile-grid instance generated from the bound book |

Architecture requirement: keep the three layers' state in **separate sub-structs** of the save file so a future "reset base, keep reality" operation is trivial.

</details>

<details>
<summary><b>Symbols & world authoring</b></summary>

A **Descriptive Book** has **4 slots** (5 with the Reality unlock): **Terrain, Biome, Bounty, Quirk**. **[PLACEHOLDER slot taxonomy]**

- Player owns symbols; drag/tap them into slots. **Empty slots are random-filled at generation** (Mystcraft rule — under-specification is a surprise, not an error).
- **Starter collection (10 symbols):**
  - Terrain: Plains, Caverns, Archipelago
  - Biome: Verdant, Ashen, Frostbound
  - Bounty: Sparse Ore, Rich Ore, Teeming Life
  - Quirk: Dim Sky (−instability), Gilded Veins (+high-value nodes, ++instability)
- Each symbol carries: yield modifiers, enemy-table modifiers, and an **instability weight**.
- **Pre-bind preview panel** shows: projected map size, expected resource mix, enemy tier, and a **Stability meter estimate** (e.g., "Stability 68 — will hold ~40 turns" — legibility pillar).
- New symbols are acquired at the Workshop (research spend) **and** as rare world drops. **[PLACEHOLDER: symbols and gambit pieces are parallel loot tracks — open decision Q5 from the research report]**
- Binding a book consumes **Essence** (base currency). Cost scales with total symbol value.

</details>

<details>
<summary><b>World runs — explore & harvest</b></summary>

- Grid: **14×14** tiles, fog of war, entry portal at edge. **[PLACEHOLDER size]**
- Movement is SPD-style (Aimee's stated decision): tap any adjacent tile to step (1 turn), OR tap a destination tile to auto-path toward it turn-by-turn (interrupted by enemy sighting/hazard), OR use an optional corner D-pad. Ship tap-adjacent + tap-to-path in v0; D-pad if time allows. Tiles: empty, resource node (harvest = 1–3 turns of tapping), enemy, hazard, **locked cache** (see itemization), exit portal (always ≥1, revealed on discovery).
- Enemies are visible on the grid; simple behavior — inert until player enters a 2-tile radius, then step toward player each world-turn. Moving onto an enemy (or it onto you) opens an encounter.
- **Stability meter** (0–100) is always visible. It ticks down **per player turn**, at a rate set by the book's composition (rich/gilded = fast). Thresholds: at 50, hazard tiles begin spawning at map edges; at 25, tiles begin crumbling inward (crumbled tiles are impassable; anything unharvested on them is lost); at 0, **collapse**.
- **Banking (Loop Hero rule, tuned):** exit via portal = keep 100% of the haul. Caught in collapse = keep **50%**, randomly selected. **[PLACEHOLDER %]** No death state in v0 — collapse ejects you home.
- Party HP persists during the run; returning home fully heals. **[PLACEHOLDER]**

</details>

<details>
<summary><b>Encounters — JRPG combat with gambit automation</b></summary>

Bump-to-encounter opens a dedicated battle screen (SPD/Spiderweb/JRPG lineage — Aimee's stated combat decision).

- **Party of 2**: the Binder (player character) + one companion. 1–3 enemies per encounter.
- Turn order: simple fixed rotation (party → enemies). **[PLACEHOLDER — no speed stat in v0]**
- Actions: **Attack, Skill (1 each), Item, Flee** (flee always succeeds, costs the run 3 stability). **[PLACEHOLDER flee cost]**
- **Gambits:** the companion runs an ordered rule list, top-down, first-match-fires (FF12 execution model). Starter pieces owned: `Foe: any → Attack`, `Ally HP < 50% → Heal`, `Foe: lowest HP → Attack`. 2 slots to start; more slots via Workshop + Reality unlock. Rules are reorderable by drag.
- **Gambit editing happens ONLY out of combat** (Aimee's stated decision) — on the Party screen at base or on the world map, never inside an encounter. In-encounter interaction with automation is limited to the per-turn manual override below.
- **Manual override:** tapping the companion during their turn overrides the gambit for that turn (FF12 rule). The Binder is always manual in v0; **"automate self" is a purchasable unlock** (Aimee's stated design: self-automation is earned) — include the Workshop entry, fine if it's the last thing built tonight.
- Victory: loot + XP-less for v0 (no leveling tonight; power comes from gear/upgrades). **[PLACEHOLDER — leveling deferred]**

</details>

<details>
<summary><b>Itemization — v0 spine</b></summary>

- **Rarity ladder:** Common / Uncommon / Rare / Mythic, color-coded.
- **Inventory:** starts at **8 slots**; +4 per Storehouse upgrade (3 tiers tonight). **[PLACEHOLDER numbers]**
- **Unidentified items:** 2 curio types drop unidentified ("A humming shard…"); identify at the Storehouse for a small Essence fee. One identifies into a useful consumable; one into a **key**.
- **Delayed-payoff seed:** worlds occasionally generate a **locked cache** tile. It can only be opened by a key found in a *different* world. Cache contents: guaranteed Rare+ (symbol, gambit piece, or Mote). This is the "held the bucket of drinks for a month" moment — must be in tonight's build.
- Resources (stackable, not slot-consuming): Ore, Fiber, Essence-raw, Motes.

</details>

<details>
<summary><b>Economy & upgrades (v0)</b></summary>

- **Essence** (common currency, refined from Essence-raw at Workshop): binds books, identifies items, buys basic upgrades. Essence-raw appears as single wild drops in worlds (Aimee's stated design).
- **Essence Spring** (base station): grants a small Essence trickle credited on each return from a run (in-session events only — pillar 2). Tier 1 built-in; Tier 2 upgrade purchasable. **[PLACEHOLDER amounts]** This seeds the v1+ essence economy (distillery, multi-world passive generation — see roadmap).
- **Motes** (rare): Reality-layer Constellation unlocks only. Sources: locked caches, Mythic drops, first-clear of a world type.
- Workshop purchases tonight: Storehouse tiers 1–3, gambit slot +1, 2 purchasable gambit pieces (`Foe HP < 30% → Attack`, `Self HP < 30% → Flee`), 2 researchable symbols beyond the starter 10, "Automate Self" unlock, companion weapon/armor tiers 1–2. **[ALL PLACEHOLDER prices — make them cheap; tonight is for feeling the loop, not balance]**

</details>

<details>
<summary><b>Screens (6)</b></summary>

1. **Base** — hub that routes to station subscreens + Constellation + "Bind & Depart." Architecture note (Aimee's stated direction): the base is a hub of subscreens that will grow — v1+ adds unlockable buildings (blacksmith, tavern, essence distillery, etc.). Build navigation as a data-driven list of stations, not hardcoded buttons.
2. **Writing Desk** — slot grid, symbol collection, live preview panel, Bind button.
3. **World** — tile grid, stability meter (top), haul summary + satchel (bottom), portal-out button when on portal tile.
4. **Encounter** — party left, foes right, action bar bottom (thumb zone). No gambit editing here.
5. **Party** — companion roster, gear, and the gambit editor (out-of-combat only).
6. **Constellation** — 3 nodes, Mote balance.

</details>

<details>
<summary><b>Build order & acceptance criteria</b></summary>

1. Data models + save/load (kill-test from the very first milestone).
2. Base + Writing Desk + preview + bind flow.
3. Worldgen + exploration + harvesting + stability decay/crumble/collapse + banking.
4. Encounters + gambit engine + manual override.
5. Workshop/Storehouse/Constellation spending + identify + locked cache/key.
6. Ergonomics pass: 44pt+ targets, thumb-zone action bar, haptics on harvest/bind. **[PLACEHOLDER: haptics optional]**
7. *Stretch:* pre-bind preview shows expected creature/resource spawn icons — silhouette if never encountered, real icon + % likelihood + ratio once encountered (Aimee's stated design; full version is a v1 item, but the data model for "encountered" flags per creature/resource type must exist from milestone 1).

**Acceptance (test on device):**
- Full loop (bind → explore → 2+ encounters → portal home → spend) completable in **5–10 minutes**.
- Force-quit at 5 random moments incl. mid-encounter → relaunch resumes exact state every time.
- Two books with different symbols produce visibly different worlds (yield, enemies, decay rate).
- A key found in world A opens a cache in world B.
- Companion fights a full encounter unattended via gambits; reordering rules visibly changes behavior.
- Nothing changes between closing the app at night and opening it in the morning.

</details>

<details>
<summary><b>Explicitly OUT of v0</b></summary>

Art (use SF Symbols/emoji + color), sound, anchored/persistent worlds + sustain economy, base resets/NG+ flow (data structure only), leveling/XP, 3rd+ party members, enemy variety beyond 3 types, difficulty tiers, Game Center, iCloud sync.

</details>

<details>
<summary><b>Open design decisions deliberately deferred (from research pass #2, Qs 1–10)</b></summary>

Deferred with v0 stances: sustain-resource source (v0: no anchoring, all worlds disposable); offline decay (v0: none, and pillar 2 makes "none" the likely permanent answer); symbol-vs-gambit economy relationship (v0: parallel tracks); permanent-loss layer policy (v0: only un-banked run haul is losable); reality-reset payoff preview (v0: not built, structs ready); automation-vs-content scaling (v0: too small to matter). Aimee decides these after reading the report + playing v0 — Claude Code should not resolve them unilaterally.

</details>

---

*v0.1 changelog (2026-08-04): applied Aimee's decisions — SPD-style movement (tap-adjacent / tap-to-path / optional D-pad); gambit editing out-of-combat only, moved to new Party screen; base rebuilt as data-driven hub-of-subscreens for future unlockable buildings; Essence Spring station added; essence-raw as wild single drops confirmed; preview-silhouette system added as stretch with encounter-flag data model required from milestone 1. See docs/decisions-log.md for the full decision record and docs/roadmap-v1plus.md for the systems deliberately not in v0.*
