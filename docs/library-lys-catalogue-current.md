# Lys's Library catalogue — current first slice

**Status:** implementation-ready keeper upgrade and recovery-provenance correction.  
**Owner:** Game Design owns catalogue/disclosure; Engineering owns recovery records, migration and
queries; Aimee owns final page/reference glyph art, while Asset Design may validate functional
placeholder layout/state only.  
**Depends on:** `library-collection-accuracy-current.md`, `library-lys-progression-current.md` and
`rune-pacing-library-legibility-current.md`.

## Outcome

The opening Library remains fully usable without Lys. Recruiting Lys attaches her as keeper to that
existing room and immediately adds three organisation tools:

1. **Catalogue** — search/filter recovered writing by facts the player legitimately knows.
2. **References** — typed links among author, subject, site, teaching and recovery world.
3. **Writability** — the non-spoiling marker for whether the current hand can ask toward a location
   clue reliably.

These tools arrange evidence. They do not translate diary prose into pressure conditions, assemble a
traveller signature checklist or tell the player which world to write.

## Required recovery record

`LibraryState.foundPages: [DiaryPageID]` preserves order but not where a page was found. It cannot
support the already-promised world filter or page→History link. New recovery uses:

```text
RecoveredPageRecord {
  pageID: DiaryPageID
  discoverySequence: Int
  foundInOutcomeID: ExpeditionOutcomeID?
  foundInWorldRecordID: InstanceID?
  foundAtSiteID: SiteID?
}
```

- `pageID` remains globally unique recovery identity; repeated placement never creates another
  record or reward.
- World/outcome/site provenance is frozen at first successful read, not inferred later from the
  current run or page preference.
- `foundPages` becomes a derived compatibility projection or decode-only migration input.
- Legacy IDs migrate in their saved order with increasing sequence and nil provenance. The UI says
  **Recovered before location records** rather than guessing a world.
- Unknown page IDs retain their record/provenance in Older records.

Recovery record, page unlock/reward, discovery XP and run-summary reporting commit atomically. A
duplicate page tile changes none of them.

## Catalogue interaction

Lys adds one search control above the existing Diaries / People / World Notes / History tabs. Search
matches only recovered/known display content:

- visible author or subject name;
- visible site name;
- page-kind label;
- teaching name already revealed by recovering that page;
- recovered prose substring;
- World number when provenance exists.

It may not search hidden condition fields, preference conditions, unrecovered catalogue prose,
unknown traveller names, internal IDs or raw pressure values.

Filter chips are **Kind / Writer / About / Teaching / World**. Each filter offers only values present
in recovered records and currently legitimate to label. Results preserve discovery order by default;
optional Writer and Newest sorting never changes the underlying record.

Search/filter state is a local UI preference. Empty results explain which filters are active and
offer **Clear filters**; they never imply that a matching unrecovered page exists.

## Typed references in page detail

Every opened recovered page shows only references backed by explicit fields:

- **From this diary** → `diary`;
- **About** → `about`;
- **Place mentioned** → `site`;
- **Carries** → `teaches`, `teachesFocus`, `teachesGambit`, `teachesPattern`, or `researchNode`;
- **Recovered in** → saved World History record;
- future authored relationship IDs only after a validated explicit field exists.

Do not infer links from coincidental names or embedding/keyword similarity. Prose search locates text;
it does not manufacture a relationship.

An unknown referenced person/site uses **Unresolved person/place** and a stable neutral mark. When
that target becomes legitimately known, the label resolves in place. If the prose itself names them,
the prose remains verbatim; the catalogue does not add extra hidden metadata early.

World links open the exact saved History record. Missing/erased History says **Record no longer
kept** while preserving the page's frozen recovery provenance; it does not retarget another world.

## Writability marker

Only location-clue pages receive this marker, and only while the subject has not been recruited:

- **Your current hand can ask toward this passage.**
- **You do not yet have the words to ask for this reliably.**
- **They are already Home.**

The state comes from the same reachability solver used by world-writing validation and the single-
target pity system. It answers whether at least one legal page using currently owned vocabulary can
produce a world satisfying that clue's hidden condition. It never names the pressure, direction,
threshold, missing focus, compound or exact page layout.

“Can ask toward” is not “will guarantee”: unwritten pressures, conflicting requests and world
simulation may still matter. The detail links to the Writing Desk without pre-filling or exposing the
solution.

## Compare boundary

The first Lys slice does not invent semantic page comparison. A later explicit **Compare passages**
mode may place two recovered pages side by side and highlight exact repeated authored strings, using
the selection grammar from World History. It cannot score truth, summarize meaning or infer that two
different phrases describe the same condition.

## Keeper and availability

- Basic Diaries, People, World Notes, History, reading and page rewards never require Lys.
- Recruiting Lys attaches her to the existing Library with no construction charge and unlocks the
  Catalogue root immediately.
- Moving Lys away from Home suspends keeper discounts/active assistance but never hides already
  indexed records, search, references or writability markers.
- No separate duplicate Library station or generic locked Catalogue tile appears.
- Deeper paid tiers wait for a real additional player capability; do not sell search speed or more
  result slots.

## Acceptance

1. A new save without Lys reads and uses every recovered page exactly as before.
2. Lys recruitment preserves all records and immediately enables truthful search/filter/reference
   tools without construction.
3. First read atomically creates one provenance record, reward and XP receipt; duplicate reads create
   none.
4. Legacy/unknown page IDs migrate without fabricated world/site provenance or silent omission.
5. Search cannot return unrecovered prose, hidden condition data or unknown names; shuffling catalogue
   content does not alter discovery order.
6. Every reference is backed by an explicit typed field and survives target unlock/History erasure.
7. Writability uses the actual current-hand reachability solver but exposes none of its hidden
   condition vocabulary.
8. At 368×800 and large text, search, chips, page grid, anchored detail and references remain usable;
   VoiceOver announces reference kind, resolved/unresolved state and writability without colour.
