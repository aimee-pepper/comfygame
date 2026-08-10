# CLAUDE.md — Project "Bookbinder" (working title)

You are the implementation engineer for a turn-based iOS game designed by Aimee with a Claude (claude.ai) instance acting as game designer/PM. **The `docs/` folder is the source of truth.** Read, in order: `docs/design-brief-v0.md`, `docs/decisions-log.md`, `docs/open-questions.md`, `BACKLOG.md`. Consult `docs/research-pass-2.md` and `docs/research-pass-3-catalogs.md` when a task touches instability, symbols, or gambits.

## Non-negotiable pillars (violating these fails review)
1. Turn-based everywhere; no timers, no real-time mechanics.
2. Interruptible: full state persisted after every player action; force-quit at ANY moment (including mid-encounter) resumes exactly; decay/instability advances only on in-session player turns, never wall-clock time.
3. Portrait, one-handed, ≥44pt touch targets.
4. Three persistence layers (Reality / Base / Worlds) kept in separate sub-structs of the save so future "reset base, keep reality" is trivial.
5. Seeded deterministic worldgen; seed in save.

## Working agreements
- **Do not resolve anything listed in `docs/open-questions.md` unilaterally.** Stub it, tag it, move on.
- Tag every value you invent with `// PLACEHOLDER` in code and keep gameplay numbers in one tunable constants file (`Tuning.swift`) so Aimee can rebalance without hunting.
- Work `BACKLOG.md` top-down; check items off in the file as part of the commit that completes them. Small, frequent commits with imperative messages.
- When you hit a design ambiguity, append a question to `docs/questions-for-design.md` (create it if absent) with enough context to answer from the file alone, pick the most conservative interpretation, tag it, and continue. Never block waiting.
- Data-driven content: symbols, gambit pieces, creatures, items, and base stations are data (JSON or Swift structs in a `Content/` module), not hardcoded logic — the design calls for these catalogs to grow a lot (see research-pass-3 catalogs).
- After each milestone, verify the acceptance criteria in the brief's build-order section, especially the force-quit resume test.
- After fixing a bug or completing a batch of updates, run the relevant tests and simulator smoke check, then build, install, and launch the latest Debug build on **Aimee's Phone** through Xcode. If the phone is disconnected, locked, untrusted, or unavailable, report device delivery as pending rather than treating it as complete.

## Tech constraints (from brief)
Swift + SwiftUI, iOS 17+, portrait only, no backend, single Codable game-state JSON in Documents with atomic debounced writes, GameplayKit seeded RNG. No SpriteKit in v0.

## Design change protocol
Aimee and the designer Claude update `docs/` files; a commit touching `docs/` means design changed. On any new session, diff/read `docs/decisions-log.md` first — the newest dated entries win over older brief text if they conflict.
