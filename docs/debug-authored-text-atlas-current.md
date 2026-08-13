# DEBUG Authored-Text Atlas — Current

**Status:** built, pushed and accepted as the DEBUG review surface in commit `9cc0f10` (9 Aug 2026).
All 21 missing-live meeting drafts, Noll's replacement and Auber's revision are present in the review
corpus without replacing shipped content. Noll is now a live traveller with a provisional meeting;
older DRQ-166 language about adding her to the live union is superseded.
the full native suite passed 828/0 and the phone reader evidence is
`docs/test-artifacts/authored-text-atlas-v1.jpg`. The atlas does not authorize prose changes by itself.

## Purpose

Aimee needs one place to read the complete authored corpus in actual presentation context, mark what
works, flag revision, and leave a note. Design also needs a reproducible audit rather than finding
abstract or mismatched lines only when a campaign happens to surface them.

The atlas covers all 29 named travellers, including missing content. It must not hide absent meeting
objects or pages behind empty filters.

The four `traveller-meetings-*-review.md` documents contain complete exact draft copy for all 21
missing-live meetings plus Noll's replacement candidate. A DEBUG-only structured source or generated fixture may mirror those drafts so
the native atlas can render them. Do not parse Markdown at runtime, move unapproved drafts into the
shipped traveller catalogue, or reduce them to a Boolean “draft available” badge. Auber is a distinct
case: show his current live meeting and the review revision candidate side by side under the same
stable exchange IDs, with independent exact-text hashes.

## Corpus

The atlas row set is the **union** of live catalogue traveller IDs and review-corpus traveller IDs.
It is not permitted to infer review availability solely from live meeting presence. Noll is the live
twenty-ninth identity with both a provisional meeting and a visible replacement-review candidate.
Draft-only meeting data uses generated DEBUG review metadata from the reviewed source; it does not
enter release content or campaign saves until exact promotion.

Current derived census:

- 29 live catalogue travellers;
- 8 live meeting objects and 21 live travellers missing meetings;
- 23 review meetings: those 21 missing-live meetings, Auber's side-by-side revision and Noll's
  replacement candidate;
- 29 distinct review identities across the union;
- 238 live diary pages.

These figures are named milestone evidence, not the inventory algorithm. Adding another draft-only
or live identity updates the union automatically and fails only genuine missing/duplicate metadata.

For every traveller show:

- identity, calling, campaign phase and authored order;
- meeting opening, each stable question/reply exchange, offer, accepted and declined lines;
- every diary page in packet/authored order and actual eligible kind;
- exact location condition or delivery dependency behind a developer disclosure;
- teaching/reward semantic ID and target, where applicable;
- whereabouts/relationship target IDs;
- validation errors, missing meeting sections, missing stable IDs and unresolved forward references.

The primary reading surface uses player-facing prose and the same text styles/component path as the
game. Raw JSON/condition data is secondary inspection material, never the default reading mode.

## Review record

Each stable authored unit has one review entry:

```json
{
  "schemaVersion": 1,
  "entries": {
    "meeting.isolde.exchange.isolde.blank_board.reply": {
      "status": "needsRevision",
      "note": "Explain the physical exercise before the metaphor.",
      "reviewedTextHash": "sha256-of-exact-current-text",
      "reviewedAt": "2026-08-09T00:00:00Z"
    }
  }
}
```

Statuses are exactly `unreviewed`, `good`, and `needsRevision`. `unreviewed` may be omitted from the
file. Notes are optional. The exact-text hash makes a changed line visibly **stale** instead of
silently inheriting approval. Review metadata never enters `GameState`, campaign saves or shipped
content JSON.

The DEBUG app keeps its writable working copy in its sandbox and supports explicit JSON import/
export through the system document/share flow. A checked-in review snapshot may live outside the
shipped content bundle for cross-lead history; importing/merging is by stable entry ID, newest
timestamp only when both hashes match, with conflicts shown rather than discarded.

## Interaction

- Start on a traveller list showing counts for Good / Needs revision / Unreviewed / Stale / Missing.
- Filter by traveller, phase, text kind, review status, teaching kind and validation issue.
- Search exact prose, IDs and notes.
- Open one traveller as a continuous readable atlas, not a table of truncated snippets.
- Mark Good or Needs revision and edit a note without leaving the reading position.
- Jump Next unreviewed / Next needs revision.
- Preview meeting choices independently and in arbitrary tap order through the same ordered meeting
  transcript component used by the game.
- Preview diary pages as their real found-page/result card, including line wrapping and large text.
- Export the filtered report as JSON and a human-readable Markdown summary. Export never rewrites
  source prose automatically.

## Automated audit routing

Mechanical checks may flag candidates but never mark prose Good:

- missing/duplicate stable IDs;
- missing meeting section or terminal line;
- location clue without exactly one condition;
- reward/relationship target missing from the catalogue;
- placeholder tokens, malformed emphasis or empty prose;
- text hash changed since review;
- condition label and page identity disagree;
- likely abstraction clusters for human review.

The abstraction heuristic is deliberately advisory. Concrete first sentences often earn abstract
reflection; the manual findings in `authored-text-audit-current.md` override a raw score.

## Accessibility and safety

- All status controls are named and do not rely on colour.
- Dynamic Type reflows the continuous reader; no horizontal prose scrolling.
- VoiceOver reads traveller/context, prose, then review state/actions.
- Review writes are debounced/atomic and recoverable from a prior export.
- The tool is DEBUG-only and absent from release navigation and release data mutation paths.

## Acceptance

1. Atlas inventory IDs equal the union of live catalogue and review-corpus IDs: currently 29 rows;
   diary totals equal the live catalogue's exact page count.
2. All eight live meeting objects and all 23 review meeting objects are visibly accounted for;
   Auber is side-by-side and Noll's provisional live meeting is distinct from her replacement candidate.
3. Isolde exchange preview preserves C→A→B tap order and addresses each unit by stable ID.
4. Editing source prose makes a prior matching review stale on next load.
5. Import/export round-trips Unicode, Markdown punctuation and notes without changing source content.
6. Two conflicting records are surfaced; neither is silently dropped.
7. Release build contains neither atlas navigation nor review-state persistence.
8. Aimee can complete a Good/Needs revision pass using only phone controls and export one report for
   Design/Engineering to consume.
9. Catalogue/review array shuffle leaves the derived row set and authored ordering unchanged;
   deleting review-only identity metadata is a validation failure rather than dropping its row.

## Acceptance disposition — 9 Aug 2026

Accepted for corpus review. Code and phone evidence prove the continuous reader, real ordered meeting
preview, real diary-card path, status/note controls and bottom Next navigation remain usable at phone
width. Phase/kind/status/teaching/validation/search filters, JSON merge/conflict handling, SHA-256
staleness and deterministic Markdown-source drift checking are present. The atlas entry, review store
and generated draft corpus are all enclosed by `#if DEBUG`; Release navigation has no reference.

This acceptance approves the **tool**, not the final quality of any prose. Under Decision279,
coherent completed imported meetings become `Live candidate / awaiting play review`; Aimee reviews
and revises them through play. Only incomplete or contradictory copy remains draft-only.
