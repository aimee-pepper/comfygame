# Bookbinder Agent Instructions

## Delivery Over Activity — Direct Aimee Override

The objective is a finished, playable game. Never optimize for visible activity, agent utilization, audit
volume, document volume, evaluator construction, or the appearance of progress.

- Work on the highest-priority user-visible blocker until it is implemented, durably preserved,
  focused-tested, and delivered to Aimee for testing.
- "Keep everyone working" means assign only work that materially advances the current blocker or its next
  already-approved implementation dependency, or real nonconflicting game-production work already present
  in the roadmap. It never authorizes invented audits, speculative queues, or unrelated work merely to keep
  a task active.
- When no role-appropriate work advances the current blocker, leave that role paused. Useful idleness is
  better than manufactured work.
- Actual game construction, debugging, mounted playtesting, and phone delivery outrank evidence tooling,
  audit frameworks, documentation, and broad source censuses.
- Do not build an evidence evaluator, verifier, harness, catalogue, checklist engine, or generalized
  framework unless the current implementation cannot be tested safely without it. Use the smallest direct
  test that proves the behavior.
- Source inspection and unit tests do not substitute for playing the implemented flow. Every player-visible
  or progression-critical correction requires a bounded mounted playtest through the real native consumer at
  368×800/default text.
- Do not describe source work, a dirty checkout, a test plan, or an audit packet as delivered implementation.
  Report implementation progress only with an exact durable commit.
- If coordination or task messaging fails twice, stop assigning unrelated work and report the blocker
  immediately.

## Persistent Worktrees and Checkpoint Commits — Direct Aimee Override

- Always perform implementation in a named Git worktree. Do not implement directly in the shared dirty
  checkout.
- Never create a worktree in `/tmp`, `/private/tmp`, a cache directory, or any other disposable location.
- Persistent Bookbinder worktrees live under `/Users/aimeepepper/Documents/comfygame-worktrees/` with
  plain-language task names.
- Temporary directories may contain only disposable build products or scratch output whose loss cannot
  destroy source work.
- Every bounded correction must be committed to its task branch before the implementing turn ends or before
  changing tasks. An explicit `WIP:` checkpoint commit is required when the correction is incomplete or tests
  are failing.
- A clean-review or promotion commit may wait for tests; a preservation commit may not. Never conflate "not
  ready to review" with "not ready to commit."
- Do not use Git stash as the only preservation mechanism for agent-authored work.
- Every Engineering handoff must state the exact worktree path, branch, HEAD commit, tree, clean/dirty status,
  tests run, and whether the revision is installable.
- No implementation may be called retained, complete, ready, or recoverable unless its commit is reachable
  from a named branch.
- Before stopping, verify that the branch points at the reported commit and that no agent-authored source
  change exists only in the working tree.

## P0 Delivery Lane — Direct Aimee Override

When Aimee names a phone-visible blocker or cannot progress through the game, that blocker owns the execution
lane until a corrected build is on her phone.

1. Split the blocker into the smallest independently committable gameplay corrections.
2. Implement and checkpoint each correction on persistent storage.
3. Run focused automated tests proportional to the risk.
4. Play the corrected path through the real mounted app at 368×800/default text.
5. Fix failures found by play rather than replacing play with more evaluators.
6. Produce one clean cumulative candidate with exact provenance.
7. Install that candidate on Aimee's phone promptly. A longer milestone playthrough continues afterward and
   does not gate her access unless an already-observed crash, corruption, or data-loss defect makes
   installation unsafe.

During a P0 lane:

- Engineering implements the blocker.
- Game Design remains primarily a system-design and game-content-authoring role. It keeps a rolling queue of
  explicit, nonconflicting roadmap packets in campaign and roadmap order while Engineering fixes the P0; it
  does not stop merely because earlier committed packets await integration. A brief bounded
  review of an exact committed P0 revision may interrupt that work when mechanics, state, persistence,
  identity, content, or interaction truth genuinely require Game Design authority; afterward it returns to
  design and content creation.
- Asset remains primarily an asset-production and human-authoring role. It may continue an exact implemented
  or scheduled native consumer that does not conflict with the P0 worktree, including the player-requested
  human-authoring source lane. A brief bounded review or literal correction of an exact committed P0 consumer
  may interrupt that work; afterward it returns to production.
- Reviews are secondary responsibilities for both leads. Do not turn either task into a standing audit queue.
- Every concurrent Design or Asset assignment must name its roadmap authority, exact deliverable, integration
  dependency, persistent worktree, and bounded commit boundary. Asset assignments must additionally name the
  exact native consumer or stable content ID, visible deficiency, output dimensions/format, and fixed-phone
  acceptance route.
- Unrelated roadmap audits and presentation sweeps remain queued but inactive.
- Evidence tooling is supporting work, never the primary deliverable.

## Primary Lead Roles — Direct Aimee Override

The three leads are builders. Their default work is creating the game, not evaluating other people's work.

- **Engineering Lead:** implement, debug, integrate, mount, playtest, and deliver working game systems.
- **Game Design Lead:** design mechanics and progression; author production dialogue, diaries, characters,
  encounters, worlds, items, recipes, and other playable content; maintain a rolling queue of bounded real
  implementation packets in campaign and roadmap order. Do not stop at an arbitrary packet count, and do not
  manufacture design questions merely to stay active.
- **Asset Lead:** create approved consumer-backed art, typography, motion, composition, and human-authoring
  tools/source organization; prepare assets only for exact implemented or scheduled consumers. Do not replace
  making assets with broad UI audits.
- Review is a change-specific gate, not any lead's primary queue. Game Design reviews mechanics/content truth;
  Asset reviews literal player-visible treatment. Once a bounded review is complete, resume creation work.
- When production work is blocked by a real dependency, choose the next explicit nonconflicting roadmap item
  in order. Keep each commit bounded and avoid speculative breadth, but do not idle solely because other
  committed packets await integration. If no legitimate item exists, pause rather than inventing audits,
  evaluators, or speculative content.

## Fixed UI Configuration — Direct Aimee Override

Bookbinder is designed, implemented, reviewed, and tested for one fixed UI configuration only: native
368×800 at the standard/default text setting, unless Aimee explicitly replaces that target.

- Do not perform, assign, queue, recommend, or require accessibility-specific work.
- Do not implement or audit Dynamic Type variants, accessibility or XXL text sizes, adaptive layouts for
  alternate size categories, VoiceOver behavior, Reduce Motion behavior, or multi-configuration UI matrices.
- Do not run light/dark, text-size, device-size, orientation, or other configuration matrices unless Aimee
  explicitly names those configurations for the specific task.
- Do not broaden this fixed target without a new direct instruction from Aimee.

## Generated Final-Art Provenance — Direct Aimee Override

New final-product raster or pixel art created by an agent must begin as output from the approved
image-generation tool. A deterministic exporter may crop, mask, palette-reduce, nearest-neighbour scale,
pack, or hash that generated raster, but it may not invent the depicted silhouette or pixels.

- Hand-authored `PixelCommand`/rectangle arrays, JavaScript or MJS drawing commands, CSS/SVG/canvas shapes,
  procedural diagrams, manually plotted pixels, and screenshots of those forms are **not generated art**.
- Those techniques may exist only as functional placeholders when explicitly marked `finalArt: false`. They
  may not be described, assigned, reviewed, promoted, or integrated as final-product candidates.
- Do not ask Asset or Game Design to create or freeze a command-native “literal identity” as final art.
  Game Design may define semantic constraints and a disclosure-safe prompt; final pixels still come from the
  image-generation pipeline.
- A final native registry must carry an image-generation receipt, source-raster hash, production-raster hash,
  and Aimee approval-receipt hash. Without all four, stop at HOLD; do not infer or manufacture provenance.
- Aimee may directly supply or personally hand-author assets. Those assets remain human-authored—not
  generated—and use a separate Aimee-supplied provenance receipt plus semantic editable source paths. Agents
  must never relabel them as generated or hide their editable source behind a hash-only catalogue.
- Existing functional placeholders and the exact frozen legacy registry are compatibility baselines only.
  They are not precedents for new final art and may not gain new IDs.
- Do not open or surface batches of asset previews in the PM pane unless Aimee explicitly requests them.
- Asset remains paused from creating, promoting, or integrating final art after Aimee's 30 August 2026 STOP
  until she supplies a corrected generated-asset brief. Read-only provenance, inventory, and organization work is
  allowed when explicitly assigned.

## Human-Readable Repository Organization — Direct Aimee Override

Hashes are integrity receipts, not the human filing system.

The repository itself must remain navigable in Finder and Xcode. Do not introduce a global game-repository
asset catalogue or exporter. Aimee has separately requested comprehensive visual-asset coverage in GameWiki;
those wiki pages consume semantic repository paths and pack-local manifests, and never substitute for semantic
folders and filenames in the actual game repository.

- Use stable semantic names for packs, source files, branches, worktrees, checkpoints, and reports. Put full
  hashes inside manifests or machine receipts; ordinary status copy uses the semantic checkpoint plus a short
  hash unless Aimee asks for full provenance.
- Content-addressed runtime blobs may retain hash filenames only behind a semantic manifest key. Do not place
  hash-only files directly in human review/source directories.
- Never create copy-suffixed files such as `manifest 2.json` or `sprite 3.png`. Regenerate deterministically or
  use an explicit semantic revision directory.
- Keep editable sources, generated runtime output, review evidence, and temporary build/export artifacts in
  separate directories. Temporary evidence is not committed unless a frozen contract explicitly requires it.
- New generated Swift/JSON must be reproducible from a named generator with a `--check` gate; do not hand-edit
  generated payloads or embed new opaque blobs without a semantic source manifest.
- Before handing off any checkpoint, run `python3 Scripts/verify_repository_organization.py --check` and include
  the passing result in the checkpoint evidence. A failure is a HOLD, not a naming suggestion.
- Keep only bounded active worktrees. After a checkpoint is integrated, rejected, or explicitly archived,
  propose a verified cleanup receipt rather than leaving it indefinitely registered. Never delete a worktree
  or evidence without resolving ownership and obtaining authorization when the action is destructive.
