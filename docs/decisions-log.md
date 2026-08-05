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
