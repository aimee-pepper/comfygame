# Armoury rebuild — implementation contract

**Status:** Implementation-ready first specialist rebuild slice. Profile offsets and research costs
are reversible playtest values under DRQ-123.  
**Updated:** 9 Aug 2026

This specializes `gear-crafting-families-current.md` and `crafted-gear-migration-current.md` for
Bracken. It adds one deliberate rebuild flow, not durability, fit stats, random affixes or a second
armour inventory.

## Eligible base

The player chooses exactly one stored or worn ordinary physical protective item in slot **offhand,
head, body, hands or feet**. The preview freezes its stable instance ID.

Ineligible:

- apex/unique/narrative gear;
- Channelworks housings or any emanation core object;
- an item already consumed by another pending preview;
- a legacy masterwork unless the player deliberately enables **Show legacy masterworks** and accepts
  the separate loss warning.

An ordinary piece with reforge rank is still shown in the default picker. Its comparison states
**Reforged rank N → 0**, but reforge work alone does not misclassify it as a legacy masterwork or
require **Show legacy masterworks**. Only positive `legacyPowerCredit` owns that exceptional gate.

Rebuilding a worn item does not require unequipping it. On commit it returns to the same owner/slot;
if the rebuilt profile is not valid for that slot, the preview must never have been offered.

## Profile availability and slots

| Effective Armoury tier | Available profile roots | Output cap |
|---:|---|---:|
| 0 | Rigid shell | 3 |
| 1 | Rigid shell, Insulated layer, Balanced laminate | 3 |
| 2 | all three | 4 |

This applies Decision 102: the built Armoury performs one honest Tier-3 job immediately, tier 1
adds the defensive choice, and tier 2 permits Tier 4.

- **Rigid shell:** offhand, head, body, hands, feet.
- **Insulated layer:** head, body, hands, feet. Offhand is excluded because a carried shield does not
  become body insulation merely by being padded.
- **Balanced laminate:** offhand, head, body, hands, feet.

The base item keeps its slot. Armoury does not turn boots into a helm or a shield into body armour.

## Requirements

All selections are distinct exact samples and use the shared weakest-qualifying default/picker.

| Stable profile ID | Requirements |
|---|---|
| `armoury_rigid_shell_v1` | 2 hardness ≥65; 1 density ≥55; 1 flexibility ≥45 |
| `armoury_insulated_layer_v1` | 2 insulation ≥65; 1 flexibility ≥55; 1 hardness ≥45 |
| `armoury_balanced_laminate_v1` | 1 hardness ≥60; 1 insulation ≥55; 1 flexibility ≥55; 1 density ≥45 |

Natural tier uses the shared `0.6 × weakest grade + 0.4 × average grade`. The old item contributes no
hidden grade: it is the identity/frame being rebuilt, not a sample whose unknown construction can be
reverse-engineered. Output tier is `min(natural tier, station cap)` and pays the normal discounted
12/24/48/80 essence for the actual output tier.

Specialist construction permits but does not guarantee Tier 3/4. If natural tier is below 3, preview
says **This stock yields Tier N; this Armoury can do better** and requires an ordinary explicit
confirmation before commit. The output remains its honest lower tier and pays that tier's cost; the
shop never inflates poor stock to protect its headline. This below-headline confirmation is distinct
from wasted-grade-above-cap and the destructive legacy-masterwork warning.

## Mechanical trade-off

Construction tier remains the item's quality/recipe band. Armoury profile changes what that tier
does against ordinary physical harm:

| Profile | Physical protection contribution | Thermal identity |
|---|---:|---|
| Rigid shell | `effectivePower` | selected-sample average insulation |
| Balanced laminate | `max(0, effectivePower − 0.5)` | selected-sample average insulation |
| Insulated layer | `max(0, effectivePower − 1.0)` | selected-sample average insulation |

These offsets apply only when combat sums protective slots for ordinary armour reduction. They do
not change construction tier, recipe eligibility, sell label or reforge math. Carry the fractional
sum to the existing final rounding boundary. Heat/emanation protection continues to read the
instance's frozen average insulation through the existing rule; do not add a second resistance
number or a reflected status. Reactivity remains the selected-sample average and creates no armour
effect in v1.

The preview shows both values in plain comparison with the current base:

```text
Physical protection: 3.6 → 3.1
Insulation: 24 → 68
```

Never describe Balanced or Insulated as a lower “tier”; the trade is profile output at the same
construction tier.

## Identity and provenance

Commit mutates one gear instance atomically:

- preserve stable instance ID, fallback catalogue ID, authored/display name, slot and wearer;
- set construction tier to the rebuilt output;
- set `specialistProfile` to the stable profile ID;
- freeze new insulation/reactivity and recipe version;
- reset reforge rank to zero;
- clear `legacyPowerCredit` only after the explicit legacy warning;
- preserve an authored unique rule only if the recipe explicitly permits it (none in Armoury v1).

The visible origin name remains the base piece's history. Add the Armoury profile as a separate
subtitle, e.g. **Keen Guard · Balanced laminate · Tier 3**, rather than replacing the object with
“Balanced Laminate.” Exact selected source names remain inspectable under Construction history.

Recycler receipt behavior:

- crafted base: prior `consumedSamples` + newly selected Armoury samples;
- found/catalog base with no receipt: newly selected samples only;
- reforge materials never enter the receipt;
- the consumed old base is never fabricated as a sample.

## Legacy warning

Legacy masterworks are hidden from the default picker. If shown and selected, confirmation states:

```text
This rebuild removes Legacy masterwork +N and resets Reforged rank to 0.
Current physical / insulation → rebuilt physical / insulation
This cannot be undone.
```

Confirmation must be distinct from ordinary wasted-grade or below-headline stock confirmation. A
legacy piece is never selected automatically, and cancel changes nothing.

## Atomic commit and stale preview

At commit, revalidate:

1. same stable base ID still exists at the recorded stored/worn location;
2. its complete profile equals the previewed base profile;
3. every chosen sample still exists at the same bin/index and remains qualifying/distinct;
4. profile remains unlocked and slot-valid;
5. current discounted essence equals the confirmed amount and is affordable;
6. output/return location can accept the rebuilt piece or recoverably spill over.

Any mismatch rejects without removing the base, samples or essence. A successful commit consumes the
selected samples and essence once, mutates the same instance once, and saves once.

## Required fixtures

1. Tier-0 Rigid Shell can produce Tier 3; Insulated/Balanced remain locked and Tier 4 impossible.
2. Tier 1 unlocks all profiles but caps superb stock at 3 with explicit wasted-grade confirmation.
3. Tier 2 permits Tier 4; natural Tier 1/2 stock remains honestly lower tier behind the exact
   below-headline confirmation.
4. Slot matrix rejects insulated offhand and every weapon/tool/keepsake base.
5. Stored and worn rebuilds preserve ID, owner, slot, name and save round-trip.
6. Rigid/Balanced/Insulated contributions differ by 0/−0.5/−1.0 before final combat rounding while
   construction tier remains equal.
7. Crafted receipts append; found receipts begin with new inputs; reforge stock never appears.
8. Positive legacy credit requires its own confirmation and reports exact credit/rank before/after
   values; ordinary reforged gear remains in the normal picker with its reset disclosed.
9. Apex, narrative and Channelworks bases never enter the picker.
10. Removing/changing a base or sample after preview causes a completely non-mutating rejection.
11. Insufficient essence leaves preview visible with an exact shortfall; failed or stale commit does
    not dismiss the sheet as though the rebuild succeeded.
