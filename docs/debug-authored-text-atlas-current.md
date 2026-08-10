# DEBUG Authored-Text Atlas — Current

**Status:** active Engineering implementation after the launch/layout and ordered-meeting checkpoints.
The first native pass has the correct review-store foundation but is not acceptance-complete until it
renders the actual review drafts and closes the interaction/import/filter gates below. The atlas does
not authorize prose changes by itself.

## Purpose

Aimee needs one place to read the complete authored corpus in actual presentation context, mark what
works, flag revision, and leave a note. Design also needs a reproducible audit rather than finding
abstract or mismatched lines only when a campaign happens to surface them.

The atlas covers all 28 named travellers, including missing content. It must not hide absent meeting
objects or pages behind empty filters.

The four `traveller-meetings-*-review.md` documents now contain complete exact draft copy for all 21
missing live meetings. A DEBUG-only structured source or generated fixture may mirror those drafts so
the native atlas can render them. Do not parse Markdown at runtime, move unapproved drafts into the
shipped traveller catalogue, or reduce them to a Boolean “draft available” badge. Auber is a distinct
case: show his current live meeting and the review revision candidate side by side under the same
stable exchange IDs, with independent exact-text hashes.

## Corpus

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

1. Atlas inventory totals match the live catalogue: 28 travellers and the exact current page count.
2. All seven current meeting objects and all 21 missing meeting objects are visibly accounted for.
3. Isolde exchange preview preserves C→A→B tap order and addresses each unit by stable ID.
4. Editing source prose makes a prior matching review stale on next load.
5. Import/export round-trips Unicode, Markdown punctuation and notes without changing source content.
6. Two conflicting records are surfaced; neither is silently dropped.
7. Release build contains neither atlas navigation nor review-state persistence.
8. Aimee can complete a Good/Needs revision pass using only phone controls and export one report for
   Design/Engineering to consume.
