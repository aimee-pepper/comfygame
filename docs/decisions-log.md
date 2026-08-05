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
