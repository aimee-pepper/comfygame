# Traveller World Pacing — Current

**Status:** implementation-ready balance/campaign correction; evidence tie weights are DEBUG-tunable  
**Date:** 11 August 2026  
**Supersedes:** the unrestricted rule that every matching unfound traveller is placed and that a
completely blind late-game signature match is always valid from world one.

## Playtest finding

A brand-new campaign's first world placed both Mara and Bryn without any recovered location page.
This is not merely a rare roll. Native worldgen currently:

1. evaluates every unfound traveller against the resolved world;
2. ignores `campaignPhase` and authored order for eligibility; and
3. places every match for which it can find a free tile.

The result collapses the diary/search arc, can skip the intended early economy people, and turns one
expedition into several recruitment/station decisions. A campaign phase that exists only in content
and a probability test is not progression authority.

## Correct placement rule

### One new traveller per world

A newly bound world places at most **one** unfound authored traveller. Existing anchored-world
occupants remain frozen; revisiting does not reroll or replace them.

The opening economy order—Vance, Noll, then Halloway—belongs to the earliest authored arrival band,
but it is not a hard next-person gate. Every traveller must still satisfy their complete signature.
When several complete signatures match, the earliest represented story band wins. Evidence the
player has found and acted on breaks ties **only inside that band**.

From every unfound candidate whose **entire signature holds**:

1. Apply blind-frontier/clue eligibility.
2. Find the lowest `storyArrivalBand` represented by the remaining matches and discard every match
   from later bands for this world.
3. Inside that band, calculate:

   ```text
   evidenceScore = recoveredLocationClues
                 + 2 × deliberatelyAuthoredMatches
   ```

4. Select the highest evidence score, then lower `authoredOrder`, then stable traveller ID.

The 1/2 coefficients are reversible Recommended values exposed together in DEBUG. Arrival bands are
authored story structure, not balancing sliders. Page evidence can decide which contemporary person
appears; no quantity of later pages can make a later band beat a simultaneous earlier-band match.

A `deliberatelyAuthoredMatch` is a recovered location-clue condition that holds in the resolved world
and would not have held in the same seeded world with the player's authored pressure contribution
removed. This counterfactual prevents an unrelated rune or lucky random fill from masquerading as
deliberate pursuit. An unrecovered condition may help produce the world but supplies no hidden
evidence bonus.

Removing authored pressure must also make every newly silent target eligible for the ordinary
seeded random fill. The counterfactual is therefore resolved from a book with the relevant authored
pressure removed **plus `rollUnwritten` rerun for that counterfactual page using the same world
seed**. It is not the incomplete reading produced by simply deleting authored sigils while retaining
only the original world's already-rolled targets. If the counterfactual random fill still satisfies
the requirement, that condition was lucky rather than causally authored.

Do not perform a weighted random draw after the player has already succeeded at deduction; identical
book, knowledge and seed must select the same person across relaunch. There is no second traveller
roll.

After deterministic selection, apply the single bounded arrival-confidence roll in
`traveller-arrival-confidence-review-current.md`: 25% at zero causally authored conditions, scaling
linearly to 100% when all are authored, plus saved 25-point near-miss protection and a guaranteed
third selected full match. A failed selection places nobody else. Never multiply independent
per-condition failure chances.

### Authored-order eligibility

`campaignPhase` is not a safe numerical gate by itself: Sela is current `mid` order 7 while Bryn is
`early-mid` order 8. Sorting phase labels would invert the accepted cast order. Blind discovery
therefore uses the stable authored order already responsible for campaign sequencing:

- every `opening` traveller is eligible from the start;
- every other traveller requires at least `max(3, authoredOrder - blindDiscoveryWindow)` previously
  recruited travellers; Recommended `blindDiscoveryWindow` is **3**.

This creates a rolling three-person discovery frontier while preserving the current sequence:
Isolde/order 6 at 3 recruits, Sela/order 7 at 4, Bryn/order 8 at 5, Orsa/order 9 at 6, Talin/order 10
at 7, and so on. `campaignPhase` remains required authored classification and validation context; it
does not override a person's more precise order.

A traveller below that blind order floor is nevertheless eligible if the Library already has at
least one of their exact location clues. Thus pages are **accelerants, not universal gates**: they
can bring a later fully matching person into consideration, and their evidence score can let
deliberate writing outrank a contemporary accidental match. It cannot outrank a simultaneous match
from an earlier story band. Relationship/name-only writing does not
reveal a signature and supplies no eligibility or evidence bonus.

Expose `blindDiscoveryWindow` as an integer DEBUG balancing control from 1–6, with Recommended reset
to 3 and next-bind application. It changes eligibility only for newly generated worlds and never
rerolls an active/anchored map. The one-traveller maximum is structural—not a slider—and cannot be
raised through balancing tools.

Use the found-traveller set frozen at bind/start of the expedition. Recruiting someone within the
same world cannot unlock and materialize another person into that already-generated map.

## Why there is no targeting selector

Aimee rejected an explicit **Seek [name]** control as too leading. Choosing after generation likewise
turns discovery into reward selection, while placing multiple people recreates the original crowd.
The automatic score lets the page, authored world and story sequence communicate intent through
existing play. DEBUG may show the full receipt; Release UI never lists rejected hidden candidates.

## Opening consequence

On the reported Mara+Bryn first world:

- Bryn is ineligible: order 8 requires five prior recruits, and there is no Bryn location clue;
- Bryn cannot appear blindly because the authored-order floor is unmet;
- a recovered Bryn location clue makes her eligible early, but she appears only if all three
  conditions hold and no earlier-band candidate also fully matches; her evidence can distinguish her
  from Isolde, Sela or Orsa inside their shared band, not from Mara's earlier band.

Vance → Noll → Halloway remains the strongest accidental opening tendency rather than a compulsory
script. Deliberate clue pursuit may alter the order because that is the payoff for collecting and
interpreting location pages.

## Diagnostics and player-facing behavior

DEBUG world diagnostics retain four distinct sets:

- all unfound candidates;
- raw signature matches;
- phase/clue-eligible matches;
- the single placed traveller, plus a stable exclusion reason for every rejected match
  (`phaseLocked`, `lowerPriorityThanClueBacked`, `laterAuthoredMatch`, `noPlacementTile`).

Do not expose the hidden phase thresholds or rejected people in release UI. The Library continues to
show only people/writing the player has reason to know.

## Acceptance

1. A fresh blank or authored first world places zero or one traveller and never blindly places Bryn
   or another person below the authored-order floor.
2. The reported simultaneous Mara+Bryn/no-clue fixture places Mara only; it never places Bryn or
   both because Bryn is outside the blind frontier.
3. A recovered Bryn clue makes her eligible early only when her full signature holds. One/two/three
   recovered clues and causally authored matches increase her priority exactly once each.
4. Name/relationship-only knowledge about Bryn does not bypass the floor.
5. At five prior recruits, Bryn may be found by signature without a page; Sela/order 7 becomes
   blindly eligible first at four, preserving their accepted relative order. Pages never become a
   permanent recruitment gate.
6. Two clue-backed simultaneous full matches in one band resolve by evidence score, then authored order and
   stable ID, never place both.
7. Recruiting a person in the current world does not cause another to appear; a newly bound next
   world uses the advanced phase.
8. Anchored revisits preserve their frozen occupant and do not apply the new selector retroactively.
9. Save/relaunch, catalogue array shuffle and map placement failure preserve the same selected ID and
   diagnostics.
10. A seeded campaign simulation shows no world with more than one new traveller and reports blind
    discovery by phase, clue-backed early discoveries and worlds with no traveller separately.
11. An earlier story-band match always beats a simultaneous later-band match regardless of page
   count; within one band, recovered-and-authored evidence can change the winner.
12. Counterfactual fixtures distinguish causal authored matches from lucky random matches, inert or
   wrong-direction writing and unrecovered hidden conditions.
13. DEBUG clue/authored weights and window 1/3/6 change only new-world selection; story bands remain
    immutable authored content; Recommended reset,
    relaunch and already-generated worlds remain exact.
14. Arrival confidence is 25/62.5/100% at zero/half/all causally authored conditions before pity;
    failed selected matches place nobody, persist +25 points, and guarantee the third full match.
