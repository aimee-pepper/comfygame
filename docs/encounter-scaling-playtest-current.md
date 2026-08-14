# Encounter scaling playtest — current

Status: implemented additive party-power candidate and default for newly bound worlds; coefficients
remain reversible until Aimee's phone comparison.

## 14 August controlled level-one evidence — correct species severity before coefficients

The committed 12-seed diagnostic at `149c2c3` froze a fresh Binder + Quill at 54 aggregate HP and
held party budget, grouping category, Stability contribution and world level constant. Results:

- Normal isolated contacts: 3–4 rounds, 7.4–37% HP spent; two of six exceeded the 20% target.
- Teeming isolated contacts: 3–8 rounds, 16.7–98.1% HP spent; one of six defeated the party.
- Teeming selected pursuer identities in five of six samples, including an ATK-10 Pierce specimen.

Do not tune additive party scaling from this result. It exposes two earlier authorities:

1. Some level-one ordinary species/offence combinations exceed the isolated Normal opening band.
2. Teeming is altering cast severity/composition, despite the settled ecology rule that Vitality
   increases **cast size and abundance, not trait spread or individual strangeness**.

Correct the sampling boundary first. **Vitality peak** may generate more species and bodies, but it
cannot increase the total trait budget or add peak-derived armour/aposematism affordance. Authored
Vitality **aspects** remain meaningful: Herd and Swarm legitimately raise `trophicDepth`, which may
redistribute the same fixed budget toward armament and produce a more predatory food web. That is a
tradeoff in composition, not free extra species power. After that correction, rerun the exact
diagnostic. If isolated Normal contacts still exceed the healthy band, tune the level-one
creature/offence or unarmed baseline that explains the outliers. Preserve the additive party-power
coefficients until those causes are separated.

Required counterfactual: with the same seed, all non-Vitality readings and all Vitality aspect shares
held constant, changing only Vitality peak must yield an identical prefix of species gameplay trait
vectors; only requested cast length/population and placement may differ. A separate fixed-budget
fixture may change `trophicDepth` and prove that armament gains are paid by less investment elsewhere.
Visual-only morphology may derive from those vectors but cannot perturb them.

### Source-level candidate after causal isolation

After the fixed-budget correction, identical-state counterfactuals showed that the remaining Normal
upper-band misses came from `multi` delivery applying 70% attack to every member. Suppressing
afflictions and replacing the action policy with explicit basic attacks were exact no-ops. The
reversible first candidate is therefore **50% per target for multi delivery**: it spreads one
opening-pair attack budget rather than receiving free extra total damage merely for choosing a free
delivery axis.

The corrected 12-seed result is source-acceptable pending ordinary-phone play:

- Normal: every fight won in 2–4 rounds; 1–11 of 54 aggregate HP spent (about 2–20%).
- Teeming: every fight won in 2–4 rounds; 2–15 of 54 HP spent (about 4–28%).

Do not tune further from these fixtures alone. Confirm one ordinary Normal and one disclosed Teeming
contact on phone, then retain or revise the 50% share from actual readability and player decisions.
Larger-party delivery remains covered by the existing two-/five-person acceptance matrix; spread
damage may scale across more bodies, but must not exceed that aggregate party band.

## 13 August design disposition — do not retune from the single uncontrolled defeat

The available evidence still contains one fresh-save defeat whose world may have been Teeming and
does not retain a complete encounter receipt. Code/rules inspection shows a fresh Binder + Quill has
54 aggregate starting HP and 11 baseline unarmed raw attack per ordinary action pair before matchup,
while generated level-1 creature identity can vary substantially in size, covering, armament,
delivery, affliction and grouping. The Recommended two-person budget adds only 15% HP to one real
foe and adds no pressure follow-up; a genuinely grouped two- or three-foe contact receives no hidden
ordinary scaling because visible bodies already exceed the 1.5-equivalent budget.

That evidence does **not** justify weakening the global coefficients. The most plausible remaining
causes—Teeming density, multiple reachable bodies, world-level Greed/Stability, a difficult species
matchup, opening type or unarmed damage matchup—belong to different authorities and would be obscured
by a blanket nerf. Keep the current Recommended numbers until the controlled Normal/Teeming receipt
pair below exists. If an isolated Normal one-foe opening repeatedly defeats the fresh pair, correct
the level-1 creature/offence or unarmed baseline. If only disclosed Teeming groups fail, tune density,
grouping or contact agency. Apex coefficients remain structurally approved but likewise require the
two-/five-person phone bands before final numerical promotion.

## Fresh-save playtest failure — 11 August 2026

Aimee's first encounter on a new save killed the party. The world may have been **Teeming**, so this
single run does not yet identify whether the failure came from ordinary baseline stats, abundance-
driven world level, reachable grouping, creature matchup or player choices. It does prove that the
Recommended profile is still **implemented but not balance-accepted**.

The settled experience target is unchanged: a healthy level-1 Binder + Quill with opening equipment
should usually beat an ordinary encounter in a normal world in 2–4 rounds while spending roughly
5–20% aggregate party HP. Routine defeat, a healthy member passed out by one untelegraphed ordinary
action, or no plausible retreat/avoidance route fails the opening baseline. Teeming may increase
encounter density and attrition, but cannot make the opening campaign an unavoidable death trap;
apex contact remains a separate deliberately optional risk.

Before retuning a coefficient, compare one controlled opening pair from the same fresh-save state:

1. ordinary unstressed world, level-1 Binder + Quill, baseline equipment;
2. Teeming world with otherwise comparable resolved pressure and the same party;
3. three ordinary contacts in each, recording world level, greed/stability contributions, real foe
   count/grouping reasons, final foe stats, opening type, turn order, damage events and outcome; and
4. a counterfactual using the same creature/roll fixture with Teeming's grouping/world contribution
   removed.

Also record the exact fresh equipment state. Current new-game state supplies no equipped weapon, so
adding a starter weapon during this comparison would change both party damage and combat-tree root
applicability. Keep the baseline genuinely fresh; if the no-weapon party repeatedly fails an isolated
Normal contact, diagnose base unarmed combat before attributing the loss to Teeming or additive
party scaling.

Retune the systemic term that explains the loss. If normal baseline fails, correct level-1 foe
offence/durability or opening party runway. If only Teeming fails because it groups too many reachable
foes, tune abundance/grouping rather than weakening every creature. If one species/matchup fails,
correct or telegraph that identity rather than flattening the global profile.

### Teeming is a composition test, not one undifferentiated difficulty flag

The current rules give Teeming several distinct consequences that evidence must keep separate:

- full resolved Vitality moves enemy-count productivity toward `3.0×` rather than the dead-world
  `0.2×` floor;
- the authored Teeming symbol currently has `enemyTierDelta +1`; in live world generation that adds
  two bodies to the base count *before* the Vitality multiplier—it does not directly add a level to
  each generated-trait foe;
- the two-person Recommended grouping radius is one passable orthogonal step, so greater map density
  raises the chance that two or three already-awake, disclosed bodies legitimately enter together;
- pressure-derived Greed and Stability independently determine world level and may make those bodies
  stronger. Record those contributions rather than attributing the level to the Teeming label.

For a fresh Binder + Quill, the additive budget is 1.5 foe equivalents. One real foe therefore gets
15% encounter HP and no follow-up; two or three real foes receive no artificial ordinary scaling at
all because their actual bodies already exceed that budget. If a two-/three-foe Teeming encounter is
too punishing, the additive scaler may be behaving correctly while density, disclosure/avoidability,
species composition or baseline multi-foe combat is not.

Use these provisional outcome bands to avoid comparing unlike encounters:

| Fresh level-1 Binder + Quill | Healthy first-pass band |
|---|---|
| Normal, one ordinary foe | 2–4 rounds; about 5–20% aggregate starting HP spent |
| Normal, two legitimately grouped ordinary foes | 2–4 rounds; about 15–35% aggregate HP spent; target priority matters |
| Normal, three legitimately grouped ordinary foes | uncommon; about 25–50% aggregate HP spent; retreat or preparation may be sensible |
| Teeming, one ordinary foe | approximately the same individual-fight band as Normal after controlling world level/species |
| Teeming, two or three ordinary foes | may be common and dangerous, but disclosed contact must be avoidable; repeated full-party defeat from baseline gear is a rejection |

These are playtest bands, not dynamic difficulty promises. Do not secretly weaken a foe because it
is the player's first fight, and do not force every fight into the band. The opening campaign's
protection is honest space and agency: a safe entry radius, disclosed group, Look information,
deliberate contact, Unbind and an available route around or away. If those affordances are present
and the player deliberately enters a visibly crowded Teeming contact, a costly win or retreat is
appropriate. If the danger is hidden, contact unavoidable, or even the isolated normal control
repeatedly kills the party, fix that underlying system first.

## Design correction — additive party power, 11 August 2026

The upper-median/count approximation below is superseded for the Recommended implementation. It can
make an encounter easier when a low-level companion joins an uneven party. Maximum level avoids that
drop but makes lower-level allies liabilities. Neither satisfies “difficulty scales with party size
and level.”

Recommended uses the Binder as the stable level anchor and makes every active companion an additive,
level-relative contribution:

```text
anchorLevel = Binder level
levelRatio(member) = 1.09 ^ (member.level - anchorLevel)
memberContribution = clamp(0.5 × levelRatio, 0.25, 1.50)
partyPowerBudget = min(3.0, 1.0 + sum(active companion contributions))
```

`1.09` is the same foe-stat-per-level curve already used by live rules. A same-level companion adds
0.5, preserving the intended equal-level budgets `1 / 1.5 / 2 / 2.5 / 3`. A much lower-level member
still adds at least 0.25 because another body/action is never zero pressure; a much higher-level member
adds at most 1.5 so one veteran cannot create an apex-stat ordinary animal. The total ordinary cap
remains three foe equivalents.

### Why the Binder anchor is valid

This model relies on a campaign invariant, not an arbitrary preference for the player character.
The Binder participates in every expedition and receives every party XP award. Named travellers join
at level 1 unless an authored rule says otherwise; generated people freeze their first-met level at
the Binder's current level; thereafter every active member receives the same encounter/discovery XP.
Consequently an ordinary reachable campaign companion may lag the Binder but does not legitimately
outlevel them. The Binder is therefore the stable maximum/progression clock without making a newly
recruited low-level person lower the foe level.

The `+1.5` high-member clamp remains tolerant DEBUG/migration handling, not permission for a new
arrival system to create companions above the Binder. If a future authored reward does that, it must
either normalize the arrival to the Binder's level or reopen this scaling model with actual combat-
duration evidence; the current cap alone is not proof that a level-25 companion beside a level-1
Binder is balanced.

World, Greed and Stability resolve the real foes' base level from the Binder anchor, not a party
median. Companion level differences are represented once through the power budget rather than
secretly changing species level and then adding count pressure again. This keeps XP/species identity
legible and makes the calculation monotonic by construction.

For ordinary encounters, use `shortfall = max(0, partyPowerBudget - realFoeCount)`:

- each whole shortfall point grants one 55%-strength, affliction-free pressure follow-up and +15%
  total encounter HP;
- the remaining fractional shortfall grants `30% × fraction` total HP, rounded through the existing
  stable largest-remainder allocation, and no action;
- real map foes, path grouping, the three-foe cap, follow-up interleaving and reward rules remain as
  specified later in this file.

Thus a low-level addition can raise pressure gently without lowering foe level; a high-level addition
raises pressure more strongly without turning every ordinary foe into that veteran's level.

For apex encounters, retain count-based action slots because screen tempo depends on bodies/actions,
but derive durability/offence from the same power budget:

```text
extraPower = partyPowerBudget - 1
apex level floor = max(world level, Binder level + 2)
HP multiplier = min(2.4, 1 + 0.70 × extraPower)
offence multiplier = min(1.4, 1 + 0.20 × extraPower)
action slots = 1 for 1–2 people; 2 for 3–4; 3 for 5
```

An equal-level five-person party still produces 2.4× HP and 1.4× offence. Uneven parties move
smoothly according to actual contributed power while every added member leaves both multipliers
nondecreasing. No equipped-item scaling is added.

### Additive-power gates

1. For every permutation of levels 1…25 and party sizes 1…5, adding one active member never lowers
   ordinary budget, apex HP/offence or resolved real-foe base level.
2. Equal-level parties reproduce budgets and apex multipliers above exactly.
3. A level-1 member joining a level-25 Binder adds 0.25 equivalent; a level-25 member joining a
   level-1 Binder adds 1.5, before the total cap. The latter is a tolerant/debug vector, not a
   campaign-supported arrival.
4. Reordering companions changes nothing. Changing which character is the Binder is outside ordinary
   party reorder and may change the anchor by design.
5. DEBUG reports anchor level, each stable member ID/level/raw ratio/clamped contribution, uncapped and
   capped budget, real-foe shortfall, HP fraction and scheduled slots. An aggregate score without the
   contribution ledger is insufficient.
6. Old upper-median previews remain decode-only historical evidence. Newly bound Recommended runs
   persist `scalingRulesVersion: additive-party-power-v1` and every contribution; active encounters
   never recompute after party/level changes.

## Live-build state — corrected 11 August 2026

The installed `ce9b1af` build contains checkpoint `5e97ef4`. **Recommended · party size + level** is
the default preference for newly bound worlds and writes
`scalingRulesVersion: additive-party-power-v1` into the run. Aimee does not need to change DEBUG
Balancing before an ordinary fresh comparison unless deliberately testing Legacy.

The tolerant rule remains intentionally different: an expedition already frozen with schema v1, or
an old active run with no tuning payload, stays **Legacy · level only** until that expedition ends.
Changing the preference cannot rewrite an encounter or world already under way. Therefore every
phone report must name whether the tested world was bound after the Recommended checkpoint; the
DEBUG scaling receipt, not the current global selector, is authoritative for an active run.

Recommended is implemented, not yet balance-accepted. Aimee's settled direction remains that
ordinary encounters scale with party size/level and apexes become materially harder; the remaining
work is the named phone matrix and coefficient tuning against the experience bands below, not a
second scaling implementation.

## Historical diagnosis — upper-median candidate

The sections through **Apex audit disposition** preserve why hidden +level scaling was rejected and
how Profile B's equal-level coefficients were derived. Where they mention upper median or the fixed
count table as current, the additive-power correction above supersedes them.

The live encounter path correctly derives an upper-median level from the Binder and every valid
active party member. That fixes the older single-companion correctness bug.

However, the default DEBUG profile previously labelled **Current live balance** maps to no
party-size scaling profile. Under it:

- additional party members do not add ordinary encounter budget;
- apexes receive no party-size HP or offence multiplier;
- apexes receive only one action slot regardless of party size.

Therefore an apex feeling far too easy with a developed large party is expected behavior under the
legacy profile, not merely an unlucky creature roll.

## Historical immediate playtest choice

Use **B · Recommended start** for the next deliberate **apex** comparison. Its implemented ordinary
`+level` conversion is superseded by the exact pressure-slot candidate later in this document and
must not be promoted. The reversible Profile B values retained are:

- ordinary budget target: `1 + 0.5 × each additional party member`, spent through the corrected
  real-group/pressure-slot contract;
- apex level floor: upper-median party level +2 after world scaling;
- apex HP: +35% per additional member, capped at 2.4×;
- apex offence: +10% per additional member, capped at 1.4×;
- apex actions: 1 for parties of 1–2, 2 for 3–4, 3 for 5.

The existing DEBUG report records party levels, upper median, visible foe IDs, budget, the rejected
level adjustment, apex floor/multipliers/action slots and final foe stats. The replacement adds
path-exclusion, HP-allocation and ordinary follow-up evidence. Values freeze when the encounter
begins and persist across relaunch.

## Promotion gate

Compare at least:

1. one ordinary encounter and one apex with a two-person party;
2. one ordinary encounter and one apex with the largest currently practical party;
3. whether the apex creates meaningful pressure without one-hit defeats or an exhausting HP wall;
4. whether extra apex actions choose legible targets and remain readable on the phone stage.

Two boundary comparisons are mandatory because the candidate's arithmetic changes mode there:

- **Two-person apex:** it receives 1.35× HP and 1.10× offence but remains at one action slot. Confirm
  that this is still a deliberate optional threat rather than a larger ordinary animal; if it folds,
  test a second interleaved slot before adding more HP.
- **Three → four people against one real ordinary foe:** hostile tempo stays at one primary plus one
  55% follow-up while durability rises from 1.15× to 1.30×. Confirm the fourth member does not make
  the encounter feel effectively unchanged; if it does, prefer a fractional visible tempo treatment
  or reachable grouping evidence over another large HP increase.

If Recommended is consistently closer, promote it deliberately as live/default balance in a named
checkpoint. Until then the selector calls the old option **Legacy · level only** so it no longer
conceals what is absent.

## Intended combat experience and tuning bands

Arithmetic correctness is not sufficient for promotion. Judge these bands with healthy, on-level
parties using ordinary available gear and plausible combat-tree spending. Also run one deliberately
well-equipped party: better preparation must still make the fight meaningfully easier, because
scaling should answer added bodies and levels rather than erase earned power.

These are playtest bands, not hidden outcome guarantees:

| Fight | Intended length | Aggregate party HP/armour spent | Passed-out risk | Intended feeling |
|---|---:|---:|---:|---|
| Ordinary, two people | 2–4 rounds | about 5–20% | unusual below 5% | A real interruption, usually manageable without recovery |
| Ordinary, five people | 2–4 rounds | about 8–25% | unusual below 8% | More enemies/tempo answer the larger party without becoming a boss |
| Apex, two people | 4–7 rounds | about 25–50% | plausible, roughly 10–25% | A deliberate risk that may justify retreat or preparation |
| Apex, five people | 5–8 rounds | about 30–60% | plausible, roughly 15–35% | A set-piece fight that uses the party rather than folding to its action count |

“Aggregate spent” means damage that remains after armour/protection and therefore creates recovery
pressure; it is not a requirement to injure every member. Creature identity, matchup, player
decisions and gear should create broad variation around the band.

Reject or retune the profile when any of these repeat across representative encounters:

- an on-level ordinary fight ends before any foe has a meaningful action in most trials;
- an ordinary fight routinely lasts five or more rounds because one body became an HP wall;
- one ordinary action passes out a healthy on-level member without a clearly authored glass-cannon
  identity or telegraphed mismatch;
- an apex routinely ends in three rounds or fewer for an ordinary prepared party;
- an apex routinely exceeds eight rounds without presenting a new tactical decision;
- one apex slot removes more than about 45% of a healthy baseline member's maximum HP after ordinary
  protection, or repeated slots can erase that member before any intervening party turn;
- the five-person result is easier in pressure or attrition than the corresponding two-person fight
  solely because more members were added; or
- a gear/skill improvement is almost completely cancelled by scaling.

The first tuning lever depends on the failure:

1. **Foes never act:** prefer real reachable grouping, pressure-slot placement and modest encounter
   durability before raising ordinary offence.
2. **Fight is long but harmless:** reduce durability and raise legible tempo; do not add more HP.
3. **Burst passes people out:** lower offence/follow-up strength or improve interleaving before
   lowering the whole encounter's durability.
4. **Apex folds to action economy:** adjust action slots/target distribution first, then HP; offence
   is last because it most quickly creates unavoidable knockouts.
5. **Apex is an HP wall:** lower HP and preserve its turns/identity rather than making it ordinary.

Do not retune ordinary and apex coefficients together merely because they share a phone session.
They solve different problems and must receive separate dispositions.

## Historical design audit — ordinary missing-foe conversion, 11 August 2026

The party-size budget direction is right, but the current conversion is too weak to promote as the
ordinary default. At five party members Recommended asks for three foe-equivalents. If only the
triggering foe is eligible, the two missing equivalents become just `+2` foe levels. The live
per-level stat curve is `1.09`, so that lone foe receives only `1.09² = 1.1881×` HP, attack and
armour while facing roughly five party actions. The telemetry calls this a three-equivalent budget,
but the resulting encounter is nowhere near three-equivalent pressure.

Do not fix this by multiplying only HP. A large solitary health bar lengthens a foregone result and
makes ordinary wildlife feel like an apex. Do not spawn invisible reinforcements either; a map foe
must remain a real world entity.

### Revised Recommended candidate — visible group, then tempo

Keep the existing party budget `1 / 1.5 / 2 / 2.5 / 3` for party sizes 1–5, but spend it in this
order:

1. Include the triggering foe and eligible **awake, reachable** map foes within a bounded gathering
   radius. Test radius `1 / 1 / 2 / 2 / 3` by party size. No foe teleports, wakes merely because the
   party is large, or joins through an impassable boundary.
2. Spend each whole missing foe-equivalent as one **pressure slot** distributed across the real foes
   already in combat. A pressure slot adds +15% total encounter HP, divided proportionally across
   those foes, plus a lighter follow-up action, initially 55% strength. The follow-up cannot produce
   an affliction and should prefer a different legal target where possible. It must be visibly
   labelled in the turn order and combat log.
3. Spend a half-equivalent remainder as bounded durability, initially +15% HP across the encounter,
   not a random level. This makes the 2- and 4-person steps perceptible without adding another full
   hostile action.
4. Keep world/party **level** scaling separate. Encounter composition should not masquerade as a
   higher-level species, alter its XP band, or multiply armour merely because no neighbour happened
   to be standing beside it.

One ordinary foe against five party members would therefore receive +30% HP and two visible 55%
follow-ups rather than +2 hidden levels; two real foes would share +15% HP and one follow-up between
them; three real foes need no missing-budget compensation. This deliberately remains somewhat less
than three fully independent foes, because concentrated attacks and armour make a single actor more
volatile. It is a reversible comparison candidate, not promoted balance.

### Ordinary candidate gates

- Never exceed three real foes or the budget's number of pressure slots.
- Follow-ups are interleaved, not consecutive; no ordinary foe may erase one healthy on-level party
  member before that member can act under baseline gear.
- Area attacks, retaliation and afflictions do not multiply through lighter follow-ups.
- A one-person party is byte-for-byte the legacy encounter after ordinary level resolution.
- Flee cost, loot, XP and Bestiary identity depend on real defeated foes, never pressure slots.
- Save/relaunch freezes real members, slot assignment and strength; changing DEBUG tuning cannot
  alter a fight already opened.
- Adding an active member may never make the resulting encounter easier. This finding led to the
  additive-power correction above. Historical comparison vectors were
  vectors `[9] → [9,1] → [9,1,1]` and `[2,4,6,20] → [2,4,6,8,20]`; the current upper-median
  reference has an odd-party discontinuity that the pressure budget must overcome. If it cannot,
  replace the separate median/count approximation with a summed party-power-equivalent calculation;
  do **not** switch casually to maximum level, which would make one veteran turn low-level allies
  into liabilities.

## Apex audit disposition

Recommended's apex candidate remains the correct first phone comparison. At five members it combines
the +2 level floor, 2.4× party-size HP, 1.4× party-size offence and three interleaved actions, with
follow-ups already reduced to 60% and unable to afflict. That supplies durability **and** tempo rather
than relying on a health wall alone. Keep the existing gates: distinct targets where possible,
legible turn-order slots, no one-hit defeats from an on-level healthy baseline party, and no
consecutive apex turns while another actor can act.

Do not scale directly from equipped item tier yet. Additive party power is the legible level/count
commitment the player made; matching every gear improvement risks erasing the reward for
finding and crafting better equipment. Gear-sensitive difficulty belongs only in a later optional
challenge model if ordinary playtesting proves level and party size insufficient.

## Exact implementation candidate — ordinary pressure slots

This section closes the reversible Engineering handoff left abstract above. It does not make the
coefficients final balance; it makes the next phone comparison test the intended mechanic rather
than the rejected hidden-level substitute.

### Scope and budget

Apply ordinary pressure compensation only when the encounter contains **no apex**. An apex plus
legitimately nearby ordinary creatures uses the real participants and Profile B's apex scaling; it
does not stack ordinary synthetic tempo on top. Apex HP/offence multipliers apply only to the apex
body. Nearby ordinary creatures retain their already resolved world stats/actions and do not inherit
the apex multiplier.

Use the additive party-power contract at the top of this file. The equal-level results remain:

| Active combatants, Binder included | Equivalents | Gathering radius |
|---:|---:|---:|
| 1 | 1.0 | 1 |
| 2 | 1.5 | 1 |
| 3 | 2.0 | 2 |
| 4 | 2.5 | 2 |
| 5 | 3.0 | 3 |

Beginning with the triggering entity, include up to three real map foes that are awake, reachable
from it through currently passable tiles within the radius, and not separated by an impassable edge.
Use a deterministic shortest-path distance and stable entity-ID tie break. Euclidean/Chebyshev
proximity alone is insufficient across a chasm or wall. Nothing teleports, wakes, crosses fog merely
because the party is large, or joins after combat begins.

Let `shortfall = max(0, partyPowerBudget - realFoeCount)`. Each whole point creates one **pressure
slot**. Any fractional remainder creates `30% × fraction` durability only. Do not roll the remainder
and do not convert either part to foe levels.

### What compensation does

- Each whole pressure slot adds +15% to the encounter's total starting HP and one 55%-strength
  ordinary follow-up action.
- A fractional remainder adds `30% × fraction` total starting HP and no follow-up.
- Distribute HP proportionally over real foes before integer rounding. Use largest-remainder rounding
  with stable foe-ID ties so the summed added HP equals the intended encounter addition and no array
  order changes it.
- Pressure durability changes `maxHP/currentHP` only. It does not raise level, attack, armour,
  initiative, affinity, XP, loot, Bestiary identity or species traits.
- Real foe count at or above the desired equivalents receives no compensation. The three-foe hard
  cap remains; a two-person party may honestly meet two nearby real foes without adding negative
  scaling.

Examples under Profile B:

| Party | Real foes | Shortfall | Result |
|---:|---:|---:|---|
| 2 | 1 | 0.5 | +15% encounter HP; no extra action |
| 3 | 1 | 1.0 | +15% HP; one 55% follow-up |
| 4 | 2 | 0.5 | +15% HP; no extra action |
| 5 | 1 | 2.0 | +30% HP; two 55% follow-ups |
| 5 | 2 | 1.0 | +15% HP; one 55% follow-up |
| 5 | 3 | 0 | real group only |

### Follow-up scheduling and combat semantics

Add a saved turn-slot kind distinct from `apexFollowUp`, provisionally
`ordinaryPressureFollowUp(Int)`. The ordinal is encounter-local and stable. Assign slots round-robin
over real foes in their resolved primary initiative order, stable ID breaking ties; do not give one
foe a second pressure slot until each other living foe has one. Persist the complete schedule when
the encounter opens.

A pressure follow-up:

- is interleaved after another living actor whenever the remaining schedule permits; never place two
  turns from the same foe consecutively while another actor can act;
- is one single-target delivery at 55% rolled attack, even if the creature's primary delivery is
  area or multi;
- cannot apply Burn, Poison, Dazzle, Ground, legacy Bleed or any later affliction;
- cannot trigger another follow-up, multiply retaliation or duplicate an apex/wild rule;
- prefers a different currently legal target from that foe's primary/earlier follow-up during the
  round, then falls back to an ordinary legal target;
- disappears harmlessly if its assigned foe is passed out before the slot; it never transfers to a
  surviving foe mid-fight.

The turn-order UI and combat log label it **Lighter follow-up** with a redundant secondary-action
shape. Opening copy may say **“Pressed — 2 lighter follow-ups.”** Do not call an invisible extra foe,
reinforcement, pack member or higher-level creature into fiction.

### Default and migration checkpoint

Once this candidate exists, **B · Recommended start** becomes the development/shipped default for
newly bound runs; Legacy remains an explicit DEBUG comparison, not the absence fallback.

- Change `DebugTuningProfile`'s property default and tolerant missing-key decode to `.recommended`.
- Version the persisted tuning profile. On the first v2 load, migrate old absent/`.current` values to
  `.recommended`; after migration, a tester may deliberately select Legacy and retain that choice.
- Never rewrite `WorldRun.tuning` or an active/saved encounter. A run freezes the profile at bind;
  the new default begins with the next bind.
- Report `scalingRulesVersion`, requested profile, real foes, reachability exclusions, shortfall,
  HP allocation and exact turn slots in DEBUG/bug context.

This promotion is intentionally reversible tuning but not optional correctness: leaving `nil` as the
default would knowingly preserve the reported no-party-scaling bug.

## Implementation and phone gates

1. Path-based group selection proves wall/chasm exclusion, awake-only inclusion, three-foe cap and
   deterministic ID ties for every party radius.
2. Exact examples in the table above pass at levels 1, 8 and 16; one-person ordinary fights remain
   byte-equivalent after ordinary level resolution.
3. HP largest-remainder allocation preserves the exact intended total and save/relaunch bytes.
4. Follow-ups are interleaved, single-target, affliction-free and inert after assigned-foe defeat.
5. XP, loot, flee cost, Bestiary and discovery depend only on real foes.
6. Additive party power is nondecreasing for vectors `[9] → [9,1] → [9,1,1]`, `[1] → [1,9] →
   [1,9,9]` and `[2,4,6,20] → [2,4,6,8,20]`, plus exhaustive level 1…25 permutations. No
   upper-median reference remains in newly bound Recommended rules.
7. In a mixed apex/ordinary group, the apex alone gets Profile B apex level/HP/offence/actions once;
   ordinary bodies retain world-resolved stats/actions and the encounter gets zero ordinary pressure
   slots.
8. Migration changes the next-bound default without altering an active fight or preventing an
   explicit post-migration Legacy comparison.
9. Phone comparison covers two- and five-person ordinary fights with one and three real foes, plus
   two- and five-person apexes. Reject/retune if an on-level healthy character can be erased before
   acting, defence/Unbind becomes irrelevant, or an obvious win becomes an HP chore.
10. Include a realistic lagging recruit fixture—Binder 8 plus companion 1—against the same isolated
    ordinary foe and apex as Binder 8 solo. Adding the recruit may make the fight safer, because
    recruitment should matter, but cannot reduce generated pressure or make the recruit a preferred
    sacrificial target. Record whether the recruit can be erased before acting; if so, treat that as
    visible party-readiness/catch-up evidence rather than secretly lowering every foe to protect an
    under-level choice. Also retain one above-Binder DEBUG vector solely to prove tolerant bounded
    output.

After Aimee's comparison, preserve the report and either promote these coefficients as the named
live profile or revise them explicitly. Do not silently fall back to Legacy merely because tuning is
still under playtest.

For gate 6, report two transparent scores rather than one opaque difficulty number: **durability
pressure** is summed final foe HP divided by the same real foes' summed unlevelled derived HP;
**opening offence pressure** is the first round's summed expected attack share (primary delivery plus
0.55 per pressure follow-up, using final attack) divided by those same foes' unlevelled one-primary
attack baseline. The denominator is frozen across the compared party vectors, so a changed level
reference cannot disappear through normalization.
Both must be nondecreasing when one active member is appended and all world/entity facts are held.
These scores are test diagnostics only; they neither choose balance nor appear to players.

## Design implementation review — 11 August 2026

The implemented Recommended slice is **accepted for phone playtesting**, not yet frozen as final
balance. Read-only source review confirms the intended semantic boundary:

- the triggering map entity is always real, while additional foes must be awake, revealed,
  legitimately visible and connected within the party-size path radius; deterministic distance/ID
  ordering and the three-real-foe cap prevent array-order recruitment;
- Recommended anchors ordinary world level to the Binder and spends companion contribution through
  the additive ledger, not an upper-median or hidden per-missing-foe level increase;
- largest-remainder allocation adds exactly the encounter-wide HP fraction once and pressure slots
  are stored as 55% single-target actions;
- lighter actions rotate among eligible real foes, attempt a different legal target, cannot inherit
  area/multi delivery, cannot inflict Rend bleed or emanation statuses, and vanish with their assigned
  defeated body; and
- mixed apex encounters explicitly zero ordinary pressure so apex and ordinary scaling cannot stack.

Focused Engineering evidence reports 92 tests passing and the full product suite at 1,022 passing;
the signed build is installed for playtest. Remaining acceptance is experiential: compare the phone
matrix in the test card, especially five-person isolated foes, lagging recruits, apex time-to-result
and whether an on-level party member can be removed before acting. Coefficients remain reversible
until that evidence is reviewed.
