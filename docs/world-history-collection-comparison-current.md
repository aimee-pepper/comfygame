# World History collection and comparison — current design

**Status:** implementation-ready presentation and interaction correction; analysis mechanics remain
authoritative in `description-analysis-surface-current.md`.  
**Owner:** Game Design owns archive/compare behavior; Engineering owns stable selection, deletion and
saved-record schema; Asset Design owns compact frozen world-cover grammar.

## Purpose

World History is the player's experimental notebook: what they wrote, what occurred, and what later
knowledge lets them understand. It should support finding and comparing evidence across a long
campaign, not become forty full-width prose cards.

The current screen has two limitations:

- every world is a large vertical card containing description and written lines;
- side-by-side comparison is available only when a tutorial-owned pair exists.

The detailed record and calibrated disclosure are correct. The collection and selection model are
not yet adequate for a month-long campaign.

## Archive surface

The ordinary History landing uses compact **world covers** in a two-column grid. A cover shows:

- World number and a stable short title, initially **World N**;
- one frozen disclosure-neutral visual swatch/mark derived from the world descriptor version saved
  with that record—not a rerender from current tuning;
- bookmark state;
- up to two small authored-request glyphs plus `+N`, never the full prose list;
- a small **chance-led** mark when nothing semantic was authored;
- traveller-present mark only when that presence is already legitimate History knowledge.

Tap opens the existing detailed record in an anchored/full compact sheet. Full description, written
requests, readings, attribution, clock, living analysis and people remain detail content and keep
their earned analysis gates.

At accessibility text sizes the collection becomes one compact cover per row; it does not return to
embedding the entire record in every row.

### Browse controls

A concise toolbar supplies:

- Search by world number and currently disclosed traveller name;
- filter **All / Kept / Chance-led**;
- sort **Newest / Oldest**;
- **Compare** selection mode.

Future Lys Catalogue filters may add authored stable subjects/references. Before Lys, History never
searches hidden raw readings, undiscovered people or prose keywords that imply an automatic solver.

## Deliberate comparison

Compare mode lets the player select exactly two visible world covers in either order.

1. The first selection becomes **Earlier** only if its run index is lower; presentation chronology is
   determined from records, not tap order.
2. A persistent footer reads `1 of 2 selected` or names both worlds and enables **Compare**.
3. Selecting a third world is impossible until one is deselected; the UI never silently replaces the
   first choice.
4. Selection is ephemeral UI state. Relaunch clears it; tutorial comparison receipts remain separate.
5. The tutorial may preselect its authored pair and explain the same ordinary comparison tool. It
   does not own a special comparison screen.

The comparison uses one union of stable semantic-request keys. Each row is one subject/request and
shows Earlier and Later values with a redundant state:

- unchanged;
- added;
- removed;
- changed.

If a request appears on only one side, the other side explicitly says **Not written**. Do not omit it
from one column and rely on the player to infer absence.

### Measured comparison

For every subject currently calibrated and saved in both records, show both readings and a qualitative
direction: higher, lower or overlapping at the player's current precision. Numeric subtraction is
shown only when the current analysis tier and precision legitimately expose both values.

If only one record contains a legitimate measurement, the other reads **Not measured in this
record**. It never exposes a missing rolled value or uses current simulation to reconstruct one.
Attribution and living-analysis comparisons obey the same gates as a single History record.

World descriptions remain above the structured comparison so the player can compare prose before
numbers. Differences are evidence, not an automated conclusion about which mark caused them.

## Keeping and erasing

- Bookmark toggles in place from cover or detail and never opens a separate screen.
- **Erase record** requires a confirmation naming the exact world and stating that it removes the
  historical record, not an anchored realm or current run.
- A kept record requires a stronger confirmation or must be unkept first; one accidental tap cannot
  erase it.
- Erasing either selected comparison record closes/repairs selection atomically.
- Tutorial pairs referencing a deliberately erased record reconcile safely and never fabricate a
  replacement.
- The existing 40 ordinary-record retention policy remains a tuning placeholder. Kept records are
  exempt; the UI reports when kept records exceed the ordinary cap rather than silently dropping one.

## Frozen cover schema

New history records store a small versioned presentation summary alongside existing evidence:

```text
WorldHistoryCover {
  schemaVersion: Int
  worldVisualDescriptorVersion: String
  paletteFamilyID: String
  atmosphereMarkID: String?
  ecologyMarkID: String?
}
```

`ecologyMarkID` is the stable contract name. It represents the disclosure-neutral visible ecology
grammar frozen into the cover, which may include no flora at all; adapters must not narrow or rename
it to `floraMarkID`. None of these IDs is an analysed trait, hidden population fact or semantic
reading. They may reproduce what the player could already see in the saved world's cover image, not
explain why it looked that way.

Comparison input is also a prepared, disclosure-filtered view rather than the raw history record.
Each measurement supplied to comparison carries its currently earned availability and precision;
the comparison resolver receives only a display value/range plus `higher`, `lower` or `overlapping`
when that relation is legitimately knowable. It must not accept an unrestricted raw-number map and
decide disclosure merely from the presence of a number. Reopening the same comparison after earning
better analysis may reveal more because the player's knowledge changed; the frozen record and cover
remain unchanged.

This is a frozen historical thumbnail identity, not the full generated asset. Legacy records without
it use one honest neutral paper/world mark and never reroll a pseudo-history from current algorithms.
Changes to Asset rendering may improve how the frozen IDs are drawn but cannot change which IDs an
old world recorded.

## Acceptance

1. Forty records are browseable as compact covers; opening one retains every current earned-analysis
   field without repeating it on the landing grid.
2. Any two visible records can be selected and compared; tutorial comparison uses the same path.
3. Added/removed/changed/unchanged derive from the union of stable request keys and are invariant to
   tap order, display sort, wording order and array order.
4. Measured comparison never exposes an uncalibrated subject or reconstructs absent saved readings.
5. Search/filter cannot reveal undiscovered travellers or hidden world subjects.
6. Kept and ordinary erasure confirmations, stale selection and tutorial-pair reconciliation are
   loss-safe and deterministic.
7. New covers freeze versioned visual identity; legacy covers do not reroll.
8. At 368×800 and large text, covers, selection footer, anchored detail and comparison remain usable;
   grayscale and VoiceOver announce bookmark, selected order, authorship difference and measurement
   availability without colour.
