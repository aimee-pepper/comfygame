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
- [x] Seeded 14×14 gen from book composition; fog of war; nodes/enemies/hazards/portal/locked cache
      (the cache generates and shows as locked; opening it needs the key from milestone 5)
- [x] Movement: tap-adjacent + tap-to-path (interrupt on sighting); D-pad shipped as the *primary*
      control, since a 14×14 grid can't give every tile a 44pt target
- [x] Stability decay per player turn; thresholds 50/25/0 (hazards → crumble → collapse); banking 100% via portal / 50% on collapse
- [x] Harvest interactions; essence-raw wild drops
- [x] Dim Sky's paired tradeoff implemented: −1 vision radius for a longer-lived world

## Milestone 4 — Encounters
- [x] Bump-to-encounter battle screen; party of 2 vs 1–3 foes; Attack/Skill/Item/Flee
      (Skill needed a cooldown to not dominate Attack — see questions-for-design Q11)
- [x] Gambit engine (ordered rules, first-match-fires); starter 3 pieces; 2 slots
- [x] Party screen gambit editor (drag-reorder) — out of combat only; in-encounter manual override tap

## Milestone 5 — Economy & payoff
- [x] Workshop purchases (storehouse tiers, gambit slot + 2 pieces, 2 researchable symbols, Automate Self, companion gear)
      (+ satchel tiers and the Essence Spring upgrade; all data-driven in `upgrades.json`)
- [x] Refinery: raw essence → essence, the join between harvesting and spending (design brief)
- [x] Identify flow for 2 unidentified curios; key→locked-cache cross-world payoff; Motes + Constellation (3 nodes)
- [x] Curios actually drop, from won encounters — otherwise nothing above could happen
- [x] Automate Self does something: the Binder gets its own rule list once bought
- [x] **Research rebuilt as themed branch trees** (`research.json`) — no flat shopping list anywhere
- [x] **Gambits assembled from learned components**, not bought whole; wild components from caches
- [x] Loot from fights is rolled at victory and shown, instead of dropping invisibly
- [x] Stability rebalanced to Aimee's steps curve (see `Tuning.World.stabilityTurnBands`)

## Milestone 7 — The writing system (language half first, per engineering-notes-session-4 §2)
- [x] Pressure schema: net values + opposed magnitude (gross) + modality tags, shared 0–100 scale
- [x] Illumination worked in full as the pattern; sources, characters, implicit secondaries
- [x] Diminishing returns on stacking; floor rule; contradiction visible when the net is nothing
- [x] **Order-invariance test** — same sigils, any arrangement, identical world
- [ ] Thermal, Hydrology (both fully specced in docs) — data, not code
- [ ] Substrate, Vitality, Relief, Atmosphere, Cycle (rough specs)
- [ ] Cross-target constraints + the energy budget (`remaining-five.md` — load-bearing, not polish)
- [ ] Sites system (`sites-system.md`) — separate from pressures, own trigger rules
- [ ] The page: footprints, packing, instruments, compounds
- [ ] Unidentified compounds + confidence meter

## Milestone 6 — Ergonomics
- [x] Q10 banking overflow → Storehouse spillover, never lost silently (ruled, session 5 audit)
- [x] 44pt audit, thumb-zone action bar (haptics + full acceptance pass still open — needs the on-device force-quit test)

## Analysis — the third progression axis (decisions-session-8)
- [x] Analysis tiers stored in Reality; description always describes, attribution is gated
- [x] Red/green underlining and named contradictions moved to tier 4, where they belong
- [ ] Field instruments — per-target, crafted, grade affects precision
- [ ] The page lens — predicts from readings you've already taken; field work feeds it
- [ ] Readings as permanent knowledge, stored like specimens (observation stored, meaning derived)
- [ ] Tiers 2, 3 and 5 (readable targets, sigil attribution incl. secondaries, the living layer)

## Contradiction, danger and the description panel
- [x] Contradiction as an enumerated catalogue, never computed from opposed magnitude
- [x] World-description panel with red/green underlining and named contradictions
- [x] Danger runes and Peace — the danger↔time axis, in The Bargain research branch
- [ ] Q23 — whether the danger-rune stability cap is wanted (shipped, disclosed, can't bite yet)
- [ ] Q21 — whether chance-filled slots should fire assertion contradictions
- [ ] Contradiction-only materials, and value scaling with danger (spec §4)
- [ ] "Water that will not freeze" — needs the conversion-vs-contradiction ruling (spec §2.2)

## Sites (docs/sites-system.md)
- [x] Site catalog, conditions-as-ranges, placement, exclusions, caps, guardians
- [x] Symbols expand to pressure components, so worlds have real climate/character
- [ ] Site items routed through the loot-decision flow (currently catalogued but not granted)
- [ ] Q19 — whether sites move the Stability headline (built, switched off)
- [ ] Q18 — whether the preview shows a world's possible sites

## Research as actual trees (Aimee, 5 Aug 2026)
- [x] Branches collapsed by default; tap a branch to expand it
- [ ] **Real tree layout, not a list.** Nodes laid out as a DAG with visible prerequisite edges, so
      you can see the shape of what you're climbing and what a node unlocks downstream. The data is
      already a DAG (`research.json` `requires`); only the presentation is a list.
- [ ] **Split across village buildings.** Each branch lives at the place that owns it rather than
      all four at the Workshop — so where you go is part of what you're doing, and the village
      becomes somewhere you move around in.
- [ ] Open: does a building have to be built/unlocked before its branch is reachable? That would
      make the village itself a progression track.

## Stretch
- [ ] Preview spawn icons with silhouette/revealed states + %
