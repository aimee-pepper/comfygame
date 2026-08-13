# Expedition return receipt — current

**Status:** implementation-ready correctness consolidation  
**Owner:** expedition outcome rules; recap UI is a consumer  
**Roadmap ID:** `return-receipt-authority`

## Why this exists

Pages and recruited travellers were once acquired correctly but omitted from the return summary.
Those specific fields are now present, but full-haul and partial-haul exits still construct
`RunExitSummary` separately and repeat its complete field list. Every new recap category can
therefore land in one exit path and silently disappear from another.

The recap is not presentation assembled after the fact. It is the immutable, idempotent receipt for
one `ExpeditionOutcomeID` and must be frozen by rules inside the same atomic return mutation that
banks or loses the haul.

## One constructor

Use one rules-owned constructor with inputs equivalent to:

```text
makeReturnReceipt(
  run,
  outcomeID,
  outcome: kind + reason,
  haul: exact BankedHaul + kept fraction,
  springYield,
  postBankState
) -> RunExitSummary
```

Portal, Waystone, collapse, defeat and abandon may choose their genuine outcome kind, reason,
retention fraction and pre-return consumed item. They may not enumerate recap fields themselves.

The constructor freezes every current category:

- run/outcome identity, outcome kind/reason and turns;
- kept fraction, kept resources/items and lost resources/items;
- per-member XP and level gains;
- XP source breakdown;
- newly recovered diary pages;
- newly recovered field notes, route marks, site fragments and working scraps;
- newly recruited travellers; and
- Raw Essence returned, refined equivalent, bind cost, Spring yield, subsidy if any and resulting
  spendable runway.

### Stable loot identity, not frozen SF-symbol rows

`RunExitGain(name, icon, count)` is not a sufficient receipt line. It throws away the stable
resource/item ID, exact gear profile, identification state and provenance, and its derived
`name-icon` identity can collide. It also freezes a fallback SF Symbol so the recap cannot consume
the same accepted resource/item artwork as Storehouse, Trading Post, Recycler and equipment.

The canonical receipt uses typed lines:

- **resource line:** stable `ResourceID`, exact retained/lost quantity and frozen fallback name;
- **stackable item line:** stable `ItemID`, exact homogeneous bin/profile key, quantity,
  identification/provenance facts needed by detail, and a stable receipt-line ID;
- **unique gear/object line:** stable item instance ID plus the complete frozen instance profile,
  upgrade/wild-growth/lock/favourite/identification/provenance facts and one-count line;
- **unknown historical line:** frozen label/icon fallback only, decode-compatible and visibly marked
  as legacy rather than guessed into a current catalogue object.

Receipt presentation resolves the current accepted pictorial asset through the stable catalogue ID
and retains the frozen label as historical fallback. It does not store a screen-local icon choice.
Truly identical stackable units may aggregate; property-bearing or unique items may not collapse by
catalogue ID. Retained and lost lines preserve the exact partition produced by banking.

On an ordinary phone, Resources and Loot use the settled six-across icon trays with quantity badges.
Tapping a tile opens the same edge-clamped anchored detail grammar as other physical-object screens;
it does not navigate away from the recap. The popup uses only the frozen receipt line, never current
Storehouse state, because the item may since have moved, been equipped or been lost.

“Newly” is measured from the departure baselines already stored on `WorldRun`, never from screen
state or recap dismissal. Exact outcome-dependent loss remains different; knowledge, recruitment
and earned progression do not disappear merely because the physical haul was partial.

## Atomicity and idempotence

- Build the receipt after banking has produced the exact `BankedHaul` and after progression/knowledge
  mutations that it summarizes, but before clearing `activeRun`.
- The receipt and its `ExpeditionOutcomeID` are written in the same flushed mutation as banking.
- Replaying, relaunching or revisiting an anchored realm cannot mint or apply a second receipt.
- Dismissing the screen removes only the presentation pointer; it does not undo or recompute facts.
- Old receipts decode missing categories as empty/default exactly as they do now.

## Acceptance

1. Drive one seeded run containing resources, an ordinary and protected item, XP from at least two
   source types, a diary page, another writing family and a recruited traveller through every exit
   kind.
2. Full and partial paths agree on every non-loss-dependent category; only retained/lost haul and
   explicit outcome metadata differ.
3. Waystone consumption is atomic and cannot appear in returned or lost loot.
4. Storehouse overflow preserves exact returned item identity while the receipt reports the banked
   item once; unique profile/upgrade/provenance facts round-trip and are visible from anchored detail.
5. Relaunch before recap dismissal preserves the exact receipt; dismissal and another relaunch do
   not recreate it.
6. Adding a future `RunExitSummary` category requires one constructor change and a completeness test,
   not edits to each exit path.
7. The recap UI renders only the frozen receipt and performs no catalogue/state diff to invent
   missing results.
8. Resource and item tiles resolve the shared native identity assets from stable IDs, appear six
   across at ordinary phone size, and retain truthful quantity plus edge-clamped detail.
9. Two lines with the same fallback name/icon but different stable IDs or instance profiles do not
   collide, merge or become inaccessible to VoiceOver.
