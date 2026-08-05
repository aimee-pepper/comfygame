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

## The page as a spatial grid (writing-system-rune-spec §2-3)
- [x] Page model: 6x6 grid, polyomino footprints, placement/removal/redraw, save round-trip
- [x] Three hands — charcoal 4-6 cells, pencil 2-3, fountain pen always 1x1
- [x] Compound footprints — ceil(sum x 0.6), always worth learning, never free
- [x] Order invariance held at the page layer: position is packing, never meaning
- [x] **The Writing Desk writes on the page.** Palette + grid; tap to place, tap to rub out.
      Books bind from what's written, not from slots.
- [x] Drag to move a mark, and drag it off the page to rub it out
- [x] Drag straight from the palette onto the page, with a fit preview under your finger
- [x] Palette sectioned by pressure target, so its organisation and its grammar are one thing
- [x] One primary per target, plus chaining as a research unlock that lifts it
- [x] The absolute description rule — a blank page describes nothing; visiting unseals a world
- [x] Glyph-shaped rune placeholders instead of pictographic SF Symbols
- [x] The page never grows — that was a Claude invention, corrected in session 10 §1
- [ ] Exact fixed page dimensions — needs playtesting on device (session 10 open #3)
- [ ] Hands as owned instruments — `base.ownedHands` carries it, nothing grants the finer two
- [ ] Compound assembly popup, unlocked in the skill tree (session 10 §4)
- [ ] Real crude-hand glyph artwork — `RuneGlyph` draws abstract placeholders until it exists
- [ ] Anchoring as the other reveal trigger (session 11 §1) — visiting is wired, anchoring isn't
- [ ] Open: refuse an over-hanging placement, or allow it and highlight the overflow? (currently
      refuses, which is the conservative reading of session 10 open #1)
- [ ] Retire the slot taxonomy entirely (`setSymbol` writes through to the page as a shim)
- [ ] The Wild rune — saying "leave this to chance" deliberately

## The search loop (decisions-session-7)
- [x] Travellers at condition signatures — difficulty is how hard the signature is to write
- [x] Diaries scattered as pages, one page one unlock, weighted placement with a patience fallback
- [x] Pages on the map, read by walking over them; knowledge banks to Reality immediately
- [x] The Library: hint pages that collect and never interpret, gaps shown as gaps, count only
- [ ] Anchoring as the other reveal trigger, and as a route to a permanent world
- [ ] Research leads, "a world worth writing" and ruin pages are recorded but nothing reads them yet
- [ ] Recruitment — finding someone is not yet joining with them (companions spec, provisional)

## From session 12
- [x] Gambit list rebuilt FF12-style: whole list visible, one rule one row, in-place segment
      editing with no modal, drag to reorder, switch a rule off without deleting it
- [x] Research branches render as actual trees with visible prerequisite edges
- [x] Forge branch removed — party modification through research is not how this works
- [x] Gear is found: worn from the Storehouse, tiers derive from it, sites carry the better pieces
- [ ] Crafting buildings arrive with the people who staff them (needs recruitment first)
- [ ] Open: the full list of crafting trades, and whether a specialist *is* the building
- [ ] Ordinary gear from encounters — currently only sites drop it

## Writing desk UI
- [x] Two panes: Write (page + vocabulary) and The world (description, stats, depart)
- [x] Pick a rune, drag the ghost into place, drag placed runes to move, drag off the page to erase
- [x] Compact throughout, 44pt targets kept
- [ ] Rotating a rune before placing it

## From the built-vs-specced audit
- [x] Bug 1 — the desk no longer describes what the world rolls, only what was written
- [x] Bug 2 — contradictions now cost stability instead of being display-only
- [x] Bug 3 — the `indefiniteTurns` sentinel no longer reaches the player as "~9999 turns"
- [x] Bug 4 — Q17 actioned: ruins pay knowledge and objects, never currency, and are never empty
- [ ] Pressure sources: 41 of 79 built
- [ ] Danger runes are old-taxonomy symbols rather than pressure sigils
- [ ] Creature traits — blocks materials, crafting and the specimen tier
- [ ] The search loop (diaries, pages, Library, hint pages) — independent, buildable today

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
