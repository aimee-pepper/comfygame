# comfygame — "Bookbinder" (working title)

Turn-based iPhone game. Design lives in `docs/` (source of truth), work order in `BACKLOG.md`,
team process in `WORKFLOW.md`, engineering rules in `CLAUDE.md`.

## Running it

The Xcode project is **generated** from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate && open Bookbinder.xcodeproj
```

Re-run `xcodegen generate` after adding or removing source files — sources are globbed from
`Sources/`, so new files don't appear in the project until you do.

To run on your iPhone: plug it in, pick it as the run destination, hit ⌘R. Free Apple ID
provisioning expires after 7 days; rebuild to renew.

Tests (⌘U in Xcode, or):

```bash
xcodebuild -project Bookbinder.xcodeproj -scheme Bookbinder -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Layout

| Path | What's in it |
|---|---|
| `Sources/Model/` | The save file: `GameState` + the three layers (`RealityState`, `BaseState`, `WorldsState`) |
| `Sources/Persistence/` | Atomic debounced save/load, backup recovery, schema migrations |
| `Sources/Content/` | Catalog loader + the JSON data (symbols, creatures, resources, items, gambits, stations) |
| `Sources/Core/` | Typed IDs, seeded RNG |
| `Sources/Debug/` | The milestone-1 force-quit harness — deleted once the real screens exist |
| `Sources/Tuning.swift` | **Every gameplay number**, all `// PLACEHOLDER` until playtested |
| `Tests/` | Persistence, determinism and content-validation suites |

## The rules that shape the code

1. **Everything goes through `GameStore.mutate`.** It bumps a mutation counter and schedules a save.
   No view keeps its own copy of state; nothing else touches the save file.
2. **Nothing gameplay-related reads the clock.** Decay and instability advance on player turns only.
   The only `Date` in the save is a diagnostic field no rule may read.
3. **Content is data.** Symbols, creatures, items, gambit pieces and base stations are JSON.
   `ContentCatalog.validate()` fails the test run on a dangling ID.
4. **The three layers never reach into each other**, so "reset base, keep reality" stays a
   three-line operation (`GameStore.resetBaseKeepingReality`, and a test that proves it).

## The save file

One JSON file at `Documents/bookbinder-save.json`, plus a `.backup` of the previous good save.
File sharing is on, so you can pull it off the phone in Finder to inspect it. A save that won't
decode is quarantined next to it, never deleted.
