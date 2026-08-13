# Encounter scaling phone test card — current

**Status:** playtest protocol for DRQ-128; does not change Recommended coefficients.  
**Authority:** mechanics and migration remain in `encounter-scaling-playtest-current.md`. This card
defines comparable phone evidence and tuning bands for Aimee's sole-tester campaign.

## What this test is answering

The current bug is not “some creatures rolled weak.” Legacy difficulty ignores party size and gives
an apex one action regardless of a developed five-person party. Recommended must prove all of these:

- adding a party member never reduces generated pressure;
- ordinary fights acknowledge additional actions without becoming boss-length;
- apexes require several real tactical decisions from a large party;
- low-level new recruits are useful but visibly vulnerable, not sacrificial targets;
- better gear and builds still feel rewarding because scaling does not read equipment.

## Before each comparison

1. Use the same saved campaign copy, world seed/fixture and disclosed encounter identity where the
   DEBUG tooling permits it.
2. Newly bound worlds default to **Recommended · party size + level**. Change DEBUG Balancing only
   for the paired **Legacy · level only** control, and make either choice before binding. Existing
   runs correctly retain their frozen profile; confirm the active run receipt rather than inferring
   its profile from the current selector.
3. Record active stable member IDs, levels, ranks, current/max HP, armour, weapons and relevant combat
   nodes. Do not quietly heal, re-equip or reorder between the paired profiles.
4. Begin from full expedition HP for the clean comparison. Campaign-worn encounters are valuable
   separately but cannot diagnose the scaler alone.
5. Capture/export the scaling ledger and outcome report even when the fight merely “felt fine.”

## Minimum comparison set

Run the same ordinary and apex fixture with:

| Party | Purpose |
|---|---|
| Binder 8 solo | proves one-person parity and baseline creature identity |
| Binder 8 + one level-8 companion | ordinary two-person pressure and apex one-slot boundary |
| Binder 8 + four level-8 companions | maximum equal-level durability and three-slot apex tempo |
| Binder 8 + one level-1 new recruit | realistic catch-up/readiness case |

If the current campaign is at another level, use its real level and preserve the same relative
patterns. The numbers above are comparison labels, not a request to manufacture progression.

For ordinary encounters, exercise one isolated real foe and a legitimately reachable three-foe
group. For apexes, exercise one apex alone and one apex with an ordinary creature already legitimately
present. The mixed case must add no ordinary pressure slots and must scale only the apex body.

## Record after every fight

- rounds and total committed player/companion/foe actions;
- each party member's HP lost, pass-out and acting-before-first-hit state;
- healing/curative items spent and defensive techniques used;
- Unbind availability and whether retreat felt like a real option;
- real foe IDs, party-power contributions, HP allocation and saved follow-up/action slots;
- whether any lighter follow-up applied an affliction or repeated a wild/area effect—it must not;
- subjective flags: **foregone**, **tense**, **confusing**, **HP wall**, **one-hit threat**.

### Bug-report evidence boundary

Checkpoint `cae4b7a` adds one tolerant optional encounter-evidence payload to the existing DEBUG
bug-report package. It is source-green and awaits the next phone install. When a report is captured
during combat, it copies and exports:

- the encounter's saved scaling profile/rules version and world level inputs;
- stable party members with levels/ranks and their frozen power contributions;
- trigger/group membership plus inclusion/exclusion reasons and grouping radius;
- final foe IDs, level, maximum HP, attack, armour and apex flag;
- ordinary HP allocation/follow-up slots or apex multipliers/action slots;
- opening classification and the current round/turn position;
- current party and foe HP, so an opening burst can be distinguished from accumulated attrition.

This is DEBUG evidence only. It reads the already-frozen encounter receipt rather than recomputing
scaling from current settings; old reports decode with the field absent, and capture is proven
read-only. It adds no atlas, dashboard, accessibility matrix or automatic balance judgment. Until a
build containing `cae4b7a` is installed, Aimee's text note and screenshot remain useful feel evidence,
but coefficient changes require a controlled reproduction or direct inspection of the active save.

## Initial feel bands

These are comparison bands, not hidden automatic difficulty targets. Do not dynamically alter a live
fight to force them.

### Ordinary on-level encounter

Read this table first for an isolated ordinary foe. A legitimately disclosed two-/three-foe group
uses the fresh-party group-size bands in `encounter-scaling-playtest-current.md`; do not reject every
three-foe fight merely for crossing the isolated-foe HP threshold.

| Result | Interpretation |
|---|---|
| Ends before any foe gets a meaningful action in most large-party trials | **Too easy:** party size is still being rewarded with pure action dominance |
| Usually 1–3 rounds; one isolated foe creates at least one legible threat window; a three-foe group asks for target priority | **Healthy starting band** |
| An isolated foe regularly exceeds 4 rounds without an unusual defence trait, or spends >20% of a healthy fresh on-level party's HP | **Too durable/punishing:** likely baseline HP/offence, matchup or follow-up pressure is doing group/apex work |
| Requires routine consumable spending merely to continue ordinary exploration | **Reject:** it attacks the longer expedition loop rather than adding combat texture |

An ordinary encounter may occasionally be harmless because build/world matchup matters. The failure
is repetition: a five-person party should not erase almost every ordinary fight before the encounter
can express one creature rule.

### Apex on-level encounter

| Result | Interpretation |
|---|---|
| Dies in ≤2 rounds to an ordinary developed party, with no defensive/target decision | **Too easy:** still reads as a loot container |
| Roughly 3–6 rounds, 1–3 meaningful defensive/target/resource decisions, and 25–65% aggregate party HP spent | **Healthy starting band** |
| One healthy on-level baseline member is passed out before their first ordinary action without a clearly telegraphed exceptional rule | **Too bursty:** reject/retune offence or slot ordering |
| Regularly exceeds 7 rounds after its tactical pattern is solved, especially with >65% aggregate HP spent | **HP wall / attrition tax:** reduce durability before removing legible tempo |
| Requires one item or planned defensive technique in a five-person fight | **Potentially healthy:** apex preparation should matter |
| Requires the same narrow item/skill every time | **Build tax:** broaden counters or reduce the offending rule |

Aggregate HP spent is total HP lost divided by starting total party HP. Healing does not erase the
loss from this measure; record items separately. A pass-out is not automatically failure, but repeated
early removal of one person—especially the new recruit—means target/tempo pressure needs examination.

## Uneven-party interpretation

Binder 8 + companion 1 should generate at least as much pressure as Binder 8 solo, because the extra
body contributes the 0.25 floor. It may still make the outcome safer; recruitment should help.

Do not lower all foe levels to protect the recruit. Instead flag readiness when either happens:

- the recruit is a preferred target for no disclosed tactical reason;
- the recruit is routinely erased before acting even with a reasonable rear rank/defensive choice.

That evidence may call for catch-up XP, arrival equipment, rank advice or a clearer “not ready” signal.
It does not justify making every encounter easier for the developed Binder.

## Tuning order if Recommended misses

Change one family per comparison and preserve the report:

1. **Apex burst/readability:** action-slot placement and 55/60% follow-up strength.
2. **Apex duration:** HP coefficient/cap.
3. **Apex persistent danger:** offence coefficient/cap, only after slot behavior is legible.
4. **Ordinary duration:** 15% whole-slot / 30% fractional HP additions.
5. **Ordinary agency pressure:** 55% lighter follow-up strength.
6. **Grouping:** path radius only if real-world groups consistently fail to form; never make it
   Euclidean or wake/teleport creatures.

Do not change appearance chance, weapon-affinity weights, loot, XP, equipment power or creature
traits to tune party scaling. Those are separate systems and would conceal which adjustment worked.

## Promotion decision

Promote Recommended from development default to accepted coefficients only after the paired evidence
contains:

- solo parity;
- two- and five-person ordinary isolated/group encounters;
- two- and five-person apex encounters;
- one realistic lagging recruit;
- one mixed apex/ordinary fixture;
- a relaunch during an encounter proving frozen membership/slots;
- no one-hit-before-action baseline failure and no repeated apex HP wall.

If a result is inconclusive, keep Recommended as the correctness direction and tune its exposed
coefficients. Do not fall back to Legacy, because Legacy knowingly ignores the settled party-size
requirement.
