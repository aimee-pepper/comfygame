# DEBUG Roadmap derived workstreams — current

**Status:** implementation-ready process/schema correction  
**Owner:** shared project status JSON; DEBUG UI derives presentation  
**Supersedes:** exactly-one-global-`inProgress` validation and manually copied header/build strings

## Problem

The Roadmap source currently repeats three presentation fields—`currentWork`, `currentNote` and
`installedCheckpoint`—beside the item records that already own status and detail. Tests also demand
exactly one global `inProgress` item. That model fails during normal work: an installed world-color
checkpoint can be `readyToTest` while Engineering fixes field controls, Design prepares acceptance,
and Asset holds or advances a separate proof.

Changing an unrelated item to `inProgress` merely to satisfy the test makes the board look green but
does not make it truthful. The app should derive headers from the real item records and build
identity, while retaining authored priority/status judgment.

## Schema v2

Remove these root-level authored mirrors from current data:

```text
currentWork
currentNote
installedCheckpoint
```

Every roadmap item owns:

```text
id                  stable unique ID
title
priority            P0 | P1 | P2 | P3
status              queued | ready | inProgress | readyToTest | accepted | held
workstream          engineering | design | asset | acceptance
isPrimary           Boolean; default false
detail              current evidence/rationale
gate                evidence required to accept
checkpoint          optional commit/build reference for that item
```

`workstream` answers who/what kind of work is active; it is not feature ownership. A feature may
move from Design to Engineering to acceptance by updating its workstream and status rather than
creating duplicate roadmap items. If simultaneous genuinely independent slices of one feature must
be tracked, give each a stable slice ID and explicit parent ID.

## Derived header

The DEBUG landing header is computed in this order:

1. all `isPrimary && status == inProgress`, grouped in workstream order Engineering, Design, Asset,
   Acceptance;
2. if a workstream has no in-progress primary, its `isPrimary && status == readyToTest` item may
   appear as **Awaiting test**, never as current implementation;
3. if no primary item exists anywhere, show the highest-priority `readyToTest`, then `ready`, then
   `queued` item with an honest status label;
4. never infer priority from JSON array order.

Validation allows **zero or one primary active item per workstream**, not exactly one globally.
Multiple workstreams may be active simultaneously. Two primary `inProgress` items in the same
workstream fail with both IDs. An item cannot be primary while `accepted` or `held`.

The header note comes from each displayed item's own `detail`; the UI does not store another note.

## Installed build identity

Build/commit identity is generated into the app bundle during build:

```text
commitSHA
buildConfiguration
buildNumber
builtAtUTC
dirtyAtBuild       DEBUG diagnostic only
```

The Roadmap header displays that actual identity plus any item's optional checkpoint reference. It
does not require someone to edit JSON after installation. A checkpoint mismatch is useful evidence:
**Installed bd2b5d2 · item expects later field-controls checkpoint**, rather than silently relabeling
the old binary.

Release builds may omit `dirtyAtBuild`; missing build metadata displays **Build identity unavailable**
and fails the DEBUG verification target rather than borrowing `installedCheckpoint` from JSON.

## Migration and editing boundary

- Decode schema-v1 files by ignoring the three mirror strings and assigning a reviewed stable
  workstream/default-primary map once; write only schema v2.
- `playability-roadmap.json` remains the single authored status source bundled into the app. Runtime
  never parses Markdown or attempts to query Codex tasks.
- Status changes remain human judgment; header selection, counts, grouping and build identity are
  derived. Automation must not claim work accepted merely because tests pass.
- Array order is presentation-neutral. Each workstream has an explicit display order and items use
  priority plus stable ID unless an authored `displayOrder` is later proven necessary.

## Acceptance

1. World Color may remain `readyToTest` in Acceptance while Field Controls is `inProgress` in
   Engineering; both appear with truthful labels and validation passes.
2. Design and Asset primary items may coexist with Engineering without stealing its header or
   failing a global count.
3. Two Engineering primaries fail with both IDs; zero global `inProgress` items is valid when work
   is honestly queued/awaiting test.
4. Removing/reordering the JSON array leaves grouping/header choice unchanged.
5. Root mirror strings are absent from encoded/current schema and cannot override item detail.
6. The installed commit/build shown in DEBUG equals compiled bundle metadata and cannot be changed by
   editing roadmap JSON alone.
7. Schema-v1 decoding preserves every item/status/detail and produces one deterministic reviewed
   workstream assignment; unknown future workstreams/statuses diagnose rather than silently map to
   Engineering.
8. Roadmap updates change no campaign save and require no migration of player data.

