# Combat action palette — current design

**Status:** implementation-ready interaction/presentation correction; combat effects, legality and
turn resolution remain owned by current rules.
**Owner:** Game Design; Engineering owns native state/action integration; Asset owns stable technique,
item and stage glyphs.
**Priority:** P2 after active playability/Base checkpoints and before broad combat-tree presentation.

## Audit result

The live encounter has sound atomic combat rules but uses another menu hierarchy:

- Attack/Skills/Item/Flee are four large text buttons in two rows;
- Skills opens a full modal `List` of prose rows;
- Items opens a second full modal list that repeats every item once per living ally;
- ally-targeted skills silently choose the lowest-health ally rather than exposing the target choice;
- player-facing combat says **Flee** while the current tutorial teaches **Unbind**;
- selecting a skill then pressing Attack again to use it makes Attack temporarily mean a different
  action;
- any party-card tap toggles companion automation instead of making ownership explicit.

This is not merely visual density. The current screen hides technique availability, duplicates item
rows, and sometimes chooses a target the player did not select.

## Persistent combat composition

The combat stage remains primary. In reading order it shows:

1. encounter/round context;
2. current actor and any gambit-selected action;
3. party and foe formations with HP/armour/status;
4. selected action and legal target state;
5. compact action palette;
6. latest log line, with an explicit expansion for history.

Opening Techniques or Items expands/replaces only the palette region. It does not cover the stage
with a navigation sheet, reset selection or create a second combat screen.

## Primary palette

Four stable 44-point-or-larger keys remain in the thumb region:

| Key | Meaning |
|---|---|
| **Attack** | ordinary equipped/basic attack |
| **Techniques** | learned active skills for the current actor |
| **Items** | usable carried combat items |
| **Unbind** | leave this encounter for the exact displayed Stability consequence |

Use **Unbind** everywhere player-facing. Internal `.flee`/`EncounterOutcome.fled` identities may
remain compatibility code. Unbind opens a compact confirmation anchored above its key; it never
commits from an accidental first tap.

The four keys use stable glyph+label and one concise state badge. Do not shrink labels to preserve
four columns; Dynamic Type uses two rows. Companion gambit/manual control is a separate explicit
**Direct / Gambits** control attached to the acting companion, not a side effect of tapping any party
card.

## Technique palette

Selecting Techniques opens an in-place grid:

- four technique tiles across at ordinary phone width, reducing before text/tap compression;
- stable technique glyph, short name, and cooldown/ready state;
- no permanent full description under every technique;
- tap selects the technique and opens one edge-clamped anchored detail with full effect, problem it
  answers, reach/target kind, cooldown and **Choose target** or **Use**;
- cooling/unusable techniques remain visible with exact reason and cannot spend a turn;
- sort is stable authored technique order, not ready-first reshuffling.

The palette may show twelve learned techniques in three rows without a full-screen list. If later
catalogue growth exceeds the contained region, branch/category chips may filter; ordinary availability
never changes with the filter.

## Item palette

Items reuse the six-across physical-object grammar:

- each carried usable stack appears once, with quantity and identity;
- tap selects the item and shows its exact effect/eligibility in anchored detail;
- selecting **Use** moves to stage target selection; it does not duplicate the item once per ally;
- unusable outside-combat items stay absent from the combat palette, while a carried combat item with
  no currently legal recipient may remain visibly disabled with the reason;
- successful use consumes exactly one from the selected stable stack. Stale/missing stack rejects
  with zero turn and refreshes the palette.

## One target-selection grammar

Attack, techniques and items share one rules-owned target candidate model:

```text
CombatActionPreview {
  actionID / stable stack ID
  actor
  targetKind
  legalTargets
  rejectedTargets + reason
  defaultTarget?
  parameterKind?
  legalParameters?
  defaultParameter?
  predicted disclosed consequence
  commitFingerprint
}
```

- foe actions highlight legal foes on the stage;
- ally/self actions highlight legal party members, including the Binder;
- all/self/no-target actions name that fact and may commit directly after confirmation where needed;
- if exactly one legal target exists and no meaningful target decision remains, the action may resolve
  immediately; otherwise the player chooses;
- ally-targeted techniques never silently choose the lowest-health ally merely because that is
  usually sensible;
- a technique with a second authored choice uses the same preview/commit fingerprint and never
  overloads target identity to carry that choice;
- selected, legal, cannot-reach, protected and passed-out remain independent states. Legal and
  cannot-reach are mutually exclusive.

The stage names the current default before a second-tap shortcut can use it. Re-tapping **the selected
action/technique**, not Attack under a changed meaning, commits that displayed default. Cancel returns
to the same palette/scroll state with no mutation.

### Typed technique parameters

These are part of the action, not modal configuration or hidden AI:

| Technique | Target | Required parameter | Manual default | Gambit default |
|---|---|---|---|---|
| Ward | self | one harm kind: Crush, Pierce, Rend, Heat, Caustic or Light | none; player chooses | rules-owned most common disclosed incoming harm, with stable fallback |
| Emanation Strike | one legal foe | Heat, Caustic or Light | actor's saved preference, visibly selected and changeable | saved preference |
| Quench | one conscious ally/self carrying an eligible condition | one of that target's burn, poison or dazzle instances | none when several differ; sole eligible condition may preselect visibly | highest remaining damage×rounds, then stable status order |
| Fall Back | self | one legal different rank | none when both are legal; sole legal rank may preselect visibly | safest legal rearward rank, then stable rank order |

Emanation Strike grants all three kinds itself; it is not disabled because the actor lacks a
Channelworks item or a separate attunement unlock. Heat applies burn, Caustic poison and Light dazzle.
Insulation/Emanant purchase choices are separate durable character choices, not prerequisites for
using the technique.

Parameter selection costs no turn. Commit revalidates exact option legality. A stale Quench status,
blocked rank or changed disclosed harm rejects with no cooldown, action, item or turn mutation.
VoiceOver reads action → target → parameter → consequence → commit.

## Gambits and manual control

Gambits remain ordered automation and are edited only at Party between fights. During combat:

- an automated companion turn shows the chosen gambit rule, resulting action and target before it
  resolves at readable tempo;
- **Direct next turn** is an explicit control for that companion; it does not fire from tapping a
  portrait/card and never changes a different companion;
- while directing, the same action/target palette is used with that actor's techniques/items;
- **Return to Gambits** is explicit and cannot discard an already committed action.

## Result, log and interruption

- Opening/closing palettes, details, targeting and Unbind confirmation costs no turn.
- One atomic commit validates actor/current turn, action/stack, cooldown, target, reach and fingerprint;
  stale state rejects without partial cooldown, item spend or turn advance.
- Force-quit before commit resumes the encounter and may discard ephemeral selection. Force-quit
  after commit resumes the resulting authoritative turn state and cannot repeat the action.
- The stage shows the latest important log line. Expand **Battle log** for ordered history; the log
  remains a list because sequence is its mechanic.
- Outcome/loot suppresses the action palette and tutorial overlays. It never appears behind a modal
  action sheet.

## Accessibility and phone gates

1. A 5v3 and 2v1 encounter on 368×800 keeps stage, current actor/action/target and all four primary
   actions reachable without horizontal scrolling.
2. Technique and item tiles retain 44×44-point ownership; Large Text reduces columns/reflows labels.
3. VoiceOver order follows actor → selected action → legal targets → palette. Every unavailable action
   names its reason and cooldown in rounds.
4. Grayscale/High Contrast distinguish current actor, selected action, legal/cannot/protected targets,
   cooldown, destructive Unbind and passed-out actors without color alone.
5. Anchored details and Unbind confirmation flip/clamp inside screen edges and fixed controls.
6. Selecting each target kind—foe, ally, self, all, none—commits exactly the rules-owned target and
   never substitutes weakest/first unless it was visibly the sole/default target chosen by shortcut.
7. Item stacks appear once regardless of party size; using one preserves exact stack identity and
   decrements once.
8. Direct/Gambits affects only the named acting companion and survives no unintended portrait tap.
9. Tutorial and ordinary UI both say Unbind and use the selected-action second-tap rule.
10. Opening every palette/detail, cancelling and relaunching before commit produces zero combat-state
    mutation; committed actions remain idempotent through relaunch.
11. Ward, Emanation Strike, Quench and Fall Back round-trip their exact typed parameter through manual
    preview, gambit resolution, commit and battle log; no first-enum or lowest-HP substitution occurs.

## Non-goals

- no combat pause wheel or timing minigame;
- no tree editing, respec or gambit reordering during a fight;
- no damage prediction beyond facts the current analysis/inspection level legitimately knows;
- no animation dependency for legality, target or outcome;
- no change to skill effects, cooldown values, item recipes or encounter scaling in this checkpoint.
