# Save compatibility policy — current

**Status:** settled by Aimee  
**Date:** 14 August 2026  
**Applies to:** game state, content receipts, generated/native asset receipts and test fixtures

## Rule

Preserve save compatibility whenever migration is reasonably contained and does not compromise the
current design. This remains the default because Aimee is actively playtesting real campaigns.

This is an early prototype, however. If preserving an old save would materially block a large
necessary change, force parallel gameplay implementations, preserve a design we are deliberately
replacing, or create disproportionate migration risk, compatibility may be broken deliberately.

When compatibility is broken:

1. increment an explicit save-format version;
2. detect the incompatible save before decoding it into live gameplay state;
3. show a clear player-facing incompatibility state in the save shelf, including the save's version
   and the version this build accepts;
4. never silently reset, partially adopt, mutate or overwrite the incompatible file;
5. keep export available so the original file can be archived or supplied for diagnosis;
6. require confirmation before deletion or replacement;
7. keep only the newest gameplay implementation in production—do not retain parallel old rules,
   screens, catalogues or generators merely to run obsolete saves; and
8. keep versioned migration fixtures only where they test a migration path the newest build still
   intentionally supports.

## Decision test

Use tolerant migration when all of the following are true:

- the old fact maps unambiguously to the new fact;
- adoption can be idempotent and tested at one clear boundary;
- the migration does not invent player choices, rewards, losses or provenance; and
- supporting it does not require the old gameplay system to remain executable.

Prefer a format break when any of the following are true:

- one old fact has several materially different new meanings and no honest inference;
- preservation would require two live simulation, economy, generation or progression paths;
- the old representation contradicts the newly settled design;
- a safe migration would cost more or carry more risk than the prototype campaign warrants; or
- compatibility work would block a high-priority playable-system correction.

## Presentation

Recommended save-shelf copy:

> **Made with an older test version**  
> This campaign uses save format {old}. This build uses format {current}, and the game changed too
> much to load it safely. You can export or delete the original save, or start a new campaign.

Do not call the save “corrupt,” because an intentionally unsupported version is not damaged data.
Do not offer a Load button that will fail after navigation. Display **Export** and **Delete…** as the
available actions, plus the ordinary **New Game** action outside the card.

## Feature-specific consequence

World Pages, Templates and the Rune Dictionary should use tolerant optional fields while their
models remain additive. If a later authored-blueprint or ink-receipt change makes their old meaning
ambiguous, it may advance the save format under this policy instead of carrying a second page,
generator or ink implementation forever.
