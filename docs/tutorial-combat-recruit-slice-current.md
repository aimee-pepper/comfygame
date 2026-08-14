# Tutorial combat and first recruit — exact triggers and copy

**Status:** Implementation-ready slice 5 under `tutorial-discoverability-current.md`. Combat safety
and card density remain playtest values; this slice does not weaken the first fight.  
**Updated:** 9 Aug 2026

## Durable facts

Persist these facts through the existing versioned tutorial record:

```text
first_encounter_started
first_player_combat_action
first_player_involved_encounter_outcome
first_combat_retreat
first_traveller_meeting
first_traveller_decision
first_traveller_recruited
first_firepit_party_change
first_party_person_reviewed
```

“Player-involved” means the Binder performed at least one manual combat action before that
encounter's victory, defeat or retreat. An entirely automatic fixture/simulation does not unlock the
gambit lesson. Old saves infer only from durable encounter/recruit history that actually exists;
absence does not manufacture a completed lesson.

Implementation keeps one tolerant `playerHasActed` boolean on the saved `EncounterState`, defaulting
false for older mid-fight saves. Set it in the same atomic mutation that commits any valid manual
Attack, Skill, Item or Unbind action, before automatic turns run. When the encounter outcome is
concluded, copy the appropriate durable tutorial facts before the encounter record is removed. Do
not infer participation from whose turn happened to finish the fight or from a combat log string.

## First encounter lessons

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `combat.turn_and_action.v1` | First encounter waits for player input | First player combat action | Acting outline + action bar: **The outlined person acts now.** Choose Attack, a ready Skill, an Item or Unbind. Selecting a foe commits the action; with one valid foe, the action may resolve immediately. |
| 2 | `combat.retreat.v1` | First encounter begins after the basics card has been eligible | First retreat, or first player-involved encounter outcome | Unbind action: **Unbind leaves this fight and costs the shown Stability.** It is a retreat, not a failed attack; the world continues if you can still stand in it. |
| 3 | `combat.gambits_after_manual.v1` | Party first opens after one player-involved encounter outcome | Player opens one party member's Gambits tab | Gambits tab: **Gambits are ordered rules for unattended turns.** The first valid rule acts. You may take over a companion's next turn in combat, but rules are edited here between fights. |

The player-facing retreat verb is **Unbind**. Internal action/event names may remain `flee`; tutorial
and ordinary combat UI must not teach two different verbs for the same button. If Aimee later
chooses “Flee” as the final surface term, revise both together rather than keeping tutorial-only
copy.

One card maximum remains absolute. Encounter outcome UI, loot choice and carried-home flow suppress
cards. A suppressed card resumes only if its completion fact is still false.

### Target and damage disclosure

- Legal targets use the normal target outline; the tutorial never adds a free reach/covering fact.
- The second-tap default is described in permanent action-bar copy, not another opening card:
  “Choose a target—or press the selected action again to use the shown default.” Attack repeats
  Attack; a selected technique repeats that technique. The UI must name whether the default is the
  Binder's gambit result, the first standing foe or another rules-owned candidate.
- Do **not** ship a damage-triangle tutorial card until weapon and foe-covering inspection is a real
  deliberate interaction. The current covering word alone is insufficient: a card appearing merely
  because a foe exists would explain strategy before the player asked.
- Once inspection exists, reserve `combat.physical_triangle.v1`: “Pierce answers rigid covering,
  crush answers plated mass, and rend answers soft or fibrous covering. Reach and emanation are
  separate questions.” Complete it by inspecting both the equipped weapon's damage kind and one
  foe covering, not by tapping Got it.

The first encounter receives no hidden HP, accuracy, species or AI exception. If playtesting needs
an opening-campaign encounter envelope, expose and snapshot it as the existing debug-plan requires.

## First traveller meeting

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `people.meeting_choice.v1` | First traveller meeting opens | Recruit or Leave them is chosen | Conversation choices: **Questions cost no world turn.** Inviting brings this person to the Base if there is room. Leaving them preserves the choice only while this world and their tile still remain. |
| 2 | `people.firepit_party.v1` | Firepit opens after the first recruit | First successful active-party membership change | Firepit travel controls: **The Firepit chooses who travels.** People left at the Base are not lost; the party limit counts the Binder plus the companions marked as coming. |
| 3 | `people.party_record.v1` | Party opens with at least one recruited traveller | A recruited person's Stats tab has been opened | Person tabs: **Party keeps each person's stats, gear, rank and gambits.** Changing who travels belongs at the Firepit; changing how they fight belongs here. |

Declining is not recruitment and must not set `first_traveller_recruited`. **Home has no lifetime
roster cap.** A full five-person travel party may disable **Take them** at the Firepit, but it never
disables inviting a newly met traveller home. Recruitment seats the person at Home; the player then
chooses at the Firepit whether they travel. If a decline is followed by collapse or tile loss,
ordinary world rules decide whether the opportunity survives—no tutorial protection or respawn is
added. Record the meeting decision only from an explicit Recruit/Leave action; optional questions
and dismissing the sheet without choosing do not fabricate one.

The Firepit lesson is independently eligible from Slice 3's first-return route. If that route already
sent the player to the Firepit, show at most one card there: `people.firepit_party` owns the screen
and the generic route card completes when navigation arrives.

## Accessibility and normal UI requirements

- Current actor, legal target, cannot-reach and protection remain distinguishable by shape and
  accessible label, not colour alone.
- Every combat action retains a 44pt minimum target and states disabled reasons in VoiceOver.
- Passed-out people remain in party reading order with “passed out” and zero HP; opacity is not the
  only status signal.
- Meeting order is identity → opening text → optional questions → invitation → Leave them.
- Large Text may stack combat controls vertically; it must not move Unbind out of the reachable
  action area or place tutorial copy over current HP.

## Debug and verification

1. Start 2v1 and 5v3 first fights; exactly one basics card appears and every normal outcome remains
   possible.
2. With one foe, the first Attack may resolve immediately and still completes the basics lesson.
3. With several foes, selecting a legal foe and using the named second-tap default both complete it.
4. Win, lose and Unbind after a player action; all unlock the later gambit lesson. A fully automated
   test encounter does not.
5. Suppress the card with outcome/loot, save and relaunch; no duplicate or stacked card appears.
6. Open a first meeting, ask every question, and verify no world turn is spent.
7. Leave, reopen while the traveller remains, then recruit; the two durable facts stay distinct.
8. Fill the active travel party, recruit another traveller successfully to Home, and verify only the
   Firepit's **Take them** action is capacity-disabled; invitation and durable recruitment remain valid.
9. Recruit, open Firepit and Party in either order; each lesson attaches only to its own verb and
   never claims the recruit is travelling until selected.
10. Exercise colour, grayscale, VoiceOver and Large Text for both combat formations and the meeting
    sheet.
