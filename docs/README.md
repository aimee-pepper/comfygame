# `docs/` — authority and routing

The repository Markdown is the shared design record for Aimee, Game Design, Engineering and Assets.
Current working documents stay aligned to the present game; superseded reasoning remains available
as history rather than competing instructions.

## Start here

Read in this order:

1. `current-design-index.md` — authoritative route to every live system and traveller document.
2. `design-lead-handoff.md` — project principles, responsibilities and current operating state.
3. `state-of-the-build.md` — current implementation/content snapshot.
4. `the-queue.md` — detailed design-ready and implementation work.
5. `design-review-queue.md` — placeholders, playtest questions and deliberate holds for Aimee.
6. `engineering-questions-for-aimee.md` — concise running implementation questions and temporary
   choices.
7. `BACKLOG.md` at repository root — engineering milestone checklist.

Do not begin a new task by treating `open-questions.md`, `questions-for-design.md`, an old audit or a
proposal as current authority. Many of their questions have since been resolved.

## Authority order

When documents disagree:

1. A clearly labelled current system document linked by `current-design-index.md` wins.
2. `decisions-session-18.md` records the current lead pass and wins over older session material for
   covered topics.
3. `design-review-queue.md` states whether a call is settled, playtest-current, placeholder, review
   or hold.
4. `roster-coherence-audit-current.md` controls cast-wide ownership/distribution.
5. Older proposals and combined logs supply reasoning only.
6. Files under `archive/` are historical and never implementation authority.

Implementation convenience does not silently revise a settled design. Engineering may use a
clearly labelled reversible placeholder and records it for review.

## History

- `design-brief-v0.md` is the original project shape and remains valuable context.
- `decisions-log.md` combines early sessions through session 15.
- `decisions-session-16.md` and `decisions-session-17.md` preserve later pre-takeover decisions.
- `decisions-session-18.md` is the current lead-pass archive.
- `open-questions.md`, `questions-for-design.md` and `for-design.md` are historical referral sources
  wherever the current index says a topic has moved.

Do not delete old decisions merely because they changed. Move obsolete point-in-time audits into
`archive/` only after repairing active links; otherwise leave them in place behind an explicit
supersession note.

## Current system families

The index now routes current authority for:

- writing vocabulary, focus pacing, compound assembly, descriptions and Void;
- flora, creatures, predation, apexes and animal companionship;
- combat trees, progression, gear crafting and all specialist stations;
- travellers, signatures, 251-page target diary corpus and teaching ownership;
- Tavern/generated people, Library/Lys depth and curio knowledge;
- anchoring, renewable realm production, Deep Works and the Great Work boundary;
- tutorial/discoverability, sites and the asset-system review.

This list describes design coverage, not implementation completion. `state-of-the-build.md`,
`the-queue.md` and `BACKLOG.md` distinguish what is designed from what is live.

## Collaboration discipline

- Game Design records decisions and reversible placeholders in Markdown before handing them off.
- Engineering owns game code, migrations, tests and device integration.
- Assets owns standalone art systems and tooling; Engineering owns in-app integration.
- Aimee reviews material challenges and the short active question queue rather than being asked to
  approve every routine content batch.
- Progress summaries point to current files so another task never has to reconstruct authority from
  chat history.
