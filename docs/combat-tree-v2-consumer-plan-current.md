# Combat tree v2 consumer plan — current

**Status:** implementation-enabling sequence; semantics remain owned by
`combat-node-viability-current.md`.
**Purpose:** replace the legacy catalogue→unused-loadout illusion with a small number of shared,
observable rules primitives. This is not a license to activate a partially functioning v2 tree.

**Live implementation checkpoint (12 Aug):** twelve nodes have real DEBUG-path scenario consumers:
Heavy Hand and Keen Eye in `782743c`; Quick Step and Light Frame in `a41159e`; Thick Hide in
`b7b320c`; and Iron Skin, Bulwark and Shieldwall in `df5a963`. Shared armour freezes equipment,
sturdiness and exact node ownership at contact while encounter rank and consciousness remain saved,
dynamic combat facts; preview and committed incoming damage share one calculation. Stagger is live in
`d33c027` with per-slot next-round delay that preserves apex/pressure interleaving and exact payload;
its last runner evidence is 102/102 focused and 1,208/1,208 full, plus a generic-build-clean exact
multi-foe order assertion. Footwork and Ghost are live in `c4d62a5` with 108/108 focused and
1,214/1,214 full tests; their shared final-target resolver also repairs Sidestep consumption and
area/multi exclusion. Typed Insulation is live in `f944cff` with 113/113 focused and 1,219/1,219
full tests. Exact-owner Immovable armour scope is live in `dbb1443` with 116/116 focused Combat
and 1,222/1,222 full tests. Work paused after that checkpoint; Attunement remains blocked on a real
Channelworks combat attack. Do not repeat any completed slice or count the remaining dormant fields
in `CombatDerivedStatsRules` as activated.

`combat-technique-registry-current.md` is the exact grant/target registry. Runtime never infers a
technique from graph role, legacy effect kind or a non-null legacy payload.
`combat-tree-node-copy-current.md` owns the concise selected-detail Effect line. Legacy poetic blurbs
may remain as secondary flavour only and never override the actual consumer semantics.

## Current-state finding

The legacy tree parser writes fields for most passives, but current production rules directly read
only the three field-concealment values (`encounterChance`, `sightedAtRange`,
`partySightedAtRange`) plus granted skills through separate paths. A field differing in a loadout
test is therefore not evidence that a node affects play.

Checkpoint `356b2ac` added a deliberately dormant `CombatDerivedStatsRules` foundation for fourteen
slice-1 nodes. Its tests prove pure arithmetic only; the source explicitly says production preview,
encounter creation and committed combat do not call it, and `CharacterState` still persists no v2
ownership. Count those fourteen as **specified/scaffolded, zero activated**, not as partial combat-v2
completion. The next slice touching this foundation must connect one shared frozen actor derivation
to preview, encounter creation and resolution together behind the DEBUG v2 route; another isolated
loadout/helper test is not forward progress.

The foundation currently exposes both a total `attack` and diagnostic fields such as
`matchingPhysicalDamageBonus` / `momentumDamageBonus`. These diagnostic components are provenance,
not additional damage for a caller to add again. Before activation, make that type boundary
unambiguous—either return a structured base-plus-components calculation with one `total`, or keep
the components diagnostics-only and consume only the total. A Heavy Hand/Keen Eye/Momentum bonus
must enter a strike exactly once.

The v2 runtime may land behind a DEBUG/dual-schema gate in the following slices. Player ownership,
purchase and migration switch only after all 72 stable IDs have a scenario consumer and the full
release gate in `combat-node-viability-current.md` passes.

### Existing mechanics are adapters, not blank implementations

The remaining stable-ID work is not 68 mechanics built from nothing. A source/test audit on 11 Aug
confirms several settled effects already have real legacy-path consumers and scenario coverage. Their
v2 checkpoint adapts exact stable-node ownership into the existing receipt/resolver, then adds the
stable-ID counterfactual and frozen provenance; it does not rewrite the mechanic under a parallel
state machine.

| Existing playable mechanic | Reuse boundary for v2 |
|---|---|
| Pry, Overbear, Shatter and Finish | Preserve existing technique target/action/cooldown and damage resolution; replace legacy branch-derived grant with canonical node ownership and v2 contribution receipt where applicable |
| Ward, Brace, Sidestep, Fall Back, Draw Off and Interpose | Preserve current saved combat receipts and target legality; wire the exact granting node and prove a non-owner cannot borrow the action |
| Conceal and Ambush | Preserve current conceal/zero-turn opening rules, including shared opening-credit restrictions; change only ownership/provenance |
| Slippery and Watchful | Preserve the saved `OpeningResolution` probability roll, suppression and pending-foe-action behavior already covered in `WorldTests`; replace legacy loadout lookup with frozen stable-ID participant inputs |
| Quiet Step, Low Profile and Shadowed | Preserve field-awareness hesitation/detection-radius rules and per-creature receipts; stable-ID ownership feeds the existing strongest-party field derivation |
| Vanish | Preserve the one-per-expedition `vanishWithdrawSpent` receipt and Withdraw transaction from `ce9b1af`; stable node ownership replaces legacy `freeFlee`, while decoded Rout stays inert |
| Unseen | Preserve encounter-entry concealment after saved opening classification; stable ownership replaces the legacy capstone Boolean |

This table does **not** count those nodes as v2-complete. Their ordinary paths still derive many
effects from legacy branch depth/loadout fields, and DEBUG selecting the canonical stable ID does not
necessarily activate them. Completion requires exact ownership, a stable-ID counterfactual,
relaunch/frozen-state behavior and the shared production resolver. Conversely, Engineering must not
add a second ambush roll, conceal dictionary, retreat receipt or field-movement engine merely to
satisfy that proof.

### Catalogue promotion prerequisite — completed in `71ffca2`

This migration is complete and must not be repeated as queued work. Before `71ffca2`, running the
generator with `--write` would have failed because the native model/validator still required
generated legacy payloads to equal the linear catalogue. Schema v2 deliberately differs at exactly
three technique assignments:

- `combat.offense.swiftness.blur`: `nil` → canonical `blur`;
- `combat.craft.emanation.emanation_strike`: migration input `elemental_strike` → canonical
  `emanation_strike`;
- `combat.craft.emanation.quench`: migration input `steady` → canonical `quench`.

`71ffca2` added canonical optional `techniqueID` and exact Effect-copy consumption to the native
model, changed validation to schema-2 authority/artifact while treating legacy payloads as migration
input, regenerated, and pinned authority/source hashes. The result has exactly **20** non-null
technique IDs and **52** nulls across 72 nodes; `python3 scripts/generate_combat_tree_v2.py --check`
is green on 11 Aug. Remaining work begins with real gameplay consumers, not catalogue regeneration.

## Shared consumer slices

### Immediate activation checkpoint — Heavy Hand and Keen Eye

**Source checkpoint:** `782743c`; focused 12/12 and full 1,150/1,150 green. This remains a DEBUG
comparison slice pending rendered/phone acceptance and does not promote release ownership.

The first implementation checkpoint deliberately activates only **Heavy Hand** and **Keen Eye**
through the DEBUG combat-v2 route. This is an end-to-end proof, not a claim that the full actor-
derivation slice is live:

- DEBUG supplies exact stable node IDs; it never infers ownership from legacy branch depth, graph
  role or presentation position;
- encounter entry freezes the actor's matching physical pre-matchup bonus and stable-node
  provenance;
- the visible direct-hit preview and committed fixed-roll attack call the same damage calculation;
- Heavy Hand contributes +2 exactly once to an ordinary Crush weapon hit and to Overbear; Keen Eye
  contributes +2 exactly once to an ordinary Pierce weapon hit and to Pry. Either contributes zero
  to the wrong damage kind. Legacy Unbind is not a weapon technique and cannot inherit either bonus
  merely because its old damage resolver falls back to the equipped weapon kind;
- relaunch preserves the frozen encounter receipt, and changing DEBUG ownership after encounter
  entry cannot rewrite an encounter already underway; and
- the first harness may expose this on the Binder only, but that is explicitly a harness limitation,
  never a design ownership rule.

Do not call Momentum, initiative, maximum-HP, armour, evasion or emanation fields activated in this
checkpoint. They remain scaffolded until encounter order, actor HP, incoming mitigation or their
other real production consumer reads the same frozen derivation. The frozen value is a named
typed pre-matchup bonus/provenance snapshot—not an ambiguously reusable `attack` total—and
diagnostic components are never added to it a second time. It preserves a bonus per eligible strike
kind: ordinary Attack uses the frozen equipped kind, Overbear declares Crush and Pry declares
Pierce. A single value calculated only from the equipped kind is insufficient because a technique
may declare a different physical kind.

### 1. Actor derivation and order

Build one `CombatDerivedStats` path used by encounter creation, preview and actual resolution:

- Heavy Hand, Keen Eye;
- Quick Step, Light Frame, Light Touch and Momentum;
- Thick Hide, Iron Skin, Bulwark and Shieldwall;
- Footwork, Insulation, Attunement and Immovable.

Formation bonuses aggregate strongest-once from stable party identity. Initiative changes after
entry use the same stable reorder operation and cannot interrupt the current action.

After the Heavy Hand/Keen Eye proof, finish this slice in consumer-shaped checkpoints rather than
catalogue order. Quick Step/Light Frame, Thick Hide and the shared Iron Skin/Bulwark/Shieldwall
armour receipt are complete in the checkpoints above:

1. **Authoritative order:** Quick Step and Light Frame, then Light Touch and Momentum once exact
   frozen gear initiative is available. Preview order, encounter order and relaunch must agree;
   Momentum reads the resulting penalty and enters direct damage once.
2. **Actor durability:** Thick Hide establishes maximum/starting expedition HP and safe respec
   clamping before any mitigation node relies on that maximum.
3. **Armour formation:** Iron Skin, Bulwark and Shieldwall feed the one incoming-harm armour value;
   five-member fixtures prove strongest-once ally aggregation, unconscious-owner removal and stable
   rank identity.
4. **Avoidance and emanation:** Footwork enters the authoritative miss calculation; Insulation,
   Attunement and Immovable enter matching harm/attack and armour-scope calculations with typed
   choices. Each uses the same preview/commit path and exposes stable-node provenance only in DEBUG.

Do not combine checkpoints merely because their values come from the same derived structure. Each
checkpoint is complete only when the named gameplay consumer, counterfactual scenario and saved
encounter receipt are live.

#### Quick Step / Light Frame contained checkpoint

**Implemented:** `a41159e` (`Freeze combat v2 initiative receipts`). The DEBUG stable-ID path freezes
personal +4/+3 initiative entries, drives the real saved order and exposes provenance without
promoting ordinary ownership. Treat this section as maintained acceptance authority, not queued work.

For the next DEBUG activation, freeze one initiative entry for every participating actor at
encounter creation. The current legacy personal baselines remain Binder 42 and companions 40;
Quick Step adds +4 and Light Frame adds +3 to their exact owner. Because both are personal effects,
one actor owning both receives +7; copies on other party members neither stack onto that actor nor
become a strongest-party aura. Foes retain their existing initiative/Crush penalty and `strikesFirst`
authority.

The saved entry contains baseline, stable-node components, total before tie-breaking and the final
order position. The actual encounter sorter consumes that total. DEBUG may preview each disclosed
actor's baseline/components/total before contact, but it must label equal-total order as unresolved
because the saved encounter RNG breaks ties only when contact is created. Once the encounter exists,
one compact DEBUG affordance presents the frozen final order and exact stable-node provenance in a
sheet/popover; it never expands the combat header or displaces the stage/action bar. Relaunch preserves it
and later harness changes cannot reorder the active fight. Tests cover each node alone, both on one
actor, nodes split across a five-person party, an unconscious/nonparticipant owner contributing
nothing, a foe-order crossing, deterministic saved tie-breaking and disabled/empty v2 parity.

#### Thick Hide contained checkpoint

Thick Hide is an **expedition-health** consumer, not an encounter-only arithmetic field. Freeze one
health-cap entry for every departing party member when a new expedition is created. Its stable
identity, ordinary maximum from character level/base identity/equipment, exact `thick_hide` +6
component, final expedition maximum and starting current HP travel together. A conscious owner starts
the new expedition at that final maximum; the node is personal and never grants HP to another party
member.

The run's frozen health-cap entry becomes the sole maximum-health authority for world items, combat
healing, health-fraction gambits, passed-out presentation and encounter UI. Do not continue displaying
the Binder/companion tuning constants from `WorldRun` while healing clamps against a different
`CombatRules.maximumHealth` value. Existing encounters need no second copy: they reference the
expedition receipt and retain their current HP.

DEBUG preview at Base may compare ordinary maximum → Thick Hide maximum for the selected exact
person. It must label this as **next expedition** and must not heal, injure or rewrite an active run.
Changing DEBUG ownership after departure affects only a later expedition. Relaunch preserves the
frozen maximum and current HP exactly.

Migration and respec preserve health rather than manufacture damage or healing:

- a legacy run with no frozen entry adopts its already-saved current HP and derives a compatible
  maximum once; adding a newly recognized node may raise the cap but does not grant current HP;
- removing a node at Base affects the next departure. If tolerant adoption ever encounters a live
  run whose old maximum exceeds the new one, clamp only `currentHP` above the new cap; do not preserve
  an impossible over-cap value, create a damage event or alter outcome/recap history;
- ordinary return-home recovery remains implicit: the next run starts full. No Base-side current-HP
  field is introduced.

Acceptance proves Binder and companion baselines, Thick Hide alone (+6), one owner/no aura in a
five-person party, equipment/level composition exactly once, world-item and combat-heal clamping,
health-fraction gambit agreement, passed-out behavior, active-run harness changes having no effect,
save/relaunch, tolerant legacy adoption and disabled/empty-v2 parity. The UI comparison must read the
same frozen receipt consumed by rules; a changed loadout field or `maximumHealth` helper alone is not
completion.

##### Exact authority and migration handoff

The live split is concrete: `CombatRules.maximumHealth(of:in:)` derives the character-aware ceiling,
`CombatRules.health(of:in:)` still reports Binder/companion tuning constants, while world healing and
some presentation call the former against mutable Base state. Thick Hide must remove this split for
an active expedition; adding `+6` to only the existing helper is explicitly insufficient.

Add a tolerant optional array on `WorldRun` rather than a second health dictionary keyed only by
roster index:

```text
RunHealthCapEntry
  member: PartyMember                 // Binder or stable roster index
  ordinaryMaximum: Int                // level/base identity/equipment, exactly once
  components: [{ nodeID, amount }]    // Thick Hide is +6
  maximum: Int                        // ordinaryMaximum + component total
```

The departure and anchored-revisit transactions create exactly one entry for every actual departing
member and initialize that person's current HP from the same entry's `maximum`. The array is the
saved receipt; duplicate members are invalid and normalized deterministically, and somebody not in
the expedition has no entry. All active-run maximum queries go through one `WorldRun` lookup. Base
preview may call the pure derivation for a proposed *next* expedition, but active combat/world code
may not fall back to mutable Base ownership when a receipt exists.

Legacy adoption happens in post-decode state normalization, where both the restored `WorldRun` and
the owning `GameState` are available—not inside a nonmutating getter and not by rewriting the raw
decoder in isolation. For each actually participating legacy member, derive the compatible ordinary
maximum under the legacy/empty-v2 path, set `maximum` to at least the saved current HP, record no
Thick Hide component unless the run already contains authoritative v2 ownership, and persist that
receipt on the next save. This prevents loading an old wounded character from manufacturing either
healing or damage. Once adopted, later Base loadout, level, roster or DEBUG changes cannot rewrite it.

The authoritative query returns `(current, maximum)` from `binderHP`/`companionHP` plus the matching
receipt. Combat healing, field healing, fraction thresholds, bars and passed-out checks consume that
query. Any mutation clamps to the receipt maximum. A missing entry for a nonparticipant is not a
license to synthesize expedition health from Base state; it is an unavailable actor. Focused tests
must include the current regression shape: a Fortitude/gear/Thick-Hide maximum visibly agrees in the
world bar, encounter bar, field-item clamp and combat-item clamp before and after relaunch.

#### Light Touch / Momentum contained checkpoint

These nodes currently lack a real input: live `GearDef`/`GearInstanceProfile` stores no initiative
modifier, so a helper receiving `gearInitiativeModifier` is scaffolding rather than a consumer. Add
one tolerant frozen integer **tempo modifier** to equipped gear. This is not inventory weight,
carrying capacity, movement encumbrance, durability or another equipment subsystem; only gear being
worn by the acting person contributes to combat initiative.

Every catalogue definition and craft recipe owns its explicit value. `GearInstanceProfile` freezes
it when the exact object is created or migrated so a later catalogue rebalance cannot rewrite gear
already found, crafted, bought or worn. Store a tolerant optional `tempoModifier` plus version during
decode so **missing legacy data remains distinguishable from an authored zero**; full-state
normalization fills a missing value from the then-current authored definition once and persists it.
After normalization, a participating equipped profile with no frozen value fails validation rather
than silently rereading mutable catalogue data. Never infer the value at runtime from display name,
rarity, raw tier, material density or icon.

Use this reversible first authored profile when populating current content:

| Equipped family | Tier 1 / 2 / 3 / 4 tempo modifier |
|---|---|
| Close Rend or Pierce weapon | 0 / 0 / 0 / 0 |
| Mid-reach weapon | -1 / -1 / -1 / -1 |
| Far-reach weapon | -2 at its authored tier |
| Crush weapon | -1 / -2 / -3 / -4 |
| Off-hand | -1 / -2 / -3 / -4 |
| Head | 0 / -1 / -2 / -3 |
| Body | -1 / -2 / -3 / -4 |
| Hands | 0 / 0 / -1 / -1 |
| Feet, tool or keepsake | 0 / 0 / 0 / 0 |

Wild-rule weapons receive explicit values matching their visible handling rather than an extra
rarity tax: Two-Natured Blade 0, Long Fang -2, Ranked Spear -1, Barbed Edge 0, Living Hook 0, Quiet
Knife 0, Bloodletter 0 and Warded Haft -3. A weapon matching more than one row uses its explicit
authored value, never cumulative family penalties. Specialist crafted gear starts from its recipe's
explicit family value; material properties do not silently change tempo in this slice.

At expedition/encounter entry, sum positive equipped modifiers separately from negative equipped
modifiers. Light Touch halves the negative subtotal toward zero, then restores the positive subtotal
unchanged. The **effective gear initiative penalty** is the positive difference between the actor's
unencumbered initiative (identity/stats plus Quick Step/Light Frame) and their final initiative after
that resolved gear modifier. Thus positive gear may offset a penalty but is never doubled or halved.
Low base initiative and temporary turn-order effects are not gear penalties.

Momentum contributes `min(4, floor(0.4 × effective gear initiative penalty))` raw damage to that
owner's landed direct weapon attacks and declared direct-damage techniques, before matchup and
armour. It contributes once per hit, not per target or damage component, and zero to Unbind, status
ticks, items, reflected harm, companions or attacks made while the relevant gear receipt is absent.
Light Touch intentionally reduces Momentum when it relieves load: the player is choosing recovered
speed versus fully exploiting committed weight. Heavy Hand/Keen Eye may coexist because they reward
a damage kind rather than load.

One frozen actor tempo receipt contains the exact equipped stable IDs and per-piece modifiers,
negative subtotal, positive subtotal, Light Touch adjustment, Quick Step/Light Frame components,
unencumbered/final initiative, effective penalty and Momentum bonus. The saved encounter order and
damage preview/commit read it; changing equipment, DEBUG nodes or catalogue data after contact cannot
rewrite the fight. Base preview is labelled **next encounter** and may compare loadouts without
mutating them.

Acceptance covers every current catalogue family and all eight wild weapons; all-empty gear; mixed
positive/negative future-proof fixtures; odd negative rounding; Light Touch alone; Momentum at
penalties 0/1/2/3/5/10+; both nodes together; Quick Step/Light Frame composition; Heavy Hand/Keen Eye
composition; multi-hit/multi-target exactly-once behavior; Unbind/status/reflection exclusions;
crafted and purchased stable profiles; legacy adoption; post-contact equipment/DEBUG changes;
preview/order/damage parity; relaunch; and disabled/empty-v2 parity.

#### Iron Skin / Bulwark / Shieldwall contained checkpoint

These three nodes feed one **incoming-harm armour calculation**; they must not create a second damage
resolver. At encounter entry, freeze each participating person's exact equipment protective power,
Fortitude sturdiness multiplier and stable personal node IDs. The encounter, not live Base equipment
or mutable DEBUG controls, owns those inputs until it ends. Entry rank merely initializes the
encounter's existing saved current-rank state; armour always reads that current rank and current
consciousness because Fall Back and passing out legitimately change formation.

For the actor actually receiving a landed direct hit, calculate in this order:

1. equipment protective power × the actor's frozen sturdiness;
2. Iron Skin adds +2 when that exact actor owns it;
3. a conscious Bulwark owner adds +1 to themself;
4. one or more other conscious Bulwark owners in the receiver's current rank grant +2 **once**;
5. if the receiver is currently in front and any conscious front-rank participant owns Shieldwall,
   add +2 **once**, including when the receiver is that owner;
6. apply the hit's armour-ignoring fraction to the combined armour unless the receiver's Immovable
   later makes armour universal; then continue through the one ordinary damage/minimum pipeline.

Bulwark's personal +1 and strongest-once allied +2 are different components and may coexist. Iron
Skin, Bulwark and Shieldwall may also coexist because they ask for different investments; duplicate
party copies never multiply either aura. A passed-out owner stops providing formation benefits
immediately, while damage already resolved is never recalculated. Redirection uses the final target's
personal and formation armour only. Cover remains later post-mitigation splitting and cannot armour
its redirected share again.

Preview and committed damage consume the same pure armour breakdown. Ordinary UI may show the
receiver's current total and named formation sources already disclosed by party composition; DEBUG
adds stable-node provenance. It must not expose hidden foe action rolls or promise that a current
formation total survives a pending rank change/pass-out.

Acceptance covers every node alone, all three together, two duplicate Bulwarks, two duplicate
Shieldwalls, same-rank versus different-rank, front/middle/back, owner and ally pass-out, Fall Back,
five-person formation reorder, redirected target, armour-ignore and later Immovable composition,
preview=commit, save/relaunch, post-entry harness/loadout changes and disabled/empty-v2 parity.

#### Stagger contained checkpoint

Stagger listens only to its exact owner's landed direct Crush hits. After the hit resolves, consume
one saved encounter RNG roll for the node's 30% chance unless Breaking Blow supplied its automatic
first-eligible-hit Stagger for that personal-turn window. Misses, non-Crush hits, carried/splash/
status/environment damage and a target defeated by the hit consume no Stagger RNG.

This checkpoint exposes and tests the typed **automatic Stagger producer seam**, but it counts only
Stagger as activated. Breaking Blow is not complete—and must not be counted—until its exact-owner
armour-ignore, first-landed-Crush personal-turn/opening receipt and relaunch behavior are all live.
Synthetic automatic-producer fixtures here prevent the later capstone from requiring a second delay
engine; they do not promote a partial capstone.

A success writes one pending receipt on that living foe for the next not-yet-started ordinary global
round. Live Ambush is selected as a zero-turn action on its owner's first ordinary scheduled slot,
so round N has already begun and its Stagger targets N+1 like every other current attack. Only a
future producer that genuinely resolves before the ordinary cursor begins may target the upcoming
round 1; current Ambush does not use that seam.
The receipt stores target foe, applying round, source actors/nodes and whether any source was
automatic. Further successes before application merge provenance and refresh the same receipt; they
never move the block twice. Breaking Blow's automatic result suppresses the redundant 30% roll on
that hit, while a later eligible hit in the same personal turn may still roll ordinary Stagger and
merge with the already-pending receipt.

At the applying round boundary, first build the authoritative saved schedule from frozen/current
initiative, including Cascade and its already-interleaved apex/pressure follow-ups. For each pending
foe, process that foe's slot indices from last to first and swap each slot with the next living
scheduled slot owned by another actor when one exists. Every owned slot moves at most once; slot
kind, strength,
affliction-suppression and relative order remain exact. This delays the whole foe without gathering
its lighter actions into a consecutive burst—the settled interleaving rule remains authoritative.
Resolve multiple pending foes deterministically by descending primary/current position in the
working schedule, with stable foe ID breaking equal-position diagnostics. A slot already last stays
last; another slot belonging to the same foe may still move. Adjacent staggered foes may interact
through successive swaps, but no individual slot moves twice for its own receipt.

Consume the receipt when that round schedule freezes, even when the target was already last. Death
before application removes it. Stagger never skips an action, creates debt, interrupts the current
block or alters an already-frozen current-round cursor. A newly landed Stagger during its displaced
round may schedule the following round normally.

Ordinary combat must make that control legible without requiring the DEBUG order sheet. The first
successful receipt logs **“<foe> loses footing · later in round <N>.”** A refresh or provenance merge
does not add another ordinary line. When round <N>'s schedule freezes, log **“<foe> falls one place
later.”** if at least one owned slot moved, or **“<foe> has no later opening.”** only if none could
move. If the foe dies before the boundary, remove the receipt silently because the defeat already
supplies the visible result. These are receipt facts, not a prediction of the eventual neighbour or
exact position.

Preview can state the 30% branch or guaranteed Breaking Blow result and show an already-pending round;
it cannot promise the final position before deaths/Cascade reorder. DEBUG records roll, source,
merge, target round, base/final block positions and attached slots.

Acceptance covers 0.299.../0.300... boundaries, miss/non-Crush/lethal/excluded events, live
zero-turn Ambush→next round with no current-cursor mutation,
mid-round→next round, repeat success/failed refresh, Breaking Blow first/later hit and RNG consumption,
one/multiple/adjacent/last foes, Cascade composition, death before boundary, preserved interleaving
and exact apex/pressure slot payloads, no skip/duplicate action, reschedule in displaced round,
save/relaunch before hit/before boundary/after schedule freeze, exact ordinary
success/move/already-last log behavior, and
disabled/empty-v2 parity.

#### Footwork contained checkpoint

**Current production defects:** `performFoeTurn` calls the legacy evasion helper without its active
encounter, so the existing `dodging` guarantee and Ghost's round-one check are bypassed on the actual
foe attack path. Even if the encounter were passed, `dodging` is a round clock rather than a consumed
next-attack receipt, Ghost returns true for every eligible round-one attack instead of exactly one,
and area/multi delivery currently calls personal evasion once per target despite being excluded.
This checkpoint must replace that call with the shared final-target miss resolver; adding Footwork
beside the broken helper is not completion.

Footwork enters the one authoritative **foe-to-party direct-attack miss calculation**. Encounter
entry freezes each participating person's character-evasion contribution and exact `footwork` +6
percentage-point component. Active Base edits or DEBUG ownership changes cannot alter those values
mid-fight. The calculation adds eligible temporary encounter components later (Feint, Untouchable and
Low Profile's opening window), then clamps the final probability once at 85%.

For each otherwise legal single-target direct attack, resolve target replacement first. On the final
target, consume Sidestep and then Ghost guaranteed-miss receipts before probability; either guaranteed
miss uses no RNG. Otherwise consume exactly one saved encounter RNG roll against the shared final
chance. A miss deals no damage, lands no affliction and cannot trigger landed-hit consequences.
Illegal targets, area/multi-target attacks, status ticks and environmental harm neither roll against
nor consume Footwork. Party attacks do not borrow it as accuracy.

At contact, adapt existing legacy Ghost ownership into one saved unspent receipt per exact owner;
later Base/loadout edits cannot create or remove it mid-fight. Existing Sidestep/Dodge activation
arms one exact-owner receipt and successful use consumes it immediately; time passing alone does not
spend it, and reactivation replaces rather than stacks. Tolerant adoption of an old active encounter
may derive an unspent Ghost once only when the legacy owner is present and no modern receipt exists.

Before contact or outside an encounter, UI may disclose the selected party member's personal base +
Footwork chance but cannot predict temporary buffs, target replacement or the future RNG result. The
encounter DEBUG breakdown names all currently applicable additive components and the one final clamp;
ordinary combat presents only the resulting miss/hit event.

Acceptance covers Footwork positive/counterfactual rolls on Binder and companion, no aura in a
five-person party, 85% clamping, final-target redirection, Sidestep→Ghost→probability precedence with
no consumed RNG on guaranteed misses, affliction suppression, excluded event kinds, deterministic
save/relaunch, post-entry ownership changes and disabled/empty-v2 parity.

#### Insulation contained checkpoint

Insulation is a typed permanent choice plus one incoming-harm multiplier. Its DEBUG consumer must
accept an explicit Heat/Caustic/Light choice; release purchase later uses the same atomic selector.
Cancel spends nothing and creates no owner. Encounter entry freezes the exact owner's choice and
stable-node provenance. It is personal, never inferred from equipment colour or a foe's affliction,
and never becomes a party resistance.

For matching typed `Harm.emanation`, multiply raw harm by **0.65**. Matching Ward, worn insulation
and other continuous harm multipliers compose multiplicatively against the same raw integer, then
round down once before legal armour. Preserve the event's declared minimum-damage policy afterward.
Nonmatching emanation and every physical `Harm.blow` remain unchanged. Burn, Poison, Dazzle and Bleed
ticks are afflictions rather than emanation harm and do not inherit Insulation merely from their
producer's element. A carried affliction is prevented only when the landed hit itself misses; reducing
its damage does not erase its payload.

Acceptance covers all three choices, matching/nonmatching/physical/status/environment boundaries,
Ward and worn-insulation multiplication with one rounding point, later Immovable armour composition,
no aura, atomic cancel/replace-through-respec only, preview=commit, save/relaunch, post-entry harness
changes and tolerant missing/unknown-choice adoption without silently defaulting to Heat.

#### Attunement contained checkpoint

Do not activate Attunement against only a convenient subset and call the node complete. It adds +3
raw pre-matchup damage exactly once to two explicitly tagged attack families:

- canonical `emanation_strike`, for each selected Heat/Caustic/Light form; and
- a future real **combat attack** whose source type is Channelworks.

The existing Base `conduit_fixture` treasure/crafting receipt is not an attack and cannot satisfy the
second family. Until a playable Channelworks combat action exists, Attunement remains specified but
inactive even if the derivation helper reports `+3`. When both consumers exist, each emits the same
typed direct-hit context with an `attunementEligible` source tag; ordinary weapon attacks, Emanant
carried afflictions, Conduction copies, status ticks and world/station crafting never receive it.
Preview and commit sum the component once before matchup, as required by the direct-damage order.

Acceptance covers each of the two positive source families, all three Emanation Strike choices,
ordinary physical and carried/status counterfactuals, +3 before matchup exactly once, five-person
personal ownership/no aura, preview=commit, save/relaunch and disabled/empty-v2 parity.

#### Immovable contained checkpoint

Immovable changes **armour scope**, not resistance or immunity. In the one incoming-harm pipeline,
the exact owner treats Pierce's partial armour ignore as zero and permits their combined legal armour
against Heat, Caustic and Light emanation harm, which otherwise bypasses armour. Crush and Rend already
use ordinary armour and receive no extra value. Matching/nonmatching Ward and Insulation still apply
before armour; status ticks remain afflictions and receive no armour.

Immovable grants armour scope only. The live emanation branch does not use Back-rank raw-damage
protection, so its armour application must not borrow that extra multiplier from a physical helper.
Current saved rank still determines Bulwark/Shieldwall eligibility; it does not separately reduce
emanation raw damage. After continuous multipliers round once, subtract the final receiver's one
effective armour value and preserve the global minimum direct damage.

Freeze ownership with the encounter's other personal armour inputs. The final target after
redirection owns the rule; another party member's Immovable never follows the hit. DEBUG breakdown
labels `armour scope · Immovable` separately from armour points so UI cannot misstate it as +armour.

Acceptance covers Pierce partial-ignore removal, all three emanation harms, unchanged Crush/Rend,
affliction exclusion, zero-armour counterfactual, Insulation/Ward composition, Iron Skin/Bulwark/
Shieldwall armour sources, redirection, no aura, preview=commit, save/relaunch, post-entry harness
changes and disabled/empty-v2 parity.

#### Evasion-state checkpoint — Sidestep, Ghost, Feint and Untouchable

After final target replacement, every otherwise legal single-target direct hostile event writes one
targeted-attack receipt. Resolve its avoidance exactly once:

1. if the final target has an armed **Sidestep**, consume it and mark a guaranteed miss without RNG;
2. otherwise, if that target owns **Ghost** and its once-per-encounter charge is unspent, spend it and
   mark a guaranteed miss without RNG;
3. otherwise add character evasion + Footwork + active Feint + Untouchable stack + eligible Low
   Profile opening bonus, clamp once at 85%, and consume one saved encounter RNG roll.

Area, multi-target, environment and status events create no targeted-attack receipt and consume none
of these effects. A guaranteed/probability miss deals no damage, applies no affliction, spends no
prepared hit coating/Envenom charge and triggers no landed-hit consequence. Interpose replacement
happens first, so only the interposer's avoidance state is eligible.

Sidestep is a targeted-self normal-cost technique that arms one saved receipt until used or encounter
end. Re-activation replaces rather than stacks. Ghost is personal passive state frozen at encounter
entry; Sidestep deliberately spends first so a prepared active defense is not hidden behind the
automatic reserve. A stale/illegal event consumes neither. Both are spent by the redirected attack
attempt even though it misses.

**Feint** activates +10 percentage points after its owner completes any committed direct attack,
whether that attack landed or missed. A multi-hit action activates it once after the full action. It
remains active through reactions and hostile events until that actor completes their next normal-cost
action, then expires after all consequences from that action resolve. Zero-turn setup/opening actions
do not expire it; if one is itself a committed direct attack such as Ambush, it may activate Feint.
A later direct attack refreshes the same receipt's expiry to the following normal action rather than
stacking another +10.

**Untouchable** stores 0/5/10/15/20 personal percentage points plus per-round `targetedDirectCount`
and `landedDirectCount`. Each otherwise legal direct attack against the final target increments the
first; a landed one increments the second and immediately resets the stack to zero. At the one saved
ordinary round boundary, if targeted > 0 and landed == 0, increase by 5 to maximum 20; if no direct
attack targeted them, retain the existing stack without growth. Then clear the round counters.
Guaranteed Sidestep/Ghost misses and probability misses count as targeted/no-land; area/status events
do not. Forced opening attacks occur before ordinary round 1 and use a separate opening bucket: they
may reset an existing migrated stack but do not grant a +5 boundary before round 1 begins.

Feint and Untouchable may coexist and add once. Low Profile contributes only during real forced foe
opening actions; Footwork is persistent. Dazzle/attacker accuracy remains on the attacker's side of
the same final hit calculation, not another evasion roll. DEBUG shows components, cap, guaranteed
source, roll and round counters; ordinary UI needs only visible active buffs and miss events.

Acceptance covers Sidestep→Ghost→RNG order, rearm/no-stack, Interpose, illegal/excluded events and
coating preservation; Ghost first/second attack and five-person no-aura; Feint hit/miss/multi-hit,
Ambush, retaliation window, zero-turn setup, next normal action expiry and refresh; Untouchable no
target/all miss/hit-after-miss/miss-after-hit, opening bucket, +5 increments/cap/reset, area/status;
all additive components and 85% cap, one/no RNG, save/relaunch at every receipt boundary, and
disabled/empty-v2 parity.

### 2. Direct-hit context

Every weapon/technique strike creates one typed context carrying actor, target, direct/carried/status
provenance, damage/delivery kind, rank held/moved, covering/armour before hit, concealment transition,
personal-turn receipt and retaliation permission. It owns:

- Follow Through, Bracing Stance, Weak Point, Steady Hand and Exploit;
- Breaking Blow, Killing Stroke and Feint;
- Tainted Edge, Sparkhand, Opportunist and Emanant;
- First Strike's `allowsRetaliation = false` exception.

Preview calls the same pure calculation with RNG ranges rather than claiming a critical roll.

#### Conditional raw-damage checkpoint — Follow Through, Bracing Stance, Weak Point, Exploit

Activate these four deterministic +raw components together because they share one pre-matchup
direct-hit snapshot, while retaining separate stable-node provenance:

- **Follow Through +3** reads the selected foe's current armour immediately before this hit. The
  threshold is `>= 8`; Shatter or another earlier event may legitimately turn it off for a later hit.
- **Bracing Stance +3** reads a saved per-actor `rankAtPreviousCompletedAction`. Encounter entry
  initializes it to entry rank. Any actual rank change, including zero-turn Fall Back, makes the next
  completed direct attack ineligible; completing that action records the new rank, so a later action
  may qualify again. Carried/status events and zero-turn setup do not update the receipt.
- **Weak Point +3** reads the target's current covering density `>= 50`, not armour, insulation or an
  icon/name inference.
- **Exploit +4** reads a Burn, Poison, Dazzle or canonical/legacy-adopted Bleed already present on the
  target before the direct hit. An affliction applied by this same hit is too late; emanation without
  one of those afflictions is insufficient.

One typed snapshot enters the existing direct-damage resolver before matchup. Components sum once;
having all four may legitimately grant +13 when every independent condition is true. Ordinary attacks
and direct techniques are eligible unless their typed action explicitly declares a different damage
path. Carried/Flurry/Conduction/status/environmental damage cannot recalculate or inherit the source
hit's conditional bonuses.

Preview uses the same snapshot. Armour, visible afflictions and the actor's own rank history may be
named directly. Weak Point must not reveal unidentified covering: when covering density is not
disclosed, preview presents the bounded branch (`current total; +3 if Weak Point's covering condition
is met`) without saying whether it is active or folding the secret branch into one exact promised
number. Once knowledge rules disclose covering, the exact active/inactive component may appear.

Acceptance covers every threshold immediately below/at/above its boundary; all-four +13; Shatter
turning Follow Through off; encounter-entry hold, Fall Back and subsequent held-rank recovery;
pre-existing versus same-hit affliction; emanation-only counterfactual; unknown/known covering preview;
carried-event exclusion; preview=commit given the same disclosed snapshot; save/relaunch; stable actor/
target identity; and disabled/empty-v2 parity.

#### Targeted attack-technique checkpoint — Pry, Finish and Flense

All three require one living legal disclosed foe and consume one normal action/cooldown only after
the target and frozen preview fingerprint validate. Cancel, stale target, changed reach or a target
that passed out before commit changes nothing.

**Pry** is a landed direct physical weapon technique with authored raw power 7 and declared Pierce.
It uses the actor's frozen weapon reach but ignores all current armour for its damage event; it does
not destroy armour. Keen Eye and other eligible direct-hit components enter once, Breaking Blow adds
nothing because the kind is Pierce, and ordinary landed physical-weapon payloads/coatings may apply.
It can miss, trigger retaliation and feed Flurry/Killing Stroke like another direct hit.

**Finish** is a landed direct physical weapon technique with declared Pierce. Read the selected foe's
current HP against its frozen maximum at commit using integer cross-multiplication. At or below 35%
it uses raw power 14; above 35% it uses `floor(14/3) = 4`. The preview names the exact branch when HP
is disclosed and shows both bounded branches if not; it never calls the high-HP branch a failed
action. After branch selection it uses the ordinary direct-hit pipeline, including reach, avoidance,
Keen Eye/conditional components, armour, physical-weapon payloads, retaliation, consequences and the
later Killing Stroke check. Finish does not itself execute or bypass apex rules.

**Flense** is a targeted affliction technique, not a direct weapon hit. Derive Bleed tick damage as
`max(1, round(9 × covering insulation / 100))`, where covering insulation is the creature model's
length×coverage result, and author three ticks. Submit that one source-attributed Bleed through
Virulence, Constitution, Stonebark and canonical max refresh. It deals no immediate direct damage,
does not test armour/reach matchup after target legality, consume a coating/Envenom charge, retaliate
or trigger direct-hit consequences. Known covering gives an exact preview; undisclosed covering gives
a bounded “depends on covering” preview without leaking the generated value. A visibly stronger
existing Bleed can be identified as no strengthening before confirmation; stale status changes fail
the fingerprint rather than consuming the action under an obsolete preview.

Shatter remains outside this checkpoint because live code performs only a four-point armour mutation
while the current Effect copy, declared Crush kind and graph synergy say it strikes. The recommended
landed-hit correction is in `combat-tree-shatter-effect-review-current.md`; do not choose either
behavior implicitly during this slice.

Acceptance covers Pry armour 0/high/ignored, Pierce ownership, payloads, miss/retaliation and carried
consequences; Finish HP integer boundary below/at/above 35%, hidden/disclosed preview, direct pipeline,
Killing Stroke and apex; Flense insulation 0/threshold/100, rounding, canonical application outcomes,
all protections/modifiers, no direct-hit side effects and hidden preview; plus actor/target reorder,
cooldown, relaunch, DEBUG provenance and disabled/empty-v2 parity.

#### Steady Hand contained checkpoint

Steady Hand gives its exact owner a **12% critical roll on each landed direct attack**. Resolve target
legality/replacement and avoidance first; a miss consumes no critical RNG. After base power and all
pre-matchup integer bonuses are known, apply matchup/reach/rank and round once, then consume one saved
encounter RNG roll. On success multiply that matched integer by 1.5 and round once before armour.
Armour ignore, minimum damage, HP loss and consequences follow ordinarily.

Ordinary weapon attacks and explicitly direct techniques are eligible. Carried, copied, splash,
status and environmental events neither roll nor inherit the source hit's critical. Each distinct
direct hit in a genuine multi-hit action rolls once; action-expansion credits do not share or promise
a result. Critical state is event provenance, never a lasting actor buff.

Preview uses the same lower/upper base-roll and deterministic arithmetic twice: ordinary branch and
clearly labelled **12% critical** branch. It never advances RNG or collapses those branches into an
average/promised value. Committed log and DEBUG receipt record the roll outcome and `steady_hand`
provenance without exposing future rolls.

Acceptance covers exact failure/success RNG boundaries, miss-without-critical-draw, direct technique,
multi-hit independence, carried/status exclusions, post-matchup/pre-armour rounding, full/partial
armour ignore composition, preview arithmetic parity, save/relaunch and disabled/empty-v2 parity.

#### Breaking Blow contained checkpoint

Breaking Blow modifies only its owner's **landed direct Crush hits**. Those hits use full armour
ignore in the one direct-damage context; this replaces rather than adds to any partial-ignore field.
The first eligible landed Crush hit in each saved personal-turn window also creates or refreshes one
automatic Stagger receipt without a 30% roll. Later hits in that same window still ignore armour but
do not delay again. Misses, non-Crush attacks and carried/splash/status damage consume nothing.

A fresh scheduled personal turn opens one window. Quicken or Blur's multiple normal-cost actions
remain inside that same window. A separately classified pre-contact opening attack has its own single
opening window; it cannot preserve an unused automatic Stagger into the actor's first scheduled turn.
The receipt closes when that window completes and survives save/relaunch. Automatic Stagger follows
the same one pending-next-round, per-saved-slot movement and refresh-not-stack rules as ordinary
Stagger; it preserves the settled interleaving and exact payload of apex/pressure follow-ups.

Preview may state full armour ignore and whether the current disclosed window still has its automatic
Stagger available, but cannot promise later initiative topology after deaths/reorders. Acceptance
covers first/second hit, miss then hit, wrong kind, opening versus scheduled window, Quicken/Blur,
ordinary Stagger refresh, apex turn block, carried exclusion, save/relaunch, and preview=commit.

#### Killing Stroke contained checkpoint

Killing Stroke evaluates only after its owner deals positive damage with a landed **direct hit** and
the target survives that hit. Compare the target's resulting current HP to 15% of its frozen maximum
with integer cross-multiplication (`currentHP × 100 <= maxHP × 15`), avoiding floating-point or rounded
display thresholds.

- A qualifying non-apex target is defeated immediately and emits one defeat transition.
- A qualifying apex instead loses exactly **4 additional HP**. This is a bounded post-hit consequence,
  not another attack: it does not reroll, reapply matchup/critical/armour, carry afflictions or trigger
  on-hit nodes. If that +4 reaches zero, the ordinary defeat transition follows.
- An apex above 15% receives no bonus. “Instead” replaces only the percentage execute at the same
  threshold; it is not +4 on every apex hit.

Carried, Flurry/Conduction, status and environmental damage cannot invoke Killing Stroke even when
credited to the owner. A target already reduced to zero by the direct hit produces no second event.
Preview uses the same post-hit candidates: if the base-roll range crosses the threshold it shows
separate possible branches rather than promising execution/+4. Hidden apex identity is never leaked;
the apex branch appears only when that classification is legitimately disclosed.

Acceptance covers integer boundary below/at/above 15%, ordinary immediate defeat, apex +4 and +4
defeat, apex above threshold, already-defeated target, carried/status exclusions, one defeat receipt,
preview range crossing, concealed/disclosed apex identity, save/relaunch and disabled/empty-v2 parity.

### 3. Non-recursive consequence queue

Resolve direct hit first, then enqueue secondary consequences with explicit provenance. Carried or
copied consequences cannot enqueue themselves:

- Stagger, Flurry and Cascade;
- Second Wind and Rally;
- Virulence, Corrode, Blight and Conduction;
- Anatomy at the one expedition-level butchery receipt rather than per hit.

Stable foe/party order breaks documented ties. Each queue event identifies its contributing node in
DEBUG telemetry.

#### Defeat consequence checkpoint — Second Wind, Rally and Cascade

Create one exact `DefeatTransition` whenever a living foe first reaches zero. It records foe stable
ID, the final damage event, and an optional stable party source actor. The source comes from event
provenance, not the currently selected combatant: direct hits, Killing Stroke's bounded apex
consequence, Flurry/Conduction carried damage and an affliction tick retain the actor who authored
them. Source-unknown migrated afflictions, environment harm and scripted removal have no party
source. A foe already at zero can never emit a second transition or another reward.

After the entire final damage event has settled, enqueue the exact source owner's defeat nodes in
stable node order:

- **Second Wind:** restore 3 HP to that owner, capped by the frozen expedition maximum. If they are
  already passed out, it restores nothing and never revives them.
- **Rally:** restore 2 HP to every *other* conscious expedition participant, each capped by their
  frozen maximum. It never heals the source and never revives a passed-out ally.
- **Cascade:** add one saved +3 initiative stack to that owner for the rest of the encounter, maximum
  three stacks. Additional defeats after three retain ordinary reward/credit but add no stack.

One event that defeats several foes creates one transition per foe in stable foe order. Therefore
Second Wind and Rally may heal once per actual foe defeated and Cascade may gain several stacks,
subject to its cap. Carried or affliction damage may earn these defeat consequences, but the healing
and initiative consequences are terminal: they cannot themselves deal damage, emit defeat credit or
re-enter this queue. Multiple actors never share one defeat.

Cascade reuses the authoritative initiative receipt and stable reorder operation. Drain all
consequences from the current damage event, update the owner's saved component, then reorder only
the unresolved ordinary slot belonging to that party owner. The currently resolving action always
completes; a slot already completed this round stays completed; an unacted owner may move among the
remaining slots; and no initiative crossing grants, skips or repeats an action. A defeat after the
owner has acted affects later rounds only. Existing apex/pressure follow-up slots keep their saved
interleaved positions and exact payload; Cascade never gathers or moves those foe slots.

Ordinary presentation may name the healing and a visible order change after it occurs. DEBUG records
the source event, foe, node, pre/post HP, Cascade stack count and resulting order. It never predicts
future defeats. All health operations use the Thick Hide expedition cap receipt; do not implement
this group against the old tuning-constant maxima.

Acceptance covers each node alone and all three together; direct, Killing Stroke, carried and
actor-owned affliction defeats; source-unknown/environment exclusions; already-zero idempotence;
one event defeating two or more foes; owner/ally full, wounded and passed-out states; exact maximum
clamping; Cascade stacks 0–3 and over-cap defeats; owner before/current/after the order cursor;
unchanged interleaved apex/pressure follow-ups; no repeated/skipped action; save/relaunch with
delayed affliction and Cascade stacks; five-member stable order; and
disabled/empty-v2 parity.

#### Carried-damage checkpoint — Flurry and Conduction

Both nodes consume the final **HP actually lost** to one landed direct hit:
`primaryHPBefore - primaryHPAfter`. Overkill is therefore excluded. If that value is zero, no carried
event exists. The carried amount is `max(1, floor(actualLoss × fraction))`: 40% for Flurry and 50%
for Conduction.

This is one terminal damage event with the original actor as source. It does not reroll base damage,
critical or avoidance; reapply matchup, reach, rank or armour; inherit armour ignore; carry the
source weapon's coating; or activate direct-hit/on-hit nodes. It subtracts its frozen amount from the
secondary target, clamped at zero. It may create one ordinary source-attributed `DefeatTransition`
under Decision260 because reaching zero is an outcome, not another on-hit proc. Its `carried`
provenance prevents Flurry, Conduction, Killing Stroke, Weak Point, Exploit and every other direct-hit
consumer from reading it recursively.

The two target rules remain distinct:

- **Flurry** chooses the first other living foe in stable foe order that would be a legal target for
  the actor's same direct attack at that moment, including its reach/rank and disclosed targeting
  restrictions. It is weapon follow-through, not a range bypass.
- **Conduction** chooses the first other living disclosed foe in stable foe order, regardless of the
  actor's physical reach. It is an emanation jump, but cannot select a hidden/nonparticipant target
  or leak its identity through preview.

If no eligible secondary exists, the node consumes nothing and creates no placeholder receipt. A
genuine multi-hit action evaluates after each landed direct hit against the then-current living
cast; each hit may carry once, but a carried event never becomes another source hit.

Conduction additionally copies the direct emanation hit's matching Burn/Poison/Dazzle payload. Start
from the primary application's authored pre-target duration after the source actor's Virulence, halve
that duration rounding up with minimum one, retain the original per-tick damage and source actor,
then pass the copy through the secondary target's Stonebark and Constitution exactly once. The first
target's Constitution does not shorten the source duration used for the second. Mark the application
`copied`: Virulence and Conduction cannot extend/copy it again, while Corrode may later recognize its
real actor-owned Poison ticks. The carried HP damage still lands if Stonebark prevents only the copied
affliction.

Preview shows an exact secondary only when target legality/order and identity are disclosed;
otherwise it states the bounded carried amount and “another eligible foe.” It never advances RNG or
reveals a hidden foe. DEBUG records primary actual loss, fraction/rounding, secondary stable ID,
carried amount and copied-affliction derivation.

Acceptance covers source losses 0/1/2/3/5/large and overkill; Flurry versus reach/rank legality;
Conduction reach bypass and hidden-target exclusion; no secondary; primary/secondary death;
Decision260 defeat credit; multi-hit reevaluation; critical/armour/matchup non-reapplication;
coating/on-hit/execute exclusions; Heat/Caustic/Light copy; odd/even duration, Virulence then half,
each target's Constitution, Stonebark, Corrode eligibility; stable order; no recursion; preview
disclosure; save/relaunch; and disabled/empty-v2 parity.

#### Venom-affliction checkpoint — Virulence, Corrode and Blight

This checkpoint lands only on the canonical exact-combatant affliction collection in
`combat-affliction-authority-current.md`; it must not add another poison dictionary or adapt the
shared legacy Bleed counters as new authority. Each application carries target, source actor,
provenance, damage, authored pre-target ticks and one stable application receipt.

**Virulence** adds +2 authored ticks when its exact owner directly applies Burn, Poison, Dazzle or
Bleed through a landed action. Eligible provenance is `direct` or `coating` with that actor as source,
including Tainted Edge, Sparkhand, Emanant, Envenom, Emanation Strike and a prepared coating.
`copied`, retaliation, environment and migrated-unknown applications are ineligible. Add the two
ticks before the target's Constitution and before canonical same-kind max refresh. It modifies only
the prospective application, never a pre-existing row merely because its owner later acts.

Canonical application returns a typed outcome: prevented, no-op, added, damage-strengthened,
duration-strengthened or both-strengthened. **Blight** listens only to an added/strengthened Poison
outcome directly authored by its owner. If Stonebark prevented the primary application or max refresh
changed nothing, Blight does not fire. Starting from that prospective post-Virulence,
pre-Constitution payload—not the target's older merged Poison—copy half damage and half ticks,
rounding each up with minimum one, to the first other living disclosed foe in stable order. The copy
retains the actor as tick source, then passes through the secondary's Stonebark, Constitution and
same-kind max refresh. Its `copied` provenance prevents Virulence, Blight and Conduction from
expanding it again. No eligible second foe means no copy.

**Corrode** listens to a completed canonical Poison boundary tick whose retained tick-damage source
is its exact owner. If the target remains living, add one saved encounter armour-erosion point for
that target, capped so its personal/equipment armour floor is zero. Apply the erosion after that
Poison tick; it affects later incoming-hit armour calculations and never changes the tick that caused
it. The receipt key `(source actor, target, global round)` permits at most one erosion from that actor
to that target in the round even if migrated/copy edge cases expose more than one Poison event.
Another Corrode owner may contribute once through their own genuinely source-owned Poison, but the
canonical max-refresh source rules prevent an equal refresh from stealing credit. Source-unknown
Poison never receives credit. Passing out after application does not erase authored poison or its
Corrode ownership; encounter end clears both poison and erosion.

Armour erosion is a named negative component in the one armour breakdown, not destructive mutation
of frozen foe stats or gear. It applies before the zero floor and before armour-ignore percentage is
used. Preview may show current disclosed erosion but cannot predict future ticks or hidden source
ownership. DEBUG exposes exact application outcome, source/provenance, Virulence ticks, Blight copy
derivation, Corrode round key and pre/post armour.

Acceptance covers all four Virulence afflictions and every eligible/ineligible provenance; ordering
against Constitution, Stonebark and max refresh; new/stronger/no-op/prevented Poison; Blight damage/
tick odd rounding, old-stronger-row counterfactual, secondary prevention/no-op, stable-order/no-target
and non-recursion; Corrode first/repeated tick, two source actors, equal refresh source retention,
source-unknown migration, living/dead target, armour floor/ignore composition, owner pass-out,
round-boundary idempotence, save/relaunch and disabled/empty-v2 parity.

### 4. Mitigation, targeting and survival

Use one incoming-harm pipeline: legal target → redirection → miss/avoidance → matchup/Ward → armour
→ reduction → minimum damage → affliction payload → survival receipt. It owns:

- Constitution, Endurance, Unyielding and Ghost;
- Cover and Guardian;
- Brace, Ward, Sidestep, Draw Off and Interpose;
- Conceal, Snuff and Quench.

Within redirection, full Interpose target replacement resolves before avoidance and prevents Cover
on that hit. Cover is a post-mitigation split of one landed single-target direct hit and never runs
the redirected share through mitigation again. Sidestep is consumed before Ghost on the actor who
actually receives the hit. Area, multi-target, environmental and status events use their declared
non-redirectable paths rather than accidentally consuming single-hit protections once per target.

Area/environment/status events declare which stages they bypass. Redirection never recurses and a
miss never lands an affliction.

#### Active mitigation and control checkpoint — Brace, Ward, Snuff and Quench

These four techniques replace live duration-shaped placeholders with typed saved receipts. They
share selection and transaction rules: release requires an explicit legal target or choice; cancel,
an invalid target and a stale preview spend neither the action nor cooldown; preview and commit use
the same rules-owned receipt. A migrated encounter remains on its frozen legacy rules version until
it ends rather than guessing which old effects should already have expired or been consumed.

**Brace** arms one personal receipt until the next hostile action slot that lands positive direct
damage on its owner, or encounter end. After final target replacement and avoidance, every direct
damage event to that owner belonging to the same hostile slot receives the 35% Brace reduction.
Combine Brace and an eligible Endurance multiplier against the post-armour integer, round down once,
then preserve the declared minimum direct damage. Mark the receipt triggered on the first qualifying
event but consume it only when the complete slot—including authored multi-hit/area shares—finishes.
An illegal action, miss, another target, or a non-damaging event leaves it armed. Affliction ticks,
environment damage, voluntary costs and Cover's already-resolved share neither benefit nor consume
it. A relaunch between events retains the triggered slot identity so it cannot gain a second
protected slot or vanish halfway through the first.

**Ward** requires the owner to choose exactly one currently disclosed harm kind: Crush, Pierce,
Rend, Heat, Caustic or Light. It never silently chooses `mostCommonIncoming`. A committed Ward
reduces matching incoming direct harm by **60%** through the remainder of its activation round and
the entirety of the following ordinary round; the receipt expires at that following round's end.
Recasting replaces kind and expiry rather than stacking. Matching Ward, Insulation, worn insulation
and other raw-harm multipliers compose multiplicatively, round once, and then pass to the one legal
armour calculation; Brace/Endurance remain later post-armour reductions. Ward does not reduce an
existing Burn, Poison, Dazzle or Bleed tick merely because that affliction originated from the chosen
kind, and it does not infer or reveal an undisclosed foe profile. A direct multi-target/area event may
apply Ward independently to the owner when it carries the matching typed harm.

**Snuff** targets one living disclosed foe with an active Heat, Caustic or Light emanation and stores
`remainingScheduledTurns: 2` against its stable encounter instance. At the start of each complete
hostile action block for that foe, freeze whether Snuff applies; while it does, the primary and every
attached ordinary/apex follow-up use the foe's underlying physical Crush/Pierce/Rend profile. This
removes emanation reach/bypass and its new Burn/Poison/Dazzle payload, but neither changes the foe's
permanent identity nor removes afflictions already carried by anybody. Decrement once only after the
whole block resolves. Relaunch between slots preserves the frozen suppressed block. Refresh below
two turns replaces the count with two; it never stacks, and using it at a full two turns is an
invalid no-op. Defeat or encounter end discards the receipt. Presentation may show that the known
emanation is suppressed without concealing the known creature identity or claiming it permanently
lost that trait.

**Quench** uses the new stable `quench` technique, selects one conscious ally or self, then selects
exactly one Burn, Poison or Dazzle currently carried by that target. It removes that canonical row
only. Bleed, Ground and every unselected affliction remain; no fallback chooses the first dictionary
entry. When exactly one eligible row exists the UI may preselect it but must still name the removal
before commit. Migrate cooldown, gambit and saved-action references originating from the sole old
`steady` node one way to `quench`; release content never exposes `steady`, and the old broad-cleanse
implementation is not retained as an alias.

Acceptance covers Brace single/multi-event slots, misses/other targets/status/environment, Cover,
Endurance arithmetic, minimum damage and mid-slot relaunch; Ward all six choices, cancel/stale,
matching/nonmatching direct/affliction events, activation timing, replacement, Insulation/armour/
Brace composition and hidden-information exclusion; Snuff all three emanations, physical fallback,
reach, primary/follow-up/apex blocks, existing afflictions, full/partial refresh, defeat and mid-block
relaunch; Quench every eligible choice and pair, Bleed/Ground preservation, conscious targeting,
cancel/stale and one-way `steady` migration; plus exact ownership in a five-person party, cooldown
commit, DEBUG receipts, phone selection flow and disabled/empty-v2 parity.

#### Survival checkpoint — Constitution, Endurance and Unyielding

These are personal frozen-owner effects in one incoming-consequence pipeline; none is a party aura.
They share the Thick Hide expedition maximum and canonical affliction collection rather than reading
Base loadout or legacy tuning maxima during an active run.

**Constitution** modifies only a prospective affliction application to its exact owner. After the
producer and source-owner bonuses such as Virulence establish authored ticks, halve them rounding up
with minimum one, then submit that payload to Stonebark and canonical same-kind max refresh. It makes
no resistance roll, changes no tick damage, does not halve an existing row in place and cannot reduce
an endless sentinel. A reapplication may therefore be a no-op against a longer existing duration.
Burn, Poison, Dazzle and Bleed are eligible; Ground and other beneficial/prepared states are not.

**Endurance** reads the conscious target's current HP **before** the incoming damage event. It is
active when `currentHP × 2 <= frozenMaximumHP`. After legal matchup, resistance, armour, redirection
and other event-specific mitigation produces a positive integer, Endurance replaces it with
`max(eventMinimum, floor(value × 0.75))`. The hit that first crosses the half-health line is not
reduced; the next event is. It applies to hostile direct, carried, affliction and environmental HP
damage, but not voluntary costs or loss already assigned to another ally before a Cover split.
Cover's redirected share is not mitigated again, so the covering actor's Endurance cannot process it.

**Unyielding** evaluates after the final damage integer is known. The first event in an encounter
that would reduce a conscious exact owner below 1 instead sets them to 1 and records one spent stable
node receipt. It does not turn the event into a displayed zero, cancel landed-hit consequences,
prevent an affliction application, refund a consumable/turn or erase damage credit. A later damage
event—even a second event from the same action or the next boundary status tick—may pass them out.
A passed-out owner cannot trigger it retroactively, and healing above zero never restores the charge.
Encounter end clears the receipt.

When both apply, Endurance reduces the integer first and Unyielding checks the result. Logs show each
only when it changed the outcome. DEBUG adds stable-node provenance and pre/post values. Preview may
show deterministic Endurance and an available/spent Unyielding branch, but never promises future HP.

Acceptance covers Constitution odd/even/one/endless durations, all four afflictions, Virulence order,
Stonebark and max-refresh no-op; Endurance immediately above/at/below half, crossing hit versus next
event, minimums, direct/carried/status/environment, Cover and voluntary-cost exclusion; Unyielding at
exact/lethal/overkill values, landed payload preservation, two damage events in one action, delayed
tick, passed-out owner, heal-after-spend and no recharge; all three together; Binder/companion/no
aura; frozen Thick Hide maximum; save/relaunch before boundary and after spend; and disabled/empty-v2
parity.

#### Target-intent checkpoint — Guardian, Draw Off, Interpose and Cover

Every hostile action slot first creates one typed target intent before any hit roll. Resolve it in
this order:

1. collect living participants and apply concealment/disclosure to ordinary direct targeting;
2. apply the foe action's reach/rank legality;
3. if any conscious front-rank Guardian owner exists and at least one disclosed legal front target
   remains, remove back-rank candidates from **single-target direct** intent;
4. if this foe has a live Draw Off receipt whose exact owner remains conscious, disclosed and inside
   that filtered legal set, choose that owner; otherwise choose by the ordinary foe targeting rule;
5. freeze the intended target and delivery classification for this action slot;
6. for a redirectable single-target direct event, choose one valid Interpose receipt and replace the
   intended target before avoidance and mitigation;
7. after a landed non-Interposed event has been mitigated against its final back-rank target, apply
   at most one eligible Cover split.

Guardian never turns area, multi-target, environment or status delivery into single-target delivery.
It does not expose a concealed front member: if no front member is a legal disclosed target, a
far-reaching foe may still select back. Multiple Guardians add no stronger restriction. A scripted
unredirectable event must carry an explicit delivery flag and disclose that exception; apex identity
or name alone never bypasses Guardian.

Draw Off's saved receipt names `foe stable ID + owner stable PartyMember + expiry`, never Binder or a
roster index by default. Activation requires a living disclosed foe, ends that actor's Conceal and
replaces an older receipt for the same foe visibly. It lasts through the activation round and the
following global round (two boundary ticks), survives relaunch and is checked independently for every
primary/follow-up action slot. It overrides apex target-diversity preference when legal, but cannot
make an out-of-reach/back-rank-under-Guardian/concealed/passed-out owner legal. Multi/area actions keep
their full delivery; Draw Off only supplies their primary/follow-up focus where that concept exists.

Interpose receipts retain activation sequence and stable owner. The oldest valid conscious owner
other than the intended target wins, then stable PartyMember breaks a sequence tie. It may redirect
across ranks because interception happens after foe target legality; it does not move the actor's
rank. Triggering ends the interposer's Conceal and consumes that one receipt immediately, even if
their Sidestep, Ghost or evasion subsequently makes the attack miss—the interception was spent.
The replacement target's Ward, armour, Endurance and Unyielding apply; the original target's do not.
Area, multi-target, environment, status and explicitly unredirectable events neither select nor
consume Interpose. Remaining queued receipts persist until used or encounter end.

Cover is not target replacement. On a landed redirectable single-target direct event whose final
target is a back-rank ally and which was not Interposed, choose the eligible conscious front-rank
Cover owner by highest fraction then stable PartyMember. Mitigate once against the back target, then
split that integer 70/30 using largest remainder; ties award the leftover point to the original
target's share. The Cover share is direct HP loss to its owner without another avoidance, Ward,
armour or Endurance pass; Unyielding may still answer that final lethal HP-loss event because it is a
survival receipt rather than second mitigation. The share cannot trigger another Cover/Interpose and retains the hostile
source for damage logs rather than pretending the covering ally attacked themself. If the split
passes the Cover owner out, the original target's already-frozen share does not change.

DEBUG shows intended target, each filtering/override reason, final target, consumed Interpose and
Cover allocation. Ordinary logs name only observable intervention. Preview can explain a currently
armed receipt but cannot promise a future foe choice or reveal a concealed target.

Acceptance covers melee/far/emanation reach; zero/one/multiple Guardians; concealed front/no legal
front; Draw Off exact companion ownership, replacement, two-round expiry, every apex slot and illegal
fallback; multiple Interposes, tie/order, post-replacement miss and consumption, conceal break,
rank crossing and excluded delivery; Cover integer damage 1–10/tie allocation, multiple owners,
Interpose exclusion, owner pass-out/Unyielding and no second mitigation; all four together; stable-ID reorder;
save/relaunch at activation and between action slots; explicit scripted exception; and disabled/
empty-v2 parity.

### 5. Technique and personal-turn receipts

Techniques remain explicit stable IDs and typed parameters; graph role never implies an action.
This slice owns:

- Overbear, Shatter, Pry and Finish;
- Quicken, First Strike and Blur;
- Fall Back;
- Envenom, Flense and Emanation Strike.

One shared action-expansion receipt prevents Quicken/Blur chaining. One opening-attack receipt
prevents repeated Ambush-style attacks. First Strike spends an ordinary action. Owed/skipped turns,
once-per-encounter use, selections and cooldowns survive relaunch.

Blur is a real explicitly granted `blur` action even though the legacy content has no technique ID
for it. It is not inferred from capstone role or `capstoneBlur`. The other 19 grants and all 52 null
grants are frozen in the registry.

#### Personal-turn expansion checkpoint — Quicken, Blur, Overbear and First Strike

Replace the ambiguous `extraTurns` increment with one saved **personal-turn receipt** per actor. A
fresh scheduled personal block begins with one normal-action credit and one unused setup window.
Pre-contact/opening foe actions are not personal blocks. A zero-turn setup consumes that setup window
without consuming the normal credit; it may grant/rewrite credits exactly once.

**Quicken** is usable only while the actor is conscious at the start of a fresh scheduled block, with
the setup window unused and no active expansion. Activation consumes the setup window, replaces the
single normal credit with exactly two consecutive normal-action credits, starts Quicken's cooldown
and adds one saved skipped-scheduled-block debt. The actor therefore takes **two actions after tapping
Quicken**, not Quicken plus one action. Debt is committed immediately and remains even if the actor
uses only one credit before the encounter ends or they pass out.

**Blur** has the same start/setup/two-credit behavior, but adds no skip debt and records a durable
once-per-encounter spent receipt at activation. Quicken and Blur share the expansion slot: neither can
follow the other in one block, and neither can be activated from an expanded credit.

An expanded normal credit cannot select any zero-turn setup, including Quicken, Blur or Fall Back.
Likewise, using Fall Back or another explicitly classified setup first consumes the block's setup
window and makes Quicken/Blur unavailable for that block. Ambush is a separate pre-contact opening
attack and does not consume a later scheduled setup window. Items and ordinary/direct techniques
remain normal-cost actions unless explicitly classified otherwise.

**Overbear** consumes one normal credit, performs exactly one Crush attack and adds one skipped-block
debt. It grants no hidden attack. Debt stacks honestly: one Overbear used during Quicken produces two
future skipped scheduled blocks total; using Overbear for both expanded credits produces three. A
skipped block is not an action, cannot trigger first-action/turn-start effects and decrements exactly
one debt. The existing `recoveryComplete` gambit fact becomes true only for the first actionable block
after the final stacked debt is paid, then clears after that actor completes one normal action.

**First Strike** is a normal-cost direct weapon action available only until that actor completes their
first normal-cost action of the encounter. Zero-turn Ambush, Quicken, Blur and Fall Back do not spend
this credit; a skipped block does not spend it. First Strike may therefore use the first expanded
credit. It adds +4 raw damage once before matchup, forbids retaliation/counter only for that hit and
grants no action/initiative change. A miss still spends the normal action and first-action credit.

After each normal action, consume one credit. If another remains and the actor is conscious and the
encounter unresolved, keep the same current block; otherwise close it and advance through the saved
schedule. Expanded credits never become separate initiative slots, so Cascade reorder and apex
follow-ups cannot interleave them. Cooldowns/round boundaries advance only when the ordinary global
schedule crosses its boundary, not between an actor's consecutive credits.

Persist block identity, setup-window state, remaining credits, expansion source, Blur spent, stacked
skip debt and first-normal-action completion. A tolerant legacy `extraTurns` value adopts once as
that many compatibility action credits on the current actor without granting Blur/Quicken ownership;
legacy `skippedTurns` remains debt. Encode only the new receipt after normalization. DEBUG shows
`Action 1 of 2`, expansion source and future debt; ordinary UI needs only compact remaining-action and
recovery indicators, not scheduler internals.

Acceptance covers Quicken tap→two actions→one skip; Blur tap→two actions/no skip/once; mutual and
Fall-Back chaining rejection; Ambush then either expansion; First Strike before/after Ambush, as
first expanded action, after a miss and after any other normal action; Overbear outside expansion,
once/twice inside Quicken and stacked recovery-complete timing; pass-out/victory after first credit;
Cascade reorder; round/cooldown boundaries; companion automation/manual override; save/relaunch at
setup, between credits and during stacked debt; legacy extra/debt adoption; and disabled/empty-v2
parity.

#### Active stance and prepared-strike checkpoint — Fall Back, Conceal, Envenom and Emanation Strike

These actions use the same atomic selection contract as the other techniques: validate exact node
ownership, conscious/current actor, personal-block eligibility, cooldown, target/choice and frozen
preview fingerprint before changing state. Cancel, stale choice and illegal target spend no action,
setup window, cooldown or prepared receipt.

**Fall Back** is zero-turn setup available once at the start of a fresh scheduled personal block while
its setup window remains unused. It changes only the exact actor between Front and Back, then consumes
that block's setup window and starts cooldown while preserving the one ordinary action credit. It
cannot be selected from an expanded Quicken/Blur credit or followed by another setup in the same
block. The actual rank change clears Bracing Stance eligibility for the actor's next completed direct
attack and updates target/reach previews immediately; it does not retroactively retarget an action
already resolving. If an authored encounter someday restricts the destination rank, the action is
illegal rather than silently leaving the actor in place.

**Conceal** spends one normal action and stores a personal receipt through the end of the following
ordinary round, guaranteeing a complete hostile schedule in which it can matter regardless of when
the actor moved. While active, ordinary direct intent excludes the owner whenever another living
legal target exists; if none exists, Conceal does not create invulnerability. Area, multi-target,
environment and affliction events remain eligible. Committing a direct attack, Draw Off or an
Interpose replacement ends Conceal immediately before that event resolves. Expiry or one of those
voluntary reveals creates exactly one `emergedOpportunity` for Opportunist through the end of the
owner's next normal-cost action; recasting replaces expiry and never banks another opportunity.

Opportunist adds +5 raw damage to the first landed direct hit made while Conceal is still active or
while that one emerged opportunity remains. A committed direct attack reveals first but retains the
same action's opportunity, so its landed hit may receive the bonus. A miss reveals and leaves the
opportunity available only through the rest of that same normal-cost action; it cannot be saved for a
later turn. Carried, copied, status, environment and retaliation events neither receive nor consume
it. Draw Off/Interpose reveal may carry the opportunity into the owner's next normal action, but the
incoming/interposed hit cannot spend an offensive bonus. Encounter end clears both receipts.

**Envenom** spends one normal action and replaces the exact owner's prepared Envenom state with three
successful-hit charges; activating it at three charges is an invalid no-op rather than a cooldown
waste. Each landed eligible direct physical weapon hit contributes strong Poison `2 damage × 3
authored ticks` to the same-kind merge, then spends one charge even if the hit defeats the target and
therefore cannot leave an affliction row. Misses and nonweapon/carried/copied/status/retaliation
events spend none. Virulence may extend ticks, but never charges. A non-Poison prepared coating may
coexist; prepared Venom is visibly ineligible while any Envenom charge remains. Charges survive
relaunch and end with the encounter.

**Emanation Strike** spends one normal action and explicitly chooses Heat, Caustic or Light before a
target. It is a direct emanation attack with authored raw power 9, plus Attunement when owned, and
uses the actor's currently frozen weapon reach only for target legality; it is not a physical weapon
hit and therefore cannot consume coatings/Envenom or trigger Tainted Edge, Sparkhand or Emanant.
Heat, Caustic and Light respectively carry the canonical Burn `4×2`, Poison `2×4` or Dazzle `0×2`
payload after a landed hit. The direct harm uses the selected typed emanation for Ward, Insulation,
ordinary armour bypass and Immovable; matchup/avoidance still apply. A surviving target receives the
payload through Virulence, Constitution, Stonebark and canonical refresh. Manual use stores the
selected kind as that actor's visible gambit preference only after a legal commit; gambits use the
saved preference and fail closed when missing rather than defaulting to Heat. Migrate the old
`elemental_strike` action/cooldown/preference one way to `emanation_strike`.

Acceptance covers Fall Back both ranks, setup/expansion exclusions, Bracing Stance and immediate
preview; Conceal alternate/no-alternate targets, every delivery family, full hostile schedule,
natural/attack/Draw-Off/Interpose reveal, Opportunist hit/miss/expiry/recast; Envenom 3→2→1→0,
lethal hit, all exclusions, Virulence and coating composition; Emanation Strike all three choices,
raw/status values, Ward/Insulation/Immovable, miss/lethal/Stonebark, Attunement, physical-proc
exclusion, manual/gambit preference and migration; plus actor reorder, cooldown, save/relaunch,
DEBUG receipt, phone selection and disabled/empty-v2 parity.

### 6. Pre-contact field and encounter opening

Freeze the pre-action disclosure/opening authority specified in `combat-node-viability-current.md`.
This slice owns:

- Slippery and Watchful;
- Ambush and Unseen;
- Quiet Step, Low Profile and Shadowed;
- Vanish.

The existing three field-concealment reads migrate into this typed resolver rather than remaining
sign-only checks. Apex/scripted exceptions are explicit and never inferred from creature names.
Quiet Step's negative legacy `encounterChance` payload is migration input only: its consumer is the
persisted deterministic one-alert-turn awareness rule in `field-awareness-avoidance-current.md`, not
a probability roll that silently deletes contact.

Vanish attaches to the confirmed ordinary **combat-retreat** transaction and changes only its
Stability cost once per expedition. It does not end the expedition, bank a haul, create an
`ExpeditionOutcomeID` or enter the Base return-settlement path.

#### Opening-resolution checkpoint — Slippery, Watchful, Low Profile, Ambush and Unseen

Encounter creation freezes one `OpeningResolution` from the pre-contact world receipt and exact
participating stable-node owners. Preserve both `initial` physical classification and `resolved`
classification; later effects never rewrite the facts that caused contact.

For an ordinary roaming encounter whose initial classification is `creatureAmbush`, apply in order:

1. **Slippery:** use one 50% saved-RNG prevention chance if any participant owns it. Copies do not
   stack. On success resolve as `mutualContact`, create no forced foe-opening actions and record the
   roll; on failure retain `creatureAmbush`.
2. **Watchful:** only if the resolved result remains `creatureAmbush` and any participant owns it,
   preserve that classification but create no forced foe-opening actions. Copies do not stack and it
   consumes no RNG.
3. **Unseen:** after classification/order are frozen, each exact owner begins concealed through the
   end of ordinary global round 1. This concealment already applies during any forced foe-opening
   actions but never changes `creatureAmbush` into a safer label.

Without Watchful, a creature ambush queues exactly one forced primary action for each living ordinary
foe in frozen foe order before the ordinary schedule. It does not queue apex/pressure follow-ups,
advance the ordinary turn cursor or create an extra status boundary. A foe removed before its pending
action is skipped idempotently. The ordinary schedule then begins from its saved first slot, so an
ambush is a real enemy opening rather than a reordered first round.

**Low Profile** gives +6 percentage points of evasion only to its exact owner while they are the final
target of one of those frozen forced foe-opening actions. It uses the authoritative miss calculation
and 85% cap after Interpose replacement. It does not apply for the rest of round 1, to ordinary
initiative actions, to party attacks or merely because the opening was initially an ambush but
Slippery/Watchful produced no forced action. Shadowed's stronger field-radius effect does not replace
this personal combat benefit.

**Ambush** uses one shared party opening-attack receipt. It is eligible after `partyApproach` or
`mutualContact`, including a successful Slippery resolution, and for an explicitly allowed scripted
opening. It remains ineligible when the resolved encounter is `creatureAmbush`, including a Watchful
suppression: noticing the attack is not approaching on your terms. A deliberately approached apex
permits it unless that encounter carries an explicit disclosed prohibition.

Any exact owner may spend the shared opportunity before completing their first normal-cost action.
It is a zero-turn free **direct attack**, commits only after a legal target is frozen, and is consumed
even if that attack subsequently misses. Invalid/stale selection changes nothing. It may receive
Opportunist/other direct-hit components and ordinary retaliation; unlike First Strike, it has no
retaliation immunity. It does not consume the later scheduled setup window or first-normal-action
credit, so First Strike or Quicken/Blur may follow legitimately. Once one actor spends it, no other
Ambush/free-opening action may do so.

Unseen is an expiry receipt keyed to completion of ordinary round 1, not a generic duration tick:
forced opening actions neither shorten nor extend it. It follows ordinary conceal targeting, does not
hide area/environment effects and does not suppress the owner's attacks unless another rule says so.
Ordinary scripted/apex revelation may remove it only through an explicit opening flag named in the
log; apex identity alone is not a blanket cancellation.

Scripted openings provide explicit independent flags for Slippery applicability, Watchful suppression,
party opening attack and forced revelation; absent flags fail closed rather than infer from prose or
enemy identity. DEBUG exposes initial/resolved classification, roll, strongest-once owners, pending
actions, Low Profile component, shared opportunity and conceal expiry. Release UI states only
observable opening consequences.

Acceptance covers Slippery success/failure/RNG/relaunch/copies; Watchful alone/after failed Slippery/
after successful Slippery; pending multi-foe order, dead foe, no extra boundary and ordinary cursor;
Low Profile exact owner, Interpose final target, cap and excluded first-round actions; Ambush mutual/
approach/Slippery/Watchful/apex/scripted, multiple owners, legal/stale/miss, retaliation, Opportunist,
First Strike and Quicken/Blur follow-up; Unseen forced actions/round-1 expiry/area/revelation; five-
member stable ownership; scripted flag matrix; disabled/empty-v2 parity.

### 7. Economy and external yield

Rules-owned previews and atomic transactions consume:

- Apothecary's Hand when the trained actor uses a beneficial item;
- Distiller when preparing a coating for that actor;
- Anatomy at butchery payout.

These effects read stable expedition participants/actor identity, not whichever member currently
occupies a legacy roster index. Distiller changes positive world-resource quantities only; it never
discounts Essence or duplicates an output.

#### External-value checkpoint — Anatomy and Apothecary's Hand

**Anatomy** freezes strongest-once expedition participation at departure. For each defeated creature,
roll its ordinary butchery quantity once, then add `max(1, floor(baseQuantity × 0.35))` when base is
positive. Apply that final quantity equally to every material family the creature truthfully yields.
It does not change grade, properties, source, which parts exist, ordinary world-resource loot, gear,
XP or apex rewards. The trained participant need not land the defeat, remain conscious at victory or
perform a separate harvesting action; somebody left at Home contributes nothing. Copies do not
stack. Final samples use the ordinary exact inventory/Waiting and later failure-retention paths.

**Apothecary's Hand** reads the exact actor who commits a beneficial item action, not the target. For
a numeric heal, add `max(1, floor(authoredMagnitude × 0.50))` before clamping to the target's frozen
health cap. For a genuinely timed beneficial effect, add the same 50% to authored duration, rounded
down with minimum +1, before saving its receipt. Choose magnitude *or* duration from typed item
metadata; never improve both.

Binary cures, Broad Antidote's one selected removal, Stonebark's exactly-one guard, Waystone return,
identification, Lure, coatings and harmful thrown items are unchanged. An item with zero/no scalable
field cannot manufacture a second target, charge, cure or copy. Current world-item actions that do
not record a stable using actor receive no bonus rather than silently assigning the Binder; a later
actor-selection field route may opt in through the same typed transaction. The item is consumed once
whether or not some bonus healing is lost to the cap.

Preview and commit share one rules-owned item-effect receipt naming item stable ID, using actor,
target, scalable field, authored value, node bonus and final value. UI names the improved number
before confirmation without exposing unrelated inventory. Acceptance covers the three salves at
empty/partial/full target HP, magnitude rounding/cap/waste, a typed timed fixture, binary cure/
Stonebark/coating/escape/copy exclusions, actor-versus-target ownership, companion automation,
stale/cancel/one-item consumption and relaunch; plus Anatomy base quantities 1–10, zero/no-part,
multiple material families, copies/home/unconscious owner, capacity/Waiting, grade/source invariance,
apex/ordinary and failure-retention receipt parity.

#### Distiller is held for Aimee's effect review

The current effect is mathematically inert: all four settled coating recipes have two named resource
requirements of one unit each plus one selected property-qualified world resource. Reducing each
positive count by 40%, rounding up with minimum one, changes every `1` to `1`. Raising recipe costs
merely to make the node work would damage the sustainable-coating economy.

Recommendation: replace the discount with **“When you apply a coating item to your own eligible
physical weapon, it arms two successful hits instead of one.”** The item is still consumed once;
each landed eligible hit spends one saved charge; misses and carried hits spend none. This preserves
personal ownership, approximately halves resource cost per successful coated hit, needs no bound
inventory subtype and fits the Distiller identity as making a preparation carry further. It remains
separate from Envenom's three Poison charges; prepared Venom stays ineligible while Envenom is armed,
and one non-Poison two-charge coating may coexist under the settled rule.

Do not implement this recommendation or retain the inert discount as a completed consumer until
Aimee reviews it. Alternatives and consequences are in `combat-tree-distiller-effect-review-current.md`.

### 8. Typed permanent choices and legacy identity

Insulation and Emanant purchases atomically store Heat/Caustic/Light. Cancel spends no point. Legacy
ownership defaults once to Heat and is surfaced in DEBUG. Migrate `steady`→`quench` and
`elemental_strike`→`emanation_strike` across cooldowns, gambits and saved preferences; old IDs are
decode-only and never appear as duplicate actions.

#### Passive weapon-affliction checkpoint — Tainted Edge, Sparkhand and Emanant

One typed `physicalWeaponDirect` hit may collect several prospective affliction contributors before
application: Tainted Edge, Sparkhand, Emanant, Envenom and one prepared coating. Ordinary Attack and
techniques explicitly tagged as direct physical weapon hits are eligible. Unbind, Emanation Strike,
items, carried/copied damage, status ticks, retaliation, environment events and a miss are not. A
successful hit still spends a prepared coating/Envenom charge if it defeats the target, but no new
affliction or Stonebark consumption is recorded on a non-standing target.

The personal roots contribute:

- **Tainted Edge:** weak Poison, 1 damage for 2 authored ticks;
- **Sparkhand:** weak Burn, 1 damage for 2 authored ticks; and
- **Emanant:** chosen Heat→Burn 1/2, Caustic→Poison 1/2 or Light→Dazzle 0 damage/2 ticks.

If an actor owns matching Emanant plus Sparkhand/Tainted Edge, replace those two weak contributors
with one strengthened 2-damage/2-tick Burn or Poison payload. Do not apply two rows. A nonmatching root
remains a separate affliction kind: Caustic Emanant + Sparkhand produces Poison 1/2 and Burn 1/2.
Light has no matching root and Dazzle remains 0/2.

Before Stonebark or canonical same-kind max refresh, merge every contributor of the same kind from
this hit into one prospective payload using maximum damage and maximum authored ticks. Retain a
sorted list of contributing stable node/item/technique receipts, but choose tick-damage source through
the canonical strongest-payload rule. Then apply Virulence **once** to the merged direct payload, pass
it through the target's Constitution once, and submit one application. A stronger Venom/Envenom or
prepared coating therefore supersedes weak passive numbers without erasing provenance or creating
duplicate Poison.

When one hit legitimately carries multiple different kinds, submit them in canonical Burn → Poison
→ Dazzle → Bleed order. Stonebark prevents the first application that would add/strengthen and is then
spent; later different kinds may still apply. A same-kind no-op cannot waste the guard. This order is
rules/presentation authority, not dictionary iteration.

Emanant purchase requires an explicit Heat/Caustic/Light choice in the same atomic point transaction.
Cancel/invalid choice spends nothing. The choice cannot be edited in place; a full Spring respec
removes node and choice together, and repurchase asks again. A legacy owner with no choice adopts Heat
once with a visible DEBUG migration receipt, never because Heat is first in an enum. Encounter entry
freezes the exact owner's choice; mid-encounter respec/DEBUG changes cannot rewrite active hits.

The Emanant owner's combat presentation may visibly suggest their chosen emanation without revealing
enemy traits, future status success or world information. It creates no ally/world-tile damage and
is not a Channelworks attack. Preview names the prospective kinds/potencies and prepared-charge use;
commit uses the same merged payload.

Acceptance covers each root alone; all three Emanant choices; matching strengthened and nonmatching
dual-kind cases; ordinary Attack and every explicitly tagged/untagged technique; miss/lethal hit;
Venom/Firebrand/Briar Oil/Flashsalt and Envenom same-/different-kind composition; Virulence once;
Constitution; Stonebark canonical order/no-op; existing stronger/weaker status max refresh; charge
spend; actor/source provenance; purchase cancel/respec/repurchase/legacy Heat adoption; five-person
no-aura; encounter freeze/relaunch; preview=commit; and disabled/empty-v2 parity.

## Slice gates

Each slice must prove:

1. at least one positive and one counterfactual scenario per included stable node;
2. preview and committed outcome use the same rules path;
3. five-member strongest-once aggregation and stable reorder behavior where applicable;
4. mid-action or mid-encounter save/relaunch for any new persisted receipt;
5. node contribution in DEBUG comparison without hidden-information leakage; and
6. no test whose only assertion is that a loadout field changed.

After all slices pass, run the full 72-node matrix, nine pure/nine hybrid observable-route fixtures,
legacy migration, generated-arrival plans, respec and native graph/device acceptance before changing
the default ownership schema.
