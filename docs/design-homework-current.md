# Design Homework — Current Contract

**Status:** Initial slice installed in `4ed15ab`; current catalogue has 12 active questions after
obsolete advance-copy approvals retired into production/play review; launch trust and phone interaction
check remain.
**Updated:** 21 August 2026
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
4. Reversible Penmanship Essence/resource comparison profile (`penmanship-price-profile`).
5. Final player-facing combat retreat name (`combat-retreat-name`).
6. Named-traveller arrival level and permanent catch-up gap (`named-traveller-arrival-level`).
7. Failed-expedition item-retention agency after stack-independent arithmetic correction
   (`failure-recovery-agency`).
8. Named-character stat-growth identity and roster-upkeep trade-off
   (`named-character-stat-growth`).
9. Constellation's matched combat/district mastery structure (`constellation-mastery-structure`).
10. Constellation persistence per campaign save versus account-wide (`constellation-persistence`).
11. Storehouse/Field Kit capacity compression profile (`capacity-compression-profile`).
12. Rare ordinary-creature territory-find frequency and category mix (`territory-find-frequency`).

The eleven Isolde/Sabine/full-cast dialogue approval pages are retired. Coherent meeting and diary copy is
production-authorized by `full-cast-voice-authority-current.md` and enters the game in campaign order for
Aimee to review during play. Retiring the bundled questions does not delete frozen historical device answers
or export records.

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
