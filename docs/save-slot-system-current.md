# Save-slot and start-screen system — current

**Status:** P0 next, immediately after Engineering's active checkpoint
**Owner:** Engineering implements; Game Design owns player-facing behavior and safety
**Purpose:** let Aimee maintain independent campaigns and test states without overwriting the only
playable save.

## First implementation

After truthful app loading completes, show a campaign start screen rather than opening the sole save
implicitly:

- **Continue** opens the most recently played valid slot and names that campaign beneath the action;
- **New Game** creates a distinct slot and never overwrites another campaign;
- **Load Game** exposes every slot as a compact card with campaign name, last-played date, Binder
  level, current location/state and enough progression context to distinguish test saves;
- a player-facing **Campaigns** action in Settings safely flushes the active slot and returns to this
  chooser; switching saves must not require force-quitting the app;
- each slot retains the existing automatic-save behavior while it is active;
- deleting a slot is a secondary action, requires an explicit confirmation naming the campaign, and
  returns safely to the remaining save list;
- an empty installation makes New Game primary and does not show a misleading Continue action.

The initial slot list should be data-driven rather than a fixed number of placeholder boxes. Storage
limits may be added only if a real platform or usability constraint appears.

## Migration and integrity

- On first launch after the change, adopt the existing single save into exactly one slot without
  resetting, duplicating or rewriting campaign progress.
- Slot identity is a stable UUID, never a display name or list index.
- Save metadata and payload updates commit atomically. A crash cannot point the slot catalogue at a
  partially written campaign.
- A corrupt or future-incompatible slot remains visible with a clear recovery/export message; it
  must not prevent loading other healthy slots.
- Compatibility checks cover both the outer slot-envelope schema and the inner game-save schema.
  An older build may inspect/export either future form but may not load or overwrite it.
- Corrupt and future-incompatible slots can still be exported and deliberately soft-deleted without
  first decoding them as playable state. Confirmation uses stable slot identity as well as its
  displayed name/date, so duplicate campaign names cannot make the target ambiguous.
- Continue ignores invalid slots and chooses the most recently played valid campaign.
- New Game creation, switching slots and deletion must flush or finish the active slot's pending save
  before changing ownership.
- Deletion removes only the exact confirmed slot. If practical, use a recoverable soft-delete/trash
  period for playtest builds before permanent removal.

## Testing affordances and boundaries

Save slots are player-facing infrastructure, but their first audience is Aimee's playtesting. Show
the build/save-schema version in DEBUG slot details and preserve existing save import/export tooling.
A later contained checkpoint may add **Duplicate save** for branching a test state, but it is not
required for the safe first slice.

Do not add cloud synchronization, accounts, named difficulty modes or a redesigned new-game flow to
this checkpoint. Do not make the splash screen itself interactive: static launch → truthful loading
→ campaign start screen remain separate phases.

## Acceptance

1. Existing installed campaign migrates and resumes with byte-equivalent meaningful state.
2. Two newly created campaigns progress independently across relaunch and slot switching.
3. Continue consistently opens the most recently played valid campaign.
4. Cancelled deletion changes nothing; confirmed deletion removes only the named slot.
5. Deleting the active, final or a non-active slot always leaves a usable start screen.
6. A deliberately corrupt slot does not crash launch or hide/load over a healthy slot.
7. Force-quit during create/save/switch/delete cannot lose or cross-wire another campaign.
8. Compact-phone and large-text layouts keep every slot action reachable without ambiguous row-wide
   destructive taps.
9. Campaign A → Settings/Campaigns → Campaign B → Campaigns → Campaign A works without relaunch and
   preserves both independent states.
