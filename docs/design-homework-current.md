# Design Homework — Current Contract

**Status:** Initial 17-question slice installed in `4ed15ab`; launch trust and phone interaction check
remain. Next 19-question/66-review-item catalogue revision is source-validated but not installed.
**Decision date:** 12 August 2026
**Content authority:** `Sources/Content/Data/design-homework.json`

## Purpose

Settings → Homework gives Aimee a quiet, asynchronous place to answer real design questions without
blocking ongoing implementation. It is a development surface, not a player feature and not a tutorial.

## Settled interaction

- One page contains exactly one design question.
- Every question supplies concise context, the Game Design recommendation and mutually exclusive
  multiple-choice answers.
- Every page also supplies a free-text **Something else** field. It may replace the offered choices or
  qualify one selected choice.
- **Save answer** means save locally on this device. It does not imply network submission.
- The list marks locally answered questions as Saved and keeps unanswered questions visible.
- **Export saved answers** shares one timestamped, machine-readable JSON answer package for Game Design
  and Engineering review.

## Persistence and review boundary

Question content is versioned bundled data. Answers are separately persisted in the app Documents
container as `DesignHomeworkAnswers.json`, including stable question/choice IDs and save timestamps.
Each answer also freezes the catalogue date and exact question/selected-choice titles that Aimee saw.
Updating question copy must not silently rewrite the meaning of an earlier answer.
If a later catalogue retires the selected choice, the question page labels that frozen title as a
previous answer and asks for a current selection; it must not falsely display the free-text option as
though that was the saved choice. The original answer remains in the export until Aimee replaces it.

Connecting the development phone alone is not an automatic submission mechanism. Answers become
reviewable through either:

1. the in-app Share action; or
2. Engineering retrieving the Documents package from the connected development phone.

A later authenticated relay may add direct submission, but the UI must not call a local save
“submitted” before such a receipt exists.

## Initial live questions

1. Shatter’s combat effect (`combat-shatter-effect`).
2. Distiller’s coating effect (`combat-distiller-effect`).
3. Reforge’s mechanically honest progression (`reforge-progression`).
4. Isolde's exact three-reply revision (`isolde-dialogue-revision`).
5. Sabine's exact seven-clue revision (`sabine-clue-revision`).
6. Marrick/Oda/Ashe/Wren's condition-validated location-clue batch
   (`location-clue-revision-batch`).
7. Rook's exact three-line meeting revision (`rook-meeting-voice-revision`).
8. Marrick's exact three-line meeting revision (`marrick-meeting-voice-revision`).
9. Ashe's exact three-line meeting revision (`ashe-meeting-voice-revision`).
10. Dagg/Lys/Wren/Kestrel/Oda's medium-risk meeting revision batch
    (`medium-risk-meeting-voice-revision`).
11. Noll and Auber's differentiated salvage/transformation meeting lines
    (`noll-auber-meeting-voice-revision`).
12. Grimmond and Nine's exact terminal-response revisions
    (`grimmond-nine-terminal-revision`).
13. Reversible Penmanship Essence/resource comparison profile
    (`penmanship-price-profile`).
14. Final player-facing combat retreat name (`combat-retreat-name`).
15. Bryn/Talin/Nessa's five-line early-hinge voice correction
    (`early-hinge-meeting-voice-revision`).
16. Corrin/Fen's three-line material-practice voice correction
    (`corrin-fen-meeting-voice-revision`).
17. Named-traveller arrival level and permanent catch-up gap
    (`named-traveller-arrival-level`).
18. Named-character stat-growth identity and roster-upkeep trade-off
    (`named-character-stat-growth`).
19. Bracken/Maud/Perren's four-line remaining abstract-reply correction
    (`remaining-meeting-voice-revision`).

The catalogue deliberately mixes held mechanical choices with exact authored-copy reviews. Each can
be answered asynchronously without blocking unrelated implementation; a question's own authority
states whether Engineering may proceed before review. Routine questions should not be manufactured
merely to populate the screen.

## Acceptance gate

- Settings opens Homework on a DEBUG phone build.
- Every bundled question opens on its own page.
- Choice-only, text-only and choice-plus-qualification answers survive relaunch.
- Save with neither a choice nor text is unavailable.
- Export contains stable IDs, exact text and timestamps for all saved answers.
- Revised or retired question content does not erase the existing answer package.
- A retired saved choice is visibly historical rather than misrepresented as a current option.
