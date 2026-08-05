# BACKLOG — work top-down, check off in the completing commit

## Milestone 1 — Skeleton & saves
- [x] Xcode project (SwiftUI, iOS 17+, portrait), `Tuning.swift`, `Content/` data module
- [x] Codable game state with separate Reality/Base/Worlds structs; atomic debounced JSON save after every mutation
- [x] Encounter-flag registry per creature/resource type (needed later for silhouette previews)
- [x] Force-quit/resume harness proven in the simulator (SIGKILL mid-encounter + after banking); **still needs one pass on Aimee's actual iPhone**

## Milestone 2 — Base & authoring
- [x] Base hub (data-driven station list) → Writing Desk, Storehouse, Workshop, Party, Constellation subscreens
      (spending/editing inside Storehouse, Workshop, Party and Constellation is milestones 4–5; each screen says so)
- [x] Symbol data (starter 10) + book slots + random-fill of empty slots
- [x] Pre-bind preview: projected yield mix, enemy tier, stability estimate; Essence bind cost
      (unfilled slots project a **range** rather than a guess — see questions-for-design Q7)
- [x] Essence Spring station (trickle on run return)
- [x] *Stretch, pulled forward:* preview spawn icons silhouette until encountered

## Milestone 3 — Worlds
- [ ] Seeded 14×14 gen from book composition; fog of war; nodes/enemies/hazards/portal/locked cache
- [ ] Movement: tap-adjacent + tap-to-path (interrupt on sighting); optional D-pad
- [ ] Stability decay per player turn; thresholds 50/25/0 (hazards → crumble → collapse); banking 100% via portal / 50% on collapse
- [ ] Harvest interactions; essence-raw wild drops

## Milestone 4 — Encounters
- [ ] Bump-to-encounter battle screen; party of 2 vs 1–3 foes; Attack/Skill/Item/Flee
- [ ] Gambit engine (ordered rules, first-match-fires); starter 3 pieces; 2 slots
- [ ] Party screen gambit editor (drag-reorder) — out of combat only; in-encounter manual override tap

## Milestone 5 — Economy & payoff
- [ ] Workshop purchases (storehouse tiers, gambit slot + 2 pieces, 2 researchable symbols, Automate Self, companion gear)
- [ ] Identify flow for 2 unidentified curios; key→locked-cache cross-world payoff; Motes + Constellation (3 nodes)

## Milestone 6 — Ergonomics
- [ ] 44pt audit, thumb-zone action bar, haptics (optional), full acceptance-criteria pass from docs/design-brief-v0.md

## Stretch
- [ ] Preview spawn icons with silhouette/revealed states + %
