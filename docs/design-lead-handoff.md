# Design Lead Handoff — Codex

**Started:** 8 Aug 2026  
**Role:** This Codex task is the game-design lead and product/design source of truth. A separate
Codex task will handle engineering. Both work from this repository rather than relying on chat
history.

## Working agreement

- Settled design decisions are written into the relevant living specification and/or current
  decision log; chat alone is never the source of truth. `current-design-index.md` is the routing
  entry point.
- Engineering questions belong in `engineering-questions-for-aimee.md`; active design reviews live
  in `design-review-queue.md`. Design answers are recorded in the repository before implementation
  is treated as authorized.
- `docs/` is authoritative. Material in `docs/archive/` is historical only. Newer dated decisions
  supersede older text where a contradiction has not yet been cleaned up.
- `BACKLOG.md` records implementation state and work order. Design status and implementation status
  must remain distinct.
- The design lead may make clearly labelled placeholder decisions to keep ordinary work moving.
  They remain visible in `design-review-queue.md` and do not silently become settled rules.
- The design lead may freely challenge inherited design, but does not freely revise it. Challenges
  are discussed with Aimee first; the design and engineering leads may confer before bringing a
  recommendation to her for review.
- Superseded decisions remain available in the archive so the project's evolution and reasoning can
  be reconstructed. Live documents are kept aligned to current decisions rather than retaining
  obsolete alternatives inline.
- Design discussions should batch related decisions and include a recommendation for each; broad
  workshops are welcome when the decisions form one coherent system.

## Takeover reading

The initial takeover included `project-overview.md`, the repository/documentation indexes, workflow,
current build state, backlog, open questions, design referrals, the combined decision log, sessions
16–17, and the live flora, apex, and combat-tree specifications.

## Current understanding

- The generation spine and core interaction systems are working; the largest debt is authored
  content and the material/crafting payoff loop.
- The four non-negotiable pillars are: fully turn-based play; interruption-safe persistence; earned
  interpretation and opacity; permanent completion/knowledge. Hoarding should eventually pay off.
- The stated near-term sequence is flora → instruments → apex encounters → traveller roster.
- Some handoff text is already stale: for example, the overview calls flora the next build while
  `BACKLOG.md` marks its core implementation complete, and `for-design.md` asks for a fixed class
  list while `combat-trees-full.md` explicitly replaces fixed classes with emergent builds.
- Therefore, old referral lists need reconciliation before being treated as active design work.
- The near-term sequence remains flora review/completion → instruments → apex encounters → traveller
  roster.
- The next practical player-support priority is a debug/balancing menu with adjustable tuning
  controls, so Aimee can explore the design space on-device.
- The target player is Aimee and players with similar tastes. Sessions should support roughly
  15 minutes through an hour or more before bed. The campaign should comfortably sustain at least a
  month and likely longer.

## Initial clarification — resolved 8 Aug 2026

Aimee answered all seven takeover questions. She likes the build so far but does not expect to have
a useful holistic verdict until more of the intended game is implemented. Concrete playtest issues
should guide near-term work in the meantime; see `playtest-notes.md`.

## Current operating state — 9 Aug 2026

- Flora, instrument and apex design audits are complete.
- The comprehensive roster identity and diary-packet pass is complete for 28 travellers. Dagg's
  recovery teaching, Maud's pattern, Oda's housing and Tovin/anchoring have current resolutions. Tam's
  endgame act and diary remain deliberately held.
- `diary-corpus-audit-current.md` routes all 251 target pages, separates implementation-ready content
  from strict deferrals, and records the remaining corpus risks.
- `anchoring-system-current.md`, `channelworks-system-current.md` and
  `diary-focus-mechanical-profiles-current.md` are implementation-facing authority for those areas.
- `roster-coherence-audit-current.md` controls teaching uniqueness, diary distribution and
  relationship coverage.
- `traveller-identities-existing-six-current.md` gives engineering honest clue replacements and the
  approved order for the six implemented travellers.
- `design-review-queue.md` is the running short list for Aimee. Continue routine work without approval
  after every batch; pause only for material changes and summarize progress intermittently.
- Engineering owns game code, the asset lead owns standalone asset systems, and game design owns
  design authority and review recommendations. The tasks confer directly through written handoffs.

## Continuing system pass — 9 Aug 2026

The remaining implementation-facing queue now has current documents for building staffing,
Exchange/Recycler, compound assembly/station trees, Tavern/random companions, curio knowledge,
rune pity/Library literacy, palette/taxonomy migration, predation, Count prose and Void's categorical
cap. Each is indexed in `current-design-index.md`, archived in `decisions-session-18.md`, and tracked
as a labelled playtest/placeholder in `design-review-queue.md`.

The most important implementation correction from this pass was separating the five-person active
party from persistent roster capacity. Engineering has applied that correction and continues the
traveller rollout on device. Physical crafting now has a current 21-family catalogue and an explicit
construction-tier/reforge split in `gear-crafting-families-current.md`. Anchoring depth now has a
sustain-first, discovered-renewable production loop in `anchored-realm-production-current.md`;
rates and tray capacity are labelled reversible playtest values. The tutorial/discoverability pass
is now current in `tutorial-discoverability-current.md`, and generated-human arrival builds are
separated cleanly from trait-built animal companions. Remaining work is smaller content and
integration auditing plus playtest review of the labelled placeholders.

The crafting migration is now exact in `crafted-gear-migration-current.md`: old paid power is
grandfathered without retaining the future tier bypass, stored/equipped profiles are lossless, and
legacy provenance is never fabricated. Asset coverage is inventoried in
`asset-dynamic-coverage-audit.md`; its current proof order is live descriptor adapter, multi-species
map, semantic tile-content collisions, then character and authored-place breadth.

The following integration audit then completed the missing keeper downstream contracts: Animal
Taming/Menagerie, Tannery, Distillery, Deep Works, Library/Lys progression and an all-station
lifecycle/cost matrix. Site rules now have six additional profiles, and focus expansion is reconciled
from 62 live to an exact 85-focus milestone. `docs/README.md` now routes new tasks through current
authority instead of the obsolete anchoring/flora questions. Engineering has begun the Distillery /
Channelworks core slice while continuing dependency-safe traveller rollout.

The following pass added the Deep Works and site catalogue boundaries, the exact 62→85 focus
expansion, safe partial-expedition loss, typed armour gambit marks for Talin, and the non-diary
fallback required to guarantee discoverable writing in every world. AssetLab's species/specimen
milestone received recommendations on disclosure-safe visual semantics and flora/terrain proof
constraints; these remain recommendations under the asset lead's authority.
