# Binder Gambit unlock and locked-state copy

Updated 4 September 2026. Bounded Game Design closure requested by Project Manager after Wiki publication. This document changes no runtime and claims no phone delivery.

## Decision

Binder self-automation remains earned. It does not start unlocked merely because Party, its character pages, or the Gambits tab are available. Preserve `hasAutomateSelfUnlock` as the production gate and preserve all existing true entitlements. Do not create rules, enable disabled rules, grant Gambit vocabulary, add slots, or alter priorities as a presentation side effect.

The existing intended acquisition owner is a **recovered advanced instruction**, not Party, a newly invented NPC, a Constellation purchase, or a restored Workshop. Recover `teaching.instruction.automate_self` — **Let your own rules run** — in a world, then read it in the Library. The Library preserves and presents the actual recovered instruction; it does not sell or spontaneously teach it.

The recovered-teaching catalogue currently specifies the later band: Binder level at least 8, at least eight resolved expeditions, and all three opening Gambit teachings known (`subject_self`, `act_flee`, `act_skill`). These are retained first-pass eligibility numbers, revisable under Aimee's 4 September progression direction. This closure does not change them, invent a new teaching owner, or request another Aimee decision.

## Authority and the apparent start-unlocked conflict

- `docs/design-brief-v0.md`, manual-override paragraph: the Binder is manual initially and self-automation is earned.
- `docs/recovered-teachings-current.md`, Player rule, Gambit and advanced-instruction catalogue, and migration sections: exact world-recovery/Library-reading owner, title, band and legacy entitlement preservation. Its old six-star introduction is superseded elsewhere; that does not revoke its automation teaching.
- `docs/workshop-constellation-role-audit-current.md`, Instruction transfer: advanced recovered instruction read in Library; Party does not teach knowledge.
- Prior PM dispatch in task `01a02b2a-71d5-7822-9a27-04e2c9328944`, turn `01a06d94-be4a-7591-a907-985d35eb7397`, used “start-unlocked human/Binder Party Gambits presentation” while explicitly requiring presentation only and preservation of all rules. It is not sufficient authority to silently reverse the explicit earned-automation design. This closure resolves that shorthand in favour of the retained earned ability.
- The former render test explicitly sets the unlock flag. Rename it to describe an **unlocked Binder fixture**, never production start-unlocked behavior.

## Source state and delivery limits

Inspected native candidate `8d914b23c1889bc644540639f2553821c1bfcc61` and the shared source records. `BaseState` defaults the flag to false and preserves it across coding. `CharacterPage.rulesCard` selects the real editor only when true. `GambitEngine` returns no Binder rules while locked. `EconomyRules` still has the older Research grant.

`research.json` still defines `automate_self` / **Write your own hand** in Instruction, with `reason_about_self` and `longer_instruction` prerequisites; `WorkshopView` still mounts the nil-station `ResearchTree`, and Workshop remains in source station/start lists. These are retained code/data facts. They do not establish a current phone-visible route, justify restoring the Workshop, or prove the recovered-teaching replacement has shipped. Preserve old entitlements and any supported legacy acquisition until its migration is explicitly integrated.

## Exact player-facing copy

### Immediate correction, before recovered teachings are delivered

Use the existing Gambits tab and locked-state host. Replace the obsolete Workshop instruction with:

> Your turns are manual. Following your own Gambits is a learned ability.

This text is truthful regardless of whether an old save still has a supported Research route. It does not send a new player to an unverified destination or imply that the Library currently contains a missing teaching. No new button, link, purchase, disabled preview editor, or early-authoring capability is required.

### After the recovered-teaching route is actually delivered

For an unrecovered/unread unlock, use:

> Recover “Let your own rules run” in a world, then read it in the Library to let the Binder follow Gambits. Until then, your turns are manual.

When the exact instruction is recovered but unread, the more useful state-specific copy is:

> “Let your own rules run” is ready to read in the Library. Read it to unlock the Binder’s Gambits.

Use the existing Library attention/navigation owner if available; do not invent one for this presentation correction. Reading applies the entitlement and the read receipt together. It neither writes a rule nor changes the enabled state of any existing rule. Already unlocked saves show their existing editor, not the locked message.

## Bounded Engineering acceptance

Keep the presentation scope from Asset's human-host contract. In temporary state, false shows the manual-turn copy and no Binder editor; true shows the existing editor, slots, rules, order and actions unchanged. A false→true entitlement transition reveals that same editor. Presentation must never assign the flag. Preserve a saved true entitlement through reopening.

Use the actual target iPhone and default text for the human presentation check; do not reuse a historical mockup rectangle as a product requirement. Engineering owns runtime change, focused checks and delivery. This document needs no Simulator operation or gameplay test because it changes no executable behavior.

The public Party/Gambit guides and September decisions reference record the same current/intended distinction. No Homework choice is added: the acquisition owner was already authored.
